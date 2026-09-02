import 'package:nyto_app/features/onboarding/onboarding_data.dart';

/// Result of validating what the user typed into the phone field.
enum PhoneInputStatus {
  /// Nothing entered yet — show no error.
  empty,

  /// On the way to a valid number. Submit stays disabled, no error shown.
  incomplete,

  /// Right length but not a real number for this country.
  invalid,
  valid,
}

class PhoneInput {
  const PhoneInput._({
    required this.status,
    required this.nationalNumber,
    required this.country,
    this.error,
  });

  final PhoneInputStatus status;

  /// Digits only, trunk prefix and country code already removed.
  final String nationalNumber;

  final CountryDial country;

  /// Only set when [status] is [PhoneInputStatus.invalid].
  final String? error;

  bool get isValid => status == PhoneInputStatus.valid;

  /// `+919876543210`. Only meaningful when [isValid].
  String get e164 => '${country.dial}$nationalNumber';
}

/// Per-country phone rules.
///
/// Length comes from [CountryDial]; anything stricter (like India's 6–9 first
/// digit) lives here. The button is driven by [PhoneInput.isValid], and the
/// server re-validates with libphonenumber regardless.
class PhoneNumbers {
  PhoneNumbers._();

  /// Countries whose national format carries a leading `0` trunk prefix that
  /// must be dropped before building an E.164 number.
  static const _trunkPrefixCountries = {
    'IN',
    'GB',
    'DE',
    'FR',
    'IT',
    'AU',
    'JP',
    'NL',
    'ES',
    'ZA',
  };

  /// Mobile prefixes that are actually assigned, where the rule is simple and
  /// stable enough to check on-device.
  static final _mobileFirstDigit = <String, RegExp>{
    'IN': RegExp(r'^[6-9]'),
    'IT': RegExp(r'^3'),
  };

  /// Strips everything that is not a digit, then removes a pasted country code
  /// or trunk prefix so pasting `+91 98765 43210` or `098765 43210` both work.
  static String sanitize(String raw, CountryDial country) {
    var digits = raw.replaceAll(RegExp(r'\D'), '');
    final dial = country.dial.replaceAll(RegExp(r'\D'), '');

    // A pasted international number: drop the leading country code, but only
    // when what remains could still be a full national number.
    if (dial.isNotEmpty && digits.length > country.maxLen) {
      if (digits.startsWith('00$dial')) {
        digits = digits.substring(2 + dial.length);
      } else if (digits.startsWith(dial)) {
        final withoutDial = digits.substring(dial.length);
        if (withoutDial.length >= country.minLen) digits = withoutDial;
      }
    }

    if (_trunkPrefixCountries.contains(country.code) &&
        digits.length > country.minLen &&
        digits.startsWith('0')) {
      digits = digits.substring(1);
    }

    if (digits.length > country.maxLen) {
      digits = digits.substring(0, country.maxLen);
    }
    return digits;
  }

  static PhoneInput validate(String raw, CountryDial country) {
    final digits = sanitize(raw, country);

    if (digits.isEmpty) {
      return PhoneInput._(
        status: PhoneInputStatus.empty,
        nationalNumber: digits,
        country: country,
      );
    }

    if (digits.length < country.minLen) {
      return PhoneInput._(
        status: PhoneInputStatus.incomplete,
        nationalNumber: digits,
        country: country,
      );
    }

    final mobileRule = _mobileFirstDigit[country.code];
    if (mobileRule != null && !mobileRule.hasMatch(digits)) {
      return PhoneInput._(
        status: PhoneInputStatus.invalid,
        nationalNumber: digits,
        country: country,
        error: 'That does not look like a ${country.name} mobile number.',
      );
    }

    if (RegExp(r'^(\d)\1+$').hasMatch(digits)) {
      return PhoneInput._(
        status: PhoneInputStatus.invalid,
        nationalNumber: digits,
        country: country,
        error: 'Enter a real mobile number.',
      );
    }

    return PhoneInput._(
      status: PhoneInputStatus.valid,
      nationalNumber: digits,
      country: country,
    );
  }

  /// Picks the country whose dial code matches a full E.164 number, so an
  /// OS-suggested number lands on the right country automatically.
  static CountryDial? countryForE164(String e164) {
    if (!e164.startsWith('+')) return null;
    final matches =
        OnboardingOptions.countries
            .where((country) => e164.startsWith(country.dial))
            .toList()
          ..sort((a, b) => b.dial.length.compareTo(a.dial.length));
    return matches.isEmpty ? null : matches.first;
  }

  /// Splits an OS-suggested E.164 number into a country and local digits.
  static ({CountryDial country, String national})? splitE164(String e164) {
    final country = countryForE164(e164);
    if (country == null) return null;
    final national = sanitize(e164.substring(country.dial.length), country);
    return (country: country, national: national);
  }

  static String hint(CountryDial country) {
    return country.minLen == country.maxLen
        ? '${country.name} · ${country.minLen} digits'
        : '${country.name} · ${country.minLen}–${country.maxLen} digits';
  }
}
