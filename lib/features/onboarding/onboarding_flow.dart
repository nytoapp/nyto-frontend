import 'package:flutter/material.dart';
import 'package:nyto_app/core/api/nyto_api.dart';
import 'package:nyto_app/core/auth/auth_user.dart';
import 'package:nyto_app/core/profile/profile_name.dart';
import 'package:nyto_app/features/home/home_screen.dart';
import 'package:nyto_app/features/onboarding/onboarding_data.dart';
import 'package:nyto_app/features/onboarding/steps/age_step.dart';
import 'package:nyto_app/features/onboarding/steps/auth_step.dart';
import 'package:nyto_app/features/onboarding/steps/curating_step.dart';
import 'package:nyto_app/features/onboarding/steps/energy_step.dart';
import 'package:nyto_app/features/onboarding/steps/first_name_step.dart';
import 'package:nyto_app/features/onboarding/steps/gender_step.dart';
import 'package:nyto_app/features/onboarding/steps/goals_step.dart';
import 'package:nyto_app/features/onboarding/steps/interests_step.dart';
import 'package:nyto_app/features/onboarding/steps/notifications_step.dart';
import 'package:nyto_app/features/onboarding/steps/night_preferences_step.dart';
import 'package:nyto_app/features/onboarding/steps/we_know_you_step.dart';
import 'package:nyto_app/features/onboarding/widgets/onboarding_chrome.dart';

/// Signed-in but profile onboarding still incomplete.
bool onboardingNeedsCompletion(AuthUser user) {
  final name = user.firstName?.trim() ?? '';
  if (name.isEmpty || name == 'Guest') return true;
  final dob = user.dateOfBirth?.trim() ?? '';
  if (dob.isEmpty) return true;
  return false;
}

OnboardingData onboardingDataFromUser(AuthUser user) {
  final data = OnboardingData();
  final name = user.firstName?.trim() ?? '';
  if (name.isNotEmpty && name != 'Guest') data.firstName = name;
  final gender = user.gender?.trim();
  if (gender != null && gender.isNotEmpty) data.gender = gender;
  final dob = user.dateOfBirth?.trim();
  if (dob != null && dob.isNotEmpty) data.dateOfBirth = dob;
  final phone = user.phone?.trim();
  if (phone != null && phone.isNotEmpty) data.phone = phone;
  final email = user.email?.trim();
  if (email != null && email.isNotEmpty) data.email = email;
  return data;
}

/// PHASE 1 — Authentication boundary (pre-auth only).
///
/// Goals → night prefs → Auth (phone / OTP / social).
///
/// On OTP/social success the entire stack (Welcome included) is wiped via
/// [Navigator.pushAndRemoveUntil] and replaced by [PostAuthOnboardingFlow].
/// Phone / OTP / Welcome can never reappear through Back.
class OnboardingFlow extends StatefulWidget {
  const OnboardingFlow({super.key});

  @override
  State<OnboardingFlow> createState() => _OnboardingFlowState();
}

class _OnboardingFlowState extends State<OnboardingFlow> {
  final OnboardingData _data = OnboardingData();
  bool _openingAuth = false;

  void _open(Widget page) {
    Navigator.of(context).push(onboardingRoute(page));
  }

  void _toNightPreferences() => _open(
        NightPreferencesStep(data: _data, onContinue: _toAuth),
      );

  void _toAuth() {
    if (_openingAuth) return;
    _openingAuth = true;
    Navigator.of(context)
        .push(
          onboardingRoute(
            AuthStep(data: _data, onContinue: _enterPostAuth),
          ),
        )
        .whenComplete(() {
      if (mounted) _openingAuth = false;
    });
  }

  /// Hard auth boundary — no auth routes remain in history.
  void _enterPostAuth() {
    Navigator.of(context).pushAndRemoveUntil(
      onboardingRoute(PostAuthOnboardingFlow(data: _data)),
      (_) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return GoalsStep(
      data: _data,
      onContinue: _toNightPreferences,
    );
  }
}

/// PHASE 2 — Profile onboarding (post-auth only).
///
/// Gender → first name → age → energy → interests → … → Home.
///
/// [GenderStep] is the stack root. Android / in-app Back never crosses into
/// authentication. Name may pop back to Gender; Gender cannot pop further.
class PostAuthOnboardingFlow extends StatefulWidget {
  const PostAuthOnboardingFlow({super.key, required this.data});

  final OnboardingData data;

  @override
  State<PostAuthOnboardingFlow> createState() => _PostAuthOnboardingFlowState();
}

class _PostAuthOnboardingFlowState extends State<PostAuthOnboardingFlow> {
  OnboardingData get _data => widget.data;
  bool _openingName = false;

  @override
  void initState() {
    super.initState();
    // Resume: if gender already chosen, open Name on top so Back → Gender.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final g = _data.gender?.trim() ?? '';
      if (g.isEmpty) return;
      final name = _data.firstName.trim();
      if (name.isEmpty || name == 'Guest' || (_data.dateOfBirth ?? '').isEmpty) {
        _openFirstName();
      }
    });
  }

  void _open(Widget page) {
    Navigator.of(context).push(onboardingRoute(page));
  }

  Future<void> _saveFirstName() async {
    final name = _data.firstName.trim();
    if (name.length < 2) return;
    try {
      _data.firstName = await ProfileName.save(name);
    } catch (_) {}
  }

  Future<void> _syncProfile() async {
    await _saveFirstName();
    final body = _data.toProfilePatch();
    body.remove('firstName');
    if (body.isEmpty) return;
    try {
      await authApi.updateMe(body);
    } catch (_) {}
  }

  Future<void> _finish() async {
    await _syncProfile();
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      onboardingRoute(const HomeScreen()),
      (_) => false,
    );
  }

  void _openFirstName() {
    if (_openingName) return;
    if (!(ModalRoute.of(context)?.isCurrent ?? true)) return;
    _openingName = true;
    Navigator.of(context)
        .push(
          onboardingRoute(
            FirstNameStep(
              data: _data,
              allowBack: true,
              onContinue: () {
                _saveFirstName();
                _toAge();
              },
            ),
          ),
        )
        .whenComplete(() {
      if (mounted) _openingName = false;
    });
  }

  void _toAge() => _open(
        AgeStep(data: _data, onContinue: _toEnergy),
      );

  void _toEnergy() => _open(
        EnergyStep(data: _data, onContinue: _toInterests),
      );

  void _toInterests() => _open(
        InterestsStep(data: _data, onContinue: _toCurating),
      );

  /// Curating is a one-shot interstitial — replace it so Back from the next
  /// screen never lands on a finished auto-advance dead end.
  void _toCurating() => _open(
        CuratingStep(
          data: _data,
          onContinue: () {
            _syncProfile();
            Navigator.of(context).pushReplacement(
              onboardingRoute(
                WeKnowYouStep(
                  data: _data,
                  onContinue: _toNotifications,
                ),
              ),
            );
          },
        ),
      );

  void _toNotifications() => _open(
        NotificationsStep(data: _data, onFinish: _finish),
      );

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: GenderStep(
        data: _data,
        allowBack: false,
        onSelected: _openFirstName,
      ),
    );
  }
}
