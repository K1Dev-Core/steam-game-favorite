import 'package:cloud_firestore/cloud_firestore.dart';

class SteamGame {
  final String? id;
  final String userId;
  final String appId;
  final String title;
  final String description;
  final String date;
  final String mood;
  final String genre;
  final String imageUrl;
  final double rating;
  final bool isFavorite;

  const SteamGame({
    this.id,
    this.userId = '',
    required this.appId,
    required this.title,
    required this.description,
    required this.date,
    this.mood = 'อื่น ๆ',
    String? genre,
    required this.imageUrl,
    required this.rating,
    this.isFavorite = true,
  }) : genre = genre ?? mood;

  SteamGame copyWith({String? id, String? userId, bool? isFavorite}) =>
      SteamGame(
        id: id ?? this.id,
        userId: userId ?? this.userId,
        appId: appId,
        title: title,
        description: description,
        date: date,
        mood: mood,
        genre: genre,
        imageUrl: imageUrl,
        rating: rating,
        isFavorite: isFavorite ?? this.isFavorite,
      );

  Map<String, Object?> toFirestore(String ownerId) => {
    'userId': ownerId,
    'appId': appId,
    'title': title,
    'description': description,
    'date': date,
    'genre': genre,
    'imageUrl': imageUrl,
    'rating': rating,
    'isFavorite': isFavorite,
  };

  Map<String, Object?> toMap({String? userId}) => {
    'id': id,
    'userId': userId ?? this.userId,
    'appId': appId,
    'title': title,
    'description': description,
    'date': date,
    'genre': genre,
    'imageUrl': imageUrl,
    'rating': rating,
    'isFavorite': isFavorite ? 1 : 0,
  };

  Map<String, Object?> toJson() => {
    'id': id,
    'userId': userId,
    'appId': appId,
    'title': title,
    'description': description,
    'date': date,
    'genre': genre,
    'imageUrl': imageUrl,
    'rating': rating,
    'isFavorite': isFavorite,
  };

  factory SteamGame.fromMap(Map<String, Object?> data) => SteamGame(
    id: data['id']?.toString(),
    userId: data['userId'] as String? ?? '',
    appId: data['appId'] as String? ?? '',
    title: data['title'] as String? ?? '',
    description: data['description'] as String? ?? '',
    date: data['date'] as String? ?? '',
    mood: data['mood'] as String? ?? data['genre'] as String? ?? 'อื่น ๆ',
    genre: data['genre'] as String? ?? data['mood'] as String? ?? 'อื่น ๆ',
    imageUrl: data['imageUrl'] as String? ?? '',
    rating: (data['rating'] as num?)?.toDouble() ?? 0,
    isFavorite: data['isFavorite'] == null
        ? true
        : data['isFavorite'] == true || data['isFavorite'] == 1,
  );

  factory SteamGame.fromJson(Map<String, dynamic> data) => SteamGame.fromMap(
    data.map((key, value) => MapEntry(key, value as Object?)),
  );

  factory SteamGame.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> document,
  ) {
    final data = document.data() ?? const <String, dynamic>{};
    return SteamGame(
      id: document.id,
      userId: data['userId'] as String? ?? '',
      appId: data['appId'] as String? ?? '',
      title: data['title'] as String? ?? '',
      description: data['description'] as String? ?? '',
      date: data['date'] as String? ?? '',
      mood: data['mood'] as String? ?? data['genre'] as String? ?? 'อื่น ๆ',
      genre: data['genre'] as String? ?? data['mood'] as String? ?? 'อื่น ๆ',
      imageUrl: data['imageUrl'] as String? ?? '',
      rating: (data['rating'] as num?)?.toDouble() ?? 0,
      isFavorite: data['isFavorite'] as bool? ?? true,
    );
  }
}
