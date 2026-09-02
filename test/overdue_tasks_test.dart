/// Tests for the Overdue screen data: overdue helpers and overdueTasks.
///
library;

// Run: flutter test test/overdue_tasks_test.dart

import 'package:flutter_test/flutter_test.dart';

import 'package:todopod/models/task.dart';
import 'package:todopod/services/app_provider.dart';
import 'package:todopod/utils/overdue.dart';

void main() {
  // ── Helpers ────────────────────────────────────────────────────────────────

  Task makeTask({
    String? id,
    String description = 'Test task',
    bool completed = false,
    DateTime? dueDate,
  }) => Task(
    id: id ?? 'id-${description.hashCode}',
    completed: completed,
    description: description,
    dueDate: dueDate,
  );

  AppProvider freshProvider() {
    final p = AppProvider();
    p.loadFromContent(todoContent: '', doneContent: '');
    return p;
  }

  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final yesterday = today.subtract(const Duration(days: 1));
  final lastWeek = today.subtract(const Duration(days: 7));
  final tomorrow = today.add(const Duration(days: 1));

  // ── Overdue helpers ────────────────────────────────────────────────────────

  group('daysOverdue', () {
    test('counts whole calendar days late', () {
      expect(daysOverdue(lastWeek), 7);
      expect(daysOverdue(yesterday), 1);
    });

    test('is zero today and negative in the future', () {
      expect(daysOverdue(today), 0);
      expect(daysOverdue(tomorrow), -1);
    });

    test('ignores the time of day', () {
      final ref = DateTime(2026, 7, 26, 23, 59);
      expect(daysOverdue(DateTime(2026, 7, 25, 0, 1), now: ref), 1);
    });
  });

  group('isOverdue', () {
    test('true only for dates strictly before today', () {
      expect(isOverdue(yesterday), isTrue);
      expect(isOverdue(today), isFalse);
      expect(isOverdue(tomorrow), isFalse);
    });

    test('false for a task with no due date', () {
      expect(isOverdue(null), isFalse);
    });
  });

  group('overdueLabel', () {
    test('singular for one day', () {
      expect(overdueLabel(yesterday), '1 day late');
    });

    test('days up to a fortnight, then weeks', () {
      final ref = DateTime(2026, 7, 26);
      expect(overdueLabel(DateTime(2026, 7, 23), now: ref), '3 days late');
      expect(overdueLabel(DateTime(2026, 7, 5), now: ref), '3 weeks late');
    });

    test('empty when not late', () {
      expect(overdueLabel(today), isEmpty);
      expect(overdueLabel(tomorrow), isEmpty);
    });
  });

  // ── Provider getter ────────────────────────────────────────────────────────

  group('overdueTasks', () {
    test('includes only tasks due before today', () {
      final p = freshProvider();
      p.addTask(makeTask(description: 'Late', dueDate: yesterday));
      p.addTask(makeTask(description: 'Due today', dueDate: today));
      p.addTask(makeTask(description: 'Future', dueDate: tomorrow));
      p.addTask(makeTask(description: 'No date'));

      expect(p.overdueTasks.map((t) => t.description), ['Late']);
    });

    test('sorts oldest due date first', () {
      final p = freshProvider();
      p.addTask(makeTask(description: 'Recent', dueDate: yesterday));
      p.addTask(makeTask(description: 'Ancient', dueDate: lastWeek));

      expect(p.overdueTasks.map((t) => t.description), ['Ancient', 'Recent']);
    });

    test('excludes completed tasks even when overdue', () {
      final p = freshProvider();
      p.addTask(makeTask(description: 'Late', dueDate: yesterday));
      p.completeTask(p.tasks.first.id);

      expect(p.overdueTasks, isEmpty);
      expect(p.doneTasks, hasLength(1));
    });

    test('ignores the Tasks screen filters', () {
      final p = freshProvider();
      p.addTask(
        Task(
          id: 'a',
          description: 'Late work task',
          projects: const ['work'],
          dueDate: yesterday,
        ),
      );
      p.addTask(
        Task(id: 'b', description: 'Late untagged task', dueDate: yesterday),
      );
      p.setFilterProject('work');

      expect(p.tasks, hasLength(1));
      expect(p.overdueTasks, hasLength(2));
    });

    test('a task drops off once rescheduled to the future', () {
      final p = freshProvider();
      p.addTask(makeTask(id: 'a', description: 'Late', dueDate: yesterday));
      expect(p.overdueTasks, hasLength(1));

      p.updateTask(p.overdueTasks.first.copyWith(dueDate: tomorrow));
      expect(p.overdueTasks, isEmpty);
    });
  });
}
