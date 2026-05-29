import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/main.dart';

void main() {
  testWidgets('LIMS app renders the splash screen', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const MyApp());

    expect(find.text('LIMS'), findsOneWidget);
    expect(find.text('Loading...'), findsOneWidget);
  });
}
