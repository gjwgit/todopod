/// PodService — save and load encrypted task lists on a Solid Pod.
///
// Time-stamp: <Friday 2026-03-27 10:00:00 +1100 Graham Williams>
///
/// Copyright (C) 2026, Togaware Pty Ltd
///
/// Licensed under the GNU General Public License, Version 3 (the "License");
///
/// License: https://opensource.org/license/gpl-3-0

library;

import 'dart:convert';

import 'package:flutter/foundation.dart';

import 'package:solidpod/solidpod.dart';
import 'package:solidui/solidui.dart';

import 'package:todopod/constants/app.dart'; // todoFileName, doneFileName
import 'package:todopod/models/task.dart';

/// Handles reading and writing task lists to a Solid Pod.
///
/// Each task list is stored as a JSON array embedded as a literal in a
/// Turtle (.ttl) file, encrypted by solidpod. Two files are maintained:
/// [todoFileName] for active tasks and [doneFileName] for completed tasks.

class PodService {
  static const _prefixes =
      '@prefix todopod: <https://'
      'todopod.solidcommunity.au/ont/> .\n'
      '@prefix xsd:     <http://'
      'www.w3.org/2001/XMLSchema#> .\n';

  // ── Turtle helpers ────────────────────────────────────────────────────────

  static String _buildTtl(String fileName, String json) =>
      '$_prefixes\n'
      'todopod:${fileName.replaceAll('.', '_')} a todopod:TaskList ;\n'
      '  todopod:tasks """$json""" .\n';

  static String? _extractJson(String ttl) {
    final match = RegExp(
      r'todopod:tasks\s+"""(.*?)"""',
      dotAll: true,
    ).firstMatch(ttl);
    return match?.group(1)?.trim();
  }

  // ── Public API ────────────────────────────────────────────────────────────

  /// Save [tasks] to [fileName] on the pod.
  ///
  /// Returns an error message on failure, or null on success.

  static Future<String?> saveTasks(String fileName, List<Task> tasks) async {
    try {
      final json = jsonEncode(tasks.map((t) => t.toJson()).toList());
      final ttl = _buildTtl(fileName, json);
      await SolidPendingWrites.track(writePod(fileName, ttl, overwrite: true));
      return null;
    } catch (e) {
      debugPrint('[PodService] saveTasks error: $e');
      return e.toString();
    }
  }

  /// Load tasks from [fileName] on the pod.
  ///
  /// Returns null on failure (e.g. file not yet created).

  static Future<List<Task>?> loadTasks(String fileName) async {
    try {
      final ttl = await readPod(fileName);
      if (ttl.isEmpty) return null;
      final json = _extractJson(ttl);
      if (json == null || json.isEmpty) return [];
      final list = jsonDecode(json) as List;
      return list.map((j) => Task.fromJson(j as Map<String, dynamic>)).toList();
    } catch (e) {
      debugPrint('[PodService] loadTasks error ($fileName): $e');
      return null;
    }
  }
}
