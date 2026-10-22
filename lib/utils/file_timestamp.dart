/// Timestamp for exported filenames.
///
// Time-stamp: <2026-10-22>
///
/// Copyright (C) 2026, Togaware Pty Ltd
///
/// Licensed under the GNU General Public License, Version 3

library;

/// Zero-padded timestamp string for filenames: YYYYMMDD_HHMM.

String fileTimestamp(DateTime t) =>
    '${t.year}${t.month.toString().padLeft(2, '0')}${t.day.toString().padLeft(2, '0')}'
    '_${t.hour.toString().padLeft(2, '0')}${t.minute.toString().padLeft(2, '0')}';
