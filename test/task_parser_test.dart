/// Tests for the todo.txt parser.
///
library;
// Run: flutter test test/task_parser_test.dart

import 'package:flutter_test/flutter_test.dart';

import 'package:todopod/models/task_parser.dart';

void main() {
  // ── parseTodoTxt ───────────────────────────────────────────────────────────

  group('parseTodoTxt', () {
    test('parses a simple task', () {
      final tasks = parseTodoTxt('Buy milk');
      expect(tasks, hasLength(1));
      expect(tasks.first.description, 'Buy milk');
      expect(tasks.first.completed, isFalse);
      expect(tasks.first.priority, isNull);
    });

    test('parses priority', () {
      final tasks = parseTodoTxt('(A) Urgent thing');
      expect(tasks.first.priority, 'A');
      expect(tasks.first.description, 'Urgent thing');
    });

    test('parses completed task', () {
      final tasks = parseTodoTxt('x 2026-04-13 2026-04-10 Done task');
      expect(tasks.first.completed, isTrue);
      expect(tasks.first.completionDate, DateTime(2026, 4, 13));
      expect(tasks.first.creationDate, DateTime(2026, 4, 10));
      expect(tasks.first.description, 'Done task');
    });

    test('parses projects and contexts', () {
      final tasks = parseTodoTxt('Call Alice +work @phone');
      expect(tasks.first.projects, ['work']);
      expect(tasks.first.contexts, ['phone']);
      expect(tasks.first.description, 'Call Alice');
    });

    test('parses due date', () {
      final tasks = parseTodoTxt('Submit report due:2026-04-30');
      expect(tasks.first.dueDate, DateTime(2026, 4, 30));
      expect(tasks.first.description, 'Submit report');
    });

    test('parses duration', () {
      final tasks = parseTodoTxt('Quick call =30m');
      expect(tasks.first.duration, '30m');
    });

    test('parses creation date', () {
      final tasks = parseTodoTxt('2026-04-01 Task with date');
      expect(tasks.first.creationDate, DateTime(2026, 4, 1));
      expect(tasks.first.description, 'Task with date');
    });

    test('skips blank lines', () {
      final tasks = parseTodoTxt('Task one\n\nTask two\n');
      expect(tasks, hasLength(2));
    });

    test('skips comment lines', () {
      final tasks = parseTodoTxt('# This is a comment\nReal task');
      expect(tasks, hasLength(1));
      expect(tasks.first.description, 'Real task');
    });

    test('parses multi-task file', () {
      const content = '''
(A) 2026-04-01 Urgent task +work @laptop due:2026-04-15
Buy groceries +personal @errands
x 2026-04-10 2026-04-05 Completed thing
''';
      final tasks = parseTodoTxt(content);
      expect(tasks, hasLength(3));
      expect(tasks[0].priority, 'A');
      expect(tasks[0].projects, ['work']);
      expect(tasks[0].contexts, ['laptop']);
      expect(tasks[0].dueDate, DateTime(2026, 4, 15));
      expect(tasks[1].description, 'Buy groceries');
      expect(tasks[2].completed, isTrue);
    });

    test('each parsed task gets a unique id', () {
      final tasks = parseTodoTxt('Task A\nTask B\nTask C');
      final ids = tasks.map((t) => t.id).toSet();
      expect(ids, hasLength(3));
    });

    test('handles multiple projects and contexts', () {
      final tasks = parseTodoTxt('Task +a +b @x @y');
      expect(tasks.first.projects, ['a', 'b']);
      expect(tasks.first.contexts, ['x', 'y']);
    });

    test('invalid due date is ignored', () {
      final tasks = parseTodoTxt('Task due:not-a-date');
      expect(tasks.first.dueDate, isNull);
      // The invalid token becomes part of the description.
      expect(tasks.first.description, contains('Task'));
    });
  });

  // ── Round-trip: parse → toTodoTxt → parse ─────────────────────────────────

  group('round-trip', () {
    test('active task survives parse → toTodoTxt → parse', () {
      const line =
          '(B) 2026-04-01 Write tests +work @laptop due:2026-04-15 =2h';
      final parsed = parseTodoTxt(line).first;
      final reparsed = parseTodoTxt(parsed.toTodoTxt()).first;

      expect(reparsed.priority, parsed.priority);
      expect(reparsed.creationDate, parsed.creationDate);
      expect(reparsed.description, parsed.description);
      expect(reparsed.projects, parsed.projects);
      expect(reparsed.contexts, parsed.contexts);
      expect(reparsed.dueDate, parsed.dueDate);
      expect(reparsed.duration, parsed.duration);
    });

    test('completed task survives round-trip', () {
      const line = 'x 2026-04-13 2026-04-01 Completed task +work';
      final parsed = parseTodoTxt(line).first;
      final reparsed = parseTodoTxt(parsed.toTodoTxt()).first;

      expect(reparsed.completed, isTrue);
      expect(reparsed.completionDate, parsed.completionDate);
      expect(reparsed.creationDate, parsed.creationDate);
      expect(reparsed.description, parsed.description);
      expect(reparsed.projects, parsed.projects);
    });
  });
}
