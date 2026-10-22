/// Tests for markdownToPdf — rendering task notes as pdf widgets.
///
library;

// Run: flutter test test/markdown_pdf_test.dart

import 'package:flutter_test/flutter_test.dart';
import 'package:pdf/widgets.dart' as pw;

import 'package:todopod/utils/markdown_pdf.dart';

/// Lay [widgets] out in a real document, which is where a bad widget tree
/// fails, using the built-in fonts so no network is needed.

Future<List<int>> render(List<pw.Widget> widgets) {
  final doc = pw.Document()..addPage(pw.MultiPage(build: (_) => widgets));

  return doc.save();
}

void main() {
  final mono = pw.Font.courier();

  test('each list item, nested or not, is its own top-level widget', () {
    final widgets = markdownToPdf(
      '- one\n- two\n  - nested\n- three',
      mono: mono,
    );

    expect(widgets, hasLength(4));
  });

  test('task-list, loose and ordered lists all lay out', () async {
    final widgets = markdownToPdf(
      '- [ ] open\n- [x] done\n\n'
      '1. first\n\n2. second\n',
      mono: mono,
    );

    expect(widgets, hasLength(4));
    expect(await render(widgets), isNotEmpty);
  });

  test(
    'headings, inline styles, code, quotes, rules and tables lay out',
    () async {
      final widgets = markdownToPdf(
        '# Title\n\n'
        'Some **bold**, *italic*, ***both***, ~~gone~~, `code` and a '
        '[link](https://example.com).\n\n'
        '> quoted\n\n'
        '```\nfenced\n```\n\n'
        '---\n\n'
        '| a | b |\n|---|---|\n| 1 | 2 |\n',
        mono: mono,
      );

      expect(widgets, hasLength(6));
      expect(await render(widgets), isNotEmpty);
    },
  );

  test('empty notes produce no widgets', () {
    expect(markdownToPdf('', mono: mono), isEmpty);
  });
}
