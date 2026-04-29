/// TodoPod — privacy-first todo list with Solid Pod storage main entry point.
///
// Time-stamp: <Wednesday 2026-04-29 15:16:11 +1000 Graham Williams>
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
// this program.  If not, see <https://opensource.org/license/gpl-3-0>.
///
/// This main.dart can be used as a template for any solidui base app (and in
/// general for any Flutter app). It contains no app specific settings but
/// includes some settings that you may want to tune, like the minimum window
/// size for desktop apps, etc.
///
/// Authors: Graham Williams

library;

import 'package:flutter/material.dart';

import 'package:provider/provider.dart';
import 'package:solidui/solidui.dart';

import 'package:todopod/app_scaffold.dart';
import 'package:todopod/constants/app.dart';
import 'package:todopod/services/app_provider.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialise SolidUI security key manager so it can automatically prompt
  // the user for their security key whenever solidpod needs it.

  SolidSecurityKeyCentralManager.instance;

  runApp(
    ChangeNotifierProvider(
      create: (_) => AppProvider(),
      child: const TodoPodApp(),
    ),
  );
}

class TodoPodApp extends StatefulWidget {
  const TodoPodApp({super.key});

  @override
  State<TodoPodApp> createState() => _TodoPodAppState();
}

class _TodoPodAppState extends State<TodoPodApp> {
  @override
  void initState() {
    super.initState();
    _initTheme();
    solidThemeNotifier.addListener(() => setState(() {}));
  }

  Future<void> _initTheme() async {
    await solidThemeNotifier.initialize();
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: appTitle,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF3A6B3A)),
        useMaterial3: true,
      ),
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF3A6B3A),
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
      ),
      themeMode: solidThemeNotifier.themeMode,
      home: SolidLogin(
        required: false,
        appDirectory: appDirectory,
        title: appName.toUpperCase(),
        image: const AssetImage('assets/images/app_image.jpg'),
        logo: const AssetImage('assets/images/app_icon.png'),
        link: 'https://github.com/gjwgit/todopod',
        child: const AppScaffold(),
      ),
    );
  }
}
