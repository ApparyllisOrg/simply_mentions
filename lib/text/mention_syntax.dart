part of 'mention_text_editing_controller.dart';

/// Mention syntax for determining when to start mentioning and parsing
/// to and from markup text. Final markup text would be:
/// Prefix -> StartingCharacter -> Id of mention -> Suffix
class MentionSyntax {
  MentionSyntax({
    required this.startingCharacter,
    required this.missingText,
    this.prefix = '<###',
    this.suffix = '###>',
    this.pattern = '[a-zA-Z0-9]{1,}',
  }) {
    _mentionRegex = RegExp(
      '($prefix)($startingCharacter)($pattern)($suffix)',
    );
  }

  /// The character the regex pattern starts with, used to more performance
  /// find sections in the text, needs to be a single character
  final String startingCharacter;

  /// The prefix to add to the final markup text per mention of this type
  final String prefix;

  /// The suffix to add to the final markup text per mention of this type
  final String suffix;

  /// The display name to show when the mention with the specified id
  /// no longer exists
  final String missingText;

  /// The inner pattern that will be followed to find a mention
  final String pattern;

  late RegExp _mentionRegex;

  RegExp getRegExp() => _mentionRegex;
}
