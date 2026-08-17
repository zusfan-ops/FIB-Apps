import 'package:flutter_test/flutter_test.dart';

import 'package:jepang_app/main.dart';

void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const SakuraKotobaApp());
    expect(find.text('SakuraKotoba · 桜言葉'), findsOneWidget);
  });
}
