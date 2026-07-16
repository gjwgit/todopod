/// TodoPod — application scaffold configuration.
///
// Time-stamp: <Friday 2026-07-17 09:00:52 +1000 Graham Williams>
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
import 'package:todopod/screens/done_screen.dart';
import 'package:todopod/screens/import_screen.dart';
import 'package:todopod/screens/kanban_screen.dart';
import 'package:todopod/screens/planner_screen.dart';
import 'package:todopod/screens/settings_screen.dart';
import 'package:todopod/screens/tasks_screen.dart';
import 'package:todopod/services/app_provider.dart'
    show AppProvider, StartupPhase;
import 'package:todopod/widgets/pod_refresh_action.dart';

const appScaffold = AppScaffold();

class AppScaffold extends StatefulWidget {
  const AppScaffold({super.key});

  @override
  State<AppScaffold> createState() => _AppScaffoldState();
}

class _AppScaffoldState extends State<AppScaffold> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _initKeys());
  }

  Future<void> _initKeys() async {
    final provider = context.read<AppProvider>();
    provider.setStartupPhase(StartupPhase.unlocking);
    try {
      final webId = await getWebId();
      if (webId == null || webId.isEmpty) return;
      if (!mounted) return;
      await getKeyFromUserIfRequired(context, widget);
      if (!mounted) return;
      provider.setStartupPhase(StartupPhase.loading);
      await provider.loadFromPod();
    } on Exception catch (e) {
      debugPrint('[AppScaffold] key/load error: $e');
    } finally {
      provider.setStartupPhase(StartupPhase.ready);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Only rebuild this scaffold when isKeySaved itself changes — not on
    // every AppProvider notify (which happens on loads, edits, sorts,
    // filters, etc).
    return Selector<AppProvider, bool>(
      selector: (_, p) => p.isKeySaved,
      builder: (context, isKeySaved, _) => SolidScaffold(
        aboutConfig: SolidAboutConfig(
          applicationName: appTitle.split(' - ')[0],
          applicationIcon: Image.asset(
            'assets/images/app_icon.png',
            width: 64,
            height: 64,
          ),
          applicationLegalese: '''

          © 2026 Togaware Pty Ltd

          ''',
          text: '''

          TodoPod is a Trello-like personal task manager that stores your tasks
          encrypted in your personal Solid Pod, so your data stays under your
          control. Your Solid Pod can be hosted on any Solid server and being
          encrypted it is protected against casual access to your data by
          anyone, including the server administrators.

          ### Key features

          - Tasks list ordered by priority
          - Kanban boards to drag cards between priorities/contexts
          - Planner calendar by due date with tasks marked
          - Done list with one-tap restore
          - Import/export of the open todo.txt format
          - Share task lists with other Pod owners
          - Security key management for encrypted data
          - Theme switching (light / dark / system)

          For more information, visit the
          [TodoPod](https://github.com/gjwgit/todopod) GitHub repository and our
          [Australian Solid Community](https://solidcommunity.au) web site.

          ''',
          readmeUrl: 'https://gjwgit.github.io/todopod',
        ),
        themeToggle: const SolidThemeToggleConfig(enabled: true),
        appBar: SolidAppBarConfig(
          title: appTitle.split(' - ')[0],
          versionConfig: const SolidVersionConfig(
            changelogUrl:
                'https://github.com/gjwgit/todopod/blob/dev/CHANGELOG.md',
          ),
          actions: [
            buildPodRefreshAction(
              context: context,
              onRefresh: context.read<AppProvider>().refreshFromPod,
            ),
          ],
        ),
        menu: [
          const SolidMenuItem(
            title: 'Tasks',
            icon: Icons.home,
            tooltip: '**Tasks**\n\nYour todo list.',
            child: TasksScreen(),
          ),
          const SolidMenuItem(
            title: 'Kanban',
            icon: Icons.view_kanban_outlined,
            tooltip:
                '**Kanban**\n\n'
                'Board view of tasks by priority. '
                'Long-press and drag a card to change its priority.',
            child: KanbanScreen(),
          ),
          const SolidMenuItem(
            title: 'Planner',
            icon: Icons.calendar_month_outlined,
            tooltip:
                '**Planner**\n\n'
                'Calendar view of tasks by due date. '
                'Tap a day to see what is due.',
            child: PlannerScreen(),
          ),
          const SolidMenuItem(
            title: 'Done',
            icon: Icons.check_circle_outline,
            tooltip:
                '**Done**\n\nCompleted tasks. Tap the checkbox to restore.',
            child: DoneScreen(),
          ),
          const SolidMenuItem(
            title: 'Export/Import',
            icon: Icons.save_alt,
            tooltip:
                '**Export/Import**\n\n'
                'Export and import all tasks to/from JSON, or import and export '
                'Todo.txt files.',
            child: ImportScreen(),
          ),
          const SolidMenuItem(
            title: 'Settings',
            icon: Icons.settings,
            tooltip:
                '**Settings**\n\n'
                'Priority guide, sharing and preferences.',
            child: SettingsScreen(),
          ),
        ],
        statusBar: SolidStatusBarConfig(
          loginStatus: const SolidLoginStatus(),
          serverInfo: const SolidServerInfo(
            serverUri: SolidConfig.defaultServerUrl,
          ),
          securityKeyStatus: SolidSecurityKeyStatus(
            isKeySaved: isKeySaved,
            title: 'TodoPod Security Keys',
            tooltip:
                '**Security Keys**\n\n'
                'Manage your Solid Pod encryption key.\n'
                'Tap to view, change or forget the key.',
            onKeyStatusChanged: (hasKey) {
              final provider = context.read<AppProvider>();
              final wasKeySaved = provider.isKeySaved;
              provider.setKeySaved(hasKey);
              if (hasKey && !wasKeySaved) {
                provider.loadFromPod();
              }
            },
          ),
        ),
      ),
    );
  }
}
