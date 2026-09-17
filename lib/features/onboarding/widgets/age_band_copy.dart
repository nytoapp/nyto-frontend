/// Deterministic age-band caption for the DOB age reveal.
///
/// The hero numeral already shows the age — captions never echo the number.
abstract final class AgeBandCopy {
  static String forAge(int age) {
    if (age <= 22) return 'A little spontaneous. A lot to discover.';
    if (age <= 27) return 'Find your people. Make tonight count.';
    if (age <= 34) return 'You know what you’re looking for.';
    return 'Good company. Better conversations.';
  }
}
