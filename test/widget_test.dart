import 'package:flutter_test/flutter_test.dart';
import 'package:voicebot_directory/main.dart';

void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const VoiceBotApp());
    expect(find.text('Contacts'), findsOneWidget);
  });
}
