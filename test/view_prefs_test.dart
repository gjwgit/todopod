/// Tests for ViewPrefs — device-local view preferences.
///
library;
// Run: flutter test test/view_prefs_test.dart

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:todopod/services/view_prefs.dart';

void main() {
  // Platform channels are needed for SharedPreferences, even when mocked.

  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() => SharedPreferences.setMockInitialValues({}));

  group('ViewPrefs', () {
    test('returns the given default when the key is absent', () async {
      expect(await ViewPrefs.getBool('no_such_key', orElse: true), isTrue);
      expect(
        await ViewPrefs.getBool('other_missing_key', orElse: false),
        isFalse,
      );
    });

    test('round-trips a saved value', () async {
      await ViewPrefs.setBool(ViewPrefs.overdueOldestFirst, false);

      expect(
        await ViewPrefs.getBool(ViewPrefs.overdueOldestFirst, orElse: true),
        isFalse,
      );
    });

    test('a saved value overrides the default', () async {
      await ViewPrefs.setBool(ViewPrefs.overdueOldestFirst, true);

      expect(
        await ViewPrefs.getBool(ViewPrefs.overdueOldestFirst, orElse: false),
        isTrue,
      );
    });
  });
}
