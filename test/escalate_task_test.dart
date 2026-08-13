/// Tests for escalateTask / canEscalateTask — the reverse Priority/Due-Date
/// progression.
///
library;
// Run: flutter test test/escalate_task_test.dart

import 'package:flutter_test/flutter_test.dart';

import 'package:todopod/models/task.dart';
import 'package:todopod/utils/escalate_task.dart';

void main() {
  const base = Task(id: '1', description: 'Task');

  DateTime todayDate() {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day);
  }

  group('canEscalateTask', () {
    test('false with no priority set', () {
      expect(canEscalateTask(base), isFalse);
    });

    test('false once priority is A', () {
      expect(canEscalateTask(base.copyWith(priority: 'A')), isFalse);
    });

    test('true for B through F', () {
      for (final p in ['B', 'C', 'D', 'E', 'F']) {
        expect(canEscalateTask(base.copyWith(priority: p)), isTrue);
      }
    });
  });

  group('escalateTask', () {
    test('B moves to A, due today', () {
      final updated = escalateTask(base.copyWith(priority: 'B'));
      expect(updated.priority, 'A');
      expect(updated.dueDate, todayDate());
    });

    test('C moves to B, due today', () {
      final updated = escalateTask(base.copyWith(priority: 'C'));
      expect(updated.priority, 'B');
      expect(updated.dueDate, todayDate());
    });

    test('D moves to C, due date unchanged', () {
      final due = DateTime(2026, 8, 20);
      final updated = escalateTask(base.copyWith(priority: 'D', dueDate: due));
      expect(updated.priority, 'C');
      expect(updated.dueDate, due);
    });

    test('E moves to D, due date unchanged', () {
      final due = DateTime(2026, 8, 20);
      final updated = escalateTask(base.copyWith(priority: 'E', dueDate: due));
      expect(updated.priority, 'D');
      expect(updated.dueDate, due);
    });

    test('F moves to E, due date unchanged', () {
      final due = DateTime(2026, 8, 20);
      final updated = escalateTask(base.copyWith(priority: 'F', dueDate: due));
      expect(updated.priority, 'E');
      expect(updated.dueDate, due);
    });

    test('D with no due date stays without one', () {
      final updated = escalateTask(base.copyWith(priority: 'D'));
      expect(updated.priority, 'C');
      expect(updated.dueDate, isNull);
    });
  });
}
