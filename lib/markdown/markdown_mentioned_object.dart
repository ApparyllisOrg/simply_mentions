import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:markdown/markdown.dart' as md;

/// Builder declaration for mentions within markdown to provide any widget you see fit
/// Example:
/// final String id = element.children![0].textContent;
/// final String displayName = getDisplayNameForId(id);
/// GestureDetector(
/// onTap: () {
///   onPressed(id)
/// },
/// child: RichText(
///     text: TextSpan(children: [
///   WidgetSpan(
///       child: DecoratedBox(
///     decoration: BoxDecoration(color: Colors.blue, borderRadius: BorderRadius.circular(2)),
///     child: Text('@$displayName'),
///   ))
/// ])))
abstract class MarkdownMentionBuilder extends MarkdownElementBuilder {
  MarkdownMentionBuilder(this.onPressed);

  final void Function(String) onPressed;

  // Provide a more user-friendly override to create the widget
  Widget createWidget(md.Element element, TextStyle? preferredStyle);

  @override
  Widget visitElementAfter(md.Element element, TextStyle? preferredStyle) {
    return createWidget(element, preferredStyle);
  }
}

// Syntax declaration for mentions within markdown
class MarkdownMentionSyntax extends md.DelimiterSyntax {
  MarkdownMentionSyntax({this.tagName = 'mention', this.patternToUse = r'<@([a-zA-Z0-9]{1,})>', this.idRegexGroup = 1, super.startCharacter})
      : super(patternToUse);

  // Name of the tag to use for the element, used in conjuction with builders and MarkdownMentionBuilder
  final String tagName;

  // Pattern to use for the mention, typically r'<@([a-zA-Z0-9]{1,})>', however you can change the requirements if needed
  final String patternToUse;

  // Regex group the ID is located in
  final int idRegexGroup;

  @override
  bool onMatch(md.InlineParser parser, Match match) {
    parser.addNode(md.Element.text(tagName, match[1]!));
    return true;
  }
}
