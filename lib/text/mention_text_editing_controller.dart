import 'dart:async';

import 'package:diff_match_patch/diff_match_patch.dart';
import 'package:flutter/material.dart';

// ignore_for_file: constant_identifier_names

// Mention object that store the id, display name and avatarurl of the mention
// You can inherit from this to add your own custom data, should you need to

// Keep in copy with diff.dart from diff_match_patch package

const DIFF_DELETE = 1;
const DIFF_INSERT = -1;
const DIFF_EQUAL = 0;

class MentionObject {
  MentionObject(
      {required this.id, required this.displayName, required this.avatarUrl});

  // id of the mention, should match ^([a-zA-Z0-9]){1,}$
  final String id;
  final String displayName;
  final String avatarUrl;
}

// Mention syntax for determining when to start mentioning and parsing to and from markup
// Final markup text would be Prefix -> StartingCharacter -> Id of mention -> Suffix
class MentionSyntax {
  MentionSyntax(
      {required this.startingCharacter,
      required this.missingText,
      this.prefix = '<###',
      this.suffix = '###>',
      this.pattern = "[a-zA-Z0-9]{1,}"}) {
    _mentionRegex = RegExp('($prefix)($startingCharacter)($pattern)($suffix)');
  }

  // The character the regex pattern starts with, used to more performantly find sections in the text, needs to be a single character
  final String startingCharacter;

  // The prefix to add to the final markup text per mention of this type
  final String prefix;

  // The suffix to add to the final markup text per mention of this type
  final String suffix;

  // The display name to show when the mention with the specified id no longer exists
  final String missingText;

  // The inner pattern that will be followed to find a mention
  final String pattern;

  late RegExp _mentionRegex;

  RegExp getRegExp() => _mentionRegex;
}

// Local-only class to store mentions currently stored in the string visible to the user
class _TextMention {
  _TextMention(
      {required this.id,
      required this.display,
      required this.start,
      required this.end,
      required this.syntax});

  final String id;
  final String display;
  final MentionSyntax syntax;
  int start;
  int end;
}

// Text editing controller that can parse mentions
class MentionTextEditingController extends TextEditingController {
  MentionTextEditingController({
    this.controllerToCopyTo,
    required this.mentionSyntaxes,
    this.onSugggestionChanged,
    required this.mentionBgColor,
    required this.mentionTextColor,
    required this.mentionTextStyle,
    required this.idToMentionObject,
    super.text,
  }) {
    _init();
  }

  // Unique mention syntaxes, all syntaxes should have a different starting character
  final List<MentionSyntax> mentionSyntaxes;

  // Delegate called when suggestion has changed
  Function(MentionSyntax? syntax, String?)? onSugggestionChanged;

  // Function to get a mention from an id, used to deconstruct markup on construct
  final MentionObject? Function(BuildContext, String) idToMentionObject;

  // Background color of the text for the mention
  final Color mentionBgColor;

  // Color of the text for the mention
  final Color mentionTextColor;

  // EditingController to copy our text to, used for things like the Autocorrect widget
  TextEditingController? controllerToCopyTo;

  final List<_TextMention> _cachedMentions = [];

  // Text style for the mention
  final TextStyle mentionTextStyle;

  String _previousText = '';

  int? _mentionStartingIndex;
  int? _mentionLength;
  MentionSyntax? _mentionSyntax;

  @override
  void dispose() {
    removeListener(_onTextChanged);

    super.dispose();
  }

  // Set markup text, this is used when you get data that has the mention syntax and you want to initialize the textfield with it.
  void setMarkupText(BuildContext context, String markupText) {
    String deconstructedText = '';

    int lastStartingRunStart = 0;

    _cachedMentions.clear();

    for (int i = 0; i < markupText.length; ++i) {
      final String character = markupText[i];

      for (final MentionSyntax syntax in mentionSyntaxes) {
        if (character == syntax.prefix[0]) {
          final String subStr = markupText.substring(i, markupText.length);
          final RegExpMatch? match = syntax.getRegExp().firstMatch(subStr);
          if (match != null) {
            deconstructedText += markupText.substring(lastStartingRunStart, i);

            final String matchedMarkup =
                match.input.substring(match.start, match.end);
            final String mentionId = match[3]!;
            final MentionObject? mention =
                idToMentionObject(context, mentionId);

            final String mentionDisplayName =
                mention?.displayName ?? syntax.missingText;

            final String insertText =
                '${syntax.startingCharacter}$mentionDisplayName';

            final int indexToInsertMention = deconstructedText.length;
            final int indexToEndInsertion =
                indexToInsertMention + insertText.length;

            _cachedMentions.add(_TextMention(
                id: mentionId,
                display: insertText,
                start: indexToInsertMention,
                end: indexToEndInsertion,
                syntax: syntax));

            deconstructedText += insertText;
            lastStartingRunStart = i + matchedMarkup.length;
          }
        }
      }
    }

    if (lastStartingRunStart != markupText.length) {
      deconstructedText +=
          markupText.substring(lastStartingRunStart, markupText.length);
    }

    _previousText = deconstructedText;
    text = deconstructedText;
  }

