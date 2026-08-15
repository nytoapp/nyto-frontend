import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:nyto_app/core/theme/app_theme.dart';
import 'package:nyto_app/core/widgets/nyto_glass.dart';
import 'package:nyto_app/features/onboarding/onboarding_data.dart';
import 'package:nyto_app/features/onboarding/widgets/onboarding_chrome.dart';

class GenderStep extends StatefulWidget {
  const GenderStep({
    super.key,
    required this.data,
    required this.onSelected,
  });

  final OnboardingData data;
  final VoidCallback onSelected;

  @override
  State<GenderStep> createState() => _GenderStepState();
}

class _GenderStepState extends State<GenderStep> {
  bool _navigating = false;

  Future<void> _pick(String id) async {
    if (_navigating) return;
    HapticFeedback.selectionClick();
    setState(() {
      widget.data.gender = id;
      _navigating = true;
    });
    await Future<void>.delayed(const Duration(milliseconds: 380));
    if (!mounted) return;
    widget.onSelected();
    // Unlock so back-navigation can re-select / change answer.
    if (mounted) setState(() => _navigating = false);
  }

  @override
  Widget build(BuildContext context) {
    // If this route is on top again (user popped back), never stay locked.
    final isCurrent = ModalRoute.of(context)?.isCurrent ?? true;
    if (isCurrent && _navigating) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        if (ModalRoute.of(context)?.isCurrent ?? false) {
          setState(() => _navigating = false);
        }
      });
    }

    return OnboardingScaffold(
      step: 3,
      totalSteps: OnboardingData.totalSteps,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const OnboardingTitle(
            'How should we seat you?',
            subtitle: 'One tap. We move on right away.',
          ),
          const SizedBox(height: 36),
          ...OnboardingOptions.genders.map((g) {
            final selected = widget.data.gender == g.id;
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _GenderTile(
                label: g.label,
                selected: selected,
                enabled: !_navigating,
                onTap: () => _pick(g.id),
              ),
            );
          }),
        ],
      ),
    );
  }
}

class _GenderTile extends StatelessWidget {
  const _GenderTile({
    required this.label,
    required this.selected,
    required this.enabled,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: enabled ? onTap : null,
        borderRadius: BorderRadius.circular(20),
        splashColor: Colors.transparent,
        highlightColor: Colors.transparent,
        child: NytoGlass.panel(
          selected: selected,
          borderRadius: 20,
          padding: const EdgeInsets.symmetric(horizontal: 22),
          child: SizedBox(
            height: 64,
            child: Row(
              children: [
                Text(
                  label,
                  style: GoogleFonts.dmSans(
                    fontSize: 17,
                    fontWeight: FontWeight.w600,
                    color: selected
                        ? Colors.white
                        : NytoColors.cream.withValues(alpha: 0.92),
                  ),
                ),
                const Spacer(),
                AnimatedScale(
                  scale: selected ? 1 : 0.6,
                  duration: const Duration(milliseconds: 240),
                  child: Icon(
                    Icons.arrow_forward_rounded,
                    color: selected
                        ? Colors.white
                        : NytoColors.cream.withValues(alpha: 0.25),
                    size: 22,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
