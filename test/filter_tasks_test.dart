/// Tests for the screen-level _filterTasks search logic.
///
/// The filter lives in TasksScreenState but the logic is pure — we test it
/// by extracting it here as a standalone function matching the implementation.
///
library;
// Run: flutter test test/filter_tasks_test.dart

import 'package:flutter_test/flutter_test.dart';

import 'package:todopod/models/task.dart';

// ── Mirror of _filterTasks from tasks_screen.dart ─────────────────────────────
// Keep in sync if the screen implementation changes.

List<Task> filterTasks(List<Task> all, String query) {
  if (query.isEmpty) return all;
  final q = query.trim().toLowerCase();
  final today = DateTime.now();
  final todayDate = DateTime(today.year, today.month, today.day);
  final tomorrowDate = todayDate.add(const Duration(days: 1));
  final weekDate = todayDate.add(const Duration(days: 7));

  if (q.startsWith('context:')) {
    final tag = q.substring('context:'.length).trim();
    return all
        .where((t) => t.contexts.any((c) => c.toLowerCase().contains(tag)))
        .toList();
  }
  if (q.startsWith('project:')) {
    final tag = q.substring('project:'.length).trim();
    return all
        .where((t) => t.projects.any((p) => p.toLowerCase().contains(tag)))
        .toList();
  }
  if (q == 'due:today') {
    return all.where((t) {
      if (t.dueDate == null) return false;
      final d = DateTime(t.dueDate!.year, t.dueDate!.month, t.dueDate!.day);
      return d.isAtSameMomentAs(todayDate);
    }).toList();
  }
  if (q == 'due:past') {
    return all.where((t) {
      if (t.dueDate == null) return false;
      final d = DateTime(t.dueDate!.year, t.dueDate!.month, t.dueDate!.day);
      return d.isBefore(todayDate);
    }).toList();
  }
  if (q == 'due:tomorrow') {
    return all.where((t) {
      if (t.dueDate == null) return false;
      final d = DateTime(t.dueDate!.year, t.dueDate!.month, t.dueDate!.day);
      return d.isAtSameMomentAs(tomorrowDate);
    }).toList();
  }
  if (q == 'due:week') {
    return all.where((t) {
      if (t.dueDate == null) return false;
      final d = DateTime(t.dueDate!.year, t.dueDate!.month, t.dueDate!.day);
      return !d.isBefore(todayDate) && !d.isAfter(weekDate);
    }).toList();
  }
  return all
      .where(
        (t) =>
            t.description.toLowerCase().contains(q) ||
            t.projects.any((p) => p.toLowerCase().contains(q)) ||
            t.contexts.any((c) => c.toLowerCase().contains(q)),
      )
      .toList();
}

// ── Test helpers ──────────────────────────────────────────────────────────────

Task makeTask({
  String description = 'Task',
  List<String> projects = const [],
  List<String> contexts = const [],
  DateTime? dueDate,
}) => Task(
  id: description.hashCode.toString(),
  description: description,
  projects: projects,
  contexts: contexts,
  dueDate: dueDate,
);

final today = DateTime.now();
final todayDate = DateTime(today.year, today.month, today.day);

