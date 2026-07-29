import 'package:bluebubbles/database/models.dart' hide Entity;
import 'package:bluebubbles/utils/logger/logger.dart';
import 'package:bluebubbles/helpers/helpers.dart';
import 'package:bluebubbles/services/services.dart';
import 'package:collection/collection.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:google_ml_kit/google_ml_kit.dart' hide Message;
import 'package:maps_launcher/maps_launcher.dart';
import 'package:tuple/tuple.dart';
import 'package:url_launcher/url_launcher.dart';

@visibleForTesting
String? safeMessageSubstring(String? text, List<int> range) {
  if (text == null || range.length < 2) return null;
  final start = range.first.clamp(0, text.length).toInt();
  final end = range.last.clamp(start, text.length).toInt();
  if (start >= end) return null;
  return text.substring(start, end);
}

List<InlineSpan> buildMessageSpans(
    BuildContext context, MessagePart part, Message message,
    {Color? colorOverride, bool hideBodyText = false}) {
  final textSpans = <InlineSpan>[];
  final textStyle =
      (context.theme.extensions[BubbleText] as BubbleText).bubbleText.apply(
            color: colorOverride ??
                ((message.isFromMe ?? false)
                    ? context.theme.colorScheme.onPrimary
                    : context.theme.colorScheme.properOnSurface),
            fontSizeFactor: message.isBigEmoji ? 3 : 1,
          );

  if (!isNullOrEmpty(part.subject)) {
    textSpans.addAll(MessageHelper.buildEmojiText(
      "${part.displaySubject}${!hideBodyText ? "\n" : ""}",
      textStyle.apply(fontWeightDelta: 2),
    ));
  }
  if (part.annotations.isNotEmpty) {
    part.annotations.forEachIndexed((i, e) {
      final range = part.annotations[i].range;
      final text = safeMessageSubstring(part.displayText, range);
      if (text == null) return;
      var style = textStyle;
      if (e.bold ?? false) style = style.apply(fontWeightDelta: 2);
      if (e.italic ?? false) style = style.apply(fontStyle: FontStyle.italic);
      style = style.apply(
          decoration: TextDecoration.combine([
        if (e.strikethrough ?? false) TextDecoration.lineThrough,
        if (e.underline ?? false) TextDecoration.underline,
      ]));
      if (e.textEffect == Attributes.BIG) style = style.apply(fontSizeDelta: 4);
      if (e.textEffect == Attributes.SMALL) {
        style = style.apply(fontSizeDelta: -2);
      }
      if (e.mentionedAddress != null) {
        textSpans.addAll(MessageHelper.buildEmojiText(
            text, style.apply(fontWeightDelta: 2),
            recognizer: TapGestureRecognizer()
              ..onTap = () async {
                if (kIsDesktop || kIsWeb) return;
                final handle = cm.activeChat!.chat.participants
                    .firstWhereOrNull((e) =>
                        e.address == part.annotations[i].mentionedAddress);
                if (handle?.contact == null && handle != null) {
                  await mcs.invokeMethod("open-contact-form", {
                    'address': handle.address,
                    'address_type': handle.address.isEmail ? 'email' : 'phone'
                  });
                } else if (handle?.contact != null) {
                  try {
                    await mcs.invokeMethod(
                        "view-contact-form", {'id': handle!.contact!.id});
                  } catch (_) {
                    showSnackbar("Error", "Failed to find contact on device!");
                  }
                }
              }));
      } else {
        textSpans.addAll(MessageHelper.buildEmojiText(
          text,
          style,
        ));
      }
    });
  } else if (!isNullOrEmpty(part.displayText)) {
    textSpans.addAll(MessageHelper.buildEmojiText(
      part.displayText!,
      textStyle,
    ));
  }

  return textSpans;
}

