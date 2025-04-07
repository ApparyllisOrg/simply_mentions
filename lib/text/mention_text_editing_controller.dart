// ignore_for_file: constant_identifier_names
import 'dart:async';

import 'package:diff_match_patch/diff_match_patch.dart';
import 'package:flutter/material.dart';

part 'mention_object.dart';
part 'mention_syntax.dart';
part 'mention_suggestion.dart';
part 'text_mention.dart';

// Keep in copy with diff.dart from diff_match_patch package
const DIFF_DELETE = 1;
const DIFF_INSERT = -1;
const DIFF_EQUAL = 0;

/// Typedef for suggestion callback.
typedef SuggestionCallback = void Function(MentionSuggestion suggestion);

/// Typedef for id to mention callback.
typedef IdToMentionCallback = Future<MentionObject?> Function(
  BuildContext context,
  String mentionId,
);

/// Text editing controller that can parse mentions
class MentionTextEditingController extends TextEditingController {
  MentionTextEditingController({
    this.controllerToCopyTo,
    required this.mentionSyntaxes,
    SuggestionCallback? onSuggestionChanged,
    this.mentionBgColor,
    this.mentionTextColor,
    this.mentionTextStyle,
    this.runTextStyle,
    required this.idToMentionObject,
    super.text,
  }) {
    _init();

    if (onSuggestionChanged != null) {
      addSuggestionListener(onSuggestionChanged);
    }
  }

  /// Unique mention syntaxes, all syntaxes should have a different
  /// starting character
  final List<MentionSyntax> mentionSyntaxes;

  /// Function to get a mention from an id, used to deconstruct markup
  /// on construct
  final IdToMentionCallback idToMentionObject;

  /// Background color of the text for the mention
  final Color? mentionBgColor;

  /// Color of the text for the mention
  final Color? mentionTextColor;

  /// EditingController to copy our text to, used for things like
  /// the Autocorrect widget
  final TextEditingController? controllerToCopyTo;

  /// Text style for the mention
  final TextStyle? mentionTextStyle;

  /// Text style for normal non-mention text
  final TextStyle? runTextStyle;

  final _suggestionCallbacks = <SuggestionCallback>[];
  final _cachedMentions = <_TextMention>[];
  bool _bGuardDeletion = false;
  String _previousText = '';
  int? _mentionStartingIndex;
  int? _mentionLength;
  MentionSyntax? _mentionSyntax;

  @override
  void dispose() {
    removeListener(_onTextChanged);

    super.dispose();
  }

  /// Add a suggestion listener.
  void addSuggestionListener(SuggestionCallback callback) =>
      _suggestionCallbacks.add(callback);

  /// Remove a suggestion listener.
  void removeSuggestionListener(SuggestionCallback callback) =>
      _suggestionCallbacks.remove(callback);

  /// Set markup text, this is used when you get data that has the mention
  /// syntax and you want to initialize the [TextField] with it.
  Future<void> setMarkupText(BuildContext context, String markupText) async {
    _cachedMentions.clear();

    String deconstructedText = '';
    int lastStartingRunStart = 0;

    for (int i = 0; i < markupText.length; ++i) {
      final character = markupText[i];

      for (final MentionSyntax syntax in mentionSyntaxes) {
        if (character != syntax.prefix[0]) {
          continue;
        }

        final subStr = markupText.substring(i, markupText.length);
        final match = syntax.getRegExp().firstMatch(subStr);

        /// Ensure the match starts at the start of our substring
        if (match != null && match.start == 0) {
          deconstructedText += markupText.substring(lastStartingRunStart, i);

          final matchedMarkup = match.input.substring(match.start, match.end);
          final mentionId = match[3]!;
          final mention = await idToMentionObject(context, mentionId);

          final mentionDisplayName = mention?.displayName ?? syntax.missingText;

          final insertText = '${syntax.startingCharacter}$mentionDisplayName';

          final indexToInsertMention = deconstructedText.length;
          final indexToEndInsertion = indexToInsertMention + insertText.length;

          _cachedMentions.add(
            _TextMention(
              id: mentionId,
              display: insertText,
              start: indexToInsertMention,
              end: indexToEndInsertion,
              syntax: syntax,
            ),
          );

          deconstructedText += insertText;
          lastStartingRunStart = i + matchedMarkup.length;
        }
      }
    }

    if (lastStartingRunStart != markupText.length) {
      deconstructedText += markupText.substring(
        lastStartingRunStart,
        markupText.length,
      );
    }

    _previousText = deconstructedText;
    text = deconstructedText;
  }

  TextSpan _createSpanForNonMatchingRange({
    required TextStyle? style,
    required int start,
    required int end,
  }) {
    return TextSpan(
      text: text.substring(start, end),
      style: style?.merge(runTextStyle) ?? runTextStyle,
    );
  }

