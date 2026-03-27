/// Task — the core data model for a todo.txt task.
///
// Time-stamp: <Friday 2026-03-27 10:00:00 +1100 Graham Williams>
///
/// Copyright (C) 2026, Togaware Pty Ltd
///
/// Licensed under the GNU General Public License, Version 3 (the "License");
///
/// License: https://opensource.org/license/gpl-3-0

library;

import 'package:todopod/constants/app.dart';

/// A single task in todo.txt format.
///
/// Todo.txt format:
///   (A) 2026-03-27 description +project @context due:2026-03-28 =30m
///   x 2026-03-28 2026-03-27 completed description

class Task {
  final String id;
  final bool completed;
  final String? priority;
  final DateTime? completionDate;
  final DateTime? creationDate;
  final String description;
  final List<String> projects;
  final List<String> contexts;
  final String? duration;
  final DateTime? dueDate;

  const Task({
    required this.id,
    this.completed = false,
    this.priority,
    this.completionDate,
    this.creationDate,
    required this.description,
    this.projects = const [],
    this.contexts = const [],
    this.duration,
    this.dueDate,
  });

  // ── Derived properties ────────────────────────────────────────────────────

  /// Human-readable priority label.
  String get priorityLabel =>
      priority != null ? (priorityLabels[priority] ?? priority!) : '';

  /// Full display text including all tags.
  String get displayText {
    final parts = [description];
    for (final p in projects) parts.add('+$p');
    for (final c in contexts) parts.add('@$c');
    if (dueDate != null) {
      parts.add(
        'due:${dueDate!.year}-'
        '${dueDate!.month.toString().padLeft(2, '0')}-'
        '${dueDate!.day.toString().padLeft(2, '0')}',
      );
    }
    if (duration != null) parts.add('=$duration');
    return parts.join(' ');
  }

  /// Serialise to todo.txt line.
  String toTodoTxt() {
    final buf = StringBuffer();
    if (completed) {
      buf.write('x ');
      if (completionDate != null) buf.write('${_fmtDate(completionDate!)} ');
    } else if (priority != null) {
      buf.write('($priority) ');
    }
    if (creationDate != null) buf.write('${_fmtDate(creationDate!)} ');
    buf.write(description);
    for (final p in projects) buf.write(' +$p');
    for (final c in contexts) buf.write(' @$c');
    if (dueDate != null) buf.write(' due:${_fmtDate(dueDate!)}');
    if (duration != null) buf.write(' =$duration');
    return buf.toString();
  }

  String _fmtDate(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-'
      '${d.day.toString().padLeft(2, '0')}';

  // ── Serialisation ─────────────────────────────────────────────────────────

  Map<String, dynamic> toJson() => {
        'id': id,
        'completed': completed,
        if (priority != null) 'priority': priority,
        if (completionDate != null)
          'completionDate': completionDate!.toIso8601String(),
        if (creationDate != null)
          'creationDate': creationDate!.toIso8601String(),
        'description': description,
        if (projects.isNotEmpty) 'projects': projects,
        if (contexts.isNotEmpty) 'contexts': contexts,
        if (duration != null) 'duration': duration,
        if (dueDate != null) 'dueDate': dueDate!.toIso8601String(),
      };

  factory Task.fromJson(Map<String, dynamic> j) => Task(
        id: j['id'] as String,
        completed: j['completed'] as bool? ?? false,
        priority: j['priority'] as String?,
        completionDate: j['completionDate'] != null
            ? DateTime.parse(j['completionDate'] as String)
            : null,
        creationDate: j['creationDate'] != null
            ? DateTime.parse(j['creationDate'] as String)
            : null,
        description: j['description'] as String,
        projects: (j['projects'] as List?)?.cast<String>() ?? [],
        contexts: (j['contexts'] as List?)?.cast<String>() ?? [],
        duration: j['duration'] as String?,
        dueDate: j['dueDate'] != null
            ? DateTime.parse(j['dueDate'] as String)
            : null,
      );

  Task copyWith({
    String? id,
    bool? completed,
    Object? priority = _sentinel,
    Object? completionDate = _sentinel,
    Object? creationDate = _sentinel,
    String? description,
    List<String>? projects,
    List<String>? contexts,
    Object? duration = _sentinel,
    Object? dueDate = _sentinel,
  }) =>
      Task(
        id: id ?? this.id,
        completed: completed ?? this.completed,
        priority: priority == _sentinel
            ? this.priority
            : priority as String?,
        completionDate: completionDate == _sentinel
            ? this.completionDate
            : completionDate as DateTime?,
        creationDate: creationDate == _sentinel
            ? this.creationDate
            : creationDate as DateTime?,
        description: description ?? this.description,
        projects: projects ?? this.projects,
        contexts: contexts ?? this.contexts,
        duration:
            duration == _sentinel ? this.duration : duration as String?,
        dueDate: dueDate == _sentinel ? this.dueDate : dueDate as DateTime?,
      );
}

const _sentinel = Object();
