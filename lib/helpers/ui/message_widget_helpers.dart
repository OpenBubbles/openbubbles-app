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
List<RegExpMatch> messageUrlMatches(String text) =>
    urlRegex.allMatches(text).toList(growable: false);

@visibleForTesting
void markEnrichedMessageRange(
    List<Annotation> annotations, Tuple3<String, List<int>, List?> annotation) {
  final range = annotation.item2;
  final extras = <Annotation>[];
  for (final existing in annotations) {
    if (existing.range[0] < range[0] && existing.range[1] > range[0]) {
      final duplicate = existing.copy();
      duplicate.range[1] = range[0];
      extras.add(duplicate);
      existing.range[0] = range[0];
    }

    if (existing.range[0] < range[1] && existing.range[1] > range[1]) {
      final duplicate = existing.copy();
      duplicate.range[0] = range[1];
      extras.add(duplicate);
      existing.range[1] = range[1];
    }
  }
  annotations.addAll(extras);

  for (final existing in annotations) {
    if (existing.range[0] >= range[0] && existing.range[1] <= range[1]) {
      existing.renderExtras.add(annotation);
    }
  }
}

List<InlineSpan> buildMessageSpans(BuildContext context, MessagePart part, Message message, {Color? colorOverride, bool hideBodyText = false}) {
  final textSpans = <InlineSpan>[];
  final textStyle = (context.theme.extensions[BubbleText] as BubbleText).bubbleText.apply(
    color: colorOverride ?? (message.isFromMe! ? context.theme.colorScheme.onPrimary : context.theme.colorScheme.properOnSurface),
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
      var style = textStyle;
      if (e.bold ?? false) style = style.apply(fontWeightDelta: 2);
      if (e.italic ?? false) style = style.apply(fontStyle: FontStyle.italic);
      style = style.apply(decoration: TextDecoration.combine([
        if (e.strikethrough ?? false) TextDecoration.lineThrough,
        if (e.underline ?? false) TextDecoration.underline,
      ]));
      if (e.textEffect == Attributes.BIG) style = style.apply(fontSizeDelta: 4);
      if (e.textEffect == Attributes.SMALL) style = style.apply(fontSizeDelta: -2);
      if (e.mentionedAddress != null) {
        textSpans.addAll(MessageHelper.buildEmojiText(
          part.displayText!.substring(range.first, range.last),
          style.apply(fontWeightDelta: 2),
          recognizer: TapGestureRecognizer()..onTap = () async {
            if (kIsDesktop || kIsWeb) return;
            final handle = cm.activeChat!.chat.participants.firstWhereOrNull((e) => e.address == part.annotations[i].mentionedAddress);
            if (handle?.contact == null && handle != null) {
              await mcs.invokeMethod("open-contact-form", {'address': handle.address, 'address_type': handle.address.isEmail ? 'email' : 'phone'});
            } else if (handle?.contact != null) {
              try {
                await mcs.invokeMethod("view-contact-form", {'id': handle!.contact!.id});
              } catch (_) {
                showSnackbar("Error", "Failed to find contact on device!");
              }
            }
          }
        ));
      } else {  
        textSpans.addAll(MessageHelper.buildEmojiText(
          part.displayText!.substring(range.first, range.last),
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

Future<List<InlineSpan>> buildEnrichedMessageSpans(BuildContext context, MessagePart part, Message message, {Color? colorOverride, bool hideBodyText = false}) async {
  final textSpans = <InlineSpan>[];
  final textStyle = (context.theme.extensions[BubbleText] as BubbleText).bubbleText.apply(
    color: colorOverride ?? (message.isFromMe! ? context.theme.colorScheme.onPrimary : context.theme.colorScheme.properOnSurface),
    fontSizeFactor: message.isBigEmoji ? 3 : 1,
  );
  List<Annotation> annotations = part.annotations.map((a) => a.copy()).toList();

  final controller = cvc(message.chat.target ?? cm.activeChat!.chat);
  if (!isNullOrEmpty(part.text)) {
    // Apply complete URL ranges before ML Kit can shorten them.
    for (final match in messageUrlMatches(part.text!)) {
      markEnrichedMessageRange(
          annotations, Tuple3("link", [match.start, match.end], null));
    }

    if (!kIsWeb && !kIsDesktop && ss.settings.smartReply.value) {
      if (controller.mlKitParsedText["${message.guid!}-${part.part}"] == null) {
        try {
          controller.mlKitParsedText["${message.guid!}-${part.part}"] = await GoogleMlKit.nlp.entityExtractor(EntityExtractorLanguage.english)
              .annotateText(part.text!);
        } catch (ex, stack) {
          Logger.warn('Failed to extract entities using mlkit!', error: ex, trace: stack);
        }
      }
      final entities = controller.mlKitParsedText["${message.guid!}-${part.part}"] ?? [];
      for (EntityAnnotation element in entities) {
        if (element.entities.first is AddressEntity) {
          markEnrichedMessageRange(
              annotations, Tuple3("map", [element.start, element.end], null));
        } else if (element.entities.first is PhoneEntity) {
          markEnrichedMessageRange(
              annotations, Tuple3("phone", [element.start, element.end], null));
        } else if (element.entities.first is EmailEntity) {
          markEnrichedMessageRange(
              annotations, Tuple3("email", [element.start, element.end], null));
        } else if (element.entities.first is UrlEntity) {
          markEnrichedMessageRange(
              annotations, Tuple3("link", [element.start, element.end], null));
        } else if (element.entities.first is DateTimeEntity) {
          final ent = (element.entities.first as DateTimeEntity);
          if (part.text?.substring(element.start, element.end).toLowerCase() == "now") {
            continue;
          }
          markEnrichedMessageRange(
              annotations,
              Tuple3("date", [element.start, element.end], [ent.timestamp]));
        } else if (element.entities.first is TrackingNumberEntity) {
          final ent = (element.entities.first as TrackingNumberEntity);
          markEnrichedMessageRange(
              annotations,
              Tuple3("tracking", [element.start, element.end],
                  [ent.carrier, ent.number]));
        } else if (element.entities.first is FlightNumberEntity) {
          final ent = (element.entities.first as FlightNumberEntity);
          markEnrichedMessageRange(
              annotations,
              Tuple3("flight", [element.start, element.end],
                  [ent.airlineCode, ent.flightNumber]));
        }
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
      final text = part.displayText!.substring(range.first, range.last);

      var style = textStyle;
      if (e.bold ?? false) style = style.apply(fontWeightDelta: 2);
      if (e.italic ?? false) style = style.apply(fontStyle: FontStyle.italic);
      style = style.apply(decoration: TextDecoration.combine([
        if (e.strikethrough ?? false) TextDecoration.lineThrough,
        if (e.underline ?? false) TextDecoration.underline,
      ]));
      if (e.textEffect == Attributes.BIG) style = style.apply(fontSizeDelta: 4);
      if (e.textEffect == Attributes.SMALL) style = style.apply(fontSizeDelta: -2);

      if (e.mentionedAddress != null) {
        textSpans.addAll(MessageHelper.buildEmojiText(
          text,
          style.apply(fontWeightDelta: 2),
          recognizer: TapGestureRecognizer()..onTap = () async {
            if (kIsDesktop || kIsWeb) return;
            final handle = cm.activeChat!.chat.participants.firstWhereOrNull((e) => e.address == data!.first);
            if (handle?.contact == null && handle != null) {
              await mcs.invokeMethod("open-contact-form", {'address': handle.address, 'address_type': handle.address.isEmail ? 'email' : 'phone'});
            } else if (handle?.contact != null) {
              try {
                await mcs.invokeMethod("view-contact-form", {'id': handle!.contact!.id});
              } catch (_) {
                showSnackbar("Error", "Failed to find contact on device!");
              }
            }
          }
        ));
      } else if (urlRegex.hasMatch(text) || type == "map" || text.isPhoneNumber || text.isEmail || type == "date" || type == "tracking" || type == "flight") {
        textSpans.add(
          TextSpan(
            text: text,
            recognizer: TapGestureRecognizer()
              ..onTap = () async {
                if (type == "link") {
                  String url = text;
                  if (Uri.tryParse(url)?.hasScheme != true) {
                    url = "http://$url";
                  }
                  await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
                } else if (type == "map") {
                  await MapsLauncher.launchQuery(text);
                } else if (type == "phone") {
                  await launchUrl(Uri(scheme: "tel", path: text));
                } else if (type == "email") {
                  await launchUrl(Uri(scheme: "mailto", path: text));
                } else if (type == "date") {
                  await mcs.invokeMethod("open-calendar", {"date": data!.first});
                } else if (type == "tracking") {
                  final TrackingCarrier c = data!.first;
                  final String number = data.last;
                  Clipboard.setData(ClipboardData(text: number));
                  await launchUrl(Uri.parse("https://www.google.com/search?q=${c.name} $number"), mode: LaunchMode.externalApplication);
                } else if (type == "flight") {
                  final String c = data!.first;
                  final String number = data.last;
                  await launchUrl(Uri.parse("https://www.google.com/search?q=flight $c$number"), mode: LaunchMode.externalApplication);
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
