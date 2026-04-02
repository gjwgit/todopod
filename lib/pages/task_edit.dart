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

import 'package:todopod/models/task.dart';
import 'package:todopod/pages/task_edit_form_fields.dart';
import 'package:todopod/services/app_provider.dart';
import 'package:todopod/widgets/tag_autocomplete.dart';

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
    for (final c in [..._projects, ..._contexts]) {
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
    if (!_listEquals(_projects, _initProjects)) return true;
    if (!_listEquals(_contexts, _initContexts)) return true;

    return false;
  }

  bool _listEquals(List<TextEditingController> ctrls, List<String> init) {
    if (ctrls.length != init.length) return false;
    for (var i = 0; i < ctrls.length; i++) {
      if (ctrls[i].text != init[i]) return false;
    }

    return true;
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

  // ── Build ───────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
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
            _buildHeader(context),
            _buildForm(context),
            _buildActions(context),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(20, 16, 12, 0),
    child: Row(
      children: [
        Text(
          _isNew ? 'New Task' : 'Edit Task',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const Spacer(),
        IconButton(icon: const Icon(Icons.close), onPressed: _confirmDiscard),
      ],
    ),
  );

  Widget _buildForm(BuildContext context) => Flexible(
    child: SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          editSectionLabel(context, 'Title'),
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
          editSectionLabel(context, 'Notes'),
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
          PriorityDueDateRow(
            priority: _priority,
            dueDate: _dueDate,
            onPriorityChanged: (v) => setState(() => _priority = v),
            onPickDueDate: _pickDueDate,
            onClearDueDate: () => setState(() => _dueDate = null),
          ),
          const Gap(16),
          editSectionLabel(context, 'Duration'),
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
          TagListEditor(
            label: 'Projects',
            prefix: '+',
            controllers: _projects,
            options: context.read<AppProvider>().allProjects,
            hintText: 'project name',
            onAdd: () => setState(() => _projects.add(TextEditingController())),
            onRemove: (i) => setState(() {
              _projects[i].dispose();
              _projects.removeAt(i);
            }),
          ),
          const Gap(16),
          TagListEditor(
            label: 'Contexts',
            prefix: '@',
            controllers: _contexts,
            options: context.read<AppProvider>().allContexts,
            hintText: 'home, office, phone...',
            onAdd: () => setState(() => _contexts.add(TextEditingController())),
            onRemove: (i) => setState(() {
              _contexts[i].dispose();
              _contexts.removeAt(i);
            }),
          ),
          const Gap(8),
        ],
      ),
    ),
  );

  Widget _buildActions(BuildContext context) => Column(
    children: [
      const Divider(height: 1),
      Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
        child: Row(
          children: [
            TextButton(onPressed: _confirmDiscard, child: const Text('Cancel')),
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
  );
}
