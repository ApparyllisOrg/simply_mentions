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
  documentMentions.add(MentionObject(
      id: "ExampleId",
      displayName: "Jane Doe",
      avatarUrl: "https://placekitten.com/50/50"));

  // Generate 100 random mentions
  for (int i = 0; i < 100; ++i) {
    documentMentions.add(MentionObject(
        id: mockUUID(),
        displayName: "${mockName()} ${mockName()}",
        avatarUrl: "https://placekitten.com/50/50"));
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
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
            seedColor: Color.fromARGB(255, 114, 67, 67),
            brightness: Brightness.dark),
        useMaterial3: true,
      ),
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
  MentionTextEditingController? mentionTextEditingController;
  FocusNode focusNode = FocusNode();

  // didChangeDependencies and not initState because we need to access context
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    if (mentionTextEditingController == null) {
      // Create a mention text editing controller and pass in the relevant syntax, then bind to onSuggestionChanged
      mentionTextEditingController = MentionTextEditingController(
          mentionSyntaxes: [DocumentMentionEditableSyntax(context)],
          mentionBgColor: Theme.of(context).colorScheme.primary,
          mentionTextColor: Theme.of(context).colorScheme.onPrimary,
          mentionTextStyle: TextStyle(),
          onSugggestionChanged: onSuggestionChanged,
          idToMentionObject: (BuildContext context, String id) =>
              documentMentions.firstWhere((element) => element.id == id));

      // Set markup text, any text that is the raw text that will be saved
      mentionTextEditingController!.setMarkupText(
          context, "Hello <###@ExampleId###>, how are you doing?");

      mentionTextEditingController!.addListener(() {
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
    setState(() {
      mentionTextEditingController!.insertMention(mention);
    });
  }

  // Create any widget of your choosing to make a list of possible mentions using the search string
  Widget getMentions() {
    if (mentionTextEditingController!.isMentioning()) {
      return SizedBox.shrink();
    }

    List<Widget> possibleMentions = [];

    // Remove diacritics and lowercase the search string so matches are easier found
    String safeSearch =
        removeDiacritics(mentionTextEditingController!.getSearchText());

    documentMentions.forEach((element) {
      String safeName = removeDiacritics(element.displayName.toLowerCase());

      if (safeName.contains(safeSearch)) {
        possibleMentions.add(Padding(
            padding: EdgeInsets.only(bottom: 5),
            child: Ink(
              child: InkWell(
                onTap: () {
                  // Tell the mention controller to insert the mention
                  onMentionSelected(element);
                },
                splashColor: Theme.of(context).highlightColor,
                child: Row(children: [
                  Image.network(
                    element.avatarUrl,
                    width: 25,
                    height: 25,
                  ),
                  SizedBox(
                    width: 6,
                  ),
                  Text(element.displayName)
                ]),
              ),
            )));
      }
    });

    ScrollController controller = ScrollController();

    return Material(
        child: ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 400),
            child: Container(
                decoration: BoxDecoration(
                    color: const Color.fromARGB(255, 99, 94, 94),
                    borderRadius: BorderRadius.circular(10)),
                child: Scrollbar(
                    controller: controller,
                    child: ListView.separated(
                      controller: controller,
                      shrinkWrap: true,
                      padding: const EdgeInsets.all(8.0),
                      itemCount: possibleMentions.length,
                      separatorBuilder: (context, i) {
                        return const Divider();
                      },
                      itemBuilder: (BuildContext context, int index) {
                        return possibleMentions[index];
                      },
                    )))));
  }

  @override
  Widget build(BuildContext context) {
    // Create a Portal at the top of your widget/page, can be done at the root of your app as well
    return Portal(
      child: Material(
          child: Center(
              child: ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: 300),
                  child: Column(mainAxisSize: MainAxisSize.min, children: [
                    Text("Enter your text"),
                    SizedBox(
                      height: 6,
                    ),
                    // Create a portal target where the mentions list should show up with an alignement of your choosing
                    PortalTarget(
                        visible: mentionTextEditingController!.isMentioning(),
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
                          decoration:
                              InputDecoration(border: OutlineInputBorder()),
                          focusNode: focusNode,
                          maxLines: null,
                          minLines: 5,
                          controller: mentionTextEditingController,
                        )),
                    SizedBox(
                      height: 20,
                    ),
                    Text("Resulting markdown"),
                    SizedBox(
                      height: 20,
                    ),
                    // Pass the inline syntaxes of your choosing and a builder for the corresponding syntax.
                    MarkdownBody(
                      data: mentionTextEditingController!.getMarkupText(),
                      softLineBreak: true,
                      builders: {
                        'docMention': DocumentMentionBuilder(context: context,
                            (String pressedMentiondId) {
                          // .. Do what you want to do when you pressed on a member
                        })
                      },
                      inlineSyntaxes: [DocumentMention()],
                    )
                  ])))),
    );
  }
}
