import 'package:flutter/widgets.dart';
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

  /// Called when a mention is tapped.
  final void Function(String) onPressed;

  /// Provide a more user-friendly override to create the widget.
  Widget createWidget(md.Element element, TextStyle? preferredStyle);

  @override
  Widget visitElementAfter(md.Element element, TextStyle? preferredStyle) {
    return createWidget(element, preferredStyle);
  }
}
