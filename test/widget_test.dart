import 'package:flutter_test/flutter_test.dart';
import 'package:nyto_app/app.dart';
import 'package:nyto_app/features/auth/welcome_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('NYTO opens on welcome when there is no session', (tester) async {
    SharedPreferences.setMockInitialValues({});
    await tester.pumpWidget(const NytoApp());
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
    expect(find.byType(WelcomeScreen), findsOneWidget);
  });
}
