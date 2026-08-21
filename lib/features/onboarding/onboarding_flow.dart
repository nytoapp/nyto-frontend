import 'package:flutter/material.dart';
import 'package:nyto_app/app/session.dart';
import 'package:nyto_app/core/api/nyto_api.dart';
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
import 'package:nyto_app/features/onboarding/steps/phone_step.dart';
import 'package:nyto_app/features/onboarding/steps/social_proof_step.dart';
import 'package:nyto_app/features/onboarding/steps/we_know_you_step.dart';
import 'package:nyto_app/features/onboarding/widgets/onboarding_chrome.dart';

/// Get started path → matching questions → Home.
/// DigiLocker + selfie happen at booking / Profile (not here).
class OnboardingFlow extends StatefulWidget {
  const OnboardingFlow({super.key});

  @override
  State<OnboardingFlow> createState() => _OnboardingFlowState();
}

class _OnboardingFlowState extends State<OnboardingFlow> {
  final OnboardingData _data = OnboardingData();

  void _open(Widget page) {
    Navigator.of(context).push(onboardingRoute(page));
  }

  Future<void> _syncProfile() async {
    final body = _data.toProfilePatch();
    if (body.isEmpty) return;
    try {
      await authApi.updateMe(body);
    } catch (_) {}
  }

  Future<void> _finish() async {
    await _syncProfile();
    await NytoSession.markSignedIn();
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      onboardingRoute(const HomeScreen()),
      (route) => false,
    );
  }

  void _toSocialProof() => _open(
        SocialProofStep(onContinue: _toGender),
      );

  void _toGender() => _open(
        GenderStep(data: _data, onSelected: _toAuth),
      );

  void _toAuth() => _open(
        AuthStep(data: _data, onContinue: _toFirstName),
      );

  void _toFirstName() => _open(
        FirstNameStep(data: _data, onContinue: _toPhone),
      );

  void _toPhone() => _open(
        PhoneStep(data: _data, onContinue: _toAge),
      );

  void _toAge() => _open(
        AgeStep(data: _data, onContinue: _toEnergy),
      );

  void _toEnergy() => _open(
        EnergyStep(data: _data, onContinue: _toInterests),
      );

  void _toInterests() => _open(
        InterestsStep(data: _data, onContinue: _toCurating),
      );

  void _toCurating() => _open(
        CuratingStep(data: _data, onContinue: _toWeKnowYou),
      );

  void _toWeKnowYou() {
    _syncProfile();
    _open(WeKnowYouStep(data: _data, onContinue: _toNotifications));
  }

  void _toNotifications() => _open(
        NotificationsStep(data: _data, onFinish: _finish),
      );

  @override
  Widget build(BuildContext context) {
    return GoalsStep(
      data: _data,
      onContinue: _toSocialProof,
    );
  }
}
