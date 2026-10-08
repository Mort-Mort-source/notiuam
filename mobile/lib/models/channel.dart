class Channel {
  final String id;
  final String name;
  final String? description;
  final String category;
  final bool publicChannel;
  final String ownerId;
  final String ownerDisplayName;
  final String ownerRole;
  final int subscriberCount;
  final bool subscribedByMe;
  final DateTime createdAt;

  Channel({
    required this.id,
    required this.name,
    this.description,
    required this.category,
    required this.publicChannel,
    required this.ownerId,
    required this.ownerDisplayName,
    required this.ownerRole,
    required this.subscriberCount,
    required this.subscribedByMe,
    required this.createdAt,
  });

  factory Channel.fromJson(Map<String, dynamic> json) => Channel(
        id: json['id'] as String,
        name: json['name'] as String,
        description: json['description'] as String?,
        category: json['category'] as String,
        publicChannel: json['publicChannel'] as bool? ?? true,
        ownerId: json['ownerId'] as String? ?? '',
        ownerDisplayName: json['ownerDisplayName'] as String? ?? '',
        ownerRole: json['ownerRole'] as String? ?? 'STUDENT',
        subscriberCount: (json['subscriberCount'] as num?)?.toInt() ?? 0,
        subscribedByMe: json['subscribedByMe'] as bool? ?? false,
        createdAt: DateTime.parse(json['createdAt'] as String),
      );

  /// Canales oficiales: creados por ADMIN o SUPERADMIN.
  bool get isOfficial => ownerRole == 'ADMIN' || ownerRole == 'SUPERADMIN';

  /// Canales docentes: creados por un PROFESSOR.
  bool get isProfessorOwned => ownerRole == 'PROFESSOR';
}