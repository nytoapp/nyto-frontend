import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:nyto_app/core/theme/app_theme.dart';
import 'package:nyto_app/features/onboarding/onboarding_data.dart';
import 'package:nyto_app/features/onboarding/widgets/onboarding_chrome.dart';

class ProfileBasicsStep extends StatefulWidget {
  const ProfileBasicsStep({
    super.key,
    required this.data,
    required this.onContinue,
  });

  final OnboardingData data;
  final VoidCallback onContinue;

  @override
  State<ProfileBasicsStep> createState() => _ProfileBasicsStepState();
}

class _ProfileBasicsStepState extends State<ProfileBasicsStep> {
  late final TextEditingController _name;
  late final TextEditingController _phone;

  @override
  void initState() {
    super.initState();
    _name = TextEditingController(text: widget.data.firstName);
    _phone = TextEditingController(text: widget.data.phone);
  }

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    super.dispose();
  }

  bool get _ok =>
      _name.text.trim().length >= 2 && _phone.text.trim().length >= 10;

  void _go() {
    widget.data.firstName = _name.text.trim();
    widget.data.phone = _phone.text.trim();
    widget.onContinue();
  }

  @override
  Widget build(BuildContext context) {
    return OnboardingScaffold(
      step: 5,
      totalSteps: 7,
      footer: NytoPrimaryButton(
        label: 'Continue',
        enabled: _ok,
        onPressed: _ok ? _go : null,
      ),
      child: ListView(
        children: [
          const OnboardingTitle(
            'What should we call you?',
            subtitle: 'First name + mobile. Hyderabad dinners only for now.',
          ),
          const SizedBox(height: 28),
          TextField(
            controller: _name,
            textCapitalization: TextCapitalization.words,
            onChanged: (_) => setState(() {}),
            style: GoogleFonts.dmSans(color: NytoColors.cream, fontSize: 16),
            cursorColor: NytoColors.brandPink,
            decoration: _deco('First name'),
          ),
          const SizedBox(height: 14),
          TextField(
            controller: _phone,
            keyboardType: TextInputType.phone,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(10),
            ],
            onChanged: (_) => setState(() {}),
            style: GoogleFonts.dmSans(color: NytoColors.cream, fontSize: 16),
            cursorColor: NytoColors.brandPink,
            decoration: _deco('Mobile number').copyWith(
              prefixText: '+91  ',
              prefixStyle: GoogleFonts.dmSans(
                color: NytoColors.cream.withValues(alpha: 0.55),
                fontSize: 16,
              ),
            ),
          ),
        ],
      ),
    );
  }

  InputDecoration _deco(String label) {
    return InputDecoration(
      labelText: label,
      labelStyle: GoogleFonts.dmSans(
        color: NytoColors.cream.withValues(alpha: 0.45),
      ),
      filled: true,
      fillColor: NytoColors.cream.withValues(alpha: 0.05),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(
          color: NytoColors.cream.withValues(alpha: 0.12),
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: NytoColors.brandPink, width: 1.4),
      ),
    );
  }
}
