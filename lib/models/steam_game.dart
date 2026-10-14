import 'package:cloud_firestore/cloud_firestore.dart';

class SteamGame {
  final String? id;
  final String userId;
  final String appId;
  final String title;
  final String description;
  final String date;
  final String mood;
  final String imageUrl;
  final double rating;

  const SteamGame({
    this.id,
    this.userId = '',
    required this.appId,
    required this.title,
    required this.description,
    required this.date,
    required this.mood,
    required this.imageUrl,
    required this.rating,
  });

  SteamGame copyWith({String? id, String? userId}) => SteamGame(
    id: id ?? this.id,
    userId: userId ?? this.userId,
    appId: appId,
    title: title,
    description: description,
    date: date,
    mood: mood,
    imageUrl: imageUrl,
    rating: rating,
  );

  Map<String, Object?> toFirestore(String ownerId) => {
    'userId': ownerId,
    'appId': appId,
    'title': title,
    'description': description,
    'date': date,
    'mood': mood,
    'imageUrl': imageUrl,
    'rating': rating,
  };

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
      mood: data['mood'] as String? ?? 'มีความสุข',
      imageUrl: data['imageUrl'] as String? ?? '',
      rating: (data['rating'] as num?)?.toDouble() ?? 0,
    );
  }
}
