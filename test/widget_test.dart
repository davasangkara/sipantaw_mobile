// Basic smoke test for SIPANTAW app.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:sipantaw_mobile/main.dart';

void main() {
  testWidgets('App boots to splash screen', (WidgetTester tester) async {
    await tester.pumpWidget(const SipantawApp(isLoggedIn: false));
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
