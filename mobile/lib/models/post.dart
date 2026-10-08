class Post {
  final String id;
  final String channelId;
  final String channelName;
  final String authorId;
  final String authorDisplayName;
  final String content;
  final DateTime createdAt;

  Post({
    required this.id,
    required this.channelId,
    required this.channelName,
    required this.authorId,
    required this.authorDisplayName,
    required this.content,
    required this.createdAt,
  });

  factory Post.fromJson(Map<String, dynamic> json) => Post(
        id: json['id'] as String,
        channelId: json['channelId'] as String,
        channelName: json['channelName'] as String? ?? '',
        authorId: json['authorId'] as String,
        authorDisplayName: json['authorDisplayName'] as String? ?? '',
        content: json['content'] as String,
        createdAt: DateTime.parse(json['createdAt'] as String),
      );
}