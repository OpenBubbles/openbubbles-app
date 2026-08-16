import 'dart:convert';
import 'dart:isolate';
import 'dart:math';
import 'dart:typed_data';

import 'package:app_links/app_links.dart';
import 'package:async_task/async_task_extension.dart';
import 'package:bluebubbles/app/layouts/conversation_list/pages/conversation_list.dart';
import 'package:bluebubbles/app/layouts/conversation_view/widgets/message/message_holder.dart';
import 'package:bluebubbles/app/layouts/settings/pages/misc/shared_streams_panel.dart';
import 'package:bluebubbles/app/layouts/settings/pages/profile/posterkit.dart';
import 'package:bluebubbles/app/layouts/setup/setup_view.dart';
import 'package:bluebubbles/app/wrappers/titlebar_wrapper.dart';
import 'package:bluebubbles/database/database.dart';
import 'package:bluebubbles/helpers/ui/facetime_helpers.dart';
import 'package:bluebubbles/main.dart';
import 'package:bluebubbles/src/rust/api/api.dart' as api;
import 'package:bluebubbles/src/rust/lib.dart' as lib;
import 'package:bluebubbles/helpers/helpers.dart';
import 'package:bluebubbles/database/models.dart';
import 'package:bluebubbles/services/services.dart';
import 'package:bluebubbles/services/rustpush/send_retry_policy.dart';
import 'package:bluebubbles/services/rustpush/profile_retry_policy.dart';
import 'package:bluebubbles/utils/crypto_utils.dart';
import 'package:bluebubbles/utils/logger/logger.dart';
import 'package:collection/collection.dart';
import 'package:crypto/crypto.dart';
import 'package:ffmpeg_kit_flutter_new/ffmpeg_kit.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_rust_bridge/flutter_rust_bridge.dart';
import 'package:get/get.dart';
import 'package:in_app_purchase_android/billing_client_wrappers.dart';
import 'package:geocoding/geocoding.dart';
import 'package:mime_type/mime_type.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:slugify/slugify.dart';
import 'package:supercharged/supercharged.dart';
import 'package:tuple/tuple.dart';
import 'package:universal_io/io.dart';
import 'package:url_launcher/url_launcher.dart';
import '../network/backend_service.dart';
import 'package:dio/dio.dart';
import 'package:uuid/uuid.dart';
import 'package:dlibphonenumber/dlibphonenumber.dart';
import 'package:telephony_plus/telephony_plus.dart';
import 'package:vpn_connection_detector/vpn_connection_detector.dart';
import 'package:convert/convert.dart';
import 'package:bluebubbles/helpers/types/constants.dart' as constants;
import 'dart:ui' as ui;
import 'package:mixpanel_flutter/mixpanel_flutter.dart';
import 'package:bluebubbles/helpers/backend/startup_tasks.dart';
import 'package:flutter_isolate/flutter_isolate.dart';
import 'package:google_sign_in_all_platforms/google_sign_in_all_platforms.dart';

var uuid = const Uuid();
RustPushService pushService =
    Get.isRegistered<RustPushService>() ? Get.find<RustPushService>() : Get.put(RustPushService());


const rpApiRoot = "https://hw.openbubbles.app/code";

const clientId = '1041242226917-ik21n86fp43e82iu1e5soh6bu6gvuste.apps.googleusercontent.com';
const clientSecret = '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';


class SyncIsolate {
  static void initialize() {
    ui.CallbackHandle callbackHandle = ui.PluginUtilities.getCallbackHandle(backgroundSyncIsolate)!;
    ss.prefs.setInt("backgroundSyncIsolate", callbackHandle.toRawHandle());
  }
}

@pragma('vm:entry-point')
Future<void> backgroundSyncIsolate() async {
  final receive = ReceivePort();
  ui.IsolateNameServer.registerPortWithName(receive.sendPort, "bg_sync");
  List<SendPort> ports = [];

  receive.listen((port) {
    ports.add(port);
  });

  await StartupTasks.initIsolateServices();

  pushService.isSyncing.listen((value) {
    notif.createSyncStatusNotification(value);

    ports.retainWhere((port) {
      try {
        port.send(value);
        return true;
      } catch (e) {
        Logger.error("failed to send status", error: e);
        return false;
      }
    });
  });

  chats.restoring = true;

  await pushService.initFuture;
  String? emsg;

  try {
    await pushService.doCloudKitSyncPrivate();
  } catch (e) {
    emsg = e.toString();
    rethrow;
  } finally {
    pushService.isSyncing.value = null;
    chats.restoring = false;
    if (emsg != null) notif.createSyncFailed(emsg);
    ui.IsolateNameServer.removePortNameMapping("bg_sync");
    mcs.invokeMethod("exit");
  }

}

// utils for communicating between dart and rustpush.
class RustPushBBUtils {
  static Handle rustHandleToBB(String handle) {
    var address = handle.replaceAll("tel:", "").replaceAll("mailto:", "");
    var mHandle = Handle.findOne(addressAndService: Tuple2(address, "iMessage"));
    if (mHandle == null) {
      mHandle = Handle(
        address: handle.replaceAll("tel:", "").replaceAll("mailto:", "")
      );
      mHandle.save();
    }
    if (mHandle.originalROWID == null) {
      mHandle.originalROWID = mHandle.id!;
      mHandle.save();
    }
    return mHandle;
  }

  static String formatAddress(String e) {
    if (e.isEmail) {
      return e;
    }
    var parsed = PhoneNumberUtil.instance.parse(e, "US");
    return PhoneNumberUtil.instance.format(parsed, PhoneNumberFormat.e164);
  }

  static Future<String> formatAndAddPrefix(String e) async {
    var address = formatAddress(e);
    if (address.isEmail) {
      return "mailto:$address";
    } else {
      return "tel:$address";
    }
  }

  static DateTime fromNsSinceAppleEpoch(int ns) {
    const coreDataEpochOffsetSeconds = 978307200;
    return DateTime.fromMicrosecondsSinceEpoch((ns ~/ 1000) + coreDataEpochOffsetSeconds * 1000000, isUtc: true);
  }

  static int nsSinceAppleEpoch(DateTime time) {
    const coreDataEpochOffsetSeconds = 978307200;
    return (time.microsecondsSinceEpoch - coreDataEpochOffsetSeconds * 1000000) * 1000;
  }

  static String bbHandleToRust(Handle handle) {
    var address = handle.address;
    if (address.isEmail) {
      return "mailto:$address";
    } else {
      return "tel:$address";
    }
  }

  static Future<(List<String>, List<Handle>)> rustParticipantsToBB(List<String> participants) async {
    var myHandles = (await api.getHandles(state: pushService.state!.client));
    var mine = myHandles.filter((e) => participants.contains(e)).toList();
    return (mine, participants.filter((e) => !myHandles.contains(e)).map((e) => rustHandleToBB(e)).toList());
  }

  static Map<String, String> modelMap = {
    "MacBookAir1,1": "MacBook Air 13\" (2008)",
    "MacBookAir2,1": "MacBook Air 13\" (2009)",
    "MacBookAir3,1": "MacBook Air 11\" (2010)",
    "MacBookAir3,2": "MacBook Air 13\" (2010)",
    "MacBookAir4,1": "MacBook Air 11\" (2011)",
    "MacBookAir4,2": "MacBook Air 13\" (2012)",
    "MacBookAir5,1": "MacBook Air 11\" (2012)",
    "MacBookAir5,2": "MacBook Air 13\" (2012)",
    "MacBookAir6,1": "MacBook Air 11\" (2014)",
    "MacBookAir6,2": "MacBook Air 13\" (2014)",
    "MacBookAir7,1": "MacBook Air 11\" (2015)",
    "MacBookAir7,2": "MacBook Air 13\" (2017)",
    "MacBookAir8,1": "MacBook Air 13\" (2018)",
    "MacBookAir8,2": "MacBook Air 13\" (2019)",
    "MacBookAir9,1": "MacBook Air 13\" (2020)",
    "MacBookAir10,1": "MacBook Air 13\" (2020)",
    "Mac14,2": "MacBook Air 13\" (2022)",
    "Mac14,15": "MacBook Air 15\" (2023)",
    "Mac15,12": "MacBook Air 13\" (2024)",
    "Mac15,13": "MacBook Air 15\" (2024)",
    "MacBookPro1,1": "MacBook Pro 15\" (2006)",
    "MacBookPro1,2": "MacBook Pro 17\" (2006)",
    "MacBookPro2,2": "MacBook Pro 15\" (2006)",
    "MacBookPro2,1": "MacBook Pro 17\" (2006)",
    "MacBookPro3,1": "MacBook Pro 17\" (2007)",
    "MacBookPro4,1": "MacBook Pro 17\" (2008)",
    "MacBookPro5,1": "MacBook Pro 15\" (2009)",
    "MacBookPro5,2": "MacBook Pro 17\" (2009)",
    "MacBookPro5,5": "MacBook Pro 13\" (2009)",
    "MacBookPro5,4": "MacBook Pro 15\" (2009)",
    "MacBookPro5,3": "MacBook Pro 15\" (2009)",
    "MacBookPro7,1": "MacBook Pro 13\" (2010)",
    "MacBookPro6,2": "MacBook Pro 15\" (2010)",
    "MacBookPro6,1": "MacBook Pro 17\" (2010)",
    "MacBookPro8,1": "MacBook Pro 13\" (2011)",
    "MacBookPro8,2": "MacBook Pro 15\" (2011)",
    "MacBookPro8,3": "MacBook Pro 17\" (2011)",
    "MacBookPro9,2": "MacBook Pro 13\" (2012)",
    "MacBookPro9,1": "MacBook Pro 15\" (2012)",
    "MacBookPro10,1": "MacBook Pro 15\" (2013)",
    "MacBookPro10,2": "MacBook Pro 13\" (2013)",
    "MacBookPro11,1": "MacBook Pro 13\" (2014)",
    "MacBookPro11,2": "MacBook Pro 15\" (2014)",
    "MacBookPro11,3": "MacBook Pro 15\" (2014)",
    "MacBookPro12,1": "MacBook Pro 13\" (2015)",
    "MacBookPro11,4": "MacBook Pro 15\" (2015)",
    "MacBookPro11,5": "MacBook Pro 15\" (2015)",
    "MacBookPro13,1": "MacBook Pro 13\" (2016)",
    "MacBookPro13,2": "MacBook Pro 13\" (2016)",
    "MacBookPro13,3": "MacBook Pro 15\" (2016)",
    "MacBookPro14,1": "MacBook Pro 13\" (2017)",
    "MacBookPro14,2": "MacBook Pro 13\" (2017)",
    "MacBookPro14,3": "MacBook Pro 15\" (2017)",
    "MacBookPro15,2": "MacBook Pro 13\" (2019)",
    "MacBookPro15,1": "MacBook Pro 15\" (2019)",
    "MacBookPro15,3": "MacBook Pro 15\" (2019)",
    "MacBookPro15,4": "MacBook Pro 13\" (2019)",
    "MacBookPro16,1": "MacBook Pro 16\" (2019)",
    "MacBookPro16,3": "MacBook Pro 13\" (2020)",
    "MacBookPro16,2": "MacBook Pro 13\" (2020)",
    "MacBookPro16,4": "MacBook Pro 16\" (2020)",
    "MacBookPro17,1": "MacBook Pro 13\" (2020)",
    "MacBookPro18,3": "MacBook Pro 14\" (2021)",
    "MacBookPro18,4": "MacBook Pro 14\" (2021)",
    "MacBookPro18,1": "MacBook Pro 16\" (2021)",
    "MacBookPro18,2": "MacBook Pro 16\" (2021)",
    "Mac14,7": "MacBook Pro 13\" (2022)",
    "Mac14,9": "MacBook Pro 14\" (2023)",
    "Mac14,5": "MacBook Pro 14\" (2023)",
    "Mac14,10": "MacBook Pro 16\" (2023)",
    "Mac14,6": "MacBook Pro 16\" (2023)",
    "Mac15,3": "MacBook Pro 14\" (2023)",
    "Mac15,6": "MacBook Pro 14\" (2023)",
    "Mac15,10": "MacBook Pro 14\" (2023)",
    "Mac15,8": "MacBook Pro 14\" (2023)",
    "Mac15,7": "MacBook Pro 16\" (2023)",
    "Mac15,11": "MacBook Pro 16\" (2023)",
    "Mac15,9": "MacBook Pro 16\" (2023)",
    "MacBook1,1": "MacBook 13\" (2006)",
    "MacBook2,1": "MacBook 13\" (2007)",
    "MacBook3,1": "MacBook 13\" (2007)",
    "MacBook4,1": "MacBook 13\" (2008)",
    "MacBook5,1": "MacBook 13\" (2008)",
    "MacBook5,2": "MacBook 13\" (2009)",
    "MacBook6,1": "MacBook 13\" (2009)",
    "MacBook7,1": "MacBook 13\" (2010)",
    "MacBook8,1": "MacBook 12\" (2015)",
    "MacBook9,1": "MacBook 12\" (2016)",
    "MacBook10,1": "MacBook 12\" (2017)",
    "iMac4,1": "iMac 20\" (2006)",
    "iMac4,2": "iMac 17\" (2006)",
    "iMac5,2": "iMac 17\" (2006)",
    "iMac5,1": "iMac 20\" (2006)",
    "iMac6,1": "iMac 24\" (2006)",
    "iMac7,1": "iMac 24\" (2007)",
    "iMac8,1": "iMac 24\" (2008)",
    "iMac9,1": "iMac 20\" (2010)",
    "iMac10,1": "iMac 27\" (2009)",
    "iMac11,1": "iMac 27\" (2009)",
    "iMac11,2": "iMac 21.5\" (2010)",
    "iMac11,3": "iMac 27\" (2010)",
    "iMac12,1": "iMac 21.5\" (2011)",
    "iMac12,2": "iMac 27\" (2011)",
    "iMac13,1": "iMac 21.5\" (2013)",
    "iMac13,2": "iMac 27\" (2012)",
    "iMac14,1": "iMac 21.5\" (2013)",
    "iMac14,3": "iMac 21.5\" (2013)",
    "iMac14,2": "iMac 27\" (2013)",
    "iMac14,4": "iMac 21.5\" (2014)",
    "iMac15,1": "iMac 27\" (2015)",
    "iMac16,1": "iMac 21.5\" (2015)",
    "iMac16,2": "iMac 21.5\" (2015)",
    "iMac17,1": "iMac 27\" (2015)",
    "iMac18,1": "iMac 21.5\" (2017)",
    "iMac18,2": "iMac 21.5\" (2017)",
    "iMac18,3": "iMac 27\" (2017)",
    "iMac19,2": "iMac 21.5\" (2019)",
    "iMac19,1": "iMac 27\" (2019)",
    "iMac20,1": "iMac 27\" (2020)",
    "iMac20,2": "iMac 27\" (2020)",
    "iMac21,2": "iMac 24\" (2021)",
    "iMac21,1": "iMac 24\" (2021)",
    "Mac15,4": "iMac 24\" (2023)",
    "Mac15,5": "iMac 24\" (2023)",
    "iMacPro1,1": "iMac Pro 27\" (2017)",
    "Macmini1,1": "Mac mini (2006)",
    "Macmini2,1": "Mac mini (2007)",
    "Macmini3,1": "Mac mini (2009)",
    "Macmini4,1": "Mac mini (2010)",
    "Macmini5,1": "Mac mini (2011)",
    "Macmini5,2": "Mac mini (2011)",
    "Macmini5,3": "Mac mini (2011)",
    "Macmini6,1": "Mac mini (2012)",
    "Macmini6,2": "Mac mini (2012)",
    "Macmini7,1": "Mac mini (2014)",
    "Macmini8,1": "Mac mini (2018)",
    "Macmini9,1": "Mac mini (2020)",
    "Mac14,3": "Mac mini (2023)",
    "Mac14,12": "Mac mini (2023)",
    "MacPro1,1*": "Mac Pro (2006)",
    "MacPro2,1": "Mac Pro (2007)",
    "MacPro3,1": "Mac Pro (2008)",
    "MacPro4,1": "Mac Pro (2009)",
    "MacPro5,1": "Mac Pro (2012)",
    "MacPro6,1": "Mac Pro (2013)",
    "MacPro7,1": "Mac Pro (2019)",
    "Mac14,8": "Mac Pro (2023)",
  };

  static IconData getIcon(String model) {
    if (model.contains("MacBook")) {
      return CupertinoIcons.device_laptop;
    } else if (model.contains("iPhone") || model.contains("iPod")) {
      return CupertinoIcons.device_phone_portrait;
    } else {
      return CupertinoIcons.device_desktop;
    }
  }

  static String modelToUser(String model) {
    return modelMap[model] ?? model;
  }
}

class RustPushBackend implements BackendService {
  final InFlightSendRegistry _inFlightSends = InFlightSendRegistry();

  Future<String> getDefaultHandle() async {
    var myHandles = await api.getHandles(state: pushService.state!.client);
    var setHandle = ss.settings.defaultHandle.value;
    if (myHandles.contains(setHandle)) {
      return setHandle;
    }
    return myHandles[0];
  }

  Future<String> getDefaultSMSHandle() async {
    var handle = await getDefaultHandle();
    if (ss.settings.smsForwardingTargets.keys.isEmpty) return handle;
    if (ss.settings.smsForwardingTargets.containsKey(handle)) return handle;
    return ss.settings.smsForwardingTargets.keys.first;
  }

  @override
  bool canSendSubject() {
    return true;
  }

  @override
  void init() {
    pushService.hello();
  }

  @override
  bool canDelete() {
    return true;
  }

  @override
  bool canCreateGroupChats() {
    return true;
  }

  @override
  bool supportsSmsForwarding() {
    return true;
  }

  Future<api.MessageType> getService(Chat chat, {Message? forMessage}) async {
    if (chat.isRpSms) {
      String? fromHandle;
      if (forMessage != null && forMessage.handle != null) {
        var myHandles = await api.getHandles(state: pushService.state!.client);
        var sender = RustPushBBUtils.bbHandleToRust(forMessage.handle!);
        if (!myHandles.contains(sender)) {
          fromHandle = sender; // this is a forwarded message
        }
      }
      return api.MessageType.sms(isPhone: await chat.shouldRoute(), usingNumber: await chat.ensureHandle(), fromHandle: fromHandle);
    }
    return const api.MessageType.iMessage();
  }

  Future<void> sendMsg(api.MessageInst msg, {bool waitForResource = true}) {
    return _inFlightSends.run(msg.id, () => _sendMsgWithRetry(msg, waitForResource: waitForResource));
  }

  Future<void> _sendMsgWithRetry(api.MessageInst msg, {required bool waitForResource}) async {
    var message = Message.findOne(guid: msg.id);
    if (message != null) {
      message.sendingServiceId = pushService.serviceId;
      message.save(updateSendingServiceId: true);
    }
    var stillRunning = false;
    final retryPolicy = SendRetryPolicy();
    try {
      while (true) {
        try {
          stillRunning = await api.send(state: pushService.state!.client, local: pushService.state!.localBroadcast, msg: msg);
          break;
        } catch (e) {
          final decision = retryPolicy.next(e, waitForResource: waitForResource);
          if (decision.markFailedLogin) {
            pushService.markFailedToLogin();
          }
          if (!decision.retry) rethrow;
          Logger.warn("Retrying send ${msg.id} in ${decision.delay.inSeconds}s (${decision.kind.name})");
          await Future.delayed(decision.delay);
        }
      }
    } finally {
      if (!stillRunning) {
        message = Message.findOne(guid: msg.id);
        if (message != null) {
          message.sendingServiceId = null;
          message.save(updateSendingServiceId: true);
        }
      }
    }
  }

  @override
  Future<Chat> createChat(List<String> addresses, AttributedBody? message, String service,
      {CancelToken? cancelToken, String? existingGuid}) async {
    var handle = service == "SMS" ? await getDefaultSMSHandle() : await getDefaultHandle();
    var formattedHandles = addresses.map((e) => RustPushBBUtils.rustHandleToBB(e)).toList();
    var chat = Chat(
      guid: existingGuid ?? uuid.v4(),
      participants: formattedHandles,
      usingHandle: handle,
      isRpSms: service == "SMS",
      senderIsKnown: formattedHandles.any((handle) => !(handle.contact?.isShared ?? true)),
    );
    chat.save(); //save for reflectMessage
    if (message != null) {
      var msg = await api.newMsg(
          conversation: await chat.getConversationData(),
          message: api.Message.message(api.NormalMessage(
              parts: await partsFromBody(message),
                  service: await getService(chat),
                  voice: false,
                  embeddedProfile: await pushService.getShareProfileMessageFor(chat.participants),
                  )),
          sender: handle);
      if (chat.isRpSms) {
        msg.target = await getSMSTargets(handle);
      }
      await sendMsg(msg);
      msg.sentTimestamp = DateTime.now().millisecondsSinceEpoch;

      final newMessage = (await pushService.reflectMessageDyn(msg))!;
      newMessage.chat.target = chat;
      await newMessage.forwardIfNessesary(chat);
      newMessage.save();
    }
    await chats.addChat(chat);
    return chat;
  }

  @override
  Future<PlatformFile> downloadAttachment(Attachment attachment,
      {void Function(int p1, int p2)? onReceiveProgress, bool original = false, CancelToken? cancelToken}) async {
    if (attachment.metadata!.containsKey("cloud")) {
      await api.downloadCloudAttachments(cloudMessagesClient: pushService.state!.icloudServices!.cloudMessagesClient!, files: [(attachment.path, attachment.metadata!["cloud"])]);
      return attachment.getFile();
    }
    var rustAttachment = api.restoreAttachment(data: attachment.metadata!["rustpush"]);
    var stream = api.downloadAttachment(aps: pushService.state!.conn, attachment: rustAttachment, path: attachment.path);
    await for (final event in stream) {
      if (onReceiveProgress != null) {
        onReceiveProgress(event.prog, event.total);
      }
    }

    // android doesn't support CAF, convert to m4a
    if (attachment.uti == "com.apple.coreaudio-format" && Platform.isAndroid) {
      await File(attachment.path).rename("${attachment.directory}/encode.caf");
      var session = await FFmpegKit.execute("-i \"${attachment.directory}/encode.caf\" \"${attachment.directory}/encode.m4a\"");

      var output = (await session.getOutput())!;
      while (output.isNotEmpty) {
        Logger.info(output.substring(0, min(output.length, 300)));
        output = output.substring(min(output.length, 300));
      }

      await File("${attachment.directory}/encode.m4a").rename(attachment.path);
    }

    return attachment.getFile();
  }

  Future<List<api.MessageTarget>> getSMSTargets(String handle) async {
    if (ss.settings.isSmsRouter.value) {
      var registered = await api.getMyPhoneHandles(state: pushService.state!.client);
      if (registered.contains(handle)) {
        return ss.settings.smsRoutingTargets.map((element) => api.MessageTarget.uuid(element)).toList();
      }
    }
    var target = ss.settings.smsForwardingTargets[handle];
    if (target == null) throw Exception("No SMS target for handle $handle");
    return [api.MessageTarget.uuid(target)];
  }

