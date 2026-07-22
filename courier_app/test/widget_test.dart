import 'package:flutter_test/flutter_test.dart';
import 'package:courier_app/main.dart';

void main() {
  testWidgets('Courier app launches', (WidgetTester tester) async {
    await tester.pumpWidget(const SentraCourierApp());
    expect(find.text('SentraGO Courier'), findsOneWidget);
  });
}
