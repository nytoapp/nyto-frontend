import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nyto_app/app.dart';

void main() {
  testWidgets('NYTO splash shows primary logo', (WidgetTester tester) async {
    await tester.pumpWidget(const NytoApp());
    expect(find.byType(Image), findsOneWidget);
    expect(
      find.byWidgetPredicate(
        (w) =>
            w is Image &&
            w.image is AssetImage &&
            (w.image as AssetImage).assetName.contains('nyto_logo_primary'),
      ),
      findsOneWidget,
    );
  });
}
