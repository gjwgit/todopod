/// TaskEdit — dialog to add or edit a task.
///
// Time-stamp: <Friday 2026-03-27 10:00:00 +1100 Graham Williams>
///
/// Copyright (C) 2026, Togaware Pty Ltd
///
/// Licensed under the GNU General Public License, Version 3 (the "License");
///
/// License: https://opensource.org/license/gpl-3-0

library;

import 'package:flutter/material.dart';

import 'package:gap/gap.dart';
import 'package:uuid/uuid.dart';

import 'package:todopod/constants/app.dart';
import 'package:todopod/models/task.dart';

const _uuid = Uuid();

class TaskEdit extends StatefulWidget {
  /// The task to edit, or null to create a new task.
  final Task? task;

  const TaskEdit({super.key, this.task});

  @override
  State<TaskEdit> createState() => _TaskEditState();
}

class _TaskEditState extends State<TaskEdit> {
  late final TextEditingController _description;
  late final TextEditingController _duration;
  late String? _priority;
  late DateTime? _dueDate;
  late List<TextEditingController> _projects;
  late List<TextEditingController> _contexts;

  bool get _isNew => widget.task == null;

  @override
  void initState() {
    super.initState();
    final t = widget.task;
    _description = TextEditingController(text: t?.description ?? '');
    _duration = TextEditingController(text: t?.duration ?? '');
    _priority = t?.priority;
    _dueDate = t?.dueDate;
    _projects = (t?.projects ?? [])
        .map((p) => TextEditingController(text: p))
        .toList();
    _contexts = (t?.contexts ?? [])
        .map((c) => TextEditingController(text: c))
        .toList();
  }

  @override
  void dispose() {
    _description.dispose();
    _duration.dispose();
    for (final c in _projects) {
      c.dispose();
    }
    for (final c in _contexts) {
      c.dispose();
    }
    super.dispose();
  }

  Task _buildTask() => Task(
    id: widget.task?.id ?? _uuid.v4(),
    priority: _priority,
    creationDate: widget.task?.creationDate ?? DateTime.now(),
    description: _description.text.trim(),
    projects: _projects
        .map((c) => c.text.trim())
        .where((s) => s.isNotEmpty)
        .toList(),
    contexts: _contexts
        .map((c) => c.text.trim())
        .where((s) => s.isNotEmpty)
        .toList(),
    duration: _duration.text.trim().isEmpty ? null : _duration.text.trim(),
    dueDate: _dueDate,
  );

  Future<void> _pickDueDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _dueDate ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (picked != null) setState(() => _dueDate = picked);
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isWide = MediaQuery.of(context).size.width > 600;

