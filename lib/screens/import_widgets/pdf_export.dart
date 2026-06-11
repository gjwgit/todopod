/// PDF generation for task exports.
///
/// Builds a Todo.txt-style PDF document from a list of tasks, using a
/// Unicode-capable font so characters outside basic Latin render correctly.
///
// Time-stamp: <2026-06-11>
///
/// Copyright (C) 2026, Togaware Pty Ltd
///
/// Licensed under the GNU General Public License, Version 3

library;

import 'dart:typed_data';

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import 'package:todopod/models/task.dart';

/// Build the raw bytes of a tasks PDF with [title] as the heading.
///
/// Uses Noto Sans (loaded via PdfGoogleFonts) as the document default so
/// characters beyond basic Latin (·, –, —, accents) render without the pdf
/// package falling back to Helvetica, which has no Unicode support.
Future<Uint8List> buildTasksPdf({
  required List<Task> tasks,
  required String title,
}) async {
  final now = DateTime.now();
  final dateStr =
      '${now.day.toString().padLeft(2, '0')}/'
      '${now.month.toString().padLeft(2, '0')}/'
      '${now.year}';

  final base = await PdfGoogleFonts.notoSansRegular();
  final bold = await PdfGoogleFonts.notoSansBold();
  final italic = await PdfGoogleFonts.notoSansItalic();
  final boldItalic = await PdfGoogleFonts.notoSansBoldItalic();

  final doc = pw.Document(
    theme: pw.ThemeData.withFont(
      base: base,
      bold: bold,
      italic: italic,
      boldItalic: boldItalic,
    ),
  );

  doc.addPage(
    pw.MultiPage(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.all(40),
      header: (ctx) => pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            title,
            style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold),
          ),
          pw.Text(
            'Generated $dateStr  ·  '
            '${tasks.length} task${tasks.length == 1 ? '' : 's'}',
            style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey600),
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

  return doc.save();
}
