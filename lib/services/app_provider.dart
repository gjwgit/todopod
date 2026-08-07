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
import 'package:todopod/models/sort_order.dart';
import 'package:todopod/models/task.dart';
import 'package:todopod/models/task_parser.dart';
import 'package:todopod/services/pod_service.dart';
import 'package:todopod/utils/overdue.dart';

const _uuid = Uuid();

/// Phases of app startup, used to show phase-aware busy feedback while the Pod
/// is unlocked and the initial data is pulled.
enum StartupPhase { idle, unlocking, loading, ready }

/// App-level state: tasks, done tasks, sort/filter, pod sync.

class AppProvider extends ChangeNotifier {
  List<Task> _tasks = [];
  List<Task> _done = [];
  bool _loading = false;
  bool _isKeySaved = false;
  String? _error;
  SortOrder _sortOrder = SortOrder.priority;
  String? _filterProject;
  String? _filterContext;
  String? _filterPriority;
  bool _showCompleted = false;

  // Startup progress, so the UI can show phase-aware busy feedback while the
  // app unlocks the Pod (security key) and then pulls data. Reusable pattern.
  StartupPhase _startupPhase = StartupPhase.idle;

  // ── Getters ───────────────────────────────────────────────────────────────

  bool get loading => _loading;
  StartupPhase get startupPhase => _startupPhase;

  /// True while the app is unlocking the Pod or loading initial data.
  bool get isStartingUp =>
      _startupPhase == StartupPhase.unlocking ||
      _startupPhase == StartupPhase.loading;

  /// Single source of truth for "show a busy indicator, not content". True
  /// during the security-key unlock phase, the initial load, AND any later
  /// load. Screens should branch on this (not [loading]) so the empty state
  /// never flashes between startup phases.
  bool get busy => _loading || isStartingUp;

  /// Sets the current startup phase and notifies listeners.
  void setStartupPhase(StartupPhase phase) {
    _startupPhase = phase;
    notifyListeners();
  }

  bool get isKeySaved => _isKeySaved;
  String? get error => _error;
  SortOrder get sortOrder => _sortOrder;
  String? get filterProject => _filterProject;
  String? get filterContext => _filterContext;
  String? get filterPriority => _filterPriority;
  bool get showCompleted => _showCompleted;

  /// Update the security-key saved state. Notifies listeners so the
  /// status bar badge in [AppScaffold] re-renders.
  void setKeySaved(bool saved) {
    if (_isKeySaved == saved) return;
    _isKeySaved = saved;
    notifyListeners();
  }

  List<Task> get tasks => _sorted(_filtered(_tasks));
  List<Task> get doneTasks => _done;

  /// Active tasks whose due date has already passed, earliest due date first.
  ///
  /// Drives the Overdue screen. Deliberately built from the raw active list and
  /// NOT from [tasks], so the Tasks screen's current sort and filter choices
  /// can never hide overdue work. Completed tasks are excluded — once done, a
  /// task belongs on the Done screen regardless of its due date.

  List<Task> get overdueTasks =>
      _tasks.where((t) => isOverdue(t.dueDate)).toList()
        ..sort((a, b) => a.dueDate!.compareTo(b.dueDate!));

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
    if (_sortOrder == SortOrder.added) return copy;

    copy.sort((a, b) {
      // Primary sort based on selected order.

      final primary = _primaryCompare(a, b);
      if (primary != 0) return primary;

      // Secondary: due date (earliest first, null last).

      final dueCmp = _compareDueDate(a, b);
      if (dueCmp != 0) return dueCmp;

      // Tertiary: alphabetic by description.

      return a.description.toLowerCase().compareTo(b.description.toLowerCase());
    });

