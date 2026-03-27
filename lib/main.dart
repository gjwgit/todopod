/// TodoPod — privacy-first todo list with Solid Pod storage.
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

class TodoPodApp extends StatelessWidget {
  const TodoPodApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: appName,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF3A6B3A)),
        useMaterial3: true,
      ),
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
