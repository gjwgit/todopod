/// TagListEditor — extracted from task_edit_form_fields.dart.
///
// Time-stamp: <2026-05-20>
///
/// Copyright (C) 2026, Togaware Pty Ltd
///
/// Licensed under the GNU General Public License, Version 3

library;

import 'package:flutter/material.dart';

import 'package:gap/gap.dart';

import 'package:todopod/widgets/tag_autocomplete.dart';

class TagListEditor extends StatelessWidget {
  final String label;
  final String prefix;
  final List<TextEditingController> controllers;
  final List<String> options;
  final String hintText;
  final String? tooltip;
  final bool focusLast;
  final VoidCallback? onFocusConsumed;
  final VoidCallback onAdd;
  final ValueChanged<int> onRemove;

  const TagListEditor({
    super.key,
    required this.label,
    required this.prefix,
    required this.controllers,
    required this.options,
    required this.hintText,
    this.tooltip,
    this.focusLast = false,
    this.onFocusConsumed,
    required this.onAdd,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        editSectionLabel(context, label, tooltip: tooltip),
        const Gap(8),
        ...controllers.asMap().entries.map((e) {
          final isNewLast = focusLast && e.key == controllers.length - 1;
          if (isNewLast) {
            // Consume the flag after this build frame.
            WidgetsBinding.instance.addPostFrameCallback(
              (_) => onFocusConsumed?.call(),
            );
          }

          return Padding(
            key: ObjectKey(e.value),
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              children: [
                Text(prefix, style: const TextStyle(fontSize: 16)),
                const Gap(8),
                Expanded(
                  child: TagAutocomplete(
                    controller: e.value,
                    options: options,
                    hintText: hintText,
                    autofocus: isNewLast,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.remove_circle_outline, size: 18),
                  onPressed: () => onRemove(e.key),
                ),
              ],
            ),
          );
        }),
        TextButton.icon(
          icon: const Icon(Icons.add, size: 16),
          label: Text('Add ${label.toLowerCase()}'),
          onPressed: onAdd,
        ),
      ],
    );
  }
}
