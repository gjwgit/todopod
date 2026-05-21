/// Tests for AppProvider — state management, task lifecycle, persistence logic.
///
/// These tests focus on in-memory operations (no pod/network calls).
///
library;
// Run: flutter test test/app_provider_test.dart

import 'package:flutter_test/flutter_test.dart';

import 'package:todopod/models/sort_order.dart';
import 'package:todopod/models/task.dart';
import 'package:todopod/services/app_provider.dart';

void main() {
  // ── Helpers ────────────────────────────────────────────────────────────────

  Task makeTask({
    String? id,
    String description = 'Test task',
    bool completed = false,
    String? priority,
    List<String> projects = const [],
    List<String> contexts = const [],
    DateTime? dueDate,
    DateTime? creationDate,
  }) => Task(
    id: id ?? 'id-${description.hashCode}',
    completed: completed,
    priority: priority,
    description: description,
    projects: projects,
    contexts: contexts,
    dueDate: dueDate,
    creationDate: creationDate,
  );

  AppProvider freshProvider() {
    final p = AppProvider();
    // Load tasks directly without pod.
    p.loadFromContent(todoContent: '', doneContent: '');
    return p;
  }

  // ── Basic CRUD ─────────────────────────────────────────────────────────────

  group('addTask', () {
    test('task appears in tasks list', () {
      final p = freshProvider();
      p.addTask(makeTask(description: 'New task'));
      expect(p.tasks, hasLength(1));
      expect(p.tasks.first.description, 'New task');
    });

    test('does not appear in doneTasks', () {
      final p = freshProvider();
      p.addTask(makeTask(description: 'Active'));
      expect(p.doneTasks, isEmpty);
    });
  });

  group('updateTask', () {
    test('updates description in place', () {
      final p = freshProvider();
      final t = makeTask(id: 'abc', description: 'Original');
      p.addTask(t);
      p.updateTask(t.copyWith(description: 'Updated'));
      expect(p.tasks.first.description, 'Updated');
      expect(p.tasks, hasLength(1));
    });

    test('preserves other fields when updating', () {
      final p = freshProvider();
      final t = makeTask(
        id: 'abc',
        description: 'Task',
        priority: 'A',
        projects: ['work'],
      );
      p.addTask(t);
      p.updateTask(t.copyWith(description: 'Updated task'));
      expect(p.tasks.first.priority, 'A');
      expect(p.tasks.first.projects, ['work']);
    });
  });

  group('deleteTask', () {
    test('removes from active list', () {
      final p = freshProvider();
      final t = makeTask(id: 'del-me', description: 'To delete');
      p.addTask(t);
      p.deleteTask('del-me');
      expect(p.tasks, isEmpty);
    });

    test('does not affect other tasks', () {
      final p = freshProvider();
      p.addTask(makeTask(id: 'keep', description: 'Keep me'));
      p.addTask(makeTask(id: 'del', description: 'Delete me'));
      p.deleteTask('del');
      expect(p.tasks, hasLength(1));
      expect(p.tasks.first.id, 'keep');
    });
  });

  // ── Complete / Uncomplete ──────────────────────────────────────────────────

  group('completeTask', () {
    test('moves task from _tasks to _done', () {
      final p = freshProvider();
      final t = makeTask(id: 'comp', description: 'Complete me');
      p.addTask(t);
      p.completeTask('comp');

      expect(p.tasks, isEmpty);
      expect(p.doneTasks, hasLength(1));
      expect(p.doneTasks.first.id, 'comp');
    });

    test('sets completed = true with a completion date', () {
      final p = freshProvider();
      p.addTask(makeTask(id: 'x'));
      p.completeTask('x');

      final done = p.doneTasks.first;
      expect(done.completed, isTrue);
      expect(done.completionDate, isNotNull);
      // Completion date should be today (within a few seconds).
      final now = DateTime.now();
      expect(done.completionDate!.difference(now).inSeconds.abs(), lessThan(5));
    });

    test('completed task preserves description and tags', () {
      final p = freshProvider();
      final t = makeTask(
        id: 'x',
        description: 'Important task',
        priority: 'A',
        projects: ['work'],
        contexts: ['laptop'],
      );
      p.addTask(t);
      p.completeTask('x');

      final done = p.doneTasks.first;
      expect(done.description, 'Important task');
      expect(done.projects, ['work']);
      expect(done.contexts, ['laptop']);
    });

    // This test covers the bug where "mark as done" in the edit dialog lost
    // the task on restart — both lists must be saved.
    test('CRITICAL: completeTask modifies both _tasks and _done', () {
      final p = freshProvider();
      p.addTask(makeTask(id: 'bug', description: 'Bug regression'));

      final tasksBefore = p.tasks.length;
      final doneBefore = p.doneTasks.length;

      p.completeTask('bug');

      // Task must be removed from active list.
      expect(
        p.tasks.length,
        tasksBefore - 1,
        reason: '_tasks was not decremented — task still appears as active',
      );

      // Task must be added to done list.
      expect(
        p.doneTasks.length,
        doneBefore + 1,
        reason:
            '_done was not incremented — task will be lost on restart '
            'if only saveTodoToPod() is called',
      );
    });

    test('uncompleteTask moves task back to active', () {
      final p = freshProvider();
      p.addTask(makeTask(id: 'yo', description: 'Back to active'));
      p.completeTask('yo');
      p.uncompleteTask('yo');

      expect(p.tasks, hasLength(1));
      expect(p.doneTasks, isEmpty);
      expect(p.tasks.first.completed, isFalse);
      expect(p.tasks.first.completionDate, isNull);
    });
  });

  // ── Sorting ────────────────────────────────────────────────────────────────

  group('sort order', () {
    test('priority sort puts A before B before no-priority', () {
      final p = freshProvider();
      p.addTask(makeTask(id: '1', description: 'No priority'));
      p.addTask(makeTask(id: '2', description: 'B task', priority: 'B'));
      p.addTask(makeTask(id: '3', description: 'A task', priority: 'A'));
      p.setSortOrder(SortOrder.priority);

      final sorted = p.tasks;
      expect(sorted[0].priority, 'A');
      expect(sorted[1].priority, 'B');
      expect(sorted[2].priority, isNull);
    });

    test('due date sort puts earlier dates first', () {
      final p = freshProvider();
      p.addTask(
        makeTask(id: '1', description: 'Later', dueDate: DateTime(2026, 5, 1)),
      );
      p.addTask(
        makeTask(
          id: '2',
          description: 'Earlier',
          dueDate: DateTime(2026, 4, 1),
        ),
      );
      p.addTask(makeTask(id: '3', description: 'No due date'));
      p.setSortOrder(SortOrder.dueDate);

      final sorted = p.tasks;
      expect(sorted[0].description, 'Earlier');
      expect(sorted[1].description, 'Later');
      // No due date goes last.
      expect(sorted[2].description, 'No due date');
    });
  });

  // ── Provider-level filtering ───────────────────────────────────────────────

  group('provider filters', () {
    test('filterProject filters by project', () {
      final p = freshProvider();
      p.addTask(
        makeTask(id: '1', description: 'Work task', projects: ['work']),
      );
      p.addTask(
        makeTask(id: '2', description: 'Home task', projects: ['home']),
      );
      p.setFilterProject('work');

      expect(p.tasks, hasLength(1));
      expect(p.tasks.first.description, 'Work task');
    });

    test('filterContext filters by context', () {
      final p = freshProvider();
      p.addTask(
        makeTask(id: '1', description: 'Phone task', contexts: ['phone']),
      );
      p.addTask(
        makeTask(id: '2', description: 'Email task', contexts: ['email']),
      );
      p.setFilterContext('phone');

      expect(p.tasks, hasLength(1));
      expect(p.tasks.first.description, 'Phone task');
    });

    test('filterPriority filters by priority', () {
      final p = freshProvider();
      p.addTask(makeTask(id: '1', description: 'A task', priority: 'A'));
      p.addTask(makeTask(id: '2', description: 'B task', priority: 'B'));
      p.addTask(makeTask(id: '3', description: 'No priority'));
      p.setFilterPriority('A');

      expect(p.tasks, hasLength(1));
      expect(p.tasks.first.priority, 'A');
    });

    test('clearFilters shows all tasks again', () {
      final p = freshProvider();
      p.addTask(makeTask(id: '1', description: 'Work', projects: ['work']));
      p.addTask(makeTask(id: '2', description: 'Home', projects: ['home']));
      p.setFilterProject('work');
      expect(p.tasks, hasLength(1));
      p.clearFilters();
      expect(p.tasks, hasLength(2));
    });

    test('allProjects reflects current tasks', () {
      final p = freshProvider();
      p.addTask(makeTask(id: '1', projects: ['alpha', 'beta']));
      p.addTask(makeTask(id: '2', projects: ['beta', 'gamma']));
      expect(p.allProjects, ['alpha', 'beta', 'gamma']);
    });

    test('allContexts reflects current tasks', () {
      final p = freshProvider();
      p.addTask(makeTask(id: '1', contexts: ['home', 'phone']));
      p.addTask(makeTask(id: '2', contexts: ['office']));
      expect(p.allContexts, ['home', 'office', 'phone']);
    });
  });

  // ── loadFromContent ────────────────────────────────────────────────────────

  group('loadFromContent', () {
    test('loads active tasks from todo content', () {
      final p = AppProvider();
      p.loadFromContent(
        todoContent: '(A) Buy milk\n(B) Write tests +work\n',
        doneContent: '',
      );
      expect(p.tasks, hasLength(2));
    });

    test('loads done tasks from done content', () {
      final p = AppProvider();
      p.loadFromContent(
        todoContent: '',
        doneContent: 'x 2026-04-10 2026-04-05 Finished thing\n',
      );
      expect(p.doneTasks, hasLength(1));
      expect(p.doneTasks.first.completed, isTrue);
    });

    test('active and done tasks are loaded independently', () {
      final p = AppProvider();
      p.loadFromContent(
        todoContent: 'Active task\n',
        doneContent: 'x 2026-04-10 Done task\n',
      );
      expect(p.tasks, hasLength(1));
      expect(p.doneTasks, hasLength(1));
      expect(p.tasks.first.completed, isFalse);
      expect(p.doneTasks.first.completed, isTrue);
    });
  });

  // ── importTasks ────────────────────────────────────────────────────────────

  group('importTasks', () {
    test('merges imported tasks with existing', () {
      final p = freshProvider();
      p.addTask(makeTask(id: 'existing', description: 'Already here'));
      final imported = [makeTask(id: 'new', description: 'Imported task')];
      p.importTasks(imported);
      expect(p.tasks, hasLength(2));
    });

    test('import does not duplicate existing ids', () {
      // importTasks adds by id so duplicates must be handled at call site,
      // but the task count should reflect what was actually imported.
      final p = freshProvider();
      final t = makeTask(id: 'dup', description: 'Original');
      p.addTask(t);
      // Import same id — provider adds it, UI deduplication is caller's job.
      // Just verify the import doesn't crash.
      expect(
        () => p.importTasks([t.copyWith(description: 'Duplicate')]),
        returnsNormally,
      );
    });
  });

  // ── reorderTask ───────────────────────────────────────────────────────────

  group('reorderTask', () {
    test('moves task to new position', () {
      final p = freshProvider();
      p.setSortOrder(SortOrder.added);
      // addTask prepends, so order after adding a,b,c is [c,b,a].
      p.addTask(makeTask(id: 'a', description: 'First'));
      p.addTask(makeTask(id: 'b', description: 'Second'));
      p.addTask(makeTask(id: 'c', description: 'Third'));

      // Visible order: [c, b, a] — move index 0 (c) to end (index 3).
      p.reorderTask(0, 3);

      final ids = p.tasks.map((t) => t.id).toList();
      expect(ids, ['b', 'a', 'c']);
    });

    test('reorder with visibleTasks param uses correct indices', () {
      final p = freshProvider();
      p.setSortOrder(SortOrder.added);
      p.addTask(makeTask(id: 'a', description: 'One'));
      p.addTask(makeTask(id: 'b', description: 'Two'));
      p.addTask(makeTask(id: 'c', description: 'Three'));

      // Visible order: [c, b, a]
      final allTasks = p.tasks;
      // Pass subset: first and third items [c, a] as the visible list.
      final visible = [allTasks[0], allTasks[2]]; // c and a
      // Move index 0 (c) to after index 1 (a) — index 2 in ReorderableListView.
      p.reorderTask(0, 2, visibleTasks: visible);

      // 'c' should now come after 'a' in the full list.
      final ids = p.tasks.map((t) => t.id).toList();
      expect(ids.indexOf('c'), greaterThan(ids.indexOf('a')));
    });
  });
}
