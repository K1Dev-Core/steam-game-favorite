class BacklogGame {
  const BacklogGame({
    this.id,
    required this.ownerId,
    required this.title,
    this.appId = '',
    this.genre = 'อื่น ๆ',
    this.note = '',
    this.status = 'อยากเล่น',
    required this.createdAt,
  });

  final String? id;
  final String ownerId;
  final String title;
  final String appId;
  final String genre;
  final String note;
  final String status;
  final String createdAt;

  BacklogGame copyWith({
    String? id,
    String? ownerId,
    String? title,
    String? appId,
    String? genre,
    String? note,
    String? status,
    String? createdAt,
  }) => BacklogGame(
    id: id ?? this.id,
    ownerId: ownerId ?? this.ownerId,
    title: title ?? this.title,
    appId: appId ?? this.appId,
    genre: genre ?? this.genre,
    note: note ?? this.note,
    status: status ?? this.status,
    createdAt: createdAt ?? this.createdAt,
  );

  Map<String, Object?> toMap() => {
    'id': id,
    'ownerId': ownerId,
    'title': title,
    'appId': appId,
    'genre': genre,
    'note': note,
    'status': status,
    'createdAt': createdAt,
  };

  factory BacklogGame.fromMap(Map<String, Object?> map) => BacklogGame(
    id: map['id']?.toString(),
    ownerId: map['ownerId'] as String? ?? '',
    title: map['title'] as String? ?? '',
    appId: map['appId'] as String? ?? '',
    genre: map['genre'] as String? ?? 'อื่น ๆ',
    note: map['note'] as String? ?? '',
    status: map['status'] as String? ?? 'อยากเล่น',
    createdAt: map['createdAt'] as String? ?? '',
  );
}
