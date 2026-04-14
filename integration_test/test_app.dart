/// A minimal test harness app for TodoPod integration tests.
///
/// Bypasses SolidLogin and injects a pre-loaded AppProvider so tests
/// can exercise the full widget tree without a live Solid Pod.

library;

import 'package:flutter/material.dart';

import 'package:provider/provider.dart';

import 'package:todopod/screens/done_screen.dart';
import 'package:todopod/screens/import_screen.dart';
import 'package:todopod/screens/settings_screen.dart';
import 'package:todopod/screens/tasks_screen.dart';
import 'package:todopod/services/app_provider.dart';

/// Build a testable MaterialApp with [provider] injected.
/// Uses _TestScaffold which skips all pod/key initialisation so no
/// security-key error messages appear in test output.
Widget buildTestApp(AppProvider provider) {
  return ChangeNotifierProvider<AppProvider>.value(
    value: provider,
    child: MaterialApp(
      title: 'TodoPod Test',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF3A6B3A)),
        useMaterial3: true,
      ),
      home: const _TestScaffold(),
    ),
  );
}

/// Create a provider pre-loaded with todo.txt content.
AppProvider providerWith({
  String todo = '',
  String done = '',
}) {
  final p = AppProvider();
  p.loadFromContent(todoContent: todo, doneContent: done);
  return p;
}

// ── Test scaffold ─────────────────────────────────────────────────────────────
//
// Mirrors the navigation structure of AppScaffold but without any solidpod,
// solidui, or key-management code. This keeps test output clean.

class _TestScaffold extends StatefulWidget {
  const _TestScaffold();

  @override
  State<_TestScaffold> createState() => _TestScaffoldState();
}

class _TestScaffoldState extends State<_TestScaffold> {
  int _index = 0;

  static const _titles = ['Tasks', 'Done', 'Import / Export', 'Settings'];
  static const _icons = [
    Icons.checklist,
    Icons.check_circle_outline,
    Icons.import_export,
    Icons.settings,
  ];
  static const _screens = [
    TasksScreen(),
    DoneScreen(),
    ImportScreen(),
    SettingsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          NavigationRail(
            selectedIndex: _index,
            onDestinationSelected: (i) => setState(() => _index = i),
            labelType: NavigationRailLabelType.all,
            destinations: [
              for (int i = 0; i < _titles.length; i++)
                NavigationRailDestination(
                  icon: Icon(_icons[i]),
                  label: Text(_titles[i]),
                ),
            ],
          ),
          const VerticalDivider(thickness: 1, width: 1),
          // Each screen owns its own FAB via its internal Scaffold.
          Expanded(child: _screens[_index]),
        ],
      ),
    );
  }
}
