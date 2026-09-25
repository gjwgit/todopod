/// Locate and toggle markdown task-list checkboxes in a block of text.
///
// Time-stamp: <2026-09-25>
///
/// Copyright (C) 2026, Togaware Pty Ltd
///
/// Licensed under the GNU General Public License, Version 3

library;

// 20260925 gjw These patterns mirror the markdown package's own task-list
// parsing (ListSyntax + `^ {0,3}\[([ xX])\][ \t]`) so that the Nth checkbox
// found here is the Nth checkbox the renderer builds. Leading whitespace is
// unrestricted because a nested item is re-parsed with its indent stripped,
// and `>` markers are allowed because a blockquoted list renders its
// checkboxes too.

final _checkboxPattern = RegExp(
  r'^(?:[ \t]*>)*[ \t]*(?:[-*+]|\d{1,9}[.)])[ \t]+\[([ xX])\](?=[ \t])',
);

/// A ``` or ~~~ code fence. Content inside a fence is not a list, so any
/// `- [ ]` there is text and must not be counted.

final _fencePattern = RegExp(r'^[ ]{0,3}(`{3,}|~{3,})');

/// Offsets into [text], in document order, of the state character inside each
/// markdown task-list checkbox — the ` `, `x` or `X` between the brackets.
///
/// Lines inside a fenced code block are skipped. Indented code blocks are
/// not detected: a four-space indent is indistinguishable from a nested list
/// item without tracking the enclosing block structure.

List<int> markdownCheckboxOffsets(String text) {
  final offsets = <int>[];

  // The fence marker currently open, or null outside a code block.

  String? fence;
  var start = 0;

  while (start <= text.length) {
    final newline = text.indexOf('\n', start);
    final end = newline == -1 ? text.length : newline;
    final line = text.substring(start, end);

    final fenceMatch = _fencePattern.firstMatch(line);

    if (fenceMatch != null) {
      // An opening fence starts a block; the same marker closes it.

      final marker = fenceMatch[1]![0];
      if (fence == null) {
        fence = marker;
      } else if (fence == marker) {
        fence = null;
      }
    } else if (fence == null) {
      final match = _checkboxPattern.firstMatch(line);

      // The pattern ends with `]`, so the state character is the second to
      // last of the match.

      if (match != null) offsets.add(start + match.end - 2);
    }

    if (newline == -1) break;
    start = newline + 1;
  }

  return offsets;
}

/// Returns [text] with its [index]-th (0-based) task-list checkbox flipped
/// between `[ ]` and `[x]`, or unchanged when there is no such checkbox.

String toggleMarkdownCheckbox(String text, int index) {
  final offsets = markdownCheckboxOffsets(text);
  if (index < 0 || index >= offsets.length) return text;

  final at = offsets[index];

  return text.replaceRange(at, at + 1, text[at] == ' ' ? 'x' : ' ');
}
