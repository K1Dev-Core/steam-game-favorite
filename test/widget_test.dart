import 'package:flutter_test/flutter_test.dart';

import 'package:mydiary_app/main.dart';

void main() {
  testWidgets('Steam favorites renders game list', (WidgetTester tester) async {
    await tester.pumpWidget(const SteamFavoriteApp());

    expect(find.text('เกมโปรดของฉัน'), findsOneWidget);
    expect(find.text('Grand Theft Auto V'), findsOneWidget);
  });
}
