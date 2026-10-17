import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mydiary_app/main.dart';
import 'package:mydiary_app/models/steam_game.dart';
import 'package:mydiary_app/repositories/game_repository.dart';

class TestRepository implements GameRepository {
  final List<SteamGame> games = [];
  final _changes = StreamController<List<SteamGame>>.broadcast();
  int nextId = 1;

  void _emit() => _changes.add(List.unmodifiable(games));

  @override
  Stream<List<SteamGame>> watchGames() async* {
    yield List.unmodifiable(games);
    yield* _changes.stream;
  }

  @override
  Future<SteamGame> saveGame(SteamGame game) async {
    final saved = game.id == null
        ? game.copyWith(id: '${nextId++}', userId: 'test-user')
        : game;
    if (game.id == null) {
      games.add(saved);
    } else {
      games[games.indexWhere((item) => item.id == game.id)] = saved;
    }
    _emit();
    return saved;
  }

  @override
  Future<void> deleteGame(String id) async {
    games.removeWhere((game) => game.id == id);
    _emit();
  }

  Future<void> close() => _changes.close();
}

void main() {
  testWidgets('Cloud CRUD UI creates, edits and deletes in real time', (
    tester,
  ) async {
    final repository = TestRepository();
    addTearDown(repository.close);
    await tester.pumpWidget(SteamFavoriteApp(repository: repository));
    await tester.pumpAndSettle();
    expect(find.text('0 เกมที่บันทึกบน Cloud'), findsOneWidget);
    expect(find.text('0 เกม'), findsOneWidget);
    expect(find.text('สรุปคลังเกม'), findsNothing);
    await tester.tap(find.byTooltip('เพิ่มเกมใหม่'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('gameTitle')), 'Palworld');
    await tester.enterText(
      find.byKey(const Key('gameDescription')),
      'เล่นกับเพื่อน',
    );
    await tester.ensureVisible(find.text('บันทึก'));
    await tester.tap(find.text('บันทึก'));
    await tester.pumpAndSettle();
    expect(find.text('1 เกมที่บันทึกบน Cloud'), findsOneWidget);
    await tester.tap(find.text('สถิติ').last);
    await tester.pumpAndSettle();
    expect(find.text('สถิติเกมโปรด'), findsOneWidget);
    expect(find.byKey(const Key('stats-filter-Action')), findsOneWidget);
    await tester.tap(find.byKey(const Key('stats-filter-Action')));
    await tester.pumpAndSettle();
    expect(find.text('เกมโปรด'), findsWidgets);
    await tester.tap(find.text('เกมโปรด').last);
    await tester.pumpAndSettle();
    expect(repository.games.single.userId, 'test-user');
    await tester.scrollUntilVisible(
      find.text('Palworld'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.text('Palworld'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('แก้ไขเกม'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const Key('gameTitle')),
      'Palworld Cloud',
    );
    await tester.ensureVisible(find.text('บันทึก'));
    await tester.tap(find.text('บันทึก'));
    await tester.pumpAndSettle();
    expect(find.text('Palworld Cloud'), findsOneWidget);
    await tester.tap(find.byTooltip('ลบเกม'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('ยืนยันลบ'));
    await tester.pumpAndSettle();
    expect(repository.games, isEmpty);
    expect(find.text('0 เกมที่บันทึกบน Cloud'), findsOneWidget);
  });
}
