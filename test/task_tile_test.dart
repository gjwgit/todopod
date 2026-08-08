/// Tests for TaskTile — action buttons shown per task row.
///
library;
// Run: flutter test test/task_tile_test.dart

import 'package:flutter/material.dart';

import 'package:flutter_test/flutter_test.dart';

import 'package:todopod/models/task.dart';
import 'package:todopod/widgets/task_tile.dart';

void main() {
  const task = Task(id: '1', description: 'Water the plants');

  Future<void> pumpTile(
    WidgetTester tester, {
    VoidCallback? onDelete,
    VoidCallback? onSetDueToday,
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: TaskTile(
            task: task,
            onTap: () {},
            onComplete: (_) {},
            onDelete: onDelete,
            onSetDueToday: onSetDueToday,
          ),
        ),
      ),
    );
  }

  group('TaskTile', () {
    testWidgets('omits the due-today button when no callback is given', (
      tester,
    ) async {
      await pumpTile(tester);
      expect(find.byIcon(Icons.today_outlined), findsNothing);
    });

    testWidgets('shows the due-today button when a callback is given', (
      tester,
    ) async {
      await pumpTile(tester, onSetDueToday: () {});
      expect(find.byIcon(Icons.today_outlined), findsOneWidget);
    });

    testWidgets('tapping the due-today button invokes the callback', (
      tester,
    ) async {
      var tapped = false;
      await pumpTile(tester, onSetDueToday: () => tapped = true);

      await tester.tap(find.byIcon(Icons.today_outlined));
      await tester.pump();

      expect(tapped, isTrue);
    });

    testWidgets('due-today and delete buttons can appear together', (
      tester,
    ) async {
      await pumpTile(tester, onDelete: () {}, onSetDueToday: () {});
      expect(find.byIcon(Icons.today_outlined), findsOneWidget);
      expect(find.byIcon(Icons.delete_outline), findsOneWidget);
    });
  });
}
