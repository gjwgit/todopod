/// AppProvider — state management for TodoPod tasks.
///
// Time-stamp: <Friday 2026-03-27 10:00:00 +1100 Graham Williams>
///
/// Copyright (C) 2026, Togaware Pty Ltd
///
/// Licensed under the GNU General Public License, Version 3 (the "License");
///
/// License: https://opensource.org/license/gpl-3-0

library;

import 'dart:convert';

import 'package:flutter/foundation.dart';

import 'package:uuid/uuid.dart';

import 'package:todopod/constants/app.dart';
import 'package:todopod/models/task.dart';
import 'package:todopod/services/pod_service.dart';

const _uuid = Uuid();

/// Sort order for the task list.

enum SortOrder { priority, dueDate, project, context, creationDate, added }

/// App-level state: tasks, done tasks, sort/filter, pod sync.

class AppProvider extends ChangeNotifier {
  List<Task> _tasks = [];
  List<Task> _done = [];
  bool _loading = false;
  String? _error;
  SortOrder _sortOrder = SortOrder.priority;
  String? _filterProject;
  String? _filterContext;
  String? _filterPriority;
  bool _showCompleted = false;

  // ── Getters ───────────────────────────────────────────────────────────────

  bool get loading => _loading;
  String? get error => _error;
  SortOrder get sortOrder => _sortOrder;
  String? get filterProject => _filterProject;
  String? get filterContext => _filterContext;
  String? get filterPriority => _filterPriority;
  bool get showCompleted => _showCompleted;

  List<Task> get tasks => _sorted(_filtered(_tasks));
  List<Task> get doneTasks => _done;

  /// All unique projects across active tasks.
  List<String> get allProjects =>
      _tasks.expand((t) => t.projects).toSet().toList()..sort();

  /// All unique contexts across active tasks.
  List<String> get allContexts =>
      _tasks.expand((t) => t.contexts).toSet().toList()..sort();

  void clearError() {
    _error = null;
    notifyListeners();
  }

  // ── Sort & filter ─────────────────────────────────────────────────────────

  void setSortOrder(SortOrder order) {
    _sortOrder = order;
    notifyListeners();
  }

  void setFilterProject(String? project) {
    _filterProject = project;
    notifyListeners();
  }

  void setFilterContext(String? context) {
    _filterContext = context;
    notifyListeners();
  }

  void setFilterPriority(String? priority) {
    _filterPriority = priority;
    notifyListeners();
  }

  void setShowCompleted(bool show) {
    _showCompleted = show;
    notifyListeners();
  }

  void clearFilters() {
    _filterProject = null;
    _filterContext = null;
    _filterPriority = null;
    notifyListeners();
  }

  List<Task> _filtered(List<Task> tasks) {
    return tasks.where((t) {
      if (_filterProject != null && !t.projects.contains(_filterProject)) {
        return false;
      }
      if (_filterContext != null && !t.contexts.contains(_filterContext)) {
        return false;
      }
      if (_filterPriority != null && t.priority != _filterPriority) {
        return false;
      }
      return true;
    }).toList();
  }

  List<Task> _sorted(List<Task> tasks) {
    final copy = List<Task>.from(tasks);
    switch (_sortOrder) {
      case SortOrder.priority:
        copy.sort((a, b) {
          if (a.priority == null && b.priority == null) return 0;
          if (a.priority == null) return 1;
          if (b.priority == null) return -1;
          return a.priority!.compareTo(b.priority!);
        });
      case SortOrder.dueDate:
        copy.sort((a, b) {
          if (a.dueDate == null && b.dueDate == null) return 0;
          if (a.dueDate == null) return 1;
          if (b.dueDate == null) return -1;
          return a.dueDate!.compareTo(b.dueDate!);
        });
      case SortOrder.project:
        copy.sort((a, b) {
          final ap = a.projects.isNotEmpty ? a.projects.first : '';
          final bp = b.projects.isNotEmpty ? b.projects.first : '';
          return ap.compareTo(bp);
        });
      case SortOrder.context:
        copy.sort((a, b) {
          final ac = a.contexts.isNotEmpty ? a.contexts.first : '';
          final bc = b.contexts.isNotEmpty ? b.contexts.first : '';
          return ac.compareTo(bc);
        });
      case SortOrder.creationDate:
        copy.sort((a, b) {
          if (a.creationDate == null && b.creationDate == null) return 0;
          if (a.creationDate == null) return 1;
          if (b.creationDate == null) return -1;
          return a.creationDate!.compareTo(b.creationDate!);
        });
      case SortOrder.added:
        break; // keep insertion order
    }
    return copy;
  }

  // ── Reordering ──────────────────────────────────────────────────────────

