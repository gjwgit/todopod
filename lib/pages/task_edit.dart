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
    show attachPrimarySelection;
import 'package:gap/gap.dart';
import 'package:provider/provider.dart';
import 'package:solidui/solidui.dart';
import 'package:uuid/uuid.dart';

import 'package:todopod/models/task.dart';
import 'package:todopod/pages/edit_fields/priority_due_date_row.dart';
import 'package:todopod/pages/edit_fields/tag_list_editor.dart';
import 'package:todopod/pages/edit_fields/task_notes_field.dart';
import 'package:todopod/services/app_provider.dart';
import 'package:todopod/utils/priority_from_due_date.dart';
import 'package:todopod/widgets/tag_autocomplete.dart';

const _uuid = Uuid();

class TaskEdit extends StatefulWidget {
  /// The task to edit, or null to create a new task.
  final Task? task;

  /// Pre-fill the title when creating a new task (ignored when editing).
  final String? initialTitle;

  /// Field to focus on open: 'projects', 'contexts', etc.
  final String? focusField;

  /// Called with the task built from the current field values when the user
  /// saves. The caller is responsible for updating the provider and the Pod.
  ///
  /// Returns a future that completes when the Pod write is done. It MUST be
  /// awaited by the caller's implementation: closing the app window waits on
  /// this before quitting, so a fire-and-forget write would be killed
  /// mid-flight and the task silently lost.
  ///
  /// A failed write MUST throw rather than report and swallow: the editor
  /// stays open on a failure, so closing over the top of unsaved work is
  /// only avoided when the failure reaches it.
  final Future<void> Function(Task)? onSave;

  const TaskEdit({
    super.key,
    this.task,
    this.initialTitle,
    this.focusField,
    this.onSave,
  });

  @override
  State<TaskEdit> createState() => _TaskEditState();
}

class _TaskEditState extends State<TaskEdit> with UnsavedChangesMixin {
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

    // Rebuild on any text change so the Save button enables/disables live.
    for (final c in [
      _description,
      _notes,
      _duration,
      ..._projects,
      ..._contexts,
    ]) {
      c.addListener(_onFieldChanged);
    }
  }

  // Triggers a rebuild so the Save button reflects the current change state.
  void _onFieldChanged() {
    if (mounted) setState(() {});
  }

  /// True when the task can be saved: there is a non-empty description AND
  /// (for an existing task) at least one change has been made. New tasks
  /// only require a non-empty description.
  bool get _canSave {
    if (_description.text.trim().isEmpty) return false;
    if (_isNew) return true;
    return _hasChanges;
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

  // ── Saving ──────────────────────────────────────────────────────────────

  /// Hand the current field values to [TaskEdit.onSave], which persists them,
  /// and report whether the write actually reached the Pod.
  ///
  /// Awaited so a window close can wait for the Pod write to complete.
  Future<bool> _save() async {
    try {
      await widget.onSave?.call(_buildTask());

      return true;
    } catch (e) {
      SolidWriteFailures.report('Failed saving the task.\n\n$e');

      return false;
    }
  }

  /// Save, then close the editor. Used by the Save/Add button and by Enter in
  /// the title field.
  ///
  /// Only closes once the write has landed: popping over a failed write loses
  /// the task the user asked to keep.
  Future<void> _saveAndClose() async {
    if (!await _save()) return;
    if (mounted) Navigator.of(context).pop();
  }

  // The window-close prompt comes from UnsavedChangesMixin, which needs to
  // know what counts as unsaved and how to save it. Saving there must not pop
  // the Navigator — the window is closing, not just this dialog.

  @override
  bool get hasUnsavedChanges => _hasChanges;

  @override
  bool get canSaveUnsavedChanges => _canSave;

  @override
  Future<bool> saveUnsavedChanges() => _save();

  /// Close the editor, but if there are unsaved changes first ask whether to
  /// save, discard, or keep editing.
  Future<void> _confirmDiscard() async {
    if (!_hasChanges) {
      Navigator.of(context).pop();

      return;
    }

    final action = await showUnsavedChangesDialog(context);
    if (!mounted) return;

    switch (action) {
      case UnsavedChangesAction.save:
        if (_canSave) await _saveAndClose();
      case UnsavedChangesAction.discard:
        Navigator.of(context).pop();
      case UnsavedChangesAction.keepEditing:
        break;
    }
  }

  Task _buildTask() => Task(
    id: widget.task?.id ?? _uuid.v4(),
    completed: _completed,
    // For a new task, derive the priority from the due date — but only if
    // the user hasn't manually changed it from the default. If they picked
    // a priority themselves, respect it.
    priority: (_isNew && _priority == _initPriority)
        ? priorityFromDueDate(_dueDate)
        : _priority,
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

  /// Compact "Mark as done" checkbox shown on the Title row, mirroring the
  /// Edit/Preview toggle on the Notes row.
  Widget _buildMarkAsDoneToggle() => InkWell(
    onTap: () => setState(() => _completed = !_completed),
    borderRadius: BorderRadius.circular(4),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Checkbox(
          value: _completed,
          onChanged: (v) => setState(() => _completed = v ?? false),
          visualDensity: VisualDensity.compact,
          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
        ),
        const Gap(4),
        const Text('Mark as done', style: TextStyle(fontSize: 13)),
      ],
    ),
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
        // Read-only created date, shown for existing tasks. Not editable —
        // creation date is set once when the task is first added.
        if (!_isNew && widget.task?.creationDate != null) ...[
          const Gap(12),
          Text(
            'Created ${_fmtCreated(widget.task!.creationDate!)}',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ],
        const Spacer(),
        IconButton(icon: const Icon(Icons.close), onPressed: _confirmDiscard),
      ],
    ),
  );

  String _fmtCreated(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/'
      '${d.month.toString().padLeft(2, '0')}/'
      '${d.year}';

  Widget _buildForm(BuildContext context) {
    return Flexible(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: editSectionLabel(
                    context,
                    'Title',
                    tooltip:
                        '**Title**\n\n'
                        'A short summary of the task — what needs to be '
                        'done.\n\n'
                        'This is the main text that appears in the task '
                        'list.',
                  ),
                ),
                _buildMarkAsDoneToggle(),
              ],
            ),
            const Gap(8),
            TextField(
              controller: _description,
              autofocus: _isNew && widget.focusField == null,
              textInputAction: _isNew
                  ? TextInputAction.done
                  : TextInputAction.next,
              onSubmitted: (_) {
                if (!_isNew) return;
                if (_description.text.trim().isEmpty) return;
                _saveAndClose();
              },
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                isDense: true,
                hintText: 'What needs to be done?',
              ),
            ),
            const Gap(16),
            TaskNotesField(
              notes: _notes,
              showPreview: _showPreview,
              onToggle: () => setState(() => _showPreview = !_showPreview),
            ),
            const Gap(16),
            PriorityDueDateRow(
              priority: _priority,
              dueDate: _dueDate,
              durationController: _duration,
              onPriorityChanged: (v) => setState(() => _priority = v),
              onPickDueDate: _pickDueDate,
              onClearDueDate: () => setState(() => _dueDate = null),
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
                _projects.add(
                  TextEditingController()..addListener(_onFieldChanged),
                );
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
                _contexts.add(
                  TextEditingController()..addListener(_onFieldChanged),
                );
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
              onPressed: _canSave ? _saveAndClose : null,
              child: Text(_isNew ? 'Add Task' : 'Save'),
            ),
          ],
        ),
      ),
    ],
  );
}
