import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:mydiary_app/data/database_helper.dart';
import 'package:mydiary_app/main.dart';
import 'package:mydiary_app/models/steam_game.dart';

class TestDatabase extends DatabaseHelper {
  TestDatabase() : super(factory: databaseFactoryFfi);
  final List<SteamGame> games = [];
  int nextId = 1;
  @override
  Future<List<SteamGame>> readGames() async => List.of(games);
  @override
  Future<void> saveGame(SteamGame game) async {
    if (game.id == null) {
      games.add(SteamGame.fromMap({...game.toMap(), 'id': nextId++}));
    } else {
      games[games.indexWhere((item) => item.id == game.id)] = game;
    }
  }

  @override
  Future<void> deleteGame(int id) async =>
      games.removeWhere((game) => game.id == id);
}

void main() {
  testWidgets(
    'Existing Steam app: create, edit, search, count, cancel and confirm delete',
    (tester) async {
      final db = TestDatabase();
      await tester.pumpWidget(SteamFavoriteApp(database: db));
      await tester.pumpAndSettle();
      expect(find.text('เกมโปรดของฉัน (0)'), findsOneWidget);
      expect(find.text('ยังไม่มีเกมในรายการนี้'), findsOneWidget);
      await tester.tap(find.byTooltip('เพิ่มเกมใหม่'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byKey(const Key('gameTitle')), 'Palworld');
      await tester.enterText(
        find.byKey(const Key('gameDescription')),
        'เล่นกับเพื่อน',
      );
      FocusManager.instance.primaryFocus?.unfocus();
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('บันทึก'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('บันทึก'));
      await tester.pumpAndSettle();
      expect(find.text('เกมโปรดของฉัน (1)'), findsOneWidget);
      expect(db.games, hasLength(1));
      await tester.enterText(find.byKey(const Key('gameSearch')), 'PAL');
      await tester.pumpAndSettle();
      expect(find.text('Palworld'), findsOneWidget);
      await tester.enterText(find.byKey(const Key('gameSearch')), 'not found');
      await tester.pumpAndSettle();
      expect(find.text('ไม่พบเกมที่ตรงกับตัวกรอง'), findsOneWidget);
      expect(find.text('เกมโปรดของฉัน (1)'), findsOneWidget);
      await tester.tap(find.text('ล้างตัวกรอง'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Palworld'));
      await tester.pumpAndSettle();
      expect(find.text('เล่นกับเพื่อน'), findsOneWidget);
      await tester.tap(find.byTooltip('แก้ไขเกม'));
      await tester.pumpAndSettle();
      expect(find.text('Palworld'), findsOneWidget);
      expect(find.text('เล่นกับเพื่อน'), findsOneWidget);
      await tester.enterText(
        find.byKey(const Key('gameTitle')),
        'Palworld updated',
      );
      FocusManager.instance.primaryFocus?.unfocus();
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('บันทึก'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('บันทึก'));
      await tester.pumpAndSettle();
      expect(find.text('Palworld updated'), findsOneWidget);
      expect(db.games.single.id, 1);
      await tester.tap(find.byTooltip('ลบเกม'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('ยกเลิก'));
      await tester.pumpAndSettle();
      expect(db.games, hasLength(1));
      await tester.tap(find.byTooltip('ลบเกม'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('ยืนยันลบ'));
      await tester.pumpAndSettle();
      expect(db.games, isEmpty);
      expect(find.text('เกมโปรดของฉัน (0)'), findsOneWidget);
      expect(find.text('ยังไม่มีเกมในรายการนี้'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
}