Future<List<InlineSpan>> buildEnrichedMessageSpans(
    BuildContext context, MessagePart part, Message message,
    {Color? colorOverride, bool hideBodyText = false}) async {
  final textSpans = <InlineSpan>[];
  final textStyle =
      (context.theme.extensions[BubbleText] as BubbleText).bubbleText.apply(
            color: colorOverride ??
                ((message.isFromMe ?? false)
                    ? context.theme.colorScheme.onPrimary
                    : context.theme.colorScheme.properOnSurface),
            fontSizeFactor: message.isBigEmoji ? 3 : 1,
          );
  // extract rich content
  final urlRegex = RegExp(
      r'((https?://)|(www\.))[-a-zA-Z0-9@:%._+~#=]{1,256}\.[a-zA-Z0-9()]{1,6}([-a-zA-Z0-9/()@:%_.~#?&=*\[\]]*)\b');

  List<Annotation> annotations = part.annotations
      .where((annotation) =>
          safeMessageSubstring(part.displayText, annotation.range) != null)
      .map((annotation) => annotation.copy())
      .toList();
  void markRange(Tuple3<String, List<int>, List?> annotation) {
    var range = annotation.item2;
    List<Annotation> extras = [];
    // split em up correctly
    for (var a in annotations) {
      if (a.range[0] < range[0] && a.range[1] > range[0]) {
        var dup = a.copy();
        dup.range[1] = range[0];
        extras.add(dup);

        // end this range at the start of my new range
        a.range[0] = range[0];
      }

      if (a.range[0] < range[1] && a.range[1] > range[1]) {
        var dup = a.copy();
        dup.range[0] = range[1];
        extras.add(dup);

        // end this range at the start of my new range
        a.range[1] = range[1];
      }
    }
    annotations.addAll(extras);

    for (var a in annotations) {
      if (a.range[0] >= range[0] && a.range[1] <= range[1]) {
        a.renderExtras.add(annotation);
      }
    }
  }

  final controller = cvc(message.chat.target ?? cm.activeChat!.chat);
  if (!isNullOrEmpty(part.text)) {
    if (!kIsWeb && !kIsDesktop && ss.settings.smartReply.value) {
      if (controller.mlKitParsedText["${message.guid!}-${part.part}"] == null) {
        final extractor =
            GoogleMlKit.nlp.entityExtractor(EntityExtractorLanguage.english);
        try {
          controller.mlKitParsedText["${message.guid!}-${part.part}"] =
              await extractor.annotateText(part.text!);
        } catch (ex, stack) {
          Logger.warn('Failed to extract entities using mlkit!',
              error: ex, trace: stack);
        } finally {
          await extractor.close();
        }
      }
      final entities =
          controller.mlKitParsedText["${message.guid!}-${part.part}"] ?? [];
      for (EntityAnnotation element in entities) {
        if (element.entities.first is AddressEntity) {
          markRange(Tuple3("map", [element.start, element.end], null));
        } else if (element.entities.first is PhoneEntity) {
          markRange(Tuple3("phone", [element.start, element.end], null));
        } else if (element.entities.first is EmailEntity) {
          markRange(Tuple3("email", [element.start, element.end], null));
        } else if (element.entities.first is UrlEntity) {
          markRange(Tuple3("link", [element.start, element.end], null));
        } else if (element.entities.first is DateTimeEntity) {
          final ent = (element.entities.first as DateTimeEntity);
          if (part.text?.substring(element.start, element.end).toLowerCase() ==
              "now") {
            continue;
          }
          markRange(
              Tuple3("date", [element.start, element.end], [ent.timestamp]));
        } else if (element.entities.first is TrackingNumberEntity) {
          final ent = (element.entities.first as TrackingNumberEntity);
          markRange(Tuple3("tracking", [element.start, element.end],
              [ent.carrier, ent.number]));
        } else if (element.entities.first is FlightNumberEntity) {
          final ent = (element.entities.first as FlightNumberEntity);
          markRange(Tuple3("flight", [element.start, element.end],
              [ent.airlineCode, ent.flightNumber]));
        }
      }
    } else {
      List<RegExpMatch> matches = urlRegex.allMatches(part.text!).toList();
      for (RegExpMatch match in matches) {
        markRange(Tuple3("link", [match.start, match.end], null));
      }
    }
  }

  annotations.sort((a, b) => a.range[0].compareTo(b.range[0]));

  // render subject
  if (!isNullOrEmpty(part.subject)) {
    textSpans.addAll(MessageHelper.buildEmojiText(
      "${part.displaySubject}${!hideBodyText ? "\n" : ""}",
      textStyle.apply(fontWeightDelta: 2),
    ));
  }
  // render rich content if needed
  if (annotations.isNotEmpty) {
    annotations.forEachIndexed((i, e) {
      var item = e.renderExtras.firstOrNull;

      final type = item?.item1;
      final range = e.range;
      final data = item?.item3;
      final text = safeMessageSubstring(part.displayText, range);
      if (text == null) return;

      var style = textStyle;
      if (e.bold ?? false) style = style.apply(fontWeightDelta: 2);
      if (e.italic ?? false) style = style.apply(fontStyle: FontStyle.italic);
      style = style.apply(
          decoration: TextDecoration.combine([
        if (e.strikethrough ?? false) TextDecoration.lineThrough,
        if (e.underline ?? false) TextDecoration.underline,
      ]));
      if (e.textEffect == Attributes.BIG) style = style.apply(fontSizeDelta: 4);
      if (e.textEffect == Attributes.SMALL) {
        style = style.apply(fontSizeDelta: -2);
      }

      if (e.mentionedAddress != null) {
        textSpans.addAll(MessageHelper.buildEmojiText(
            text, style.apply(fontWeightDelta: 2),
            recognizer: TapGestureRecognizer()
              ..onTap = () async {
                if (kIsDesktop || kIsWeb) return;
                final handle = cm.activeChat!.chat.participants
                    .firstWhereOrNull((e) => e.address == data!.first);
                if (handle?.contact == null && handle != null) {
                  await mcs.invokeMethod("open-contact-form", {
                    'address': handle.address,
                    'address_type': handle.address.isEmail ? 'email' : 'phone'
                  });
                } else if (handle?.contact != null) {
                  try {
                    await mcs.invokeMethod(
                        "view-contact-form", {'id': handle!.contact!.id});
                  } catch (_) {
                    showSnackbar("Error", "Failed to find contact on device!");
                  }
                }
              }));
      } else if (urlRegex.hasMatch(text) ||
          type == "map" ||
          text.isPhoneNumber ||
          text.isEmail ||
          type == "date" ||
          type == "tracking" ||
          type == "flight") {
        textSpans.add(
          TextSpan(
            text: text,
            recognizer: TapGestureRecognizer()
              ..onTap = () async {
                if (type == "link") {
                  String url = text;
                  if (!url.startsWith("http://") &&
                      !url.startsWith("https://")) {
                    url = "http://$url";
                  }
                  await launchUrl(Uri.parse(url),
                      mode: LaunchMode.externalApplication);
                } else if (type == "map") {
                  await MapsLauncher.launchQuery(text);
                } else if (type == "phone") {
                  await launchUrl(Uri(scheme: "tel", path: text));
                } else if (type == "email") {
                  await launchUrl(Uri(scheme: "mailto", path: text));
                } else if (type == "date") {
                  await mcs
                      .invokeMethod("open-calendar", {"date": data!.first});
                } else if (type == "tracking") {
                  final TrackingCarrier c = data!.first;
                  final String number = data.last;
                  Clipboard.setData(ClipboardData(text: number));
                  await launchUrl(
                      Uri.parse(
                          "https://www.google.com/search?q=${c.name} $number"),
                      mode: LaunchMode.externalApplication);
                } else if (type == "flight") {
                  final String c = data!.first;
                  final String number = data.last;
                  await launchUrl(
                      Uri.parse(
                          "https://www.google.com/search?q=flight $c$number"),
                      mode: LaunchMode.externalApplication);
                }
              },
            style: style.apply(decoration: TextDecoration.underline),
          ),
        );
      } else {
        textSpans.addAll(MessageHelper.buildEmojiText(
          text,
          style,
        ));
      }
    });
  } else if (!isNullOrEmpty(part.displayText)) {
    textSpans.addAll(MessageHelper.buildEmojiText(
      part.displayText!,
      textStyle,
    ));
  }

  return textSpans;
}
