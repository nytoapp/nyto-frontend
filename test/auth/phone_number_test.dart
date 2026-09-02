import 'package:flutter_test/flutter_test.dart';
import 'package:nyto_app/core/auth/phone_number.dart';
import 'package:nyto_app/features/onboarding/onboarding_data.dart';

CountryDial _country(String code) =>
    OnboardingOptions.countries.firstWhere((c) => c.code == code);

void main() {
  final india = _country('IN');
  final usa = _country('US');
  final italy = _country('IT');

  group('sanitize', () {
    test('keeps digits only', () {
      expect(PhoneNumbers.sanitize('98a7-65 43(21)0', india), '9876543210');
    });

    test('trims whitespace and ignores padding', () {
      expect(PhoneNumbers.sanitize('  9876543210  ', india), '9876543210');
    });

    test('caps at the country maximum', () {
      expect(PhoneNumbers.sanitize('98765432101234', india), '9876543210');
      expect(PhoneNumbers.sanitize('9876543210', india).length, 10);
    });

    test('strips a pasted +91 country code', () {
      expect(PhoneNumbers.sanitize('+91 98765 43210', india), '9876543210');
      expect(PhoneNumbers.sanitize('009198765 43210', india), '9876543210');
    });

    test('strips the national trunk prefix', () {
      expect(PhoneNumbers.sanitize('09876543210', india), '9876543210');
    });

    test('keeps a leading zero that is part of a short number', () {
      // Nothing to strip yet — the user may still be typing.
      expect(PhoneNumbers.sanitize('098765', india), '098765');
    });
  });

  group('validate — India', () {
    test('9 digits is incomplete, not an error', () {
      final result = PhoneNumbers.validate('987654321', india);
      expect(result.status, PhoneInputStatus.incomplete);
      expect(result.isValid, isFalse);
      expect(result.error, isNull);
    });

    test('10 digits is valid', () {
      final result = PhoneNumbers.validate('9876543210', india);
      expect(result.isValid, isTrue);
      expect(result.e164, '+919876543210');
    });

    test('11 digits cannot be represented', () {
      final result = PhoneNumbers.validate('98765432109', india);
      expect(result.nationalNumber.length, 10);
      expect(result.isValid, isTrue);
    });

    test('empty is empty', () {
      expect(PhoneNumbers.validate('', india).status, PhoneInputStatus.empty);
    });

    test('rejects a mobile prefix India does not assign', () {
      final result = PhoneNumbers.validate('1234567890', india);
      expect(result.status, PhoneInputStatus.invalid);
      expect(result.error, isNotNull);
    });

    test('rejects a repeated-digit number', () {
      final result = PhoneNumbers.validate('9999999999', india);
      expect(result.status, PhoneInputStatus.invalid);
    });

    test('letters alone never validate', () {
      expect(
        PhoneNumbers.validate('abcdefghij', india).status,
        PhoneInputStatus.empty,
      );
    });
  });

  group('validate — other countries', () {
    test('US uses 10 digits', () {
      expect(
        PhoneNumbers.validate('415555012', usa).status,
        PhoneInputStatus.incomplete,
      );
      expect(PhoneNumbers.validate('4155550123', usa).e164, '+14155550123');
    });

    test('Italy accepts 9 or 10 digits and requires a 3 prefix', () {
      expect(PhoneNumbers.validate('3331234567', italy).e164, '+393331234567');
      expect(PhoneNumbers.validate('333123456', italy).isValid, isTrue);
      expect(
        PhoneNumbers.validate('213123456', italy).status,
        PhoneInputStatus.invalid,
      );
    });
  });

  group('splitE164', () {
    test('routes an OS-suggested number to its country', () {
      final split = PhoneNumbers.splitE164('+919876543210');
      expect(split, isNotNull);
      expect(split!.country.code, 'IN');
      expect(split.national, '9876543210');
    });

    test('prefers the longest matching dial code', () {
      // +1 and +91 both start with a digit that could collide.
      expect(PhoneNumbers.countryForE164('+14155550123')?.dial, '+1');
      expect(PhoneNumbers.countryForE164('+919876543210')?.dial, '+91');
    });

    test('returns null for an unknown country', () {
      expect(PhoneNumbers.splitE164('+9998887776'), isNull);
      expect(PhoneNumbers.splitE164('9876543210'), isNull);
    });
  });
}
