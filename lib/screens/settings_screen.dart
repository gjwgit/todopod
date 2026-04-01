/// SettingsScreen — pod sharing and app preferences.
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

import 'package:gap/gap.dart';
import 'package:solidui/solidui.dart';

import 'package:todopod/constants/app.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Priority guide ─────────────────────────────────────────
          Text('Priority Guide', style: Theme.of(context).textTheme.titleLarge),
          const Gap(12),
          ...priorityLabels.entries.map(
            (e) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: _priorityColor(e.key, cs),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      e.key,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                      ),
                    ),
                  ),
                  const Gap(12),
                  Text(e.value, style: const TextStyle(fontSize: 14)),
                ],
              ),
            ),
          ),

          // ── Sharing ────────────────────────────────────────────────
          const Gap(32),
          Text('Sharing', style: Theme.of(context).textTheme.titleLarge),
          const Gap(8),
          Text(
            'Grant others access to your todo or done task lists '
            'on your Solid Pod.',
            style: TextStyle(color: cs.onSurfaceVariant, fontSize: 13),
          ),
          const Gap(16),
          OutlinedButton.icon(
            icon: const Icon(Icons.share_outlined),
            label: const Text('Manage Todo.txt permissions'),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute<void>(
                builder: (_) => GrantPermissionUi(
                  resourceName: todoFileName,
                  child: const _ReturnPage(),
                ),
              ),
            ),
          ),
          const Gap(12),
          OutlinedButton.icon(
            icon: const Icon(Icons.share_outlined),
            label: const Text('Manage Done.txt permissions'),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute<void>(
                builder: (_) => GrantPermissionUi(
                  resourceName: doneFileName,
                  child: const _ReturnPage(),
                ),
              ),
            ),
          ),
          const Gap(12),
          OutlinedButton.icon(
            icon: const Icon(Icons.folder_shared_outlined),
            label: const Text('View shared resources'),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute<void>(
                builder: (_) => const SharedResourcesUi(child: _ReturnPage()),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color _priorityColor(String p, ColorScheme cs) =>
      priorityColors[p] ?? cs.primary;
}

class _ReturnPage extends StatelessWidget {
  const _ReturnPage();

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text(appName)),
    body: Center(
      child: FilledButton.tonal(
        onPressed: () => Navigator.of(context).pop(),
        child: const Text('Return to Settings'),
      ),
    ),
  );
}
