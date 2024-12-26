import "dart:convert";
import "dart:math";

import "package:bluebubbles/app/layouts/conversation_view/dialogs/custom_mention_dialog.dart";
import "package:bluebubbles/helpers/helpers.dart";
import "package:bluebubbles/database/models.dart";
import "package:bluebubbles/services/services.dart";
import 'package:bluebubbles/utils/emoji.dart';
import "package:bluebubbles/utils/emoticons.dart";
import "package:collection/collection.dart";
import "package:emojis/emoji.dart";
import "package:flutter/foundation.dart";
import "package:flutter/material.dart";
import "package:flutter/services.dart";
import "package:get/get.dart";
import "package:languagetool_textfield/core/enums/mistake_type.dart";
import 'package:languagetool_textfield/languagetool_textfield.dart';
import "package:languagetool_textfield/utils/closed_range.dart";
import "package:languagetool_textfield/utils/keep_latest_response_service.dart";
import 'package:tuple/tuple.dart';
import 'package:bluebubbles/utils/logger/logger.dart';

class Mentionable {
  Mentionable({required this.handle});

  final Handle handle;
  String? customDisplayName;

  String get displayName => customDisplayName ?? handle.displayName.split(" ").first;

  String get address => handle.address;

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is Mentionable && runtimeType == other.runtimeType && address == other.address;

  @override
  int get hashCode => address.hashCode;

  @override
  String toString() => displayName;
}

class SpellCheckTextEditingController extends TextEditingController {
  SpellCheckTextEditingController({super.text, this.focusNode}) {
    assert(focusNode != null || !(kIsDesktop || kIsWeb));
    _languageCheckService =
        DebounceLangToolService(LangToolService(LanguageToolClient(language: ss.settings.spellcheckLanguage.value)),
            const Duration(milliseconds: 500));
    _processMistakes(text);
  }

  /// focusNode
  /// Required for spellcheck replacement to work
  FocusNode? focusNode;

  /// Language tool configs
  final HighlightStyle highlightStyle = const HighlightStyle();
  final _latestResponseService = KeepLatestResponseService();
  late final LanguageCheckService _languageCheckService;

  /// List which contains Mistake objects spans are built from
  List<Mistake> _mistakes = [];
  int _selectedMistakeIndex = -1;

  Mistake? get selectedMistake => _selectedMistakeIndex == -1 ? null : _mistakes.elementAtOrNull(_selectedMistakeIndex);

  Object? _fetchError;

  /// An error that may have occurred during the API fetch.
  Object? get fetchError => _fetchError;

  /// Mistake tooltip
  OverlayEntry? _mistakeTooltip;

  @override
  set value(TextEditingValue newValue) {
    String origText = newValue.text;
    int origOffset = newValue.selection.start;
    String newText = newValue.text;
    int newOffset = newValue.selection.start;

    if (ss.settings.replaceEmoticonsWithEmoji.value) {
      List<(int, int)> offsetsAndDifferences;
      (newText, offsetsAndDifferences) = replaceEmoticons(newText);

      if (offsetsAndDifferences.isNotEmpty) {
        // Add all differences before the cursor and subtract from offset
        for (final (_offset, difference) in offsetsAndDifferences) {
          if (_offset < newOffset) {
            newOffset -= difference;
          }
        }
      }
    }

    final regExp = RegExp(r"(?<=^|[^a-zA-Z\d]):[^: \n]{2,}:", multiLine: true);
    final matches = regExp.allMatches(newText);
    if (matches.isNotEmpty) {
      RegExpMatch match = matches.lastWhere((m) => m.start < newOffset);
      // Full emoji text (do not search for partial matches)
      String emojiName = newText.substring(match.start + 1, match.end - 1).toLowerCase();
      if (emojiNames.keys.contains(emojiName)) {
        // We can replace the :emoji: with the actual emoji here
        final emoji = Emoji.byShortName(emojiName)!;
        newText = newText.substring(0, match.start) + emoji.char + newText.substring(match.end);
        newOffset = match.start + emoji.char.length;
      }
    }

    if (newText != origText || newOffset != origOffset) {
      newValue = newValue.copyWith(
        text: newText,
        selection: TextSelection.collapsed(offset: newOffset),
      );
    }

    if (kIsDesktop || kIsWeb) {
      _handleTextChange(newValue.text);
      _mistakeTooltip?.remove();
      _mistakeTooltip = null;
    }

    super.value = newValue;
  }

