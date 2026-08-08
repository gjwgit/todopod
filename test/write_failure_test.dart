/// Tests for surfacing failures from Pod writes that nothing awaits.
///
/// The saves fired from a synchronous UI callback — a drag-reorder, a Restore
/// tap — complete with a non-null String error rather than throwing. These
/// tests pin down that such a result reaches [SolidWriteFailures], and that a
/// successful save reports nothing.
///
library;
// Run: flutter test test/write_failure_test.dart

import 'package:flutter_test/flutter_test.dart';
import 'package:solidui/solidui.dart';

import 'package:todopod/models/task.dart';
import 'package:todopod/services/app_provider.dart';

void main() {
  setUp(SolidWriteFailures.clear);

  group('SolidWriteFailures.watch', () {
    test('a save completing with an error String is reported', () async {
      SolidWriteFailures.watch(
        Future<String?>.value('403 Forbidden'),
        during: 'saving tasks',
      );
      await pumpEventQueue();

      expect(SolidWriteFailures.latest.value, contains('Failed saving tasks.'));
      expect(SolidWriteFailures.latest.value, contains('403 Forbidden'));
    });

    test('a save completing with null reports nothing', () async {
      SolidWriteFailures.watch(Future<String?>.value(), during: 'saving tasks');
      await pumpEventQueue();

      expect(SolidWriteFailures.latest.value, isNull);
    });

    test('a save that throws is reported too', () async {
      SolidWriteFailures.watch(
        Future<String?>.error(Exception('network down')),
        during: 'reordering tasks',
      );
      await pumpEventQueue();

      expect(
        SolidWriteFailures.latest.value,
        contains('Failed reordering tasks.'),
      );
      expect(SolidWriteFailures.latest.value, contains('network down'));
    });

    test('clear marks the pending failure as shown', () async {
      SolidWriteFailures.watch(Future<String?>.value('boom'));
      await pumpEventQueue();
      expect(SolidWriteFailures.latest.value, 'boom');

      SolidWriteFailures.clear();
      expect(SolidWriteFailures.latest.value, isNull);
    });
  });

  group('AppProvider.saveAllToPod', () {
    // It returns Future<String?> so an unawaited caller can hand the failure
    // to SolidWriteFailures; previously the errors were swallowed.

    test('watching a successful save reports nothing', () async {
      final provider = AppProvider()
        ..loadFromContent(todoContent: '', doneContent: '');

      SolidWriteFailures.watch(
        provider.saveAllToPod(),
        during: 'marking the task done',
      );
      await pumpEventQueue();

      expect(SolidWriteFailures.latest.value, isNull);
    });

    test('the completed task still moves to the done list', () async {
      final provider = AppProvider()
        ..loadFromContent(todoContent: '', doneContent: '');
      provider.addTask(
        Task(id: 'a', description: 'Write tests', creationDate: DateTime.now()),
      );

      provider.completeTask('a');
      SolidWriteFailures.watch(
        provider.saveAllToPod(),
        during: 'marking the task done',
      );
      await pumpEventQueue();

      expect(provider.tasks, isEmpty);
      expect(provider.doneTasks.single.description, 'Write tests');
      expect(SolidWriteFailures.latest.value, isNull);
    });
  });
}
