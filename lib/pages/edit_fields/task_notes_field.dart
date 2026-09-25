/// TaskNotesField — extracted from task_edit.dart.
///
// Time-stamp: <2026-08-08>
///
/// Copyright (C) 2026, Togaware Pty Ltd
///
/// Licensed under the GNU General Public License, Version 3

library;

import 'package:flutter/material.dart';

import 'package:emacs_text_field/emacs_text_field.dart'
    show EmacsTextField, writePrimarySelection;
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import 'package:gap/gap.dart';

import 'package:todopod/utils/markdown_checkbox.dart';
import 'package:todopod/widgets/tag_autocomplete.dart';

/// The Notes section of the task editor: a section header with an
/// Edit/Preview toggle, then either the rendered markdown or the editor.
class TaskNotesField extends StatelessWidget {
  final TextEditingController notes;
  final bool showPreview;
  final VoidCallback onToggle;

  const TaskNotesField({
    super.key,
    required this.notes,
    required this.showPreview,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final styleSheet = MarkdownStyleSheet.fromTheme(Theme.of(context));

    // 20260925 gjw checkboxBuilder is passed only the checked state, so the
    // tapped box is identified by its position in the build order, which the
    // markdown builder walks in document order. The counter is reset once it
    // reaches the number of checkboxes in the source, so a re-parse against
    // this same closure — the builder is invoked from the markdown widget's
    // didChangeDependencies, not from this build — starts again from zero.

    final total = markdownCheckboxOffsets(notes.text).length;
    var next = 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Notes section header with Edit/Preview toggle.
        Row(
          children: [
            Expanded(
              child: editSectionLabel(
                context,
                'Notes',
                tooltip:
                    '**Notes**\n\n'
                    'Additional details, links, or context for the task.\n\n'
                    'Supports **markdown** formatting.\n\n'
                    'Write a checklist with `- [ ]` and tap a box in '
                    '**Preview** to tick it off.\n\n'
                    '**Emacs keys:** C-a/e line · C-f/b char · C-n/p line '
                    '· M-f/b word · C-k kill · C-y yank · M-Enter bullet',
              ),
            ),
            TextButton.icon(
              onPressed: onToggle,
              icon: Icon(
                showPreview ? Icons.edit_outlined : Icons.preview_outlined,
                size: 16,
              ),
              label: Text(showPreview ? 'Edit' : 'Preview'),
              style: TextButton.styleFrom(
                visualDensity: VisualDensity.compact,
                padding: const EdgeInsets.symmetric(horizontal: 8),
              ),
            ),
          ],
        ),
        const Gap(8),
        if (showPreview)
          Container(
            width: double.infinity,
            constraints: const BoxConstraints(minHeight: 80),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              border: Border.all(color: cs.outline),
              borderRadius: BorderRadius.circular(4),
            ),
            child: notes.text.trim().isEmpty
                ? Text(
                    'Nothing to preview.',
                    style: TextStyle(
                      color: cs.onSurfaceVariant,
                      fontStyle: FontStyle.italic,
                    ),
                  )
                : SelectionArea(
                    onSelectionChanged: (value) {
                      final text = value?.plainText ?? '';
                      if (text.isNotEmpty) writePrimarySelection(text);
                    },
                    child: MarkdownBody(
                      data: notes.text,
                      shrinkWrap: true,
                      styleSheet: styleSheet,
                      checkboxBuilder: (checked) {
                        if (next >= total) next = 0;
                        final index = next++;

                        return GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onTap: () => notes.text = toggleMarkdownCheckbox(
                            notes.text,
                            index,
                          ),
                          child: Padding(
                            padding: styleSheet.listBulletPadding!,
                            child: Icon(
                              checked
                                  ? Icons.check_box
                                  : Icons.check_box_outline_blank,
                              size: styleSheet.checkbox!.fontSize,
                              color: styleSheet.checkbox!.color,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
          )
        else
          EmacsTextField(
            controller: notes,
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              isDense: true,
              alignLabelWithHint: true,
              hintText: 'Details, links, markdown…',
            ),
          ),
      ],
    );
  }
}
