/// Render markdown as pdf widgets, so task notes print formatted.
///
// Time-stamp: <2026-10-22>
///
/// Copyright (C) 2026, Togaware Pty Ltd
///
/// Licensed under the GNU General Public License, Version 3

library;

import 'package:markdown/markdown.dart' as md;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

/// Indent per list nesting level, in points.

const _indent = 16.0;

/// A tick drawn as a vector so it does not depend on the font having a
/// check-mark glyph.

const _tickSvg =
    '<svg viewBox="0 0 10 10"><path d="M2 5.2 L4.2 7.5 L8 2.5" '
    'fill="none" stroke="#000000" stroke-width="1.6"/></svg>';

/// Convert markdown [source] into a flat list of pdf widgets for a
/// MultiPage, using [mono] for code.
///
/// Parsed with the GitHub-flavoured extension set, matching the
/// MarkdownBody that renders the notes on screen, so task-list checkboxes,
/// tables and strikethrough come out the same. List items are emitted as
/// separate top-level widgets, indented by nesting level, so a long list can
/// break across pages.

List<pw.Widget> markdownToPdf(String source, {required pw.Font mono}) {
  final nodes = md.Document(
    extensionSet: md.ExtensionSet.gitHubFlavored,
    encodeHtml: false,
  ).parse(source);

  return _blocks(nodes, 0, mono);
}

List<pw.Widget> _blocks(List<md.Node> nodes, int level, pw.Font mono) {
  final out = <pw.Widget>[];
  final inline = <md.Node>[];

  // Consecutive inline nodes (as in a tight list item) form one paragraph.

  void flush() {
    if (inline.isEmpty) return;
    out.add(_indented(level, _para(inline, mono)));
    inline.clear();
  }

  for (final node in nodes) {
    if (node is md.Element && _isBlock(node.tag)) {
      flush();
      out.addAll(_block(node, level, mono));
    } else {
      inline.add(node);
    }
  }
  flush();

  return out;
}

bool _isBlock(String tag) => const {
  'h1', 'h2', 'h3', 'h4', 'h5', 'h6', 'p', 'ul', 'ol', 'blockquote', //
  'pre', 'hr', 'table',
}.contains(tag);

List<pw.Widget> _block(md.Element e, int level, pw.Font mono) {
  final children = e.children ?? const <md.Node>[];

  switch (e.tag) {
    case 'h1' || 'h2' || 'h3' || 'h4' || 'h5' || 'h6':
      final size = const [
        18.0,
        16.0,
        14.0,
        13.0,
        12.0,
        11.0,
      ][int.parse(e.tag.substring(1)) - 1];

      return [
        _indented(
          level,
          pw.Padding(
            padding: const pw.EdgeInsets.only(top: 6, bottom: 4),
            child: pw.RichText(
              text: pw.TextSpan(
                style: pw.TextStyle(
                  fontSize: size,
                  fontWeight: pw.FontWeight.bold,
                ),
                children: _spans(children, mono),
              ),
            ),
          ),
        ),
      ];
    case 'ul' || 'ol':
      final start = int.tryParse(e.attributes['start'] ?? '') ?? 1;
      final items = children.whereType<md.Element>().toList();

      return [
        for (var i = 0; i < items.length; i++)
          ..._listItem(
            items[i],
            e.tag == 'ol' ? '${start + i}.' : '•',
            level,
            mono,
          ),
      ];
    case 'blockquote':
      return [
        _indented(
          level,
          pw.Container(
            padding: const pw.EdgeInsets.only(left: 8),
            margin: const pw.EdgeInsets.only(bottom: 6),
            decoration: const pw.BoxDecoration(
              border: pw.Border(
                left: pw.BorderSide(color: PdfColors.grey400, width: 2),
              ),
            ),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: _blocks(children, 0, mono),
            ),
          ),
        ),
      ];
    case 'pre':
      return [
        _indented(
          level,
          pw.Container(
            width: double.infinity,
            padding: const pw.EdgeInsets.all(6),
            margin: const pw.EdgeInsets.only(bottom: 6),
            color: PdfColors.grey100,
            child: pw.Text(
              e.textContent.trimRight(),
              style: pw.TextStyle(font: mono, fontSize: 9),
            ),
          ),
        ),
      ];
    case 'hr':
      return [pw.Divider(color: PdfColors.grey400)];
    case 'table':
      return [_indented(level, _table(e, mono))];
    default:
      return [_indented(level, _para(children, mono))];
  }
}

/// One list item: its [marker] (or checkbox) beside the item's first run of
/// inline text, then any further blocks, such as a nested list, one level
/// deeper.

