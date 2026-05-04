import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kassma_miners/app.dart';

void main() {
  testWidgets('App renders splash screen', (WidgetTester tester) async {
    await tester.pumpWidget(const KassmaApp());
    expect(find.byType(KassmaApp), findsOneWidget);
  });
}
