import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:async_task/async_task_extension.dart';
import 'package:bluebubbles/app/layouts/conversation_list/pages/conversation_list.dart';
import 'package:bluebubbles/app/layouts/conversation_view/widgets/message/message_holder.dart';
import 'package:bluebubbles/app/layouts/setup/setup_view.dart';
import 'package:bluebubbles/app/wrappers/titlebar_wrapper.dart';
import 'package:bluebubbles/database/database.dart';
import 'package:bluebubbles/main.dart';
import 'package:bluebubbles/src/rust/api/api.dart' as api;
import 'package:bluebubbles/src/rust/lib.dart' as lib;
import 'package:bluebubbles/helpers/helpers.dart';
import 'package:bluebubbles/database/models.dart';
import 'package:bluebubbles/services/services.dart';
import 'package:bluebubbles/utils/crypto_utils.dart';
import 'package:bluebubbles/utils/logger/logger.dart';
import 'package:collection/collection.dart';
import 'package:crypto/crypto.dart';
import 'package:ffmpeg_kit_flutter/ffmpeg_kit.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_rust_bridge/flutter_rust_bridge.dart';
import 'package:get/get.dart';
import 'package:supercharged/supercharged.dart';
import 'package:tuple/tuple.dart';
import 'package:universal_io/io.dart';
import '../network/backend_service.dart';
import 'package:dio/dio.dart';
import 'package:uuid/uuid.dart';
import 'package:dlibphonenumber/dlibphonenumber.dart';
import 'package:telephony_plus/telephony_plus.dart';
import 'package:vpn_connection_detector/vpn_connection_detector.dart';
import 'package:convert/convert.dart';
import 'package:bluebubbles/helpers/types/constants.dart' as constants;

var uuid = const Uuid();
RustPushService pushService =
    Get.isRegistered<RustPushService>() ? Get.find<RustPushService>() : Get.put(RustPushService());


