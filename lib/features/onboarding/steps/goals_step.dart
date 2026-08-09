import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:nyto_app/core/theme/app_theme.dart';
import 'package:nyto_app/core/widgets/nyto_glass.dart';
import 'package:nyto_app/features/onboarding/onboarding_data.dart';
import 'package:nyto_app/features/onboarding/widgets/onboarding_chrome.dart';

const _kTotal = 8;

class GoalsStep extends StatefulWidget {
  const GoalsStep({super.key, required this.data, required this.onContinue});

  final OnboardingData data;
  final VoidCallback onContinue;

  @override
  State<GoalsStep> createState() => _GoalsStepState();
}

class _GoalsStepState extends State<GoalsStep> {
  void _toggle(String id) {
    setState(() {
      if (widget.data.goals.contains(id)) {
        widget.data.goals.remove(id);
      } else if (widget.data.goals.length < 2) {
        widget.data.goals.add(id);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final canContinue = widget.data.goals.isNotEmpty;

    return OnboardingScaffold(
      step: 1,
      totalSteps: _kTotal,
      footer: NytoPrimaryButton(
        label: 'Continue',
        enabled: canContinue,
        onPressed: canContinue ? widget.onContinue : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const OnboardingTitle(
            'What brings you to the table?',
            subtitle: 'Pick up to two. We’ll seat you with that energy.',
          ),
          const SizedBox(height: 28),
          Expanded(
            child: ListView.separated(
              itemCount: OnboardingOptions.goals.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, i) {
                final g = OnboardingOptions.goals[i];
                final selected = widget.data.goals.contains(g.id);
                final locked =
                    !selected && widget.data.goals.length >= 2;
                return _GoalTile(
                  label: g.label,
                  hint: g.hint,
                  selected: selected,
                  locked: locked,
                  onTap: locked ? null : () => _toggle(g.id),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _GoalTile extends StatelessWidget {
  const _GoalTile({
    required this.label,
    required this.hint,
    required this.selected,
    required this.locked,
    required this.onTap,
  });

  final String label;
  final String hint;
  final bool selected;
  final bool locked;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return AnimatedOpacity(
      duration: const Duration(milliseconds: 200),
      opacity: locked ? 0.4 : 1,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(18),
          splashColor: Colors.transparent,
          highlightColor: Colors.transparent,
          child: NytoGlass.panel(
            selected: selected,
            borderRadius: 18,
            padding: const EdgeInsets.fromLTRB(18, 16, 16, 16),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        label,
                        style: GoogleFonts.dmSans(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: NytoColors.cream,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        hint,
                        style: GoogleFonts.dmSans(
                          fontSize: 13,
                          height: 1.35,
                          color: NytoColors.cream.withValues(alpha: 0.5),
                        ),
                      ),
                    ],
                  ),
                ),
                AnimatedContainer(
                  duration: const Duration(milliseconds: 220),
                  width: 22,
                  height: 22,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: selected
                        ? const LinearGradient(
                            colors: [
                              NytoColors.ctaSoft,
                              NytoColors.cta,
                            ],
                          )
                        : null,
                    border: selected
                        ? null
                        : Border.all(
                            color: NytoColors.cream.withValues(alpha: 0.28),
                          ),
                  ),
                  child: selected
                      ? const Icon(Icons.check, size: 14, color: Colors.white)
                      : null,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
