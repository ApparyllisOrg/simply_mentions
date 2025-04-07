import 'package:diacritic/diacritic.dart';
import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:flutter_portal/flutter_portal.dart';
import 'package:mock_data/mock_data.dart';
import 'package:simply_mentions/text/mention_text_editing_controller.dart';
import 'package:simply_mentions_example/types/mentions.dart';

/// For the sake of ease of understanding, any possible data is called
/// a document (a user, a channel, etc.)
final documentMentions = <MentionObject>[
  /// Insert a default mention to have data for setMarkupText example
  const MentionObject(
    id: "ExampleId",
    displayName: "Jane Doe",
    avatarUrl: "https://placekitten.com/50/50",
  ),

  /// Generate 100 random mentions
  for (int i = 0; i < 100; ++i)
    MentionObject(
      id: mockUUID(),
      displayName: "${mockName()} ${mockName()}",
      avatarUrl: "https://placekitten.com/50/50",
    ),
];

void main() {
  runApp(const SimplyMentionsExample());
}

class SimplyMentionsExample extends StatelessWidget {
  const SimplyMentionsExample({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Simply Mentions Example',
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color.fromARGB(255, 114, 67, 67),
          brightness: Brightness.light,
        ),
      ),
      darkTheme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color.fromARGB(255, 114, 67, 67),
          brightness: Brightness.dark,
        ),
      ),
      // Theme mode system by default
      // themeMode: ThemeMode.system,
      home: const ExamplePage(),
    );
  }
}

class ExamplePage extends StatefulWidget {
  const ExamplePage({super.key});

  @override
  State<ExamplePage> createState() => _ExamplePageState();
}

class _ExamplePageState extends State<ExamplePage> {
  final _focusNode = FocusNode();
  final _scrollController = ScrollController();
  MentionTextEditingController? _mentionTextEditingController;

  /// didChangeDependencies and not initState because we need to access context
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    final theme = Theme.of(context);

    if (_mentionTextEditingController == null) {
      // Create a mention text editing controller and pass
      // in the relevant syntax, then bind to
      // the [MentionTextEditingController.onSuggestionChanged].
      _mentionTextEditingController = MentionTextEditingController(
        mentionSyntaxes: [DocumentMentionEditableSyntax()],
        // mentionBgColor: theme.colorScheme.primary,
        // mentionTextColor: theme.colorScheme.onPrimary,

        /// Pass fixed text style
        // runTextStyle: const TextStyle(color: Colors.white),

        /// Pass fixed text style
        mentionTextStyle: TextStyle(
          backgroundColor: theme.colorScheme.primary,
          color: theme.colorScheme.onPrimary,
        ),
        onSuggestionChanged: onSuggestionChanged,
        idToMentionObject: (context, id) async => documentMentions.firstWhere(
          (element) => element.id == id,
        ),
      );

      // Set markup text, any text that is the raw text that will be saved
      _mentionTextEditingController!.setMarkupText(
        context,
        'Hello <###@ExampleId###>, how are you doing?',
      );

      _mentionTextEditingController!.addListener(() {
        setState(() {});
      });
    }

    _focusNode.requestFocus();
  }

  void onSuggestionChanged(MentionSuggestion suggestion) {
    setState(() {});
  }

  /// When a mention is selected, insert the mention into
  /// the [TextEditingController]. This will insert a mention in the current
  /// mentioning text, will assert if not currently mentioning.
  void onMentionSelected(MentionObject mention) {
    setState(() {
      _mentionTextEditingController!.insertMention(mention);
    });
  }

  /// Create any widget of your choosing to make a list of possible mentions
  /// using the search string
  Widget getMentions() {
    if (!_mentionTextEditingController!.isMentioning()) {
      return const SizedBox.shrink();
    }

    final possibleMentions = <Widget>[];

    /// Remove diacritics and lowercase the search string so matches
    /// are easier found
    final safeSearch = removeDiacritics(
      _mentionTextEditingController!.getSearchText(),
    );

    for (var mention in documentMentions) {
      final safeName = removeDiacritics(mention.displayName.toLowerCase());

      if (safeName.contains(safeSearch)) {
        possibleMentions.add(
          Padding(
            padding: const EdgeInsets.only(bottom: 5),
            child: Ink(
              child: InkWell(
                // Tell the mention controller to insert the mention
                onTap: () => onMentionSelected(mention),
                splashColor: Theme.of(context).highlightColor,
                child: Row(
                  children: [
                    if (mention.avatarUrl != null)
                      Image.network(
                        mention.avatarUrl!,
                        width: 25,
                        height: 25,
                      ),
                    const SizedBox(width: 6),
                    Text(mention.displayName),
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
            controller: _scrollController,
            child: ListView.separated(
              controller: _scrollController,
              shrinkWrap: true,
              padding: const EdgeInsets.all(8.0),
              itemCount: possibleMentions.length,
              separatorBuilder: (context, __) => const Divider(),
              itemBuilder: (context, index) => possibleMentions[index],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Create a Portal at the top of your widget/page, can be done at the root
    // of your app as well
    return Portal(
      child: Material(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 300),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text("Enter your text"),
                const SizedBox(height: 6),
                // Create a portal target where the mentions list should
                // show up with an alignment of your choosing
                PortalTarget(
                  visible: _mentionTextEditingController!.isMentioning(),
                  portalFollower: getMentions(),
                  anchor: const Aligned(
                    follower: Alignment.bottomLeft,
                    target: Alignment.topLeft,
                    widthFactor: 1,
                    backup: Aligned(
                      follower: Alignment.bottomLeft,
                      target: Alignment.topLeft,
                      widthFactor: 1,
                    ),
                  ),
                  child: TextField(
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                    ),
                    focusNode: _focusNode,
                    maxLines: null,
                    minLines: 5,
                    controller: _mentionTextEditingController,
                  ),
                ),
                const SizedBox(height: 20),
                const Text("Resulting markdown"),
                const SizedBox(height: 20),
                // Pass the inline syntaxes of your choosing and a builder
                // for the corresponding syntax.
                MarkdownBody(
                  data: _mentionTextEditingController!.getMarkupText(),
                  softLineBreak: true,
                  builders: {
                    'docMention': DocumentMentionBuilder(
                      (pressedMentionId) {
                        // Do what you want to do when you pressed on a member
                      },
                    )
                  },
                  inlineSyntaxes: [DocumentMention()],
                )
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _focusNode.dispose();
    _scrollController.dispose();

    super.dispose();
  }
}
