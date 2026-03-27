/// ImportScreen — import from todo.txt and export backups.
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
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'package:file_picker/file_picker.dart';
import 'package:gap/gap.dart';
import 'package:provider/provider.dart';

import 'package:todopod/models/task_parser.dart';
import 'package:todopod/services/app_provider.dart';

class ImportScreen extends StatefulWidget {
  const ImportScreen({super.key});

  @override
  State<ImportScreen> createState() => _ImportScreenState();
}

class _ImportScreenState extends State<ImportScreen> {
  bool _loading = false;
  String? _message;
  bool _isError = false;

  void _setMessage(String msg, {bool error = false}) {
    setState(() {
      _message = msg;
      _isError = error;
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
          Text(
            'Import',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const Gap(8),
          Text(
            'Import tasks from a todo.txt file. Imported tasks are '
            'merged with your existing task list.',
            style: TextStyle(color: cs.onSurfaceVariant),
          ),
          if (_message != null) ...[
            const Gap(12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: _isError ? cs.errorContainer : cs.secondaryContainer,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(
                    _isError
                        ? Icons.error_outline
                        : Icons.check_circle_outline,
                    color: _isError
                        ? cs.onErrorContainer
                        : cs.onSecondaryContainer,
                  ),
                  const Gap(8),
                  Expanded(
                    child: Text(
                      _message!,
                      style: TextStyle(
                        color: _isError
                            ? cs.onErrorContainer
                            : cs.onSecondaryContainer,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
          const Gap(16),
          _ActionCard(
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
          const Gap(8),
          Text(
            'Save a timestamped copy of your tasks to your '
            'Downloads folder.',
            style: TextStyle(color: cs.onSurfaceVariant),
          ),
          const Gap(16),
          _ActionCard(
            icon: Icons.download_outlined,
            title: 'Export Todo.txt',
            subtitle: 'Saves Todo_YYYYMMDD_HHMM.txt with '
                '${provider.tasks.length} active tasks.',
            loading: _loading,
            onTap: () => _exportTodoTxt(context),
          ),
          const Gap(12),
          _ActionCard(
            icon: Icons.download_outlined,
            title: 'Export Done.txt',
            subtitle: 'Saves Done_YYYYMMDD_HHMM.txt with '
                '${provider.doneTasks.length} completed tasks.',
            loading: _loading,
            onTap: () => _exportDoneTxt(context),
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
      _message = null;
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
        _setMessage('No tasks found in "${file.name}".', error: true);
        setState(() => _loading = false);
        return;
      }

      provider.importTasks(tasks);
      await provider.saveAllToPod();
      _setMessage('Imported ${tasks.length} task${tasks.length == 1 ? '' : 's'} '
          'from "${file.name}".');
    } catch (e, st) {
      debugPrint('[Import] error: $e\n$st');
      _setMessage('Import failed: $e', error: true);
    } finally {
      setState(() => _loading = false);
    }
  }

  // ── Export ────────────────────────────────────────────────────────────────

  Future<void> _exportTodoTxt(BuildContext context) async {
    final provider = context.read<AppProvider>();
    await _export(
      tasks: provider.tasks,
      prefix: 'Todo',
    );
  }

  Future<void> _exportDoneTxt(BuildContext context) async {
    final provider = context.read<AppProvider>();
    await _export(
      tasks: provider.doneTasks,
      prefix: 'Done',
    );
  }

  Future<void> _export({
    required List tasks,
    required String prefix,
  }) async {
    setState(() {
      _loading = true;
      _message = null;
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

      final home = Platform.environment['HOME'] ??
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
}

// ── Action card ───────────────────────────────────────────────────────────────

class _ActionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool loading;
  final VoidCallback onTap;

  const _ActionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.loading,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Card(
      child: ListTile(
        leading: Icon(icon, color: cs.primary),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w500)),
        subtitle: Text(
          subtitle,
          style: TextStyle(color: cs.onSurfaceVariant, fontSize: 12),
        ),
        trailing: loading
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : Icon(Icons.chevron_right, color: cs.onSurfaceVariant),
        onTap: loading ? null : onTap,
      ),
    );
  }
}