List<pw.Widget> _listItem(
  md.Element li,
  String marker,
  int level,
  pw.Font mono,
) {
  final children = li.children ?? const <md.Node>[];
  final firstBlock = children.indexWhere(
    (n) => n is md.Element && _isBlock(n.tag),
  );
  final split = firstBlock == -1 ? children.length : firstBlock;
  var lead = children.sublist(0, split);
  var rest = children.sublist(split);

  // A loose list wraps each item's text in a paragraph: lift it beside the
  // marker.

  if (lead.isEmpty && rest.isNotEmpty) {
    final first = rest.first as md.Element;
    if (first.tag == 'p') {
      lead = [...?first.children];
      rest = rest.sublist(1);
    }
  }

  // A task-list item starts with an <input> checkbox, which replaces the
  // bullet.

  pw.Widget markerWidget = pw.Text(marker);
  final box = lead.isEmpty ? null : lead.first;
  if (box is md.Element && box.tag == 'input') {
    markerWidget = _checkbox(box.attributes['checked'] == 'true');
    lead = lead.sublist(1);
  }

  return [
    _indented(
      level,
      pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.SizedBox(width: _indent, child: markerWidget),
          pw.Expanded(child: _para(lead, mono)),
        ],
      ),
    ),
    ..._blocks(rest, level + 1, mono),
  ];
}

pw.Widget _checkbox(bool checked) => pw.Container(
  width: 9,
  height: 9,
  margin: const pw.EdgeInsets.only(top: 2),
  decoration: pw.BoxDecoration(
    border: pw.Border.all(color: PdfColors.grey700, width: 0.8),
  ),
  child: checked ? pw.SvgImage(svg: _tickSvg) : null,
);

pw.Widget _table(md.Element table, pw.Font mono) {
  final rows = <pw.TableRow>[];

  void collect(md.Node n) {
    if (n is! md.Element) return;
    if (n.tag == 'tr') {
      rows.add(
        pw.TableRow(
          children: [
            for (final cell in (n.children ?? const []).whereType<md.Element>())
              pw.Padding(
                padding: const pw.EdgeInsets.all(4),
                child: pw.RichText(
                  text: pw.TextSpan(
                    style: cell.tag == 'th'
                        ? const pw.TextStyle(fontWeight: pw.FontWeight.bold)
                        : null,
                    children: _spans(cell.children ?? const [], mono),
                  ),
                ),
              ),
          ],
        ),
      );
    } else {
      n.children?.forEach(collect);
    }
  }

  table.children?.forEach(collect);

  return pw.Padding(
    padding: const pw.EdgeInsets.only(bottom: 6),
    child: pw.Table(
      border: pw.TableBorder.all(color: PdfColors.grey400, width: 0.5),
      children: rows,
    ),
  );
}

pw.Widget _para(List<md.Node> nodes, pw.Font mono) => pw.Padding(
  padding: const pw.EdgeInsets.only(bottom: 6),
  child: pw.RichText(text: pw.TextSpan(children: _spans(nodes, mono))),
);

pw.Widget _indented(int level, pw.Widget child) => level == 0
    ? child
    : pw.Padding(
        padding: pw.EdgeInsets.only(left: level * _indent),
        child: child,
      );

/// Inline markdown as styled text spans. Styles nest, so bold inside italic
/// picks up the bold-italic font from the document theme.

List<pw.InlineSpan> _spans(List<md.Node> nodes, pw.Font mono) => [
  for (final n in nodes) _span(n, mono),
];

pw.InlineSpan _span(md.Node node, pw.Font mono) {
  if (node is md.Text) return pw.TextSpan(text: node.text);
  final e = node as md.Element;
  final kids = _spans(e.children ?? const [], mono);

  switch (e.tag) {
    case 'strong':
      return pw.TextSpan(
        style: const pw.TextStyle(fontWeight: pw.FontWeight.bold),
        children: kids,
      );
    case 'em':
      return pw.TextSpan(
        style: const pw.TextStyle(fontStyle: pw.FontStyle.italic),
        children: kids,
      );
    case 'del':
      return pw.TextSpan(
        style: const pw.TextStyle(decoration: pw.TextDecoration.lineThrough),
        children: kids,
      );
    case 'code':
      return pw.TextSpan(
        text: e.textContent,
        style: pw.TextStyle(
          font: mono,
          fontSize: 9,
          background: const pw.BoxDecoration(color: PdfColors.grey200),
        ),
      );
    case 'a':
      return pw.TextSpan(
        style: const pw.TextStyle(
          color: PdfColors.blue700,
          decoration: pw.TextDecoration.underline,
        ),
        annotation: pw.AnnotationUrl(e.attributes['href'] ?? ''),
        children: kids,
      );
    case 'br':
      return const pw.TextSpan(text: '\n');
    case 'img':
      return pw.TextSpan(text: e.attributes['alt'] ?? '');
    default:
      return pw.TextSpan(children: kids);
  }
}