  @override
  Future<Message> sendAttachment(Chat chat, Message m, bool isAudioMessage, Attachment att, {void Function(int p1, int p2)? onSendProgress, CancelToken? cancelToken}) async {
    if (chat.isRpSms && !smsForwardingEnabled()) {
      throw Exception("SMS is not enabled (enable in settings -> user)");
    }
    var stream = api.uploadAttachment(
        aps: pushService.state!.conn,
        path: att.getFile().path!,
        mime: att.mimeType ?? "application/octet-stream",
        uti: att.uti ?? "public.data",
        name: att.transferName!);
    api.Attachment? attachment;
    await for (final event in stream) {
      if (event.attachment != null) {
        Logger.info("upload finish");
        attachment = event.attachment;
        att.metadata = {"rustpush": await api.saveAttachment(att: attachment!)};
        att.save(m);
      } else if (onSendProgress != null) {
        Logger.info("upload progress ${event.prog} of ${event.total}");
        onSendProgress(event.prog, event.total);
      }
    }
    Logger.info("uploaded");
    var msg = await api.newMsg(
        conversation: await chat.getConversationData(),
        sender: await chat.ensureHandle(),
        message: api.Message.message(api.NormalMessage(
          parts: api.MessageParts(
              field0: [
                if (m.payloadData?.appData?.first.ldText != null)
                api.IndexedMessagePart(part_: api.MessagePart.object(m.payloadData!.appData!.first.ldText!)),
                api.IndexedMessagePart(part_: api.MessagePart.attachment(attachment!))
              ]),
          replyGuid: m.threadOriginatorGuid,
          replyPart: m.threadOriginatorGuid == null ? null : m.threadOriginatorPart,
          effect: m.expressiveSendStyleId,
          service: await getService(chat, forMessage: m),
          subject: m.subject,
          app: m.payloadData == null ? null : pushService.dataToApp(m.payloadData!),
          voice: isAudioMessage,
          scheduled: m.dateScheduled != null ? api.ScheduleMode(ms: m.dateScheduled!.millisecondsSinceEpoch, schedule: true) : null,
          embeddedProfile: await pushService.getShareProfileMessageFor(chat.participants),
        )));
    if (m.stagingGuid != null) {
      msg.id = m.stagingGuid!;
    }
    if (chat.isRpSms) {
      msg.target = await getSMSTargets(msg.sender!);
    }
    m.stagingGuid = msg.id; // in case delivered comes in before sending "finishes" (also for retries, duh)
    m.save(chat: chat);
    await sendMsg(msg);
    if (chat.isRpSms) {
      m.stagingGuid = msg.id;
    } else {
      m.stagingGuid = null;
    }
    m.save(chat: chat);
    msg.sentTimestamp = DateTime.now().millisecondsSinceEpoch;
    return (await pushService.reflectMessageDyn(msg))!;
  }

  Future<Message> forwardMMSAttachment(Chat chat, Message m, Attachment att) async {
    // 300 kb
    api.Attachment? attachment;
    var stream = api.uploadAttachment(
        aps: pushService.state!.conn,
        path: att.getFile().path!,
        mime: att.mimeType ?? "application/octet-stream",
        uti: att.uti ?? "public.data",
        name: att.transferName!);
    if (att.getFile().size > 300000) {
      await for (final event in stream) {
        if (event.attachment != null) {
          Logger.info("upload finish");
          attachment = event.attachment;
        }
      }
    } else {
      attachment = api.Attachment(
        aType: api.AttachmentType.inline(await att.getFile().getBytes()),
        mime: att.mimeType ?? "application/octet-stream",
        part_: 0,
        utiType: att.uti ?? "public.data",
        name: att.transferName!,
        iris: false,
      );
    }
    Logger.info("uploaded");
    var service = await getService(chat, forMessage: m);
    var msg = await api.newMsg(
        conversation: await chat.getConversationData(),
        sender: await chat.ensureHandle(),
        message: api.Message.message(api.NormalMessage(
          parts: api.MessageParts(
              field0: [api.IndexedMessagePart(part_: api.MessagePart.attachment(attachment!))]),
          replyGuid: m.threadOriginatorGuid,
          replyPart: m.threadOriginatorGuid == null ? null : m.threadOriginatorPart,
          effect: m.expressiveSendStyleId,
          service: service,
          voice: false
        )));
    if (m.stagingGuid != null || (m.guid != null && m.guid!.contains("error") && m.guid!.contains("temp"))) {
      msg.id = m.stagingGuid ?? m.guid!;
    }
    msg.target = await getSMSTargets(msg.sender!);
    await sendMsg(msg);
    msg.sentTimestamp = DateTime.now().millisecondsSinceEpoch;
    return (await pushService.reflectMessageDyn(msg))!;
  }

  @override
  bool canCancelUploads() {
    return false;
  }

  Future<void> broadcastSmsForwardingState(bool state, List<String> uuids) async {
    var handles = await api.getHandles(state: pushService.state!.client);
    var useHandle = handles.firstWhereOrNull((handle) => handle.contains("tel:")) ?? handles.first;
    var msg = await api.newMsg(
      conversation: api.ConversationData(participants: [useHandle], cvName: null, senderGuid: null),
      sender: useHandle,
      message: api.Message.enableSmsActivation(state),
    );
    msg.target = uuids.map((e) => api.MessageTarget.uuid(e)).toList();
    await sendMsg(msg);
  }

  Future<void> confirmSmsSent(Message m, Chat c, bool success) async {
    var msg = await api.newMsg(
      conversation: await c.getConversationData(),
      sender: await c.ensureHandle(),
      message: api.Message.smsConfirmSent(success),
    );
    msg.id = m.stagingGuid ?? m.guid!;
    if (c.isRpSms) {
      msg.target = await getSMSTargets(msg.sender!);
    }
    await sendMsg(msg);
  }

  @override
  Future<bool> canUploadGroupPhotos() async {
    return true;
  }

  @override
  Future<bool> deleteChatIcon(Chat chat, {CancelToken? cancelToken}) async {
    var msg = await api.newMsg(
      conversation: await chat.getConversationData(),
      sender: await chat.ensureHandle(),
      message: api.Message.iconChange(api.IconChangeMessage(groupVersion: chat.groupVersion!)),
    );
    await sendMsg(msg);
    Attachment.delete(chat.photoAttachmentGuid!);
    chat.photoAttachmentGuid = null;
    return true;
  }

  String formatDuration(int secondsAbs, {bool useSecs = false}) {
    var seconds = secondsAbs.abs();
    var secs = seconds % 60;
    var minTotal = seconds ~/ 60;
    var mins = minTotal % 60;
    var hrTotal = minTotal ~/ 60;
    var hrs = hrTotal % 24;
    var days = hrTotal ~/ 24;
    String output = seconds.isNegative ? "-" : "";
    if (days > 0) output += "${days}d ";
    if (hrs > 0) output += "${hrs}h ";
    if (mins > 0) output += "${mins}m ";
    if ((secs > 0 && useSecs) || output.trim() == "") output += "${secs}s ";
    return output.trim();
  }

  @override
  Future<Map<String, dynamic>> getAccountInfo() async {
    var detail = await pushService.checkPurchaseState();
    var handles = await api.getHandles(state: pushService.state!.client);
    var state = await api.getRegstate(state: pushService.state!.client);
    var deviceState = await api.getDeviceInfo(config: pushService.state!.osConfig);
    var stateStr = "";
    if (!detail && ss.settings.deviceIsHosted.value && ss.settings.hostedToken.value != null) {
      stateStr = "Subscription not active!";
    } else if (state is api.RegisterState_Registered) {
      stateStr = "Connected (renew in ${formatDuration(state.nextS)})";
    } else if (state is api.RegisterState_Registering) {
      stateStr = "Reregistering...";
    } else if (state is api.RegisterState_Failed) {
      String suffix = "";
      if (state.retryWait != null) {
        var data = state.retryWait!.toInt();
        suffix = "(waiting ${formatDuration(data)}; error: ${state.error})";
      }
      stateStr = "Deregistered $suffix";
    }
    return {
      "account_name": ss.settings.userName.value,
      "apple_id": ss.settings.iCloudAccount.value,
      "login_status_message": stateStr,
      "vetted_aliases": handles.map((e) => {
        "Alias": e.replaceFirst("tel:", "").replaceFirst("mailto:", ""),
        "Status": state is api.RegisterState_Registered ? 3 : 0,
      }).toList(),
      "active_alias": (await getDefaultHandle()).replaceFirst("tel:", "").replaceFirst("mailto:", ""),
      "sms_forwarding_capable": true,
      "sms_forwarding_enabled": smsForwardingEnabled(),
      "can_pnr": deviceState.name.contains("iPhone") || deviceState.name.contains("iPod") || deviceState.name.contains("iPad"),
      "can_forward": (await api.getMyPhoneHandles(state: pushService.state!.client)).isNotEmpty || ss.settings.isTester.value,
    };
  }

  @override
  Future<void> setDefaultHandle(String defaultHandle) async {
    ss.settings.defaultHandle.value = await RustPushBBUtils.formatAndAddPrefix(defaultHandle);
    ss.saveSettings();
  }

  @override
  Future<Map<String, dynamic>> getAccountContact() async {
    return {};
  }

  @override
  Future<bool> setChatIcon(Chat chat, String path,
      {void Function(int p1, int p2)? onSendProgress, CancelToken? cancelToken}) async {
    chat.groupVersion = (chat.groupVersion ?? -1) + 1;
    var mmcsStream = api.uploadMmcs(aps: pushService.state!.conn, path: path);
    api.MMCSFile? mmcs;
    await for (final event in mmcsStream) {
      if (event.file != null) {
        Logger.info("upload finish");
        mmcs = event.file;
      } else if (onSendProgress != null) {
        Logger.info("upload progress ${event.prog} of ${event.total}");
        onSendProgress(event.prog, event.total);
      }
    }
    chat.customAvatarPath = path;
    var msg = await api.newMsg(
      conversation: await chat.getConversationData(),
      sender: await chat.ensureHandle(),
      message: api.Message.iconChange(api.IconChangeMessage(groupVersion: chat.groupVersion!, file: mmcs!)),
    );

    await sendMsg(msg);

    chat.updateAttachmentGuid(msg.id);
    chat.ckSyncState = false;
    chat.save(updateAttachmentGuid: true, updateCustomAvatarPath: true, updateGroupVersion: true, updateCkSyncState: true);

    msg.sentTimestamp = DateTime.now().millisecondsSinceEpoch;
    inq.queue(IncomingItem(
      chat: chat,
      message: (await pushService.reflectMessageDyn(msg))!,
      type: QueueType.newMessage
    ));
    return true;
  }

  Future<api.OperatedChat> getOperatedChat(Chat c) async {
    var conversationData = await c.getConversationData();
    var name = c.participants.length == 1 ? "iMessage;-;${c.participants[0].address}" : "iMessage;+;chat${Random().nextInt(9999999999999999)}";
    return api.OperatedChat(
      participants: conversationData.participants.map((p) => p.replaceFirst("mailto:", "").replaceFirst("tel:", "")).toList(), 
      groupId: conversationData.senderGuid!, 
      guid: name,
    );
  }

  @override
  Future<void> moveToRecycleBin(Chat c, Message? message) async {

    var handle = await c.ensureHandle();
    var msg = await api.newMsg(
      conversation: message?.dateScheduled != null ? await c.getConversationData() : api.ConversationData(participants: [handle]),
      sender: handle,
      message: message?.dateScheduled != null ?
        const api.Message.unschedule()
       : api.Message.moveToRecycleBin(api.MoveToRecycleBinMessage(target: message != null ? api.DeleteTarget.messages([message.guid!]) : api.DeleteTarget.chat(await getOperatedChat(c)), recoverableDeleteDate: DateTime.now().millisecondsSinceEpoch))
    );
    if (message?.dateScheduled != null) {
      msg.id = message!.guid!;
    }
    await sendMsg(msg);
  }

  @override
  Future<void> restoreChat(Chat c) async {
    var handle = await c.ensureHandle();
    var msg = await api.newMsg(
      conversation: api.ConversationData(participants: [handle]),
      sender: handle,
      message: api.Message.recoverChat(await getOperatedChat(c))
    );
    await sendMsg(msg);
  }

  @override
  Future<void> permanentlyDeleteChat(Chat c) async {
    var handle = await c.ensureHandle();
    var msg = await api.newMsg(
      conversation: api.ConversationData(participants: [handle]),
      sender: handle,
      message: api.Message.permanentDelete(api.PermanentDeleteMessage(target: api.DeleteTarget.chat(await getOperatedChat(c)), isScheduled: false))
    );
    await sendMsg(msg);
  }

  bool smsForwardingEnabled() {
    return ss.settings.isSmsRouter.value || ss.settings.smsForwardingTargets.isNotEmpty;
  }

  Future<api.MessageParts> partsFromBody(AttributedBody body) async {

    List<api.IndexedMessagePart> parts = [];
    for (var e in body.runs) {
      if (e.isAttachment) {
        var attachment = Attachment.findOne(e.attributes!.attachmentGuid!);
        if (attachment == null) continue;
        var rustAttachment = api.restoreAttachment(data: attachment.metadata!["rustpush"]);
        parts.add(api.IndexedMessagePart(part_: api.MessagePart.attachment(rustAttachment)));
        continue;
      }

      var text = body.string.substring(e.range.first, e.range.first + e.range.last);
      parts.add(api.IndexedMessagePart(part_: e.hasMention ? 
        api.MessagePart.mention(e.attributes!.mention!, text) : 
        api.MessagePart.text(text, pushService.fromAttributes(e.attributes!))));
    }

    return api.MessageParts(field0: parts);
  }

  @override
  Future<Message> sendMessage(Chat chat, Message m, {CancelToken? cancelToken}) async {
    if (chat.isRpSms && !smsForwardingEnabled()) {
      throw Exception("SMS is not enabled (enable in settings -> user)");
    }
    api.LinkMeta? linkMeta;
    try {
      if (m.fullText.replaceAll("\n", " ").hasUrl && !MetadataHelper.mapIsNotEmpty(m.metadata) && !m.hasApplePayloadData) {
        var metadata = await MetadataHelper.fetchMetadata(m).timeout(const Duration(seconds: 15));
        
        if (MetadataHelper.isNotEmpty(metadata)) {
          m.metadata = metadata!.toJson();
          List<Uint8List> attachments = [];
          api.LPImageMetadata? imagemeta;
          api.RichLinkImageAttachmentSubstitute? image;
          api.LPIconMetadata? iconmeta;
          api.RichLinkImageAttachmentSubstitute? icon;

          var uri = Uri.parse(m.url!).replace(path: "/favicon.ico");
          var iconUrl = uri.toString();
          final response = await http.dio.get(iconUrl, options: Options(responseType: ResponseType.bytes, receiveTimeout: const Duration(seconds: 15)));
          if (response.statusCode == 200) {
            var contentType = response.headers.value('content-type')!;
            // some sites don't send favicons for the favicon
            if (contentType.startsWith("image/")) {

              iconmeta = api.LPIconMetadata(url: api.NSURL(base: "\$null", relative: iconUrl), version: 1);

              icon = api.RichLinkImageAttachmentSubstitute(mimeType: contentType, richLinkImageAttachmentSubstituteIndex: BigInt.from(attachments.length));
              attachments.add(response.data as Uint8List);
            }
          }

          if (metadata.image != null) {
            imagemeta = api.LPImageMetadata(size: "{0, 0}", url: api.NSURL(base: "\$null", relative: metadata.image!), version: 1);

            final response = await http.dio.get(metadata.image!, options: Options(responseType: ResponseType.bytes, receiveTimeout: const Duration(seconds: 15)));
            var contentType = response.headers.value('content-type')!;

            image = api.RichLinkImageAttachmentSubstitute(mimeType: contentType, richLinkImageAttachmentSubstituteIndex: BigInt.from(attachments.length));
            attachments.add(response.data as Uint8List);
          }

          linkMeta = api.LinkMeta(
            attachments: attachments,
            data: api.LPLinkMetadata(
              imageMetadata: imagemeta,
              image: image,
              originalUrl: api.NSURL(base: "\$null", relative: m.url!),
              url: api.NSURL(base: "\$null", relative: metadata.url!),
              title: metadata.title,
              summary: metadata.description,
              images: imagemeta == null ? null : await api.createImageArray(img: imagemeta),
              iconMetadata: iconmeta,
              icon: icon,
              icons: iconmeta == null ? null : await api.createIconArray(img: iconmeta),
              version: 1,
            ),
          );
        }
      }
    } catch (e, s) {
      Logger.error("Failed to generate meta $e $s");
    }
    // await Future.delayed(const Duration(seconds: 15));
    api.MessageParts parts;
    if (m.attributedBody.isNotEmpty) {
      parts = await partsFromBody(m.attributedBody.first);
    } else {
      parts = api.MessageParts(field0: [api.IndexedMessagePart(part_: api.MessagePart.text(m.text!, pushService.defaultFormat()))]);
    }
    if (m.payloadData?.appData?.first.ldText != null) {
      parts.field0.add(api.IndexedMessagePart(part_: api.MessagePart.object(m.payloadData!.appData!.first.ldText!)));
    }
    var msg = await api.newMsg(
      conversation: await chat.getConversationData(),
      sender: await chat.ensureHandle(),
      message: api.Message.message(api.NormalMessage(
        parts: parts,
        replyGuid: m.threadOriginatorGuid,
        replyPart: m.threadOriginatorGuid == null ? null : m.threadOriginatorPart,
        effect: m.expressiveSendStyleId,
        service: await getService(chat, forMessage: m),
        subject: m.subject == "" ? null : m.subject,
        app: m.payloadData == null ? null : pushService.dataToApp(m.payloadData!),
        linkMeta: linkMeta,
        voice: false,
        scheduled: m.dateScheduled != null ? api.ScheduleMode(ms: m.dateScheduled!.millisecondsSinceEpoch, schedule: true) : null,
        embeddedProfile: await pushService.getShareProfileMessageFor(chat.participants),
      )),
    );
    Logger.info("sending ${msg.id}");
    if (m.stagingGuid != null || (m.dateScheduled != null && !m.guid!.contains("temp") && !m.guid!.contains("error")) || (chat.isRpSms && m.guid != null && m.guid!.contains("error") && m.guid!.contains("temp"))) {
      msg.id = m.stagingGuid ?? m.guid!; // make sure we pass forwarded messages's original GUID so it doesn't get overwritten and marked as a different msg
    }
    if (chat.isRpSms) {
      msg.target = await getSMSTargets(msg.sender!);
    }
    m.stagingGuid = msg.id; // in case delivered comes in before sending "finishes" (also for retries, duh)
    m.save(chat: chat);
    try {
      await sendMsg(msg);
    } catch (e) {
      Logger.error(e);
      if (!chat.isRpSms || !ss.settings.isSmsRouter.value) {
        rethrow; // APN errors are fatal for non-SMS messages
      }
    }
    if (chat.isRpSms && (m.isFromMe ?? true)) {
      m.stagingGuid = msg.id;
    } else {
      m.stagingGuid = null;
      m.guid = msg.id;
    }
    await m.forwardIfNessesary(chat);
    m.save(chat: chat);
    msg.sentTimestamp = DateTime.now().millisecondsSinceEpoch;
    if (m.hasBeenForwarded) return m; // do not reflect back, it will just send it out again
    return (await pushService.reflectMessageDyn(msg)) ?? m;
  }


  @override
  bool supportsFocusStates() {
    return false;
  }

  @override
  Future<bool> markRead(Chat chat, bool notifyOthers) async {
    if (chat.isRpSms) notifyOthers = false;
    var latestMsg = chat.latestMessage.guid;
    var data = await chat.getConversationData();
    if (data.participants.length > 2) notifyOthers = false;
    if (!notifyOthers) {
      data.participants = [await chat.ensureHandle()];
    }
    var msg = await api.newMsg(
        conversation: data,
        sender: await chat.ensureHandle(),
        message: const api.Message.read());
    
    msg.id = latestMsg!;
    if (msg.id.contains("temp") || msg.id.contains("error")) {
      return true;
    }
    await sendMsg(msg);
    return true;
  }

  @override
  Future<bool> markUnread(Chat chat) async {
    var latestMsg = chat.latestMessage.guid;
    var data = await chat.getConversationData();
    data.participants = [await chat.ensureHandle()];
    var msg = await api.newMsg(
        conversation: data,
        sender: await chat.ensureHandle(),
        message: const api.Message.markUnread());
    msg.id = latestMsg!;
    if (msg.id.contains("temp") || msg.id.contains("error")) {
      return true;
    }
    if (chat.isRpSms) {
      msg.target = await getSMSTargets(msg.sender!);
    }
    await sendMsg(msg);
    return true;
  }

  @override
  Future<bool> renameChat(Chat chat, String newName) async {
    var data = await chat.getConversationData();
    var msg = await api.newMsg(
        conversation: data,
        sender: await chat.ensureHandle(),
        message: api.Message.renameMessage(api.RenameMessage(newName: newName)));
    await sendMsg(msg);
    msg.sentTimestamp = DateTime.now().millisecondsSinceEpoch;
    chat.apnTitle = newName;
    chat.ckSyncState = false;
    chat.save(updateAPNTitle: true, updateCkSyncState: true);
    inq.queue(IncomingItem(
      chat: chat,
      message: (await pushService.reflectMessageDyn(msg))!,
      type: QueueType.newMessage
    ));
    return true;
  }

  @override
  Future<bool> chatParticipant(ParticipantOp method, Chat chat, String newName) async {
    chat.groupVersion = (chat.groupVersion ?? -1) + 1;
    var data = await chat.getConversationData();
    var newParticipants = data.participants.copy();
    if (method == ParticipantOp.Add) {
      var target = await RustPushBBUtils.formatAndAddPrefix(newName);
      var valid =
          (await api.validateTargets(state: pushService.state!.client, targets: [target], sender: await chat.ensureHandle()))
              .isNotEmpty;
      if (!valid) {
        return false;
      }
      newParticipants.add(target);
    } else if (method == ParticipantOp.Remove) {
      newParticipants.remove(await RustPushBBUtils.formatAndAddPrefix(newName));
    }
    var msg = await api.newMsg(
        conversation: data,
        sender: await chat.ensureHandle(),
        message: api.Message.changeParticipants(
            api.ChangeParticipantMessage(groupVersion: chat.groupVersion!, newParticipants: newParticipants)));
    await sendMsg(msg);
    msg.sentTimestamp = DateTime.now().millisecondsSinceEpoch;
    await pushService.reflectMessageDyn(msg); // change participants does itself
    return true;
  }

  @override
  Future<bool> leaveChat(Chat chat) async {
    var handle = RustPushBBUtils.rustHandleToBB(await chat.ensureHandle());
    return await chatParticipant(ParticipantOp.Remove, chat, handle.address);
  }

  var reactionMap = {
    ReactionTypes.LOVE: api.Reaction.heart,
    ReactionTypes.LIKE: api.Reaction.like,
    ReactionTypes.DISLIKE: api.Reaction.dislike,
    ReactionTypes.LAUGH: api.Reaction.laugh,
    ReactionTypes.EMPHASIZE: api.Reaction.emphasize,
    ReactionTypes.QUESTION: api.Reaction.question,
  };

  @override
  Future<Message> sendTapback(
      Chat chat, Message selected, String reaction, int? repPart) async {
    if (!chat.isIMessage) {
      String text;
      if (ReactionTypes.reactionToVerb.containsKey(reaction)) {
        var time = ReactionTypes.reactionToVerb[reaction]!;
        // capitalize first letter
        text = "${time[0].toUpperCase()}${time.substring(1).toLowerCase()}";
      } else {
        text = reaction.startsWith("-") ? "Removed ${reaction.substring(1)} from" : "Reacted $reaction to";
      }
      var annotations = AttributedBody.raw("$text “${selected.text}”");
      final _message = Message(
        text: annotations.string,
        dateCreated: DateTime.now(),
        hasAttachments: false,
        isFromMe: true,
        associatedMessageGuid: selected.guid,
        associatedMessagePart: 0,
        associatedMessageType: ReactionTypes.reactionToVerb.containsKey(reaction) ? reaction : reaction.startsWith("-") ? "-${ReactionTypes.EMOJI}" : ReactionTypes.EMOJI,
        associatedMessageEmoji: ReactionTypes.reactionToVerb.containsKey(reaction) ? null : reaction.startsWith("-") ? reaction.substring(1) : reaction,
        handleId: 0,
        hasDdResults: true,
        attributedBody: [
          if (annotations.string.isNotEmpty)
            annotations
        ],
      );
      _message.generateTempGuid();
      return await sendMessage(chat, _message);
    }
    var enabled = !reaction.startsWith("-");
    reaction = enabled ? reaction : reaction.substring(1);
    var msg = await api.newMsg(
        conversation: await chat.getConversationData(),
        sender: await chat.ensureHandle(),
        message: api.Message.react(api.ReactMessage(
            toUuid: selected.guid!,
            toPart: repPart ?? 0,
            embeddedProfile: await pushService.getShareProfileMessageFor(chat.participants),
            toText: selected.text ?? "",
            reaction: api.ReactMessageType.react(reaction: reactionMap[reaction]?.call() ?? api.Reaction.emoji(reaction), enable: enabled))));
    await sendMsg(msg);
    msg.sentTimestamp = DateTime.now().millisecondsSinceEpoch;
    return (await pushService.reflectMessageDyn(msg))!;
  }

