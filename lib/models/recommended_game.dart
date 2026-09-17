import 'steam_game.dart';

class RecommendedGame {
  const RecommendedGame({
    required this.appId,
    required this.title,
    required this.description,
    required this.imageUrl,
  });

  final String appId, title, description, imageUrl;

  factory RecommendedGame.fromJson(Map<String, dynamic> json) {
    String read(String key, {bool allowEmpty = false}) {
      final value = json[key];
      if (value is! String || (!allowEmpty && value.trim().isEmpty)) {
        throw FormatException('Invalid $key');
      }
      return value.trim();
    }

    final image = read('imageUrl', allowEmpty: true);
    if (image.isNotEmpty) {
      final uri = Uri.tryParse(image);
      if (uri == null || uri.scheme != 'https' || uri.host.isEmpty) {
        throw const FormatException('Invalid imageUrl');
      }
    }
    return RecommendedGame(
      appId: read('appId'),
      title: read('title'),
      description: read('description'),
      imageUrl: image,
    );
  }

  SteamGame toDraft() => SteamGame(
    appId: appId,
    title: title,
    description: description,
    imageUrl: imageUrl,
    date: DateTime.now().toIso8601String().split('T').first,
    mood: 'มีความสุข',
    rating: 4,
  );
}
