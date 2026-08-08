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

import 'package:flutter/material.dart';

import 'package:provider/provider.dart';
import 'package:solidui/solidui.dart';
import 'package:window_manager/window_manager.dart';

import 'package:todopod/app.dart';
import 'package:todopod/constants/app.dart';
import 'package:todopod/services/app_provider.dart';

// 20260520 gjw Below is the main entry point for the application. For main()
// we require [async] because we asynchronously [await] the window manager as
// below. Often, main() will include just the call to runApp().

void main() async {
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

    const windowOptions = WindowOptions(
      title: appTitle,
      minimumSize: Size(500, 800),
      backgroundColor: Colors.transparent,
      skipTaskbar: false,
      titleBarStyle: TitleBarStyle.normal,
    );

    // 20260520 gjw Now we await the window being shown and receiving the
    // focus, to then proceed to run the app.

    await windowManager.waitUntilReadyToShow(windowOptions, () async {
      await windowManager.show();
      await windowManager.focus();
    });
  }

  // 20260520 gjw The runApp() function takes the given Widget and makes it
  // the root of the widget tree. AppProvider is provided here so the entire
  // tree (App -> AppScaffold -> screens -> Home) can read and watch it.

  runApp(
    ChangeNotifierProvider(create: (_) => AppProvider(), child: const App()),
  );
}