  @override
  Future<Message> updateMessage(
        Chat chat, Message old, PayloadData newData, PlatformFile? newImage, bool isMeta, String? notifText) async {
    api.Attachment? attachment;
    if (newImage != null) {
      String data = await DefaultAssetBundle.of(Get.context!).loadString("assets/rustpush/uti-map.json");
      final utiMap = jsonDecode(data);
      var att = Attachment(
        isOutgoing: true,
        mimeType: mime(newImage.path ?? newImage.name),
        uti: utiMap[mime(newImage.path ?? newImage.name)] ?? "public.data",
        bytes: newImage.bytes,
        transferName: newImage.name,
        totalBytes: newImage.size,
        sourcePath: newImage.path,
        guid: uuid.v4().toString(),
      );
      await att.writeToDisk();
      var stream = api.uploadAttachment(
          aps: pushService.state!.conn,
          path: att.getFile().path!,
          mime: att.mimeType ?? "application/octet-stream",
          uti: att.uti ?? "public.data",
          name: att.transferName!);
      await for (final event in stream) {
        if (event.attachment != null) {
          Logger.info("upload finish");
          attachment = event.attachment;
          att.metadata = {"rustpush": await api.saveAttachment(att: attachment!)};
        } else {
          Logger.info("upload progress ${event.prog} of ${event.total}");
        }
      }
      File(att.path).deleteSync();
    }

    var msg = await api.newMsg(
        conversation: await chat.getConversationData(),
        sender: await chat.ensureHandle(),
        message: api.Message.react(api.ReactMessage(
            toUuid: isMeta ? old.guid! : old.amkSessionId!,
            toText: notifText ?? "",
            embeddedProfile: await pushService.getShareProfileMessageFor(chat.participants),
            reaction: api.ReactMessageType.extension_(
              spec: pushService.dataToApp(newData),
              body: api.MessageParts(field0: [
                api.IndexedMessagePart(part_: api.MessagePart.object(newData.appData![0].ldText ?? "")),
                if (attachment != null)
                api.IndexedMessagePart(part_: api.MessagePart.attachment(attachment)),
              ]),
              isMeta: isMeta,
            ))));
    await sendMsg(msg);
    msg.sentTimestamp = DateTime.now().millisecondsSinceEpoch;
    return (await pushService.reflectMessageDyn(msg))!;
  }

  @override
  Future<Message?> unsend(Message msgObj, MessagePart part) async {
    var msg = await api.newMsg(
        sender: await msgObj.chat.target!.ensureHandle(),
        conversation: await msgObj.chat.target!.getConversationData(),
        message: api.Message.unsend(api.UnsendMessage(tuuid: msgObj.guid!, editPart: part.part)));
    await sendMsg(msg);

    if (msgObj.ckRecordId != null) {
      await api.saveMessages(cloudMessagesClient: pushService.state!.icloudServices!.cloudMessagesClient!, messages: {msgObj.ckRecordId!: msgObj.toCloud(true)});
    }

    return await pushService.reflectMessageDyn(msg);
  }

  @override
  Future<Message?> edit(Message msgObj, AttributedBody text, int part) async {
    if (msgObj.dateScheduled != null) {
      msgObj.attributedBody[0] = text;
      msgObj.messageSummaryInfo = [];
      return await sendMessage(msgObj.getChat()!, msgObj);
    }

    var msg = await api.newMsg(
        conversation: await msgObj.chat.target!.getConversationData(),
        sender: await msgObj.chat.target!.ensureHandle(),
        message: api.Message.edit(api.EditMessage(
            tuuid: msgObj.guid!,
            editPart: part,
            newParts: await partsFromBody(text))));
    await sendMsg(msg);

    if (msgObj.ckRecordId != null) {
      await pushService.uploadMessages([msgObj], [], {}, true);
    }

    msg.sentTimestamp = DateTime.now().millisecondsSinceEpoch;
    return await pushService.reflectMessageDyn(msg);
  }

  @override
  HttpService? getRemoteService() {
    return null;
  }

  @override
  bool canLeaveChat() {
    return true;
  }

  @override
  bool canEditUnsend() {
    return true;
  }

  @override
  Future<bool> downloadLivePhoto(Attachment attachment, String target,
      {void Function(int p1, int p2)? onReceiveProgress, CancelToken? cancelToken}) async {
    var rustAttachment = api.restoreAttachment(data: attachment.metadata!["myIris"]);
    var filePath = "${attachment.directory}/$target";
    if (!canonicalize(filePath).startsWith(canonicalize(attachment.directory))) {
      throw Exception("Path traversal detected, are we under attack??");
    }
    var stream = api.downloadAttachment(aps: pushService.state!.conn, attachment: rustAttachment, path: filePath);
    await for (final event in stream) {
      if (onReceiveProgress != null) {
        onReceiveProgress(event.prog, event.total);
      }
    }
    final file = PlatformFile(
      name: target,
      size: await rustAttachment.getSize(),
      path: "${attachment.directory}/$target"
    );
    await as.saveToDisk(file);

    return true;
  }

  @override
  bool canSchedule() {
    return false; // don't want to write a local db for scheduled messages rn
  }

  @override
  bool supportsFindMy() {
    return pushService.state?.icloudServices?.fmfd != null;
  }

  @override
  void startedTyping(Chat c, [iMessageAppData? appdata]) async {
    if (c.isRpSms) return;
    var msg = await api.newMsg(
      conversation: await c.getConversationData(),
      sender: await c.ensureHandle(),
      message: api.Message.typing(true, appdata?.appIcon != null ? api.TypingApp(
        bundleId: appdata!.bundleId, 
        icon: base64Decode(appdata.appIcon!),
      ) : null)
    );
    await sendMsg(msg, waitForResource: false); // typing state is stale after a reconnect
  }

  @override
  void stoppedTyping(Chat c) async {
    if (c.isRpSms) return;
    var msg = await api.newMsg(
      conversation: await c.getConversationData(),
      sender: await c.ensureHandle(),
      message: const api.Message.typing(false)
    );
    await sendMsg(msg, waitForResource: false);
  }

  @override
  void updateTypingStatus(Chat c) {  }

  @override
  Future<bool> handleiMessageState(String address) async {
    var handle = await getDefaultHandle();
    var formatted = await RustPushBBUtils.formatAndAddPrefix(address);
    List<String> available = await pushService.doValidateTargets([formatted], handle);
    return available.isNotEmpty;
  }

}

class RustPushService extends GetxService {
  api.SharedPushState? state;

  Mixpanel? mixpanel;

  var disableOutgoingSms = false;

  Map<String, api.Attachment> attachments = {};

  Future<List<String>> doValidateTargets(List<String> targets, String handle) async {
    List<String> available;
    try {
      available = await api.validateTargets(state: pushService.state!.client, targets: targets, sender: handle);
    } catch (e) {
      if (e is AnyhowException) {
        if (e.message.contains("Failed to generate resource") && e.message.contains("not retrying")) {
          pushService.markFailedToLogin();
        }
      }
      rethrow;
    }
    return available;
  }

  StickerData stickerFromDart(api.PartExtension_Sticker ext) {
    return StickerData(
      msgWidth: ext.msgWidth, 
      rotation: ext.rotation, 
      sai: ext.sai.toInt(), 
      scale: ext.scale, 
      update: ext.update, 
      sli: ext.sli.toInt(), 
      normalizedX: ext.normalizedX, 
      normalizedY: ext.normalizedY, 
      version: ext.version.toInt(), 
      hash: ext.hash, 
      safi: ext.safi.toInt(), 
      effectType: ext.effectType, 
      stickerId: ext.stickerId
    );
  }

  Future<void> updateChatParticipants(Chat c, api.MessageInst myMsg, List<String> oldParticipants, List<String> newParticipants) async {
    var myHandles = await api.getHandles(state: pushService.state!.client);
    var newP = newParticipants.filter((p) => !oldParticipants.contains(p) && !myHandles.contains(p));
    var delP = oldParticipants.filter((p) => !newParticipants.contains(p));
    if (newP.isEmpty && delP.isEmpty) return; // nothing to do
    c.handles.clear();
    var (_, participantHandles) = await RustPushBBUtils.rustParticipantsToBB(newParticipants);
    c.handles.addAll(participantHandles);
    c.handles.applyToDb();
    c.handlesChanged();
    c = c.getParticipants();
    c.save();

    var useId = myMsg.message is api.Message_ChangeParticipants;

    for (var item in newP) {
      var bb = RustPushBBUtils.rustHandleToBB(item);
      var msg = Message(
        guid: useId ? myMsg.id : uuid.v4(),
        isFromMe: myHandles.contains(myMsg.sender),
        handleId: RustPushBBUtils.rustHandleToBB(myMsg.sender!).originalROWID!,
        dateCreated: DateTime.fromMillisecondsSinceEpoch(myMsg.sentTimestamp),
        itemType: 1,
        groupActionType: 0,
        otherHandle: bb.originalROWID
      );

      inq.queue(IncomingItem(
        chat: c,
        message: msg,
        type: QueueType.newMessage
      ));
    }

    for (var item in delP) {
      var bb = RustPushBBUtils.rustHandleToBB(item);
      var personDidLeave = item == myMsg.sender;
      var msg = Message(
        guid: useId ? myMsg.id : uuid.v4(),
        isFromMe: myHandles.contains(myMsg.sender),
        handleId: RustPushBBUtils.rustHandleToBB(myMsg.sender!).originalROWID!,
        dateCreated: DateTime.fromMillisecondsSinceEpoch(myMsg.sentTimestamp),
        itemType: personDidLeave ? 3 : 1,
        groupActionType: personDidLeave ? 0 : 1,
        otherHandle: bb.originalROWID
      );

      inq.queue(IncomingItem(
        chat: c,
        message: msg,
        type: QueueType.newMessage
      ));
    }
  }

  Future<(AttributedBody, String, List<Attachment?>)> indexedPartsToAttributedBodyDyn(
      List<api.IndexedMessagePart> parts, String msgId, AttributedBody? existingBody) async {
    var bodyString = "";
    List<Run> body = existingBody?.runs.copy() ?? [];
    List<Attachment> attachments = [];
    var index = -1;
    var addedIndicies = [];
    for (var indexedParts in parts) {
      index += 1;
      var part = indexedParts.part_;
      var fieldIdx = indexedParts.idx ?? body.count((i) => i.attributes?.attachmentGuid != null); // only count attachments increment parts by default
      // remove old elements
      if (!addedIndicies.contains(fieldIdx)) {
        body.removeWhere((element) => element.attributes?.messagePart == fieldIdx);
        addedIndicies.add(fieldIdx);
      }
      if (part is api.MessagePart_Text) {
        api.TextFlags? flags;
        int? textEffect;
        if (part.field1 is api.TextFormat_Flags) {
          flags = (part.field1 as api.TextFormat_Flags).field0;
        } else if (part.field1 is api.TextFormat_Effect) {
          var effect = part.field1 as api.TextFormat_Effect;
          Map<api.TextEffect, int> invertedEffectMap = {
            api.TextEffect.big: Attributes.BIG,
            api.TextEffect.small: Attributes.SMALL,
            api.TextEffect.shake: Attributes.SHAKE,
            api.TextEffect.nod: Attributes.NOD,
            api.TextEffect.explode: Attributes.EXPLODE,
            api.TextEffect.ripple: Attributes.RIPPLE,
            api.TextEffect.bloom: Attributes.BLOOM,
            api.TextEffect.jitter: Attributes.JITTER,
          };
          textEffect = invertedEffectMap[effect.field0];
        }
        body.add(Run(
          range: [bodyString.length, part.field0.length],
          attributes: Attributes(
            messagePart: fieldIdx,
            textEffect: textEffect,
            bold: flags?.bold,
            italic: flags?.italic,
            strikethrough: flags?.strikethrough,
            underline: flags?.underline,
          )
        ));
        bodyString += part.field0;
      } else if (part is api.MessagePart_Mention) {
        body.add(Run(
          range: [bodyString.length, part.field1.length],
          attributes: Attributes(
            messagePart: fieldIdx,
            mention: part.field0
          )
        ));
        bodyString += part.field1;
      } else if (part is api.MessagePart_Attachment) {
        if (part.field0.iris) {
          continue;
        }
        if (part.field0.mime == "application/smil") {
          continue; // who needs display info amirite?
        }
        api.Attachment? myIris;
        var next = parts.elementAtOrNull(index + 1);
        if (next != null && next.part_ is api.MessagePart_Attachment) {
          var nextA = next.part_ as api.MessagePart_Attachment;
          if (nextA.field0.iris) {
            myIris = nextA.field0;
          }
        }

        StickerData? stickerData;
        if (indexedParts.ext != null && indexedParts.ext is api.PartExtension_Sticker) {
          var ext = indexedParts.ext! as api.PartExtension_Sticker;
          stickerData = stickerFromDart(ext);
        }
        
        var myUuid = "${msgId}_$fieldIdx";
        attachments.add(Attachment(
          guid: myUuid,
          uti: part.field0.utiType,
          mimeType: part.field0.mime,
          isOutgoing: false,
          transferName: part.field0.name.replaceAll(RegExp(r'/'), "_").replaceAll(RegExp(r'\\'), "_"),
          totalBytes: await part.field0.getSize(),
          hasLivePhoto: myIris != null,
          metadata: {"rustpush": await api.saveAttachment(att: part.field0), "myIris": myIris != null ? await api.saveAttachment(att: myIris) : null},
        ));
        body.add(Run(
          range: [bodyString.length, 1],
          attributes: Attributes(
            attachmentGuid: myUuid,
            messagePart: body.length,
            stickerData: stickerData,
          )
        ));
        bodyString += " ";
      }
    }
    return (AttributedBody(string: bodyString, runs: body), bodyString, attachments);
  }

  api.ExtensionApp dataToApp(PayloadData data) {
    var appData = data.appData!.first;
    return api.ExtensionApp(
      name: appData.appName!,
      appId: appData.appId,
      bundleId: appData.bundleId,
      balloon: api.Balloon(
        icon: appData.appIcon != null && appData.appIcon!.length < 100000 ? base64Decode(appData.appIcon!) : null,
        url: appData.url!,
        session: appData.session,
        ldText: appData.ldText,
        isLive: appData.isLive ?? false,
        layout: appData.userInfo != null ? api.BalloonLayout.templateLayout(
          imageSubtitle: appData.userInfo!.imageSubtitle ?? "",
          imageTitle: appData.userInfo!.imageTitle ?? "",
          caption: appData.userInfo!.caption ?? "", 
          secondarySubcaption: appData.userInfo!.secondarySubcaption ?? "", 
          tertiarySubcaption: appData.userInfo!.tertiarySubcaption ?? "", 
          subcaption: appData.userInfo!.subcaption ?? "", 
          class_: api.NSDictionaryClass.nsDictionary,
        ) : null,
      )
    );
  }

  PayloadData appToData(api.ExtensionApp app) {
    var layout = app.balloon!.layout as api.BalloonLayout_TemplateLayout?;
    return PayloadData(
      type: constants.PayloadType.app,
      urlData: null,
      appData: [
        iMessageAppData(
          appName: app.name,
          ldText: app.balloon?.ldText,
          url: app.balloon?.url,
          session: app.balloon?.session,
          appIcon: app.balloon?.icon != null ? base64Encode(app.balloon!.icon!) : null,
          appId: app.appId,
          isLive: app.balloon?.isLive ?? false,
          userInfo: layout != null ? UserInfo(
            imageSubtitle: layout.imageSubtitle,
            imageTitle: layout.imageTitle,
            caption: layout.caption,
            secondarySubcaption: layout.secondarySubcaption,
            subcaption: layout.subcaption,
            tertiarySubcaption: layout.tertiarySubcaption,
          ) : null,
        )
      ]
    );
  }

  MediaMetadata? rpToMedia(api.LPImageMetadata? imagemeta) {
    if (imagemeta == null) return null;
    var data = Size(double.parse(imagemeta.size.split(",").first.toString().numericOnly()), double.parse(imagemeta.size.split(",").last.toString().numericOnly()));
    return MediaMetadata(
      size: data,
      url: imagemeta.url.relative
    );
  }

  MediaMetadata? rpIToMedia(api.LPIconMetadata? imagemeta) {
    if (imagemeta == null) return null;
    return MediaMetadata(
      size: null,
      url: imagemeta.url.relative
    );
  }

  String linkToBalloonBundleId(api.LinkMeta link) {
    if (link.data.specialization2 is api.LPSpecializationMetadata_LPPasswordsInviteMetadata) {
      return "com.openbubbles.passwords";
    }
    return "com.apple.messages.URLBalloonProvider";
  }

  PayloadData linkToData(api.LinkMeta link) {
    if (link.data.specialization2 is api.LPSpecializationMetadata_LPPasswordsInviteMetadata) {
      var data = link.data.specialization2 as api.LPSpecializationMetadata_LPPasswordsInviteMetadata;
      return PayloadData(
        type: constants.PayloadType.app,
        urlData: null,
        appData: [
          iMessageAppData(
            appName: "Shared Passwords",
            ldText: "You have been invited to join the group “${data.groupName}”.",
            url: data.urlParameters,
          )
        ],
      );
    }
    return PayloadData(
      type: constants.PayloadType.url,
      urlData: [
        UrlPreviewData(
          imageMetadata: rpToMedia(link.data.imageMetadata),
          videoMetadata: null,
          iconMetadata: rpIToMedia(link.data.iconMetadata),
          originalUrl: link.data.originalUrl?.relative,
          url: link.data.url?.relative,
          title: link.data.title,
          summary: link.data.summary,
          siteName: link.data.title,
        )
      ],
      appData: null,
    );
  }

