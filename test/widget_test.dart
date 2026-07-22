import 'package:flutter_test/flutter_test.dart';
import 'package:nyto_app/app.dart';

void main() {
  testWidgets('NYTO splash shows brand', (WidgetTester tester) async {
    await tester.pumpWidget(const NytoApp());
    expect(find.text('NYTO'), findsOneWidget);
  });
}
