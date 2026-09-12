import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:nyto_app/core/theme/app_theme.dart';
import 'package:nyto_app/features/onboarding/onboarding_data.dart';
import 'package:nyto_app/features/onboarding/widgets/age_reveal.dart';
import 'package:nyto_app/features/onboarding/widgets/onboarding_chrome.dart';

class AgeStep extends StatefulWidget {
  const AgeStep({
    super.key,
    required this.data,
    required this.onContinue,
  });

  final OnboardingData data;
  final VoidCallback onContinue;

  @override
  State<AgeStep> createState() => _AgeStepState();
}

class _AgeStepState extends State<AgeStep> {
  DateTime? _dob;
  String? _error;

  @override
  void initState() {
    super.initState();
    final raw = widget.data.dateOfBirth;
    if (raw != null && raw.isNotEmpty) {
      final parsed = DateTime.tryParse(raw);
      if (parsed != null) _dob = parsed;
    }
  }

  int? get _age {
    final dob = _dob;
    if (dob == null) return null;
    final now = DateTime.now();
    var age = now.year - dob.year;
    if (now.month < dob.month ||
        (now.month == dob.month && now.day < dob.day)) {
      age--;
    }
    return age;
  }

  bool get _ok {
    final age = _age;
    return age != null && age >= 18 && age <= 100;
  }

  String get _display {
    final dob = _dob;
    if (dob == null) return 'Tap to choose';
    final d = dob.day.toString().padLeft(2, '0');
    final m = dob.month.toString().padLeft(2, '0');
    return '$d-$m-${dob.year}';
  }

  Future<void> _pick() async {
    final now = DateTime.now();
    final initial = _dob ?? DateTime(now.year - 24, 1, 1);
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(now.year - 80),
      lastDate: DateTime(now.year - 18, now.month, now.day),
      helpText: 'Date of birth',
      barrierColor: const Color(0xE605070A),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.dark(
              primary: NytoColors.cta,
              onPrimary: Colors.white,
              surface: NytoColors.surfaceElevated,
              onSurface: NytoColors.cream,
            ),
            dialogTheme: const DialogThemeData(
              backgroundColor: NytoColors.surfaceElevated,
              elevation: 12,
              shadowColor: Colors.black54,
            ),
            datePickerTheme: DatePickerThemeData(
              backgroundColor: NytoColors.surfaceElevated,
              headerBackgroundColor: NytoColors.ground,
              surfaceTintColor: Colors.transparent,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked == null || !mounted) return;
    setState(() {
      _dob = picked;
      _error = null;
    });
  }

  void _go() {
    final age = _age;
    if (!_ok || _dob == null) {
      setState(() {
        _error = age != null && age < 18
            ? 'You must be 18 or older to join NYTO.'
            : 'Pick your date of birth.';
      });
      return;
    }
    final d = _dob!;
    widget.data.dateOfBirth =
        '${d.year.toString().padLeft(4, '0')}-'
        '${d.month.toString().padLeft(2, '0')}-'
        '${d.day.toString().padLeft(2, '0')}';
    widget.onContinue();
  }

  @override
  Widget build(BuildContext context) {
    final age = _age;
    final showReveal = _ok && age != null;
    final selected = _dob != null;

    return OnboardingScaffold(
      step: 6,
      totalSteps: OnboardingData.totalSteps,
      footer: NytoPrimaryButton(
        label: 'Continue',
        enabled: _ok,
        onPressed: _ok ? _go : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const OnboardingTitle(
            'What’s your date of birth?',
            subtitle: 'We’ll seat you with people around your age.',
          ),
          const SizedBox(height: 22),
          // DOB field — quiet; selected state leads into the reveal below.
          AnimatedContainer(
            duration: const Duration(milliseconds: 280),
            curve: const Cubic(0.16, 1, 0.3, 1),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  NytoColors.cream.withValues(alpha: selected ? 0.065 : 0.04),
                  NytoColors.cta.withValues(alpha: selected ? 0.05 : 0.015),
                ],
              ),
              border: Border.all(
                color: selected
                    ? NytoColors.cta.withValues(alpha: 0.22)
                    : NytoColors.cream.withValues(alpha: 0.11),
              ),
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: _pick,
                borderRadius: BorderRadius.circular(18),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(18, 15, 14, 15),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Date of birth',
                              style: GoogleFonts.dmSans(
                                fontSize: 11.5,
                                fontWeight: FontWeight.w600,
                                letterSpacing: 0.35,
                                color: selected
                                    ? NytoColors.ctaSoft.withValues(alpha: 0.8)
                                    : NytoColors.cream.withValues(alpha: 0.38),
                              ),
                            ),
                            const SizedBox(height: 6),
                            AnimatedDefaultTextStyle(
                              duration: const Duration(milliseconds: 220),
                              style: GoogleFonts.dmSans(
                                fontSize: 17.5,
                                fontWeight: FontWeight.w600,
                                letterSpacing: selected ? 0.35 : 0,
                                height: 1.2,
                                color: selected
                                    ? NytoColors.cream
                                    : NytoColors.cream.withValues(alpha: 0.35),
                              ),
                              child: Text(_display),
                            ),
                          ],
                        ),
                      ),
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 240),
                        width: 38,
                        height: 38,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(11),
                          color: NytoColors.cta.withValues(
                            alpha: selected ? 0.12 : 0.07,
                          ),
                          border: Border.all(
                            color: NytoColors.cta.withValues(
                              alpha: selected ? 0.24 : 0.12,
                            ),
                          ),
                        ),
                        child: Icon(
                          Icons.calendar_today_rounded,
                          size: 16,
                          color: NytoColors.ctaSoft.withValues(
                            alpha: selected ? 1 : 0.8,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          if (_error != null) ...[
            const SizedBox(height: 12),
            Text(
              _error!,
              style: GoogleFonts.dmSans(
                fontSize: 13,
                color: const Color(0xFFE57373),
              ),
            ),
          ],
          // Fill the middle: age reveal is composed into the remaining space.
          Expanded(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 420),
              switchInCurve: const Cubic(0.22, 1, 0.36, 1),
              switchOutCurve: Curves.easeIn,
              transitionBuilder: (child, animation) {
                return FadeTransition(opacity: animation, child: child);
              },
              child: showReveal
                  ? KeyedSubtree(
                      key: ValueKey<int>(age),
                      child: AgeReveal(age: age),
                    )
                  : const SizedBox.expand(key: ValueKey('empty')),
            ),
          ),
        ],
      ),
    );
  }
}
