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
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';

import 'package:todopod/constants/app.dart';
import 'package:todopod/models/task.dart';
import 'package:todopod/services/app_provider.dart';

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
  late final TextEditingController _notes;
  late final TextEditingController _duration;
  late String? _priority;
  late DateTime? _dueDate;
  late List<TextEditingController> _projects;
  late List<TextEditingController> _contexts;

  bool get _isNew => widget.task == null;

  // ── Initial state snapshot for change detection ─────────────────────────

  late final String _initDescription;
  late final String _initNotes;
  late final String _initDuration;
  late final String? _initPriority;
  late final DateTime? _initDueDate;
  late final List<String> _initProjects;
  late final List<String> _initContexts;

  @override
  void initState() {
    super.initState();
    final t = widget.task;
    _description = TextEditingController(text: t?.description ?? '');
    _notes = TextEditingController(text: t?.notes ?? '');
    _duration = TextEditingController(text: t?.duration ?? '');
    _priority = t?.priority;
    _dueDate = t?.dueDate;
    _projects = (t?.projects ?? [])
        .map((p) => TextEditingController(text: p))
        .toList();
    _contexts = (t?.contexts ?? [])
        .map((c) => TextEditingController(text: c))
        .toList();

    // Snapshot for change detection.

    _initDescription = _description.text;
    _initNotes = _notes.text;
    _initDuration = _duration.text;
    _initPriority = _priority;
    _initDueDate = _dueDate;
    _initProjects = _projects.map((c) => c.text).toList();
    _initContexts = _contexts.map((c) => c.text).toList();
  }

  @override
  void dispose() {
    _description.dispose();
    _notes.dispose();
    _duration.dispose();
    for (final c in _projects) {
      c.dispose();
    }
    for (final c in _contexts) {
      c.dispose();
    }
    super.dispose();
  }

  // ── Change detection ────────────────────────────────────────────────────

  bool get _hasChanges {
    if (_description.text != _initDescription) return true;
    if (_notes.text != _initNotes) return true;
    if (_duration.text != _initDuration) return true;
    if (_priority != _initPriority) return true;
    if (_dueDate != _initDueDate) return true;

    final curProjects = _projects.map((c) => c.text).toList();
    if (curProjects.length != _initProjects.length) return true;
    for (var i = 0; i < curProjects.length; i++) {
      if (curProjects[i] != _initProjects[i]) return true;
    }

    final curContexts = _contexts.map((c) => c.text).toList();
    if (curContexts.length != _initContexts.length) return true;
    for (var i = 0; i < curContexts.length; i++) {
      if (curContexts[i] != _initContexts[i]) return true;
    }

    return false;
  }

  Future<void> _confirmDiscard() async {
    if (!_hasChanges) {
      Navigator.of(context).pop();

      return;
    }

    final discard = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Discard changes?'),
        content: const Text(
          'You have unsaved changes. Are you sure you want to discard them?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Keep editing'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Discard'),
          ),
        ],
      ),
    );

    if (discard == true && mounted) Navigator.of(context).pop();
  }

  Task _buildTask() => Task(
    id: widget.task?.id ?? _uuid.v4(),
    priority: _priority,
    creationDate: widget.task?.creationDate ?? DateTime.now(),
    description: _description.text.trim(),
    notes: _notes.text.trim().isEmpty ? null : _notes.text.trim(),
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
                    onPressed: _confirmDiscard,
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
                    // Title
                    _sectionLabel(context, 'Title'),
                    const Gap(8),
                    TextField(
                      controller: _description,
                      autofocus: _isNew,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        isDense: true,
                        hintText: 'What needs to be done?',
                      ),
                    ),
                    const Gap(16),
                    // Notes
                    _sectionLabel(context, 'Notes'),
                    const Gap(8),
                    TextField(
                      controller: _notes,
                      maxLines: null,
                      minLines: 3,
                      keyboardType: TextInputType.multiline,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        isDense: true,
                        alignLabelWithHint: true,
                        hintText: 'Details, links, markdown…',
                      ),
                    ),
                    const Gap(16),
                    // Priority + Due Date row
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
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
                              child: _TagAutocomplete(
                                controller: e.value,
                                options: context
                                    .read<AppProvider>()
                                    .allProjects,
                                hintText: 'project name',
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
                              child: _TagAutocomplete(
                                controller: e.value,
                                options: context
                                    .read<AppProvider>()
                                    .allContexts,
                                hintText: 'home, office, phone...',
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
                    onPressed: _confirmDiscard,
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

// ── Autocomplete that suggests existing values but accepts free text ─────────

class _TagAutocomplete extends StatelessWidget {
  final TextEditingController controller;
  final List<String> options;
  final String hintText;

  const _TagAutocomplete({
    required this.controller,
    required this.options,
    required this.hintText,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Autocomplete<String>(
      initialValue: controller.value,
      optionsBuilder: (textEditingValue) {
        final query = textEditingValue.text.toLowerCase();
        if (query.isEmpty) return options;

        return options.where((o) => o.toLowerCase().contains(query)).toList();
      },
      fieldViewBuilder: (context, fieldController, focusNode, onSubmitted) {
        fieldController.addListener(
          () => controller.text = fieldController.text,
        );

        return TextField(
          controller: fieldController,
          focusNode: focusNode,
          decoration: InputDecoration(
            border: const OutlineInputBorder(),
            isDense: true,
            hintText: hintText,
            suffixIcon: options.isNotEmpty
                ? Icon(
                    Icons.arrow_drop_down,
                    size: 18,
                    color: cs.onSurfaceVariant,
                  )
                : null,
            suffixIconConstraints: const BoxConstraints(
              minWidth: 24,
              minHeight: 0,
            ),
          ),
          onSubmitted: (_) => onSubmitted(),
        );
      },
      optionsViewBuilder: (context, onSelected, options) => Align(
        alignment: Alignment.topLeft,
        child: Material(
          elevation: 4,
          borderRadius: BorderRadius.circular(8),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 200, maxWidth: 220),
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 4),
              shrinkWrap: true,
              itemCount: options.length,
              itemBuilder: (context, index) {
                final option = options.elementAt(index);

                return ListTile(
                  dense: true,
                  visualDensity: VisualDensity.compact,
                  title: Text(option, style: const TextStyle(fontSize: 13)),
                  onTap: () => onSelected(option),
                );
              },
            ),
          ),
        ),
      ),
      onSelected: (value) => controller.text = value,
    );
  }
}
