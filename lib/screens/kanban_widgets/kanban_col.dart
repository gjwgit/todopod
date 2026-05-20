/// KanbanCol — extracted from kanban_screen.dart.
///
// Time-stamp: <2026-05-20>
///
/// Copyright (C) 2026, Togaware Pty Ltd
///
/// Licensed under the GNU General Public License, Version 3

library;

import 'package:flutter/material.dart';

import 'package:markdown_tooltip/markdown_tooltip.dart';
import 'package:provider/provider.dart';

import 'package:todopod/models/task.dart';
import 'package:todopod/services/app_provider.dart';
import 'package:todopod/services/task_actions.dart';

class KanbanCol {
  final String? priority; // null = No Priority
  final String label;
  final Color color;

  const KanbanCol(this.priority, this.label, this.color);
}
