import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:mydiary_app/models/steam_game.dart';
import 'package:mydiary_app/services/diary_api_service.dart';
import 'package:mydiary_app/widgets/game_review_section.dart';

void main() {
  testWidgets(
    'game detail review supports API create, update, reload and delete',
    (tester) async {
      final serverRows = <Map<String, dynamic>>[];
      var nextId = 1;
      http.Response jsonResponse(Object body, int status) => http.Response(
        jsonEncode(body),
        status,
        headers: {'content-type': 'application/json; charset=utf-8'},
      );
      final client = MockClient((request) async {
        if (request.method == 'GET') {
          return jsonResponse(serverRows, 200);
        }
        if (request.method == 'POST') {
          final row = jsonDecode(request.body) as Map<String, dynamic>;
          final created = {...row, 'id': 'review-${nextId++}'};
          serverRows.add(created);
          return jsonResponse(created, 201);
        }
        final id = request.url.pathSegments.last;
        if (request.method == 'PUT') {
          final index = serverRows.indexWhere((row) => row['id'] == id);
          if (index < 0) return http.Response('not found', 404);
          serverRows[index] = {
            ...jsonDecode(request.body) as Map<String, dynamic>,
            'id': id,
          };
          return jsonResponse(serverRows[index], 200);
        }
        if (request.method == 'DELETE') {
          serverRows.removeWhere((row) => row['id'] == id);
          return jsonResponse({}, 200);
        }
        return http.Response('method not allowed', 405);
      });
      final api = DiaryApiService(
        endpoint: 'https://example.test/mydiary/api.php/67011212055',
        client: client,
      );
      addTearDown(api.close);
      const game = SteamGame(
        id: 'favorite-1',
        appId: '292030',
        title: 'The Witcher 3: Wild Hunt',
        description: 'Fantasy RPG',
        date: '2026-10-17',
        genre: 'RPG',
        imageUrl: '',
        rating: 4,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: GameReviewSection(game: game, api: api),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('เขียนรีวิวเกมนี้'));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const Key('gameReviewContent')),
        'เนื้อเรื่องดีมาก',
      );
      await tester.tap(find.text('บันทึก'));
      await tester.pumpAndSettle();
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pumpAndSettle();
      expect(serverRows.single['title'], game.title);
      expect(serverRows.single['appId'], game.appId);
      expect((await api.getDiaries()).single.content, 'เนื้อเรื่องดีมาก');
      expect(find.text('เนื้อเรื่องดีมาก'), findsOneWidget);

      await tester.tap(find.text('แก้ไข'));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const Key('gameReviewContent')),
        'เล่นซ้ำก็ยังสนุก',
      );
      await tester.tap(find.text('บันทึก'));
      await tester.pumpAndSettle();
      expect(serverRows.single['content'], 'เล่นซ้ำก็ยังสนุก');

      await tester.tap(find.text('ลบ'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('ลบรีวิว'));
      await tester.pumpAndSettle();
      expect(serverRows, isEmpty);
      expect(find.text('เขียนรีวิวเกมนี้'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
}