  @override
  set selection(TextSelection newSelection) {
    if (kIsDesktop || kIsWeb) {
      _handleSelectionChange(newSelection);
    }
    super.selection = newSelection;
  }

  @override
  void dispose() {
    _languageCheckService.dispose();
    _mistakeTooltip?.remove();
    _mistakeTooltip = null;
    super.dispose();
  }

  void insert(TextSelection selection, String value, { Annotation? newAnnotation }) {
    text = text.substring(0, selection.baseOffset) + value + text.substring(selection.extentOffset);
  }

  /// Replaces mistake with given replacement
  void replaceMistake(Mistake mistake, String replacement) {
    final mistakes = List<Mistake>.from(_mistakes);
    mistakes.remove(mistake);
    _mistakes = mistakes;
    text = text.replaceRange(mistake.offset, mistake.endOffset, replacement);
    Future.microtask.call(() {
      final newOffset = mistake.offset + replacement.length;
      selection = TextSelection.fromPosition(TextPosition(offset: newOffset));
      focusNode?.requestFocus();
    });
  }

  /// Clear mistakes list when text mas modified and get a new list of mistakes
  /// via API
  Future<void> _handleTextChange(String newText) async {
    ///set value triggers each time, even when cursor changes its location
    ///so this check avoid cleaning Mistake list when text wasn't really changed
    if (newText == text) return;

    await _processMistakes(newText);
  }

  Future<void> _handleSelectionChange(TextSelection newSelection) async {
    if (newSelection.baseOffset == newSelection.extentOffset) {
      _selectedMistakeIndex = -1;
      return;
    }
    final mistakeIndex = _mistakes
        .indexWhere((e) => (e.offset == newSelection.baseOffset) && (e.endOffset == newSelection.extentOffset));
    if (mistakeIndex != -1) {
      _selectedMistakeIndex = mistakeIndex;
    } else {
      _selectedMistakeIndex = -1;
    }
  }

  Future<void> _processMistakes(String newText) async {
    if (!ss.settings.spellcheck.value || newText.isEmpty) {
      _mistakes.clear();
      _mistakeTooltip?.remove();
      _mistakeTooltip = null;
      notifyListeners();
      return;
    }
    final filteredMistakes = _filterMistakesOnChanged(newText);
    _mistakes = filteredMistakes.toList();

    final mistakesWrapper = await _latestResponseService.processLatestOperation(
          () => _languageCheckService.findMistakes(newText),
    );
    if (mistakesWrapper == null || !mistakesWrapper.hasResult) return;

    final mistakes = mistakesWrapper.result();
    _fetchError = mistakesWrapper.error;

    _mistakes = List.from(mistakes);
    notifyListeners();
  }

  /// Filters the list of mistakes based on the changes
  /// in the text when it is changed.
  Iterable<Mistake> _filterMistakesOnChanged(String newText) sync* {
    final isSelectionRangeEmpty = selection.end == selection.start;
    final lengthDiscrepancy = newText.length - text.length;

    for (final mistake in _mistakes) {
      Mistake? newMistake;

      newMistake = isSelectionRangeEmpty
          ? _adjustMistakeOffsetWithCaretCursor(
        mistake: mistake,
        lengthDiscrepancy: lengthDiscrepancy,
      )
          : _adjustMistakeOffsetWithSelectionRange(
        mistake: mistake,
        lengthDiscrepancy: lengthDiscrepancy,
      );

      if (newMistake != null) yield newMistake;
    }
  }

  /// Adjusts the mistake offset when the selection is a caret cursor.
  Mistake? _adjustMistakeOffsetWithCaretCursor({
    required Mistake mistake,
    required int lengthDiscrepancy,
  }) {
    final mistakeRange = ClosedRange(mistake.offset, mistake.endOffset);
    final caretLocation = selection.base.offset;

    // Don't highlight mistakes on changed text
    // until we get an update from the API.
    final isCaretOnMistake = mistakeRange.contains(caretLocation);
    if (isCaretOnMistake) return null;

    final shouldAdjustOffset = mistakeRange.isBeforeOrAt(caretLocation);
    if (!shouldAdjustOffset) return mistake;

    final newOffset = mistake.offset + lengthDiscrepancy;

    return mistake.copyWith(offset: newOffset);
  }

