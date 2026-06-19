/// Reusable startup busy overlay.
///
/// Shows a centered progress indicator with a phase-aware message while the app
/// unlocks the Pod (security key) and then loads data. Without this, startup
/// for a large data set looks like the app is frozen — and the transient
/// "security key not available" state is confusing.
///
/// REUSE PATTERN (for other apps in the suite):
///   1. Give the provider a `StartupPhase` (idle / unlocking / loading / ready)
///      and an `isStartingUp` getter, set through the startup sequence.
///   2. Wrap the landing screen body so the overlay shows while starting up:
///        final phase = context.watch`<`AppProvider`>`().startupPhase;
///        return StartupOverlay(phase: phase, child: `<`normal body`>`);
///   3. Also branch list screens on a unified `busy` getter (loading ||
///      isStartingUp) so the empty state never flashes between phases.
///   4. Copy this file in; adjust only the StartupPhase import to the app.
///
// Time-stamp: <2026-06-19>
///
/// Copyright (C) 2025, Software Innovation Institute, ANU.
///
/// Licensed under the GNU General Public License, Version 3 (the "License").
///
/// License: https://opensource.org/license/gpl-3-0.

library;

import 'package:flutter/material.dart';

import 'package:todopod/services/app_provider.dart' show StartupPhase;

/// Human-readable message for each startup phase.
String startupPhaseMessage(StartupPhase phase) {
  switch (phase) {
    case StartupPhase.unlocking:
      return 'Unlocking your Pod…';
    case StartupPhase.loading:
      return 'Loading your data…';
    case StartupPhase.idle:
    case StartupPhase.ready:
      return '';
  }
}

/// Overlays a busy indicator over [child] while [phase] is unlocking/loading.
///
/// When not starting up, [child] is shown unchanged.
class StartupOverlay extends StatelessWidget {
  const StartupOverlay({super.key, required this.phase, required this.child});

  final StartupPhase phase;
  final Widget child;

  bool get _busy =>
      phase == StartupPhase.unlocking || phase == StartupPhase.loading;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        child,
        if (_busy)
          Positioned.fill(
            child: ColoredBox(
              color: Theme.of(
                context,
              ).colorScheme.surface.withValues(alpha: 0.85),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const CircularProgressIndicator(),
                    const SizedBox(height: 20),
                    Text(
                      startupPhaseMessage(phase),
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }
}
