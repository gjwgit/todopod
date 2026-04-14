/// Tests for the Task model — serialisation, todo.txt format, copyWith.
///
library;
// Run: flutter test test/task_model_test.dart

import 'package:flutter_test/flutter_test.dart';

import 'package:todopod/models/task.dart';

void main() {
  // ── Helpers ────────────────────────────────────────────────────────────────

  Task makeTask({
    String id = 'test-id',
    bool completed = false,
    String? priority,
    String description = 'Test task',
    List<String> projects = const [],
    List<String> contexts = const [],
    DateTime? dueDate,
    String? notes,
    String? duration,
    DateTime? creationDate,
    DateTime? completionDate,
  }) => Task(
    id: id,
    completed: completed,
    priority: priority,
    description: description,
    projects: projects,
    contexts: contexts,
    dueDate: dueDate,
    notes: notes,
    duration: duration,
    creationDate: creationDate,
    completionDate: completionDate,
  );

  // ── toTodoTxt ──────────────────────────────────────────────────────────────

  group('toTodoTxt', () {
    test('simple active task', () {
      final t = makeTask(description: 'Buy milk');
      expect(t.toTodoTxt(), 'Buy milk');
    });

    test('priority prefix', () {
      final t = makeTask(priority: 'A', description: 'Urgent task');
      expect(t.toTodoTxt(), '(A) Urgent task');
    });

    test('completed task with dates', () {
      final t = makeTask(
        completed: true,
        description: 'Done task',
        completionDate: DateTime(2026, 4, 13),
        creationDate: DateTime(2026, 4, 10),
      );
      expect(t.toTodoTxt(), 'x 2026-04-13 2026-04-10 Done task');
    });

    test('projects and contexts', () {
      final t = makeTask(
        description: 'Meet Alice',
        projects: ['work'],
        contexts: ['office'],
      );
      expect(t.toTodoTxt(), 'Meet Alice +work @office');
    });

    test('due date', () {
      final t = makeTask(
        description: 'Submit report',
        dueDate: DateTime(2026, 4, 30),
      );
      expect(t.toTodoTxt(), 'Submit report due:2026-04-30');
    });

    test('duration', () {
      final t = makeTask(description: 'Quick call', duration: '30m');
      expect(t.toTodoTxt(), 'Quick call =30m');
    });

    test('completed task has no priority prefix', () {
      final t = makeTask(
        completed: true,
        priority: 'A',
        description: 'Was urgent',
        completionDate: DateTime(2026, 1, 1),
      );
      // Completed tasks do not show priority.
      expect(t.toTodoTxt(), startsWith('x '));
      expect(t.toTodoTxt(), isNot(contains('(A)')));
    });
  });

  // ── JSON round-trip ────────────────────────────────────────────────────────

  group('JSON round-trip', () {
    test('basic task survives toJson/fromJson', () {
      final original = makeTask(
        priority: 'B',
        description: 'JSON test',
        projects: ['home'],
        contexts: ['evening'],
        dueDate: DateTime(2026, 5, 1),
        duration: '1h',
        notes: 'Some notes',
      );
      final restored = Task.fromJson(original.toJson());
      expect(restored.id, original.id);
      expect(restored.priority, original.priority);
      expect(restored.description, original.description);
      expect(restored.projects, original.projects);
      expect(restored.contexts, original.contexts);
      expect(restored.dueDate, original.dueDate);
      expect(restored.duration, original.duration);
      expect(restored.notes, original.notes);
      expect(restored.completed, original.completed);
    });

    test('completed task round-trips completion date', () {
      final original = makeTask(
        completed: true,
        description: 'Done',
        completionDate: DateTime(2026, 3, 28),
        creationDate: DateTime(2026, 3, 20),
      );
      final restored = Task.fromJson(original.toJson());
      expect(restored.completed, isTrue);
      expect(restored.completionDate, original.completionDate);
      expect(restored.creationDate, original.creationDate);
    });

    test('null optional fields are omitted from JSON', () {
      final t = makeTask(description: 'Minimal');
      final json = t.toJson();
      expect(json.containsKey('priority'), isFalse);
      expect(json.containsKey('notes'), isFalse);
      expect(json.containsKey('dueDate'), isFalse);
      expect(json.containsKey('duration'), isFalse);
    });

    test('fromJson tolerates missing optional fields', () {
      final json = {'id': 'abc', 'completed': false, 'description': 'Bare'};
      final t = Task.fromJson(json);
      expect(t.priority, isNull);
      expect(t.projects, isEmpty);
      expect(t.contexts, isEmpty);
    });
  });

  // ── copyWith ───────────────────────────────────────────────────────────────

  group('copyWith', () {
    test('unchanged fields are preserved', () {
      final original = makeTask(
        priority: 'C',
        description: 'Original',
        projects: ['p1'],
        contexts: ['c1'],
      );
      final copy = original.copyWith(description: 'Updated');
      expect(copy.priority, 'C');
      expect(copy.projects, ['p1']);
      expect(copy.contexts, ['c1']);
      expect(copy.description, 'Updated');
    });

    test('can clear nullable fields with sentinel', () {
      final original = makeTask(priority: 'A', dueDate: DateTime(2026, 4, 1));
      final cleared = original.copyWith(priority: null, dueDate: null);
      expect(cleared.priority, isNull);
      expect(cleared.dueDate, isNull);
    });

    test('completed flag can be toggled', () {
      final active = makeTask(completed: false);
      final done = active.copyWith(completed: true);
      expect(done.completed, isTrue);
      // Original unchanged.
      expect(active.completed, isFalse);
    });

    test('id is preserved when not specified', () {
      final t = makeTask(id: 'unique-123');
      expect(t.copyWith(description: 'New desc').id, 'unique-123');
    });
  });

  // ── displayText ────────────────────────────────────────────────────────────

  group('displayText', () {
    test('includes all tags', () {
      final t = makeTask(
        description: 'Task',
        projects: ['proj'],
        contexts: ['ctx'],
        dueDate: DateTime(2026, 4, 15),
        duration: '2h',
      );
      final text = t.displayText;
      expect(text, contains('+proj'));
      expect(text, contains('@ctx'));
      expect(text, contains('due:2026-04-15'));
      expect(text, contains('=2h'));
    });
  });
}
