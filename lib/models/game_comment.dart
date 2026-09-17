class GameComment {
  const GameComment({
    required this.id,
    required this.appId,
    required this.gameTitle,
    required this.user,
    required this.text,
    required this.rating,
    required this.date,
  });

  final String id, appId, gameTitle, user, text, date;
  final double rating;

  // ponytail: รูปปก derive จาก appId เอง ไม่ต้องส่งซ้ำใน API
  String get imageUrl =>
      'https://cdn.cloudflare.steamstatic.com/steam/apps/$appId/header.jpg';

  factory GameComment.fromJson(Map<String, dynamic> json) {
    String read(String key) {
      final value = json[key];
      if (value is! String || value.trim().isEmpty) {
        throw FormatException('Invalid $key');
      }
      return value.trim();
    }

    final rating = json['rating'];
    if (rating is! num || rating < 0 || rating > 5) {
      throw const FormatException('Invalid rating');
    }
    return GameComment(
      id: read('id'),
      appId: read('appId'),
      gameTitle: read('gameTitle'),
      user: read('user'),
      text: read('text'),
      rating: rating.toDouble(),
      date: read('date'),
    );
  }
}
