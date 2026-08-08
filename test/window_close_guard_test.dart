// Widget tests for SolidWindowCloseGuard as wired up by TaskEdit — the
// window-close confirmation path (save / discard / keep editing).
//
// Runs without a live Pod: only rendering / state behaviour.

import 'dart:async';

import 'package:flutter/material.dart';

import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:solidui/solidui.dart';

import 'package:todopod/pages/task_edit.dart';
import 'package:todopod/services/app_provider.dart';

Widget wrap(Widget child) => ChangeNotifierProvider(
  create: (_) => AppProvider(),
  child: MaterialApp(home: child),
);

/// Pump [editor] and settle.
///
/// The test-only font draws every glyph as a fixed-width box, so the priority
/// dropdown's label overflows its row here although it fits in the real app.
/// That layout complaint is ignored rather than allowed to fail these tests,
/// which are about the close-guard behaviour, not the layout.
Future<void> pumpEditor(WidgetTester tester, Widget editor) async {
  final onError = FlutterError.onError;
  FlutterError.onError = (details) {
    if (details.exceptionAsString().startsWith('A RenderFlex overflowed')) {
      return;
    }
    onError?.call(details);
  };
  addTearDown(() => FlutterError.onError = onError);

  await tester.pumpWidget(wrap(editor));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('resolveAll succeeds with no prompt when nothing changed', (
    tester,
  ) async {
    await pumpEditor(tester, const TaskEdit());
    expect(await SolidWindowCloseGuard.resolveAll(), isTrue);
    expect(find.text('Unsaved changes'), findsNothing);
  });

  testWidgets('resolveAll prompts and resolves true on Discard', (
    tester,
  ) async {
    await pumpEditor(tester, const TaskEdit());
    await tester.enterText(find.byType(TextField).first, 'New task');
    await tester.pump();

    final future = SolidWindowCloseGuard.resolveAll();
    await tester.pumpAndSettle();
    expect(find.text('Unsaved changes'), findsOneWidget);

    await tester.tap(find.text('Discard'));
    await tester.pumpAndSettle();
    expect(await future, isTrue);
  });

  testWidgets('resolveAll prompts and resolves false on Keep editing', (
    tester,
  ) async {
    await pumpEditor(tester, const TaskEdit());
    await tester.enterText(find.byType(TextField).first, 'New task');
    await tester.pump();

    final future = SolidWindowCloseGuard.resolveAll();
    await tester.pumpAndSettle();

    await tester.tap(find.text('Keep editing'));
    await tester.pumpAndSettle();
    expect(await future, isFalse);
    // The editor is still open with the unsaved description intact.
    expect(find.text('New task'), findsOneWidget);
  });

  // Regression: TaskEdit used to pop the task and let the caller persist it,
  // so the Pod write was not awaited by the guard. resolveAll() returned
  // immediately, the window was destroyed mid-write, and the new task was
  // lost despite tapping Save.
  testWidgets('window-close Save waits for the Pod write to finish', (
    tester,
  ) async {
    final podWrite = Completer<void>();
    var written = false;

    await pumpEditor(
      tester,
      TaskEdit(
        onSave: (task) async {
          await podWrite.future;
          written = true;
        },
      ),
    );
    await tester.enterText(find.byType(TextField).first, 'New task');
    await tester.pump();

    var resolved = false;
    final future = SolidWindowCloseGuard.resolveAll()
      ..then((_) => resolved = true);
    await tester.pumpAndSettle();

    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();

    // The Pod write is still in flight, so the guard must NOT have resolved
    // — otherwise the caller would destroy the window and lose the task.
    expect(resolved, isFalse);
    expect(written, isFalse);

    podWrite.complete();
    await tester.pumpAndSettle();

    expect(await future, isTrue);
    expect(written, isTrue);
  });

  testWidgets('editor unregisters its resolver on dispose', (tester) async {
    await pumpEditor(tester, const TaskEdit());
    await tester.pumpWidget(wrap(const SizedBox()));
    await tester.pumpAndSettle();
    // No editor left registered, so nothing to resolve.
    expect(await SolidWindowCloseGuard.resolveAll(), isTrue);
  });
}
