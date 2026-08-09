/// Parse a free-text task duration into total minutes, for sorting.
///
// Time-stamp: <2026-08-09>
///
/// Copyright (C) 2026, Togaware Pty Ltd
///
/// Licensed under the GNU General Public License, Version 3

library;

final _hoursMinutes = RegExp(r'^(?:(\d+)h)?(?:(\d+)(?:min|m))?$');

/// Parses the accepted duration formats (bare integer minutes, 1h, 30m,
/// 2h30m, 15min) into total minutes. Returns null for anything that doesn't
/// match, so callers can treat it the same as no duration at all.
int? durationMinutes(String? duration) {
  if (duration == null) return null;
  final text = duration.trim();

  final bareMinutes = int.tryParse(text);
  if (bareMinutes != null) return bareMinutes;

  final match = _hoursMinutes.firstMatch(text);
  if (match == null) return null;
  final hours = int.tryParse(match.group(1) ?? '');
  final minutes = int.tryParse(match.group(2) ?? '');
  if (hours == null && minutes == null) return null;

  return (hours ?? 0) * 60 + (minutes ?? 0);
}
