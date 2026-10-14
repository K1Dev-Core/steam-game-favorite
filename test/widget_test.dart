import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mydiary_app/models/steam_game.dart';
import 'package:mydiary_app/pages/auth_page.dart';
import 'package:mydiary_app/pages/game_editor_page.dart';

import 'lab2_test.dart' show TestRepository;

void main() {
  test('Firebase Auth errors have friendly Thai messages', () {
    expect(authErrorMessage('weak-password'), contains('6'));
    expect(authErrorMessage('email-already-in-use'), contains('สมัคร'));
    expect(authErrorMessage('wrong-password'), contains('ไม่ถูกต้อง'));
  });

  testWidgets('Form validates blank fields and pre-fills edit data', (
    tester,
  ) async {
    final repository = TestRepository();
    addTearDown(repository.close);
    await tester.pumpWidget(
      MaterialApp(home: GameEditorPage(repository: repository)),
    );
    await tester.enterText(find.byKey(const Key('gameTitle')), '   ');
    await tester.enterText(find.byKey(const Key('gameDescription')), '   ');
    await tester.ensureVisible(find.text('บันทึก'));
    await tester.tap(find.text('บันทึก'));
    await tester.pump();
    expect(find.text('กรุณากรอกชื่อเกม'), findsOneWidget);
    expect(find.text('กรุณากรอกรายละเอียด'), findsOneWidget);

    await tester.pumpWidget(
      MaterialApp(
        home: GameEditorPage(
          key: const ValueKey('edit-game'),
          repository: repository,
          game: const SteamGame(
            id: 'doc-1',
            userId: 'user-1',
            appId: '1',
            title: 'Existing game',
            description: 'Existing note',
            date: '2026-10-13',
            mood: 'เศร้า',
            imageUrl: '',
            rating: 2.5,
          ),
        ),
      ),
    );
    expect(find.text('Existing game'), findsOneWidget);
    expect(find.text('คะแนนของฉัน: 2.5 / 5'), findsOneWidget);
  });
}
