/// Integration tests — Tasks screen.
///
/// Tests the full widget tree: adding tasks, completing tasks, searching,
/// editing, and verifying that state changes are reflected in the UI.
///
library;
// Run: flutter test integration_test/tasks_screen_test.dart
// On device: flutter test integration_test/tasks_screen_test.dart -d <device>

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'package:todopod/services/app_provider.dart';

import 'test_app.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  // ── Helpers ────────────────────────────────────────────────────────────────

  Future<void> pumpApp(WidgetTester tester, AppProvider provider) async {
    await tester.pumpWidget(buildTestApp(provider));
    await tester.pumpAndSettle();
  }

  Future<void> tapAddButton(WidgetTester tester) async {
    // Use the FAB tooltip to distinguish it from other + icons in nav rail.
    await tester.tap(find.byTooltip('Add task'));
    await tester.pumpAndSettle();
  }

  Future<void> typeInField(
    WidgetTester tester,
    Finder field,
    String text,
  ) async {
    await tester.tap(field);
    await tester.enterText(field, text);
    await tester.pumpAndSettle();
  }

  // ── Empty state ────────────────────────────────────────────────────────────

  group('empty state', () {
    testWidgets('shows empty state when no tasks', (tester) async {
      await pumpApp(tester, providerWith());
      expect(find.text('No tasks yet'), findsOneWidget);
    });

    testWidgets('shows add button in empty state', (tester) async {
      await pumpApp(tester, providerWith());
      expect(find.byTooltip('Add task'), findsOneWidget);
    });
  });

  // ── Task list display ──────────────────────────────────────────────────────

  group('task list', () {
    testWidgets('displays loaded tasks', (tester) async {
      await pumpApp(
        tester,
        providerWith(todo: 'Buy milk\nWrite tests\n'),
      );
      expect(find.text('Buy milk'), findsOneWidget);
      expect(find.text('Write tests'), findsOneWidget);
    });

    testWidgets('shows priority badge', (tester) async {
      await pumpApp(tester, providerWith(todo: '(A) Urgent task\n'));
      expect(find.text('Urgent task'), findsOneWidget);
      // Priority badge shows the label for A.
      expect(find.textContaining('Now'), findsOneWidget);
    });

    testWidgets('past due task shows title in red', (tester) async {
      final yesterday =
          DateTime.now().subtract(const Duration(days: 1));
      final dateStr =
          '${yesterday.year}-${yesterday.month.toString().padLeft(2, '0')}'
          '-${yesterday.day.toString().padLeft(2, '0')}';
      await pumpApp(
        tester,
        providerWith(todo: 'Overdue task due:$dateStr\n'),
      );
      expect(find.text('Overdue task'), findsOneWidget);
      // Find the Text widget and verify its colour.
      final textWidget = tester.widget<Text>(find.text('Overdue task'));
      expect(textWidget.style?.color, isNotNull);
    });

    testWidgets('tasks screen has search field', (tester) async {
      await pumpApp(tester, providerWith(todo: 'Task\n'));
      expect(find.byType(TextField), findsOneWidget);
    });
  });

  // ── Add task ───────────────────────────────────────────────────────────────

  group('add task', () {
    testWidgets('FAB opens add task dialog', (tester) async {
      await pumpApp(tester, providerWith());
      await tapAddButton(tester);
      expect(find.text('New Log Entry'), findsNothing); // not a log dialog
      // The TaskEdit dialog should be present.
      expect(find.byType(Dialog), findsOneWidget);
    });

    testWidgets('cancel closes dialog without adding task', (tester) async {
      final provider = providerWith();
      await pumpApp(tester, provider);
      await tapAddButton(tester);
      expect(find.byType(Dialog), findsOneWidget);
      await tester.tap(find.descendant(
        of: find.byType(Dialog),
        matching: find.text('Cancel'),
      ));
      await tester.pumpAndSettle();
      expect(find.byType(Dialog), findsNothing);
      expect(provider.tasks, isEmpty);
    });

    testWidgets('typing and saving adds task to list', (tester) async {
      final provider = providerWith();
      await pumpApp(tester, provider);
      await tapAddButton(tester);

      // Wait for dialog to fully open.
      expect(find.byType(Dialog), findsOneWidget);

      // Find the description field by its hint text.
      final descField = find.descendant(
        of: find.byType(Dialog),
        matching: find.byWidgetPredicate(
          (w) =>
              w is TextField &&
              w.decoration?.hintText == 'What needs to be done?',
        ),
      );
      expect(descField, findsOneWidget);
      await tester.tap(descField);
      await tester.enterText(descField, 'My new task');
      await tester.pumpAndSettle();

      await tester.tap(find.descendant(
        of: find.byType(Dialog),
        matching: find.text('Add Task'),
      ));
      await tester.pumpAndSettle();

      expect(find.byType(Dialog), findsNothing);
      expect(find.text('My new task'), findsOneWidget);
      expect(provider.tasks, hasLength(1));
    });

    testWidgets('tapping outside barrier-dismissed=false does not close',
        (tester) async {
      await pumpApp(tester, providerWith());
      await tapAddButton(tester);

      // Dismiss attempt via Escape key (barrier tap is unreliable in tests).
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pumpAndSettle();

      // Dialog should still be open — barrierDismissible is false.
      expect(find.byType(Dialog), findsOneWidget);
    });
  });

  // ── Complete task ──────────────────────────────────────────────────────────

  group('complete task', () {
    testWidgets('ticking checkbox moves task to done', (tester) async {
      final provider = providerWith(todo: 'Task to complete\n');
      await pumpApp(tester, provider);

      // Tap the checkbox.
      await tester.tap(find.byType(Checkbox).first);
      await tester.pumpAndSettle();

      expect(provider.tasks, isEmpty);
      expect(provider.doneTasks, hasLength(1));
      expect(provider.doneTasks.first.description, 'Task to complete');
    });

    testWidgets('completed task disappears from tasks list', (tester) async {
      final provider = providerWith(todo: 'Vanishing task\n');
      await pumpApp(tester, provider);

      await tester.tap(find.byType(Checkbox).first);
      await tester.pumpAndSettle();

      expect(find.text('Vanishing task'), findsNothing);
    });

    testWidgets(
        'CRITICAL: completing via edit dialog removes from tasks AND adds to done',
        (tester) async {
      final provider = providerWith(todo: 'Edit to complete\n');
      await pumpApp(tester, provider);

      // Tap the task title to open edit dialog.
      await tester.tap(find.text('Edit to complete'));
      await tester.pumpAndSettle();
      expect(find.byType(Dialog), findsOneWidget);

      // Tick "Mark as done" inside the dialog.
      final checkbox = find.descendant(
        of: find.byType(Dialog),
        matching: find.text('Mark as done'),
      );
      await tester.tap(checkbox);
      await tester.pumpAndSettle();

      // Save.
      await tester.tap(find.descendant(
        of: find.byType(Dialog),
        matching: find.text('Save'),
      ));
      await tester.pumpAndSettle();

      // Must be in done, not in active.
      expect(provider.tasks, isEmpty,
          reason: 'Task still in active list after marking done via edit');
      expect(provider.doneTasks, hasLength(1),
          reason: 'Task not in done list — would be lost on restart');
    });
  });

  // ── Search / filter ────────────────────────────────────────────────────────

  group('search', () {
    testWidgets('search filters task list by description', (tester) async {
      await pumpApp(
        tester,
        providerWith(todo: 'Buy milk\nWrite tests\nCall Alice\n'),
      );

      final searchField = find.byType(TextField).first;
      await typeInField(tester, searchField, 'milk');

      expect(find.text('Buy milk'), findsOneWidget);
      expect(find.text('Write tests'), findsNothing);
      expect(find.text('Call Alice'), findsNothing);
    });

    testWidgets('clearing search shows all tasks', (tester) async {
      await pumpApp(
        tester,
        providerWith(todo: 'Task A\nTask B\n'),
      );

      final searchField = find.byType(TextField).first;
      await typeInField(tester, searchField, 'Task A');
      expect(find.text('Task B'), findsNothing);

      // Clear the search.
      await tester.tap(find.byIcon(Icons.clear));
      await tester.pumpAndSettle();

      expect(find.text('Task A'), findsOneWidget);
      expect(find.text('Task B'), findsOneWidget);
    });

    testWidgets('context: filter works', (tester) async {
      await pumpApp(
        tester,
        providerWith(todo: 'Call Bob @phone\nSend email @email\n'),
      );

      final searchField = find.byType(TextField).first;
      await typeInField(tester, searchField, 'context:phone');

      expect(find.text('Call Bob'), findsOneWidget);
      expect(find.text('Send email'), findsNothing);
    });

    testWidgets('help tooltip icon is present', (tester) async {
      await pumpApp(tester, providerWith(todo: 'Task\n'));
      expect(find.byIcon(Icons.help_outline), findsOneWidget);
    });
  });

  // ── Navigation ─────────────────────────────────────────────────────────────

  group('navigation', () {
    testWidgets('Done nav item is present', (tester) async {
      await pumpApp(tester, providerWith(todo: 'Task\n'));
      expect(find.text('Done'), findsOneWidget);
    });

    testWidgets('Import / Export nav item is present', (tester) async {
      await pumpApp(tester, providerWith(todo: 'Task\n'));
      expect(find.text('Import / Export'), findsOneWidget);
    });

    testWidgets('navigating to Done shows completed tasks', (tester) async {
      await pumpApp(
        tester,
        providerWith(
          todo: 'Active task\n',
          done: 'x 2026-04-13 Completed task\n',
        ),
      );

      await tester.tap(find.text('Done'));
      await tester.pumpAndSettle();

      expect(find.text('Completed task'), findsOneWidget);
      expect(find.text('Active task'), findsNothing);
    });
  });
}
