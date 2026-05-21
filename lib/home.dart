/// TodoPod — home page with welcome card and security-key bootstrap.
///
// Time-stamp: <2026-05-20>
///
/// Copyright (C) 2026, Togaware Pty Ltd
///
/// Licensed under the GNU General Public License, Version 3 (the "License").
///
/// License: https://opensource.org/license/gpl-3-0
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
// this program. If not, see <https://opensource.org/license/gpl-3-0>.
///
/// Authors: Graham Williams

library;

import 'package:flutter/material.dart';

import 'package:provider/provider.dart';
import 'package:solidpod/solidpod.dart';
import 'package:solidui/solidui.dart';

import 'package:todopod/constants/app.dart';
import 'package:todopod/services/app_provider.dart';

/// The landing page after login.
///
/// Shows a welcome card describing the app, and on first build prompts the
/// user for their security key (if not already cached) before triggering
/// the initial load of tasks from the Pod.
class Home extends StatefulWidget {
  const Home({super.key, required this.title});

  final String title;

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  @override
  void initState() {
    super.initState();
    // Defer to the first frame so context is fully wired up before we
    // touch SolidPod APIs that may show a dialog.
    WidgetsBinding.instance.addPostFrameCallback((_) => _initKeys());
  }

  /// Prompt for the security key if it isn't already cached, then trigger
  /// the initial pull of tasks from the Pod. Updates [AppProvider.isKeySaved]
  /// so the status-bar badge in [AppScaffold] reflects the new state.
  Future<void> _initKeys() async {
    try {
      // Only proceed if actually logged in to a Pod.
      final webId = await getWebId();
      if (webId == null || webId.isEmpty) return;
      if (!mounted) return;

      await getKeyFromUserIfRequired(context, widget);
      if (!mounted) return;

      final provider = context.read<AppProvider>();
      provider.setKeySaved(true);
      await provider.loadFromPod();
    } on Exception catch (e) {
      debugPrint('[Home] key/load error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Center(
        child: Card(
          child: Padding(
            padding: const EdgeInsets.all(32.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.checklist,
                  size: 64,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(height: 16),
                Text(
                  widget.title,
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                const SizedBox(height: 24),
                Text(
                  'Welcome to TodoPod!\n\n'
                  'TodoPod is a Trello-like task manager that stores '
                  'your tasks encrypted in your personal Solid Pod, so '
                  'your data stays under your control.\n\n'
                  'Key features:\n\n'
                  '• Tasks list ordered by priority\n'
                  '• Kanban board, drag cards between priorities\n'
                  '• Planner calendar by due date\n'
                  '• Done list with one-tap restore\n'
                  '• Import / export in the open todo.txt format\n'
                  '• Share task lists with other Pod owners\n'
                  '• Security key management for encrypted data\n'
                  '• Theme switching (light / dark / system)\n\n'
                  'Use the navigation menu to get started.',
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
                const SizedBox(height: 16),
                Text(
                  appName,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
