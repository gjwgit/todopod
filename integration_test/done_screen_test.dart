/// Integration tests — Done screen.
///
library;

// Run: flutter test integration_test/done_screen_test.dart

import 'package:flutter/material.dart';

import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'test_app.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  Future<void> pumpApp(WidgetTester tester, {String done = ''}) async {
    await tester.pumpWidget(buildTestApp(providerWith(done: done)));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Done'));
    await tester.pumpAndSettle();
  }

  // ── Empty state ────────────────────────────────────────────────────────────

  group('empty state', () {
    testWidgets('shows empty message when no completed tasks', (tester) async {
      await pumpApp(tester);
      expect(find.textContaining('No completed'), findsOneWidget);
    });
  });

  // ── Display ────────────────────────────────────────────────────────────────

  group('display', () {
    testWidgets('shows completed task descriptions', (tester) async {
      await pumpApp(
        tester,
        done:
            'x 2026-04-13 2026-04-10 Finished report +work\n'
            'x 2026-04-12 Buy groceries @errands\n',
      );
      expect(find.text('Finished report'), findsOneWidget);
      expect(find.text('Buy groceries'), findsOneWidget);
    });

    testWidgets('completed tasks have strikethrough decoration', (
      tester,
    ) async {
      await pumpApp(tester, done: 'x 2026-04-13 Done task\n');
      final textWidget = tester.widget<Text>(find.text('Done task'));
      expect(textWidget.style?.decoration, TextDecoration.lineThrough);
    });
  });

  // ── Restore ────────────────────────────────────────────────────────────────

  group('restore', () {
    testWidgets('unchecking moves task back to active', (tester) async {
      final provider = providerWith(done: 'x 2026-04-13 Restore me\n');
      await tester.pumpWidget(buildTestApp(provider));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Done'));
      await tester.pumpAndSettle();

      // Uncheck the completed task.
      await tester.tap(find.byType(Checkbox).first);
      await tester.pumpAndSettle();

      expect(provider.doneTasks, isEmpty);
      expect(provider.tasks, hasLength(1));
      expect(provider.tasks.first.completed, isFalse);
    });
  });

  // ── Search ─────────────────────────────────────────────────────────────────

  group('search', () {
    testWidgets('search filters done tasks', (tester) async {
      await pumpApp(
        tester,
        done: 'x 2026-04-13 Finished report\nx 2026-04-12 Bought groceries\n',
      );

      final searchField = find.byType(TextField).first;
      await tester.tap(searchField);
      await tester.enterText(searchField, 'report');
      await tester.pumpAndSettle();

      expect(find.text('Finished report'), findsOneWidget);
      expect(find.text('Bought groceries'), findsNothing);
    });
  });
}
