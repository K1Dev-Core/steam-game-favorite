class SteamGame {
  final int? id;
  final String appId;
  final String title;
  final String description;
  final String date;
  final String mood;
  final String imageUrl;
  final double rating;

  const SteamGame({
    this.id,
    required this.appId,
    required this.title,
    required this.description,
    required this.date,
    required this.mood,
    required this.imageUrl,
    required this.rating,
  });

  Map<String, Object?> toMap() => {
    if (id != null) 'id': id,
    'appId': appId,
    'title': title,
    'description': description,
    'date': date,
    'mood': mood,
    'imageUrl': imageUrl,
    'rating': rating,
  };

  factory SteamGame.fromMap(Map<String, Object?> map) => SteamGame(
    id: map['id'] as int,
    appId: map['appId'] as String,
    title: map['title'] as String,
    description: map['description'] as String,
    date: map['date'] as String,
    mood: map['mood'] as String,
    imageUrl: map['imageUrl'] as String,
    rating: (map['rating'] as num).toDouble(),
  );
}