  /// Get the current search string for the mention (this is the mention minus
  /// the starting character. i.e. @Amber -> Amber)
  String getSearchText() {
    if (isMentioning()) {
      return text.substring(
        _mentionStartingIndex! + 1,
        _mentionStartingIndex! + _mentionLength!,
      );
    }

    return '';
  }

  /// Get the current search syntax for the current mention.
  /// This is useful when you have multiple syntaxes
  MentionSyntax? getSearchSyntax() => _mentionSyntax;

  /// Get the text in the format that is readable by syntaxes.
  /// This will contain all text + syntax mentions (i.e. <###@USERID###>)
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
    int lastStartingRunStart = 0;
    final inlineSpans = <InlineSpan>[];

    for (final mention in _cachedMentions) {
      final indexToEndRegular = mention.start;

      if (indexToEndRegular != lastStartingRunStart) {
        inlineSpans.add(
          _createSpanForNonMatchingRange(
            style: style,
            start: lastStartingRunStart,
            end: indexToEndRegular,
          ),
        );
      }

      inlineSpans.add(
        TextSpan(
          text: text.substring(mention.start, mention.end),
          style: (style?.merge(mentionTextStyle) ?? mentionTextStyle)?.copyWith(
            backgroundColor: mentionBgColor,
            color: mentionTextColor,
          ),
        ),
      );

      lastStartingRunStart = mention.end;
    }

    if (lastStartingRunStart < text.length) {
      inlineSpans.add(
        _createSpanForNonMatchingRange(
          style: style,
          start: lastStartingRunStart,
          end: text.length,
        ),
      );
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

    controllerToCopyTo?.text = text;
  }

  /// Insert a mention in the currently mentioning position
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

    _bGuardDeletion = true;
    text = text.replaceRange(
        mentionStart, mentionEnd, '$startChar${mention.displayName}');
    _bGuardDeletion = false;

    selection = TextSelection.collapsed(
        offset: mentionVisibleTextEnd, affinity: TextAffinity.upstream);

    _sortMentions();
  }

  /// Check if we are currently mentioning
  bool isMentioning() =>
      _mentionStartingIndex != null &&
      _mentionLength != null &&
      _mentionSyntax != null;

  void _sortMentions() {
    _cachedMentions.sort((_TextMention a, _TextMention b) {
      return a.start - b.start;
    });
  }

  /// Cancel mentioning
  void cancelMentioning() {
    _mentionStartingIndex = null;
    _mentionLength = null;
    _mentionSyntax = null;

    _notifySuggestionListeners(const MentionSuggestion());
  }

  void _notifySuggestionListeners(MentionSuggestion suggestion) {
    for (var e in _suggestionCallbacks) {
      e.call(suggestion);
    }
  }

  void _processTextChange() {
    final differences = diff(text, _previousText);
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

              _notifySuggestionListeners(
                MentionSuggestion(
                  syntax: _mentionSyntax!,
                  search: text.substring(
                    _mentionStartingIndex!,
                    _mentionStartingIndex! + _mentionLength!,
                  ),
                ),
              );
            } else {
              cancelMentioning();
            }
          }
        } else {
          for (int i = 0; i < mentionSyntaxes.length; ++i) {
            final syntax = mentionSyntaxes[i];
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
          // TODO: This detects if *ANY* character contains our mention character, which isn't ideal..
          // But I have not yet figured out how to get whether we are currently deleting our starting character..
          // We can, however, find out if we are deleting our starting character AFTER our mention start so that names with the starting character don't cancel mentioning when backspacing
          if (difference.text.contains(_mentionSyntax!.startingCharacter) &&
              currentTextIndex <= _mentionStartingIndex!) {
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

            // If we no longer have text after our mention sign then hide
            // suggestions until we start typing again
            if (_mentionLength == 1) {
              _notifySuggestionListeners(const MentionSuggestion());
            } else {
              _notifySuggestionListeners(
                MentionSuggestion(
                  syntax: _mentionSyntax!,
                  search: text.substring(
                    _mentionStartingIndex!,
                    _mentionStartingIndex! + _mentionLength!,
                  ),
                ),
              );
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

        // Not overlapping but we inserted text in front of mentions so we need to shift them
        if (mention.start >= currentTextIndex &&
            difference.operation == DIFF_INSERT) {
          mention.start += difference.text.length;
          mention.end += difference.text.length;
        }

        // Check for overlaps
        if (!_bGuardDeletion) {
          if (difference.operation != DIFF_EQUAL) {
            if (rangeStart < mention.end && rangeEnd > mention.start) {
              _cachedMentions.removeAt(x);
              continue;
            }
          }
        }

        // Not overlapping but we removed text in front of mentions so we need to shift them
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
