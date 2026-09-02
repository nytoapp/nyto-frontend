import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nyto_app/app.dart';
import 'package:nyto_app/features/auth/welcome_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  final binding = TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});

    // No keystore in a unit test: report "nothing stored" so the app treats
    // this as a fresh install rather than a storage failure.
    binding.defaultBinaryMessenger.setMockMethodCallHandler(
      const MethodChannel('plugins.it_nomads.com/flutter_secure_storage'),
      (call) async => call.method == 'readAll' ? <String, String>{} : null,
    );
  });

  tearDown(() {
    binding.defaultBinaryMessenger.setMockMethodCallHandler(
      const MethodChannel('plugins.it_nomads.com/flutter_secure_storage'),
      null,
    );
  });

  testWidgets('NYTO opens on welcome when there is no session', (tester) async {
    await tester.pumpWidget(const NytoApp());

    // Splash holds for a beat before routing, then the transition runs.
    await tester.pump(const Duration(milliseconds: 1100));
    await tester.pump(const Duration(milliseconds: 700));

    expect(find.byType(WelcomeScreen), findsOneWidget);
  });
}
