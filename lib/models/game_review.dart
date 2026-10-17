class GameReview {
  const GameReview({
    required this.id,
    required this.title,
    required this.content,
    required this.mood,
    required this.date,
    this.appId = '',
  });

  final String id;
  final String title;
  final String content;
  final String mood;
  final String date;
  final String appId;

  double get rating {
    final match = RegExp(r'([0-5](?:\.\d)?)').firstMatch(mood);
    return double.tryParse(match?.group(1) ?? '') ?? 0;
  }

  factory GameReview.fromJson(Map<String, dynamic> json) {
    String read(String key, {String fallback = ''}) {
      final value = json[key];
      if (value == null) return fallback;
      if (value is String) return value.trim();
      return value.toString();
    }

    return GameReview(
      id: read('id', fallback: read('_id')),
      title: read('title'),
      content: read('content'),
      mood: read('mood'),
      date: read('date'),
      appId: read('appId'),
    );
  }

  Map<String, dynamic> toJson() => {
    'title': title,
    'content': content,
    'mood': mood,
    'date': date,
    if (appId.isNotEmpty) 'appId': appId,
  };
}
