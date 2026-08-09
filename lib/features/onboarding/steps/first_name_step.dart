import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:nyto_app/core/theme/app_theme.dart';
import 'package:nyto_app/features/onboarding/onboarding_data.dart';
import 'package:nyto_app/features/onboarding/widgets/onboarding_chrome.dart';

class FirstNameStep extends StatefulWidget {
  const FirstNameStep({
    super.key,
    required this.data,
    required this.onContinue,
  });

  final OnboardingData data;
  final VoidCallback onContinue;

  @override
  State<FirstNameStep> createState() => _FirstNameStepState();
}

class _FirstNameStepState extends State<FirstNameStep> {
  late final TextEditingController _name;

  @override
  void initState() {
    super.initState();
    _name = TextEditingController(text: widget.data.firstName);
  }

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  bool get _ok => _name.text.trim().length >= 2;

  void _go() {
    widget.data.firstName = _name.text.trim();
    widget.onContinue();
  }

  @override
  Widget build(BuildContext context) {
    return OnboardingScaffold(
      step: 5,
      totalSteps: 8,
      footer: NytoPrimaryButton(
        label: 'Continue',
        enabled: _ok,
        onPressed: _ok ? _go : null,
      ),
      child: ListView(
        children: [
          const OnboardingTitle(
            'What should we call you?',
            subtitle: 'Just your first name — how it shows at the table.',
          ),
          const SizedBox(height: 36),
          TextField(
            controller: _name,
            autofocus: true,
            textCapitalization: TextCapitalization.words,
            onChanged: (_) => setState(() {}),
            onSubmitted: (_) {
              if (_ok) _go();
            },
            style: GoogleFonts.dmSans(color: NytoColors.cream, fontSize: 18),
            cursorColor: NytoColors.brandPink,
            decoration: InputDecoration(
              labelText: 'First name',
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
                borderSide:
                    const BorderSide(color: NytoColors.brandPink, width: 1.4),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
