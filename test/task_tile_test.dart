/// Tests for TaskTile — action buttons shown per task row.
///
library;
// Run: flutter test test/task_tile_test.dart

import 'package:flutter/material.dart';

import 'package:flutter_test/flutter_test.dart';

import 'package:todopod/models/task.dart';
import 'package:todopod/widgets/task_tile.dart';

void main() {
  const baseTask = Task(id: '1', description: 'Water the plants');

  Future<void> pumpTile(
    WidgetTester tester, {
    Task task = baseTask,
    VoidCallback? onDelete,
    VoidCallback? onDefer,
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: TaskTile(
            task: task,
            onTap: () {},
            onComplete: (_) {},
            onDelete: onDelete,
            onDefer: onDefer,
          ),
        ),
      ),
    );
  }

  group('TaskTile', () {
    testWidgets('omits the defer button when no callback is given', (
      tester,
    ) async {
      await pumpTile(tester);
      expect(find.byIcon(Icons.next_plan_outlined), findsNothing);
    });

    testWidgets('shows the defer button when a callback is given', (
      tester,
    ) async {
      await pumpTile(
        tester,
        task: baseTask.copyWith(priority: 'A'),
        onDefer: () {},
      );
      expect(find.byIcon(Icons.next_plan_outlined), findsOneWidget);
    });

    testWidgets('tapping the defer button invokes the callback', (
      tester,
    ) async {
      var tapped = false;
      await pumpTile(
        tester,
        task: baseTask.copyWith(priority: 'A'),
        onDefer: () => tapped = true,
      );

      await tester.tap(find.byIcon(Icons.next_plan_outlined));
      await tester.pump();

      expect(tapped, isTrue);
    });

    testWidgets('defer and delete buttons can appear together', (tester) async {
      await pumpTile(
        tester,
        task: baseTask.copyWith(priority: 'A'),
        onDelete: () {},
        onDefer: () {},
      );
      expect(find.byIcon(Icons.next_plan_outlined), findsOneWidget);
      expect(find.byIcon(Icons.delete_outline), findsOneWidget);
    });

    testWidgets('defer button is disabled with no priority set', (
      tester,
    ) async {
      var tapped = false;
      await pumpTile(tester, onDefer: () => tapped = true);

      await tester.tap(find.byIcon(Icons.next_plan_outlined));
      await tester.pump();

      expect(tapped, isFalse);
    });

    testWidgets('defer button is disabled once priority is F', (tester) async {
      var tapped = false;
      await pumpTile(
        tester,
        task: baseTask.copyWith(priority: 'F'),
        onDefer: () => tapped = true,
      );

      await tester.tap(find.byIcon(Icons.next_plan_outlined));
      await tester.pump();

      expect(tapped, isFalse);
    });
  });
}
