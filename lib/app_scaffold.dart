/// AppScaffold — main SolidScaffold with left nav for TodoPod.
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

import 'package:provider/provider.dart';
import 'package:solidpod/solidpod.dart';
import 'package:solidui/solidui.dart';

import 'package:todopod/constants/app.dart';
import 'package:todopod/screens/done_screen.dart';
import 'package:todopod/screens/import_screen.dart';
import 'package:todopod/screens/settings_screen.dart';
import 'package:todopod/screens/tasks_screen.dart';
import 'package:todopod/services/app_provider.dart';

class AppScaffold extends StatefulWidget {
  const AppScaffold({super.key});

  @override
  State<AppScaffold> createState() => _AppScaffoldState();
}

class _AppScaffoldState extends State<AppScaffold> {
  bool _isKeySaved = false;

  @override
  void initState() {
    super.initState();
    // Prompt for security key if not cached, then load from pod.
    WidgetsBinding.instance.addPostFrameCallback((_) => _initKeys());
  }

  Future<void> _initKeys() async {
    try {
      // Only proceed if actually logged in to a pod.
      final webId = await getWebId();
      if (webId == null || webId.isEmpty) return;
      if (!mounted) return;

      await getKeyFromUserIfRequired(context, widget);
      if (!mounted) return;
      setState(() => _isKeySaved = true);
      await context.read<AppProvider>().loadFromPod();
    } on Exception catch (e) {
      debugPrint('[AppScaffold] key/load error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    context.watch<AppProvider>();

    return SolidScaffold(
      showLogout: false,
      appBar: const SolidAppBarConfig(
        title: appName,
        versionConfig: SolidVersionConfig(
          changelogUrl:
              'https://github.com/gjwgit/todopod/blob/dev/CHANGELOG.md',
        ),
      ),
      menu: const [
        SolidMenuItem(
          title: 'Tasks',
          icon: Icons.checklist,
          tooltip: '**Tasks**\n\nYour todo list.',
          child: TasksScreen(),
        ),
        SolidMenuItem(
          title: 'Done',
          icon: Icons.check_circle_outline,
          tooltip: '**Done**\n\nCompleted tasks. Tap the checkbox to restore.',
          child: DoneScreen(),
        ),
        SolidMenuItem(
          title: 'Import / Export',
          icon: Icons.import_export,
          tooltip:
              '**Import / Export**\n\n'
              'Import from Todo.txt or export a backup.',
          child: ImportScreen(),
        ),
        SolidMenuItem(
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
          isKeySaved: _isKeySaved,
          title: 'TodoPod Security Keys',
          tooltip:
              '**Security Keys**\n\n'
              'Manage your Solid Pod encryption key.\n'
              'Tap to view, change or forget the key.',
          onKeyStatusChanged: (hasKey) {
            final wasKeySaved = _isKeySaved;
            setState(() => _isKeySaved = hasKey);
            if (hasKey && !wasKeySaved) {
              context.read<AppProvider>().loadFromPod();
            }
          },
        ),
      ),
    );
  }
}
