/// TodoPod — application scaffold configuration.
///
// Time-stamp: <Tuesday 2026-05-26 05:58:35 +1000 Graham Williams>
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
import 'package:solidui/solidui.dart';

import 'package:todopod/constants/app.dart';
import 'package:todopod/home.dart';
import 'package:todopod/screens/done_screen.dart';
import 'package:todopod/screens/import_screen.dart';
import 'package:todopod/screens/kanban_screen.dart';
import 'package:todopod/screens/planner_screen.dart';
import 'package:todopod/screens/settings_screen.dart';
import 'package:todopod/screens/tasks_screen.dart';
import 'package:todopod/services/app_provider.dart';
import 'package:todopod/widgets/pod_refresh_action.dart';

const appScaffold = AppScaffold();

class AppScaffold extends StatelessWidget {
  const AppScaffold({super.key});

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

          TodoPod is a Trello-like personal task manager that allows you to manage
          your tasks as a list, a kanban, or a planner/calendar. All data is
          stored securely and privately on your personal online data store (Pod)
          hosted on a Solid server.

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
          SolidMenuItem(
            title: 'Home',
            icon: Icons.home,
            tooltip: '**Home**\n\nWelcome page with an overview of TodoPod.',
            child: Home(title: appTitle.split(' - ')[0]),
          ),
          const SolidMenuItem(
            title: 'Tasks',
            icon: Icons.checklist,
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
            title: 'Backup',
            icon: Icons.save_alt,
            tooltip:
                '**Backup**\n\n'
                'Back up and restore all tasks, or import and export '
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