  Future<Message?> reflectMessageDyn(api.MessageInst myMsg) async {
    Logger.info("reflecting msg");
    var chat = myMsg.conversation != null ? await chatForMessage(myMsg) : null;
    var myHandles = (await api.getHandles(state: pushService.state!.client));
    if (myMsg.message is api.Message_NotifyAnyways) {
      var msgObj = Message.findOne(guid: myMsg.id)!;
      msgObj.wasDeliveredQuietly = false;
      Logger.info("Got notify anyways message");
      MessageHelper.handleNotification(msgObj, msgObj.chat.target!, findExisting: false, notifyAnyways: true);
      return msgObj;
    } else if (myMsg.message is api.Message_Message) {
      var innerMsg = myMsg.message as api.Message_Message;
      var attributedBodyData = await indexedPartsToAttributedBodyDyn(innerMsg.field0.parts.field0, myMsg.id, null);
      var sender = myMsg.sender;
      
      bool hasBeenForwarded = false;
      var staging = false;
      var tempGuid = "temp-${randomString(8)}";
      if (innerMsg.field0.service is api.MessageType_SMS) {
        var smsServ = innerMsg.field0.service as api.MessageType_SMS;
        if (smsServ.fromHandle != null) {
          sender = smsServ.fromHandle;
        }
        staging = myHandles.contains(sender);
        var myPhoneHandles = await api.getMyPhoneHandles(state: pushService.state!.client);
        if (!myPhoneHandles.contains(smsServ.usingNumber)) {
          // this is a forwarded message from someone else
          hasBeenForwarded = true;
        }
        if (staging) {
          var found = Message.findOne(guid: myMsg.id);
          if (found != null && found.guid != null) {
            tempGuid = found.guid!;
          }
        }
      }

      var msg = Message(
        guid: staging ? tempGuid : myMsg.id,
        stagingGuid: staging ? myMsg.id : null,
        text: attributedBodyData.$2,
        isFromMe: myHandles.contains(sender),
        handle: RustPushBBUtils.rustHandleToBB(sender!),
        dateCreated: DateTime.fromMillisecondsSinceEpoch(myMsg.sentTimestamp),
        dateScheduled: innerMsg.field0.scheduled != null ? DateTime.fromMillisecondsSinceEpoch(innerMsg.field0.scheduled!.ms) : null,
        subject: innerMsg.field0.subject,
        threadOriginatorPart: innerMsg.field0.replyPart?.toString(),
        threadOriginatorGuid: innerMsg.field0.replyGuid,
        expressiveSendStyleId: innerMsg.field0.effect,
        attributedBody: [attributedBodyData.$1],
        attachments: attributedBodyData.$3,
        hasAttachments: attributedBodyData.$3.isNotEmpty,
        balloonBundleId: innerMsg.field0.app?.balloon != null ? innerMsg.field0.app?.bundleId : innerMsg.field0.linkMeta != null ? linkToBalloonBundleId(innerMsg.field0.linkMeta!) : null,
        payloadData: innerMsg.field0.app?.balloon != null ? appToData(innerMsg.field0.app!) : innerMsg.field0.linkMeta != null ? linkToData(innerMsg.field0.linkMeta!) : null,
        amkSessionId: innerMsg.field0.app?.balloon != null ? myMsg.id : null,
        verificationFailed: myMsg.verificationFailed,
        hasApplePayloadData: innerMsg.field0.app?.balloon != null,
        hasBeenForwarded: hasBeenForwarded,
      );

      if (innerMsg.field0.service is api.MessageType_SMS && chat != null) {
        msg.inferReaction(chat);
      }
      return msg;
    } else if (myMsg.message is api.Message_RenameMessage) {
      var msg = myMsg.message as api.Message_RenameMessage;
      if (myMsg.verificationFailed) return null;

      chat!.ckSyncState = false;
      chat.save(updateCkSyncState: true);
      
      return Message(
        guid: myMsg.id,
        isFromMe: myHandles.contains(myMsg.sender),
        handleId: RustPushBBUtils.rustHandleToBB(myMsg.sender!).originalROWID!,
        dateCreated: DateTime.fromMillisecondsSinceEpoch(myMsg.sentTimestamp),
        itemType: 2,
        groupActionType: 2,
        groupTitle: msg.field0.newName,
      );
    } else if (myMsg.message is api.Message_ChangeParticipants) {
      var msg = myMsg.message as api.Message_ChangeParticipants;
      if (myMsg.verificationFailed) return null;
      await updateChatParticipants(chat!, myMsg, myMsg.conversation!.participants, msg.field0.newParticipants);
      chat.groupVersion = msg.field0.groupVersion;
      chat.ckSyncState = false;
      chat.save(updateGroupVersion: true, updateCkSyncState: true);
      return null;
    } else if (myMsg.message is api.Message_IconChange) {
      var innerMsg = myMsg.message as api.Message_IconChange;
      if (!chat!.lockChatIcon && (chat.groupVersion ?? 0) < innerMsg.field0.groupVersion) {
        var file = innerMsg.field0.file;
        chat.groupVersion = innerMsg.field0.groupVersion;
        chat.ckSyncState = false;
        if (file != null) {
          var path = chat.getIconPath(file.size);
          var stream = api.downloadMmcs(aps: pushService.state!.conn, attachment: file, path: path);
          await for (final event in stream) {
            Logger.info("Downloaded attachment ${event.prog} bytes of ${event.total}");
          }
          chat.customAvatarPath = path;
        } else {
          chat.removeProfilePhoto();
        }
        chat.updateAttachmentGuid(myMsg.id);
        chat.save(updateCustomAvatarPath: true, updateGroupVersion: true, updateCkSyncState: true, updateAttachmentGuid: true);
      }
      return Message(
        guid: myMsg.id,
        isFromMe: myHandles.contains(myMsg.sender),
        handleId: RustPushBBUtils.rustHandleToBB(myMsg.sender!).originalROWID!,
        dateCreated: DateTime.fromMillisecondsSinceEpoch(myMsg.sentTimestamp),
        itemType: 3,
        groupActionType: 1,
      );
    } else if (myMsg.message is api.Message_React) {
      var msg = myMsg.message as api.Message_React;
      if (msg.field0.embeddedProfile != null) {
        handleSharedProfile(msg.field0.embeddedProfile!, myMsg.sender!, chat?.participants ?? []);
      }

      String? reaction;
      String? emoji;
      api.ExtensionApp? app;
      (AttributedBody, String, List<Attachment?>)? attributedBodyData;
      if (msg.field0.reaction is api.ReactMessageType_React) {
        var msgType = msg.field0.reaction as api.ReactMessageType_React;
        if (msgType.reaction is api.Reaction_Heart) {
          reaction = ReactionTypes.LOVE;
        } else if (msgType.reaction is api.Reaction_Like) {
          reaction = ReactionTypes.LIKE;
        } else if (msgType.reaction is api.Reaction_Dislike) {
          reaction = ReactionTypes.DISLIKE;
        } else if (msgType.reaction is api.Reaction_Laugh) {
          reaction = ReactionTypes.LAUGH;
        } else if (msgType.reaction is api.Reaction_Emphasize) {
          reaction = ReactionTypes.EMPHASIZE;
        } else if (msgType.reaction is api.Reaction_Question) {
          reaction = ReactionTypes.QUESTION;
        } else if (msgType.reaction is api.Reaction_Emoji) {
          reaction = ReactionTypes.EMOJI;
          emoji = (msgType.reaction as api.Reaction_Emoji).field0;
        } else if (msgType.reaction is api.Reaction_Sticker) {
          var sticker = msgType.reaction as api.Reaction_Sticker;
          app = sticker.spec;
          attributedBodyData = await indexedPartsToAttributedBodyDyn(sticker.body.field0, myMsg.id, null);
          reaction = ReactionTypes.STICKERBACK;
        }
        if (!msgType.enable) {
          reaction = "-$reaction";
        }
      } else if (msg.field0.reaction is api.ReactMessageType_Extension) {
        var msgType = msg.field0.reaction as api.ReactMessageType_Extension;
        app = msgType.spec;
        attributedBodyData = await indexedPartsToAttributedBodyDyn(msgType.body.field0, myMsg.id, null);
        if (msgType.isMeta) {
          reaction = "meta";
        }
        if (msgType.spec.balloon != null && !msgType.isMeta) {
          // copy over assets
          reaction = null;

          final query = (Database.messages.query(Message_.amkSessionId.equals(msg.field0.toUuid))
            ..order(Message_.dateCreated, flags: Order.descending))
          .build();
          query.limit = 2;

          final messages = query.find();
          query.close();

          final original = messages.firstWhere((msg) => (msg.stagingGuid ?? msg.guid) != myMsg.id);

          original.fetchAssociatedMessages();

          // for polls, move associated messages (votes) to latest message when updating
          for (var associated in original.associatedMessages) {
            if (associated.associatedMessageType != null) continue;
            associated.associatedMessageGuid = myMsg.id;
            associated.save();
          }
          
          // allow updating image
          attributedBodyData = (attributedBodyData.$3.isEmpty ? original.attributedBody[0] : attributedBodyData.$1, original.text!, attributedBodyData.$3.isEmpty ? original.dbAttachments : attributedBodyData.$3);
          var tag = es.getLatest(msg.field0.toUuid);
          // updates cached value; we are latest
          if (tag.firstOrNull != myMsg.id) {
            tag.insert(0, myMsg.id);
            if (tag.length > 3) {
              tag.removeAt(3);
            }
          }

          if (chat != null && cm.activeChat?.chat.guid == chat.guid) {
            ms(original.chat.target!.guid).updateMessage(original);
            mwc(original).updateWidgets<MessageHolder>(null);
          }
        } else if (!msgType.isMeta) {
          reaction = "sticker";
        }
      } else {
        throw Exception("bad type!");
      }
      var message = Message(
        guid: myMsg.id,
        isFromMe: myHandles.contains(myMsg.sender),
        handleId: RustPushBBUtils.rustHandleToBB(myMsg.sender!).originalROWID!,
        dateCreated: DateTime.fromMillisecondsSinceEpoch(myMsg.sentTimestamp),
        associatedMessagePart: msg.field0.toPart,
        associatedMessageGuid: reaction == null ? null : msg.field0.toUuid,
        associatedMessageType: reaction == "meta" ? null : reaction,
        associatedMessageEmoji: emoji,
        text: attributedBodyData?.$2,
        attributedBody: attributedBodyData != null ? [attributedBodyData.$1] : [],
        attachments: attributedBodyData?.$3 ?? [],
        hasAttachments: attributedBodyData?.$3.isNotEmpty ?? false,
        balloonBundleId: app?.bundleId,
        payloadData: app?.balloon != null ? appToData(app!) : null,
        amkSessionId: app?.balloon != null && reaction == null ? msg.field0.toUuid : null,
        verificationFailed: myMsg.verificationFailed,
        hasApplePayloadData: app?.balloon != null,
      );

      if (app?.balloon != null) {
        es.informUpdate(message);
      }

      return message;
    } else if (myMsg.message is api.Message_Unsend) {
      var msg = myMsg.message as api.Message_Unsend;
      var msgObj = Message.findOne(guid: msg.field0.tuuid)!;
      msgObj.verificationFailed = myMsg.verificationFailed;
      msgObj.dateEdited = DateTime.now();
      var summaryInfo = msgObj.messageSummaryInfo.firstOrNull;
      if (summaryInfo == null) {
        summaryInfo = MessageSummaryInfo.empty();
        msgObj.messageSummaryInfo.add(summaryInfo);
      }
      summaryInfo.retractedParts.add(msg.field0.editPart);
      return msgObj;
    } else if (myMsg.message is api.Message_Edit) {
      var msg = myMsg.message as api.Message_Edit;
      var msgObj = Message.findOne(guid: msg.field0.tuuid);
      if (msgObj == null) {
        throw Exception("Cannot find msg!");
      }

      msgObj.verificationFailed = myMsg.verificationFailed;
      
      var attributedBodyDataInclusive = await indexedPartsToAttributedBodyDyn(
          msg.field0.newParts.field0, myMsg.id, msgObj.attributedBody.firstOrNull);
      var attributedBodyEdited = await indexedPartsToAttributedBodyDyn(msg.field0.newParts.field0, myMsg.id, null);
      msgObj.text = attributedBodyDataInclusive.$2;
      msgObj.dateEdited = DateTime.now();

      var summaryInfo = msgObj.messageSummaryInfo.firstOrNull;
      if (summaryInfo == null) {
        summaryInfo = MessageSummaryInfo.empty();
        msgObj.messageSummaryInfo.add(summaryInfo);
      }
      if (!summaryInfo.editedParts.contains(msg.field0.editPart)) {
        summaryInfo.editedParts.add(msg.field0.editPart);
      }

      var contentMap = summaryInfo.editedContent;
      if (contentMap[msg.field0.editPart.toString()] == null) {
        contentMap[msg.field0.editPart.toString()] = [
          EditedContent(
            date: (msgObj.dateCreated?.millisecondsSinceEpoch ?? 0).toDouble(),
            text: Content(values: msgObj.attributedBody)
          )
        ];
      }

      contentMap[msg.field0.editPart.toString()]!.add(
        EditedContent(
          date: myMsg.sentTimestamp.toDouble(),
          text: Content(values: [attributedBodyEdited.$1])
        )
      );

      msgObj.attributedBody = [attributedBodyDataInclusive.$1];
      return msgObj;
    }
    throw Exception("bad message type! ${myMsg.message}");
  }

  File fileForAsset(String path, api.PosterAsset asset, String n, {bool friendly = false}) {
    var name = "${asset.uuid}_$n";
    if (friendly) {
      File f2 = File("$path/${sha256.convert(name.codeUnits).toString()}.png");
      if (f2.existsSync()) {
        return f2;
      }
    }
    return File("$path/${sha256.convert(name.codeUnits).toString()}");
  }

  String getService(api.MessageInst msg) {
    if (msg.message is api.Message_Message) {
      var m = msg.message as api.Message_Message;
      if (m.field0.service is api.MessageType_SMS) {
        return "SMS";
      }
    }
    return "iMessage";
  }

  // finds chat for message. Use over `Chat.findByRust` for incoming messages
  // to handle after conversation changes (renames, participants)
  Future<Chat> chatForMessageInner(api.MessageInst myMsg, {bool routingStub = false}) async {
    // find existing saved message and use that chat if we're getting a replay
    var existing = Message.findOne(guid: myMsg.id);
    if (myMsg.message is api.Message_Edit) {
      var msg = myMsg.message as api.Message_Edit;
      existing = Message.findOne(guid: msg.field0.tuuid);
    } else if (myMsg.message is api.Message_Unsend) {
      var msg = myMsg.message as api.Message_Unsend;
      existing = Message.findOne(guid: msg.field0.tuuid);
    }
    if (existing?.getChat() != null) {
      return existing!.getChat()!;
    }
    if (myMsg.conversation?.afterGuid != null) {
      var existing = Message.findOne(guid: myMsg.conversation!.afterGuid!);
      if (existing?.getChat() != null) {
        var result = existing!.getChat()!;
        if (myMsg.sender == null || result.participants.contains(RustPushBBUtils.rustHandleToBB(myMsg.sender!))) return existing.getChat()!;
      }
    }
    if (myMsg.message is api.Message_RenameMessage) {
      var found = (await Chat.findByRust(myMsg.conversation!, getService(myMsg), soft: true));
      if (found == null) {
        // try using the new name
        var msg = myMsg.message as api.Message_RenameMessage;
        myMsg.conversation!.cvName = msg.field0.newName;
        return (await Chat.findByRust(myMsg.conversation!, getService(myMsg)))!;
      } else {
        return found;
      }
    }
    if (myMsg.message is api.Message_ChangeParticipants) {
      var found = (await Chat.findByRust(myMsg.conversation!, getService(myMsg), soft: true));
      if (found == null) {
        // try using the new participants
        var msg = myMsg.message as api.Message_ChangeParticipants;
        myMsg.conversation!.participants = msg.field0.newParticipants;
        return (await Chat.findByRust(myMsg.conversation!, getService(myMsg)))!;
      } else {
        return found;
      }
    }
    if (myMsg.message is api.Message_Message) {
      var message = myMsg.message as api.Message_Message;
      var service = message.field0.service;
      if (service is api.MessageType_SMS) {
        // remove any potential us from the conversation it won't recognize the telephone as a "handle"
        myMsg.conversation?.participants.remove(service.usingNumber);
      }
    }
    return (await Chat.findByRust(myMsg.conversation!, getService(myMsg), routingStub: routingStub))!;
  }

  Future<Chat> chatForMessage(api.MessageInst myMsg) async {
    var routingStub = false;
    if (myMsg.message is api.Message_Message) {
        var message = myMsg.message as api.Message_Message;
        var service = message.field0.service;
        var myNumbers = await api.getMyPhoneHandles(state: pushService.state!.client);
        if (service is api.MessageType_SMS) {
          if (myNumbers.contains(service.usingNumber)) {
            routingStub = true; // we are just forwarding this, search for routing stubs
          }
        }
      }
    var result = await chatForMessageInner(myMsg, routingStub: routingStub);
    if (myMsg.conversation != null) {
      // conformance stuff
      if (myMsg.conversation!.senderGuid != null && !result.guidRefs.contains(myMsg.conversation!.senderGuid!)) {
        result.guidRefs.add(myMsg.conversation!.senderGuid!);
        result.save(updateGuidRefs: true);
      }
      var (mine, _) = await RustPushBBUtils.rustParticipantsToBB(myMsg.conversation!.participants);
      if (mine.isNotEmpty && !mine.contains(result.usingHandle)) {
        result.usingHandle = mine[0];
        result.save(updateUsingHandle: true);
      }
      if (myMsg.message is api.Message_Message) {
        var message = myMsg.message as api.Message_Message;
        var service = message.field0.service;
        if (service is api.MessageType_SMS) {
          if (service.usingNumber != result.usingHandle) {
            Logger.info("Mismatch between chat handle ${result.usingHandle} and incoming handle ${service.usingNumber}, updating chat handle!");
            result.usingHandle = service.usingNumber;
            result.save(updateUsingHandle: true);
          }
        }
      }
      if (myMsg.message is! api.Message_ChangeParticipants) {
        var isNormal = myMsg.message is api.Message_Message;
        var isSms = isNormal && (myMsg.message as api.Message_Message).field0.service is api.MessageType_SMS;
        if (!isSms) {
          var data = await result.getConversationData();
          // make sure we are in consensus
          await updateChatParticipants(result, myMsg, data.participants, myMsg.conversation!.participants);
        }
      }
      if (myMsg.message is! api.Message_RenameMessage && myMsg.conversation!.cvName != null && myMsg.conversation!.cvName != result.apnTitle) {
        if (!result.lockChatName) {
          result.displayName = myMsg.conversation!.cvName;
        }
        result.apnTitle = myMsg.conversation!.cvName;
        myMsg.conversation?.cvName = myMsg.conversation!.cvName;
        result.save(updateDisplayName: true, updateAPNTitle: true);

        var myHandles = await api.getHandles(state: pushService.state!.client);
        var msg = Message(
          guid: uuid.v4(),
          isFromMe: myHandles.contains(myMsg.sender),
          handleId: RustPushBBUtils.rustHandleToBB(myMsg.sender!).originalROWID!,
          dateCreated: DateTime.fromMillisecondsSinceEpoch(myMsg.sentTimestamp),
          itemType: 2,
          groupActionType: 2,
          groupTitle: myMsg.conversation!.cvName,
        );

        inq.queue(IncomingItem(
          chat: result,
          message: msg,
          type: QueueType.newMessage
        ));
      }
    }
    if (result.dateDeleted != null) {
      Chat.unDelete(result);
      await chats.addChat(result);
    }
    return result;
  }

  Future<void> markFailed(Message mistakeFor, String error) async {
    if (mistakeFor.guid != null && !mistakeFor.guid!.contains("temp") && !mistakeFor.guid!.contains("error")) {
      mistakeFor.stagingGuid = mistakeFor.guid;
    }
    mistakeFor.generateTempGuid();
    mistakeFor.guid = mistakeFor.guid!.replaceAll("temp", "error-protocol: $error");
    var chat = mistakeFor.chat.target!;
    if (!ls.isAlive || !(cm.getChatController(chat.guid)?.isAlive ?? false)) {
      await notif.createFailedToSend(chat);
    }
    await Message.replaceMessage(mistakeFor.stagingGuid, mistakeFor);
  }

  Future<Chat?> findOperatedChat(api.OperatedChat chat) async {
    var conversation = api.ConversationData(participants: chat.participants.map((p) => p.isEmail ? "mailto:$p" : "tel:$p").toList(), senderGuid: chat.groupId);
    return await Chat.findByRust(conversation, chat.guid.startsWith("iMessage") ? "iMessage" : "SMS");
  }

  bool isSessionActive(api.FTSession session) {
    var anHourAgo = DateTime.now().millisecondsSinceEpoch - 3600000;
    return session.participants.values.any((value) => value.active != null) && (session.lastRekey ?? session.startTime) != null && (session.lastRekey ?? session.startTime)! > anHourAgo;
  }

  
  RxList<api.FTSession> sessions = <api.FTSession>[].obs;
  RxList<api.FTSession> activeSessions = <api.FTSession>[].obs;
  Future<void> updateState() async {
    var ftSessions = (await api.ftSessions(facetime: pushService.state!.ftClient)).filter((a) => a.startTime != null).toList();
    ftSessions.sort((a, b) {
      return b.startTime! - a.startTime!;
    });

    List<api.FTSession> othersessions = [];
    List<api.FTSession> activesessions = [];
    for (var session in ftSessions) {
      if (isSessionActive(session)) {
        activesessions.add(session);
      } else {
        othersessions.add(session);
      }
    }
    
    sessions.value = othersessions;
    activeSessions.value = activesessions;
  }

  String convertAttachmentGuid(String guid) {
    if (guid.startsWith("at")) {
      var items = guid.split("_");
      guid = "${items[2]}_${items[1]}";
    }
    return guid;
  }

  String generateCloudKitId() {
    final random = Random.secure(); // cryptographically secure RNG
    final bytes = Uint8List(32);    // 32 bytes
    for (int i = 0; i < bytes.length; i++) {
      bytes[i] = random.nextInt(256); // fill with random byte
    }
    return hex.encode(bytes);
  }

  bool syncStopDelete = false;

  void eraseCloudKitSync() {
    if (ss.prefs.getString("chatSyncToken") == null) return;
    ss.prefs.remove("chatSyncToken");
    ss.prefs.remove("messageSyncToken");
    ss.prefs.remove("attachmentSyncToken");
    ss.prefs.remove("chatDeletionIds-1");
    ss.prefs.remove("messageDeletionIds-1");
    ss.prefs.remove("attachmentDeletionIds-1");
    var messages = Database.messages.getAll();
    for (var message in messages) {
      message.ckRecordId = null;
      message.ckSyncState = false;
    }
    Database.messages.putMany(messages);
    var chats = Database.chats.getAll();
    for (var chat in chats) {
      chat.ckRecordId = null;
      chat.ckSyncState = false;
      chat.cloudData = null;
      chat.photoAttachmentGuid = null;
    }
    Database.chats.putMany(chats);
    var attachments = Database.attachments.getAll();
    for (var attachment in attachments) {
      attachment.ckRecordId = null;
    }
    Database.attachments.putMany(attachments);
  }

  // forcibly stops a running sync operation.
  Future<void> resetCloudKitSync() async {
    if (isSyncing.value == null) return;

    if (kIsDesktop) {
      exit(0);
    } else {
      await mcs.invokeMethod("native-sync-isolate", {
        "close": true
      });
      ui.IsolateNameServer.removePortNameMapping("bg_sync");
      pushService.isSyncing.value = null;
      chats.restoring = false;
    }
  }

  Rxn<String> isSyncing = Rxn(null);
  Future<void> doCloudKitSync() async {
    if (kIsDesktop) {
      chats.restoring = true;
      try {
        await pushService.doCloudKitSyncPrivate();
      } finally {
        pushService.isSyncing.value = null;
        chats.restoring = false;
      }
      return;
    }
    var syncing = ui.IsolateNameServer.lookupPortByName("bg_sync");
    if (syncing != null) {
      Logger.warn("Already syncing, not syncing again!");
      return;
    }
    isSyncing.value = "Starting Sync...";
    await mcs.invokeMethod("native-sync-isolate");
    
    var port = ReceivePort();
    port.listen((data) {
      if (data == null) {
        ss.prefs.reload(); // to get the new final sync time
      }
      isSyncing.value = data;
    });
    syncing = ui.IsolateNameServer.lookupPortByName("bg_sync");
    syncing!.send(port.sendPort);
  }

  String formatBytes(int bytes, [int decimals = 2]) {
    if (bytes <= 0) return "0 B";
    const suffixes = ["B", "KB", "MB", "GB", "TB"];
    var i = (log(bytes) / log(1024)).floor();
    var size = bytes / pow(1024, i);
    return "${size.toStringAsFixed(decimals)} ${suffixes[i]}";  
  }

  (int, DateTime) getCutoffTime() {
    // yes, we call this a lot, it's a bit of a shame.
    ss.prefs.reload();
    var time = ss.prefs.getInt('syncHistoryTime') ?? 0;

    var cutoffDateTime = DateTime.fromMillisecondsSinceEpoch(0);
    var cutoffTime = 0;
    if (time != 0) {
      cutoffTime = RustPushBBUtils.nsSinceAppleEpoch(DateTime.now()) - (time * 1000000);
      cutoffDateTime = DateTime.now().subtract(Duration(milliseconds: time));
    }
    return (cutoffTime, cutoffDateTime);
  }

  Future<void> uploadMessages(
      List<Message> messages, 
      List<(String, String)> uploadAttachments, 
      Map<String, Attachment> idToAttachment,
      bool noAttachments,
    ) async {
    var availableSize = await api.getQuotaInfo(info: pushService.state!.icloudServices!.tokenProvider);
    Map<String, api.CloudMessage> saveMessages = {};
    var totalSize = 0;

    List<String> newCloudKitIds = [];

    String createNewCloudKitId() {
      var id = generateCloudKitId();
      newCloudKitIds.add(id);
      return id;
    }

    // var counter = 0;
    for (var message in messages) {
      // counter += 1;
      // Logger.info("Processing message $counter of ${messages.length}");
      if (message.chat.target?.isRpSms == true) {
        message.ckSyncState = true;
        continue;
      }
      message.fetchAttachments();

      // remember: other invocations
      message.ckRecordId ??= createNewCloudKitId();
      var saveMessageAttachments = !noAttachments || message.attachments.every((a) => a!.ckRecordId != null);
      try {
        saveMessages[message.ckRecordId!] = message.toCloud(!saveMessageAttachments);
      } catch (e, s) {
        Logger.warn("Failure to convert to cloud", error: e, trace: s);
        continue;
      } finally {
        message.ckSyncState = true;
      }

      if (!noAttachments) {
        for (var attachment in message.attachments) {
          if (!attachment!.getFile().exists() || File(attachment.path).lengthSync() == 0 || attachment.ckRecordId != null) continue;
          totalSize += File(attachment.path).lengthSync();
          attachment.ckRecordId ??= createNewCloudKitId();
          uploadAttachments.add((attachment.path, attachment.ckRecordId!));
          idToAttachment[attachment.ckRecordId!] = attachment;
        }
      }
    }

    // sub 25 mb off the top just for other things
    if (totalSize != 0 && totalSize > availableSize.availableBytes - (25 * 1024 * 1024)) {
      throw Exception("Not enough space for attachments, needed ${formatBytes(totalSize)}!");
    }

    Logger.info("Attachment total size $totalSize!");

    if (uploadAttachments.isNotEmpty) {
      Map<String, api.CloudAttachment> saveAttachments = {};
      var results = await api.uploadCloudAttachments(cloudMessagesClient: pushService.state!.icloudServices!.cloudMessagesClient!, files: uploadAttachments);
      for (var result in results.entries) {
        var attachment = idToAttachment[result.key]!;
        saveAttachments[attachment.ckRecordId!] = api.CloudAttachment(
          cm: api.encodeAttachmentmeta(attachmentmeta: await attachment.getAttachmentMeta()),
          lqa: result.value,
        );
      }
      var result = await api.saveAttachments(cloudMessagesClient: pushService.state!.icloudServices!.cloudMessagesClient!, attachments: saveAttachments);

      for (var result in result.entries) {
        if (result.value) continue; // success
        var failedAttachment = idToAttachment.values.firstWhere((c) => c.ckRecordId == result.key);
        if (newCloudKitIds.contains(failedAttachment.ckRecordId!)) failedAttachment.ckRecordId = null;
        Logger.warn("Failed to save attachment ${failedAttachment.guid}");
      }

      for (var result in idToAttachment.values) {
        result.save(null); // save ckRecordId
      }
    }

    if (saveMessages.isNotEmpty) {
      var result = await api.saveMessages(cloudMessagesClient: pushService.state!.icloudServices!.cloudMessagesClient!, messages: saveMessages);

      for (var result in result.entries) {
        if (result.value) continue; // success
        var failedMessage = messages.firstWhere((c) => c.ckRecordId == result.key);
        if (newCloudKitIds.contains(failedMessage.ckRecordId!)) failedMessage.ckRecordId = null;
        Logger.warn("Failed to save message ${failedMessage.guid}");
      }
    }

    for (var result in messages) {
      result.save(); // save ckRecordId
      getActiveMwc(result.guid!)?.message.ckRecordId = result.ckRecordId;
    }
  }

  Future<void> uploadAttachment(Message message) async {
    if (message.attachments.every((att) => att!.ckRecordId != null)) {
      showSnackbar("Success", "Attachment already uploaded");
      return;
    }
    await wrapPromise(uploadMessages([message], [], {}, false), "Uploading to iCloud...");
    showSnackbar("Success", "Attachment uploaded");
  }

