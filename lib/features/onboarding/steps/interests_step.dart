import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:nyto_app/core/theme/app_theme.dart';
import 'package:nyto_app/core/widgets/nyto_glass.dart';
import 'package:nyto_app/features/onboarding/onboarding_data.dart';
import 'package:nyto_app/features/onboarding/widgets/onboarding_chrome.dart';

class InterestsStep extends StatefulWidget {
  const InterestsStep({
    super.key,
    required this.data,
    required this.onContinue,
  });

  final OnboardingData data;
  final VoidCallback onContinue;

  @override
  State<InterestsStep> createState() => _InterestsStepState();
}

class _InterestsStepState extends State<InterestsStep> {
  void _toggle(String id) {
    setState(() {
      if (widget.data.interests.contains(id)) {
        widget.data.interests.remove(id);
      } else if (widget.data.interests.length < 3) {
        widget.data.interests.add(id);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final can = widget.data.interests.isNotEmpty;

    return OnboardingScaffold(
      step: 7,
      totalSteps: 8,
      footer: NytoPrimaryButton(
        label: 'Continue',
        enabled: can,
        onPressed: can ? widget.onContinue : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const OnboardingTitle(
            'What are you into?',
            subtitle: 'Up to three for now. Deeper matching comes when you book.',
          ),
          const SizedBox(height: 24),
          Expanded(
            child: SingleChildScrollView(
              child: Wrap(
                spacing: 10,
                runSpacing: 10,
                children: OnboardingOptions.interests.map((item) {
                  final selected = widget.data.interests.contains(item.id);
                  final locked =
                      !selected && widget.data.interests.length >= 3;
                  return _InterestChip(
                    label: item.label,
                    selected: selected,
                    locked: locked,
                    onTap: locked ? null : () => _toggle(item.id),
                  );
                }).toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _InterestChip extends StatelessWidget {
  const _InterestChip({
    required this.label,
    required this.selected,
    required this.locked,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final bool locked;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return AnimatedOpacity(
      duration: const Duration(milliseconds: 180),
      opacity: locked ? 0.35 : 1,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(999),
          splashColor: Colors.transparent,
          highlightColor: Colors.transparent,
          child: NytoGlass.panel(
            selected: selected,
            borderRadius: 999,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Text(
              label,
              style: GoogleFonts.dmSans(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: selected
                    ? Colors.white
                    : NytoColors.cream.withValues(alpha: 0.85),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
