import 'package:markdown/markdown.dart' as md;

/// Syntax declaration for mentions within markdown
class MarkdownMentionSyntax extends md.DelimiterSyntax {
  MarkdownMentionSyntax({
    this.tagName = 'mention',
    this.patternToUse = r'<@([a-zA-Z0-9]{1,})>',
    this.idRegexGroup = 1,
    super.startCharacter,
  }) : super(patternToUse);

  /// Name of the tag to use for the element, used in conjunction with builders
  /// and MarkdownMentionBuilder
  final String tagName;

  /// Pattern to use for the mention, typically r'<@([a-zA-Z0-9]{1,})>',
  /// however you can change the requirements if needed
  final String patternToUse;

  /// Regex group the ID is located in
  final int idRegexGroup;

  @override
  bool onMatch(md.InlineParser parser, Match match) {
    parser.addNode(md.Element.text(tagName, match[1]!));
    return true;
  }
}
