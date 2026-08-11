import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nyto_app/app.dart';
import 'package:nyto_app/features/splash/splash_screen.dart';

void main() {
  testWidgets('NYTO opens on glow splash', (WidgetTester tester) async {
    await tester.pumpWidget(const NytoApp());
    expect(find.byType(SplashScreen), findsOneWidget);
  });
}
