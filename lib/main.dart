/// TodoPod — main entry for the app.
///
// Time-stamp: <Friday 2026-05-20 13:57:04 +1000 Graham Williams>
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
/// This main.dart can be used as a template for any solidui-based app (and in
/// general for any Flutter app). It contains no app-specific UI; the App
/// widget in `app.dart` is the root of the widget tree.
///
/// Authors: Graham Williams

library;

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';

import 'package:logging/logging.dart';
import 'package:provider/provider.dart';
import 'package:solidui/solidui.dart';
import 'package:universal_io/io.dart' show Platform;
import 'package:window_manager/window_manager.dart';

import 'package:todopod/app.dart';
import 'package:todopod/constants/app.dart';
import 'package:todopod/services/app_provider.dart';

// 20260920 gjw Send package:logging records to debugPrint so the internals
// of oidc and solid_auth can be seen while a login failure is diagnosed.
// Those packages log the interesting detail and nothing listens by default,
// so the evidence is discarded: notably OidcDefaultStore reports there that
// a keychain write failed and it has fallen back to shared_preferences,
// which is the difference between a broken keychain and a server refusing
// the request. Silent unless asked for, taking the level from the
// TODOPOD_LOG environment variable, so a user can reproduce a problem with
//
//   TODOPOD_LOG=ALL /Applications/todopod.app/Contents/MacOS/todopod
//
// and send back the output, while every other run stays quiet. An
// unrecognised level name turns everything on rather than failing.

void initLogging() {
  if (kIsWeb) return;

  final requested = Platform.environment['TODOPOD_LOG']?.trim();

  if (requested == null || requested.isEmpty) return;

  Logger.root.level = Level.LEVELS.firstWhere(
    (level) => level.name == requested.toUpperCase(),
    orElse: () => Level.ALL,
  );

  Logger.root.onRecord.listen((record) {
    final error = record.error == null ? '' : ' ERROR: ${record.error}';

    debugPrint(
      '${record.level.name} ${record.loggerName}: '
      '${record.message}$error',
    );
  });
}

// 20260520 gjw Below is the main entry point for the application. For main()
// we require [async] because we asynchronously [await] the window manager as
// below. Often, main() will include just the call to runApp().

void main() async {
  initLogging();

  // 20260520 gjw Optionally for development we utilise [debugPrint] to trace
  // execution, and note that the output is not shown on a `--release`. To
  // quieten the `--debug` running we can globally remove [debugPrint] messages
  // by mapping it to null (no op).
  //
  // debugPrint = (String? message, {int? wrapWidth}) {
  //   null;
  // };

  // 20260520 gjw We want to ensure Flutter bindings are initialised for async
  // operations particularly to set the Linux desktop window [title] as we do
  // below.

  WidgetsFlutterBinding.ensureInitialized();
  SolidSecurityKeyCentralManager.instance;

  if (isDesktop) {
    await windowManager.ensureInitialized();

    // 20260808 gjw Route the title-bar close button through the solidui close
    // guard instead of quitting immediately, so a task being edited with
    // unsaved changes can be saved or discarded rather than silently lost.
    // TaskEdit registers a resolver with the guard.

    await SolidWindowCloseGuard.enable();

    // 20260520 gjw For our desktop app we tune various window oriented
    // settings.
    //
    // 20260913 gjw Shown through solidui, which opens the window at the size
    // it was last left at and keeps that size up to date as it is resized.
    // The user sets the size, and turns remembering it off, under Settings in
    // the profile menu. Until a size has been remembered the window opens at
    // the default in `linux/my_application.cc`.

    await SolidWindowSize.show(
      const WindowOptions(
        title: appTitle,
        minimumSize: Size(500, 800),
        backgroundColor: Colors.transparent,
        skipTaskbar: false,
        titleBarStyle: TitleBarStyle.normal,
      ),
    );
  }

  // 20260520 gjw The runApp() function takes the given Widget and makes it
  // the root of the widget tree. AppProvider is provided here so the entire
  // tree (App -> AppScaffold -> screens -> Home) can read and watch it.

  runApp(
    ChangeNotifierProvider(create: (_) => AppProvider(), child: const App()),
  );
}
