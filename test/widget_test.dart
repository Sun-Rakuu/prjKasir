import 'package:flutter_test/flutter_test.dart';
import 'package:app_pos/main.dart';

void main() {
  testWidgets('App starts correctly', (WidgetTester tester) async {
    await tester.pumpWidget(const IntiHoseApp());
    expect(find.text('Dashboard'), findsOneWidget);
  });
}
