/// Normalise a free-text duration entry.
///
// Time-stamp: <2026-08-09>
///
/// Copyright (C) 2026, Togaware Pty Ltd
///
/// Licensed under the GNU General Public License, Version 3

library;

final _bareInteger = RegExp(r'^\d+$');

/// A duration typed as a bare integer (e.g. "30") is assumed to be minutes,
/// so it's stored as "30m" — consistent with the other accepted formats
/// (1h, 2h30m, 15min).
String normalizeDuration(String duration) =>
    _bareInteger.hasMatch(duration) ? '${duration}m' : duration;
