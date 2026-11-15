/// EditActions — the Cancel and Save buttons along the foot of the task editor.
///
// Time-stamp: <2026-11-16>
///
/// Copyright (C) 2026, Togaware Pty Ltd
///
/// Licensed under the GNU General Public License, Version 3

library;

import 'package:flutter/material.dart';

class EditActions extends StatelessWidget {
  /// Label for the save button, e.g. "Add Task" or "Save".

  final String saveLabel;

  /// Save, or null to disable the save button.

  final VoidCallback? onSave;

  /// Cancel, or null to disable the cancel button.

  final VoidCallback? onCancel;

  /// Whether a save is under way, shown as a busy animation on the button.

  final bool saving;

  const EditActions({
    super.key,
    required this.saveLabel,
    required this.onSave,
    required this.onCancel,
    required this.saving,
  });

  @override
  Widget build(BuildContext context) => Column(
    children: [
      const Divider(height: 1),
      Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
        child: Row(
          children: [
            TextButton(onPressed: onCancel, child: const Text('Cancel')),
            const Spacer(),
            FilledButton.icon(
              onPressed: onSave,
              icon: saving
                  ? const SizedBox.square(
                      dimension: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : null,
              label: Text(saveLabel),
            ),
          ],
        ),
      ),
    ],
  );
}
