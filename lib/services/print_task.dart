/// Preview a single task as a PDF, then print or save it.
///
// Time-stamp: <2026-10-22>
///
/// Copyright (C) 2026, Togaware Pty Ltd
///
/// Licensed under the GNU General Public License, Version 3

library;

import 'dart:typed_data';

import 'package:flutter/material.dart';

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:solidui/solidui.dart';

import 'package:todopod/models/task.dart';
import 'package:todopod/screens/done_widgets/done_tile.dart';
import 'package:todopod/screens/import_widgets/pdf_export.dart';
import 'package:todopod/utils/file_timestamp.dart';
import 'package:todopod/utils/markdown_pdf.dart';
import 'package:todopod/widgets/pdf_preview_page.dart';

/// Open a PDF preview of [task], from which the user can print it or save
/// it to a file. The notes are rendered from their markdown.

Future<void> printTaskAction(BuildContext context, Task task) =>
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => PdfPreviewPage(
          title: task.description,
          fileName: 'todopod_task_${fileTimestamp(DateTime.now())}.pdf',
          buildPdf: (format) => _buildTaskPdf(task, format),
          onSaveMessage: (ctx, msg) {
            if (!msg.startsWith('error:')) {
              showPositiveSnackBar(ctx, msg);

              return;
            }
            showDialog<void>(
              context: ctx,
              builder: (dctx) => AlertDialog(
                title: const Text('Save Failed'),
                content: Text(msg.substring(6)),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(dctx).pop(),
                    child: const Text('OK'),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );

/// Lay out [task] for [format]: the description as the heading, a label
/// column of its dates and tags, then the formatted notes.

Future<Uint8List> _buildTaskPdf(Task task, PdfPageFormat format) async {
  final mono = await PdfGoogleFonts.notoSansMonoRegular();
  final doc = pw.Document(theme: await notoPdfTheme());
  final rows = <(String, String)>[
    ('Status', task.completed ? 'Done' : 'Active'),
    if (task.completionDate != null) ('Done', fmtDate(task.completionDate!)),
    if (task.creationDate != null) ('Created', fmtDate(task.creationDate!)),
    if (task.dueDate != null) ('Due', fmtDate(task.dueDate!)),
    if (task.priority != null) ('Priority', task.priorityLabel),
    if (task.duration != null) ('Duration', task.duration!),
    if (task.projects.isNotEmpty)
      ('Projects', task.projects.map((p) => '+$p').join(', ')),
    if (task.contexts.isNotEmpty)
      ('Contexts', task.contexts.map((c) => '@$c').join(', ')),
  ];
  const labelStyle = pw.TextStyle(fontSize: 10, color: PdfColors.grey700);

  doc.addPage(
    pw.MultiPage(
      pageFormat: format,
      margin: const pw.EdgeInsets.all(40),
      build: (_) => [
        pw.Text(
          task.description,
          style: const pw.TextStyle(
            fontSize: 18,
            fontWeight: pw.FontWeight.bold,
          ),
        ),
        pw.Divider(),
        for (final (label, value) in rows)
          pw.Padding(
            padding: const pw.EdgeInsets.only(bottom: 4),
            child: pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.SizedBox(
                  width: 80,
                  child: pw.Text(label, style: labelStyle),
                ),
                pw.Expanded(child: pw.Text(value)),
              ],
            ),
          ),
        if (task.notes != null && task.notes!.isNotEmpty) ...[
          pw.SizedBox(height: 12),
          pw.Text('Notes', style: labelStyle),
          pw.SizedBox(height: 4),
          ...markdownToPdf(task.notes!, mono: mono),
        ],
      ],
    ),
  );

  return doc.save();
}
