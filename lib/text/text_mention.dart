part of 'mention_text_editing_controller.dart';

/// Local-only class to store mentions currently stored in the string visible to the user
class _TextMention {
  _TextMention({
    required this.id,
    required this.display,
    required this.start,
    required this.end,
    required this.syntax,
  });

  final String id;
  final String display;
  final MentionSyntax syntax;
  int start;
  int end;
}