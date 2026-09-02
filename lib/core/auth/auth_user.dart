/// The authenticated app user, as the backend describes it.
///
/// The backend is the source of truth for identity: nothing here is inferred
/// from a provider payload on the client.
class AuthUser {
  const AuthUser({
    required this.id,
    required this.authProvider,
    this.phone,
    this.email,
    this.firstName,
    this.fullName = '',
    this.gender,
    this.dateOfBirth,
    this.isAgeVerified = false,
    this.linkedProviders = const LinkedProviders(),
  });

  final String id;
  final String authProvider;
  final String? phone;
  final String? email;
  final String? firstName;
  final String fullName;
  final String? gender;
  final String? dateOfBirth;
  final bool isAgeVerified;
  final LinkedProviders linkedProviders;

  /// Best label for "signed in as …" copy.
  String get displayLabel {
    final name = firstName?.trim();
    if (name != null && name.isNotEmpty && name != 'Guest') return name;
    final mail = email?.trim();
    if (mail != null && mail.isNotEmpty) return mail;
    return phone ?? 'Your account';
  }

  static AuthUser? fromJson(Object? raw) {
    if (raw is! Map) return null;
    final id = raw['id'];
    if (id is! String || id.isEmpty) return null;

    return AuthUser(
      id: id,
      authProvider: raw['authProvider'] as String? ?? 'unknown',
      phone: raw['phone'] as String?,
      email: raw['email'] as String?,
      firstName: raw['firstName'] as String?,
      fullName: raw['fullName'] as String? ?? '',
      gender: raw['gender'] as String?,
      dateOfBirth: raw['dateOfBirth'] as String?,
      isAgeVerified: raw['isAgeVerified'] as bool? ?? false,
      linkedProviders: LinkedProviders.fromJson(raw['linkedProviders']),
    );
  }
}

class LinkedProviders {
  const LinkedProviders({
    this.phone = false,
    this.email = false,
    this.google = false,
    this.apple = false,
    this.facebook = false,
  });

  final bool phone;
  final bool email;
  final bool google;
  final bool apple;
  final bool facebook;

  static LinkedProviders fromJson(Object? raw) {
    if (raw is! Map) return const LinkedProviders();
    return LinkedProviders(
      phone: raw['phone'] as bool? ?? false,
      email: raw['email'] as bool? ?? false,
      google: raw['google'] as bool? ?? false,
      apple: raw['apple'] as bool? ?? false,
      facebook: raw['facebook'] as bool? ?? false,
    );
  }
}

/// Details the server returns after accepting an OTP request.
class OtpChallengeInfo {
  const OtpChallengeInfo({
    required this.destination,
    required this.maskedDestination,
    required this.expiresAt,
    required this.resendAfter,
  });

  final String destination;
  final String maskedDestination;
  final DateTime expiresAt;
  final Duration resendAfter;

  static OtpChallengeInfo fromJson(
    Map<String, dynamic> json, {
    required String fallbackDestination,
  }) {
    final expiresRaw = json['expiresAt'];
    final expires = expiresRaw is String
        ? DateTime.tryParse(expiresRaw)?.toLocal()
        : null;
    final resendSeconds = json['resendAfterSeconds'];

    return OtpChallengeInfo(
      destination:
          json['phone'] as String? ??
          json['email'] as String? ??
          fallbackDestination,
      maskedDestination:
          json['maskedPhone'] as String? ??
          json['maskedEmail'] as String? ??
          fallbackDestination,
      expiresAt: expires ?? DateTime.now().add(const Duration(minutes: 5)),
      resendAfter: Duration(seconds: resendSeconds is int ? resendSeconds : 30),
    );
  }
}
