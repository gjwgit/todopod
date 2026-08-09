/// Tests for durationMinutes — parses free-text durations for sorting.
///
library;
// Run: flutter test test/duration_minutes_test.dart

import 'package:flutter_test/flutter_test.dart';

import 'package:todopod/utils/duration_minutes.dart';

void main() {
  group('durationMinutes', () {
    test('parses a bare integer as minutes', () {
      expect(durationMinutes('45'), 45);
    });

    test('parses a minute suffix', () {
      expect(durationMinutes('30m'), 30);
    });

    test('parses an hour suffix', () {
      expect(durationMinutes('1h'), 60);
    });

    test('parses combined hours and minutes', () {
      expect(durationMinutes('2h30m'), 150);
    });

    test('parses the min suffix', () {
      expect(durationMinutes('15min'), 15);
    });

    test('returns null for null', () {
      expect(durationMinutes(null), isNull);
    });

    test('returns null for unparseable text', () {
      expect(durationMinutes('soon'), isNull);
    });
  });
}