  TextSpan _createSpanForNonMatchingRange(
      int start, int end, BuildContext context) {
    return TextSpan(text: text.substring(start, end));
  }

  // Get the current search string for the mention (this is the mention minus the starting character. i.e. @Amber -> Amber)
  String getSearchText() {
    if (isMentioning()) {
      return text.substring(
          _mentionStartingIndex! + 1, _mentionStartingIndex! + _mentionLength!);
    }

    return '';
  }

  // Get the current search syntax for the current mention. This is useful when you have multiple syntaxes
  MentionSyntax? getSearchSyntax() {
    return _mentionSyntax;
  }

  // Get the text in the format that is readable by syntaxes. This will contain all text + syntax mentions (i.e. <###@USERID###>)
  String getMarkupText() {
    String finalString = '';
    int lastStartingRunStart = 0;

    for (int i = 0; i < _cachedMentions.length; ++i) {
      final _TextMention mention = _cachedMentions[i];

      final int indexToEndRegular = mention.start;

      if (indexToEndRegular != lastStartingRunStart) {
        finalString += text.substring(lastStartingRunStart, indexToEndRegular);
      }

      final String markupString =
          '${mention.syntax.prefix}${mention.syntax.startingCharacter}${mention.id}${mention.syntax.suffix}';

      finalString += markupString;

      lastStartingRunStart = mention.end;
    }

    if (lastStartingRunStart < text.length) {
      finalString += text.substring(lastStartingRunStart, text.length);
    }

    return finalString;
  }

  @override
  TextSpan buildTextSpan({
    required BuildContext context,
    TextStyle? style,
    required bool withComposing,
  }) {
    final List<InlineSpan> inlineSpans = [];
    int lastStartingRunStart = 0;

    for (int i = 0; i < _cachedMentions.length; ++i) {
      final _TextMention mention = _cachedMentions[i];

      final int indexToEndRegular = mention.start;

      if (indexToEndRegular != lastStartingRunStart) {
        inlineSpans.add(_createSpanForNonMatchingRange(
            lastStartingRunStart, indexToEndRegular, context));
      }

      inlineSpans.add(TextSpan(
          text: text.substring(mention.start, mention.end),
          style: mentionTextStyle.copyWith(
              backgroundColor: mentionBgColor, color: mentionTextColor)));

      lastStartingRunStart = mention.end;
    }

    if (lastStartingRunStart < text.length) {
      inlineSpans.add(_createSpanForNonMatchingRange(
          lastStartingRunStart, text.length, context));
    }

    return TextSpan(children: inlineSpans);
  }

  void _init() {
    addListener(_onTextChanged);
    if (text.isNotEmpty) {
      _onTextChanged();
    }
  }

  Future<void> _onTextChanged() async {
    if (_previousText == text) {
      return;
    }

    _processTextChange();

    _previousText = text;

    if (controllerToCopyTo != null) {
      controllerToCopyTo!.text = text;
    }
  }

  bool bGuardDeletion = false;

  // Insert a mention in the currently mentioning position
  void insertMention(MentionObject mention) {
    assert(isMentioning());

    final int mentionVisibleTextEnd =
        _mentionStartingIndex! + mention.displayName.length + 1;

    _cachedMentions.add(_TextMention(
        id: mention.id,
        display: mention.displayName,
        start: _mentionStartingIndex!,
        end: mentionVisibleTextEnd,
        syntax: _mentionSyntax!));

    final int mentionStart = _mentionStartingIndex!;
    final int mentionEnd = _mentionStartingIndex! + _mentionLength!;
    final String startChar = _mentionSyntax!.startingCharacter;

    cancelMentioning();

    bGuardDeletion = true;
    text = text.replaceRange(
        mentionStart, mentionEnd, '$startChar${mention.displayName}');
    bGuardDeletion = false;

    selection = TextSelection.collapsed(
        offset: mentionVisibleTextEnd, affinity: TextAffinity.upstream);

    _sortMentions();
  }

