/// ImportScreen — import from todo.txt / JSON and export backups.
///
// Time-stamp: <Thursday 2026-06-11 20:52:13 +1000 Graham Williams>
///
/// Copyright (C) 2026, Togaware Pty Ltd
///
/// Licensed under the GNU General Public License, Version 3 (the "License");
///
/// License: https://opensource.org/license/gpl-3-0

library;

import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'package:file_picker/file_picker.dart';
import 'package:gap/gap.dart';
import 'package:markdown_tooltip/markdown_tooltip.dart';
import 'package:printing/printing.dart';
import 'package:provider/provider.dart';

import 'package:todopod/models/task.dart';
import 'package:todopod/models/task_parser.dart';
import 'package:todopod/screens/import_widgets/export_filter_sheet.dart';
import 'package:todopod/screens/import_widgets/import_action_card.dart';
import 'package:todopod/screens/import_widgets/import_message_banner.dart';
import 'package:todopod/screens/import_widgets/pdf_export.dart';
import 'package:todopod/screens/import_widgets/task_file_export.dart';
import 'package:todopod/services/app_provider.dart';

class ImportScreen extends StatefulWidget {
  const ImportScreen({super.key});

  @override
  State<ImportScreen> createState() => _ImportScreenState();
}

class _ImportScreenState extends State<ImportScreen> {
  bool _loading = false;
  String? _importMessage;
  bool _importError = false;
  String? _exportMessage;
  bool _exportError = false;
  String? _backupMessage;
  bool _backupError = false;
  String? _viewMessage;
  bool _viewError = false;

  void _setImportMsg(String msg, {bool error = false}) => setState(() {
    _importMessage = msg;
    _importError = error;
  });

  void _setExportMsg(String msg, {bool error = false}) => setState(() {
    _exportMessage = msg;
    _exportError = error;
  });

  void _setBackupMsg(String msg, {bool error = false}) => setState(() {
    _backupMessage = msg;
    _backupError = error;
  });

  void _setViewMsg(String msg, {bool error = false}) => setState(() {
    _viewMessage = msg;
    _viewError = error;
  });