  Future<void> doCloudKitSyncPrivate() async {
    isSyncing.value = "Syncing Now...";

    var isInClique = await api.isInClique(keychain: pushService.state!.icloudServices!.keychain!);
    if (!isInClique) {
      Logger.warn("Skipping sync because we are no longer in the clique!");
      ss.settings.cloudSyncingEnabled.value = false;
      ss.saveSettings();
      return;
    }

    if (ss.prefs.getStringList("messageDeletionIds-1")?.isNotEmpty ?? false) {
      await api.deleteMessages(cloudMessagesClient: pushService.state!.icloudServices!.cloudMessagesClient!, messages: ss.prefs.getStringList("messageDeletionIds-1")!);
      ss.prefs.remove("messageDeletionIds-1");
    }

    if (ss.prefs.getStringList("attachmentDeletionIds-1")?.isNotEmpty ?? false) {
      await api.deleteAttachments(cloudMessagesClient: pushService.state!.icloudServices!.cloudMessagesClient!, attachments: ss.prefs.getStringList("attachmentDeletionIds-1")!);
      ss.prefs.remove("attachmentDeletionIds-1");
    }

    if (ss.prefs.getStringList("chatDeletionIds-1")?.isNotEmpty ?? false) {
      await api.deleteChats(cloudMessagesClient: pushService.state!.icloudServices!.cloudMessagesClient!, chats: ss.prefs.getStringList("chatDeletionIds-1")!);
      ss.prefs.remove("chatDeletionIds-1");
    }

    ss.saveSettings();

    isSyncing.value = "Syncing Chats...";

    List<(String, String)> downloadPfPics = [];
    var currentState = 0;
    while (currentState != 3) {
      var (token, items, state) = await api.syncChats(cloudMessagesClient: pushService.state!.icloudServices!.cloudMessagesClient!, 
        continuationToken: ss.prefs.getString("chatSyncToken") != null ? base64Decode(ss.prefs.getString("chatSyncToken")!) : null);
      currentState = state;
      List<String> dupDeleteChats = [];
      for (var item in items.entries) {
        try {
          if (item.value == null) {
            final query = Database.chats.query(Chat_.ckRecordId.equals(item.key)).build();
            final result = query.findFirst();
            if (result != null) {
              syncStopDelete = true;
              chats.removeChat(result);
              Chat.deleteChat(result);
              syncStopDelete = false;
            }
            var index = downloadPfPics.indexWhere((i) => i.$2 == item.key);
            if (index != -1) {
              downloadPfPics.removeAt(index);
            }
            continue;
          }

          // localized deduplication works fine, since it should not sync down items that have been deleted
          if (dupDeleteChats.contains(item.key)) continue;
          if (item.value!.serviceName != "iMessage") continue; // imessage only

          var chat = await Chat.findFromCloud(item.value!);

          if (chat.ckRecordId != null && chat.ckRecordId != item.key) {
            // we have a different record id
            dupDeleteChats.add(chat.ckRecordId!);
          }

          var didSync = chat.applyFromCloud(item.value!, item.key);
          if (didSync && item.value!.groupPhoto != null) {
            downloadPfPics.add((chat.customAvatarPath!, item.key));
          }
        } catch (e, s) {
          Logger.error("Failed to sync item ${item.key}", error: e, trace: s);
        }
      }

      if (dupDeleteChats.isNotEmpty) {
        Logger.info("Deleting ${dupDeleteChats.length} duplicate chats");
        try {
          await api.deleteChats(cloudMessagesClient: pushService.state!.icloudServices!.cloudMessagesClient!, chats: dupDeleteChats);
        } catch (e) {
          if (e is AnyhowException) {
            if (e.message.contains("Too many requests")) {
              Logger.warn("Too many requests, waiting 10s");
              await Future.delayed(const Duration(seconds: 10));
              await api.deleteChats(cloudMessagesClient: pushService.state!.icloudServices!.cloudMessagesClient!, chats: dupDeleteChats);
            } else { rethrow; }
          } else { rethrow; }
        }
      }

      ss.prefs.setString("chatSyncToken", base64Encode(token));
    }  

    if (downloadPfPics.isNotEmpty) {
      await api.downloadCloudGroupPhotos(cloudMessagesClient: pushService.state!.icloudServices!.cloudMessagesClient!, files: downloadPfPics);
    }

    isSyncing.value = "Downloading Attachments...";

    // we must have one uniform cutoff time to ensure we don't upload duplicates
    var (cutoffTime, cutoffDateTime) = getCutoffTime();
    var attCount = 0;
    currentState = 0;
    while (currentState != 3) {
      var (token3, items3, state3) = await api.syncAttachments(cloudMessagesClient: pushService.state!.icloudServices!.cloudMessagesClient!, 
          continuationToken: ss.prefs.getString("attachmentSyncToken") != null ? base64Decode(ss.prefs.getString("attachmentSyncToken")!) : null);
      currentState = state3;
      List<String> dupDeleteAttachments = [];
      for (var item in items3.entries) {
        try {
          if (item.value == null) {
            final query = Database.attachments.query(Attachment_.ckRecordId.equals(item.key)).build();
            final result = query.findFirst();
            syncStopDelete = true;
            if (result != null) Attachment.delete(result.guid!);
            syncStopDelete = false;
            continue;
          }
          if (dupDeleteAttachments.contains(item.key)) continue;
          var decoded = api.decodeAttachmentmeta(wrapped: item.value!.cm);

          if (cutoffTime > decoded.createdDate && currentState != 3) {
            Logger.info("Stopping attachment sync for cutoff!");
            currentState = 3;
          }

          var existing = Attachment.findOne(convertAttachmentGuid(decoded.guid));
          if (existing != null) {
            if (existing.ckRecordId != null && existing.ckRecordId != item.key) {
              // we have a different record id
              dupDeleteAttachments.add(existing.ckRecordId!);
            }
            existing.ckRecordId = item.key;
            existing.save(null);
            continue;
          } // don't overwrite existing
          Logger.info("Syncing new attachment");
          var attachment = Attachment();
          attachment.applyFromCloud(item.value!, item.key);
        } catch (e, s) {
          Logger.error("Failed to sync attachment ${item.key}", error: e, trace: s);
        }
      }

      if (dupDeleteAttachments.isNotEmpty) {
        Logger.info("Deleting ${dupDeleteAttachments.length} duplicate attachments");
        try {
          await api.deleteAttachments(cloudMessagesClient: pushService.state!.icloudServices!.cloudMessagesClient!, attachments: dupDeleteAttachments);
        } catch (e) {
          if (e is AnyhowException) {
            if (e.message.contains("Too many requests")) {
              Logger.warn("Too many requests, waiting 10s");
              await Future.delayed(const Duration(seconds: 10));
              await api.deleteAttachments(cloudMessagesClient: pushService.state!.icloudServices!.cloudMessagesClient!, attachments: dupDeleteAttachments);
            } else { rethrow; }
          } else { rethrow; }
        }
      }

      attCount += items3.length;
      isSyncing.value = "Downloaded $attCount attachments";

      ss.prefs.setString("attachmentSyncToken", base64Encode(token3));
    }

    int localUnchanged = 0;
    int localChanged = 0;
    int localSet = 0;
    int remoteSaved = 0;
    int totalMessages = 0;
    int remoteNew = 0;

    isSyncing.value = "Downloading Messages...";

    currentState = 0;
    while (currentState != 3) {
      var (token2, items2, state2) = await api.syncMessages(cloudMessagesClient: pushService.state!.icloudServices!.cloudMessagesClient!, 
        continuationToken: ss.prefs.getString("messageSyncToken") != null ? base64Decode(ss.prefs.getString("messageSyncToken")!) : null);
      currentState = state2;

      List<String> dupDeleteMessages = [];
      Logger.info("Syncing group of ${items2.length} messages, total $totalMessages");
      totalMessages += items2.length;

      for (var item in items2.entries) {
        try {
          if (item.value == null) {
            final query = Database.messages.query(Message_.ckRecordId.equals(item.key)).build();
            final result = query.findFirst();
            syncStopDelete = true;
            if (result != null) Message.delete(result.guid!);
            syncStopDelete = false;
            continue;
          }
          if (dupDeleteMessages.contains(item.key)) continue;

          if (cutoffTime > item.value!.time && currentState != 3) {
            Logger.info("Stopping message sync for cutoff!");
            currentState = 3;
          }

          var existing = Message.findOne(guid: item.value!.guid);
          if (existing != null) {
            if (existing.ckRecordId == item.key) {
              localUnchanged++;
            } else if (existing.ckRecordId != null) {
              // we have a different record id
              dupDeleteMessages.add(existing.ckRecordId!);
              localChanged++;
            } else {
              localSet++;
            }
            existing.ckRecordId = item.key;
            existing.save();
            remoteSaved++;
            continue;
          } // don't overwrite existing
          var message = Message();
          message.applyFromCloud(item.value!, item.key);
          remoteNew++;
        } catch (e, s) {
          Logger.error("Failed to sync attachment ${item.key}", error: e, trace: s);
        }
      }

      if (dupDeleteMessages.isNotEmpty) {
        Logger.info("Deleting ${dupDeleteMessages.length} duplicate messages");
        try {
          await api.deleteMessages(cloudMessagesClient: pushService.state!.icloudServices!.cloudMessagesClient!, messages: dupDeleteMessages);
        } catch (e) {
          if (e is AnyhowException) {
            if (e.message.contains("Too many requests")) {
              Logger.warn("Too many requests, waiting 10s");
              await Future.delayed(const Duration(seconds: 10));
              await api.deleteMessages(cloudMessagesClient: pushService.state!.icloudServices!.cloudMessagesClient!, messages: dupDeleteMessages);
            } else { rethrow; }
          } else { rethrow; }
        }
      }

      isSyncing.value = "Downloaded $totalMessages messages";
      
      ss.prefs.setString("messageSyncToken", base64Encode(token2));
    }

    isSyncing.value = "Uploading chats...";

    Logger.info("Out");

    List<(String, String)> uploadAttachments = [];
    Map<String, Attachment> idToAttachment = {};

    var unsyncedChats = Database.chats.query(Chat_.ckSyncState.equals(false).and(Chat_.dateDeleted.isNull()).and(Chat_.isRpSms.equals(false))).build();
    var useChats = unsyncedChats.find();
    Logger.info("Out2");
    Map<String, api.CloudChat> saveChats = {};
    List<(String, String)> uploadPhotos = [];
    var totalSavedChats = 0;
    for (var chat in useChats) {
      var item = await chat.toCloud();

      if (chat.photoAttachmentGuid != null) {
        var attachment = Attachment.findOne(chat.photoAttachmentGuid!);
        if (attachment != null && attachment.getFile().exists() && attachment.ckRecordId == null) {
          attachment.ckRecordId = generateCloudKitId();
          uploadAttachments.add((attachment.path, attachment.ckRecordId!));
          idToAttachment[attachment.ckRecordId!] = attachment;
        }
      }

      chat.ckRecordId ??= generateCloudKitId();

      if (chat.customAvatarPath != null) {
        var file = File(chat.customAvatarPath!);
        if (file.existsSync() && file.lengthSync() > 0) {
          uploadPhotos.add((chat.customAvatarPath!, chat.ckRecordId!));
        }
      }

      saveChats[chat.ckRecordId!] = item;
    }

    if (saveChats.isNotEmpty) {
      if (uploadPhotos.isNotEmpty) {
        var results = await api.uploadGroupPhoto(cloudMessagesClient: pushService.state!.icloudServices!.cloudMessagesClient!, files: uploadPhotos);
        for (var result in results.entries) {
          saveChats[result.key]!.groupPhoto = result.value;
        }
      }

      totalSavedChats += saveChats.length;

      var result = await api.saveChats(cloudMessagesClient: pushService.state!.icloudServices!.cloudMessagesClient!, chats: saveChats);
      for (var result in result.entries) {
        if (result.value) continue; // success
        var failedChat = useChats.firstWhere((c) => c.ckRecordId == result.key);
        failedChat.ckRecordId = null;
        Logger.warn("Failed to save chat ${failedChat.guid}");
      }
      for (var result in useChats) {
        result.save(updateCkRecordId: true); // save ckRecordId
      }

      isSyncing.value = "Uploaded $totalSavedChats chats";
    }

    Logger.info("Syncing messages");
    bool noAttachments = !ss.settings.attachmentSyncEnabled.value;


    var unsyncedMessages = Database.messages.query(Message_.ckRecordId.isNull().and(Message_.itemType.equals(0)).and(Message_.ckSyncState.equals(false).or(Message_.ckSyncState.isNull()))
      .and(Message_.dateCreated.greaterThanDate(cutoffDateTime)))
      .build()
      ..limit = 3000;
    var messages = unsyncedMessages.find();
      int localUpload = messages.length;

    while (messages.isNotEmpty) {
      Logger.info("Syncing batch ${messages.length}");
      await uploadMessages(messages, uploadAttachments, idToAttachment, noAttachments);

      var unsyncedMessages = Database.messages.query(Message_.ckRecordId.isNull().and(Message_.itemType.equals(0)).and(Message_.ckSyncState.equals(false).or(Message_.ckSyncState.isNull()))
        .and(Message_.dateCreated.greaterThanDate(cutoffDateTime)))
        .build()
        ..limit = 3000;
      messages = unsyncedMessages.find();
      localUpload += messages.length;
      isSyncing.value = "Uploaded $localUpload messages";
    }

    ss.prefs.setInt("lastSynced", DateTime.now().millisecondsSinceEpoch);
    Logger.info("Syncing completed");
    Logger.info("Sync stats: $localUnchanged $localChanged $localSet $remoteSaved $localUpload $totalMessages $remoteNew");
  }

  Future<PurchaseWrapper?> getPurchaseDetails() async {
    try {
      var purchases = await pushService.client.runWithClient((client) => client.queryPurchases(ProductType.subs));
      var token = purchases.purchasesList.firstOrNull?.purchaseToken;
      if (token != null && ss.settings.deviceIsHosted.value) {
        ss.settings.hostedToken.value = token;
        ss.saveSettings();
      }
      return purchases.purchasesList.firstOrNull;
    } catch (e, s) {
      Logger.error("Failed to get purchase details", error: e, trace: s);
      return null;
    }
  }

  // true if active purchase is valid.
  Future<bool> checkPurchaseState() async {
    if (ss.settings.hostedToken.value == null) return false;
    final status = await http.dio.post("https://hw.openbubbles.app/restore", data: {"purchase_token": ss.settings.hostedToken.value!}, options: Options(responseType: ResponseType.plain),);
    var elapsed = status.data.toString().contains("Invalid subscription!");

    return !elapsed;
  }

  Future<void> handleRegistered() async {
    notif.clearRegisterFailed();
    if (ss.settings.hostedToken.value != null) {
      var detail = await getPurchaseDetails();
      if (detail == null) return;

      if (!detail.isAcknowledged) {
        await pushService.client.runWithClient((client) => client.acknowledgePurchase(detail.purchaseToken));
      }
    }
  }

  Future<void> rotateIncomingLink() async {
    await api.useLinkFor(facetime: pushService.state!.ftClient, oldUsage: "incomingcall", usage: "incomingcall-old");
    await api.useLinkFor(facetime: pushService.state!.ftClient, oldUsage: "nextincomingcall", usage: "incomingcall");
    await api.getFtLink(facetime: pushService.state!.ftClient, usage: "nextincomingcall");
  }

  Future<void> rotateLink() async {
    await api.useLinkFor(facetime: pushService.state!.ftClient, oldUsage: "current", usage: "current-old");
    await api.useLinkFor(facetime: pushService.state!.ftClient, oldUsage: "next", usage: "current");
    await api.getFtLink(facetime: pushService.state!.ftClient, usage: "next");
  }

  Timer? outgoingCallTimer;
  Map<String, dynamic> outgoingCallMeta = {};
  RxString? currentOutgoingCall;
  Future<void> placeOutgoingCall(String caller, List<String> targets) async {

    var outgoingguid = uuid.v4().toUpperCase();

    var link = await api.getFtLink(facetime: pushService.state!.ftClient, usage: "next");
    var desc = targets.map((p) => RustPushBBUtils.rustHandleToBB(p).displayName).join(" & ");
    // rotate link
    pushService.rotateLink().catchError((e, s) {
      Logger.error("Failed to rotate link", error: e, trace: s);
    });

    // preload
    mcs.invokeMethod("update-call-state", {
      "name": ss.settings.userName.value == "You" ? (await api.getHandles(state: pushService.state!.client)).first.replaceFirst("tel:", "").replaceFirst("mailto:", "") : ss.settings.userName.value,
      "desc": desc,
      "url": link,
      "callUuid": outgoingguid,
      "state": "ringing",
    });

    outgoingCallMeta = {
      'link': link, 
      'callUuid': outgoingguid, 
      'desc': desc, 
      'name': ss.settings.userName.value == "You" ? (await api.getHandles(state: pushService.state!.client)).first.replaceFirst("tel:", "").replaceFirst("mailto:", "") : ss.settings.userName.value, 
      'answer': true
    };

    outgoingCallTimer = Timer(const Duration(seconds: 30), () async {
      currentOutgoingCall?.value = "timeout";

      await api.cancelFacetime(facetime: pushService.state!.ftClient, guid: outgoingguid);

      // destroy webview
      mcs.invokeMethod("update-call-state", {
        "callUuid": outgoingguid,
        "state": "timeout",
      });
      currentOutgoingCall = null;
    });

    currentOutgoingCall = outgoingguid.obs;

    Uint8List? icon;
    String? poster;
    if (targets.length == 1) {
      var handle = RustPushBBUtils.rustHandleToBB(targets[0]);
      icon = handle.contact?.avatar;
      poster = handle.getPoster();
    }

    showOutgoingFaceTimeOverlay(currentOutgoingCall!, desc, caller, targets, icon, link, poster);
    await api.createFacetime(facetime: pushService.state!.ftClient, uuid: outgoingguid, handle: caller, participants: targets);
  }

  // returns handle to show poster of
  String? getSessionIdentity(String guid, bool active) {
    var session = activeSessions.firstWhereOrNull((a) => a.groupId == guid);
    if (session == null) {
      if (!active) {
        session = sessions.firstWhereOrNull((a) => a.groupId == guid);
      }
      if (session == null) {
        return null;
      }
    }
    return session.members.where((a) => !session!.myHandles.contains(a.handle)).firstOrNull?.handle;
  }

  String? getSessionName(String guid, bool active) {
    var session = activeSessions.firstWhereOrNull((a) => a.groupId == guid);
    if (session == null) {
      if (!active) {
        session = sessions.firstWhereOrNull((a) => a.groupId == guid);
      }
      if (session == null) {
        return null;
      }
    }
    var participants = session.members.where((a) => !session!.myHandles.contains(a.handle)).map((a) {
      if (a.nickname != null) {
        return Handle(address: "Maybe: ${a.nickname}");
      } else {
        return RustPushBBUtils.rustHandleToBB(a.handle);
      }
    }).toList();
    return participants.map((p) => p.displayName).join(" & ");
  }

  Future<void> updateShareState() async {
    var handle = (await api.getHandles(state: pushService.state!.client)).first;
    ss.settings.shareVersion.value++;
    var msg = await api.newMsg(
      conversation: api.ConversationData(participants: [handle]),
      sender: handle,
      message: api.Message.updateProfileSharing(api.UpdateProfileSharingMessage(
        sharedAll: ss.settings.sharedContacts.toList(),
        sharedDismissed: ss.settings.dismissedContacts.toList(),
        version: ss.settings.shareVersion.value,
      )),
    );
    await (backend as RustPushBackend).sendMsg(msg);
    ss.saveSettings();
  }

  Future<api.ShareProfileMessage?> getShareProfileMessageFor(List<Handle> targets) async {
    if (targets.length != 1) return null; // only share in 1-1 chats atm
    if (ss.settings.shareProfileMessage.value == null || !ss.settings.shareContactAutomatically.value || !ss.settings.nameAndPhotoSharing.value) return null;
    if (targets.every((t) => !(t.contact?.isShared ?? true) && !ss.settings.sharedContacts.contains(t.address))) {
      ss.settings.sharedContacts.addAll(targets.map((t) => t.address));
      ss.saveSettings();
      return api.decodeProfileMessage(s: ss.settings.shareProfileMessage.value!);
    }
    return null;
  }

  final Set<String> profilesDownloading = {};
  final Map<String, Timer> _profileRetryTimers = {};
  final ProfileRetryPolicy _profileRetryPolicy = ProfileRetryPolicy();

  String _profileFailureCategory(Object error) {
    final description = error.toString().toLowerCase();
    if (description.contains("profile service unavailable")) return "service_unavailable";
    if (description.contains("timeout")) return "timeout";
    if (description.contains("connection") ||
        description.contains("network") ||
        description.contains("socket") ||
        description.contains("dns")) {
      return "network";
    }
    if (description.contains("record") && description.contains("not found")) return "record_not_found";
    if (description.contains("plist") || description.contains("serde")) return "plist";
    if (description.contains("decrypt") ||
        description.contains("hmac") ||
        description.contains("crypto")) {
      return "crypto";
    }
    if (description.contains("asset")) return "asset";
    if (description.contains("panic")) return "panic";
    return error.runtimeType.toString();
  }

  void _clearProfileRetry(String profileKey) {
    _profileRetryTimers.remove(profileKey)?.cancel();
    _profileRetryPolicy.complete(profileKey);
  }

  void _scheduleProfileRetry(
    api.ShareProfileMessage shared,
    String sender,
    List<Handle> targets,
    String category,
  ) {
    final profileKey = shared.cloudKitRecordKey;
    final delay = _profileRetryPolicy.schedule(profileKey);
    if (delay == null) {
      Logger.warn("Shared profile fetch exhausted or already scheduled category=$category");
      return;
    }

    Logger.warn(
      "Shared profile fetch deferred category=$category "
      "retry_in_seconds=${delay.inSeconds}",
    );
    _profileRetryTimers[profileKey] = Timer(delay, () {
      _profileRetryTimers.remove(profileKey);
      _profileRetryPolicy.timerFired(profileKey);
      unawaited(handleSharedProfile(shared, sender, targets));
    });
  }

  Future<void> handleSharedProfile(api.ShareProfileMessage shared, String sender, List<Handle> targets) async {
    final profileKey = shared.cloudKitRecordKey;
    if (_profileRetryPolicy.isScheduled(profileKey) || !profilesDownloading.add(profileKey)) return;

    try {
      await _handleSharedProfile(shared, sender, targets);
      _clearProfileRetry(profileKey);
    } catch (error) {
      // Shared profile payloads are optional message metadata. A malformed
      // CloudKit plist must not escape an unawaited profile task and disturb
      // message delivery. Retry independently so the contact image can recover
      // after transient CloudKit, network, or service-initialization failures.
      final category = _profileFailureCategory(error);
      if (_profileRetryPolicy.classify(error) == ProfileFailureKind.transient) {
        _scheduleProfileRetry(shared, sender, targets, category);
      } else {
        Logger.warn("Shared profile fetch permanently failed category=$category");
        _profileRetryPolicy.complete(profileKey);
      }
    } finally {
      profilesDownloading.remove(profileKey);
    }
  }

  Future<void> _handleSharedProfile(api.ShareProfileMessage shared, String sender, List<Handle> targets) async {
    var myHandles = await api.getHandles(state: pushService.state!.client);
    if (myHandles.contains(sender)) {
      for (var target in targets) {
        if (ss.settings.sharedContacts.contains(target.address)) {
          continue;
        }
        ss.settings.sharedContacts.add(target.address);
      }
      ss.saveSettings();
      return;
    }
    var profiles = pushService.state?.icloudServices?.profilesClient;
    if (profiles == null) return;

    // mask with profilesDownloading because iPhones have a nasty habit of sharing once to every handle. We don't want to download 15 times for each handle
    if (Contact.findOne(id: shared.cloudKitRecordKey) != null || profilesDownloading.contains(shared.cloudKitRecordKey)) return; // already downloaded
    profilesDownloading.add(shared.cloudKitRecordKey);

    try {
      var fetch = await api.fetchProfile(profiles: profiles, message: shared);
      var otherHandle = RustPushBBUtils.rustHandleToBB(sender);

      String? posterPath;
      if (fetch.poster != null && !kIsDesktop) {
        var decoded = await api.parsePoster(poster: fetch.poster!);
        try {
          posterPath = await savePoster(decoded);
        } catch (e, t) {
          Logger.error("Could not decode other poster", error: e, trace: t); 
        }
      }

      var existingShared = Contact.findOne(address: otherHandle.address, wantShared: true);
      if (existingShared != null) {
        if (otherHandle.contactRelation.targetId == existingShared.dbId) {
          otherHandle.contactRelation.target = null;
        }
        if (existingShared.posterPath != null) {
          try {
            await deletePoster(existingShared.posterPath!);
          } catch (e) { /* */ }
        }
        Database.contacts.remove(existingShared.dbId!);
      }
      if (otherHandle.getPoster() == null) {
        otherHandle.setPoster(posterPath);
        posterPath = "alreadyset";
      }
      var newId = Database.contacts.put(Contact(
        id: shared.cloudKitRecordKey,
        displayName: "Maybe: ${fetch.name.name}",
        structuredName: StructuredName(
          namePrefix: "",
          nameSuffix: "",
          givenName: fetch.name.first,
          middleName: "",
          familyName: fetch.name.last,
        ),
        avatar: fetch.image,
        isShared: true,
        phones: otherHandle.contact?.phones ?? (otherHandle.address.isEmail ? [] : [otherHandle.address]),
        emails: otherHandle.contact?.emails ?? (otherHandle.address.isEmail ? [otherHandle.address] : []),
        posterPath: posterPath,
      ));
      if (otherHandle.contactRelation.target == null) {
        otherHandle.contactRelation.targetId = newId;
        Database.handles.put(otherHandle);
      }
      final result = (await Chat.findByRust(api.ConversationData(participants: [sender]), "iMessage", soft: true));
      if (result != null) {
        cvc(result).updateContactInfo();
      }
    } finally {
      profilesDownloading.remove(shared.cloudKitRecordKey);
    }
  }

