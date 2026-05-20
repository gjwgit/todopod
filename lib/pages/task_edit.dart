/// TaskEdit — dialog to add or edit a task.
///
// Time-stamp: <Tuesday 2026-05-05 14:50:31 +1000 Graham Williams>
///
/// Copyright (C) 2026, Togaware Pty Ltd
///
/// Licensed under the GNU General Public License, Version 3 (the "License");
///
/// License: https://opensource.org/license/gpl-3-0

library;

import 'package:flutter/material.dart';

import 'package:emacs_text_field/emacs_text_field.dart'
    show EmacsTextField, attachPrimarySelection, writePrimarySelection;
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import 'package:gap/gap.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';

import 'package:todopod/models/task.dart';
import 'package:todopod/pages/edit_fields/priority_due_date_row.dart';
import 'package:todopod/pages/edit_fields/tag_list_editor.dart';
import 'package:todopod/services/app_provider.dart';
import 'package:todopod/widgets/tag_autocomplete.dart';

const _uuid = Uuid();

class TaskEdit extends StatefulWidget {
  /// The task to edit, or null to create a new task.
  final Task? task;

  /// Pre-fill the title when creating a new task (ignored when editing).
  final String? initialTitle;

  /// Field to focus on open: 'projects', 'contexts', etc.
  final String? focusField;

  const TaskEdit({super.key, this.task, this.initialTitle, this.focusField});

  @override
  State<TaskEdit> createState() => _TaskEditState();
}

class _TaskEditState extends State<TaskEdit> {
  late final TextEditingController _description;
  late final TextEditingController _notes;
  late final TextEditingController _duration;
  late VoidCallback _removePrimaryDescription;
  late VoidCallback _removePrimaryDuration;
  late bool _showPreview;
  late bool _completed;
  late String? _priority;
  late DateTime? _dueDate;
  late List<TextEditingController> _projects;
  late List<TextEditingController> _contexts;

  bool _focusNewProject = false;
  bool _focusNewContext = false;

  bool get _isNew => widget.task == null;

  // ── Initial state snapshot for change detection ─────────────────────────

  late final String _initDescription;
  late final String _initNotes;
  late final String _initDuration;
  late bool _initCompleted;
  late final String? _initPriority;
  late final DateTime? _initDueDate;
  late final List<String> _initProjects;
  late final List<String> _initContexts;

  @override
  void initState() {
    super.initState();
    final t = widget.task;
    _description = TextEditingController(
      text: t?.description ?? widget.initialTitle ?? '',
    );
    _notes = TextEditingController(text: t?.notes ?? '');
    _duration = TextEditingController(text: t?.duration ?? '');
    // _notes is an EmacsTextField — it handles primary selection internally.
    _removePrimaryDescription = attachPrimarySelection(_description);
    _removePrimaryDuration = attachPrimarySelection(_duration);
    // Default to preview for existing tasks, edit for new.
    _showPreview = widget.task != null;
    _completed = t?.completed ?? false;
    _priority = t != null ? t.priority : 'B';
    _dueDate = t != null ? t.dueDate : DateTime.now();
    _projects = (t?.projects ?? [])
        .map((p) => TextEditingController(text: p))
        .toList();
    _contexts = (t?.contexts ?? [])
        .map((c) => TextEditingController(text: c))
        .toList();

    // When opening with a focusField, add an empty entry to focus into.

    if (widget.focusField == 'projects') {
      _projects.add(TextEditingController());
      _focusNewProject = true;
    } else if (widget.focusField == 'contexts') {
      _contexts.add(TextEditingController());
      _focusNewContext = true;
    }

    // Snapshot for change detection.

    _initDescription = _description.text;
    _initNotes = _notes.text;
    _initDuration = _duration.text;
    _initCompleted = _completed;
    _initPriority = _priority;
    _initDueDate = _dueDate;
    _initProjects = _projects.map((c) => c.text).toList();
    _initContexts = _contexts.map((c) => c.text).toList();
  }

