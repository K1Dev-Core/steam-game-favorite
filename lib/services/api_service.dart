import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import '../models/game_comment.dart';
import '../models/recommended_game.dart';

class ApiException implements Exception {
  const ApiException(this.message);
  final String message;
  @override
  String toString() => message;
}

class ApiService {
  ApiService({
    http.Client? client,
    String? endpoint,
    String? commentsEndpoint,
    this.timeout = const Duration(seconds: 12),
  }) : _client = client ?? http.Client(),
       endpoint = endpoint ?? _defaultEndpoint(),
       commentsEndpoint = commentsEndpoint ?? _defaultCommentsEndpoint();

  // ponytail: URL ตรงๆ ตัวแปรเดียว ไม่รับ dart-define
  static const gamesApiUrl =
      'https://steam-games-hw3.vercel.app/api/games';
  static const commentsApiUrl =
      'https://steam-comments-hw3.vercel.app/api/comments';

  static String _defaultEndpoint() => kIsWeb
      ? Uri.base.resolve('/api/games').toString()
      : gamesApiUrl;

  static String _defaultCommentsEndpoint() => kIsWeb
      ? Uri.base.resolve('/api/comments').toString()
      : commentsApiUrl;

  final http.Client _client;
  final String endpoint;
  final String commentsEndpoint;
  final Duration timeout;

  bool get isLocalPreview {
    final host = Uri.tryParse(endpoint)?.host;
    return host == 'localhost' || host == '127.0.0.1';
  }

  Future<List<RecommendedGame>> fetchGames() async {
    final ids = <String>{};
    return _getList(endpoint, 'games', (row) {
      final game = RecommendedGame.fromJson(row);
      if (!ids.add(game.appId)) {
        throw const FormatException('Duplicate appId');
      }
      return game;
    });
  }

  Future<List<GameComment>> fetchComments() async {
    return _getList(
      commentsEndpoint,
      'comments',
      GameComment.fromJson,
    );
  }

  Future<List<T>> _getList<T>(
    String target,
    String key,
    T Function(Map<String, dynamic>) parse,
  ) async {
    final uri = Uri.tryParse(target);
    if (uri == null ||
        uri.host.isEmpty ||
        (uri.scheme != 'https' && !(isLocalPreview && uri.scheme == 'http'))) {
      throw const ApiException('URL ของ API ไม่ถูกต้อง');
    }
    try {
      final response = await _client
          .get(uri, headers: {'Accept': 'application/json'})
          .timeout(timeout);
      if (response.statusCode != 200) {
        throw ApiException(
          'เซิร์ฟเวอร์ตอบกลับไม่สำเร็จ (${response.statusCode}) กรุณาลองใหม่',
        );
      }
      final decoded = jsonDecode(utf8.decode(response.bodyBytes));
      if (decoded is! Map<String, dynamic> || decoded[key] is! List) {
        throw FormatException('Missing $key array');
      }
      return (decoded[key] as List).map((row) {
        if (row is! Map<String, dynamic>) {
          throw const FormatException('Invalid row');
        }
        return parse(row);
      }).toList();
    } on TimeoutException {
      throw const ApiException('เชื่อมต่อใช้เวลานานเกินไป กรุณาลองใหม่');
    } on FormatException {
      throw const ApiException(
        'รูปแบบข้อมูลจาก API ไม่ถูกต้อง กรุณาตรวจสอบ JSON',
      );
    } on ApiException {
      rethrow;
    } catch (_) {
      throw const ApiException('เชื่อมต่อไม่ได้ กรุณาลองใหม่');
    }
  }

  void close() => _client.close();
}
