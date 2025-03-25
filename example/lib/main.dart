import 'package:diacritic/diacritic.dart';
import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:flutter_portal/flutter_portal.dart';
import 'package:mock_data/mock_data.dart';
import 'package:simply_mentions/text/mention_text_editing_controller.dart';
import 'package:simply_mentions_example/types/mentions.dart';

// For the sake of ease of understanding, any possible data is called a document (a user, a channel, etc.)
final List<MentionObject> documentMentions = [];

void main() {
  // Insert a default mention to have data for setMarkupText example
  documentMentions.add(
    MentionObject(
      id: 'ExampleId',
      displayName: 'Jane Doe',
      avatarUrl: 'https://placekitten.com/50/50',
    ),
  );

  // Generate 100 random mentions
  for (int i = 0; i < 100; ++i) {
    documentMentions.add(
      MentionObject(
        id: mockUUID(),
        displayName: '${mockName()} ${mockName()}',
        avatarUrl: 'https://placekitten.com/50/50',
      ),
    );
  }
  runApp(const SimplyMentionsExample());
}

class SimplyMentionsExample extends StatelessWidget {
  const SimplyMentionsExample({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Simply Mentions Example',
      theme: ThemeData.light(useMaterial3: true),
      darkTheme: ThemeData.dark(useMaterial3: true),
      home: const Example(),
    );
  }
}

class Example extends StatefulWidget {
  const Example({super.key});

  @override
  State<Example> createState() => _ExampleState();
}

class _ExampleState extends State<Example> {
  final focusNode = FocusNode();
  final controller = ScrollController();
  late final MentionTextEditingController mentionTextEditingController;
  bool _isInitialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    if (!_isInitialized) {
      final theme = Theme.of(context);
      _isInitialized = true;
      // Create a mention text editing controller and pass in the relevant syntax, then bind to onSuggestionChanged
      mentionTextEditingController = MentionTextEditingController(
        mentionSyntaxes: [DocumentMentionEditableSyntax()],
        mentionTextStyle: TextStyle(
          backgroundColor: theme.colorScheme.primary,
          color: theme.colorScheme.onPrimary,
        ),
        onSuggestionChanged: onSuggestionChanged,
        idToMentionObject: (context, id) => documentMentions.firstWhere(
          (element) => element.id == id,
        ),
      )
        ..setMarkupText(
          context,
          'Hello <###@ExampleId###>, how are you doing?',
        )
        ..addListener(() {
          setState(() {});
        });
    }

    focusNode.requestFocus();
  }

  void onSuggestionChanged(MentionSyntax? syntax, String? fullSearchString) {
    setState(() {});
  }

  // When a mention is selected, insert the mention into the text editing controller.
  // This will insert a mention in the current mentioning text, will assert if not currently mentioning
  void onMentionSelected(MentionObject mention) {
    setState(() => mentionTextEditingController.insertMention(mention));
  }

  // Create any widget of your choosing to make a list of possible mentions using the search string
  Widget getMentions() {
    if (!mentionTextEditingController.isMentioning()) {
      return SizedBox();
    }

    final possibleMentions = <Widget>[];

    // Remove diacritics and lowercase the search string so matches are easier found
    final safeSearch = removeDiacritics(
      mentionTextEditingController.getSearchText(),
    );

    for (final element in documentMentions) {
      final safeName = removeDiacritics(element.displayName.toLowerCase());

      if (safeName.contains(safeSearch)) {
        possibleMentions.add(
          Padding(
            padding: EdgeInsets.only(bottom: 5),
            child: Ink(
              child: InkWell(
                // Tell the mention controller to insert the mention
                onTap: () => onMentionSelected(element),
                splashColor: Theme.of(context).highlightColor,
                child: Row(
                  children: [
                    if (element.avatarUrl != null)
                      Image.network(
                        element.avatarUrl!,
                        width: 25,
                        height: 25,
                      ),
                    SizedBox(width: 6),
                    Text(element.displayName),
                  ],
                ),
              ),
            ),
          ),
        );
      }
    }

    return Material(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxHeight: 400),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: const Color.fromARGB(255, 99, 94, 94),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Scrollbar(
            controller: controller,
            child: ListView.separated(
              controller: controller,
              shrinkWrap: true,
              padding: const EdgeInsets.all(8.0),
              itemCount: possibleMentions.length,
              separatorBuilder: (context, _) => const Divider(),
              itemBuilder: (context, index) => possibleMentions[index],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Create a Portal at the top of your widget/page, can be done at
    // the root of your app as well
    return Portal(
      child: Material(
        child: Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: 300),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Enter your text'),
                SizedBox(height: 8),
                // Create a portal target where the mentions list should show
                // up with an alignment of your choosing
                PortalTarget(
                  visible: mentionTextEditingController.isMentioning(),
                  portalFollower: getMentions(),
                  anchor: Aligned(
                    follower: Alignment.bottomLeft,
                    target: Alignment.topLeft,
                    widthFactor: 1,
                    backup: const Aligned(
                      follower: Alignment.bottomLeft,
                      target: Alignment.topLeft,
                      widthFactor: 1,
                    ),
                  ),
                  child: TextField(
                    decoration: InputDecoration(
                      border: OutlineInputBorder(),
                    ),
                    focusNode: focusNode,
                    maxLines: null,
                    minLines: 5,
                    controller: mentionTextEditingController,
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                ),
                SizedBox(height: 20),
                Text('Resulting markdown'),
                SizedBox(height: 20),
                // Pass the inline syntaxes of your choosing and a builder
                // for the corresponding syntax.
                MarkdownBody(
                  data: mentionTextEditingController.getMarkupText(),
                  softLineBreak: true,
                  builders: {
                    'docMention': DocumentMentionBuilder(
                      context,
                      (pressedMentionId) {
                        // .. Do what you want to do when you pressed on a member
                      },
                    ),
                  },
                  inlineSyntaxes: [DocumentMention()],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
