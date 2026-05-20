/// ExportFilterChip — extracted from import_screen_widgets.dart.
///
// Time-stamp: <2026-05-20>
///
/// Copyright (C) 2026, Togaware Pty Ltd
///
/// Licensed under the GNU General Public License, Version 3

library;

import 'package:flutter/material.dart';

import 'package:gap/gap.dart';

import 'package:todopod/constants/app.dart';
import 'package:todopod/models/task.dart';

class ExportFilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  final ColorScheme cs;
  const ExportFilterChip({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
    required this.cs,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Chip(
        label: Text(label),
        labelStyle: TextStyle(
          fontSize: 12,
          color: selected ? cs.onPrimary : cs.onSurfaceVariant,
        ),
        backgroundColor: selected ? cs.primary : cs.surfaceContainerHighest,
        padding: EdgeInsets.zero,
        visualDensity: VisualDensity.compact,
      ),
    );
  }
}