    return copy;
  }

  int _primaryCompare(Task a, Task b) {
    switch (_sortOrder) {
      case SortOrder.priority:
        if (a.priority == null && b.priority == null) return 0;
        if (a.priority == null) return 1;
        if (b.priority == null) return -1;
        return a.priority!.compareTo(b.priority!);
      case SortOrder.dueDate:
        return _compareDueDate(a, b);
      case SortOrder.project:
        final ap = a.projects.isNotEmpty ? a.projects.first : '';
        final bp = b.projects.isNotEmpty ? b.projects.first : '';
        return ap.compareTo(bp);
      case SortOrder.context:
        final ac = a.contexts.isNotEmpty ? a.contexts.first : '';
        final bc = b.contexts.isNotEmpty ? b.contexts.first : '';
        return ac.compareTo(bc);
      case SortOrder.creationDate:
        if (a.creationDate == null && b.creationDate == null) return 0;
        if (a.creationDate == null) return 1;
        if (b.creationDate == null) return -1;
        return a.creationDate!.compareTo(b.creationDate!);
      case SortOrder.added:
        return 0;
    }
  }

  static int _compareDueDate(Task a, Task b) {
    if (a.dueDate == null && b.dueDate == null) return 0;
    if (a.dueDate == null) return 1;
    if (b.dueDate == null) return -1;

    return a.dueDate!.compareTo(b.dueDate!);
  }

  // ── Reordering ──────────────────────────────────────────────────────────

  /// Reorder a task within the visible (sorted + filtered) list.
  ///
  /// When sorted by priority, dragging a task into a different priority
  /// section automatically changes the task's priority to match.

  void reorderTask(int oldIndex, int newIndex, {List<Task>? visibleTasks}) {
    // The screen wires this to ReorderableListView's onReorderItem, which
    // (unlike the deprecated onReorder) already adjusts newIndex for the
    // removed item — do not subtract 1 again here.
    if (oldIndex == newIndex) return;

    // Use the caller-supplied visible list (which may be further filtered by
    // the screen's own search query) so indices always match the displayed list.
    final visible = visibleTasks ?? tasks;
    final task = visible[oldIndex];

    // Determine new priority from the drop target's neighbours.
    //
    // Use the item ABOVE the insertion point — this is the tail of the group
    // the user is dragging into.  When dropping at the very top (no item
    // above), fall back to the item below.

    String? newPriority = task.priority;
    if (_sortOrder == SortOrder.priority) {
      // Build the list as it will look after removing the dragged item.

      final without = List<Task>.from(visible)..removeAt(oldIndex);
      final dropIdx = newIndex.clamp(0, without.length);

      if (dropIdx > 0) {
        newPriority = without[dropIdx - 1].priority;
      } else if (without.isNotEmpty) {
        newPriority = without.first.priority;
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
    if (updated.completed) {
      // Treat an update that flips completed to true as a complete-and-move:
      // never leave a completed task in the active _tasks list.
      _tasks = _tasks.where((t) => t.id != updated.id).toList();
      final stamped = updated.completionDate == null
          ? updated.copyWith(completionDate: DateTime.now())
          : updated;
      // Replace if already in _done, otherwise prepend.
      if (_done.any((t) => t.id == updated.id)) {
        _done = [for (final t in _done) t.id == updated.id ? stamped : t];
      } else {
        _done = [stamped, ..._done];
      }
    } else {
      _tasks = [for (final t in _tasks) t.id == updated.id ? updated : t];
    }
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

  /// Load tasks directly from content strings — used in tests to avoid
  /// requiring a live Solid Pod connection.
  void loadFromContent({
    required String todoContent,
    required String doneContent,
  }) {
    _testMode = true;
    final todo = todoContent.isEmpty ? <Task>[] : parseTodoTxt(todoContent);
    final done = doneContent.isEmpty ? <Task>[] : parseTodoTxt(doneContent);
    final all = [...todo, ...done];
    _tasks = all.where((t) => !t.completed).toList();
    _done = all.where((t) => t.completed).toList();
    _loading = false;
    notifyListeners();
  }

  /// Reusable "refresh from Pod" pattern: snapshot a signature, reload, compare.
  /// Returns true if the data changed (Pod was updated elsewhere), false if
  /// already current.
  Future<bool> refreshFromPod() async {
    if (_testMode) return false;
    final before = _tasksSignature();
    await loadFromPod();
    return _tasksSignature() != before;
  }

  /// Stable content signature for change detection.
  String _tasksSignature() => [
    ..._tasks,
    ..._done,
  ].map((t) => '${t.id}:${t.completed}:${t.description}').join(',');

  Future<void> loadFromPod() async {
    _loading = true;
    _error = null;
    notifyListeners();

    try {
      final todo = await PodService.loadTasks(todoFileName);
      final done = await PodService.loadTasks(doneFileName);

      // Partition by completion status so that a completed task in todo.ttl,
      // or an active task in done.ttl, ends up in the correct list. Bad data
      // from earlier bugs (or hand-edited Pod files) is self-healed on load
      // and re-saved correctly on the next save.
      final all = [...?todo, ...?done];
      _tasks = all.where((t) => !t.completed).toList();
      _done = all.where((t) => t.completed).toList();
    } catch (e) {
      _error = 'Could not load tasks from Pod.';
      debugPrint('[AppProvider] loadFromPod error: $e');
    } finally {
      // Always clear loading so the UI can't hang on the busy indicator.
      _loading = false;
      notifyListeners();
    }
  }

  /// When true, all pod save operations are silently skipped.
  /// Set via [loadFromContent] to keep test output clean.
  bool _testMode = false;

  Future<String?> saveTodoToPod() async {
    if (_testMode) return null;
    final err = await PodService.saveTasks(todoFileName, _tasks);
    if (err != null) {
      _error = err;
      notifyListeners();
    }
    return err;
  }

  Future<String?> saveDoneToPod() async {
    if (_testMode) return null;
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
