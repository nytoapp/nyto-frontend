import 'package:flutter/material.dart';
import 'package:nyto_app/core/theme/app_theme.dart';

/// 4-step onboarding progress strip used on verification screens.
class NytoProgressStrip extends StatelessWidget {
  const NytoProgressStrip({
    super.key,
    required this.filledSteps,
    this.totalSteps = 4,
  });

  final int filledSteps;
  final int totalSteps;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(totalSteps, (index) {
        final filled = index < filledSteps;
        return Expanded(
          child: Container(
            margin: EdgeInsets.only(right: index == totalSteps - 1 ? 0 : 6),
            height: 3,
            decoration: BoxDecoration(
              color: filled
                  ? NytoColors.orange
                  : NytoColors.cream.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        );
      }),
    );
  }
}
