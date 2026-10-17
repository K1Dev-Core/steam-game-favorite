import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mydiary_app/data/game_database.dart';
import 'package:mydiary_app/models/backlog_game.dart';
import 'package:mydiary_app/models/steam_game.dart';
import 'package:mydiary_app/pages/backlog_page.dart';

class MemoryGameDatabase implements GameDatabase {
  final List<BacklogGame> backlog = [];

  @override
  Future<List<BacklogGame>> readBacklog(String ownerId) async =>
      backlog.where((game) => game.ownerId == ownerId).toList();

  @override
  Future<void> saveBacklog(BacklogGame game) async {
    final index = backlog.indexWhere((item) => item.id == game.id);
    if (index == -1) {
      backlog.add(game);
    } else {
      backlog[index] = game;
    }
  }

  @override
  Future<void> deleteBacklog(String ownerId, String id) async {
    backlog.removeWhere((game) => game.ownerId == ownerId && game.id == id);
  }

  @override
  Future<List<SteamGame>> readGames(String userId) async => [];

  @override
  Future<void> replaceGames(String userId, List<SteamGame> games) async {}

  @override
  Future<void> saveGame(SteamGame game) async {}

  @override
  Future<void> deleteGame(String userId, String id) async {}
}

void main() {
  testWidgets('Backlog can create, edit, filter and delete local items', (
    tester,
  ) async {
    final database = MemoryGameDatabase();
    await tester.pumpWidget(
      MaterialApp(
        home: BacklogPage(database: database, ownerId: 'student-a'),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('ยังไม่มีเกมในรายการ'), findsOneWidget);

    await tester.tap(find.byTooltip('เพิ่มเกมในเครื่อง'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField).first, 'Hades');
    await tester.tap(find.text('บันทึกลงเครื่อง'));
    await tester.pumpAndSettle();

    expect(find.text('Hades'), findsOneWidget);
    expect(database.backlog.single.ownerId, 'student-a');
    expect(database.backlog.single.status, 'อยากเล่น');

    await tester.tap(find.text('Hades'));
    await tester.pumpAndSettle();
    await tester.tap(find.byType(DropdownButtonFormField<String>).last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('กำลังเล่น').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('บันทึกลงเครื่อง'));
    await tester.pumpAndSettle();
    expect(database.backlog.single.status, 'กำลังเล่น');

    await tester.tap(find.text('เล่นจบแล้ว'));
    await tester.pumpAndSettle();
    expect(find.text('ยังไม่มีเกมสถานะนี้'), findsOneWidget);

    await tester.tap(find.text('ทั้งหมด'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('ลบออกจากรายการ'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'ลบ'));
    await tester.pumpAndSettle();
    expect(database.backlog, isEmpty);
    expect(find.text('ยังไม่มีเกมในรายการ'), findsOneWidget);
  });
}
