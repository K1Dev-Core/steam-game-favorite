import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:mydiary_app/services/api_service.dart';
import 'package:mydiary_app/pages/community_page.dart';
import 'package:mydiary_app/pages/recommended_games_page.dart';
import 'lab2_test.dart' show TestDatabase;

const sample = {
  'appId': '271590',
  'title': 'GTA V',
  'description': 'รายละเอียดจาก API',
  'imageUrl': '',
};

void main() {
  ApiService service(Future<http.Response> Function(http.Request) handler) =>
      ApiService(
        endpoint: 'https://games.example/api/games',
        client: MockClient(handler),
        timeout: const Duration(milliseconds: 30),
      );

  test('HTTP JSON becomes game model and draft without SQLite id', () async {
    final api = service((request) async {
      expect(request.method, 'GET');
      return http.Response(
        jsonEncode({
          'games': [sample],
        }),
        200,
        headers: {'content-type': 'application/json; charset=utf-8'},
      );
    });
    final game = (await api.fetchGames()).single;
    expect(game.title, 'GTA V');
    expect(game.description, 'รายละเอียดจาก API');
    expect(game.toDraft().id, isNull);
    api.close();
  });

  test('Empty API list is valid', () async {
    final api = service((_) async => http.Response('{"games":[]}', 200));
    expect(await api.fetchGames(), isEmpty);
    api.close();
  });

  for (final code in [404, 500]) {
    test('HTTP $code gives friendly error', () async {
      final api = service((_) async => http.Response('error', code));
      await expectLater(api.fetchGames(), throwsA(isA<ApiException>()));
      api.close();
    });
  }

  for (final body in [
    'not json',
    '{}',
    '{"games":[{}]}',
    jsonEncode({
      'games': [sample, sample],
    }),
  ]) {
    test('Reject invalid response $body', () async {
      final api = service((_) async => http.Response(body, 200));
      await expectLater(api.fetchGames(), throwsA(isA<ApiException>()));
      api.close();
    });
  }

  test('Offline and timeout are handled', () async {
    final offline = service((_) async => throw http.ClientException('offline'));
    await expectLater(offline.fetchGames(), throwsA(isA<ApiException>()));
    offline.close();
    final timeout = service((_) => Completer<http.Response>().future);
    await expectLater(timeout.fetchGames(), throwsA(isA<ApiException>()));
    timeout.close();
  });

  testWidgets(
    'FutureBuilder loading, error, retry, detail and save to favorites',
    (tester) async {
      final response = Completer<http.Response>();
      var calls = 0;
      var saved = false;
      final db = TestDatabase();
      final api = ApiService(
        endpoint: 'https://games.example/api/games',
        client: MockClient((_) async {
          calls++;
          if (calls == 1) return response.future;
          return http.Response(
            jsonEncode({
              'games': [sample],
            }),
            200,
            headers: {'content-type': 'application/json; charset=utf-8'},
          );
        }),
      );
      await tester.pumpWidget(
        MaterialApp(
          home: RecommendedGamesPage(
            database: db,
            api: api,
            onSaved: () => saved = true,
          ),
        ),
      );
      await tester.pump();
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      response.complete(http.Response('unavailable', 503));
      await tester.pumpAndSettle();
      expect(find.text('โหลดเกมไม่สำเร็จ'), findsOneWidget);
      await tester.tap(find.text('ลองใหม่'));
      await tester.pumpAndSettle();
      expect(find.text('GTA V'), findsOneWidget);
      expect(calls, 2);
      await tester.tap(find.text('GTA V'));
      await tester.pumpAndSettle();
      expect(find.text('รายละเอียดจาก API'), findsOneWidget);
      await tester.ensureVisible(find.text('เพิ่มลงเกมโปรด'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('เพิ่มลงเกมโปรด'));
      await tester.pumpAndSettle();
      expect(find.text('เพิ่มเกมโปรด'), findsOneWidget);
      expect(find.text('GTA V'), findsOneWidget);
      await tester.ensureVisible(find.text('บันทึก'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('บันทึก'));
      await tester.pumpAndSettle();
      expect(saved, isTrue);
      expect(db.games.single.appId, '271590');
      expect(db.games.single.description, 'รายละเอียดจาก API');
      expect(tester.takeException(), isNull);
      api.close();
    },
  );

  testWidgets(
    'Discover page with many games shows featured card and survives shuffle',
    (tester) async {
      const second = {
        'appId': '570',
        'title': 'Dota 2',
        'description': 'MOBA ฟรี',
        'imageUrl': '',
      };
      final api = service(
        (_) async => http.Response(
          jsonEncode({
            'games': [sample, second],
          }),
          200,
          headers: {'content-type': 'application/json; charset=utf-8'},
        ),
      );
      await tester.pumpWidget(
        MaterialApp(
          home: RecommendedGamesPage(
            database: TestDatabase(),
            api: api,
            onSaved: () {},
          ),
        ),
      );
      // ponytail: จอสูงให้เห็นทุกการ์ดโดยไม่ต้องสกรอลล์
      tester.view.physicalSize = const Size(800, 2000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      await tester.pumpAndSettle();
      expect(find.text('GTA V'), findsOneWidget);
      expect(find.text('Dota 2'), findsOneWidget);
      // ดึงลงเพื่อรีเฟรชต้องโหลดใหม่โดยไม่พัง
      await tester.fling(
        find.byType(ListView),
        const Offset(0, 300),
        1000,
      );
      await tester.pumpAndSettle();
      expect(find.text('GTA V'), findsOneWidget);
      expect(find.text('Dota 2'), findsOneWidget);
      expect(tester.takeException(), isNull);
      api.close();
    },
  );
const sampleComment = {
  'id': 'c1',
  'appId': '730',
  'gameTitle': 'Counter-Strike 2',
  'user': 'Nutty',
  'text': 'ยิงหัวฟินมาก',
  'rating': 5,
  'date': '2026-09-12',
};

  ApiService commentsService(
    Future<http.Response> Function(http.Request) handler,
  ) => ApiService(
    endpoint: 'https://games.example/api/games',
    commentsEndpoint: 'https://games.example/api/comments',
    client: MockClient(handler),
    timeout: const Duration(milliseconds: 30),
  );

  test('Comments JSON becomes models with derived cover image', () async {
    final api = commentsService(
      (_) async => http.Response(
        jsonEncode({
          'comments': [sampleComment],
        }),
        200,
        headers: {'content-type': 'application/json; charset=utf-8'},
      ),
    );
    final comment = (await api.fetchComments()).single;
    expect(comment.user, 'Nutty');
    expect(comment.rating, 5);
    expect(comment.imageUrl, contains('730'));
    api.close();
  });

  for (final body in [
    '{"comments":[{}]}',
    jsonEncode({
      'comments': [
        {...sampleComment, 'rating': 9},
      ],
    }),
    jsonEncode({
      'comments': [
        {...sampleComment, 'text': '   '},
      ],
    }),
  ]) {
    test('Reject invalid comments response $body', () async {
      final api = commentsService((_) async => http.Response(body, 200));
      await expectLater(api.fetchComments(), throwsA(isA<ApiException>()));
      api.close();
    });
  }

  testWidgets('Community page lists comments read-only', (tester) async {
    final api = commentsService(
      (_) async => http.Response(
        jsonEncode({
          'comments': [sampleComment],
        }),
        200,
        headers: {'content-type': 'application/json; charset=utf-8'},
      ),
    );
    await tester.pumpWidget(
      MaterialApp(home: CommunityPage(api: api)),
    );
    await tester.pumpAndSettle();
    expect(find.text('ยิงหัวฟินมาก'), findsOneWidget);
    expect(find.text('@Counter-Strike 2'), findsOneWidget);
    expect(find.text('Nutty'), findsOneWidget);
    expect(tester.takeException(), isNull);
    api.close();
  });
}
