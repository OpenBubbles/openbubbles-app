import 'dart:convert';
import 'dart:typed_data';

import 'package:bluebubbles/app/layouts/conversation_view/widgets/message/interactive/apple_pay.dart';
import 'package:bluebubbles/app/layouts/conversation_view/widgets/message/interactive/find_my.dart';
import 'package:bluebubbles/app/layouts/conversation_view/widgets/message/interactive/embedded_media.dart';
import 'package:bluebubbles/app/layouts/conversation_view/widgets/message/interactive/supported_interactive.dart';
import 'package:bluebubbles/app/layouts/conversation_view/widgets/message/interactive/unsupported_interactive.dart';
import 'package:bluebubbles/app/layouts/conversation_view/widgets/message/interactive/url_preview.dart';
import 'package:bluebubbles/app/layouts/conversation_view/widgets/message/interactive/url_preview.legacy.dart';
import 'package:bluebubbles/app/layouts/conversation_view/widgets/message/misc/tail_clipper.dart';
import 'package:bluebubbles/app/layouts/conversation_view/widgets/message/popup/message_popup_holder.dart';
import 'package:bluebubbles/app/wrappers/stateful_boilerplate.dart';
import 'package:bluebubbles/helpers/helpers.dart';
import 'package:bluebubbles/database/models.dart' hide PayloadType;
import 'package:bluebubbles/services/services.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:url_launcher/url_launcher.dart';

class InteractiveHolder extends CustomStateful<MessageWidgetController> {
  InteractiveHolder({
    super.key,
    required super.parentController,
    required this.message,
  });

  final MessagePart message;

  @override
  CustomState createState() => _InteractiveHolderState();
}

class _InteractiveHolderState extends CustomState<InteractiveHolder, void, MessageWidgetController> with AutomaticKeepAliveClientMixin {
  MessagePart get part => widget.message;
  Message get message => controller.message;
  PayloadData? get payloadData => message.payloadData;
  late bool selected = controller.cvController?.isSelected(message.guid!) ?? false;

  dynamic content;

  bool hasImage = false;
  Uint8List? appIcon;

