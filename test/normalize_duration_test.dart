/// Tests for normalizeDuration — bare-integer durations default to minutes.
///
library;
// Run: flutter test test/normalize_duration_test.dart

import 'package:flutter_test/flutter_test.dart';

import 'package:todopod/utils/normalize_duration.dart';

void main() {
  group('normalizeDuration', () {
    test('appends m to a bare integer', () {
      expect(normalizeDuration('30'), '30m');
    });

    test('leaves an explicit minute suffix untouched', () {
      expect(normalizeDuration('30m'), '30m');
    });

    test('leaves an hour value untouched', () {
      expect(normalizeDuration('1h'), '1h');
    });

    test('leaves a combined hour/minute value untouched', () {
      expect(normalizeDuration('2h30m'), '2h30m');
    });

    test('leaves non-numeric text untouched', () {
      expect(normalizeDuration('15min'), '15min');
    });
  });
}
