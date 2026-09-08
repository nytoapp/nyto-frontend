import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:nyto_app/core/profile/profile_name.dart';
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
  final FocusNode _focus = FocusNode();
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _name = TextEditingController(text: widget.data.firstName);
  }

  @override
  void dispose() {
    _focus.dispose();
    _name.dispose();
    super.dispose();
  }

  bool get _ok => _name.text.trim().length >= 2 && !_saving;

  Future<void> _go() async {
    if (!_ok) return;
    FocusScope.of(context).unfocus();
    final name = _name.text.trim();
    widget.data.firstName = name;
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      final saved = await ProfileName.save(name);
      widget.data.firstName = saved;
      if (!mounted) return;
      widget.onContinue();
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _saving = false;
        _error = 'Could not save your name. Try again.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // resizeForKeyboard lifts the footer with the inset so Continue stays
    // visible above the keyboard — no dismiss-to-tap required.
    return OnboardingScaffold(
      step: 5,
      totalSteps: OnboardingData.totalSteps,
      resizeForKeyboard: true,
      footer: NytoPrimaryButton(
        label: _saving ? 'Saving…' : 'Continue',
        enabled: _ok,
        onPressed: _ok ? _go : null,
      ),
      child: ListView(
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        padding: const EdgeInsets.only(bottom: 12),
        children: [
          const OnboardingTitle(
            'What should we call you?',
            subtitle: 'Just your first name — how it shows at the table.',
          ),
          const SizedBox(height: 28),
          TextField(
            controller: _name,
            focusNode: _focus,
            autofocus: true,
            textCapitalization: TextCapitalization.words,
            textInputAction: TextInputAction.done,
            inputFormatters: [
              LengthLimitingTextInputFormatter(32),
              FilteringTextInputFormatter.allow(RegExp(r"[A-Za-zÀ-ÖØ-öø-ÿ' -]")),
            ],
            onChanged: (_) => setState(() {}),
            onSubmitted: (_) => _go(),
            style: GoogleFonts.dmSans(
              color: NytoColors.cream,
              fontSize: 18,
              fontWeight: FontWeight.w500,
            ),
            cursorColor: NytoColors.ctaSoft,
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
                borderSide: BorderSide(
                  color: NytoColors.ctaSoft.withValues(alpha: 0.85),
                  width: 1.4,
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            _error ?? 'At least 2 letters. You can change this later.',
            style: GoogleFonts.dmSans(
              fontSize: 12.5,
              color: _error == null
                  ? NytoColors.cream.withValues(alpha: 0.38)
                  : const Color(0xFFE8A0A0),
            ),
          ),
        ],
      ),
    );
  }
}
