/// Tests for PriorityHeader — section label and task count.
///
library;

// Run: flutter test test/priority_header_test.dart

import 'package:flutter/material.dart';

import 'package:flutter_test/flutter_test.dart';

import 'package:todopod/widgets/priority_header.dart';

void main() {
  Future<void> pumpHeader(
    WidgetTester tester, {
    String? priority,
    int? count,
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => PriorityHeader(
            priority: priority,
            cs: Theme.of(context).colorScheme,
            count: count,
          ),
        ),
      ),
    );
  }

  group('PriorityHeader', () {
    testWidgets('appends the task count to the label', (tester) async {
      await pumpHeader(tester, priority: 'A', count: 5);
      expect(find.text('A — Now — 5 tasks'), findsOneWidget);
    });

    testWidgets('uses the singular for one task', (tester) async {
      await pumpHeader(tester, priority: 'C', count: 1);
      expect(find.text('C — This Week — 1 task'), findsOneWidget);
    });

    testWidgets('counts the no-priority section too', (tester) async {
      await pumpHeader(tester, count: 3);
      expect(find.text('No Priority — 3 tasks'), findsOneWidget);
    });

    testWidgets('omits the count when none is given', (tester) async {
      await pumpHeader(tester, priority: 'A');
      expect(find.text('A — Now'), findsOneWidget);
    });
  });
}
