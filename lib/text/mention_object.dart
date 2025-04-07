part of 'mention_text_editing_controller.dart';

/// Mention object that store the id, display name and avatar url
/// of the mention. You can inherit from this to add your own custom data,
/// should you need to
class MentionObject {
  const MentionObject({
    required this.id,
    required this.displayName,
    this.avatarUrl,
  });

  /// id of the mention, should match ^([a-zA-Z0-9]){1,}$
  final String id;

  /// display name of the mention
  final String displayName;

  /// avatar url of the mention
  final String? avatarUrl;
}
