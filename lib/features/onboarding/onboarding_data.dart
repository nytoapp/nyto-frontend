/// Shared onboarding state for the short Get started → home path.
class OnboardingData {
  static const totalSteps = 10;

  final Set<String> goals = {};
  String? gender;
  String authMethod = 'email'; // email | google
  String? googleAccount;
  String email = '';
  String firstName = '';
  String phone = '';
  String countryDial = '+91';
  String countryCode = 'IN';
  final Set<String> interests = {};
  /// Custom interests added via search (id → display label). AI later.
  final Map<String, String> customInterestLabels = {};
  bool notificationsEnabled = false;
  bool digilockerLinked = false;
  bool selfieCaptured = false;
}

class CountryDial {
  const CountryDial({
    required this.code,
    required this.name,
    required this.dial,
    required this.flag,
    this.minLen = 8,
    this.maxLen = 12,
  });

  final String code;
  final String name;
  final String dial;
  final String flag;
  final int minLen;
  final int maxLen;
}

class OnboardingOptions {
  static const goals = <({String id, String label, String hint})>[
    (
      id: 'new_faces',
      label: 'Meet new faces',
      hint: 'Sit with people you wouldn’t meet otherwise',
    ),
    (
      id: 'real_talk',
      label: 'Real conversation',
      hint: 'Skip small talk. Go deeper at the table',
    ),
    (
      id: 'city_nights',
      label: 'Hyderabad nights',
      hint: 'A standing dinner ritual in your city',
    ),
    (
      id: 'zero_plan',
      label: 'Zero planning',
      hint: 'We seat the table. You just show up',
    ),
    (
      id: 'women_circle',
      label: 'Women-led tables',
      hint: 'Prefer evenings curated for women',
    ),
    (
      id: 'curiosity',
      label: 'Stay curious',
      hint: 'Different professions, same dinner',
    ),
  ];

  static const genders = <({String id, String label})>[
    (id: 'man', label: 'Man'),
    (id: 'woman', label: 'Woman'),
    (id: 'nonbinary', label: 'Non-binary'),
    (id: 'skip', label: 'Prefer not to say'),
  ];

  static const interests = <({String id, String label})>[
    (id: 'food', label: 'Food & flavour'),
    (id: 'film', label: 'Film & series'),
    (id: 'music', label: 'Live music'),
    (id: 'startups', label: 'Startups'),
    (id: 'design', label: 'Design'),
    (id: 'fitness', label: 'Movement'),
    (id: 'books', label: 'Books'),
    (id: 'travel', label: 'Travel'),
    (id: 'tech', label: 'Tech'),
    (id: 'art', label: 'Art'),
  ];

  static const socialProof = <({String name, String city, String quote})>[
    (
      name: 'Ananya',
      city: 'Hyderabad',
      quote: 'I came for dinner. Left with three people I actually text.',
    ),
    (
      name: 'Rahul',
      city: 'Banjara Hills',
      quote: 'No awkward apps. Just a table and good timing.',
    ),
    (
      name: 'Meera',
      city: 'Jubilee Hills',
      quote: 'Felt curated, not random. That mattered.',
    ),
    (
      name: 'Dev',
      city: 'Gachibowli',
      quote: 'Finally a Friday that isn’t the same group chat.',
    ),
    (
      name: 'Sara',
      city: 'Madhapur',
      quote: 'Showed up alone. Didn’t feel alone for a second.',
    ),
    (
      name: 'Arjun',
      city: 'Hyderabad',
      quote: 'The matching is quiet but spot on.',
    ),
  ];

  static const mockGoogleAccounts = <({String name, String email})>[
    (name: 'You', email: 'you@gmail.com'),
    (name: 'Work', email: 'you@company.com'),
    (name: 'Personal', email: 'hello.nyto@gmail.com'),
  ];

  static const countries = <CountryDial>[
    CountryDial(code: 'IN', name: 'India', dial: '+91', flag: '🇮🇳', minLen: 10, maxLen: 10),
    CountryDial(code: 'US', name: 'United States', dial: '+1', flag: '🇺🇸', minLen: 10, maxLen: 10),
    CountryDial(code: 'GB', name: 'United Kingdom', dial: '+44', flag: '🇬🇧', minLen: 10, maxLen: 11),
    CountryDial(code: 'AE', name: 'United Arab Emirates', dial: '+971', flag: '🇦🇪', minLen: 9, maxLen: 9),
    CountryDial(code: 'SG', name: 'Singapore', dial: '+65', flag: '🇸🇬', minLen: 8, maxLen: 8),
    CountryDial(code: 'JP', name: 'Japan', dial: '+81', flag: '🇯🇵', minLen: 10, maxLen: 11),
    CountryDial(code: 'AU', name: 'Australia', dial: '+61', flag: '🇦🇺', minLen: 9, maxLen: 9),
    CountryDial(code: 'DE', name: 'Germany', dial: '+49', flag: '🇩🇪', minLen: 10, maxLen: 12),
    CountryDial(code: 'CA', name: 'Canada', dial: '+1', flag: '🇨🇦', minLen: 10, maxLen: 10),
    CountryDial(code: 'FR', name: 'France', dial: '+33', flag: '🇫🇷', minLen: 9, maxLen: 9),
  ];
}
