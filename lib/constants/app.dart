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

/// Pod path prefix for data files.

const podDataPath = 'todopod/data';

/// Pod filename for active tasks.

const todoFileName = 'todo.ttl';

/// Pod filename for completed tasks.

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
