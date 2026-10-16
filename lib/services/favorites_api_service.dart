import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/steam_game.dart';
import 'api_service.dart';

class FavoritesApiService {
  FavoritesApiService({http.Client? client, String? endpoint})
    : _client = client ?? http.Client(),
      endpoint =
          endpoint ??
          ApiService.gamesApiUrl.replaceFirst('/games', '/favorites');

  final http.Client _client;
  final String endpoint;
  static const _timeout = Duration(seconds: 15);

  Future<List<SteamGame>> getGames(String idToken) async {
    final response = await _send('GET', idToken);
    final decoded = _decode(response);
    final rows = decoded['games'];
    if (rows is! List) throw const FormatException('Missing games list');
    return rows
        .map((row) => SteamGame.fromJson(Map<String, dynamic>.from(row as Map)))
        .toList();
  }

  Future<SteamGame> createGame(SteamGame game, String idToken) async =>
      _save('POST', game, idToken);

  Future<SteamGame> updateGame(SteamGame game, String idToken) async =>
      _save('PUT', game, idToken);

  Future<SteamGame> _save(String method, SteamGame game, String idToken) async {
    final response = await _send(
      method,
      idToken,
      body: jsonEncode(game.toJson()),
    );
    final decoded = _decode(response);
    return SteamGame.fromJson(
      Map<String, dynamic>.from(decoded['game'] as Map),
    );
  }

  Future<void> deleteGame(String id, String idToken) async {
    final uri = Uri.parse(endpoint).replace(queryParameters: {'id': id});
    _decode(await _send('DELETE', idToken, uri: uri));
  }

  Future<http.Response> _send(
    String method,
    String idToken, {
    String? body,
    Uri? uri,
  }) => _client
      .send(
        http.Request(method, uri ?? Uri.parse(endpoint))
          ..headers.addAll({
            'Accept': 'application/json',
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $idToken',
          })
          ..body = body ?? '',
      )
      .then(http.Response.fromStream)
      .timeout(_timeout);

  Map<String, dynamic> _decode(http.Response response) {
    if (response.statusCode < 200 || response.statusCode >= 300) {
      final message =
          _tryMessage(response.body) ??
          'เซิร์ฟเวอร์บันทึกข้อมูลไม่สำเร็จ (${response.statusCode})';
      throw ApiException(message);
    }
    if (response.bodyBytes.isEmpty) return const {};
    try {
      final decoded = jsonDecode(utf8.decode(response.bodyBytes));
      if (decoded is! Map<String, dynamic>) {
        throw const FormatException('Invalid response');
      }
      return decoded;
    } on FormatException {
      throw const ApiException('เซิร์ฟเวอร์ส่งข้อมูลกลับมาไม่ถูกต้อง');
    }
  }

  String? _tryMessage(String body) {
    try {
      final decoded = jsonDecode(body);
      if (decoded is Map<String, dynamic> && decoded['error'] is String) {
        return decoded['error'] as String;
      }
    } catch (_) {}
    return null;
  }

  void close() => _client.close();
}