void main() {
  // ── Empty query ────────────────────────────────────────────────────────────

  test('empty query returns all tasks', () {
    final tasks = [makeTask(description: 'A'), makeTask(description: 'B')];
    expect(filterTasks(tasks, ''), hasLength(2));
  });

  // ── Full-text search ───────────────────────────────────────────────────────

  group('full-text search', () {
    test('matches description substring', () {
      final tasks = [
        makeTask(description: 'Buy milk'),
        makeTask(description: 'Write report'),
      ];
      expect(filterTasks(tasks, 'milk'), hasLength(1));
      expect(filterTasks(tasks, 'milk').first.description, 'Buy milk');
    });

    test('search is case-insensitive', () {
      final tasks = [makeTask(description: 'Important Task')];
      expect(filterTasks(tasks, 'important'), hasLength(1));
      expect(filterTasks(tasks, 'TASK'), hasLength(1));
    });

    test('matches project tag in full-text mode', () {
      final tasks = [
        makeTask(description: 'Task A', projects: ['work']),
        makeTask(description: 'Task B', projects: ['home']),
      ];
      expect(filterTasks(tasks, 'work'), hasLength(1));
    });

    test('matches context tag in full-text mode', () {
      final tasks = [
        makeTask(description: 'Call', contexts: ['phone']),
        makeTask(description: 'Email', contexts: ['email']),
      ];
      expect(filterTasks(tasks, 'phone'), hasLength(1));
    });

    test('no match returns empty list', () {
      final tasks = [makeTask(description: 'Nothing relevant')];
      expect(filterTasks(tasks, 'xyzzy'), isEmpty);
    });
  });

  // ── context: filter ────────────────────────────────────────────────────────

  group('context: filter', () {
    final tasks = [
      makeTask(description: 'Call Alice', contexts: ['phone']),
      makeTask(description: 'Send email', contexts: ['email']),
      makeTask(description: 'Buy food', contexts: ['errands', 'phone']),
    ];

    test('returns tasks with matching context', () {
      final result = filterTasks(tasks, 'context:phone');
      expect(result, hasLength(2));
    });

    test('partial context match works', () {
      final result = filterTasks(tasks, 'context:err');
      expect(result, hasLength(1));
      expect(result.first.description, 'Buy food');
    });

    test('no match returns empty', () {
      expect(filterTasks(tasks, 'context:xyz'), isEmpty);
    });

    test('is case-insensitive', () {
      expect(filterTasks(tasks, 'context:PHONE'), hasLength(2));
    });
  });

  // ── project: filter ────────────────────────────────────────────────────────

  group('project: filter', () {
    final tasks = [
      makeTask(description: 'Write spec', projects: ['work', 'docs']),
      makeTask(description: 'Clean room', projects: ['home']),
      makeTask(description: 'No project'),
    ];

    test('returns tasks with matching project', () {
      expect(filterTasks(tasks, 'project:work'), hasLength(1));
    });

    test('partial project match works', () {
      final result = filterTasks(tasks, 'project:doc');
      expect(result, hasLength(1));
      expect(result.first.description, 'Write spec');
    });

    test('tasks with no projects are excluded', () {
      expect(
        filterTasks(tasks, 'project:work'),
        everyElement(predicate<Task>((t) => t.projects.isNotEmpty)),
      );
    });
  });

  // ── due: filters ───────────────────────────────────────────────────────────

  group('due: filters', () {
    final yesterday = todayDate.subtract(const Duration(days: 1));
    final tomorrow = todayDate.add(const Duration(days: 1));
    final in3Days = todayDate.add(const Duration(days: 3));
    final in10Days = todayDate.add(const Duration(days: 10));

    final tasks = [
      makeTask(description: 'Overdue', dueDate: yesterday),
      makeTask(description: 'Due today', dueDate: todayDate),
      makeTask(description: 'Due tomorrow', dueDate: tomorrow),
      makeTask(description: 'Due in 3 days', dueDate: in3Days),
      makeTask(description: 'Due in 10 days', dueDate: in10Days),
      makeTask(description: 'No due date'),
    ];

    test('due:past returns only overdue tasks', () {
      final result = filterTasks(tasks, 'due:past');
      expect(result, hasLength(1));
      expect(result.first.description, 'Overdue');
    });

    test('due:today returns only today tasks', () {
      final result = filterTasks(tasks, 'due:today');
      expect(result, hasLength(1));
      expect(result.first.description, 'Due today');
    });

    test('due:tomorrow returns only tomorrow tasks', () {
      final result = filterTasks(tasks, 'due:tomorrow');
      expect(result, hasLength(1));
      expect(result.first.description, 'Due tomorrow');
    });

    test('due:week returns today through 7 days inclusive', () {
      final result = filterTasks(tasks, 'due:week');
      // Today, tomorrow, and in 3 days — not overdue, not 10 days out.
      expect(result, hasLength(3));
      final descs = result.map((t) => t.description).toList();
      expect(descs, contains('Due today'));
      expect(descs, contains('Due tomorrow'));
      expect(descs, contains('Due in 3 days'));
    });

    test('due: filters exclude tasks with no due date', () {
      expect(
        filterTasks(tasks, 'due:today').any((t) => t.dueDate == null),
        isFalse,
      );
    });

    test('due:week excludes overdue tasks', () {
      expect(
        filterTasks(tasks, 'due:week').any((t) => t.description == 'Overdue'),
        isFalse,
      );
    });
  });
}
