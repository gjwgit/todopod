/// ReturnPage — extracted from settings_screen.dart.
///
// Time-stamp: <2026-05-20>
///
/// Copyright (C) 2026, Togaware Pty Ltd
///
/// Licensed under the GNU General Public License, Version 3

library;

import 'package:flutter/material.dart';

import 'package:gap/gap.dart';
import 'package:solidui/solidui.dart';

import 'package:todopod/constants/app.dart';

class ReturnPage extends StatelessWidget {
  const ReturnPage();

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