  /// Reorder a task within the visible (sorted + filtered) list.
  ///
  /// When sorted by priority, dragging a task into a different priority
  /// section automatically changes the task's priority to match.

  void reorderTask(int oldIndex, int newIndex) {
    if (oldIndex < newIndex) newIndex--;
    if (oldIndex == newIndex) return;

    final visible = tasks; // sorted + filtered snapshot
    final task = visible[oldIndex];

    // Determine new priority from the drop target's neighbours.

    String? newPriority = task.priority;
    if (_sortOrder == SortOrder.priority) {
      // Build the list as it will look after removing the dragged item.

      final without = List<Task>.from(visible)..removeAt(oldIndex);
      final dropIdx = newIndex.clamp(0, without.length);
      if (dropIdx < without.length) {
        newPriority = without[dropIdx].priority;
      } else if (without.isNotEmpty) {
        newPriority = without.last.priority;
      }
    }

    // Apply new priority if it changed.

    final updated = newPriority != task.priority
        ? task.copyWith(priority: newPriority)
        : task;

    // Rebuild _tasks: remove the moved task, then insert at the correct
    // position relative to the other visible tasks.

    final visibleIds = visible.map((t) => t.id).toList();
    final reordered = List<String>.from(visibleIds)..removeAt(oldIndex);
    reordered.insert(newIndex, updated.id);

    // Partition _tasks into visible (respecting new order) and hidden.

    final taskMap = {for (final t in _tasks) t.id: t};
    taskMap[updated.id] = updated;

    final orderedVisible = reordered.map((id) => taskMap[id]!).toList();
    final hidden = _tasks.where((t) => !reordered.contains(t.id)).toList();

    _tasks = [...orderedVisible, ...hidden];
    notifyListeners();
  }

  // ── CRUD ──────────────────────────────────────────────────────────────────

  void addTask(Task task) {
    _tasks = [task, ..._tasks];
    notifyListeners();
  }

  void updateTask(Task updated) {
    _tasks = [for (final t in _tasks) t.id == updated.id ? updated : t];
    notifyListeners();
  }

  void deleteTask(String id) {
    _tasks = _tasks.where((t) => t.id != id).toList();
    notifyListeners();
  }

  /// Mark a task as complete — moves it from active to done list.
  void completeTask(String id) {
    final task = _tasks.firstWhere((t) => t.id == id);
    _tasks = _tasks.where((t) => t.id != id).toList();
    _done = [
      task.copyWith(completed: true, completionDate: DateTime.now()),
      ..._done,
    ];
    notifyListeners();
  }

  /// Restore a done task back to active.
  void uncompleteTask(String id) {
    final task = _done.firstWhere((t) => t.id == id);
    _done = _done.where((t) => t.id != id).toList();
    _tasks = [task.copyWith(completed: false, completionDate: null), ..._tasks];
    notifyListeners();
  }

  /// Permanently delete a completed task.
  void deleteDoneTask(String id) {
    _done = _done.where((t) => t.id != id).toList();
    notifyListeners();
  }

  /// Permanently delete all completed tasks.
  void clearDone() {
    _done = [];
    notifyListeners();
  }

  void importTasks(List<Task> tasks) {
    // Assign fresh IDs on import to avoid collisions.
    final stamped = tasks.map((t) => t.copyWith(id: _uuid.v4())).toList();
    final (active, done) = (
      stamped.where((t) => !t.completed).toList(),
      stamped.where((t) => t.completed).toList(),
    );
    _tasks = [..._tasks, ...active];
    _done = [..._done, ...done];
    notifyListeners();
  }

  // ── Serialisation ─────────────────────────────────────────────────────────

  String serialiseTasks() => jsonEncode(_tasks.map((t) => t.toJson()).toList());

  String serialiseDone() => jsonEncode(_done.map((t) => t.toJson()).toList());

  // ── Pod sync ──────────────────────────────────────────────────────────────

  Future<void> loadFromPod() async {
    _loading = true;
    _error = null;
    notifyListeners();

    final todo = await PodService.loadTasks(todoFileName);
    final done = await PodService.loadTasks(doneFileName);

    _tasks = todo ?? [];
    _done = done ?? [];
    _loading = false;
    notifyListeners();
  }

  Future<String?> saveTodoToPod() async {
    final err = await PodService.saveTasks(todoFileName, _tasks);
    if (err != null) {
      _error = err;
      notifyListeners();
    }
    return err;
  }

  Future<String?> saveDoneToPod() async {
    final err = await PodService.saveTasks(doneFileName, _done);
    if (err != null) {
      _error = err;
      notifyListeners();
    }
    return err;
  }

  Future<void> saveAllToPod() async {
    await saveTodoToPod();
    await saveDoneToPod();
  }
}