  @override
  void dispose() {
    _removePrimaryDescription();
    _removePrimaryDuration();
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
    if (_completed != _initCompleted) return true;
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
    completed: _completed,
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
      barrierDismissible: false,
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

  Widget _buildForm(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Flexible(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            editSectionLabel(
              context,
              'Title',
              tooltip:
                  '**Title**\n\n'
                  'A short summary of the task — what needs to be done.\n\n'
                  'This is the main text that appears in the task list.',
            ),
            const Gap(8),
            TextField(
              controller: _description,
              autofocus: _isNew && widget.focusField == null,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                isDense: true,
                hintText: 'What needs to be done?',
              ),
            ),
            const Gap(16),
            // Notes section header with Edit/Preview toggle.
            Row(
              children: [
                Expanded(
                  child: editSectionLabel(
                    context,
                    'Notes',
                    tooltip:
                        '**Notes**\n\n'
                        'Additional details, links, or context for the task.\n\n'
                        'Supports **markdown** formatting.\n\n'
                        '**Emacs keys:** C-a/e line · C-f/b char · C-n/p line '
                        '· M-f/b word · C-k kill · C-y yank · M-Enter bullet',
                  ),
                ),
                TextButton.icon(
                  onPressed: () => setState(() => _showPreview = !_showPreview),
                  icon: Icon(
                    _showPreview ? Icons.edit_outlined : Icons.preview_outlined,
                    size: 16,
                  ),
                  label: Text(_showPreview ? 'Edit' : 'Preview'),
                  style: TextButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                  ),
                ),
              ],
            ),
            const Gap(8),
            if (_showPreview)
              Container(
                width: double.infinity,
                constraints: const BoxConstraints(minHeight: 80),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  border: Border.all(color: cs.outline),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: _notes.text.trim().isEmpty
                    ? Text(
                        'Nothing to preview.',
                        style: TextStyle(
                          color: cs.onSurfaceVariant,
                          fontStyle: FontStyle.italic,
                        ),
                      )
                    : SelectionArea(
                        onSelectionChanged: (value) {
                          final text = value?.plainText ?? '';
                          if (text.isNotEmpty) writePrimarySelection(text);
                        },
                        child: MarkdownBody(
                          data: _notes.text,
                          shrinkWrap: true,
                          styleSheet: MarkdownStyleSheet.fromTheme(
                            Theme.of(context),
                          ),
                        ),
                      ),
              )
            else
              EmacsTextField(
                controller: _notes,
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
            const Gap(8),
            CheckboxListTile(
              value: _completed,
              onChanged: (v) => setState(() => _completed = v ?? false),
              title: const Text('Mark as done'),
              controlAffinity: ListTileControlAffinity.leading,
              contentPadding: EdgeInsets.zero,
              dense: true,
            ),
            const Gap(16),
            editSectionLabel(
              context,
              'Duration',
              tooltip:
                  '**Duration**\n\n'
                  'Estimated time to complete the task.\n\n'
                  'Free-text — common formats include '
                  '*30m*, *1h*, *2h30m*, *15min*.',
            ),
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
              tooltip:
                  '**Projects**\n\n'
                  'Group related tasks under a project tag (prefixed with **+**).\n\n'
                  'Examples: +home, +work, +garden.\n'
                  'Autocomplete suggests existing project names.',
              focusLast: _focusNewProject,
              onFocusConsumed: () => _focusNewProject = false,
              onAdd: () => setState(() {
                _projects.add(TextEditingController());
                _focusNewProject = true;
              }),
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
              tooltip:
                  '**Contexts**\n\n'
                  'Where or how the task should be done (prefixed with **@**).\n\n'
                  'Examples: @home, @office, @phone, @computer.\n'
                  'Useful for filtering tasks by location or tool.',
              focusLast: _focusNewContext,
              onFocusConsumed: () => _focusNewContext = false,
              onAdd: () => setState(() {
                _contexts.add(TextEditingController());
                _focusNewContext = true;
              }),
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
  }

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
