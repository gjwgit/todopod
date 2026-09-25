/// Tests for TaskNotesField — tapping a rendered checkbox in Preview mode.
///
library;

// Run: flutter test test/task_notes_field_test.dart

import 'package:flutter/material.dart';

import 'package:flutter_test/flutter_test.dart';

import 'package:todopod/pages/edit_fields/task_notes_field.dart';

void main() {
  Future<void> pumpPreview(WidgetTester tester, TextEditingController notes) {
    return tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ListenableBuilder(
            listenable: notes,
            builder: (context, _) => TaskNotesField(
              notes: notes,
              showPreview: true,
              onToggle: () {},
            ),
          ),
        ),
      ),
    );
  }

  testWidgets('tapping a checkbox in preview ticks it off', (tester) async {
    final notes = TextEditingController(text: '- [ ] Milk\n- [ ] Bread');
    addTearDown(notes.dispose);

    await pumpPreview(tester, notes);

    expect(find.byIcon(Icons.check_box_outline_blank), findsNWidgets(2));

    await tester.tap(find.byIcon(Icons.check_box_outline_blank).first);
    await tester.pumpAndSettle();

    expect(notes.text, '- [x] Milk\n- [ ] Bread');
    expect(find.byIcon(Icons.check_box), findsOneWidget);
  });

  testWidgets('tapping the second checkbox toggles the second line', (
    tester,
  ) async {
    final notes = TextEditingController(text: '- [ ] Milk\n- [ ] Bread');
    addTearDown(notes.dispose);

    await pumpPreview(tester, notes);

    await tester.tap(find.byIcon(Icons.check_box_outline_blank).last);
    await tester.pumpAndSettle();

    expect(notes.text, '- [ ] Milk\n- [x] Bread');
  });

  testWidgets('tapping a ticked checkbox unticks it', (tester) async {
    final notes = TextEditingController(text: '- [x] Milk');
    addTearDown(notes.dispose);

    await pumpPreview(tester, notes);

    await tester.tap(find.byIcon(Icons.check_box));
    await tester.pumpAndSettle();

    expect(notes.text, '- [ ] Milk');
  });

  // Re-tapping a box must land on the same line: the ordinal the builder
  // hands out has to restart at zero on each re-parse.

  testWidgets('re-tapping the same checkbox returns to the original', (
    tester,
  ) async {
    final notes = TextEditingController(text: '- [ ] a\n- [ ] b\n- [ ] c');
    addTearDown(notes.dispose);

    await pumpPreview(tester, notes);

    await tester.tap(find.byIcon(Icons.check_box_outline_blank).at(1));
    await tester.pumpAndSettle();

    expect(notes.text, '- [ ] a\n- [x] b\n- [ ] c');

    await tester.tap(find.byIcon(Icons.check_box));
    await tester.pumpAndSettle();

    expect(notes.text, '- [ ] a\n- [ ] b\n- [ ] c');
  });

  testWidgets('a checkbox inside a blockquote toggles its own line', (
    tester,
  ) async {
    final notes = TextEditingController(text: '- [ ] a\n\n> - [ ] quoted');
    addTearDown(notes.dispose);

    await pumpPreview(tester, notes);

    await tester.tap(find.byIcon(Icons.check_box_outline_blank).last);
    await tester.pumpAndSettle();

    expect(notes.text, '- [ ] a\n\n> - [x] quoted');
  });
}