  /// Adjusts the mistake offset when the selection is a range.
  Mistake? _adjustMistakeOffsetWithSelectionRange({
    required Mistake mistake,
    required int lengthDiscrepancy,
  }) {
    final selectionRange = ClosedRange(selection.start, selection.end);
    final mistakeRange = ClosedRange(mistake.offset, mistake.endOffset);

    final hasSelectedTextChanged = selectionRange.overlapsWith(mistakeRange);
    if (hasSelectedTextChanged) return null;

    final shouldAdjustOffset = selectionRange.isAfterOrAt(mistake.offset);
    if (!shouldAdjustOffset) return mistake;

    final newOffset = mistake.offset + lengthDiscrepancy;

    return mistake.copyWith(offset: newOffset);
  }

  /// Returns color for mistake TextSpan style
  Color _getMistakeColor(MistakeType type) {
    switch (type) {
      case MistakeType.misspelling:
        return highlightStyle.misspellingMistakeColor;
      case MistakeType.typographical:
        return highlightStyle.typographicalMistakeColor;
      case MistakeType.grammar:
        return highlightStyle.grammarMistakeColor;
      case MistakeType.uncategorized:
        return highlightStyle.uncategorizedMistakeColor;
      case MistakeType.nonConformance:
        return highlightStyle.nonConformanceMistakeColor;
      case MistakeType.style:
        return highlightStyle.styleMistakeColor;
      case MistakeType.other:
        return highlightStyle.otherMistakeColor;
    }
  }