  // Check if we are currently mentioning
  bool isMentioning() =>
      _mentionStartingIndex != null &&
      _mentionLength != null &&
      _mentionSyntax != null;

  void _sortMentions() {
    _cachedMentions.sort((_TextMention a, _TextMention b) {
      return a.start - b.start;
    });
  }

  // Cancel mentioning
  void cancelMentioning() {
    _mentionStartingIndex = null;
    _mentionLength = null;
    _mentionSyntax = null;

    if (onSugggestionChanged != null) {
      onSugggestionChanged!(null, null);
    }
  }

  void _processTextChange() {
    List<Diff> differences = diff(text, _previousText);

    int currentTextIndex = 0;

    for (int i = 0; i < differences.length; ++i) {
      Diff difference = differences[i];

      if (difference.operation == DIFF_INSERT) {
        if (isMentioning()) {
          // Spaces are considered breakers for mentioning
          if (difference.text == " ") {
            cancelMentioning();
          } else {
            if (currentTextIndex <= _mentionStartingIndex! + _mentionLength! &&
                currentTextIndex >= _mentionStartingIndex! + _mentionLength!) {
              _mentionLength = _mentionLength! + difference.text.length;
              if (onSugggestionChanged != null) {
                onSugggestionChanged!(
                    _mentionSyntax!,
                    text.substring(_mentionStartingIndex!,
                        _mentionStartingIndex! + _mentionLength!));
              }
            } else {
              cancelMentioning();
            }
          }
        } else {
          for (int i = 0; i < mentionSyntaxes.length; ++i) {
            final MentionSyntax syntax = mentionSyntaxes[i];
            if (difference.text == syntax.startingCharacter) {
              _mentionStartingIndex = currentTextIndex;
              _mentionLength = 1;
              _mentionSyntax = syntax;
              break;
            }
          }
        }
      }

      if (difference.operation == DIFF_DELETE) {
        if (isMentioning()) {
          // If we removed our startingCharacter, chancel mentioning
          if (difference.text == _mentionSyntax!.startingCharacter) {
            cancelMentioning();
          } else {
            if (currentTextIndex < _mentionStartingIndex!) {
              continue;
            }

            if (currentTextIndex > _mentionStartingIndex! + _mentionLength!) {
              continue;
            }

            _mentionLength = _mentionLength! - difference.text.length;
            assert(_mentionLength! >= 0);

            // If we no longer have text after our mention sign then hide suggestions until we start typing again
            if (_mentionLength == 1) {
              if (onSugggestionChanged != null) {
                onSugggestionChanged!(null, null);
              }
            } else {
              if (onSugggestionChanged != null) {
                onSugggestionChanged!(
                    _mentionSyntax!,
                    text.substring(_mentionStartingIndex!,
                        _mentionStartingIndex! + _mentionLength!));
              }
            }
          }
        }
      }

      int rangeStart = currentTextIndex;
      int rangeEnd = currentTextIndex + difference.text.length;

      // If we insert a character in a position then it should end the range on the last character, not after the last character
      if (difference.operation != DIFF_DELETE) {
        rangeEnd -= 1;
      }

      for (int x = _cachedMentions.length - 1; x >= 0; --x) {
        final _TextMention mention = _cachedMentions[x];

        // Check for overlaps
        if (!bGuardDeletion) {
          if (difference.operation != DIFF_EQUAL) {
            if (rangeStart < mention.end && rangeEnd > mention.start) {
              _cachedMentions.removeAt(x);
              continue;
            }
          }
        }

        // Not overlapping but we inserted text in front of metions so we need to shift them
        if (mention.start >= currentTextIndex &&
            difference.operation == DIFF_INSERT) {
          mention.start += difference.text.length;
          mention.end += difference.text.length;
        }
        // Not overlapping but we removed text in front of metions so we need to shift them
        if (mention.start >= currentTextIndex &&
            difference.operation == DIFF_DELETE) {
          mention.start -= difference.text.length;
          mention.end -= difference.text.length;
        }
      }

      if (difference.operation == DIFF_EQUAL) {
        currentTextIndex += difference.text.length;
      }

      if (difference.operation == DIFF_INSERT) {
        currentTextIndex += difference.text.length;
      }

      if (difference.operation == DIFF_DELETE) {
        currentTextIndex -= difference.text.length;
      }
    }
  }
}
