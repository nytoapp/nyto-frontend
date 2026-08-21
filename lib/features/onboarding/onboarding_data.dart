/// Shared onboarding state for the short Get started → home path.
class OnboardingData {
  /// Goals → … → notifications (verification is at booking / Profile).
  static const totalSteps = 12;

  /// Max interests at signup; deeper topics come at booking.
  static const maxInterests = 5;

  final Set<String> goals = {};
  String? gender;
  String authMethod = 'email'; // email | google
  String? googleAccount;
  String email = '';
  String firstName = '';
  String phone = '';
  String countryDial = '+91';
  String countryCode = 'IN';
  /// ISO yyyy-MM-dd when set.
  String? dateOfBirth;
  /// introverted | ambiverted | extroverted
  String? socialEnergy;
  final Set<String> interests = {};
  /// Custom interests added via search (id → display label). AI later.
  final Map<String, String> customInterestLabels = {};
  bool notificationsEnabled = false;
  bool digilockerLinked = false;
  bool selfieCaptured = false;

  String get interestLabelHint {
    if (interests.isEmpty) return 'what you love';
    final id = interests.first;
    for (final group in OnboardingOptions.interestGroups) {
      for (final item in group.items) {
        if (item.id == id) return item.label.toLowerCase();
      }
    }
    return customInterestLabels[id]?.toLowerCase() ?? 'what you love';
  }

  Map<String, dynamic> toProfilePatch() {
    final body = <String, dynamic>{};
    final name = firstName.trim();
    if (name.isNotEmpty) body['firstName'] = name;
    if (gender != null && gender!.isNotEmpty) body['gender'] = gender;
    if (interests.isNotEmpty) body['interests'] = interests.toList();
    if (dateOfBirth != null && dateOfBirth!.isNotEmpty) {
      body['dateOfBirth'] = dateOfBirth;
    }
    if (socialEnergy != null && socialEnergy!.isNotEmpty) {
      body['socialEnergy'] = socialEnergy;
    }

    final local = phone.replaceAll(RegExp(r'\D'), '');
    final dial = countryDial.replaceAll(RegExp(r'\D'), '');
    if (local.length >= 8) {
      body['phone'] = '$dial$local';
    }
    return body;
  }
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

class InterestGroup {
  const InterestGroup({
    required this.id,
    required this.label,
    required this.items,
  });

  final String id;
  final String label;
  final List<({String id, String label})> items;
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

  static const interestGroups = <InterestGroup>[
    InterestGroup(
      id: 'table',
      label: 'At the table',
      items: [
        (id: 'food', label: 'Food & flavour'),
        (id: 'cooking', label: 'Cooking'),
        (id: 'tea_coffee', label: 'Tea & coffee'),
        (id: 'wine', label: 'Wine'),
      ],
    ),
    InterestGroup(
      id: 'move',
      label: 'Move',
      items: [
        (id: 'cricket', label: 'Cricket'),
        (id: 'football', label: 'Football'),
        (id: 'badminton', label: 'Badminton'),
        (id: 'running', label: 'Running'),
        (id: 'gym', label: 'Gym'),
        (id: 'yoga', label: 'Yoga'),
      ],
    ),
    InterestGroup(
      id: 'culture',
      label: 'Culture',
      items: [
        (id: 'film', label: 'Film & series'),
        (id: 'music', label: 'Live music'),
        (id: 'books', label: 'Books'),
        (id: 'art', label: 'Art'),
        (id: 'travel', label: 'Travel'),
        (id: 'photography', label: 'Photography'),
      ],
    ),
    InterestGroup(
      id: 'build',
      label: 'Build',
      items: [
        (id: 'startups', label: 'Startups'),
        (id: 'tech', label: 'Tech'),
        (id: 'design', label: 'Design'),
        (id: 'business', label: 'Business'),
      ],
    ),
    InterestGroup(
      id: 'vibe',
      label: 'Vibe',
      items: [
        (id: 'gaming', label: 'Gaming'),
        (id: 'pets', label: 'Pets'),
        (id: 'nature', label: 'Nature'),
        (id: 'languages', label: 'Languages'),
        (id: 'board_games', label: 'Board games'),
      ],
    ),
  ];

  /// Flat list for lookups / legacy.
  static List<({String id, String label})> get interests => [
        for (final g in interestGroups) ...g.items,
      ];

  static const socialEnergies = <({String id, String label, String hint})>[
    (
      id: 'introverted',
      label: 'Introverted',
      hint: 'I prefer smaller groups or one-on-one conversations.',
    ),
    (
      id: 'ambiverted',
      label: 'Ambiverted',
      hint: 'I enjoy both — it depends on the moment.',
    ),
    (
      id: 'extroverted',
      label: 'Extroverted',
      hint: 'I love being around people — it gives me energy.',
    ),
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