  OverlayEntry _createTooltip(BuildContext context, Offset offset, Mistake mistake, String mistakeText) {
    final Color color = _getMistakeColor(mistake.type);
    Iterable<String> replacements = mistake.replacements.take(15);
    return OverlayEntry(
      builder: (context) =>
          Positioned(
            left: offset.dx - 100,
            width: 200,
            bottom: (context.height - offset.dy) ~/ 60 * 60 + 60,
            child: Center(
              child: Container(
                decoration: BoxDecoration(
                  color: context.theme.colorScheme.properSurface,
                  borderRadius: BorderRadius.circular(8.0),
                ),
                padding: const EdgeInsets.all(8.0),
                child: Material(
                  color: Colors.transparent,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(mistake.type.value.capitalizeFirst!,
                          style: context.textTheme.titleSmall!.copyWith(color: color)),
                      Text(
                        "\"$mistakeText\"",
                        style: context.textTheme.bodySmall!.copyWith(color: context.theme.colorScheme.outline),
                      ),
                      const SizedBox(height: 8.0),
                      replacements.isEmpty
                          ? Text(
                        "No Replacements",
                        style: context.textTheme.bodySmall!.copyWith(color: context.theme.colorScheme.outline),
                      )
                          : Wrap(
                        alignment: WrapAlignment.center,
                        spacing: 4.0,
                        runSpacing: 4.0,
                        children: List.generate(replacements.length, (index) {
                          final replacement = mistake.replacements[index];
                          return InkWell(
                            borderRadius: BorderRadius.circular(8.0),
                            hoverColor: color.withOpacity(0.2),
                            onTapDown: (_) {
                              replaceMistake(mistake, replacement);
                            },
                            child: Container(
                              padding: const EdgeInsets.all(4.0),
                              decoration: BoxDecoration(
                                border: Border.all(color: context.theme.colorScheme.outline),
                                borderRadius: BorderRadius.circular(8.0),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(4.0),
                                child: Text(replacement, style: context.textTheme.bodySmall),
                              ),
                            ),
                          );
                        }),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
    );
  }

  /// Builds a TextSpan with mistakes highlighted
  /// [chunk] - the text chunk to build TextSpan for
  /// [offset] - the offset of the chunk in the whole text
  /// [endOffset] - the end offset of the chunk in the whole text
  /// [style] - the style to apply to the text
  TextSpan buildMistakeTextSpans({
    required BuildContext context,
    required String chunk,
    required int offset,
    TextStyle? style,
  }) {
    // Only spellcheck on desktop/web
    if (kIsDesktop || kIsWeb) {
      // Check if there are mistakes in this chunk
      int endOffset = offset + chunk.length;
      final mistakes = _mistakes.where((e) => e.offset >= offset && e.endOffset <= endOffset).toList();
      List<InlineSpan> spans = [];
      if (mistakes.isNotEmpty) {
        // Split text into mistakes and nonmistakes
        for (int i = 0; i < mistakes.length; i++) {
          final mistake = mistakes[i];
          final mistakeStart = mistake.offset - offset;
          final mistakeEnd = mistake.endOffset - offset;
          final mistakeText = chunk.substring(mistakeStart, mistakeEnd);
          final mistakeStyle = (style ?? const TextStyle()).copyWith(
            backgroundColor: _getMistakeColor(mistake.type).withOpacity(highlightStyle.backgroundOpacity),
            decoration: highlightStyle.decoration,
            decorationColor: _getMistakeColor(mistake.type),
            decorationThickness: highlightStyle.mistakeLineThickness,
          );

          final prevMistakeEnd = i == 0 ? 0 : mistakes[i - 1].endOffset - offset;
          final leadingNonMistakeText = chunk.substring(prevMistakeEnd, mistakeStart);
          if (leadingNonMistakeText.isNotEmpty) spans.add(TextSpan(text: leadingNonMistakeText, style: style));

          spans.add(
            TextSpan(
              text: mistakeText,
              style: mistakeStyle,
              onEnter: (event) {
                if (_mistakeTooltip != null) {
                  _mistakeTooltip!.remove();
                }
                _mistakeTooltip = _createTooltip(context,
                    Offset(event.position.dx - ns.widthChatListLeft(context), event.position.dy), mistake, mistakeText);
                Overlay.of(context).insert(_mistakeTooltip!);
              },
            ),
          );

          if (i == mistakes.length - 1) {
            final nextMistakeStart = i == mistakes.length - 1 ? chunk.length : mistakes[i + 1].offset - offset;
            final trailingNonMistakeText = chunk.substring(mistakeEnd, nextMistakeStart);
            if (trailingNonMistakeText.isNotEmpty) spans.add(TextSpan(text: trailingNonMistakeText, style: style));
          }
        }
        return TextSpan(children: spans);
      }
    }
    return TextSpan(text: chunk, style: style);
  }

  @override
  TextSpan buildTextSpan({
    required BuildContext context,
    TextStyle? style,
    required bool withComposing,
  }) {
    return buildMistakeTextSpans(context: context, chunk: text, offset: 0, style: style);
  }
}

class MentionTextEditingController extends SpellCheckTextEditingController {
  MentionTextEditingController({
    super.text,
    super.focusNode,
    this.mentionables = const <Mentionable>[],
  }) {
    TextSelection oldTextFieldSelection = const TextSelection.collapsed(offset: 0);
    String lastText = "";

    addListener(() {
      if (lastText != text) {
        // something changed, compute deltas
        // use text diff because some keyboards can bump the cursor forward into an existing space when typing a period during an autocorrect.
        int caret = min(selection.baseOffset, selection.extentOffset) - min(oldTextFieldSelection.baseOffset, oldTextFieldSelection.extentOffset);
        var textdiff = text.length - lastText.length;
        if (caret != textdiff) {
          Logger.info("Caret diff $caret $textdiff");
        }
        try {
          mutateRange(oldTextFieldSelection, oldTextFieldSelection.isCollapsed ? textdiff : caret);
        } catch (e, s) {
          Logger.error("Invalid changed annotations!", error: e, trace: s);
          if (text.isNotEmpty) {
            annotations = [Annotation(range: [0, text.length])];
          } else {
            annotations = [];
          }
          mentionCache = {};
        }
      }
      oldTextFieldSelection = selection;
      lastText = text;
    });
  }

  Map<String, String> mentionCache = {};
  List<Mentionable> mentionables;
  List<Annotation> annotations = [];

  String saveAnnotations() {
    var values = {
      "annotations": annotations.map((i) => i.toMap()).toList(),
      "cache": mentionCache
    };
    return jsonEncode(values);
  }

  void restoreAnnotations(String myText, String values) {
    try {
      changeLock = true;
      text = myText; // this triggers a rebuild
    } finally {
      changeLock = false;
    }
    var data = jsonDecode(values);
    annotations = data["annotations"].map((i) => Annotation.fromMap(i)).toList().cast<Annotation>();
    mentionCache = data["cache"].cast<String, String>();
    try {
      validateRange();
    } catch (e, s) {
      Logger.error("Invalid restored annotations!", error: e, trace: s);
      if (text.isNotEmpty) {
        annotations = [Annotation(range: [0, text.length])];
      } else {
        annotations = [];
      }
      mentionCache = {};
    }
  }

  bool changeLock = false;

  void validateRange() {
    annotations.sort((a, b) => a.range[0].compareTo(b.range[0]));
    if (text.isEmpty) {
      assert(annotations.isEmpty);
    }
    Annotation? lastAnnotation;
    var pointer = 0;
    while (pointer < text.length) {
      var annotation = annotations.firstWhere((a) => a.range[0] == pointer);
      // do we overlap with any other annotation?
      assert(!annotations.any((a) => ((a.range[0] >= annotation.range[0] && a.range[0] < annotation.range[1]) ||
          (a.range[1] > annotation.range[0] && a.range[1] <= annotation.range[1])) && annotation != a));
      // we cannot have zero length
      assert(annotation.range[0] != annotation.range[1]);
      pointer = annotation.range[1];

      if (lastAnnotation?.eqUnranged(annotation) ?? false) {
        lastAnnotation!.range[1] = annotation.range[1]; // merge equal annotations
        annotations.remove(annotation);
      } else {
        lastAnnotation = annotation;
      }
    }
    assert(pointer == text.length);
    assert(lastAnnotation == annotations.lastOrNull);
  }

  List<Annotation> annotationsForRange(TextSelection range) {
    return annotations.where((a) =>
        ((a.range[0] >= range.baseOffset && a.range[0] < range.extentOffset) ||
          (a.range[1] > range.baseOffset && a.range[1] <= range.extentOffset) ||
          (range.baseOffset >= a.range[0] && range.baseOffset < a.range[1] &&
          range.extentOffset >= a.range[0] && range.extentOffset < a.range[1]))
    ).toList();
  }

  void mutateRange(TextSelection collapse, int length, { Annotation? newAnnotation }) {
    // base < offset
    if (collapse.baseOffset > collapse.extentOffset) {
      collapse = TextSelection(baseOffset: collapse.extentOffset, extentOffset: collapse.baseOffset);
    }
    if (changeLock) return;
    if (!collapse.isCollapsed) {
      annotations.retainWhere((a) {
        var deleteLen = collapse.extentOffset - collapse.baseOffset;
        if (a.range[0] >= collapse.extentOffset) {
          a.range[0] -= deleteLen;
        } else if (a.range[0] >= collapse.baseOffset) {
          a.range[0] = collapse.baseOffset;
        }
        if (a.range[1] >= collapse.extentOffset) {
          a.range[1] -= deleteLen;
        } else if (a.range[1] >= collapse.baseOffset) {
          a.range[1] = collapse.baseOffset;
        }
        return a.range[0] != a.range[1];
      });
    }

    var annotation = annotations.firstWhereOrNull((a) => collapse.baseOffset > a.range[0] && collapse.baseOffset <= a.range[1]);
  
    annotations.retainWhere((a) {
      if (a.range[0] >= collapse.baseOffset) {
        a.range[0] += length;
      }
      if (a.range[1] >= collapse.baseOffset) {
        a.range[1] += length;
      }
      return a.range[0] != a.range[1];
    });

    // initial case where there is an empty text field and no annotations
    if (annotation == null || (annotation.mentionedAddress != null /* can't add to this*/ && length > 0)) {
      if (annotations.isNotEmpty && annotation?.mentionedAddress == null && collapse.baseOffset > 0) {
        throw Exception("Not empty no annotation??");
      }
      if (length > 0) {
        annotation?.range[1] -= length; // this was grown in the retainWhere above; make space for my new one
        var annotation2 = newAnnotation ?? Annotation();
        annotation2.range = [annotation?.range[1] ?? 0, (annotation?.range[1] ?? 0) + length];
        annotations.add(annotation2);
      }

      validateRange();
      return;
    }

    if (newAnnotation != null) {
      // mark the range as annotated
      markRange(TextSelection(baseOffset: collapse.baseOffset, extentOffset: collapse.baseOffset + length), newAnnotation);
    }

    validateRange();
  }

  void markRange(TextSelection range, Annotation annotation) {
    // base < offset
    if (range.baseOffset > range.extentOffset) {
      range = TextSelection(baseOffset: range.extentOffset, extentOffset: range.baseOffset);
    }
    if (changeLock) return;
    List<Annotation> extras = [];
    // split em up correctly
    for (var a in annotations) {
      if (a.range[0] < range.baseOffset && a.range[1] > range.baseOffset) {
        var dup = a.copy();
        dup.range[1] = range.baseOffset;
        extras.add(dup);

        // end this range at the start of my new range
        a.range[0] = range.baseOffset;
      }

      if (a.range[0] < range.extentOffset && a.range[1] > range.extentOffset) {
        var dup = a.copy();
        dup.range[0] = range.extentOffset;
        extras.add(dup);

        // end this range at the start of my new range
        a.range[1] = range.extentOffset;
      }
    }
    annotations.addAll(extras);

    for (var a in annotations) {
      if (a.range[0] >= range.baseOffset && a.range[1] <= range.extentOffset) {
        annotation.applyTo(a);
      }
    }
    validateRange();
  }

  @override
  void clear() {
    try {
      changeLock = true;
      annotations = [];
      super.clear();
    } finally {
      changeLock = false;
    }
  }

  @override
  void insert(TextSelection selection, String value, { Annotation? newAnnotation, int? moveCursor }) {
    try {
      changeLock = true;
      text = text.substring(0, selection.baseOffset) + value + text.substring(selection.extentOffset); // this triggers a rebuild
    } finally {
      changeLock = false;
    }
    mutateRange(selection, value.length, newAnnotation: newAnnotation);
    if (moveCursor != null) {
      this.selection = TextSelection.collapsed(offset: selection.baseOffset + value.length + moveCursor);
    }
  }

  void addMention(String candidate, Mentionable mentionable) {
    final indexSelection = selection.base.offset;
    final atIndex = text.substring(0, indexSelection).lastIndexOf("@");
    final index = mentionables.indexOf(mentionable);
    if (index == -1 || atIndex == -1) return;

    mentionCache[mentionable.address] = mentionable.displayName;

    // always store mentions as one character since WidgetSpan takes one character.
    
    var next = text.substring(indexSelection);
    var needsSpace = !next.startsWith(" ");
    var removeSelection = TextSelection(baseOffset: atIndex, extentOffset: indexSelection);
    insert(removeSelection, " ", newAnnotation: Annotation(mentionedAddress: mentionable.address), moveCursor: !needsSpace ? 1 : null);
    if (needsSpace) {
      insert(TextSelection.collapsed(offset: atIndex + 1), " ", moveCursor: 0);
    }

    // processMentions();
  }

  void importMessagePart(MessagePart part) {
    List<Annotation> copiedAnnotations = part.annotations.map((a) => a.copy()).toList();
    var savedText = part.text!;

    var waterfall = 0;
    for (var annotation in copiedAnnotations) {
      annotation.range[0] += waterfall;
      annotation.range[1] += waterfall;
      if (annotation.mentionedAddress == null) continue;

      var address = savedText.substring(annotation.range[0], annotation.range[1]);
      mentionCache[annotation.mentionedAddress!] = address;

      // ignore: prefer_interpolation_to_compose_strings
      savedText = savedText.substring(0, annotation.range[0]) + " " + savedText.substring(annotation.range[1]);
      annotation.range[1] = annotation.range[0] + 1;
      waterfall += 1 - address.length; // it already had 1 accouted for the space
    }

    annotations = copiedAnnotations;
    try {
      changeLock = true;
      text = savedText; // this triggers a rebuild
    } finally {
      changeLock = false;
    }
  }

  void refresh() {
    var position = selection;
    text = text;

    selection = position;
  }

  AttributedBody getFinalAnnotations() {
    var saved = annotations;
    var savedText = text;
    restoreAnnotations(savedText, saveAnnotations()); // duplicate annotations
    // replace mentions with proper text
    var waterfall = 0;
    for (var annotation in saved) {
      annotation.range[0] += waterfall;
      annotation.range[1] += waterfall;
      if (annotation.mentionedAddress == null) continue;
      var address = mentionCache[annotation.mentionedAddress]!;

      savedText = savedText.substring(0, annotation.range[0]) + address + savedText.substring(annotation.range[1]);
      annotation.range[1] = annotation.range[0] + address.length;
      waterfall += address.length - 1; // it already had 1 accouted for the space
    }
    return AttributedBody(
      string: savedText,
      runs: saved.map((a) => Run(
        range: [a.range[0], a.range[1] - a.range[0]],
        attributes: Attributes(
          mention: a.mentionedAddress,
          textEffect: a.textEffect,
          bold: a.bold,
          italic: a.italic,
          strikethrough: a.strikethrough,
          underline: a.underline,
          messagePart: 0,
        ),
      )).toList().cast<Run>(),
    );
  }

  Map<ShortcutActivator, VoidCallback> getShortcuts() {
    return <ShortcutActivator, VoidCallback>{
      const SingleActivator(LogicalKeyboardKey.keyB, control: true): () {
        var range = selection;
        if (selection.isCollapsed) return;
        if (range.baseOffset > range.extentOffset) {
          range = TextSelection(baseOffset: range.extentOffset, extentOffset: range.baseOffset);
        }

        var annotations = annotationsForRange(range);
        var already = annotations!.every((a) => a.bold == true);
        markRange(range, Annotation(bold: !already));
        refresh();
      },
      const SingleActivator(LogicalKeyboardKey.keyI, control: true): () {
        var range = selection;
        if (selection.isCollapsed) return;
        if (range.baseOffset > range.extentOffset) {
          range = TextSelection(baseOffset: range.extentOffset, extentOffset: range.baseOffset);
        }

        var annotations = annotationsForRange(range);
        var already = annotations!.every((a) => a.italic == true);
        markRange(range, Annotation(italic: !already));
        refresh();
      },
      const SingleActivator(LogicalKeyboardKey.keyD, control: true): () {
        var range = selection;
        if (selection.isCollapsed) return;
        if (range.baseOffset > range.extentOffset) {
          range = TextSelection(baseOffset: range.extentOffset, extentOffset: range.baseOffset);
        }

        var annotations = annotationsForRange(range);
        var already = annotations!.every((a) => a.strikethrough == true);
        markRange(range, Annotation(strikethrough: !already));
        refresh();
      },
      const SingleActivator(LogicalKeyboardKey.keyU, control: true): () {
        var range = selection;
        if (selection.isCollapsed) return;
        if (range.baseOffset > range.extentOffset) {
          range = TextSelection(baseOffset: range.extentOffset, extentOffset: range.baseOffset);
        }

        var annotations = annotationsForRange(range);
        var already = annotations!.every((a) => a.underline == true);
        markRange(range, Annotation(underline: !already));
        refresh();
      },
    };
  }

  Widget Function(BuildContext, EditableTextState)? getContextMenuBuilder() {
    return (BuildContext context, EditableTextState editableTextState) {
      var range = editableTextState.textEditingValue.selection;
      if (range.baseOffset > range.extentOffset) {
        range = TextSelection(baseOffset: range.extentOffset, extentOffset: range.baseOffset);
      }
      var annotations = annotationsForRange(range);
      var mention = annotations?.firstWhereOrNull((r) => r.mentionedAddress != null);

      return AdaptiveTextSelectionToolbar.editableText(
        editableTextState: editableTextState
      )..buttonItems?.addAllIf(
          mention != null,
          [
            ContextMenuButtonItem(
              onPressed: () {
                insert(TextSelection(baseOffset: mention!.range[0], extentOffset: mention.range[1]), 
                  "@${mentionCache[mention.mentionedAddress!]}", moveCursor: 1);

                editableTextState.hideToolbar();
              },
              label: "Remove Mention",
            ),
            ContextMenuButtonItem(
              onPressed: () async {
                // if (kIsDesktop || kIsWeb) {
                //   controller?.showingOverlays = true;
                // }
                final changed = await showCustomMentionDialog(context, mentionCache[mention!.mentionedAddress!]);
                // if (kIsDesktop || kIsWeb) {
                //   controller?.showingOverlays = false;
                // }
                if (!isNullOrEmpty(changed)) {
                  mentionCache[mention.mentionedAddress!] = changed!;
                }

                editableTextState.hideToolbar();
                
              },
              label: "Custom Mention",
            ),
          ],
        )..buttonItems?.addAll([
          ContextMenuButtonItem(
            onPressed: () {
              var already = annotations!.every((a) => a.bold == true);
              markRange(range, Annotation(bold: !already));
              editableTextState.hideToolbar();
              refresh();
            },
            label: "Bold",
          ),
          ContextMenuButtonItem(
            onPressed: () {
              var already = annotations!.every((a) => a.italic == true);
              markRange(range, Annotation(italic: !already));
              editableTextState.hideToolbar();
              refresh();
            },
            label: "Italic",
          ),
          ContextMenuButtonItem(
            onPressed: () {
              var already = annotations!.every((a) => a.strikethrough == true);
              markRange(range, Annotation(strikethrough: !already));
              editableTextState.hideToolbar();
              refresh();
            },
            label: "Strikethrough",
          ),
          ContextMenuButtonItem(
            onPressed: () {
              var already = annotations!.every((a) => a.underline == true);
              markRange(range, Annotation(underline: !already));
              editableTextState.hideToolbar();
              refresh();
            },
            label: "Underline",
          ),
          ContextMenuButtonItem(
            onPressed: () {
              var already = annotations!.every((a) => a.textEffect == Attributes.BIG);
              markRange(range, Annotation(textEffect: already ? null : Attributes.BIG));
              editableTextState.hideToolbar();
              refresh();
            },
            label: "Big",
          ),
          ContextMenuButtonItem(
            onPressed: () {
              var already = annotations!.every((a) => a.textEffect == Attributes.SMALL);
              markRange(range, Annotation(textEffect: already ? null : Attributes.SMALL));
              editableTextState.hideToolbar();
              refresh();
            },
            label: "Small",
          ),
        ]);
    };
  }

  @override
  TextSpan buildTextSpan({
    required BuildContext context,
    TextStyle? style,
    required bool withComposing,
  }) {
    return TextSpan(
      children: annotations.mapIndexed((idx, annotation) {
        // uncomment top variant for annotation debugging (give each annotation a unique color)
        // var s = style!.copyWith(color: Color((0xff << 0x18) | (annotation.hashCode & 0xffffff)));
        var s = style!;

        if (annotation.bold ?? false) s = s.apply(fontWeightDelta: 2);
        if (annotation.italic ?? false) s = s.apply(fontStyle: FontStyle.italic);
        s = s.apply(decoration: TextDecoration.combine([
          if (annotation.strikethrough ?? false) TextDecoration.lineThrough,
          if (annotation.underline ?? false) TextDecoration.underline,
        ]));
        if (annotation.textEffect == Attributes.BIG) s = s.apply(fontSizeDelta: 4);
        if (annotation.textEffect == Attributes.SMALL) s = s.apply(fontSizeDelta: -2);

        if (annotation.mentionedAddress != null) {
          // Mandatory WidgetSpan so that it takes the appropriate char number.
          return WidgetSpan(
            child: Listener(
              onPointerDown: (PointerDownEvent e) {
                if (selection.isCollapsed && e.buttons == 2) {
                  // Right click
                  selection = TextSelection(baseOffset: annotation.range[0], extentOffset: annotation.range[1]);
                }
              },
              child: ShaderMask(
                blendMode: BlendMode.srcIn,
                shaderCallback: (bounds) =>
                    LinearGradient(
                      colors: <Color>[
                        context.theme.colorScheme.primary.darkenPercent(20),
                        context.theme.colorScheme.primary.lightenPercent(20)
                      ],
                    ).createShader(
                      Rect.fromLTWH(0, 0, bounds.width, bounds.height),
                    ),
                child: Text(
                  mentionCache[annotation.mentionedAddress!]!,
                  style: s.copyWith(fontWeight: FontWeight.bold).apply(heightFactor: 1.1),
                ),
              ),
            ),
          );
        }

        // Anything beyond this point is not a mention. So fallback to original style.
        return buildMistakeTextSpans(
          context: context,
          chunk: text.substring(annotation.range[0], annotation.range[1]),
          offset: annotation.range[0],
          style: s,
        );
      }).toList(),
    );
  }
}
