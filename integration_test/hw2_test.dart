import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:mydiary_app/main.dart' as app;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  testWidgets('HW2 CRUD demonstration', (tester) async {
    app.main();
    await tester.pumpAndSettle();
    await Future<void>.delayed(const Duration(seconds: 3));
    expect(find.text('ยังไม่มีเกมในรายการนี้'), findsOneWidget);
    await tester.tap(find.byTooltip('เพิ่มเกมใหม่'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('บันทึก'));
    await tester.tap(find.text('บันทึก'));
    await tester.pumpAndSettle();
    expect(find.text('กรุณากรอกชื่อเกม'), findsOneWidget);
    await Future<void>.delayed(const Duration(seconds: 2));
    await tester.ensureVisible(find.byKey(const Key('gameTitle')));
    await tester.enterText(find.byKey(const Key('gameTitle')), 'Palworld');
    await tester.enterText(
      find.byKey(const Key('gameDescription')),
      'My favorite game with friends',
    );
    FocusManager.instance.primaryFocus?.unfocus();
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.byType(Slider));
    await tester.tap(find.byType(Slider));
    await tester.pumpAndSettle();
    await Future<void>.delayed(const Duration(seconds: 2));
    await tester.ensureVisible(find.text('บันทึก'));
    await tester.tap(find.text('บันทึก'));
    await tester.pumpAndSettle();
    expect(find.text('Palworld'), findsOneWidget);
    await Future<void>.delayed(const Duration(seconds: 2));
    await tester.tap(find.text('Palworld'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('แก้ไขเกม'));
    await tester.pumpAndSettle();
    expect(find.text('Palworld'), findsOneWidget);
    await tester.enterText(find.byKey(const Key('gameTitle')), 'Palworld HW2');
    await tester.enterText(
      find.byKey(const Key('gameDescription')),
      'Updated note saved in SQLite',
    );
    FocusManager.instance.primaryFocus?.unfocus();
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('บันทึก'));
    await tester.tap(find.text('บันทึก'));
    await tester.pumpAndSettle();
    expect(find.text('Palworld HW2'), findsOneWidget);
    await Future<void>.delayed(const Duration(seconds: 2));
    await tester.tap(find.byTooltip('ลบเกม'));
    await tester.pumpAndSettle();
    await Future<void>.delayed(const Duration(seconds: 2));
    await tester.tap(find.text('ยืนยันลบ'));
    await tester.pumpAndSettle();
    expect(find.text('ยังไม่มีเกมในรายการนี้'), findsOneWidget);
    await Future<void>.delayed(const Duration(seconds: 2));
    await tester.tap(find.byTooltip('เพิ่มเกมใหม่'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('gameTitle')), 'GTA V HW2');
    await tester.enterText(
      find.byKey(const Key('gameDescription')),
      'This record survives app restart',
    );
    FocusManager.instance.primaryFocus?.unfocus();
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('บันทึก'));
    await tester.tap(find.text('บันทึก'));
    await tester.pumpAndSettle();
    expect(find.text('GTA V HW2'), findsOneWidget);
    await Future<void>.delayed(const Duration(seconds: 3));
    expect(tester.takeException(), isNull);
  });
}
