/// Tests for showDueDatePickerDialog — Set / No Due Date / Cancel.
///
library;

// Run: flutter test test/due_date_picker_dialog_test.dart

import 'package:flutter/material.dart';

import 'package:flutter_test/flutter_test.dart';

import 'package:todopod/widgets/due_date_picker_dialog.dart';

void main() {
  ({bool cancelled, DateTime? dueDate})? result;

  Future<void> pumpTrigger(WidgetTester tester, {DateTime? initialDate}) async {
    result = null;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () async {
                result = await showDueDatePickerDialog(
                  context,
                  initialDate: initialDate,
                );
              },
              child: const Text('Open'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();
  }

  group('showDueDatePickerDialog', () {
    testWidgets('Set returns the selected date, not cancelled', (tester) async {
      final initial = DateTime(2026, 8, 20);
      await pumpTrigger(tester, initialDate: initial);

      await tester.tap(find.text('Set'));
      await tester.pumpAndSettle();

      expect(result!.cancelled, isFalse);
      expect(result!.dueDate, initial);
    });

    testWidgets('No Due Date returns null dueDate, not cancelled', (
      tester,
    ) async {
      await pumpTrigger(tester, initialDate: DateTime(2026, 8, 20));

      await tester.tap(find.text('No Due Date'));
      await tester.pumpAndSettle();

      expect(result!.cancelled, isFalse);
      expect(result!.dueDate, isNull);
    });

    testWidgets('Cancel is reported as cancelled', (tester) async {
      await pumpTrigger(tester, initialDate: DateTime(2026, 8, 20));

      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      expect(result!.cancelled, isTrue);
    });
  });
}
