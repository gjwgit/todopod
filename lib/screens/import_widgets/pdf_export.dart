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

import 'package:flutter/foundation.dart';

import 'package:file_picker/file_picker.dart';
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
            style: const pw.TextStyle(
              fontSize: 20,
              fontWeight: pw.FontWeight.bold,
            ),
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

/// Prompt for a filename and location, then write the PDF [bytes] there.
///
/// Returns a status message to display: the saved path on success, null if
/// the user cancelled, or an error string prefixed with 'error:'. On web,
/// falls back to the printing share/save sheet and returns null.
Future<String?> savePdfAs(List<int> bytes, String defaultName) async {
  try {
    if (kIsWeb) {
      // No filesystem on web; fall back to the printing share/save sheet.
      await Printing.sharePdf(
        bytes: Uint8List.fromList(bytes),
        filename: defaultName,
      );
      return null;
    }
    final fileUri = await FilePicker.saveFile(
      dialogTitle: 'Save PDF',
      fileName: defaultName,
      type: FileType.custom,
      allowedExtensions: ['pdf'],
      bytes: Uint8List.fromList(bytes),
    );
    if (fileUri == null) return null; // user cancelled
    return 'Saved to ${fileUri.path}';
  } catch (e, st) {
    debugPrint('[Save PDF] error: $e\n$st');
    return 'error:Save failed: $e';
  }
}
