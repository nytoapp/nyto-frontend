import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:nyto_app/core/theme/app_theme.dart';
import 'package:nyto_app/features/onboarding/onboarding_data.dart';
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
      // Dim the onboarding screen so calendar text doesn't clash.
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
    return OnboardingScaffold(
      step: 7,
      totalSteps: OnboardingData.totalSteps,
      footer: NytoPrimaryButton(
        label: 'Continue',
        enabled: _ok,
        onPressed: _ok ? _go : null,
      ),
      child: ListView(
        children: [
          const OnboardingTitle(
            'What’s your date of birth?',
            subtitle: 'We’ll seat you with people around your age.',
          ),
          const SizedBox(height: 36),
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: _pick,
              borderRadius: BorderRadius.circular(16),
              child: Ink(
                padding: const EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: 18,
                ),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  color: NytoColors.cream.withValues(alpha: 0.05),
                  border: Border.all(
                    color: NytoColors.cream.withValues(alpha: 0.12),
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Date of birth',
                            style: GoogleFonts.dmSans(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: NytoColors.cream.withValues(alpha: 0.4),
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            _display,
                            style: GoogleFonts.dmSans(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: _dob == null
                                  ? NytoColors.cream.withValues(alpha: 0.35)
                                  : NytoColors.cream,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Icon(
                      Icons.calendar_today_rounded,
                      size: 20,
                      color: NytoColors.ctaSoft.withValues(alpha: 0.9),
                    ),
                  ],
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
        ],
      ),
    );
  }
}
