/// TodoPod - app-wide constants.
///
// Time-stamp: <Saturday 2026-07-04 08:45:39 +1000 Graham Williams>
///
/// Copyright (C) 2026, Togaware Pty Ltd
///
/// Licensed under the GNU General Public License, Version 3 (the "License");
///
/// License: https://opensource.org/license/gpl-3-0
//
//
// This program is free software: you can redistribute it and/or modify it under
// the terms of the GNU General Public License as published by the Free Software
// Foundation, either version 3 of the License, or (at your option) any later
// version.
//
// This program is distributed in the hope that it will be useful, but WITHOUT
// ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
// FOR A PARTICULAR PURPOSE. See the GNU General Public License for more
// details.
//
// You should have received a copy of the GNU General Public License along with
// this program.  If not, see <https://opensource.org/license/gpl-3-0>.
///
/// Authors: Graham Williams

library;

import 'package:flutter/material.dart';

/// Application name displayed in the UI.

const appName = 'TodoPod';

/// Application title displayed as the window title.

const String appTitle = 'TodoPod - Manage Daily Tasks';

/// Application version.

// const appVersion = '0.1.0';

/// Application description.

// const appDescription =
//    'A privacy-first todo list using the todo.txt format, '
//    'stored encrypted on your Solid Pod.';

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

const priorityColors = {
  'A': Color(0xFFC62828), // red.shade800     — Now (urgent, deep red)
  'B': Color(0xFFF57C00), // orange.shade700   — Today (bright orange)
  'C': Color(0xFF00796B), // teal.shade700     — This Week
  'D': Color(0xFF1976D2), // blue.shade700     — Next Week
  'E': Color(0xFF7B1FA2), // purple.shade700   — Later
  'F': Color(0xFF546E7A), // blueGrey.shade600 — Parked
};
