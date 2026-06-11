/// ImportScreen — import from todo.txt / JSON and export backups.
///
// Time-stamp: <Friday 2026-04-24 19:58:58 +1000 Graham Williams>
///
/// Copyright (C) 2026, Togaware Pty Ltd
///
/// Licensed under the GNU General Public License, Version 3 (the "License");
///
/// License: https://opensource.org/license/gpl-3-0

library;

import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'package:file_picker/file_picker.dart';
import 'package:gap/gap.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:provider/provider.dart';

import 'package:todopod/models/task.dart';
import 'package:todopod/models/task_parser.dart';
import 'package:todopod/screens/import_widgets/export_filter_sheet.dart';
import 'package:todopod/screens/import_widgets/import_action_card.dart';
import 'package:todopod/screens/import_widgets/import_message_banner.dart';
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
          ImportActionCard(
            icon: Icons.save_alt,
            title: 'Back up all tasks (JSON)',
            subtitle:
                'Save all ${provider.tasks.length + provider.doneTasks.length} '
                'tasks to a todopod JSON backup file.',
            loading: _loading,
            onTap: () => _exportJson(context),
          ),
          const Gap(12),
          ImportActionCard(
            icon: Icons.restore,
            title: 'Restore from backup (JSON)',
            subtitle: 'Restore tasks from a todopod JSON backup file.',
            loading: _loading,
            onTap: () => _import(
              context,
              dialogTitle: 'Select JSON backup file',
              fileType: FileType.custom,
              extensions: ['json'],
              backup: true,
              parse: (b) {
                final bundle =
                    jsonDecode(utf8.decode(b)) as Map<String, dynamic>;
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

          // ── Export ──────────────────────────────────────────────────
          const Gap(32),
          Text('Export', style: Theme.of(context).textTheme.titleLarge),
          const Gap(8),
          Text(
            'Save a timestamped copy of your tasks as Todo.txt or PDF.',
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
            title: 'Export Todo.txt',
            subtitle:
                'Saves Todo_YYYYMMDD_HHMM.txt with '
                '${provider.tasks.length} active tasks.',
            loading: _loading,
            onTap: () => _exportTxt(tasks: provider.tasks, prefix: 'Todo'),
          ),
          const Gap(12),
          ImportActionCard(
            icon: Icons.download_outlined,
            title: 'Export Done.txt',
            subtitle:
                'Saves Done_YYYYMMDD_HHMM.txt with '
                '${provider.doneTasks.length} completed tasks.',
            loading: _loading,
            onTap: () => _exportTxt(tasks: provider.doneTasks, prefix: 'Done'),
          ),
          const Gap(12),
          ImportActionCard(
            icon: Icons.picture_as_pdf_outlined,
            title: 'Export Todo.txt as PDF',
            subtitle:
                'Choose tasks to save or print from '
                '${provider.tasks.length} active tasks.',
            loading: _loading,
            onTap: () => _showFilterAndExportPdf(
              context,
              allTasks: provider.tasks,
              title: 'Active Tasks',
              prefix: 'Todo',
            ),
          ),
          const Gap(12),
          ImportActionCard(
            icon: Icons.picture_as_pdf_outlined,
            title: 'Export Done.txt as PDF',
            subtitle:
                'Choose tasks to save or print from '
                '${provider.doneTasks.length} completed tasks.',
            loading: _loading,
            onTap: () => _showFilterAndExportPdf(
              context,
              allTasks: provider.doneTasks,
              title: 'Completed Tasks',
              prefix: 'Done',
            ),
          ),

          // ── Import ──────────────────────────────────────────────────
          const Gap(32),
          Text('Import', style: Theme.of(context).textTheme.titleLarge),
          const Gap(8),
          Text(
            'Import tasks from a Todo.txt file. Imported tasks are merged '
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
            title: 'Import Todo.txt',
            subtitle: 'Select a Todo.txt file to import active tasks.',
            loading: _loading,
            onTap: () => _import(
              context,
              dialogTitle: 'Select Todo.txt file',
              parse: (b) => parseTodoTxt(utf8.decode(b)),
            ),
          ),
          const Gap(12),
          ImportActionCard(
            icon: Icons.upload_file_outlined,
            title: 'Import Done.txt',
            subtitle: 'Select a Done.txt file to import completed tasks.',
            loading: _loading,
            onTap: () => _import(
              context,
              dialogTitle: 'Select Done.txt file',
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

  Future<void> _exportTxt({required List tasks, required String prefix}) async {
    setState(() {
      _loading = true;
      _exportMessage = null;
    });
    try {
      if (kIsWeb) {
        _setExportMsg('Export to file is not supported on web.', error: true);
        return;
      }
      final now = DateTime.now();
      final savePath = await FilePicker.saveFile(
        dialogTitle: 'Save $prefix.txt',
        fileName: '${prefix}_${_ts(now)}.txt',
        type: FileType.any,
      );
      if (savePath == null) return;
      await File(
        savePath,
      ).writeAsBytes(utf8.encode(tasks.map((t) => t.toTodoTxt()).join('\n')));
      _setExportMsg('Saved to $savePath');
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
      final now = DateTime.now();
      final bundle = {
        'exported_at': now.toIso8601String(),
        'tasks': provider.tasks.map((t) => t.toJson()).toList(),
        'done': provider.doneTasks.map((t) => t.toJson()).toList(),
      };
      final savePath = await FilePicker.saveFile(
        dialogTitle: 'Save JSON Backup',
        fileName: 'todopod_backup_${_ts(now)}.json',
        type: FileType.custom,
        allowedExtensions: ['json'],
      );
      if (savePath == null) return;
      await File(
        savePath,
      ).writeAsString(const JsonEncoder.withIndent('  ').convert(bundle));
      _setBackupMsg('Backup saved to $savePath');
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
      ),
    );
    if (result == null || !mounted) return;
    final (filtered, filterLabel) = result;
    await _exportPdf(
      // ignore: use_build_context_synchronously — mounted checked above.
      context,
      tasks: filtered,
      title: title,
      prefix: prefix,
      filterLabel: filterLabel,
    );
  }

  Future<void> _exportPdf(
    BuildContext context, {
    required List tasks,
    required String title,
    required String prefix,
    String filterLabel = '',
  }) async {
    setState(() {
      _loading = true;
      _exportMessage = null;
    });
    try {
      final now = DateTime.now();
      final dateStr =
          '${now.day.toString().padLeft(2, '0')}/'
          '${now.month.toString().padLeft(2, '0')}/'
          '${now.year}';
      final doc = pw.Document();
      doc.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(40),
          header: (ctx) => pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                title,
                style: pw.TextStyle(
                  fontSize: 20,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.Text(
                'Generated $dateStr  ·  '
                '${tasks.length} task${tasks.length == 1 ? '' : 's'}',
                style: const pw.TextStyle(
                  fontSize: 10,
                  color: PdfColors.grey600,
                ),
              ),
              pw.Divider(),
              pw.SizedBox(height: 4),
            ],
          ),
          build: (ctx) => [
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: tasks
                  .map<pw.Widget>(
                    (t) => pw.Padding(
                      padding: const pw.EdgeInsets.only(bottom: 6),
                      child: pw.Text(
                        t.toTodoTxt(),
                        style: const pw.TextStyle(fontSize: 11),
                      ),
                    ),
                  )
                  .toList(),
            ),
          ],
        ),
      );
      final labelPart = filterLabel.isNotEmpty ? '_$filterLabel' : '';
      final pdfName =
          'todopod_${prefix.toLowerCase()}${labelPart}_${_ts(now)}.pdf';
      final pdfBytes = await doc.save();
      if (kIsWeb) {
        await Printing.layoutPdf(
          onLayout: (_) async => pdfBytes,
          name: pdfName,
        );
        _setExportMsg('PDF ready — use the dialog to save or print.');
      } else {
        final savePath = await FilePicker.saveFile(
          dialogTitle: 'Save PDF',
          fileName: pdfName,
          type: FileType.custom,
          allowedExtensions: ['pdf'],
        );
        if (savePath != null) {
          await File(savePath).writeAsBytes(pdfBytes);
          _setExportMsg('Saved to $savePath');
        }
      }
    } catch (e, st) {
      debugPrint('[PDF Export] error: $e\n$st');
      _setExportMsg('PDF export failed: $e', error: true);
    } finally {
      setState(() => _loading = false);
    }
  }
}

// Widgets in import_screen_widgets.dart.
