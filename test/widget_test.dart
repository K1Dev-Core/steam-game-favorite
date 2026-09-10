import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:mydiary_app/data/database_helper.dart';
import 'package:mydiary_app/models/steam_game.dart';
import 'package:mydiary_app/pages/game_editor_page.dart';

void main() {
  test(
    'SQLite CRUD persists every field after closing and reopening',
    () async {
      sqfliteFfiInit();
      final directory = await Directory.systemTemp.createTemp(
        'steam_hw2_test_',
      );
      final path = '${directory.path}/test.db';
      var helper = DatabaseHelper(
        databasePath: path,
        factory: databaseFactoryFfi,
      );
      try {
        expect(await helper.readGames(), isEmpty);
        const original = SteamGame(
          appId: '1623730',
          title: 'Palworld',
          description: 'เล่นกับเพื่อน',
          date: '2026-09-10',
          mood: 'ผ่อนคลาย',
          imageUrl: 'https://example.com/game.jpg',
          rating: 4.5,
        );
        await helper.saveGame(original);
        final created = (await helper.readGames()).single;
        expect(created.id, isNotNull);
        await helper.close();
        helper = DatabaseHelper(
          databasePath: path,
          factory: databaseFactoryFfi,
        );
        expect((await helper.readGames()).single.toMap(), created.toMap());
        final updated = SteamGame(
          id: created.id,
          appId: '271590',
          title: 'GTA V',
          description: 'แก้รายละเอียด',
          date: '2026-09-11',
          mood: 'มีความสุข',
          imageUrl: '',
          rating: 3.5,
        );
        await helper.saveGame(updated);
        await helper.close();
        helper = DatabaseHelper(
          databasePath: path,
          factory: databaseFactoryFfi,
        );
        expect((await helper.readGames()).single.toMap(), updated.toMap());
        await helper.deleteGame(created.id!);
        await helper.close();
        helper = DatabaseHelper(
          databasePath: path,
          factory: databaseFactoryFfi,
        );
        expect(await helper.readGames(), isEmpty);
      } finally {
        await helper.close();
        await directory.delete(recursive: true);
      }
    },
  );

  testWidgets('Form rejects whitespace and pre-fills existing values', (
    tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: GameEditorPage()));
    await tester.enterText(find.byKey(const Key('gameTitle')), '   ');
    await tester.enterText(find.byKey(const Key('gameDescription')), '   ');
    await tester.ensureVisible(find.text('บันทึก'));
    await tester.tap(find.text('บันทึก'));
    await tester.pump();
    expect(find.text('กรุณากรอกชื่อเกม'), findsOneWidget);
    expect(find.text('กรุณากรอกรายละเอียด'), findsOneWidget);
    await tester.pumpWidget(
      const MaterialApp(
        home: GameEditorPage(
          key: ValueKey('edit'),
          game: SteamGame(
            id: 1,
            appId: '1',
            title: 'Existing game',
            description: 'Existing note',
            date: '2026-09-10',
            mood: 'เศร้า',
            imageUrl: '',
            rating: 2.5,
          ),
        ),
      ),
    );
    expect(find.text('Existing game'), findsOneWidget);
    expect(find.text('Existing note'), findsOneWidget);
    expect(find.text('คะแนนของฉัน: 2.5 / 5'), findsOneWidget);
  });
}
