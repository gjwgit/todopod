/// SnackBar helper — consistent, understated transient feedback.
///
// Time-stamp: <Wednesday 2026-07-29 09:00:00 +1000 Graham Williams>
///
/// Copyright (C) 2026, Togaware Pty Ltd
///
/// Licensed under the GNU General Public License, Version 3 (the "License");
///
/// License: https://opensource.org/license/gpl-3-0

library;

import 'dart:async';

import 'package:flutter/material.dart';

import 'package:gap/gap.dart';

import 'package:todopod/constants/app.dart';

/// Confirm [message] with a soft green SnackBar that auto-dismisses.
///
/// Pass [actionLabel] and [onAction] together to add a button, e.g. Restore.
///
/// There is no negative variant yet, on purpose — nothing needs one, and we
/// don't carry unused code. To add one when it is needed, mirror this with a
/// `snackBarNegative` bar colour and `Icons.info_outline`, and keep it for
/// outcomes worth noticing but not worth interrupting for. Real errors still
/// belong in a modal dialog, which forces acknowledgement.

void showPositiveSnackBar(
  BuildContext context,
  String message, {
  String? actionLabel,
  VoidCallback? onAction,
  Duration duration = snackBarDuration,
}) {
  unawaited(
    _show(
      context,
      _positiveSnackBar(
        message,
        actionLabel: actionLabel,
        onAction: onAction,
        duration: duration,
      ),
      duration,
    ),
  );
}

/// Show [bar] and make sure it goes away again.
///
/// A SnackBar carrying an action is not always timed out by Flutter itself:
/// when accessibility features are active it deliberately leaves an
/// actionable SnackBar on screen until the action or the close button is
/// tapped, which is why the Undo bar sat there indefinitely. Graham wants an
/// action AND auto-dismiss, so the bar is hidden here once [duration] has
/// passed. The grace period means we only step in if Flutter's own timer did
/// not, and the `open` flag means we never hide a later, unrelated SnackBar.

Future<void> _show(
  BuildContext context,
  SnackBar bar,
  Duration duration,
) async {
  final messenger = ScaffoldMessenger.of(context);
  final controller = messenger.showSnackBar(bar);

  var open = true;
  unawaited(controller.closed.then((_) => open = false));

  await Future<void>.delayed(duration + const Duration(milliseconds: 250));
  if (open) messenger.hideCurrentSnackBar();
}

/// The bar itself.
///
/// Text, icon and action are near-black for contrast against the light pastel
/// bar. The floating behaviour, elevation and shape come from `snackBarTheme`
/// in app.dart, whose neutral dark background is overridden here.

SnackBar _positiveSnackBar(
  String message, {
  required Duration duration,
  String? actionLabel,
  VoidCallback? onAction,
}) => SnackBar(
  duration: duration,
  backgroundColor: snackBarPositive,
  content: Row(
    children: [
      const Icon(Icons.check_circle_outline, size: 18, color: snackBarInk),
      const Gap(12),
      Expanded(
        child: Text(
          message,
          style: const TextStyle(color: snackBarInk, fontSize: 14),
        ),
      ),
    ],
  ),
  action: (actionLabel != null && onAction != null)
      ? SnackBarAction(
          label: actionLabel,
          textColor: snackBarInk,
          onPressed: onAction,
        )
      : null,
);