    return Dialog(
      insetPadding: EdgeInsets.symmetric(
        horizontal: isWide ? 60 : 12,
        vertical: 16,
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 560),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 12, 0),
              child: Row(
                children: [
                  Text(
                    _isNew ? 'New Task' : 'Edit Task',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),
            // Form
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Description
                    _sectionLabel(context, 'Description'),
                    const Gap(8),
                    TextField(
                      controller: _description,
                      maxLines: 3,
                      autofocus: _isNew,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        isDense: true,
                        hintText: 'What needs to be done?',
                      ),
                    ),
                    const Gap(16),
                    // Priority + Due Date row
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _sectionLabel(context, 'Priority'),
                              const Gap(8),
                              DropdownButtonFormField<String?>(
                                initialValue: _priority,
                                decoration: const InputDecoration(
                                  border: OutlineInputBorder(),
                                  isDense: true,
                                ),
                                items: [
                                  const DropdownMenuItem(child: Text('None')),
                                  ...priorities.map(
                                    (p) => DropdownMenuItem(
                                      value: p,
                                      child: Text('$p — ${priorityLabels[p]}'),
                                    ),
                                  ),
                                ],
                                onChanged: (v) => setState(() => _priority = v),
                              ),
                            ],
                          ),
                        ),
                        const Gap(12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _sectionLabel(context, 'Due Date'),
                              const Gap(8),
                              InkWell(
                                onTap: _pickDueDate,
                                borderRadius: BorderRadius.circular(4),
                                child: InputDecorator(
                                  decoration: const InputDecoration(
                                    border: OutlineInputBorder(),
                                    isDense: true,
                                    suffixIcon: Icon(
                                      Icons.event_outlined,
                                      size: 18,
                                    ),
                                  ),
                                  child: Text(
                                    _dueDate != null
                                        ? '${_dueDate!.day.toString().padLeft(2, '0')}/'
                                              '${_dueDate!.month.toString().padLeft(2, '0')}/'
                                              '${_dueDate!.year}'
                                        : 'No due date',
                                    style: TextStyle(
                                      color: _dueDate != null
                                          ? null
                                          : cs.onSurfaceVariant,
                                    ),
                                  ),
                                ),
                              ),
                              if (_dueDate != null)
                                TextButton(
                                  onPressed: () =>
                                      setState(() => _dueDate = null),
                                  child: const Text('Clear'),
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const Gap(16),
                    // Duration
                    _sectionLabel(context, 'Duration'),
                    const Gap(8),
                    TextField(
                      controller: _duration,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        isDense: true,
                        hintText: 'e.g. 30m, 1h, 2h30m',
                        prefixText: '= ',
                      ),
                    ),
                    const Gap(16),
                    // Projects
                    _sectionLabel(context, 'Projects'),
                    const Gap(8),
                    ..._projects.asMap().entries.map(
                      (e) => Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Row(
                          children: [
                            const Text('+', style: TextStyle(fontSize: 16)),
                            const Gap(8),
                            Expanded(
                              child: TextField(
                                controller: e.value,
                                decoration: const InputDecoration(
                                  border: OutlineInputBorder(),
                                  isDense: true,
                                  hintText: 'project name',
                                ),
                              ),
                            ),
                            IconButton(
                              icon: const Icon(
                                Icons.remove_circle_outline,
                                size: 18,
                              ),
                              onPressed: () => setState(() {
                                _projects[e.key].dispose();
                                _projects.removeAt(e.key);
                              }),
                            ),
                          ],
                        ),
                      ),
                    ),
                    TextButton.icon(
                      icon: const Icon(Icons.add, size: 16),
                      label: const Text('Add project'),
                      onPressed: () => setState(
                        () => _projects.add(TextEditingController()),
                      ),
                    ),
                    const Gap(16),
                    // Contexts
                    _sectionLabel(context, 'Contexts'),
                    const Gap(8),
                    ..._contexts.asMap().entries.map(
                      (e) => Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Row(
                          children: [
                            const Text('@', style: TextStyle(fontSize: 16)),
                            const Gap(8),
                            Expanded(
                              child: TextField(
                                controller: e.value,
                                decoration: const InputDecoration(
                                  border: OutlineInputBorder(),
                                  isDense: true,
                                  hintText: 'home, office, phone...',
                                ),
                              ),
                            ),
                            IconButton(
                              icon: const Icon(
                                Icons.remove_circle_outline,
                                size: 18,
                              ),
                              onPressed: () => setState(() {
                                _contexts[e.key].dispose();
                                _contexts.removeAt(e.key);
                              }),
                            ),
                          ],
                        ),
                      ),
                    ),
                    TextButton.icon(
                      icon: const Icon(Icons.add, size: 16),
                      label: const Text('Add context'),
                      onPressed: () => setState(
                        () => _contexts.add(TextEditingController()),
                      ),
                    ),
                    const Gap(8),
                  ],
                ),
              ),
            ),
            // Actions
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
              child: Row(
                children: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Cancel'),
                  ),
                  const Spacer(),
                  FilledButton(
                    onPressed: () {
                      if (_description.text.trim().isEmpty) return;
                      Navigator.of(context).pop(_buildTask());
                    },
                    child: Text(_isNew ? 'Add Task' : 'Save'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

Widget _sectionLabel(BuildContext context, String text) => Text(
  text,
  style: TextStyle(
    color: Theme.of(context).colorScheme.primary,
    fontWeight: FontWeight.w600,
    fontSize: 13,
    letterSpacing: 0.5,
  ),
);
