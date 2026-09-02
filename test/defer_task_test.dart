/// Tests for deferTask / canDeferTask — the Priority/Due-Date progression.
///
library;

// Run: flutter test test/defer_task_test.dart

import 'package:flutter_test/flutter_test.dart';

import 'package:todopod/models/task.dart';
import 'package:todopod/utils/defer_task.dart';

void main() {
  const base = Task(id: '1', description: 'Task');

  DateTime todayDate() {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day);
  }

  group('canDeferTask', () {
    test('false with no priority set', () {
      expect(canDeferTask(base), isFalse);
    });

    test('false once priority is F', () {
      expect(canDeferTask(base.copyWith(priority: 'F')), isFalse);
    });

    test('true for A through E', () {
      for (final p in ['A', 'B', 'C', 'D', 'E']) {
        expect(canDeferTask(base.copyWith(priority: p)), isTrue);
      }
    });
  });

  group('deferTask', () {
    test('A moves to B, due today', () {
      final updated = deferTask(base.copyWith(priority: 'A'));
      expect(updated.priority, 'B');
      expect(updated.dueDate, todayDate());
    });

    test('B moves to C, due tomorrow', () {
      final updated = deferTask(base.copyWith(priority: 'B'));
      expect(updated.priority, 'C');
      expect(updated.dueDate, todayDate().add(const Duration(days: 1)));
    });

    test('C moves to D, due date pushed out a week', () {
      final due = DateTime(2026, 8, 20);
      final updated = deferTask(base.copyWith(priority: 'C', dueDate: due));
      expect(updated.priority, 'D');
      expect(updated.dueDate, DateTime(2026, 8, 27));
    });

    test('C with no due date pushes a week out from today', () {
      final updated = deferTask(base.copyWith(priority: 'C'));
      expect(updated.priority, 'D');
      expect(updated.dueDate, todayDate().add(const Duration(days: 7)));
    });

    test('D moves to E, due date pushed out a week', () {
      final due = DateTime(2026, 8, 20);
      final updated = deferTask(base.copyWith(priority: 'D', dueDate: due));
      expect(updated.priority, 'E');
      expect(updated.dueDate, DateTime(2026, 8, 27));
    });

    test('E moves to F, due date unchanged', () {
      final due = DateTime(2026, 8, 20);
      final updated = deferTask(base.copyWith(priority: 'E', dueDate: due));
      expect(updated.priority, 'F');
      expect(updated.dueDate, due);
    });

    test('E with no due date stays without one', () {
      final updated = deferTask(base.copyWith(priority: 'E'));
      expect(updated.priority, 'F');
      expect(updated.dueDate, isNull);
    });
  });
}
