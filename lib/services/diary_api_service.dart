import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/game_review.dart';

class DiaryApiException implements Exception {
  const DiaryApiException(this.message);
  final String message;

  @override
  String toString() => message;
}

class DiaryApiService {
  DiaryApiService({http.Client? client, String? endpoint})
    : _client = client ?? http.Client(),
      endpoint = endpoint ?? defaultEndpoint;

  static const studentId = '67011212055';
  static const defaultEndpoint =
      'https://thipwimon.comsciproject.net/mydiary/api.php/$studentId';

  final http.Client _client;
  final String endpoint;

  Uri get _baseUri => Uri.parse(endpoint);

  Future<List<GameReview>> getDiaries() async {
    final decoded = await _send('GET', _baseUri);
    final rows = decoded is List
        ? decoded
        : decoded is Map<String, dynamic>
        ? decoded['diaries'] ?? decoded['data']
        : null;
    if (rows is! List) {
      throw const DiaryApiException('รูปแบบรายการรีวิวจาก API ไม่ถูกต้อง');
    }
    try {
      return rows
          .whereType<Map<String, dynamic>>()
          .map(GameReview.fromJson)
          .toList();
    } on FormatException {
      throw const DiaryApiException('ข้อมูลรีวิวจาก API ไม่ถูกต้อง');
    }
  }

  Future<void> createDiary(GameReview review) async {
    await _send('POST', _baseUri, body: review.toJson());
  }

  Future<void> updateDiary(GameReview review) async {
    if (review.id.isEmpty) {
      throw const DiaryApiException('ไม่พบรหัสรีวิวสำหรับแก้ไข');
    }
    await _send(
      'PUT',
      Uri.parse('$endpoint/${Uri.encodeComponent(review.id)}'),
      body: review.toJson(),
    );
  }

  Future<void> deleteDiary(String id) async {
    if (id.isEmpty) throw const DiaryApiException('ไม่พบรหัสรีวิวสำหรับลบ');
    await _send('DELETE', Uri.parse('$endpoint/${Uri.encodeComponent(id)}'));
  }

  Future<dynamic> _send(
    String method,
    Uri uri, {
    Map<String, dynamic>? body,
  }) async {
    try {
      final request = http.Request(method, uri)
        ..headers['Accept'] = 'application/json';
      if (body != null) {
        request.headers['Content-Type'] = 'application/json; charset=utf-8';
        request.body = jsonEncode(body);
      }
      final response = await _client
          .send(request)
          .timeout(const Duration(seconds: 15));
      final result = await http.Response.fromStream(response);
      if (result.statusCode < 200 || result.statusCode >= 300) {
        throw DiaryApiException(
          'บันทึกกับเซิร์ฟเวอร์ไม่สำเร็จ (${result.statusCode})',
        );
      }
      final text = utf8.decode(result.bodyBytes).trim();
      if (text.isEmpty) return null;
      try {
        return jsonDecode(text);
      } on FormatException {
        // Some CRUD endpoints respond with a plain success message.
        return text;
      }
    } on TimeoutException {
      throw const DiaryApiException('เซิร์ฟเวอร์ตอบช้า กรุณาลองใหม่');
    } on DiaryApiException {
      rethrow;
    } catch (_) {
      throw const DiaryApiException('เชื่อมต่อ API ไม่ได้ กรุณาลองใหม่');
    }
  }

  void close() => _client.close();
}
