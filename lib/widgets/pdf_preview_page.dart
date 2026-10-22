/// PdfPreviewPage — on-screen preview of a generated PDF with Print and Save.
///
// Time-stamp: <2026-10-22>
///
/// Copyright (C) 2026, Togaware Pty Ltd
///
/// Licensed under the GNU General Public License, Version 3

library;

import 'package:flutter/material.dart';

import 'package:printing/printing.dart';

import 'package:todopod/screens/import_widgets/pdf_export.dart';

/// A full-screen preview of the actual PDF. Sharing is replaced with an
/// explicit Save action that prompts for a filename and location; printing
/// stays available.

class PdfPreviewPage extends StatelessWidget {
  /// App bar title.
  final String title;

  /// Default filename offered when saving or printing to file.
  final String fileName;

  /// Builds the PDF bytes for the page format chosen in the preview.
  final LayoutCallback buildPdf;

  /// Called with the [savePdfAs] status when a save completes or fails: the
  /// saved path, or an error string prefixed with 'error:'. Not called when
  /// the user cancels.
  final void Function(BuildContext context, String message) onSaveMessage;

  const PdfPreviewPage({
    super.key,
    required this.title,
    required this.fileName,
    required this.buildPdf,
    required this.onSaveMessage,
  });

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text(title)),
    body: PdfPreview(
      build: buildPdf,
      pdfFileName: fileName,
      canChangePageFormat: false,
      canChangeOrientation: false,
      canDebug: false,
      allowSharing: false,
      actions: [
        PdfPreviewAction(
          icon: const Icon(Icons.save_alt),
          onPressed: (ctx, build, pageFormat) async {
            final bytes = await build(pageFormat);
            final msg = await savePdfAs(bytes, fileName);
            if (msg == null || !ctx.mounted) return;
            onSaveMessage(ctx, msg);
          },
        ),
      ],
    ),
  );
}
