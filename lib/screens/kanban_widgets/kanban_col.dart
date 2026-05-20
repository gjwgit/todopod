/// KanbanCol — extracted from kanban_screen.dart.
///
// Time-stamp: <2026-05-20>
///
/// Copyright (C) 2026, Togaware Pty Ltd
///
/// Licensed under the GNU General Public License, Version 3

library;

import 'package:flutter/material.dart';

class KanbanCol {
  final String? priority; // null = No Priority
  final String label;
  final Color color;

  const KanbanCol(this.priority, this.label, this.color);
}