  Future<void> deletePoster(String path) async {
    if (Directory(path).existsSync()) {
      await Directory(path).delete(recursive: true);
    }
    if (File("$path.jpg").existsSync()) {
      await File("$path.jpg").delete(); 
    }
    if (File("$path-preview.png").existsSync()) {
      await File("$path-preview.png").delete();
    }
  }

  Future<void> savePosterData(api.SimplifiedPoster poster, int number) async {
    String appDocPath = fs.appDocDir.path;
    if (poster.type is api.PosterType_Photo) {
      var photo = poster.type as api.PosterType_Photo;
      for (var asset in photo.assets) {
        Map<String, Uint8List> entries = {};
        for (var file in asset.files.entries) {
          File f = fileForAsset("$appDocPath/avatars/you/poster-$number", asset, file.key);
          if (!(await f.exists())) {
            await f.create(recursive: true);
          }
          await f.writeAsBytes(file.value);

          if (file.key.endsWith("HEIC")) {
            await mcs.invokeMethod("decode-heif", {"file": f.path, "output": "${f.path}.png"});
          }

          entries[file.key] = Uint8List(0);
        }
        asset.files = entries;
      }
    }

    if (poster.type is api.PosterType_Memoji) {
      var memoji = poster.type as api.PosterType_Memoji;
      File f = File("$appDocPath/avatars/you/poster-$number/memoji_orig.heic");
      if (!(await f.exists())) {
        await f.create(recursive: true);
      }
      await f.writeAsBytes(memoji.data.avatarImageData);

      await mcs.invokeMethod("decode-heif", {"file": f.path, "output": "$appDocPath/avatars/you/poster-$number/memoji.png"});
      memoji.data.avatarImageData = Uint8List(0);
    }
  }

  Future<String> savePoster(api.SimplifiedIncomingCallPoster decoded) async {
    int number = Random().nextInt(9999999);

    String appDocPath = fs.appDocDir.path;

    savePosterData(decoded.poster, number);

    var save = await api.parsePosterSave(poster: decoded);
    File file = File("$appDocPath/avatars/you/poster-$number.jpg");
    if (!(await file.exists())) {
      await file.create(recursive: true);
    }
    await file.writeAsBytes(save);

    Logger.info("Wrote poster $appDocPath/avatars/you/poster-$number");

    return "$appDocPath/avatars/you/poster-$number";
  }

  Future<String> saveTranscriptPoster(api.SimplifiedTranscriptPoster decoded) async {
    int number = Random().nextInt(9999999);

    String appDocPath = fs.appDocDir.path;

    savePosterData(decoded.poster, number);

    var save = await api.transcriptPosterSave(poster: decoded);
    File file = File("$appDocPath/avatars/you/poster-$number.jpg");
    if (!(await file.exists())) {
      await file.create(recursive: true);
    }
    await file.writeAsBytes(save);

    Logger.info("Wrote poster $appDocPath/avatars/you/poster-$number");

    return "$appDocPath/avatars/you/poster-$number";
  }

  Future invalidatePeerCaches() async {
    var myHandles = (await api.getHandles(state: pushService.state!.client));
    // loop through recent chats (1 day or newer)
    Query<Chat> query = Database.chats.query(Chat_.dateDeleted.isNull().and(Chat_.dbOnlyLatestMessageDate.greaterThan(DateTime.now().subtract(const Duration(hours: 12)).millisecondsSinceEpoch)))
        .build();

    // Execute the query, then close the DB connection
    final chats = query.find();
    query.close();

    // notify participants of these chats that my keys have changed
    Map<String, Set<String>> handleChats = <String, Set<String>>{};
    for (var handle in myHandles) {
      handleChats[handle] = {handle};
    }

    for (var chat in chats) {
      if (!chat.isIMessage) continue;
      var data = await chat.getConversationData();
      var sender = await chat.ensureHandle();
      handleChats[sender]?.addAll(data.participants);
    }

    for (var handle in myHandles) {
      if (handleChats[handle]!.length == 1) continue; // if it's just us, we're good.
      var msg = await api.newMsg(
        conversation: api.ConversationData(participants: handleChats[handle]!.toList()),
        sender: handle,
        message: const api.Message.peerCacheInvalidate(),
      );
      await (backend as RustPushBackend).sendMsg(msg);
    }
  }

  void wantAddNumber() {
    final status = http.dio.get("https://hw.openbubbles.app/status").then((status) => status.data["available"]);
    showDialog(
      context: Get.context!,
      builder: (context) => AlertDialog(
        title: Text(
          "Adding a phone number requires an iPhone",
          style: context.theme.textTheme.titleLarge,
        ),
        backgroundColor: context.theme.colorScheme.properSurface,
        content: Text("Try hosted for a just-works, paid, hosted solution. Or, jailbreak your own to self-host.", style: context.theme.textTheme.bodyLarge),
        actions: [
          TextButton(
            child: Text(
                "Close",
                style: context.theme.textTheme.bodyLarge!.copyWith(color: context.theme.colorScheme.primary)
            ),
            onPressed: () => Navigator.of(context).pop(),
          ),
          TextButton(
            child: Text(
                "Learn to Self-host",
                style: context.theme.textTheme.bodyLarge!.copyWith(color: context.theme.colorScheme.primary)
            ),
            onPressed: () {
              Navigator.of(context).pop();
              launchUrl(Uri.parse("https://openbubbles.app/docs/pnr.html"));
            }
          ),
          TextButton(
            child: Text(
                "Switch to Hosted",
                style: context.theme.textTheme.bodyLarge!.copyWith(color: context.theme.colorScheme.primary)
            ),
            onPressed: () async {
              Navigator.of(context).pop();
              if (await status) {
                pushService.markFailedToLogin(hw: true, logout: true, ui: true);
              } else {
                launchUrl(Uri.parse("https://openbubbles.app/#hosted"));
              }
            }
          ),
        ],
      ),
    );
  }

  var notifiedFailed = false;
  var notifiedSubFailed = false;

  String? chosenFTRoomGuid;
  String? incomingRingingCallGuid;

  Future<void> markCertified(api.PushMessage push) async {
    if (push is! api.PushMessage_IMessage) return;
    var sendDelivered = push.field0.sendDelivered;
    try {
      var chat = await pushService.chatForMessage(push.field0);
      if (!chat.isGroup && chat.handles.length == 1 && chat.handles.first.isBlocked()) {
        sendDelivered = false; // we are blocked
      }
      if (chat.isRpSms) {
        sendDelivered = false; // no delivery recipts :)
      }
    } catch (e) { /* sending a receipt is more important */ }
    if (push.field0.certifiedContext == null) {
      if (sendDelivered) {
        var chat = await pushService.chatForMessage(push.field0);
        var message = push.field0;
        var msg = await api.newMsg(
          conversation: api.ConversationData(
            participants: [message.sender!],
            cvName: message.conversation!.cvName,
            senderGuid: message.conversation!.senderGuid
          ),
          sender: await chat.ensureHandle(),
          message: const api.Message.delivered(),
        );
        msg.id = message.id;
        msg.target = message.target; // delivered is only sent to the device that sent it
        if (msg.id.contains("temp") || msg.id.contains("error")) {
          return;
        }
        await (backend as RustPushBackend).sendMsg(msg);
      }
      return;
    }
    await api.certifyDelivery(state: pushService.state!.client, context: push.field0.certifiedContext!, notify: sendDelivered);
  }

  Future markAsSpam(Chat chat) async {
    List<api.ReportMessage> messages = [];
    var chatMessages = Chat.getMessages(chat, limit: 5);
    for (var message in chatMessages) {
      api.MessageParts parts;
      if (message.attributedBody.isNotEmpty) {
        parts = await (backend as RustPushBackend).partsFromBody(message.attributedBody.first);
      } else {
        parts = api.MessageParts(field0: [api.IndexedMessagePart(part_: api.MessagePart.text(message.text!, pushService.defaultFormat()))]);
      }
      if (message.isFromMe!) continue;
      messages.add(api.ReportMessage(
        guid: message.guid!, 
        sender: RustPushBBUtils.bbHandleToRust(message.handle!), 
        conversationSize: chat.participants.length, 
        parts: parts, 
        timeOfMessage: message.dateCreated!.microsecondsSinceEpoch.toDouble() / 1000000
      ));
    }
    await api.reportMessages(state: pushService.state!.client, handle: await chat.ensureHandle(), messages: messages);
    Chat.softDelete(chat);
  }

  Future handleMsg(api.PushMessage push, bool finalAttempt) async {
    try {
      await handleMsgInner(push).timeout(const Duration(minutes: 3));
    } catch (e, s) {
      if (finalAttempt) markCertified(push);
      rethrow;
    }
    // if we complete successfully, mark delivery "certified"
    markCertified(push);
  }

  bool authing = false;
  Future handleMsgInner(api.PushMessage push) async {
    if (push is api.PushMessage_CircleFinishEvent) {
      if (await api.isInClique(keychain: pushService.state!.icloudServices!.keychain!)) {
        cachedInClique = true;
        // enable after battle testing
        
        // Logger.info("Joined clique, enabling sync!");
        // ss.settings.cloudSyncingEnabled.value = true;
        // ss.settings.attachmentSyncEnabled.value = false;
        // ss.saveSettings();
        // pushService.doCloudKitSync();
      }
      return;
    }
    if (push is api.PushMessage_StatusUpdate) {
      var status = push.field0;
      final result = (await Chat.findByRust(api.ConversationData(participants: [status.user]), "iMessage", soft: true));
      if (result == null) return;
      result.notifsSilenced = !status.allowed;
      result.save(updateNotifsSilenced: true);
      cvc(result).recipientNotifsSilenced.value = !status.allowed;
      cvc(result).chat.notifsSilenced = !status.allowed; // make sure all our objects are in sync lmao
      return;
    }

    if (push is api.PushMessage_TwoFaAuthEvent) {
      if (push.field0 && authing) {
        // Success
        Get.back();
      }
      return;
    }

    if (push is api.PushMessage_Idms) {
      var message = push.field0;
      if (message is api.IdmsMessage_RequestedSignIn) {
        notif.notifySignInRequest(message.field0);
      } else if (message is api.IdmsMessage_TeardownSignIn) {
        await mcs.invokeMethod("apple-account-login", {
          "txnid": message.field0.prevtxnid,
        });
      }
      print("Got idms message");
      return;
    }

    if (push is api.PushMessage_FaceTime) {
      var facetime = push.field0;
      if (facetime is api.FTMessage_AddMembers ||
          facetime is api.FTMessage_RemoveMembers ||
          facetime is api.FTMessage_LeaveEvent ||
          facetime is api.FTMessage_JoinEvent) {
        await updateState();
      }
      String? ring;
      if (facetime is api.FTMessage_JoinEvent) {
        if (facetime.ring) {
          ring = facetime.guid;
        }
        if (facetime.guid == currentOutgoingCall?.value) {
          currentOutgoingCall?.value = "accepted";
          hideFaceTimeOverlay(facetime.guid);

          outgoingCallTimer?.cancel();
          chosenFTRoomGuid = facetime.guid;

          if (Platform.isAndroid) {
            await mcs.invokeMethod("launch-facetime", outgoingCallMeta);
          } else {
            await launchUrl(
                Uri.parse(outgoingCallMeta['link']),
                mode: LaunchMode.externalApplication
            );
          }
          
          incomingRingingCallGuid = null;
        }
      } else if (facetime is api.FTMessage_AddMembers) {
        if (facetime.ring) {
          ring = facetime.guid;
        }
      } else if (facetime is api.FTMessage_Ring) {
        ring = facetime.guid;
      }

      if (facetime is api.FTMessage_Decline) {
        if (currentOutgoingCall?.value == facetime.guid) {
          currentOutgoingCall?.value = "declined";
          
          outgoingCallTimer?.cancel();

          // destroy webview
          mcs.invokeMethod("update-call-state", {
            "callUuid": facetime.guid,
            "state": "timeout",
          });
          currentOutgoingCall = null;
        }
      }

      if (ring != null) {
        String? existingCall = await mcs.invokeMethod("get-active-call");
        if (existingCall == ring) {
          // we already answered this call
          Logger.info("Not ringing call $ring because we have already answered it!");
          return;
        }

        var session = getSessionName(ring, true);
        if (session == null) {
          Logger.warn("Rung call $ring not found in active sessions!");
          return;
        }
        var link = await api.getFtLink(facetime: pushService.state!.ftClient, usage: "nextincomingcall");
        rotateIncomingLink();
        incomingRingingCallGuid = ring;

        String? myPoster;
        Uint8List? icon;
        var identity = getSessionIdentity(ring, true);
        if (identity != null) {
          var handle = RustPushBBUtils.rustHandleToBB(identity);
          if (handle.isBlocked()) {
            incomingRingingCallGuid = null;
            Logger.info("Dropping call from blocked handle $handle");
            return;
          }
          icon = handle.contact?.avatar;
          var poster = handle.getPoster();
          if (poster != null && !kIsDesktop) {
            var loaded = await api.fromPosterSave(poster: await File("$poster.jpg").readAsBytes());
            var images = await loadPosterImages(poster, loaded.poster);

            var recorder = ui.PictureRecorder();
            var canvas = Canvas(recorder);

            var painter = PosterPainter(poster: loaded.poster, images: images, name: handle.displayName);

            Map<dynamic, dynamic> results = await mcs.invokeMethod("get-full-resolution");

            var size = Size((results["width"]! as int).toDouble(), (results["height"]! as int).toDouble());
            canvas.scale(results["ratio"]! as double);
            painter.paint(canvas, size / (results["ratio"]! as double));

            ui.Picture picture = recorder.endRecording();
            ui.Image image = await picture.toImage(size.width.toInt(), size.height.toInt());

            Uint8List bytes = (await image.toByteData(format: ui.ImageByteFormat.png))!.buffer.asUint8List();
            File file = File("$poster-preview.png");
            await file.writeAsBytes(bytes);
            myPoster = file.path;
          }
        }

        ah.handleIncomingFaceTimeCall({
          "uuid": ring,
          "address": session,
          "link": link,
          "icon": icon,
          "poster": myPoster,
        });
      }

      if (facetime is api.FTMessage_LeaveEvent) {
        var nonActive = sessions.firstWhereOrNull((a) => a.groupId == facetime.guid);
        if (nonActive != null) {
          if (incomingRingingCallGuid != null) {
            var session = getSessionName(facetime.guid, false);
            if (session == null) {
              Logger.warn("Missed call $ring not found in active sessions!");
              return;
            }
            // this is a missed call
            notif.createMissedCallNotification(session, facetime.guid);
            incomingRingingCallGuid = null;
          }

          hideFaceTimeOverlay(facetime.guid, timeout: true); // they have given up the ringing
        }
      }

      if (facetime is api.FTMessage_RespondedElsewhere) {
        hideFaceTimeOverlay(facetime.guid, timeout: true); // they have given up the ringing
        incomingRingingCallGuid = null;
      }

      if (facetime is api.FTMessage_LetMeInRequest) {
        var approvedGroup = chosenFTRoomGuid;
        if (facetime.field0.usage == "incomingcall" || facetime.field0.usage == "nextincomingcall") {
          approvedGroup = incomingRingingCallGuid;
          incomingRingingCallGuid = null;
        }
        await api.answerFtRequest(facetime: pushService.state!.ftClient, request: facetime.field0, approvedGroup: approvedGroup);
      }
      return;
    }

    if (push is api.PushMessage_RegistrationState) {
      var state = push.field0;
      if (state is api.RegisterState_Registered) {
        notifiedFailed = false;
        if (ss.settings.deviceIsHosted.value) {
          mixpanel?.track("hosted-register-success");
        }
        handleRegistered();
      }
      if (state is api.RegisterState_Failed && !notifiedFailed) {
        if (ss.settings.deviceIsHosted.value) {
          mixpanel?.track("hosted-register-failure");
        }
        notif.createRegisterFailed(state.retryWait == null);
        if (state.retryWait == null) {
          pushService.markFailedToLogin(hw: false);
        }
        notifiedFailed = true;
      }
      return;
    }

    if (push is api.PushMessage_BeaconShared) {
      notif.createBeaconInvitation(RustPushBBUtils.rustHandleToBB(push.sender), push.attributes);
      return;
    }

    if (push is api.PushMessage_NewPhotostream) {
      var state = push.field0;
      notif.createInvitation(state);
      return;
    }

    if (push is api.PushMessage_SendConfirm) {
      var message = Message.findOne(guid: push.uuid);
      if (message == null) return;
      Logger.info("SendFinished");
      message.sendingServiceId = null;
      message.save(updateSendingServiceId: true);
      return;
    }

    var myMsg = (push as api.PushMessage_IMessage).field0;
    Logger.info("starting ${myMsg.id}");
    if (myMsg.message is api.Message_EnableSmsActivation) {
      if (myMsg.verificationFailed) return;
      var message = myMsg.message as api.Message_EnableSmsActivation;
      try {
        var peerUuid = await api.convertTokenToUuid(state: pushService.state!.client, handle: myMsg.sender!, token: (myMsg.target!.first as api.MessageTarget_Token).field0);
        if (message.field0) {
          ss.settings.smsForwardingTargets[myMsg.sender!] = peerUuid;
        } else {
          if (ss.settings.smsForwardingTargets.containsKey(myMsg.sender!)) {
            ss.settings.smsForwardingTargets.remove(myMsg.sender!);
          }
        }
        ss.saveSettings();
      } catch (e) {
        showSnackbar("Error", "Error activating SMS forwarding");
        rethrow;
      }
      return;
    }
    if (myMsg.message is api.Message_SetTranscriptBackground) {
      var innerMsg = myMsg.message as api.Message_SetTranscriptBackground;

      Chat? chat;

      if (innerMsg.field0.chatId != null) {
        if (innerMsg.field0.chatId!.contains("+") || innerMsg.field0.chatId!.contains("@")) {
          chat = Chat.findByHandle(innerMsg.field0.chatId!);
        } else {
          chat = Chat.findByRustGuid(innerMsg.field0.chatId!)!;
        }
      } else {
        chat = Chat.findByHandle(RustPushBBUtils.rustHandleToBB(myMsg.sender!).address);
      }

      if (chat == null) return null;

      if (innerMsg.field0 is api.SetTranscriptBackgroundMessage_Set) {
        var value = innerMsg.field0 as api.SetTranscriptBackgroundMessage_Set;

        var path = "${(await getApplicationCacheDirectory()).path}/${Random().nextInt(9999999)}";
        var stream = api.downloadMmcs(aps: pushService.state!.conn, attachment: api.MMCSFile(
          signature: base64.decode(value.signature), 
          object: value.objectId, 
          url: value.url, 
          key: base64.decode(value.key).sublist(1), 
          size: 0,
        ), path: path);
        try {
          await for (final event in stream) {
            Logger.info("Downloaded transcript ${event.prog} bytes of ${event.total}");
          }
        } catch (e) {
          try {
            File(path).deleteSync();
          } catch (_) { }
          rethrow;
        }

        var data = await File(path).readAsBytes();
        File(path).deleteSync();
        var poster = await api.parseTranscriptPoster(payload: data);

        if (poster.poster.type is api.PosterType_TranscriptDynamic || poster.poster.type is api.PosterType_TranscriptGradient) {
          // dynamic posters are deleted posters
          if (chat.transcriptPosterPath != null) {
            await deletePoster(chat.transcriptPosterPath!);
            chat.transcriptPosterPath = null;
            chat.transcriptBackgroundVersion = innerMsg.field0.bid.toInt();
            chat.save(updateTranscriptPosterPath: true, updateTranscriptBackgroundVersion: true);
          }
        } else {
        
          var saved = await saveTranscriptPoster(poster);

          if (chat.transcriptPosterPath != null) {
            await deletePoster(chat.transcriptPosterPath!);
          }

          chat.transcriptBackgroundVersion = value.bid.toInt();
          chat.transcriptPosterPath = saved;
          chat.save(updateTranscriptPosterPath: true, updateTranscriptBackgroundVersion: true);
        }
      } else {
        if (chat.transcriptPosterPath != null) {
          await deletePoster(chat.transcriptPosterPath!);
          chat.transcriptPosterPath = null;
          chat.transcriptBackgroundVersion = innerMsg.field0.bid.toInt();
          chat.save(updateTranscriptPosterPath: true, updateTranscriptBackgroundVersion: true);
        }
      }
      cvc(chat).chat.transcriptPosterPath = chat.transcriptPosterPath;
      cvc(chat).updatePoster();
      markBackgroundChange(myMsg.sender!, myMsg.sentTimestamp, chat);
      return;
    }
    if (myMsg.message is api.Message_ShareProfile) {
      // someone shared to us
      var message = myMsg.message as api.Message_ShareProfile;
      await handleSharedProfile(message.field0, myMsg.sender!, []);
      return;
    }
    if (myMsg.message is api.Message_UpdateProfileSharing) {
      var message = myMsg.message as api.Message_UpdateProfileSharing;
      ss.settings.sharedContacts.value = message.field0.sharedAll;
      ss.settings.dismissedContacts.value = message.field0.sharedDismissed;
      ss.settings.shareVersion.value = message.field0.version;
      ss.saveSettings();
      return;
    }
    if (myMsg.message is api.Message_UpdateProfile) {
      var message = myMsg.message as api.Message_UpdateProfile;
      ss.settings.nameAndPhotoSharing.value = message.field0.profile != null;
      if (message.field0.profile != null) {
        ss.settings.shareProfileMessage.value = await api.encodeProfileMessage(p: message.field0.profile!);
        // delete old data
        if (ss.settings.userAvatarPath.value != null) {
          try {
           await File(ss.settings.userAvatarPath.value!).delete(); 
          } catch (e) { /*pass*/ }
          ss.settings.userAvatarPath.value = null;
        }
        if (ss.settings.userPosterPath.value != null) {
          try {
            await deletePoster(ss.settings.userPosterPath.value!);
          } catch (e) { /*pass*/ }
          ss.settings.userPosterPath.value = null;
        }
        ss.settings.shareContactAutomatically.value = message.field0.shareContacts;
        ss.saveSettings();
        
        var profile = pushService.state?.icloudServices?.profilesClient;
        if (profile == null) return;
        var result = await api.fetchProfile(profiles: profile, message: message.field0.profile!);

        if (result.image != null) {
          String appDocPath = fs.appDocDir.path;
          File file = File("$appDocPath/avatars/you/avatar-${result.image!.length}.jpg");
          if (!(await file.exists())) {
            await file.create(recursive: true);
          }
          await file.writeAsBytes(result.image!);
          ss.settings.userAvatarPath.value = file.path;
        }

        if (result.poster != null && !kIsDesktop) {
          var decoded = await api.parsePoster(poster: result.poster!);
          try {
            ss.settings.userPosterPath.value = await savePoster(decoded);
          } catch (e, t) {
            Logger.error("Could not decode poster", error: e, trace: t); 
          }
        }

        ss.settings.firstName.value = result.name.first;
        ss.settings.lastName.value = result.name.last;
        ss.settings.userName.value = result.name.name;
      } else {
        ss.settings.shareProfileMessage.value = null;
      }
      ss.saveSettings();
      return;
    }
    if (myMsg.message is api.Message_Error) {
      var message = myMsg.message as api.Message_Error;
      var mistakeFor = Message.findOne(guid: message.field0.forUuid);
      // if we've been delivered, well :shrug: probably some stray device complaining 
      if (mistakeFor == null || mistakeFor.isDelivered) return; // multiple errors will likely come in, at which point guid will be bad.
      // do not flag 300 error messages for self handles
      var myHandles = (await api.getHandles(state: pushService.state!.client));
      if (!myHandles.contains(myMsg.sender)) return;

      markFailed(mistakeFor, message.field0.statusStr);
      return;
    }
    if (myMsg.message is api.Message_UpdateExtension) {
      var message = myMsg.message as api.Message_UpdateExtension;
      var subject = Message.findOne(guid: message.field0.forUuid);
      if (subject == null) return;
      subject.verificationFailed = myMsg.verificationFailed;
      var data = message.field0.ext;
      if (data is! api.PartExtension_Sticker) return;
      var body = subject.attributedBody.first.toMap();
      body["runs"].first["attributes"]["sticker"] = stickerFromDart(data).toMap();
      subject.attributedBody = [AttributedBody.fromMap(body)];
      subject.save();
      return;
    }
    if (myMsg.message is api.Message_PeerCacheInvalidate) {
      invalidatePeerCaches();
      return;
    }
    if (myMsg.message is api.Message_SmsConfirmSent) {
      var message = Message.findOne(guid: myMsg.id)!;
      if (myMsg.verificationFailed) return;
      var msg = myMsg.message as api.Message_SmsConfirmSent;
      if (msg.field0) {
        message.guid = message.stagingGuid;
        message.stagingGuid = null;
        message.save();
      } else {
        // message failed to send
        var m = message;
        var c = m.chat.target!;
        var lastGuid = m.guid;
        m = handleSendError(Exception("Failed to send SMS"), m);

        if (!ls.isAlive || !(cm.getChatController(c.guid)?.isAlive ?? false)) {
          await notif.createFailedToSend(c);
        }
        await Message.replaceMessage(lastGuid, m);
        ah.attachmentProgress.removeWhere((e) => e.item1 == lastGuid || e.item2 >= 1);
      }
      return;
    }
    if (myMsg.message is api.Message_MoveToRecycleBin) {
      var msg = (myMsg.message as api.Message_MoveToRecycleBin).field0;
      var target = msg.target;
      if (target is api.DeleteTarget_Messages) {
        for (var message in target.field0) {
          var msg2 = Message.findOne(guid: message);
          if (msg2 == null) continue;
          ms(msg2.getChat()!.guid).removeMessage(msg2);
          msg2.dateDeleted = DateTime.fromMillisecondsSinceEpoch(msg.recoverableDeleteDate);
          msg2.save();
        }
      } else if (target is api.DeleteTarget_Chat) {
        var msg2 = await findOperatedChat(target.field0);
        if (msg2 != null) {
          chats.removeChat(msg2);
          Chat.softDelete(msg2, markDeleted: false);
        }
      }
      return;
    }
    if (myMsg.message is api.Message_RecoverChat) {
      var target = (myMsg.message as api.Message_RecoverChat).field0;
      var msg2 = await findOperatedChat(target);
      if (msg2 != null) {
        Chat.unDelete(msg2);
        msg2.restoreTranscript();
        await chats.addChat(msg2);
      }
      return;
    }
    if (myMsg.message is api.Message_PermanentDelete) {
      var target = (myMsg.message as api.Message_PermanentDelete).field0.target;
      if (target is api.DeleteTarget_Chat) {
        var msg2 = await findOperatedChat(target.field0);
        if (msg2 == null) return;
        if (msg2.dateDeleted != null) {
          chats.removeChat(msg2);
          Chat.deleteChat(msg2); // perma delete
        } else {
          // some messages are deleted
          final query = (Database.messages.query(Message_.dateDeleted.notNull())
              ..link(Message_.chat, Chat_.id.equals(msg2.id!)))
              .build();
          for (var message in query.find()) {
            for (var attachment in (message.fetchAttachments() ?? [])) {
              if (attachment == null) continue;
              try {
                File(attachment.getFile().path!).deleteSync();
              } catch(e) {
                Logger.debug("Failed to rm attachment $e");
              }
            }
            Message.delete(message.guid!);
          }
        }
      } else if (target is api.DeleteTarget_Messages) {
        for (var msg in target.field0) {
          var message = Message.findOne(guid: msg);
          if (message == null) continue;
          for (var attachment in (message.fetchAttachments() ?? [])) {
            if (attachment == null) continue;
            try {
              File(attachment.getFile().path!).deleteSync();
            } catch(e) {
              Logger.debug("Failed to rm attachment $e");
            }
          }
          // do this to update UI
          ms(message.getChat()!.guid).removeMessage(message);
          Message.delete(message.guid!);
        }
      }
      return;
    }
    if (myMsg.message is api.Message_Delivered || myMsg.message is api.Message_Read) {
      var myHandles = (await api.getHandles(state: pushService.state!.client));
      var message = Message.findOne(guid: myMsg.id);
      if (message == null) {
        return;
      }
      if (myMsg.verificationFailed) return;
      if (myHandles.contains(myMsg.sender) && message.chat.target!.isIMessage) {
        if (myMsg.message is api.Message_Read) {
          var chat = message.chat.target!;
          chat.toggleHasUnread(false, privateMark: false);
        }
        return; // delivered to other devices is not
      }
      if (myMsg.message is api.Message_Delivered) {
        message.dateDelivered = parseDate(myMsg.sentTimestamp);
      } else {
        message.dateRead = parseDate(myMsg.sentTimestamp);
      }
      if (message.chat.target!.notifsSilenced) {
        var lastNotifiedAnyways = message.chat.target!.dateNotifiedAnyways;
        message.wasDeliveredQuietly = lastNotifiedAnyways == null || DateTime.now().difference(lastNotifiedAnyways).inMinutes > 5;
      }
      message.save();
      inq.queue(IncomingItem(
        chat: message.chat.target!,
        message: message,
        type: QueueType.updatedMessage
      ));
      return;
    }
    var chat = await chatForMessage(myMsg);
    if (myMsg.message is api.Message_RenameMessage) {
      var msg = myMsg.message as api.Message_RenameMessage;
      if (myMsg.verificationFailed) return; 
      if (!chat.lockChatName) {
        chat.displayName = msg.field0.newName;
      }
      chat.apnTitle = msg.field0.newName;
      myMsg.conversation?.cvName = msg.field0.newName;
      chat = chat.save(updateDisplayName: true, updateAPNTitle: true);
    }
    if (myMsg.message is api.Message_MarkUnread) {
      chat.hasUnreadMessage = true;
      chat.save(updateHasUnreadMessage: true);
      return;
    }
    if (myMsg.message is api.Message_Typing) {
      if (myMsg.verificationFailed) return; 
      final controller = cvc(chat);
      var handle = RustPushBBUtils.rustHandleToBB(myMsg.sender!);

      if (controller.typingIndicatorData[handle.address] != null) {
        controller.typingIndicatorData[handle.address]?.$1.cancel();
        controller.typingIndicatorData.remove(handle.address);
      }

      var typing = myMsg.message as api.Message_Typing;
      if (typing.field0) {
        if (!controller.showTypingIndicatorFor.any((h) => handle.address == h.address)) {
          controller.showTypingIndicatorFor.add(handle);
        }
        var future = Future.delayed(const Duration(minutes: 1));
        var subscription = future.asStream().listen((any) {
          controller.showTypingIndicatorFor.remove(handle);
          controller.typingIndicatorData.remove(handle.address);
        });
        Uint8List? icon;
        if (typing.field1 != null) {
          String? i = es.cachedStatus.firstWhereOrNull((i) => i.madridBundleId == typing.field1!.bundleId)?.available?.icon;
          if (i != null) {
            icon = base64Decode(i);
          } else {
            icon = typing.field1!.icon;
          }
        }
        controller.typingIndicatorData[handle.address] = (subscription, icon);
      } else {
        var existing = controller.showTypingIndicatorFor.firstWhereOrNull((h) => handle.address == h.address);
        if (existing != null) {
          controller.showTypingIndicatorFor.remove(existing);
        }
      }
      return;
    }
    if (myMsg.message is api.Message_Message) {
      final controller = cvc(chat);
      
      var handle = RustPushBBUtils.rustHandleToBB(myMsg.sender!);
      var existing = controller.showTypingIndicatorFor.firstWhereOrNull((h) => handle.address == h.address);
      if (existing != null) {
        controller.showTypingIndicatorFor.remove(existing);
      }
      if (controller.typingIndicatorData[handle.address] != null) {
        controller.typingIndicatorData[handle.address]?.$1.cancel();
        controller.typingIndicatorData.remove(handle.address);
      }

      if (chat.isRpSms && !myMsg.verificationFailed) {
        var myHandles = await api.getMyPhoneHandles(state: pushService.state!.client);
        var service = (myMsg.message as api.Message_Message).field0.service;
        if (service is api.MessageType_SMS && myHandles.contains(service.usingNumber)) {
          var otherIds = ss.settings.smsRoutingTargets.copy();
          var myToken = (myMsg.target!.first as api.MessageTarget_Token).field0;
          var myId = await api.convertTokenToUuid(state: pushService.state!.client, handle: myMsg.sender!, token: myToken);
          otherIds.remove(myId);
          if (otherIds.isNotEmpty) {
            myMsg.target = otherIds.map((element) => api.MessageTarget.uuid(element)).toList(); // forward to other devices
            await (backend as RustPushBackend).sendMsg(myMsg);
          }
          var msg = (await pushService.reflectMessageDyn(myMsg))!;
          msg.temp = true;
          msg.forwardIfNessesary(chat);
          return;
        }
      }
      var msg = myMsg.message as api.Message_Message;
      if (msg.field0.embeddedProfile != null) {
        handleSharedProfile(msg.field0.embeddedProfile!, myMsg.sender!, chat.participants);
      }
      if ((await msg.field0.parts.rawText()) == "" &&
          msg.field0.parts.field0.none((p0) => p0.part_ is api.MessagePart_Attachment)) {
        return;
      }
    }
    Logger.info("Reflecting ${myMsg.id}");
    var reflected = await pushService.reflectMessageDyn(myMsg);
    Logger.info("Reflect finished ${myMsg.id}");
    if (reflected != null) {
      Logger.info("Queing");
      await inq.queue(IncomingItem(
        chat: chat,
        message: reflected,
        type: QueueType.newMessage
      ));
    }
  }

