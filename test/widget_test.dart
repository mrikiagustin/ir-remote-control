import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_remote/main.dart';

void main() {
  testWidgets('App renders IR AC Remote UI', (WidgetTester tester) async {
    await tester.pumpWidget(const AcRemoteApp());
    expect(find.text('IR AC REMOTE'), findsOneWidget);
    expect(find.text('MODE'), findsOneWidget);
    expect(find.text('FAN SPEED'), findsOneWidget);
  });
}