const rpApiRoot = "https://hw.openbubbles.app";

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

  static Future<String> formatAddress(String e) async {
    if (e.isEmail) {
      return e;
    }
    var parsed = PhoneNumberUtil.instance.parse(e, "US");
    return PhoneNumberUtil.instance.format(parsed, PhoneNumberFormat.e164);
  }

  static Future<String> formatAndAddPrefix(String e) async {
    var address = await formatAddress(e);
    if (address.isEmail) {
      return "mailto:$address";
    } else {
      return "tel:$address";
    }
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
    var myHandles = (await api.getHandles(state: pushService.state));
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
  Future<String> getDefaultHandle() async {
    var myHandles = await api.getHandles(state: pushService.state);
    var setHandle = ss.settings.defaultHandle.value;
    if (myHandles.contains(setHandle)) {
      return setHandle;
    }
    return myHandles[0];
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

  Future<api.MessageType> getService(bool isSms, {Message? forMessage}) async {
    if (isSms) {
      String? fromHandle;
      if (forMessage != null && forMessage.handle != null) {
        var myHandles = await api.getHandles(state: pushService.state);
        var sender = RustPushBBUtils.bbHandleToRust(forMessage.handle!);
        if (!myHandles.contains(sender)) {
          fromHandle = sender; // this is a forwarded message
        }
      }
      var number = "";
      if (!kIsDesktop) {
        // we don't need number on desktop, b/c it's only used for relaying messages to other devices
        // which desktops will never do
        number = await RustPushBBUtils.formatAddress(await TelephonyPlus().getNumber());
      }
      return api.MessageType.sms(isPhone: ss.settings.isSmsRouter.value, usingNumber: "tel:$number", fromHandle: fromHandle);
    }
    return const api.MessageType.iMessage();
  }
  

  void markFailedToLogin() async {
    Logger.error("markingfailed");
    if (usingRustPush) {
      await pushService.reset(false);
    }
    ss.settings.finishedSetup.value = false;
    ss.saveSettings();
    Get.offAll(() => PopScope(
      canPop: false,
      child: TitleBarWrapper(child: SetupView()),
    ), duration: Duration.zero, transition: Transition.noTransition);
  }

  Future<void> sendMsg(api.MessageInst msg) async {
    var message = Message.findOne(guid: msg.id);
    if (message != null) {
      message.sendingServiceId = pushService.serviceId;
      message.save(updateSendingServiceId: true);
    }
    var stillRunning = false;
    try {
      stillRunning = await api.send(state: pushService.state, msg: msg);
    } catch (e) {
      if (e is AnyhowException) {
        if (e.message.contains("Failed to generate resource") && e.message.contains("not retrying")) {
          markFailedToLogin();
        }
      }
      rethrow;
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
    var handle = await getDefaultHandle();
    var formattedHandles = (await Future.wait(
              addresses.map((e) async => RustPushBBUtils.rustHandleToBB(await RustPushBBUtils.formatAddress(e)))))
          .toList();
    var chat = Chat(
      guid: existingGuid ?? uuid.v4(),
      participants: formattedHandles,
      usingHandle: handle,
      isRpSms: service == "SMS",
    );
    chat.save(); //save for reflectMessage
    if (message != null) {
      var msg = await api.newMsg(
          state: pushService.state,
          conversation: await chat.getConversationData(),
          message: api.Message.message(api.NormalMessage(
              parts: await partsFromBody(message),
                  service: await getService(chat.isRpSms),
                  voice: false,
                  )),
          sender: handle);
      if (chat.isRpSms) {
        msg.target = getSMSTargets();
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
    var rustAttachment = await api.restoreAttachment(data: attachment.metadata!["rustpush"]);
    var stream = api.downloadAttachment(state: pushService.state, attachment: rustAttachment, path: attachment.path);
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

  List<api.MessageTarget> getSMSTargets() {
    return ss.settings.smsForwardingTargets.map((element) => api.MessageTarget.uuid(element)).toList();
  }

  @override
  Future<Message> sendAttachment(Chat chat, Message m, bool isAudioMessage, Attachment att, {void Function(int p1, int p2)? onSendProgress, CancelToken? cancelToken}) async {
    if (chat.isRpSms && !smsForwardingEnabled()) {
      throw Exception("SMS is not enabled (enable in settings -> user)");
    }
    var stream = api.uploadAttachment(
        state: pushService.state,
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
        state: pushService.state,
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
          service: await getService(chat.isRpSms, forMessage: m),
          subject: m.subject,
          app: m.payloadData == null ? null : pushService.dataToApp(m.payloadData!),
          voice: isAudioMessage,
          scheduledMs: m.dateScheduled?.millisecondsSinceEpoch,
        )));
    if (m.stagingGuid != null) {
      msg.id = m.stagingGuid!;
    }
    if (chat.isRpSms) {
      msg.target = getSMSTargets();
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
    api.Attachment? attachment = api.Attachment(
      aType: api.AttachmentType.inline(await att.getFile().getBytes()),
      mime: att.mimeType ?? "application/octet-stream",
      part_: 0,
      utiType: att.uti ?? "public.data",
      name: att.transferName!,
      iris: false,
    );
    Logger.info("uploaded");
    var service = await getService(chat.isRpSms, forMessage: m);
    var msg = await api.newMsg(
        state: pushService.state,
        conversation: await chat.getConversationData(),
        sender: await chat.ensureHandle(),
        message: api.Message.message(api.NormalMessage(
          parts: api.MessageParts(
              field0: [api.IndexedMessagePart(part_: api.MessagePart.attachment(attachment))]),
          replyGuid: m.threadOriginatorGuid,
          replyPart: m.threadOriginatorGuid == null ? null : m.threadOriginatorPart,
          effect: m.expressiveSendStyleId,
          service: service,
          voice: false
        )));
    if (m.stagingGuid != null || (m.guid != null && m.guid!.contains("error") && m.guid!.contains("temp"))) {
      msg.id = m.stagingGuid ?? m.guid!;
    }
    msg.target = getSMSTargets();
    await sendMsg(msg);
    msg.sentTimestamp = DateTime.now().millisecondsSinceEpoch;
    return (await pushService.reflectMessageDyn(msg))!;
  }

  @override
  bool canCancelUploads() {
    return false;
  }

  Future<void> broadcastSmsForwardingState(bool state, List<String> uuids) async {
    var handles = await api.getHandles(state: pushService.state);
    var useHandle = handles.firstWhereOrNull((handle) => handle.contains("tel:")) ?? handles.first;
    var msg = await api.newMsg(
      state: pushService.state,
      conversation: api.ConversationData(participants: [useHandle], cvName: null, senderGuid: null),
      sender: useHandle,
      message: api.Message.enableSmsActivation(state),
    );
    msg.target = uuids.map((e) => api.MessageTarget.uuid(e)).toList();
    await sendMsg(msg);
  }

  Future<void> confirmSmsSent(Message m, Chat c, bool success) async {
    var msg = await api.newMsg(
      state: pushService.state,
      conversation: await c.getConversationData(),
      sender: await c.ensureHandle(),
      message: api.Message.smsConfirmSent(success),
    );
    msg.id = m.stagingGuid ?? m.guid!;
    if (c.isRpSms) {
      msg.target = getSMSTargets();
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
      state: pushService.state,
      conversation: await chat.getConversationData(),
      sender: await chat.ensureHandle(),
      message: api.Message.iconChange(api.IconChangeMessage(groupVersion: chat.groupVersion!)),
    );
    await sendMsg(msg);
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
    var handles = await api.getHandles(state: pushService.state);
    var state = await api.getRegstate(state: pushService.state);
    var stateStr = "";
    if (state is api.RegisterState_Registered) {
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
    var mmcsStream = api.uploadMmcs(state: pushService.state, path: path);
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
    var msg = await api.newMsg(
      state: pushService.state,
      conversation: await chat.getConversationData(),
      sender: await chat.ensureHandle(),
      message: api.Message.iconChange(api.IconChangeMessage(groupVersion: chat.groupVersion!, file: mmcs!)),
    );
    await sendMsg(msg);
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
      state: pushService.state,
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
      state: pushService.state,
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
      state: pushService.state,
      conversation: api.ConversationData(participants: [handle]),
      sender: handle,
      message: api.Message.permanentDelete(api.PermanentDeleteMessage(target: api.DeleteTarget.chat(await getOperatedChat(c)), isScheduled: false))
    );
    await sendMsg(msg);
  }

  Future<void> invalidateSelf() async {
    var handles = await api.getHandles(state: pushService.state);
    for (var handle in handles) {
      var msg = await api.newMsg(
        state: pushService.state,
        conversation: api.ConversationData(participants: [handle]),
        sender: handle,
        message: const api.Message.peerCacheInvalidate(),
      );
      await sendMsg(msg);
    }
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
        var rustAttachment = await api.restoreAttachment(data: attachment.metadata!["rustpush"]);
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
        var metadata = await MetadataHelper.fetchMetadata(m);
        
        if (MetadataHelper.isNotEmpty(metadata)) {
          m.metadata = metadata!.toJson();
          List<Uint8List> attachments = [];
          api.LPImageMetadata? imagemeta;
          api.RichLinkImageAttachmentSubstitute? image;
          api.LPIconMetadata? iconmeta;
          api.RichLinkImageAttachmentSubstitute? icon;

          var uri = Uri.parse(m.url!).replace(path: "/favicon.ico");
          var iconUrl = uri.toString();
          final response = await http.dio.get(iconUrl, options: Options(responseType: ResponseType.bytes));
          if (response.statusCode == 200) {
            var contentType = response.headers.value('content-type')!;

            iconmeta = api.LPIconMetadata(url: api.NSURL(base: "\$null", relative: iconUrl), version: 1);

            icon = api.RichLinkImageAttachmentSubstitute(mimeType: contentType, richLinkImageAttachmentSubstituteIndex: BigInt.from(attachments.length));
            attachments.add(response.data as Uint8List);
          }

          if (metadata.image != null) {
            imagemeta = api.LPImageMetadata(size: "{0, 0}", url: api.NSURL(base: "\$null", relative: metadata.image!), version: 1);

            final response = await http.dio.get(metadata.image!, options: Options(responseType: ResponseType.bytes));
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
    var msg = await api.newMsg(
      state: pushService.state,
      conversation: await chat.getConversationData(),
      sender: await chat.ensureHandle(),
      message: api.Message.message(api.NormalMessage(
        parts: parts,
        replyGuid: m.threadOriginatorGuid,
        replyPart: m.threadOriginatorGuid == null ? null : m.threadOriginatorPart,
        effect: m.expressiveSendStyleId,
        service: await getService(chat.isRpSms, forMessage: m),
        subject: m.subject == "" ? null : m.subject,
        app: m.payloadData == null ? null : pushService.dataToApp(m.payloadData!),
        linkMeta: linkMeta,
        voice: false,
        scheduledMs: m.dateScheduled?.millisecondsSinceEpoch,
      )),
    );
    Logger.info("sending ${msg.id}");
    if (m.stagingGuid != null || (m.dateScheduled != null && !m.guid!.contains("temp") && !m.guid!.contains("error")) || (chat.isRpSms && m.guid != null && m.guid!.contains("error") && m.guid!.contains("temp"))) {
      msg.id = m.stagingGuid ?? m.guid!; // make sure we pass forwarded messages's original GUID so it doesn't get overwritten and marked as a different msg
    }
    if (chat.isRpSms) {
      msg.target = getSMSTargets();
    }
    m.stagingGuid = msg.id; // in case delivered comes in before sending "finishes" (also for retries, duh)
    m.save(chat: chat);
    try {
      await sendMsg(msg);
    } catch (e) {
      Logger.error(e);
      if (!chat.isRpSms) {
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
    return (await pushService.reflectMessageDyn(msg))!;
  }

  Future<bool> markDelivered(api.MessageInst message) async {
    if (!message.sendDelivered) return true;
    var chat = await pushService.chatForMessage(message);
    if (chat.isRpSms) {
      return true; // no delivery recipts :)
    }
    var msg = await api.newMsg(
      state: pushService.state,
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
      return true;
    }
    await sendMsg(msg);
    return true;
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
        state: pushService.state,
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
        state: pushService.state,
        conversation: data,
        sender: await chat.ensureHandle(),
        message: const api.Message.markUnread());
    msg.id = latestMsg!;
    if (msg.id.contains("temp") || msg.id.contains("error")) {
      return true;
    }
    if (chat.isRpSms) {
      msg.target = getSMSTargets();
    }
    await sendMsg(msg);
    return true;
  }

  @override
  Future<bool> renameChat(Chat chat, String newName) async {
    var data = await chat.getConversationData();
    var msg = await api.newMsg(
        state: pushService.state,
        conversation: data,
        sender: await chat.ensureHandle(),
        message: api.Message.renameMessage(api.RenameMessage(newName: newName)));
    await sendMsg(msg);
    msg.sentTimestamp = DateTime.now().millisecondsSinceEpoch;
    chat.apnTitle = newName;
    chat.save(updateAPNTitle: true);
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
          (await api.validateTargets(state: pushService.state, targets: [target], sender: await chat.ensureHandle()))
              .isNotEmpty;
      if (!valid) {
        return false;
      }
      newParticipants.add(target);
    } else if (method == ParticipantOp.Remove) {
      newParticipants.remove(await RustPushBBUtils.formatAndAddPrefix(newName));
    }
    var msg = await api.newMsg(
        state: pushService.state,
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
    var enabled = !reaction.startsWith("-");
    reaction = enabled ? reaction : reaction.substring(1);
    var msg = await api.newMsg(
        state: pushService.state,
        conversation: await chat.getConversationData(),
        sender: await chat.ensureHandle(),
        message: api.Message.react(api.ReactMessage(
            toUuid: selected.guid!,
            toPart: repPart ?? 0,
            toText: selected.text ?? "",
            reaction: api.ReactMessageType.react(reaction: reactionMap[reaction]?.call() ?? api.Reaction.emoji(reaction), enable: enabled))));
    await sendMsg(msg);
    msg.sentTimestamp = DateTime.now().millisecondsSinceEpoch;
    return (await pushService.reflectMessageDyn(msg))!;
  }

  @override
  Future<Message> updateMessage(
        Chat chat, Message old, PayloadData newData) async {
    var msg = await api.newMsg(
        state: pushService.state,
        conversation: await chat.getConversationData(),
        sender: await chat.ensureHandle(),
        message: api.Message.react(api.ReactMessage(
            toUuid: old.amkSessionId!,
            toText: "",
            reaction: api.ReactMessageType.extension_(
              spec: pushService.dataToApp(newData),
              body: api.MessageParts(field0: [
                api.IndexedMessagePart(part_: api.MessagePart.object(newData.appData![0].ldText ?? ""))
              ])
            ))));
    await sendMsg(msg);
    msg.sentTimestamp = DateTime.now().millisecondsSinceEpoch;
    return (await pushService.reflectMessageDyn(msg))!;
  }

  @override
  Future<Message?> unsend(Message msgObj, MessagePart part) async {
    var msg = await api.newMsg(
        state: pushService.state,
        sender: await msgObj.chat.target!.ensureHandle(),
        conversation: await msgObj.chat.target!.getConversationData(),
        message: api.Message.unsend(api.UnsendMessage(tuuid: msgObj.guid!, editPart: part.part)));
    await sendMsg(msg);
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
        state: pushService.state,
        conversation: await msgObj.chat.target!.getConversationData(),
        sender: await msgObj.chat.target!.ensureHandle(),
        message: api.Message.edit(api.EditMessage(
            tuuid: msgObj.guid!,
            editPart: part,
            newParts: await partsFromBody(text))));
    await sendMsg(msg);
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
    var rustAttachment = await api.restoreAttachment(data: attachment.metadata!["myIris"]);
    var stream = api.downloadAttachment(state: pushService.state, attachment: rustAttachment, path: "${attachment.directory}/$target");
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
    return pushService.findMy;
  }

  @override
  void startedTyping(Chat c) async {
    if (c.isRpSms) return;
    if (c.participants.length > 1) {
      return; // no typing indicators for multiple chats
    }
    var msg = await api.newMsg(
      state: pushService.state,
      conversation: await c.getConversationData(),
      sender: await c.ensureHandle(),
      message: const api.Message.typing()
    );
    await sendMsg(msg);
  }

  @override
  void stoppedTyping(Chat c) async {
    if (c.isRpSms) return;
    if (c.participants.length > 1) {
      return; // no typing indicators for multiple chats
    }
    var msg = await api.newMsg(
      state: pushService.state,
      conversation: await c.getConversationData(),
      sender: await c.ensureHandle(),
      message: const api.Message.stopTyping()
    );
    await sendMsg(msg);
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
  late lib.ArcPushState state;

  var findMy = false;

  Map<String, api.Attachment> attachments = {};

  Future<List<String>> doValidateTargets(List<String> targets, String handle) async {
    List<String> available;
    try {
      available = await api.validateTargets(state: pushService.state, targets: targets, sender: handle);
    } catch (e) {
      if (e is AnyhowException) {
        if (e.message.contains("Failed to generate resource") && e.message.contains("not retrying")) {
          (backend as RustPushBackend).markFailedToLogin();
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
    var myHandles = await api.getHandles(state: pushService.state);
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
          transferName: part.field0.name,
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
      appId: appData.appId!,
      bundleId: appData.bundleId,
      balloon: api.Balloon(
        icon: base64Decode(appData.appIcon!),
        url: appData.url!,
        session: appData.session,
        ldText: appData.ldText,
        isLive: appData.isLive ?? false,
        layout: api.BalloonLayout.templateLayout(
          imageSubtitle: appData.userInfo!.imageSubtitle ?? "",
          imageTitle: appData.userInfo!.imageTitle ?? "",
          caption: appData.userInfo!.caption ?? "", 
          secondarySubcaption: appData.userInfo!.secondarySubcaption ?? "", 
          tertiarySubcaption: appData.userInfo!.tertiarySubcaption ?? "", 
          subcaption: appData.userInfo!.subcaption ?? "", 
          class_: api.NSDictionaryClass.nsDictionary,
        )
      )
    );
  }

  PayloadData appToData(api.ExtensionApp app) {
    var layout = app.balloon!.layout as api.BalloonLayout_TemplateLayout;
    return PayloadData(
      type: constants.PayloadType.app,
      urlData: null,
      appData: [
        iMessageAppData(
          appName: app.name,
          ldText: app.balloon?.ldText,
          url: app.balloon?.url,
          session: app.balloon?.session,
          appIcon: app.balloon?.icon != null ? base64Encode(app.balloon!.icon) : null,
          appId: app.appId,
          isLive: app.balloon?.isLive ?? false,
          userInfo: UserInfo(
            imageSubtitle: layout.imageSubtitle,
            imageTitle: layout.imageTitle,
            caption: layout.caption,
            secondarySubcaption: layout.secondarySubcaption,
            subcaption: layout.subcaption,
            tertiarySubcaption: layout.tertiarySubcaption,
          )
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

  PayloadData linkToData(api.LinkMeta link) {
    return PayloadData(
      type: constants.PayloadType.url,
      urlData: [
        UrlPreviewData(
          imageMetadata: rpToMedia(link.data.imageMetadata),
          videoMetadata: null,
          iconMetadata: rpIToMedia(link.data.iconMetadata),
          originalUrl: link.data.originalUrl.relative,
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
    var myHandles = (await api.getHandles(state: pushService.state));
    if (myMsg.message is api.Message_Message) {
      var innerMsg = myMsg.message as api.Message_Message;
      var attributedBodyData = await indexedPartsToAttributedBodyDyn(innerMsg.field0.parts.field0, myMsg.id, null);
      var sender = myMsg.sender;
      
      var staging = false;
      var tempGuid = "temp-${randomString(8)}";
      if (innerMsg.field0.service is api.MessageType_SMS) {
        var smsServ = innerMsg.field0.service as api.MessageType_SMS;
        if (smsServ.fromHandle != null) {
          sender = smsServ.fromHandle;
        }
        staging = myHandles.contains(sender);
        if (staging) {
          var found = Message.findOne(guid: myMsg.id);
          if (found != null && found.guid != null) {
            tempGuid = found.guid!;
          }
        }
      }

      return Message(
        guid: staging ? tempGuid : myMsg.id,
        stagingGuid: staging ? myMsg.id : null,
        text: attributedBodyData.$2,
        isFromMe: myHandles.contains(sender),
        handle: RustPushBBUtils.rustHandleToBB(sender!),
        dateCreated: DateTime.fromMillisecondsSinceEpoch(myMsg.sentTimestamp),
        dateScheduled: innerMsg.field0.scheduledMs != null ? DateTime.fromMillisecondsSinceEpoch(innerMsg.field0.scheduledMs!) : null,
        subject: innerMsg.field0.subject,
        threadOriginatorPart: innerMsg.field0.replyPart?.toString(),
        threadOriginatorGuid: innerMsg.field0.replyGuid,
        expressiveSendStyleId: innerMsg.field0.effect,
        attributedBody: [attributedBodyData.$1],
        attachments: attributedBodyData.$3,
        hasAttachments: attributedBodyData.$3.isNotEmpty,
        balloonBundleId: innerMsg.field0.app?.balloon != null ? innerMsg.field0.app?.bundleId : innerMsg.field0.linkMeta != null ? "com.apple.messages.URLBalloonProvider" : null,
        payloadData: innerMsg.field0.app?.balloon != null ? appToData(innerMsg.field0.app!) : innerMsg.field0.linkMeta != null ? linkToData(innerMsg.field0.linkMeta!) : null,
        amkSessionId: innerMsg.field0.app?.balloon != null ? myMsg.id : null,
        verificationFailed: myMsg.verificationFailed,
        hasApplePayloadData: innerMsg.field0.app?.balloon != null,
      );
    } else if (myMsg.message is api.Message_RenameMessage) {
      var msg = myMsg.message as api.Message_RenameMessage;
      if (myMsg.verificationFailed) return null;
      
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
      chat.save(updateGroupVersion: true);
      return null;
    } else if (myMsg.message is api.Message_IconChange) {
      if (!chat!.lockChatIcon) {
        var innerMsg = myMsg.message as api.Message_IconChange;
        var file = innerMsg.field0.file;
        chat.groupVersion = innerMsg.field0.groupVersion;
        if (file != null) {
          var path = chat.getIconPath(file.size);
          var stream = api.downloadMmcs(state: pushService.state, attachment: file, path: path);
          await for (final event in stream) {
            Logger.info("Downloaded attachment ${event.prog} bytes of ${event.total}");
          }
          chat.customAvatarPath = path;
        } else {
          chat.removeProfilePhoto();
        }
        chat.save(updateCustomAvatarPath: true, updateGroupVersion: true);
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
        if (msgType.spec.balloon != null) {
          // copy over assets
          reaction = null;

          final query = (Database.messages.query(Message_.amkSessionId.equals(msg.field0.toUuid))
            ..order(Message_.dateCreated, flags: Order.descending))
          .build();
          query.limit = 2;

          final messages = query.find();
          query.close();

          final original = messages.firstWhere((msg) => (msg.stagingGuid ?? msg.guid) != myMsg.id);
          
          attributedBodyData = (original.attributedBody[0], original.text!, original.dbAttachments);
          es.amkToLatest[msg.field0.toUuid] = myMsg.id; // we are latest

          if (chat != null && cm.activeChat?.chat.guid == chat.guid) {
            ms(original.chat.target!.guid).updateMessage(original);
            mwc(original).updateWidgets<MessageHolder>(null);
          }
        } else {
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
        associatedMessageType: reaction,
        associatedMessageEmoji: emoji,
        text: attributedBodyData?.$2,
        attributedBody: attributedBodyData != null ? [attributedBodyData.$1] : [],
        attachments: attributedBodyData?.$3 ?? [],
        hasAttachments: attributedBodyData?.$3.isNotEmpty ?? false,
        balloonBundleId: app?.bundleId,
        payloadData: app?.balloon != null ? appToData(app!) : null,
        amkSessionId: app?.balloon != null ? msg.field0.toUuid : null,
        verificationFailed: myMsg.verificationFailed,
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
    throw Exception("bad message type!");
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
  Future<Chat> chatForMessageInner(api.MessageInst myMsg) async {
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
    return (await Chat.findByRust(myMsg.conversation!, getService(myMsg)))!;
  }

  Future<Chat> chatForMessage(api.MessageInst myMsg) async {
    var result = await chatForMessageInner(myMsg);
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
      if (myMsg.message is! api.Message_ChangeParticipants) {
        var isNormal = myMsg.message is api.Message_Message;
        var isSms = isNormal && (myMsg.message as api.Message_Message).field0.service is api.MessageType_SMS;
        if (!isSms) {
          var data = await result.getConversationData();
          // make sure we are in consensus
          await updateChatParticipants(result, myMsg, data.participants, myMsg.conversation!.participants);
        }
      }
    }
    if (result.dateDeleted != null) {
      Chat.unDelete(result);
      await chats.addChat(result);
    }
    return result;
  }

  Future<void> markFailed(Message mistakeFor, String error) async {
      mistakeFor.stagingGuid = mistakeFor.guid;
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

  var notifiedFailed = false;

  Future handleMsg(api.PushMessage push) async {

    if (push is api.PushMessage_RegistrationState) {
      var state = push.field0;
      if (state is api.RegisterState_Registered) {
        notifiedFailed = false;
      }
      if (state is api.RegisterState_Failed && !notifiedFailed) {
        notif.createRegisterFailed(state.retryWait == null);
        notifiedFailed = true;
      }
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
        var peerUuid = await api.convertTokenToUuid(state: pushService.state, handle: myMsg.sender!, token: (myMsg.target!.first as api.MessageTarget_Token).field0);
        if (message.field0) {
          if (!ss.settings.smsForwardingTargets.contains(peerUuid)) ss.settings.smsForwardingTargets.add(peerUuid);
        } else {
          ss.settings.smsForwardingTargets.remove(peerUuid);
        }
        ss.saveSettings();
      } catch (e) {
        showSnackbar("Error", "Error activating SMS forwarding");
        rethrow;
      }
      return;
    }
    if (myMsg.message is api.Message_Error) {
      var message = myMsg.message as api.Message_Error;
      var mistakeFor = Message.findOne(guid: message.field0.forUuid);
      if (mistakeFor == null) return; // multiple errors will likely come in, at which point guid will be bad.
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
      var myHandles = (await api.getHandles(state: pushService.state));
      if (!myHandles.contains(myMsg.sender)) return; // sanity check, shouldn't get here anyways otherwise
      // loop through recent chats (1 day or newer)
      Query<Chat> query = Database.chats.query(Chat_.dateDeleted.isNull().and(Chat_.usingHandle.equals(myMsg.sender!)).and(Chat_.dbOnlyLatestMessageDate.greaterThan(DateTime.now().subtract(const Duration(days: 1)).millisecondsSinceEpoch)))
          .build();

      // Execute the query, then close the DB connection
      final chats = query.find();
      query.close();

      // notify participants of these chats that my keys have changed
      for (var chat in chats) {
        var data = await chat.getConversationData();
        if (data.participants.filter((element) => !myHandles.contains(element)).isEmpty) continue;
        var msg = await api.newMsg(
          state: pushService.state,
          conversation: data,
          sender: myMsg.sender!,
          message: const api.Message.peerCacheInvalidate(),
        );
        msg.id = myMsg.id;
        await (backend as RustPushBackend).sendMsg(msg);
      }
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
      var myHandles = (await api.getHandles(state: pushService.state));
      var message = Message.findOne(guid: myMsg.id);
      if (message == null) {
        return;
      }
      if (myMsg.verificationFailed) return;
      if (myHandles.contains(myMsg.sender)) {
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
      controller.showTypingIndicator.value = true;
      var future = Future.delayed(const Duration(minutes: 1));
      var subscription = future.asStream().listen((any) {
        controller.showTypingIndicator.value = false;
        controller.cancelTypingIndicator = null;
      });
      controller.cancelTypingIndicator = subscription;
      return;
    }
    if (myMsg.message is api.Message_StopTyping) {
      if (myMsg.verificationFailed) return; 
      final controller = cvc(chat);
      controller.showTypingIndicator.value = false;
      if (controller.cancelTypingIndicator != null) {
        controller.cancelTypingIndicator!.cancel();
        controller.cancelTypingIndicator = null;
      }
      return;
    }
    if (myMsg.message is api.Message_Message) {
      final controller = cvc(chat);
      controller.showTypingIndicator.value = false;
      controller.cancelTypingIndicator?.cancel();
      controller.cancelTypingIndicator = null;
      if (chat.isRpSms && !myMsg.verificationFailed) {
        var otherIds = ss.settings.smsForwardingTargets.copy();
        var myToken = (myMsg.target!.first as api.MessageTarget_Token).field0;
        var myId = await api.convertTokenToUuid(state: pushService.state, handle: myMsg.sender!, token: myToken);
        otherIds.remove(myId);
        if (otherIds.isNotEmpty) {
          myMsg.target = otherIds.map((element) => api.MessageTarget.uuid(element)).toList(); // forward to other devices
          await (backend as RustPushBackend).sendMsg(myMsg);
        }
      }
      var msg = myMsg.message as api.Message_Message;
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
      var service = backend as RustPushBackend;
      service.markDelivered(myMsg);
      inq.queue(IncomingItem(
        chat: chat,
        message: reflected,
        type: QueueType.newMessage
      ));
    }
  }
  
  Timer? myTimer;

  List<Function> subscriptions = [];
  Function subscribeToLocationUpdates(Function subscribe) {
    var timer = ((timer) async {
      var subs = await api.refreshBackgroundFollowing(state: pushService.state);
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

  Future recievedMsgPointer(String pointer) async {
    var message = await api.ptrToDart(ptr: pointer);
    if (message == null) {
      Logger.info("bad pointer $pointer");
      return;
    }
    Logger.info("waitingForInit $pointer");
    await initFuture;
    try {
      Logger.info("Handling $pointer");
      await handleMsg(message);
    } catch (e, s) {
      Logger.error("Handle failed", error: e, trace: s);
      rethrow;
    } finally {
      Logger.info("Marking as handled $pointer");
      await api.completeMsg(ptr: pointer);
    }
  }

  void doPoll() async {
    while (true) {
      try {
        var msgRaw = await api.recvWait(state: pushService.state);
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
        await handleMsg(msg);
      } catch (e, t) {
        // if there was an error somewhere, log it and move on.
        // don't stop our loop
        Logger.error("$e: $t");
      }
    }
  }

  void hello() {
    // used to get GetX to get up off it's ass
  }

  late Future initFuture;

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

  Future<void> correctState() async {
    await initFuture;
    var phase = await api.getPhase(state: state);
    if (phase != api.RegistrationPhase.registered && ss.settings.finishedSetup.value) {
      ss.settings.finishedSetup.value = false;
      ss.saveSettings();
      Get.offAll(() => PopScope(
        canPop: false,
        child: TitleBarWrapper(child: SetupView()),
      ), duration: Duration.zero, transition: Transition.noTransition);
    } else if (phase == api.RegistrationPhase.registered && !ss.settings.finishedSetup.value) {
      ss.settings.finishedSetup.value = true;
      ss.saveSettings();
      Get.offAll(() => ConversationList(
          showArchivedChats: false,
          showUnknownSenders: false,
        ),
        routeName: "",
        duration: Duration.zero,
        transition: Transition.noTransition
      );
      Get.delete<SetupViewController>(force: true);
    }
  }

  // uniquely identify the backend service that is running
  String serviceId = "";

  @override
  Future<void> onInit() async {
    super.onInit();
    initFuture = (() async {
      final vpnDetector = VpnConnectionDetector();
      vpnDetector.vpnConnectionStream.listen((state) {
        tryWarnVpn();
      });
      if (Platform.isAndroid) {
        Logger.info("tryingService");
        serviceId = await mcs.invokeMethod("get-native-handle");
        state = await api.serviceFromPtr(ptr: serviceId);
        Logger.info("statecheck");
        if ((await api.getPhase(state: state)) == api.RegistrationPhase.registered) {
          ss.settings.finishedSetup.value = true;
          ss.saveSettings();
        }
        Logger.info("service");
      } else {
        state = await api.newPushState(dir: fs.appDocDir.path);
        serviceId = randomString(8);
        if ((await api.getPhase(state: state)) == api.RegistrationPhase.registered) {
          ss.settings.finishedSetup.value = true;
          ss.saveSettings();
          doPoll();
        }
      }
      pushService.findMy = await api.canFindMy(state: state);
    })();
    await initFuture;
    Logger.info("initDone");
    await correctState();
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

  Future reset(bool hw) async {
    await api.resetState(state: state, resetHw: hw);
  }

  Future configured() async {
    if (Platform.isAndroid) {
      await mcs.invokeMethod("notify-native-configured");
    } else {
      doPoll();
    }
    try {
      await (backend as RustPushBackend).invalidateSelf();
    } catch (e) {
      // not that important
    }
  }

  @override
  void onClose() {
    state.dispose();
    super.onClose();
  }
}
