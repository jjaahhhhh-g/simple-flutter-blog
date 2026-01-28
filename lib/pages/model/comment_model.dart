class Comment {
  final String id;
  final String content;
  final String? imageUrl;
  final String userId;
  final String userName;
  final String? userAvatar;
  final String createdAt;

  Comment.fromMap(Map<String, dynamic> map)
      : id = map['id'],
        content = map['content'] ?? '',
        imageUrl = map['image_url'],
        userId = map['user_id'],
        userName = map['user_name'] ?? 'User',
        userAvatar = map['user_avatar'],
        createdAt = map['created_at'];
}