  Future<Placemark?> reverseGeocode(double lat, double lng) async {
    try {
      var result = await placemarkFromCoordinates(lat, lng);
      return result.firstOrNull;
    } catch (e, s) {
      Logger.warn("failed to native geocode, falling back to nominatim", error: e, trace: s);
      var request = await http.dio.get("https://nominatim.openstreetmap.org/reverse?lat=$lat&lon=$lng&format=jsonv2&zoom=10", options: Options(
        headers: {
          "User-Agent": "OpenBubbles"
        }
      ));
      // Logger.info("Got location $request");
      return Placemark(
        name: request.data["name"],
        isoCountryCode: request.data["address"]?["country_code"],
        country: request.data["address"]?["country"],
        locality: request.data["address"]?["city"],
        administrativeArea: request.data["address"]?["state"],
        subAdministrativeArea: request.data["address"]?["county"],
      );
    }
  }
  
  Timer? myTimer;

  List<Function> subscriptions = [];
  Function subscribeToLocationUpdates(Function subscribe) {
    var timer = ((timer) async {
      var subs = await api.refreshBackgroundFollowing(state: pushService.state!.icloudServices!.fmfd!, config: pushService.state!.osConfig);
      for (var sub in subscriptions) {
        sub(subs);
      }
    });
    if (subscriptions.isEmpty) {
      myTimer = Timer.periodic(const Duration(seconds: 5), timer);
    }
    timer(null);
    subscriptions.add(subscribe);
    return () {
      subscriptions.remove(subscribe);
      if (subscriptions.isEmpty) {
        myTimer!.cancel();
        myTimer = null;
      }
    };
  }

  Future updateChatPoster(Chat chat) async {    
    api.SetTranscriptBackgroundMessage Function(String? chat) message;
    if (chat.transcriptPosterPath != null) {
      api.SimplifiedTranscriptPoster poster = await api.fromTranscriptPosterSave(poster: await File("${chat.transcriptPosterPath!}.jpg").readAsBytes());
      await restorePoster(poster.poster, chat.transcriptPosterPath!);
      var result = await api.packTranscriptPoster(payload: poster);

      var path = "${(await getApplicationCacheDirectory()).path}/${Random().nextInt(9999999)}";
      await File(path).writeAsBytes(result);

      var mmcsStream = api.uploadMmcs(aps: pushService.state!.conn, path: path);
      api.MMCSFile? mmcs;
      await for (final event in mmcsStream) {
        if (event.file != null) {
          Logger.info("upload finish");
          mmcs = event.file;
        } else {
          Logger.info("upload progress ${event.prog} of ${event.total}");
        }
      }

      File(path).deleteSync();

      // ns since core data epoch
      chat.transcriptBackgroundVersion = (DateTime.now().microsecondsSinceEpoch - 978307200000000) * 1000;
      chat.save(updateTranscriptBackgroundVersion: true);

      message = (c) => api.SetTranscriptBackgroundMessage.set_(
        aid: 1, 
        bid: BigInt.from(chat.transcriptBackgroundVersion), 
        objectId: mmcs!.object, 
        payloadVersion: 1, 
        backgroundId: uuid.v4().toUpperCase(), 
        url: mmcs.url, 
        signature: base64Encode(mmcs.signature), 
        key: base64Encode([0, ...mmcs.key]), 
        fileSize: BigInt.from(mmcs.size),
        chatId: c,
      );
    } else {
      chat.transcriptBackgroundVersion++;
      chat.save(updateTranscriptBackgroundVersion: true);

      message = (c) => api.SetTranscriptBackgroundMessage.remove(
        aid: 1, 
        bid: BigInt.from(chat.transcriptBackgroundVersion), 
        remove: true,
        chatId: c,
      );
    }

    var myhandle = await chat.ensureHandle();
    if (chat.participants.length > 1) {
      var m = message(chat.guid);
      var msg = await api.newMsg(
            conversation: await chat.getConversationData(),
            message: api.Message.setTranscriptBackground(m),
            sender: myhandle);
      await (backend as RustPushBackend).sendMsg(msg);
    } else {
      var cv = await chat.getConversationData();
      cv.participants.remove(myhandle);

      var msg = await api.newMsg(
            conversation: cv,
            message: api.Message.setTranscriptBackground(message(null)),
            sender: myhandle);
      await (backend as RustPushBackend).sendMsg(msg);

      cv.participants = [myhandle];
      var msg2 = await api.newMsg(
            conversation: cv,
            message: api.Message.setTranscriptBackground(message(chat.participants[0].address)),
            sender: myhandle);
      await (backend as RustPushBackend).sendMsg(msg2);
    }

    markBackgroundChange(myhandle, DateTime.now().millisecondsSinceEpoch, chat);
  }

