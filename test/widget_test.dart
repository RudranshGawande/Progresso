import 'package:flutter_test/flutter_test.dart';
import 'package:progresso/main.dart';

void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const ProgressoApp(isLoggedIn: false));
    expect(find.text('PROGRESSO'), findsOneWidget);
  });
}