  @override
  void initState() {
    forceDelete = false;
    if (controller.cvController != null && !iOS) {
      ever<List<Message>>(controller.cvController!.selected, (event) {
        if (controller.cvController!.isSelected(message.guid!) && !selected) {
          setState(() {
            selected = true;
          });
        } else if (!controller.cvController!.isSelected(message.guid!) && selected) {
          setState(() {
            selected = false;
          });
        }
      });
    }

    if (payloadData?.appData?.first.icon != null) {
      appIcon = base64Decode(payloadData!.appData!.first.icon!);
    } 

    updateObx(() async {
      final attachment = widget.message.attachments.firstOrNull;
      if (attachment != null) {
        content = as.getContent(attachment, forExtension: true, autoDownload: true, onComplete: (file) {
          setState(() {
            content = file;
            hasImage = true;
          });
        });
        if (content is PlatformFile) {
          setState(() {});
          if ((content as PlatformFile).path != null || (content as PlatformFile).bytes != null) {
            hasImage = true;
          }
        }
      }
    });

    super.initState();
  }

  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    if (message.amkSessionId != null && es.getLatest(message.amkSessionId!) != (message.stagingGuid ?? message.guid)) {
      var appData = payloadData!.appData!.first;
      return Padding(
        padding: EdgeInsets.only(left: message.isFromMe! ? 0 : 10, right: message.isFromMe! ? 10 : 0, top: 10, bottom: 10),
        child: Row(
          children: [
            if (appIcon != null)
            ClipRRect(
              child: Image.memory(
                appIcon!,
                width: 30,
              ),
              borderRadius: BorderRadius.circular(100),
            ),
            const SizedBox(width: 5),
            Text(
              appData.ldText ?? "",
              style: context.theme.textTheme.labelMedium!.copyWith(fontWeight: FontWeight.normal, color: context.theme.colorScheme.outline),
            ),
          ],
        ),
      );
    }
    return ColorFiltered(
      colorFilter: ColorFilter.mode(!selected ? Colors.transparent : context.theme.colorScheme.tertiaryContainer.withOpacity(0.5), BlendMode.srcOver),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: payloadData == null ? null : () async {
            String? url;
            if (payloadData!.type == PayloadType.url) {
              url = payloadData!.urlData!.first.url ?? payloadData!.urlData!.first.originalUrl;
            } else {
              url = payloadData!.appData!.first.url;
            }
            if (url != null && url.startsWith("data:")) {
              es.engageApp(message);
            }
            if (message.interactiveText == "Live Location") return; // better way to handle this?
            if (url != null && Uri.tryParse(url) != null) {
              await launchUrl(
                Uri.parse(url),
                mode: LaunchMode.externalApplication,
              );
            }
          },
          child: CustomPaint(
            painter: iOS ? null : TailPainter(
              isFromMe: message.isFromMe!,
              showTail: false,
              color: context.theme.colorScheme.properSurface,
              width: 1.5,
            ),
            child: Ink(
              color: iOS ? context.theme.colorScheme.properSurface : null,
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: ns.width(context) * (ns.isTabletMode(context) ? 0.5 : 0.6),
                  maxHeight: context.height * 0.6,
                  minHeight: 40,
                  minWidth: 40,
                ),
                child: Padding(
                  padding: EdgeInsets.only(left: message.isFromMe! ? 0 : 10, right: message.isFromMe! ? 10 : 0),
                  child: AnimatedSize(
                    duration: const Duration(milliseconds: 150),
                    child: Center(
                      heightFactor: 1,
                      widthFactor: 1,
                      child: ss.settings.redactedMode.value && ss.settings.hideAttachments.value ? const Padding(
                        padding: EdgeInsets.all(15),
                        child: Text("Interactive Message")
                      ) : Stack(
                        children: [
                          Builder(
                            builder: (context) {
                              if (payloadData == null && !(message.isLegacyUrlPreview)) {
                                switch (message.interactiveText) {
                                  case "Handwritten Message":
                                  case "Digital Touch Message":
                                    if (ss.settings.enablePrivateAPI.value && ss.isMinBigSurSync && ss.serverDetailsSync().item4 >= 226) {
                                      return EmbeddedMedia(
                                        message: message,
                                        parentController: controller,
                                      );
                                    } else {
                                      return UnsupportedInteractive(
                                        content: content,
                                        payloadData: null,
                                        balloonBundleId: message.balloonBundleId,
                                      );
                                    }
                                  default:
                                    return UnsupportedInteractive(
                                      payloadData: null,
                                      content: content,
                                      balloonBundleId: message.balloonBundleId,
                                    );
                                }
                              } else if (payloadData?.type == PayloadType.url || message.isLegacyUrlPreview) {
                                if (payloadData == null) {
                                  return LegacyUrlPreview(
                                    message: message,
                                  );
                                }
                                return UrlPreview(
                                  data: payloadData!.urlData!.first,
                                  message: message,
                                );
                              } else {
                                final data = payloadData!.appData!.first;
                                switch (message.interactiveText) {
                                  case "Apple Pay":
                                    return ApplePay(
                                      data: data,
                                      message: message,
                                    );
                                  case "Live Location":
                                    return FindMy(
                                      data: data,
                                      message: message,
                                      isPopup: PopupScope.maybeOf(context) != null,
                                    );
                                  default:
                                    if (data.isSupported) {
                                      return SupportedInteractive(
                                        data: data,
                                        content: content,
                                        guid: message.stagingGuid ?? message.guid,
                                      );
                                    } else {
                                      return UnsupportedInteractive(
                                        payloadData: data,
                                        balloonBundleId: message.balloonBundleId,
                                        content: content,
                                      );
                                    }
                                }
                              }
                            }
                          ),
                          if (appIcon != null && (hasImage || ((payloadData?.appData?.first.isLive ?? false) && (payloadData?.appData?.first.isSupported ?? false))))
                          Positioned(
                            child: ClipRRect(
                              child: Image.memory(
                                appIcon!,
                                width: 30,
                              ),
                              borderRadius: BorderRadius.circular(100),
                            ),
                            top: 7,
                            left: 7,
                          )
                        ],
                      )
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
