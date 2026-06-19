/// Reusable "refresh from Pod" app bar action.
///
/// Reloads the app's in-memory data from the Pod (which may have been updated
/// by another instance of the app or another app sharing the same Pod data),
/// then reports — via a simple OK dialog — whether anything changed.
///
/// REUSE PATTERN (for other apps in the suite):
///   1. Give the app's provider/service a `Future<bool> refreshFromPod()` that
///      reloads from the Pod and returns true iff the data changed (snapshot a
///      content signature, reload, compare — see TodoPod's AppProvider).
///   2. Add this action to the SolidAppBarConfig actions list:
///        actions: [
///          buildPodRefreshAction(
///            context: context,
///            onRefresh: provider.refreshFromPod,
///          ),
///        ]
///   3. Copy this file into the new app and adjust the import of nothing else —
///      it only depends on solidui and flutter.
///
// Time-stamp: <2026-06-19>
///
/// Copyright (C) 2025, Software Innovation Institute, ANU.
///
/// Licensed under the GNU General Public License, Version 3 (the "License").
///
/// License: https://opensource.org/license/gpl-3-0.

library;

import 'package:flutter/material.dart';

import 'package:solidui/solidui.dart';

/// Builds the refresh [SolidAppBarAction].
///
/// [onRefresh] reloads the in-memory data from the Pod and returns true if the
/// data changed (the Pod had been updated elsewhere), false if already current.
SolidAppBarAction buildPodRefreshAction({
  required BuildContext context,
  required Future<bool> Function() onRefresh,
  String tooltip = 'Refresh from Pod',
}) {
  return SolidAppBarAction(
    icon: Icons.refresh,
    tooltip: tooltip,
    onPressed: () => handlePodRefresh(context: context, onRefresh: onRefresh),
  );
}

/// Runs the refresh and shows the appropriate OK dialog.
///
/// Kept public and separate from [buildPodRefreshAction] so it can also be
/// triggered from elsewhere (e.g. a menu item or pull-to-refresh).
Future<void> handlePodRefresh({
  required BuildContext context,
  required Future<bool> Function() onRefresh,
}) async {
  bool changed;
  try {
    changed = await onRefresh();
  } catch (e) {
    if (!context.mounted) return;
    await _showRefreshDialog(
      context,
      title: 'Refresh failed',
      message: 'Could not refresh from your Pod.\n\n$e',
      icon: Icons.error_outline,
      iconColor: Colors.red,
    );
    return;
  }

  if (!context.mounted) return;

  if (changed) {
    await _showRefreshDialog(
      context,
      title: 'Data updated',
      message: 'Your data has been updated from changes made in your Pod '
          'outside this app.',
      icon: Icons.cloud_download_outlined,
      iconColor: Colors.green,
    );
  } else {
    await _showRefreshDialog(
      context,
      title: 'Already up to date',
      message: 'Your data is already up to date with your Pod. No changes were '
          'found.',
      icon: Icons.check_circle_outline,
      iconColor: Colors.blue,
    );
  }
}

Future<void> _showRefreshDialog(
  BuildContext context, {
  required String title,
  required String message,
  required IconData icon,
  required Color iconColor,
}) {
  return showDialog<void>(
    context: context,
    builder: (context) => AlertDialog(
      title: Row(
        children: [
          Icon(icon, color: iconColor),
          const SizedBox(width: 8),
          Expanded(child: Text(title)),
        ],
      ),
      content: Text(message),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('OK'),
        ),
      ],
    ),
  );
}
