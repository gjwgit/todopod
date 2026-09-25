/// Tests for markdownCheckboxOffsets / toggleMarkdownCheckbox — locating and
/// flipping markdown task-list checkboxes in the Notes field.
///
library;

// Run: flutter test test/markdown_checkbox_test.dart

import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:markdown/markdown.dart' as md;

import 'package:todopod/utils/markdown_checkbox.dart';

/// The number of checkboxes the markdown renderer actually draws for [text],
/// counted from the same parser and extension set flutter_markdown_plus uses.

int renderedCheckboxCount(String text) {
  final document = md.Document(
    extensionSet: md.ExtensionSet.gitHubFlavored,
    encodeHtml: false,
  );

  var count = 0;

  void walk(List<md.Node> nodes) {
    for (final node in nodes) {
      if (node is md.Element) {
        if (node.attributes['type'] == 'checkbox') count++;
        if (node.children != null) walk(node.children!);
      }
    }
  }

  walk(document.parseLines(const LineSplitter().convert(text)));

  return count;
}

void main() {
  group('markdownCheckboxOffsets', () {
    test('finds nothing in text without checkboxes', () {
      expect(markdownCheckboxOffsets(''), isEmpty);
      expect(markdownCheckboxOffsets('Just some notes.\n- a bullet'), isEmpty);
    });

    test('points at the state character between the brackets', () {
      const text = '- [ ] Milk';
      final offsets = markdownCheckboxOffsets(text);

      expect(offsets, [3]);
      expect(text[offsets.first], ' ');
    });

    test('counts in document order across bullet styles', () {
      const text = '- [ ] a\n* [x] b\n+ [X] c\n1. [ ] d\n2) [x] e';

      expect(markdownCheckboxOffsets(text), hasLength(5));
    });

    test('includes nested items at any indent', () {
      const text = '- [ ] a\n    - [x] nested\n\t- [ ] tabbed';

      expect(markdownCheckboxOffsets(text), hasLength(3));
    });

    test('ignores brackets that are not task-list items', () {
      // No bullet, no space after the brackets, and not a checkbox state.

      const text = '[ ] a\n- [ ]b\n- [y] c\n- [] d';

      expect(markdownCheckboxOffsets(text), isEmpty);
    });

    test('skips fenced code blocks', () {
      const text = '- [ ] real\n```\n- [ ] fenced\n```\n- [x] also real';

      expect(markdownCheckboxOffsets(text), hasLength(2));
    });

    test('treats a tilde fence as a code block too', () {
      const text = '~~~\n- [ ] fenced\n~~~\n- [ ] real';

      expect(markdownCheckboxOffsets(text), hasLength(1));
    });

    test('a backtick fence is not closed by a tilde fence', () {
      const text =
          '```\n- [ ] fenced\n~~~\n- [ ] still fenced\n```\n- [ ] real';

      expect(markdownCheckboxOffsets(text), hasLength(1));
    });

    test('handles an unterminated fence', () {
      const text = '- [ ] real\n```\n- [ ] fenced to the end';

      expect(markdownCheckboxOffsets(text), hasLength(1));
    });

    // The tapped checkbox is identified by its ordinal, so a scan that finds
    // a different number of boxes than the renderer draws would toggle the
    // wrong line. Guards the scanner against markdown package changes.

    test('counts exactly what the renderer draws', () {
      const samples = [
        '',
        'no checkboxes at all',
        '- [ ] a',
        '- [ ] a\n- [x] b\n- [X] c',
        '* [ ] a\n+ [x] b',
        '1. [ ] a\n2) [x] b',
        '10. [ ] ten\n11. [x] eleven',
        '   - [ ] three spaces',
        '- [x]  double space after',
        '- [ ]\ttabbed after',
        '- [ ] a\n    - [x] nested\n- [ ] c',
        '- [ ] a\n  - [ ] b\n    - [ ] c\n      - [ ] d',
        '- [ ] a\n```\n- [ ] fenced\n```\n- [x] b',
        '~~~\n- [ ] fenced\n~~~\n- [ ] real',
        '[ ] a\n- [ ]b\n- [y] c\n- [] d',
        '- [ ]\n- [ ] real',
        'para\n- [ ] interrupt',
        'Notes\n\n- [ ] a\n\n- [x] b\n',
        '# Head\n\ntext\n\n- [ ] a\n\n> - [x] quoted\n\n- [ ] b',
        '> - [ ] quoted\n> - [x] two',
        '> > - [ ] nested quote',
        '- [ ] a\n\ntext\n\n1. [ ] b\n1. [x] c',
        '- [ ] a *emph* text\n- [x] `code`',
      ];

      for (final sample in samples) {
        expect(
          markdownCheckboxOffsets(sample),
          hasLength(renderedCheckboxCount(sample)),
          reason: 'scanner and renderer disagree for:\n$sample',
        );
      }
    });
  });

  group('toggleMarkdownCheckbox', () {
    test('ticks an empty box', () {
      expect(toggleMarkdownCheckbox('- [ ] Milk', 0), '- [x] Milk');
    });

    test('unticks a ticked box, in either case', () {
      expect(toggleMarkdownCheckbox('- [x] Milk', 0), '- [ ] Milk');
      expect(toggleMarkdownCheckbox('- [X] Milk', 0), '- [ ] Milk');
    });

    test('toggles the indexed box and leaves the others alone', () {
      const text = '- [ ] a\n- [ ] b\n- [ ] c';

      expect(toggleMarkdownCheckbox(text, 1), '- [ ] a\n- [x] b\n- [ ] c');
    });

    test('counts past a fenced block when indexing', () {
      const text = '- [ ] a\n```\n- [ ] fenced\n```\n- [ ] b';

      expect(
        toggleMarkdownCheckbox(text, 1),
        '- [ ] a\n```\n- [ ] fenced\n```\n- [x] b',
      );
    });

    test('round-trips back to the original text', () {
      const text = 'Notes\n\n- [ ] a\n- [x] b\n';
      final once = toggleMarkdownCheckbox(text, 0);

      expect(once, isNot(text));
      expect(toggleMarkdownCheckbox(once, 0), text);
    });

    test('returns the text unchanged for an out-of-range index', () {
      const text = '- [ ] only one';

      expect(toggleMarkdownCheckbox(text, -1), text);
      expect(toggleMarkdownCheckbox(text, 1), text);
      expect(toggleMarkdownCheckbox('no boxes here', 0), 'no boxes here');
    });
  });
}
