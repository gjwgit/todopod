/// App-wide constants for TodoPod.
///
// Time-stamp: <Friday 2026-03-27 10:00:00 +1100 Graham Williams>
///
/// Copyright (C) 2026, Togaware Pty Ltd
///
/// Licensed under the GNU General Public License, Version 3 (the "License");
///
/// License: https://opensource.org/license/gpl-3-0

library;

import 'package:flutter/material.dart';

/// Application name displayed in the UI.

const appName = 'TodoPod';

/// Application version.

const appVersion = '0.1.0';

/// Application description.

const appDescription =
    'A privacy-first todo list using the todo.txt format, '
    'stored encrypted on your Solid Pod.';

/// App directory name used by solidpod for storage paths.

const appDirectory = 'todopod';

/// Pod filename for active tasks (relative to app directory).

const todoFileName = 'todo.ttl';

/// Pod filename for completed tasks (relative to app directory).

const doneFileName = 'done.ttl';

/// Priority labels mapping priority letter to user-facing meaning.

const priorityLabels = {
  'A': 'Now',
  'B': 'Today',
  'C': 'This Week',
  'D': 'Next Week',
  'E': 'Later',
  'F': 'Parked',
};

/// All valid priority letters.

const priorities = ['A', 'B', 'C', 'D', 'E', 'F'];

/// Colours for each priority badge.
///
/// A = Red        — Now (urgent)
/// B = DeepOrange — Today
/// C = Teal       — This Week
/// D = Blue       — Next Week
/// E = Purple     — Later
/// F = BlueGrey   — Parked

const priorityColors = {
  'A': Color(0xFFC62828), // red.shade800     — Now (urgent, deep red)
  'B': Color(0xFFF57C00), // orange.shade700   — Today (bright orange)
  'C': Color(0xFF00796B), // teal.shade700     — This Week
  'D': Color(0xFF1976D2), // blue.shade700     — Next Week
  'E': Color(0xFF7B1FA2), // purple.shade700   — Later
  'F': Color(0xFF546E7A), // blueGrey.shade600 — Parked
};
