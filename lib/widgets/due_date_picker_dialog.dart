/// Due-date picker dialog — pick a date, clear it, or cancel.
///
// Time-stamp: <2026-08-13>
///
/// Copyright (C) 2026, Togaware Pty Ltd
///
/// Licensed under the GNU General Public License, Version 3

library;

import 'package:flutter/material.dart';

/// Prompts for a due date, starting from [initialDate] (or today).
///
/// Unlike the plain `showDatePicker`, this offers a third option — "No Due
/// Date" — alongside Cancel and the calendar itself, for callers that need
/// to distinguish "the user picked a date", "the user explicitly cleared
/// it", and "the user backed out, leave things as they were".
///
/// Returns a record: `cancelled: true` means leave the due date unchanged;
/// otherwise `dueDate` is the chosen date, or `null` for "No Due Date".
Future<({bool cancelled, DateTime? dueDate})> showDueDatePickerDialog(
  BuildContext context, {
  DateTime? initialDate,
}) async {
  var selected = initialDate ?? DateTime.now();

  final result = await showDialog<({bool cancelled, DateTime? dueDate})>(
    context: context,
    barrierDismissible: false,
    builder: (context) => StatefulBuilder(
      builder: (context, setState) => AlertDialog(
        title: const Text('Due Date'),
        content: SizedBox(
          width: 320,
          height: 380,
          child: CalendarDatePicker(
            initialDate: selected,
            firstDate: DateTime(2020),
            lastDate: DateTime(2100),
            onDateChanged: (d) => setState(() => selected = d),
          ),
        ),
        actionsAlignment: MainAxisAlignment.spaceBetween,
        actions: [
          TextButton(
            onPressed: () =>
                Navigator.of(context).pop((cancelled: false, dueDate: null)),
            child: const Text('No Due Date'),
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextButton(
                onPressed: () =>
                    Navigator.of(context).pop((cancelled: true, dueDate: null)),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: () => Navigator.of(
                  context,
                ).pop((cancelled: false, dueDate: selected)),
                child: const Text('Set'),
              ),
            ],
          ),
        ],
      ),
    ),
  );

  return result ?? (cancelled: true, dueDate: null);
}
