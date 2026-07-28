/// ViewPrefs — device-local view preferences.
///
// Time-stamp: <Tuesday 2026-07-28 09:00:00 +1000 Graham Williams>
///
/// Copyright (C) 2026, Togaware Pty Ltd
///
/// Licensed under the GNU General Public License, Version 3 (the "License");
///
/// License: https://opensource.org/license/gpl-3-0

library;

import 'package:shared_preferences/shared_preferences.dart';

/// Per-device display choices, remembered between sessions.
///
/// Deliberately SharedPreferences ONLY. These are device preferences, never
/// written to the Pod, so a stale Pod copy cannot overwrite them on login.
/// Every read takes an explicit default, so a missing key is not an error.

class ViewPrefs {
  ViewPrefs._();

  /// Overdue screen: true when the oldest due date is listed first.

  static const overdueOldestFirst = 'overdue_oldest_first';

  static Future<bool> getBool(String key, {required bool orElse}) async {
    final prefs = await SharedPreferences.getInstance();

    return prefs.getBool(key) ?? orElse;
  }

  static Future<void> setBool(String key, bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(key, value);
  }
}
