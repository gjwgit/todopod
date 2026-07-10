/// TodoPod — the primary [MaterialApp] widget.
///
// Time-stamp: <Friday 2026-07-10 17:24:31 +1000 Graham Williams>
///
/// Copyright (C) 2026, Togaware Pty Ltd
///
/// Licensed under the GNU General Public License, Version 3 (the "License").
///
/// License: https://opensource.org/license/gpl-3-0.
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

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';

import 'package:solidui/solidui.dart';

import 'package:todopod/app_scaffold.dart';
import 'package:todopod/constants/app.dart';

// 20260429 gjw This widget is the root of the application. On startup it will
// call upon [SolidLogin] to connect to the user's Pod stored within the user's
// data vault on their chosen Solid server.

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return SolidThemeApp(
      // 20260429 gjw We can manually turn off the debug banner. It is turned
      // off automatically for a `flutter --release`.
      //
      debugShowCheckedModeBanner: true,

      title: appTitle,

      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF3A6B3A)),
        useMaterial3: true,
      ),

      home: SolidLogin(
        required: false,
        appDirectory: appDirectory,
        title: appTitle.replaceAll(' - ', '\n'),
        image: const AssetImage('assets/images/app_image.jpg'),
        logo: const AssetImage('assets/images/app_icon.png'),
        link: 'https://github.com/gjwgit/todopod',
        clientId: 'https://gjwgit.github.io/todopod/client-profile.jsonld',
        redirectUris: kIsWeb
            ? ['${Uri.base.origin}/redirect.html']
            : const [
                'com.togaware.todopod://redirect',
                'http://localhost:4400/redirect.html',
              ],
        child: appScaffold,
      ),
    );
  }
}
