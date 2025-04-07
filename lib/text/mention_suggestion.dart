part of 'mention_text_editing_controller.dart';

/// Object that holds the syntax and search string for a suggestion.
class MentionSuggestion {
  const MentionSuggestion({
    this.syntax,
    this.search,
  });

  /// The syntax for the suggestion.
  final MentionSyntax? syntax;

  /// The search string for the suggestion.
  final String? search;
}
