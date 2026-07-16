import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:customer_app/main.dart';

void main() {
  testWidgets('App should build successfully', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const ProviderScope(child: SentraApp()));

    // Verify that the app builds and MaterialApp is present.
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