  Future<void> updateCardDav() async {
    final server = TextEditingController(text: ss.settings.cardDavServer.value);
    final user = TextEditingController(text: ss.settings.cardDavUser.value);
    final pass = TextEditingController(text: ss.settings.cardDavPass.value);
    done() async {
      if (server.text.isEmpty) {
        showSnackbar("Error", "Enter a server!");
        return;
      }
      Get.back();
      ss.settings.cardDavServer.value = server.text;
      ss.settings.cardDavUser.value = user.text;
      ss.settings.cardDavPass.value = pass.text;
      await ss.saveSettings();
      cs.refreshContacts();
    }
    await showDialog(
        context: Get.context!,
        builder: (_) {
          return AlertDialog(
            actions: [
              TextButton(
                child: Text("Cancel", style: Get.context!.theme.textTheme.bodyLarge!.copyWith(color: Get.context!.theme.colorScheme.primary)),
                onPressed: () => Get.back(),
              ),
              TextButton(
                child: Text("OK", style: Get.context!.theme.textTheme.bodyLarge!.copyWith(color: Get.context!.theme.colorScheme.primary)),
                onPressed: () async {
                  done.call();
                },
              ),
            ],
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: server,
                  autofocus: true,
                  textInputAction: TextInputAction.next,
                  decoration: const InputDecoration(
                    labelText: "Server URL",
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16,),
                TextField(
                  controller: user,
                  textInputAction: TextInputAction.next,
                  decoration: const InputDecoration(
                    labelText: "Username",
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16,),
                TextField(
                  controller: pass,
                  onSubmitted: (_) => done.call(),
                  decoration: const InputDecoration(
                    labelText: "Password",
                    border: OutlineInputBorder(),
                  ),
                )
              ],
            ),
            title: Text("Set CardDav details", style: Get.context!.theme.textTheme.titleLarge),
            backgroundColor: Get.context!.theme.colorScheme.properSurface,
          );
        }
    );
  }

  Future<(bool, String?)> promptPassword(api.ViableBottle bottle, String desc) async {
    var context = Get.context!;
    bool change = false;
    bool obscureText = true;
    String? text;
    var codeController = TextEditingController();
    await showDialog(
      context: context,
      builder: (_) {
        return AlertDialog(
          actions: [
            TextButton(
              child: Text("Choose Device", style: context.theme.textTheme.bodyLarge!.copyWith(color: context.theme.colorScheme.primary)),
              onPressed: () {
                text = null;
                change = true;
                Get.back();
              },
            ),
            TextButton(
              child: Text("OK", style: context.theme.textTheme.bodyLarge!.copyWith(color: context.theme.colorScheme.primary)),
              onPressed: () async {
                text = codeController.text;
                Get.back();
              },
            ),
          ],
          title: Text("Enter the ${bottle.numericLength > 0 ? "passcode" : "password"} for “${bottle.deviceName}”", style: context.theme.textTheme.titleLarge),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(desc),
              const SizedBox(height: 20,),
              bottle.numericLength > 0 ? StatefulBuilder(builder: (context, state) => Stack(
                children: [
                  Row(
                    children: List.generate(bottle.numericLength, (index) {
                      var text = index < codeController.text.length ? "•" : "";
                      return Expanded(child: 
                        Container(
                          decoration: index == codeController.text.length ? 
                            BoxDecoration(
                              border: Border.all(
                                color: context.theme.colorScheme.primary,
                                width: 2
                              ),
                              borderRadius: const BorderRadius.all(Radius.circular(10)),
                            )
                          : BoxDecoration(
                            border: Border.all(
                              color: context.theme.colorScheme.outline,
                            ),
                            borderRadius: const BorderRadius.all(Radius.circular(10)),
                          ),
                          margin: const EdgeInsets.all(3),
                          height: 50,
                          child: Center(
                            child: Text(
                              text,
                              style: context.theme.textTheme.titleLarge?.copyWith(fontSize: 40, fontWeight: FontWeight.bold)
                            ),
                          )
                        )
                      );
                    }),
                  ),
                  Opacity(
                    opacity: 0,
                    child: TextField(
                      cursorColor: context.theme.colorScheme.primary,
                      autocorrect: false,
                      autofocus: true,
                      controller: codeController,
                      textInputAction: TextInputAction.next,
                      keyboardType: TextInputType.number,
                      onChanged: (v) {
                        state(() {});
                      },
                    )),
                ],
              )) : StatefulBuilder(builder: (context, update) => TextField(
                controller: codeController,
                decoration: InputDecoration(
                  labelText: "Password",
                  border: const OutlineInputBorder(),
                  suffixIcon: IconButton(
                    icon: Icon(obscureText ? Icons.visibility_off : Icons.visibility),
                    color: context.theme.colorScheme.outline,
                    onPressed: () {
                      update(() {
                        obscureText = !obscureText;
                      });
                    },
                  ),
                ),
                autofocus: true,
                obscureText: obscureText,
              ))
            ],
          ),
          backgroundColor: context.theme.colorScheme.properSurface,
        );
      }
    );
    return (change, text);
  }

  final googleSignIn = GoogleSignIn(
    // See 'How to Get Google OAuth Credentials' section below
    params: const GoogleSignInParams(
      clientId: clientId,
      clientSecret: clientSecret, // Don't worry - not truly a secret! See 'Client Secret Requirements'
      scopes: ['https://www.googleapis.com/auth/carddav'],
    ),
  );

  Future<api.ViableBottle?> promptChange(List<api.ViableBottle> bottles) async {
    var context = Get.context!;
    api.ViableBottle? newBottle;
    var promptReset = false;
    await showDialog(
      context: context,
      builder: (_) {
        return AlertDialog(
          actions: [
            TextButton(
              child: Text("Don't know any passwords", style: context.theme.textTheme.bodyLarge!.copyWith(color: context.theme.colorScheme.primary)),
              onPressed: () {
                promptReset = true;
                Get.back();
              },
            ),
          ],
          title: Text("Choose a device", style: context.theme.textTheme.titleLarge),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: bottles.map((bottle) => Material( // provides a Material ancestor for the ripple
                color: Colors.transparent,
                child: InkWell(
                  onTap: () {
                    newBottle = bottle;
                    Get.back();
                  },
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    child: Text(
                      bottle.deviceName,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ),
                ),
                
              )).toList(),
            ),
          ),
          backgroundColor: context.theme.colorScheme.properSurface,
        );
      }
    );
    if (promptReset) {
      await promptResetData(false);
    }
    return newBottle;
  }

  Future<void> promptResetData(bool mandatory) async {
    var context = Get.context!;
    await showDialog(
      context: context,
      builder: (_) {
        return AlertDialog(
          actions: [
            TextButton(
              child: Text("Cancel", style: context.theme.textTheme.bodyLarge!.copyWith(color: context.theme.colorScheme.primary)),
              onPressed: () {
                Get.back();
              },
            ),
            TextButton(
              child: Text("Reset encrypted data", style: context.theme.textTheme.bodyLarge!.copyWith(color: context.theme.colorScheme.primary)),
              onPressed: () async {
                var defaultPassword = Random.secure().nextInt(1000000).toString().padLeft(6, '0');
                ss.settings.keychainDefaultPassword.value = defaultPassword;
                ss.saveSettings();

                Get.back();
                await wrapPromise(api.resetClique(keychain: pushService.state!.icloudServices!.keychain!, cloudMessages: pushService.state!.icloudServices!.cloudMessagesClient!, devicePassword: defaultPassword), "Resetting clique...");

                showDialog(
                  context: Get.context!,
                  builder: (_) {
                    return AlertDialog(
                      actions: [
                        TextButton(
                          child: Text("Ok", style: Get.context!.theme.textTheme.bodyLarge!.copyWith(color: Get.context!.theme.colorScheme.primary)),
                          onPressed: () async {
                            Get.back();
                          },
                        ),
                      ],
                      title: Text("Encrypted data reset", style: Get.context!.theme.textTheme.titleLarge),
                      content: Text.rich(
                        TextSpan(
                          text: "This device's iCloud Keychain code is ",
                          style: Get.context!.theme.textTheme.bodyLarge,
                          children: <TextSpan>[
                            TextSpan(
                              text: '${ss.settings.keychainDefaultPassword.value}',
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                            const TextSpan(
                              text: '.',
                            ),
                            const TextSpan(
                              text: '\n\nYou will need this code to sync iCloud data on other devices. ',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            const TextSpan(
                              text: 'This code can be found again in Settings -> Device.',
                            ),
                          ],
                        ),
                      ),
                      backgroundColor: Get.context!.theme.colorScheme.properSurface,
                    );
                  }
                );
              },
            ),
          ],
          title: Text("Reset data?", style: context.theme.textTheme.titleLarge),
          content: Text(mandatory ? "Your encrypted data needs to be reset." : "If you can't remember the credentials to any of your devices, you won't be able to recover your data.", style: context.theme.textTheme.bodyLarge),
          backgroundColor: context.theme.colorScheme.properSurface,
        );
      }
    );
  }

  Future<int> attemptBottle(api.ViableBottle bottle) async {
    var desc = "Your device's password is required to access end-to-end encrypted data in iCloud.";
    while (true) {
      var (change, password) = await promptPassword(bottle, desc);
      if (change) return 2;
      if (password == null) return 1;

      var defaultPassword = Random.secure().nextInt(1000000).toString().padLeft(6, '0');
      ss.settings.keychainDefaultPassword.value = defaultPassword;
      ss.saveSettings();

      if(!await wrapPromise((() async {
        try {
          await api.joinCliqueWithBottle(keychain: pushService.state!.icloudServices!.keychain!, bottle: bottle.escrow, password: password, devicePassword: defaultPassword);
        } catch (e) {
          if (e is AnyhowException) {
            if (e.message.contains("Credential is not verified.")) {
              desc = "Invalid Credential";
              return false;
            }
          }
          rethrow;
        }
        return true;
      })(), "Opening bottle...")) {
        continue;
      }
      break;
    }

    return 0;
  }

  Future<T> wrapPromise<T>(Future<T> inner, String text) async {
    showDialog(
      context: Get.context!,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: context.theme.colorScheme.properSurface,
          title: Text(
            text,
            style: context.theme.textTheme.titleLarge,
          ),
          content: Container(
            height: 70,
            child: Center(
              child: CircularProgressIndicator(
                backgroundColor: context.theme.colorScheme.properSurface,
                valueColor: AlwaysStoppedAnimation<Color>(context.theme.colorScheme.primary),
              ),
            ),
          ),
        );
      }
    );
    T result;
    try {
      result = await inner;
    } catch (e, s) {
      Get.back();
      showSnackbar("Failure! Please try again", e.toString());
      rethrow;
    }
    Get.back();
    return result;
  }

  Future<bool> checkClique() async {
    var isInClique = await api.isInClique(keychain: pushService.state!.icloudServices!.keychain!);
    cachedInClique = isInClique;
    return isInClique;
  }

  Future<bool> joinClique() async {
    var isInClique = await checkClique();
    if (isInClique) return true;

    var bottles = await wrapPromise(api.getBottles(keychain: pushService.state!.icloudServices!.keychain!), "Fetching Bottles...");

    if (bottles.isEmpty) {
      await promptResetData(true);
      return await checkClique();
    }
    
    api.ViableBottle? bottle = bottles[0];

    while(await attemptBottle(bottle!) == 2) {
      bottle = await promptChange(bottles);
      if (bottle == null) {
        return await checkClique();
      }
    }
    return await checkClique();
  }

  void markBackgroundChange(String sender, int ms, Chat chat) async {
    var myHandles = await api.getHandles(state: pushService.state!.client);
    var msg = Message(
      guid: uuid.v4(),
      isFromMe: myHandles.contains(sender),
      handleId: RustPushBBUtils.rustHandleToBB(sender).originalROWID!,
      dateCreated: DateTime.fromMillisecondsSinceEpoch(ms),
      itemType: 7,
      groupActionType: chat.transcriptPosterPath != null ? 1 : 2,
    );

    inq.queue(IncomingItem(
      chat: chat,
      message: msg,
      type: QueueType.newMessage
    ));
  }

  api.TextFormat defaultFormat() {
    return const api.TextFormat.flags(api.TextFlags(bold: false, italic: false, underline: false, strikethrough: false));
  }

  api.TextFormat fromAttributes(Attributes attributes) {
    if (attributes.textEffect != null) {
      Map<int, api.TextEffect> effectMap = {
        Attributes.BIG: api.TextEffect.big,
        Attributes.SMALL: api.TextEffect.small,
        Attributes.SHAKE: api.TextEffect.shake,
        Attributes.NOD: api.TextEffect.nod,
        Attributes.EXPLODE: api.TextEffect.explode,
        Attributes.RIPPLE: api.TextEffect.ripple,
        Attributes.BLOOM: api.TextEffect.bloom,
        Attributes.JITTER: api.TextEffect.jitter,
      };
      return api.TextFormat.effect(effectMap[attributes.textEffect!]!);
    }
    return api.TextFormat.flags(api.TextFlags(
      bold: attributes.bold ?? false,
      italic: attributes.italic ?? false,
      underline: attributes.underline ?? false,
      strikethrough: attributes.strikethrough ?? false,
    ));
  }

  Uint8List getQrInfo(bool allowSharing, Uint8List data) {
    var b = BytesBuilder();
    b.add(utf8.encode("OABS"));
    b.addByte(allowSharing ? 0 : 1);
    b.add(data);
    // for (var slice in b.toBytes().slices(500)) {
    //   print(hex.encode(slice));
    // }
    return b.toBytes();
  }

  Future<String> uploadCode(bool allowSharing, api.DeviceInfo deviceInfo) async {
    var data = getQrInfo(allowSharing, deviceInfo.encodedData!);
    if (allowSharing) {
      return base64Encode(data);
    }
    const _chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ123456789';

    Random _rnd = Random.secure();
    String code = "MB";
    for (var i = 0; i < 4; i++) {
      code += String.fromCharCodes(Iterable.generate(
        4, (_) => _chars.codeUnitAt(_rnd.nextInt(_chars.length))));
      if (i != 3) {
        code += "-";
      }
    }

    String hash = hex.encode(sha256.convert(code.codeUnits).bytes);

    var encrypted = encryptAESCryptoJS(data, code);
    showDialog(
      context: Get.context!,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: context.theme.colorScheme.properSurface,
          title: Text(
            "Creating code...",
            style: context.theme.textTheme.titleLarge,
          ),
          content: Container(
            height: 70,
            child: Center(
              child: CircularProgressIndicator(
                backgroundColor: context.theme.colorScheme.properSurface,
                valueColor: AlwaysStoppedAnimation<Color>(context.theme.colorScheme.primary),
              ),
            ),
          ),
        );
    });
    try {
      final response = await http.dio.post(
        rpApiRoot,
        data: {
          "data": encrypted,
          "id": hash,
        }
      );
      if (response.statusCode != 200) {
        throw Exception("bad!");
      }
      return code;
    } catch (e) {
      showSnackbar("Error", "Couldn't create link!");
      rethrow;
    } finally {
      Get.back(closeOverlays: true);
    }
  }

  Future<void> markAsHandledAfter(String ptr) async {
    if (inq.isProcessing.value) {
      Logger.info("Marking as handled processing wait $ptr");
      await for (final value in inq.isProcessing.stream) {
        if (!value) break;
      }
    }
    Logger.info("Marking as handled commit $ptr");
    await api.completeMsg(ptr: ptr);
  }

  Future recievedMsgPointer(String pointer, String retry) async {
    var message = await api.ptrToDart(ptr: pointer);
    if (message == null) {
      Logger.info("bad pointer $pointer $retry");
      return;
    }
    Logger.info("waitingForInit $pointer $retry");
    await initFuture;
    var isFinal = (int.tryParse(retry) ?? 3) >= 3;
    try {
      Logger.info("Handling $pointer $retry");
      await handleMsg(message, isFinal);
      Logger.info("Marking as handled $pointer");
      await markAsHandledAfter(pointer);
    } catch (e, s) {
      Logger.error("Handle failed", error: e, trace: s);
      if (isFinal) {
        Logger.info("Failed; Marking as handled anyways $pointer");
        await markAsHandledAfter(pointer);
      }
      rethrow;
    }
  }

  void doPoll(api.ApsWatcher watcher, lib.ArcSharedPushState sharedPushState) async {
    while (true) {
      try {
        var msgRaw = await api.recvWait(state: sharedPushState, watcher: watcher);
        if (msgRaw is api.PollResult_Stop) {
          break;
        }
        if (msgRaw is PanicException) {
          if ((msgRaw as PanicException).message.contains("Wrong phase!")) {
            break;
          }
        }
        var msg = (msgRaw as api.PollResult_Cont).field0;
        if (msg == null) {
          continue;
        }
        await handleMsg(msg, true);
      } catch (e, t) {
        // if there was an error somewhere, log it and move on.
        // don't stop our loop
        Logger.error("$e: $t");
      }
    }
    watcher.dispose();
  }

  void hello() {
    // used to get GetX to get up off it's ass
  }

  late Future initFuture;

  Future<bool> setupZenMode(bool val) async {
    if (val) {
      if (pushService.state?.icloudServices?.statuskitClient == null) {
        showSnackbar("Relog Required", "Re-log in Settings -> Reconfigure to use zen modes");
        ss.settings.zenModeAware.value = false;
        ss.saveSettings();
        return false;
      }
      if (!await mcs.invokeMethod("zen-mode-setup")) return false;
    }
    await mcs.invokeMethod("zen-mode-uuid", {"key": val ? "enable" : "disable"});
    ss.settings.enableShareZen.value = val;
    ss.settings.zenModeAware.value = true;
    ss.saveSettings();
    return true;
  }

  void onboardZenMode() async {
    if (ss.settings.zenModeAware.value || !ss.settings.finishedSetup.value) return;
    String? currentMode = await mcs.invokeMethod("get-zen-mode");
    if (currentMode == null) return;
    ss.settings.zenModeAware.value = true;
    ss.saveSettings();
    // TODO support onboarding without permissions
    await showDialog(
        context: Get.context!,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          backgroundColor: Get.theme.colorScheme.properSurface,
          title: Text("Allow OpenBubbles to share that you have notifications silenced?", style: Get.textTheme.titleLarge),
          content: Text(
            "When you're using Do Not Disturb or other modes, OpenBubbles will share with your contacts that you have notifications silenced. Focus sharing on other devices will be turned off.",
            style: Get.textTheme.bodyLarge,
          ),
          actions: [
            TextButton(
                onPressed: () => Get.back(),
                child: Text("Don't allow", style: Get.textTheme.bodyLarge!.copyWith(color: Get.theme.colorScheme.primary))),
            TextButton(
                onPressed: () async {
                  if (await setupZenMode(true)) {
                    Get.back();
                  }
                },
                child: Text("Allow", style: Get.textTheme.bodyLarge!.copyWith(color: Get.theme.colorScheme.primary)))
          ],
        ));
  }

  void offerHostedRefund(bool revoke) async {
    await showDialog(
        context: Get.context!,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          backgroundColor: Get.theme.colorScheme.properSurface,
          title: Text("Get a refund?", style: Get.textTheme.titleLarge),
          content: Text(revoke ? "You're subscribed but we don't have a device for you at this time. You can come back later, or, get a refund here. After your refund, your subscription will be cancelled." : "You're subscribed but we don't have a device for you at this time. This is on us. We usually keep devices in reserve for customers in good standing, however, for some reason, all of them are offline. If you choose to take a refund, you will get the month free and can still use OpenBubbles when we have gotten our affairs in order.",
            style: Get.textTheme.bodyLarge,
          ),
          actions: [
            TextButton(
                onPressed: () => Get.back(),
                child: Text("Cancel", style: Get.textTheme.bodyLarge!.copyWith(color: Get.theme.colorScheme.primary))),
            TextButton(
                onPressed: () async {
                  Get.back();
                  await wrapPromise((() async {
                    var details = (await pushService.getPurchaseDetails())?.purchaseToken;
                    details ??= ss.settings.hostedToken.value;
                    
                    var activated = await http.dio.post("https://hw.openbubbles.app/refund-token", data: {"purchase_token": details});
                    if (activated.statusCode != 200) {
                      throw Exception("Failed to refund ${activated.data}");
                    }
                  })(), "Refunding...");
                  showSnackbar("Success", "Refund succeded!");
                },
                child: Text("Refund", style: Get.textTheme.bodyLarge!.copyWith(color: Get.theme.colorScheme.primary)))
          ],
        ));
  }

  void tryWarnVpn() async {
    var state = await VpnConnectionDetector.isVpnActive();
    if (state && !ss.settings.vpnWarned.value && ls.isAlive) {
      ss.settings.vpnWarned.value = true;
      await ss.saveSettings();
      await showDialog(
        context: Get.context!,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          backgroundColor: Get.theme.colorScheme.properSurface,
          title: Text("VPN warning", style: Get.textTheme.titleLarge),
          content: Text(
            "It appears you may be using a VPN. Apple blocks some VPN servers from using iMessage as real iDevices bypass them. Exclude OpenBubbles from your VPN app if you have trouble sending messages.",
            style: Get.textTheme.bodyLarge,
          ),
          actions: [
            TextButton(
                onPressed: () => Get.back(),
                child: Text("Got it", style: Get.textTheme.bodyLarge!.copyWith(color: Get.theme.colorScheme.primary)))
          ],
        ));
      Logger.info("VPN connected.");
    }
  }

  bool subscribing = false;

  void handleAppLink(Uri link) async {
    var text = link.toString();
    Logger.info("Got uri stream $text");
    if ((text.startsWith("https://hw.openbubbles.app/ticket/") || text.startsWith("https://hw.openbubbles.app/waitlist/")) && ss.settings.finishedSetup.value) {
      showDialog(
        barrierDismissible: true,
        context: Get.context!,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text(
              "Welcome to Hosted!",
              style: context
                  .theme.textTheme.titleLarge,
            ),
            content: Text(
              "To get started, you'll have to drop your old device. Re-login will be required. No messages will be deleted.",
              style: context
                  .theme.textTheme.bodyLarge,
            ),
            backgroundColor: context.theme
                .colorScheme.properSurface,
            actions: <Widget>[
              TextButton(
                child: Text("Not yet",
                    style: context.theme
                        .textTheme.bodyLarge!
                        .copyWith(
                            color: context
                                .theme
                                .colorScheme
                                .primary)),
                onPressed: () {
                  Navigator.of(context).pop();
                },
              ),
              TextButton(
                child: Text("Continue",
                    style: context.theme
                        .textTheme.bodyLarge!
                        .copyWith(
                            color: context
                                .theme
                                .colorScheme
                                .primary)),
                onPressed: () async {
                  pushService.markFailedToLogin(hw: true, ui: true);
                }
              ),
            ],
          );
        },
      );
      return;
    }

    if (link.host != "www.icloud.com") return;
    var invitationId = link.queryParameters["invitation_id"];
    if (invitationId == null) return;
    await initFuture;
    if (subscribing) return;
    subscribing = true;
    showDialog(
      context: Get.context!,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: context.theme.colorScheme.properSurface,
          title: Text(
            "Subscribing...",
            style: context.theme.textTheme.titleLarge,
          ),
          content: Container(
            height: 70,
            child: Center(child: buildProgressIndicator(context)),
          ),
        );
      }
    );
    try {
      try {
        await api.subscribeToken(lock: pushService.state!.icloudServices!.sharedstreams!, token: invitationId);
      } catch (e) {
        // sometimes first one can give 500, try again
        await api.subscribeToken(lock: pushService.state!.icloudServices!.sharedstreams!, token: invitationId);
      }
      await api.getAlbums(lock: pushService.state!.icloudServices!.sharedstreams!, refresh: true);
    } catch (e, stack) {
      Logger.error("Failed to subscribe!!", error: e, trace: stack);
      Get.back();
      subscribing = false;
      showSnackbar("Error", "Failed to subscribe! Error: ${e.toString()}");
      rethrow;
    }
    Get.back();
    ns.pushLeft(Get.context!, SharedStreamsPanel());
    subscribing = false;
  }

  void initAppLinks() async {
    final _appLinks = AppLinks();

    var link = await _appLinks.getLatestLink();
    if (link != null) handleAppLink(link);
    final sub = _appLinks.uriLinkStream.listen((uri) {
        handleAppLink(uri);
    });
  }

  void validateSubState() async {
    // only show notification if we are registered
    if (state == null) {
      return;
    }
    if (!ss.settings.deviceIsHosted.value || ss.settings.hostedToken.value == null) return;
    var detail = await checkPurchaseState();
    if (!detail) {
      if (!notifiedSubFailed) {
        notif.createSubscriptionFailed();
        notifiedSubFailed = true;
      }
    } else if (notifiedSubFailed) {
      notifiedSubFailed = false;
    }
  }

  void initSyncState() {
    isSyncing.listen((syncing) {
      chats.restoring = syncing != null;
    });
    if (!ls.isUiThread) return;

    var syncing = ui.IsolateNameServer.lookupPortByName("bg_sync");
    if (syncing != null) {
      var port = ReceivePort();
      port.listen((data) {
        isSyncing.value = data;
      });
      syncing.send(port.sendPort);
    }
  }

  // uniquely identify the backend service that is running
  String serviceId = "";

  BillingClientManager client = BillingClientManager();
  bool cachedInClique = false;

  @override
  Future<void> onInit() async {
    super.onInit();
    api.doFirstTimeInit(path: fs.appDocDir.path);
    initFuture = (() async {
      statePath = (await getApplicationSupportDirectory()).path;
      final vpnDetector = VpnConnectionDetector();
      vpnDetector.vpnConnectionStream.listen((state) {
        tryWarnVpn();
      });
      if (Platform.isAndroid) {
        Logger.info("tryingService");
        serviceId = await mcs.invokeMethod("get-native-handle");
        if (serviceId != "0") {
          state = await api.serviceFromPtr(ptr: serviceId);
        }
        
        Logger.info("service");
      } else {
        var data = await api.SharedPushState.restore(path: fs.appDocDir.path);
        if (data != null) {
          var (pollState, deskState) = api.dupDaemonDesk(state: data.$1);
          state = deskState;
          doPoll(data.$2, pollState);
        }
      }
      if (state == null && ss.settings.finishedSetup.value) {
        ss.settings.finishedSetup.value = false;
        ss.saveSettings();
        try {
          Get.offAll(() => PopScope(
            canPop: false,
            child: TitleBarWrapper(child: SetupView()),
          ), duration: Duration.zero, transition: Transition.noTransition);
        } catch (e) { }
      }
      if (state != null && !ss.settings.finishedSetup.value) {
        handleRegistered();
        ss.settings.finishedSetup.value = true;
        ss.saveSettings();
        try {
          Get.offAll(() => ConversationList(
              showArchivedChats: false,
              showUnknownSenders: false,
            ),
            routeName: "",
            duration: Duration.zero,
            transition: Transition.noTransition
          );
          Get.delete<SetupViewController>(force: true);
        } catch (e) { }
      }
      Timer.periodic(const Duration(days: 1), (timer) => validateSubState());
      validateSubState();
      if (ls.isUiThread) {
        Timer.periodic(const Duration(days: 1), (timer) async {
          if (state == null) return;
          var passwords = state!.icloudServices?.passwords;
          if (passwords != null) {
            api.syncPasswords(passwords: passwords, conn: state!.conn);
          }
          if (!ss.settings.cloudSyncingEnabled.value) return;
          Logger.info("Doing cloudkit sync!");
          await pushService.doCloudKitSync();
        });
        if (state != null) {
          var passwords = state!.icloudServices?.passwords;
          if (passwords != null) {
            api.syncPasswords(passwords: passwords, conn: state!.conn);
          }
          if (ss.settings.cloudSyncingEnabled.value) {
            Logger.info("Doing cloudkit sync!");
            pushService.doCloudKitSync();
          }
        }
        var keychain = pushService.state?.icloudServices?.keychain;
        if (keychain != null) {
          cachedInClique = await api.isInClique(keychain: keychain);
        }
      }
    })();
    initSyncState();
    initAppLinks();
    initMixPanel();
    await initFuture;
    Timer(const Duration(seconds: 2), checkIncident);
    // pre-cache next FT link
    if (pushService.state != null) api.getFtLink(facetime: pushService.state!.ftClient, usage: "next");
    Logger.info("initDone");
    final sendingProgress = Database.messages.query(Message_.sendingServiceId.notNull()).build().find();
    for (var item in sendingProgress) {
      // we are still sending
      if (item.sendingServiceId == serviceId) continue;
      item.sendingServiceId = null;
      item = item.save(updateSendingServiceId: true);
      markFailed(item, "Crashed while still sending");
    }
    if (ls.isUiThread) await cs.refreshContacts();
    Logger.info("finishInit");
  }

  void checkIncident() {
    if (!File("$statePath/incident_affected").existsSync()) return;
    showDialog(
      context: Get.context!,
      builder: (context) => AlertDialog(
        title: Text(
          "Action requried",
          style: context.theme.textTheme.titleLarge,
        ),
        backgroundColor: context.theme.colorScheme.properSurface,
        content: Text("There's an issue with a recent update. A software bug corrupted part of the app's internal state and needs to be fixed before messaging can continue. You won't be able to send messages until you take action.\n\nYour data was not compromised, and this was not a security issue.\nWe recommend backing up any important messages before proceeding. Have your apple device and account authentication credentials ready.", style: context.theme.textTheme.bodyLarge),
        actions: [
          TextButton(
            child: Text(
                "Dismiss for now",
                style: context.theme.textTheme.bodyLarge!.copyWith(color: context.theme.colorScheme.primary)
            ),
            onPressed: () => Navigator.of(context).pop(),
          ),
          TextButton(
            child: Text(
                "Fix",
                style: context.theme.textTheme.bodyLarge!.copyWith(color: context.theme.colorScheme.primary)
            ),
            onPressed: () async {
              Navigator.of(context).pop();
              pushService.markFailedToLogin(hw: true, logout: true, ui: true);
              File("$statePath/incident_affected").deleteSync();
            }
          ),
        ],
      ),
    );
  }

  void initMixPanel() async {
    if (ss.settings.finishedSetup.value && !ss.settings.deviceIsHosted.value) return;
    mixpanel = await Mixpanel.init("d66dc2d8f2ad649fac2640ff059dc9f4", trackAutomaticEvents: false);
  }

  String statePath = "";

  bool loggingOut = false;
  Future<void> markFailedToLogin({bool hw = false, bool logout = false, bool ui = false}) async {
    Logger.error("markingfailed");
    if (loggingOut) return;
    try {
      loggingOut = true;
      if (ui) {
        await wrapPromise(reset(hw, logout, true), "Loading...");
      } else {
        await reset(hw, logout, true);
      }
    } finally {
      loggingOut = false;
    }
  }

  Future reset(bool hw, bool logout, bool setup) async {
    var thisState = state;
    state = null;

    if (thisState == null) return;

    if (logout) {
      ss.settings.cloudSyncingEnabled.value = false;
      ss.settings.keychainDefaultPassword.value = null;
      ss.saveSettings();
    }
    await api.resetState(
      cancel: thisState.cancelPoll,
      path: statePath,
      config: thisState.osConfig,
      aps: thisState.conn,
      account: thisState.icloudServices?.account,

      resetHw: hw, 
      logout: logout
    );
    disposeState(thisState, hw, setup);
  }

  

  void disposeState(api.SharedPushState state, bool hw, bool setup) {
    state.cancelPoll.dispose();
    state.localBroadcast.dispose();
    state.ftClient.dispose();
    state.idmsClient.dispose();
    state.activeCircleSessions.dispose();
    state.clientSession.dispose();

    state.icloudServices?.account.dispose();
    state.icloudServices?.tokenProvider.dispose();
    state.icloudServices?.cloudkitClient?.dispose();
    state.icloudServices?.keychain?.dispose();
    state.icloudServices?.profilesClient.dispose();
    state.icloudServices?.fmfd?.dispose();
    state.icloudServices?.cloudMessagesClient?.dispose();
    state.icloudServices?.statuskitClient.dispose();
    var streams = state.icloudServices?.sharedstreams;
    if (streams != null) api.closeSyncmanager(shared: streams);
    streams?.dispose();

    api.closeClient(client: state.client);
    state.client.dispose();


    (lib.ApsConnection, lib.ApsState, api.JoinedOsConfig, api.IdsngmIdentity, lib.ArcAnisetteClientDefaultAnisetteProvider)? prefix;    
    if (hw || !setup) {
      api.closeAps(aps: state.conn);
      state.conn.dispose();
      state.osConfig.dispose();
      state.anisette.dispose();
    } else {
      var restored = api.readHardware(path: pushService.statePath)!;
      prefix = (state.conn, restored.push, state.osConfig, api.decodeIdentity(identity: restored.identity), state.anisette);
    }

    if (setup) {
      ss.settings.finishedSetup.value = false;
      ss.saveSettings();
      if (ls.isUiThread) {
        try {
          Get.offAll(() => PopScope(
            canPop: false,
            child: TitleBarWrapper(child: SetupView(prefix: prefix)),
          ), duration: Duration.zero, transition: Transition.noTransition);
        } catch (e) { }
      }
    }
  }

  Future configured() async {
    await handleRegistered();
    Timer(const Duration(seconds: 2), checkIncident);
    if (Platform.isAndroid) {
      await mcs.invokeMethod("notify-native-configured");
    }
  }

  @override
  void onClose() {
    for (final timer in _profileRetryTimers.values) {
      timer.cancel();
    }
    _profileRetryTimers.clear();
    _profileRetryPolicy.clear();
    if (state != null) disposeState(state!, true, false);
    super.onClose();
  }
}