  /// Zero-padded timestamp string for filenames: YYYYMMDD_HHMM.
  String _ts(DateTime t) =>
      '${t.year}${t.month.toString().padLeft(2, '0')}${t.day.toString().padLeft(2, '0')}'
      '_${t.hour.toString().padLeft(2, '0')}${t.minute.toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final provider = context.watch<AppProvider>();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Backup & Restore ────────────────────────────────────────
          Text(
            'Backup & Restore',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const Gap(8),
          Text(
            'Save a complete JSON backup of all your tasks, or restore '
            'everything from a previously saved backup file.',
            style: TextStyle(color: cs.onSurfaceVariant),
          ),
          if (_backupMessage != null) ...[
            const Gap(12),
            ImportMessageBanner(
              message: _backupMessage!,
              isError: _backupError,
              cs: cs,
            ),
          ],
          const Gap(16),
          Row(
            children: [
              MarkdownTooltip(
                message:
                    '**Export Backup**\n\n'
                    'Save all '
                    '${provider.tasks.length + provider.doneTasks.length} '
                    'tasks (active and completed) to a todopod JSON backup '
                    'file on this device. Keep it somewhere safe so you can '
                    'restore everything later.',
                child: FilledButton.icon(
                  icon: const Icon(Icons.download),
                  label: const Text('Export Backup'),
                  onPressed: _loading ? null : () => _exportJson(context),
                ),
              ),
              const Gap(12),
              MarkdownTooltip(
                message:
                    '**Import Backup**\n\n'
                    'Restore tasks from a previously saved todopod JSON '
                    'backup file. Restored tasks are merged with your '
                    'existing task list.',
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.upload),
                  label: const Text('Import Backup'),
                  onPressed: _loading
                      ? null
                      : () => _import(
                          context,
                          dialogTitle: 'Select JSON backup file',
                          fileType: FileType.custom,
                          extensions: ['json'],
                          backup: true,
                          parse: (b) {
                            final bundle =
                                jsonDecode(utf8.decode(b))
                                    as Map<String, dynamic>;
                            return [
                              ...(bundle['tasks'] as List? ?? [])
                                  .cast<Map<String, dynamic>>()
                                  .map(Task.fromJson),
                              ...(bundle['done'] as List? ?? [])
                                  .cast<Map<String, dynamic>>()
                                  .map(Task.fromJson),
                            ];
                          },
                        ),
                ),
              ),
            ],
          ),

          // ── View ────────────────────────────────────────────────────
          const Gap(32),
          Text('View', style: Theme.of(context).textTheme.titleLarge),
          const Gap(8),
          Text(
            'Choose tasks and view them as a PDF on screen. You can save '
            'or print from the preview.',
            style: TextStyle(color: cs.onSurfaceVariant),
          ),
          if (_viewMessage != null) ...[
            const Gap(12),
            ImportMessageBanner(
              message: _viewMessage!,
              isError: _viewError,
              cs: cs,
            ),
          ],
          const Gap(16),
          ImportActionCard(
            icon: Icons.picture_as_pdf_outlined,
            title: 'View Todo as PDF',
            subtitle:
                'Choose tasks to view, save or print from '
                '${provider.tasks.length} active tasks.',
            loading: _loading,
            onTap: () => _showFilterAndExportPdf(
              context,
              allTasks: provider.tasks,
              title: 'Active Tasks',
              prefix: 'todo',
            ),
          ),
          const Gap(12),
          ImportActionCard(
            icon: Icons.picture_as_pdf_outlined,
            title: 'View Done as PDF',
            subtitle:
                'Choose tasks to view, save or print from '
                '${provider.doneTasks.length} completed tasks.',
            loading: _loading,
            onTap: () => _showFilterAndExportPdf(
              context,
              allTasks: provider.doneTasks,
              title: 'Completed Tasks',
              prefix: 'done',
            ),
          ),

          // ── Export ──────────────────────────────────────────────────
          const Gap(32),
          Text('Export', style: Theme.of(context).textTheme.titleLarge),
          const Gap(8),
          Text(
            'Save a timestamped copy of your tasks using the Todo.txt format or as PDF.',
            style: TextStyle(color: cs.onSurfaceVariant),
          ),
          if (_exportMessage != null) ...[
            const Gap(12),
            ImportMessageBanner(
              message: _exportMessage!,
              isError: _exportError,
              cs: cs,
            ),
          ],
          const Gap(16),
          ImportActionCard(
            icon: Icons.download_outlined,
            title: 'Export todo.txt',
            subtitle:
                'Saves todo_YYYYMMDD_HHMM.txt with '
                '${provider.tasks.length} active tasks.',
            loading: _loading,
            onTap: () => _exportTxt(tasks: provider.tasks, prefix: 'todo'),
          ),
          const Gap(12),
          ImportActionCard(
            icon: Icons.download_outlined,
            title: 'Export done.txt',
            subtitle:
                'Saves done_YYYYMMDD_HHMM.txt with '
                '${provider.doneTasks.length} completed tasks.',
            loading: _loading,
            onTap: () => _exportTxt(tasks: provider.doneTasks, prefix: 'done'),
          ),

          // ── Import ──────────────────────────────────────────────────
          const Gap(32),
          Text('Import', style: Theme.of(context).textTheme.titleLarge),
          const Gap(8),
          Text(
            'Import tasks from a todo.txt file. Imported tasks are merged '
            'with your existing task list.',
            style: TextStyle(color: cs.onSurfaceVariant),
          ),
          if (_importMessage != null) ...[
            const Gap(12),
            ImportMessageBanner(
              message: _importMessage!,
              isError: _importError,
              cs: cs,
            ),
          ],
          const Gap(16),
          ImportActionCard(
            icon: Icons.upload_file_outlined,
            title: 'Import todo.txt',
            subtitle: 'Select a todo.txt file to import active tasks.',
            loading: _loading,
            onTap: () => _import(
              context,
              dialogTitle: 'Select todo.txt file',
              parse: (b) => parseTodoTxt(utf8.decode(b)),
            ),
          ),
          const Gap(12),
          ImportActionCard(
            icon: Icons.upload_file_outlined,
            title: 'Import done.txt',
            subtitle: 'Select a done.txt file to import completed tasks.',
            loading: _loading,
            onTap: () => _import(
              context,
              dialogTitle: 'Select done.txt file',
              parse: (b) => parseTodoTxt(utf8.decode(b)),
            ),
          ),
        ],
      ),
    );
  }

  // ── Import ────────────────────────────────────────────────────────────────

  /// Generic import: picks a file, decodes bytes via [parse], merges into pod.
  /// When [backup] is true, status messages appear in the Backup & Restore
  /// section rather than the Import section.
  Future<void> _import(
    BuildContext context, {
    required String dialogTitle,
    FileType fileType = FileType.any,
    List<String>? extensions,
    bool backup = false,
    required List<Task> Function(List<int> bytes) parse,
  }) async {
    final provider = context.read<AppProvider>();
    void setMsg(String msg, {bool error = false}) => backup
        ? _setBackupMsg(msg, error: error)
        : _setImportMsg(msg, error: error);
    setState(() {
      _loading = true;
      if (backup) {
        _backupMessage = null;
      } else {
        _importMessage = null;
      }
    });
    try {
      final result = await FilePicker.pickFiles(
        dialogTitle: dialogTitle,
        type: fileType,
        allowedExtensions: extensions,
        withData: true,
      );
      if (result == null || result.files.isEmpty) return;
      final file = result.files.first;
      final bytes = file.bytes;
      if (bytes == null) {
        setMsg('Could not read file.', error: true);
        return;
      }
      final tasks = parse(bytes);
      if (tasks.isEmpty) {
        setMsg('No tasks found in "${file.name}".', error: true);
        return;
      }
      provider.importTasks(tasks);
      await provider.saveAllToPod();
      setMsg(
        '${backup ? 'Restored' : 'Imported'} ${tasks.length} '
        'task${tasks.length == 1 ? '' : 's'} from "${file.name}".',
      );
    } catch (e, st) {
      debugPrint('[Import] error: $e\n$st');
      setMsg('${backup ? 'Restore' : 'Import'} failed: $e', error: true);
    } finally {
      setState(() => _loading = false);
    }
  }

  // ── Export ────────────────────────────────────────────────────────────────

  Future<void> _exportTxt({required List<Task> tasks, required String prefix}) async {
    setState(() {
      _loading = true;
      _exportMessage = null;
    });
    try {
      if (kIsWeb) {
        _setExportMsg('Export to file is not supported on web.', error: true);
        return;
      }
      final path = await saveTasksTxt(
        tasks: tasks,
        prefix: prefix,
        timestamp: _ts(DateTime.now()),
      );
      if (path != null) _setExportMsg('Saved to $path');
    } catch (e, st) {
      debugPrint('[Export] error: $e\n$st');
      _setExportMsg('Export failed: $e', error: true);
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _exportJson(BuildContext context) async {
    final provider = context.read<AppProvider>();
    setState(() {
      _loading = true;
      _backupMessage = null;
    });
    try {
      if (kIsWeb) {
        _setBackupMsg('Backup to file is not supported on web.', error: true);
        return;
      }
      final path = await saveTasksJsonBackup(
        tasks: provider.tasks,
        done: provider.doneTasks,
        timestamp: _ts(DateTime.now()),
      );
      if (path != null) _setBackupMsg('Backup saved to $path');
    } catch (e, st) {
      debugPrint('[ExportJSON] error: $e\n$st');
      _setBackupMsg('Backup failed: $e', error: true);
    } finally {
      setState(() => _loading = false);
    }
  }

  // ── Filter chooser + PDF export ──────────────────────────────────────────

  Future<void> _showFilterAndExportPdf(
    BuildContext context, {
    required List<Task> allTasks,
    required String title,
    required String prefix,
  }) async {
    final today = DateTime.now();
    final projects = <String>{};
    final contexts = <String>{};
    for (final t in allTasks) {
      projects.addAll(t.projects);
      contexts.addAll(t.contexts);
    }
    final result = await showModalBottomSheet<(List<Task>, String)>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => ExportFilterSheet(
        allTasks: allTasks,
        projects: projects.toList()..sort(),
        contexts: contexts.toList()..sort(),
        todayDate: DateTime(today.year, today.month, today.day),
        title: title,
        actionVerb: 'View',
      ),
    );
    if (result == null || !mounted) return;
    final (filtered, filterLabel) = result;
    await _exportPdf(
      tasks: filtered,
      title: title,
      prefix: prefix,
      filterLabel: filterLabel,
    );
  }

  Future<void> _exportPdf({
    required List<Task> tasks,
    required String title,
    required String prefix,
    String filterLabel = '',
  }) async {
    setState(() {
      _loading = true;
      _viewMessage = null;
    });
    try {
      final pdfBytes = await buildTasksPdf(tasks: tasks, title: title);
      final labelPart = filterLabel.isNotEmpty ? '_$filterLabel' : '';
      final pdfName =
          'todopod_${prefix.toLowerCase()}${labelPart}_${_ts(DateTime.now())}.pdf';
      if (!mounted) return;
      // Open an on-screen preview of the actual PDF. PdfPreview renders the
      // document and provides toolbar actions to save, print or share.
      await Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => Scaffold(
            appBar: AppBar(title: Text(title)),
            body: PdfPreview(
              build: (_) async => pdfBytes,
              pdfFileName: pdfName,
              canChangePageFormat: false,
              canChangeOrientation: false,
              canDebug: false,
            ),
          ),
        ),
      );
      _setViewMsg('PDF generated.');
    } catch (e, st) {
      debugPrint('[PDF View] error: $e\n$st');
      _setViewMsg('PDF generation failed: $e', error: true);
    } finally {
      setState(() => _loading = false);
    }
  }
}

// Widgets in import_screen_widgets.dart.
