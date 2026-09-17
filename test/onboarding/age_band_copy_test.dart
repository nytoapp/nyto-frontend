import 'package:flutter_test/flutter_test.dart';
import 'package:nyto_app/features/onboarding/widgets/age_band_copy.dart';

void main() {
  group('AgeBandCopy.forAge', () {
    test('18–22 band', () {
      const expected = 'A little spontaneous. A lot to discover.';
      expect(AgeBandCopy.forAge(18), expected);
      expect(AgeBandCopy.forAge(22), expected);
    });

    test('23–27 band', () {
      const expected = 'Find your people. Make tonight count.';
      expect(AgeBandCopy.forAge(23), expected);
      expect(AgeBandCopy.forAge(27), expected);
    });

    test('28–34 band', () {
      const expected = 'You know what you’re looking for.';
      expect(AgeBandCopy.forAge(28), expected);
      expect(AgeBandCopy.forAge(34), expected);
    });

    test('35+ band', () {
      const expected = 'Good company. Better conversations.';
      expect(AgeBandCopy.forAge(35), expected);
      expect(AgeBandCopy.forAge(48), expected);
    });

    test('never echoes numeric age', () {
      for (final age in [18, 22, 23, 27, 28, 34, 35, 40]) {
        expect(AgeBandCopy.forAge(age).contains('$age'), isFalse);
      }
    });
  });
}
