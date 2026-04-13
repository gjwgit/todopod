/// ImportScreen — import from todo.txt and export backups.
///
// Time-stamp: <Monday 2026-04-13 12:08:45 +1000 Graham Williams>
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
import 'package:todopod/screens/import_screen_widgets.dart';
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

  void _setImportMessage(String msg, {bool error = false}) {
    setState(() {
      _importMessage = msg;
      _importError = error;
    });
  }

  void _setMessage(String msg, {bool error = false}) {
    setState(() {
      _exportMessage = msg;
      _exportError = error;
    });
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final provider = context.watch<AppProvider>();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Import ──────────────────────────────────────────────────
          Text('Import', style: Theme.of(context).textTheme.titleLarge),
          const Gap(8),
          Text(
            'Import tasks from a todo.txt file. Imported tasks are '
            'merged with your existing task list.',
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
            onTap: () => _importTodoTxt(context),
          ),

          // ── Export ──────────────────────────────────────────────────
          const Gap(32),
          Text(
            'Export / Backup',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          if (_exportMessage != null) ...[
            const Gap(12),
            ImportMessageBanner(
              message: _exportMessage!,
              isError: _exportError,
              cs: cs,
            ),
          ],
          const Gap(8),
          Text(
            'Save a timestamped copy of your tasks to your '
            'Downloads folder.',
            style: TextStyle(color: cs.onSurfaceVariant),
          ),
          const Gap(16),
          ImportActionCard(
            icon: Icons.download_outlined,
            title: 'Export Todo.txt',
            subtitle:
                'Saves Todo_YYYYMMDD_HHMM.txt with '
                '${provider.tasks.length} active tasks.',
            loading: _loading,
            onTap: () => _exportTodoTxt(context),
          ),
          const Gap(12),
          ImportActionCard(
            icon: Icons.download_outlined,
            title: 'Export Done.txt',
            subtitle:
                'Saves Done_YYYYMMDD_HHMM.txt with '
                '${provider.doneTasks.length} completed tasks.',
            loading: _loading,
            onTap: () => _exportDoneTxt(context),
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
        ],
      ),
    );
  }

  // ── Import ────────────────────────────────────────────────────────────────

  Future<void> _importTodoTxt(BuildContext context) async {
    final provider = context.read<AppProvider>();
    setState(() {
      _loading = true;
      _importMessage = null;
    });

    try {
      final result = await FilePicker.platform.pickFiles(
        dialogTitle: 'Select Todo.txt file',
        type: FileType.any,
        withData: true,
      );

      if (result == null || result.files.isEmpty) {
        setState(() => _loading = false);
        return;
      }

      final file = result.files.first;
      final bytes = file.bytes;
      if (bytes == null) {
        _setMessage('Could not read file.', error: true);
        setState(() => _loading = false);
        return;
      }

      final content = utf8.decode(bytes);
      final tasks = parseTodoTxt(content);

      if (tasks.isEmpty) {
        _setImportMessage('No tasks found in "${file.name}".', error: true);
        setState(() => _loading = false);
        return;
      }

      provider.importTasks(tasks);
      await provider.saveAllToPod();
      _setImportMessage(
        'Imported ${tasks.length} task${tasks.length == 1 ? '' : 's'} '
        'from "${file.name}".',
      );
    } catch (e, st) {
      debugPrint('[Import] error: $e\n$st');
      _setImportMessage('Import failed: $e', error: true);
    } finally {
      setState(() => _loading = false);
    }
  }

  // ── Export ────────────────────────────────────────────────────────────────

  Future<void> _exportTodoTxt(BuildContext context) async {
    final provider = context.read<AppProvider>();
    await _export(tasks: provider.tasks, prefix: 'Todo');
  }

  Future<void> _exportDoneTxt(BuildContext context) async {
    final provider = context.read<AppProvider>();
    await _export(tasks: provider.doneTasks, prefix: 'Done');
  }

  Future<void> _export({required List tasks, required String prefix}) async {
    setState(() {
      _loading = true;
      _exportMessage = null;
    });

    try {
      final lines = tasks.map((t) => t.toTodoTxt()).join('\n');
      final bytes = utf8.encode(lines);
      final now = DateTime.now();
      final ts =
          '${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}'
          '_${now.hour.toString().padLeft(2, '0')}${now.minute.toString().padLeft(2, '0')}';
      final fileName = '${prefix}_$ts.txt';

      if (kIsWeb) {
        _setMessage('Export to file is not supported on web.', error: true);
        return;
      }

      final home =
          Platform.environment['HOME'] ??
          Platform.environment['USERPROFILE'] ??
          '.';
      final downloads = Directory('$home/Downloads');
      final dir = downloads.existsSync() ? downloads : Directory(home);
      final file = File('${dir.path}/$fileName');
      await file.writeAsBytes(bytes);
      _setMessage('Exported to ${file.path}');
    } catch (e, st) {
      debugPrint('[Export] error: $e\n$st');
      _setMessage('Export failed: $e', error: true);
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
    final todayDate = DateTime(today.year, today.month, today.day);

    // Collect available projects and contexts from the task list.
    final projects = <String>{};
    final contexts = <String>{};
    for (final t in allTasks) {
      projects.addAll(t.projects);
      contexts.addAll(t.contexts);
    }

    // Show the filter bottom sheet and wait for the user's selection.
    // Returns (filteredTasks, filterLabel) so the filename can reflect filters.
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
        todayDate: todayDate,
        title: title,
      ),
    );

    if (result == null || !mounted) return;
    final (filtered, filterLabel) = result;
    await _exportPdf(
      // ignore: use_build_context_synchronously — mounted checked immediately above.
      context,
      tasks: filtered,
      title: title,
      prefix: prefix,
      filterLabel: filterLabel,
    );
  }

  // ── PDF Export ───────────────────────────────────────────────────────────

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
      final doc = pw.Document();
      final now = DateTime.now();
      final dateStr =
          '${now.day.toString().padLeft(2, '0')}/'
          '${now.month.toString().padLeft(2, '0')}/'
          '${now.year}';

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
                'Generated $dateStr  ·  ${tasks.length} task${tasks.length == 1 ? '' : 's'}',
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
              children: tasks.map<pw.Widget>((t) {
                final line = t.toTodoTxt();
                return pw.Padding(
                  padding: const pw.EdgeInsets.only(bottom: 6),
                  child: pw.Text(line, style: const pw.TextStyle(fontSize: 11)),
                );
              }).toList(),
            ),
          ],
        ),
      );

      // Build the suggested filename from active filters.
      final datePart =
          '${now.year}'
          '${now.month.toString().padLeft(2, '0')}'
          '${now.day.toString().padLeft(2, '0')}';
      final labelPart = filterLabel.isNotEmpty ? '_$filterLabel' : '';
      final pdfName =
          'todopod_${prefix.toLowerCase()}${labelPart}_$datePart.pdf';
      final pdfBytes = await doc.save();

      if (kIsWeb) {
        // On web fall back to the printing dialog.
        await Printing.layoutPdf(
          onLayout: (_) async => pdfBytes,
          name: pdfName,
        );
      } else {
        // On desktop/mobile use FilePicker so the filename is pre-filled.
        final savePath = await FilePicker.platform.saveFile(
          dialogTitle: 'Save PDF',
          fileName: pdfName,
          type: FileType.custom,
          allowedExtensions: ['pdf'],
        );
        if (savePath != null) {
          await File(savePath).writeAsBytes(pdfBytes);
          _setMessage('Saved to $savePath');
        }
        return;
      }
      _setMessage('PDF ready — use the dialog to save or print.');
    } catch (e, st) {
      debugPrint('[PDF Export] error: $e\n$st');
      _setMessage('PDF export failed: $e', error: true);
    } finally {
      setState(() => _loading = false);
    }
  }
}

// ── Action card ───────────────────────────────────────────────────────────────

// Widgets in import_screen_widgets.dart.
