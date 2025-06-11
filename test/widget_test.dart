// This is a basic Flutter widget test.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('Smart Rice App basic test', (WidgetTester tester) async {
    // Build a simple app
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          appBar: AppBar(title: const Text('Smart Rice Container')),
          body: const Center(child: Text('Test')),
        ),
      ),
    );

    // Verify that the app builds correctly
    expect(find.text('Smart Rice Container'), findsOneWidget);
    expect(find.text('Test'), findsOneWidget);
  });
}
