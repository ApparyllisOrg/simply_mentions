import 'package:flutter/material.dart';
import 'package:markdown/markdown.dart' as md;
import 'package:simply_mentions/simply_mentions.dart';
import 'package:simply_mentions_example/main.dart';

// Define a new mention with an id that will be used for markdown
class DocumentMention extends MarkdownMentionSyntax {
  DocumentMention()
      : super(
            patternToUse: mentionPattern,
            tagName: 'docMention',
            idRegexGroup: 2,
            startCharacter: 0x3C);

  // Set the pattern, by default <###@USERID###>, however this can be anything.
  // Just make sure it's unlikely to show up in the text naturally.
  static const String mentionPattern = '<###@([a-zA-Z0-9-]{1,})###>';
}

// Create a syntax for the mention while editing text, regex should match the markdown regex or vice versa
class DocumentMentionEditableSyntax extends MentionSyntax {
  DocumentMentionEditableSyntax()
      : super(
          startingCharacter: '@',
          prefix: '<###',
          suffix: '###>',
          missingText: "Unknown document",
          pattern: "[a-zA-Z0-9-]{1,}",
        );
}

// Mention building for displaying in markdown
class DocumentMentionBuilder extends MarkdownMentionBuilder {
  DocumentMentionBuilder(super.onPressed);

  @override
  Widget createWidget(md.Element element, TextStyle? preferredStyle) {
    final mentionedId = element.children![0].textContent;

    final mentionIndex = documentMentions.indexWhere(
      (element) => element.id == mentionedId,
    );

    // If we don't find it, display the raw text
    if (mentionIndex == -1) {
      return RichText(text: TextSpan(text: mentionedId));
    }

    final name = documentMentions[mentionIndex].displayName;

    return Builder(
      builder: (context) {
        final theme = Theme.of(context);

        return RichText(
          text: TextSpan(
            children: [
              WidgetSpan(
                baseline: TextBaseline.alphabetic,
                alignment: PlaceholderAlignment.baseline,
                child: GestureDetector(
                  onTap: () {
                    // Do what you need to do using mentionedId
                  },
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary,
                      borderRadius: BorderRadius.circular(2),
                    ),
                    child: RichText(
                      text: TextSpan(
                        text: '@$name',
                        style: TextStyle(
                          color: theme.colorScheme.onPrimary,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      }
    );
  }
}
