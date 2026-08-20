import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:nyto_app/core/theme/app_theme.dart';
import 'package:nyto_app/features/onboarding/onboarding_data.dart';
import 'package:nyto_app/features/onboarding/widgets/onboarding_chrome.dart';

class NotificationsStep extends StatefulWidget {
  const NotificationsStep({
    super.key,
    required this.data,
    required this.onFinish,
  });

  final OnboardingData data;
  final VoidCallback onFinish;

  @override
  State<NotificationsStep> createState() => _NotificationsStepState();
}

class _NotificationsStepState extends State<NotificationsStep>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    )..repeat();
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  void _enable() {
    widget.data.notificationsEnabled = true;
    widget.onFinish();
  }

  void _later() {
    widget.data.notificationsEnabled = false;
    widget.onFinish();
  }

  @override
  Widget build(BuildContext context) {
    return OnboardingScaffold(
      step: 12,
      totalSteps: OnboardingData.totalSteps,
      footer: Column(
        children: [
          NytoPrimaryButton(
            label: 'Turn on updates',
            onPressed: _enable,
          ),
          const SizedBox(height: 4),
          NytoGhostButton(
            label: 'Maybe later',
            onPressed: _later,
          ),
        ],
      ),
      child: Column(
        children: [
          const SizedBox(height: 24),
          AnimatedBuilder(
            animation: _pulse,
            builder: (context, _) {
              final t = _pulse.value;
              final scale = 1 + math.sin(t * math.pi * 2) * 0.04;
              return Transform.scale(
                scale: scale,
                child: Container(
                  width: 96,
                  height: 96,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        NytoColors.brandViolet.withValues(alpha: 0.9),
                        NytoColors.brandPink.withValues(alpha: 0.85),
                      ],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: NytoColors.cta.withValues(alpha: 0.22),
                        blurRadius: 18,
                        spreadRadius: 0,
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.notifications_active_rounded,
                    color: Colors.white,
                    size: 40,
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 32),
          Text(
            'Don’t miss your table',
            textAlign: TextAlign.center,
            style: GoogleFonts.fraunces(
              fontSize: 28,
              fontWeight: FontWeight.w500,
              color: NytoColors.cream,
              height: 1.15,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Seat reveals, chat opens, and night-of reminders — you can mute anytime.',
            textAlign: TextAlign.center,
            style: GoogleFonts.dmSans(
              fontSize: 15,
              height: 1.45,
              color: NytoColors.cream.withValues(alpha: 0.55),
            ),
          ),
          const SizedBox(height: 28),
          _PreviewCard(
            title: 'Your table is set',
            body: 'Friday · 8:00 PM · Hyderabad',
            tint: NytoColors.brandViolet,
          ),
          const SizedBox(height: 10),
          _PreviewCard(
            title: 'Chat unlocked',
            body: 'Say hi before you sit down',
            tint: NytoColors.brandMagenta,
          ),
        ],
      ),
    );
  }
}

class _PreviewCard extends StatelessWidget {
  const _PreviewCard({
    required this.title,
    required this.body,
    required this.tint,
  });

  final String title;
  final String body;
  final Color tint;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: NytoColors.cream.withValues(alpha: 0.05),
        border: Border.all(color: tint.withValues(alpha: 0.35)),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: tint.withValues(alpha: 0.35),
            ),
            child: Icon(Icons.restaurant_rounded, color: tint, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.dmSans(
                    fontWeight: FontWeight.w700,
                    color: NytoColors.cream,
                    fontSize: 14,
                  ),
                ),
                Text(
                  body,
                  style: GoogleFonts.dmSans(
                    color: NytoColors.cream.withValues(alpha: 0.5),
                    fontSize: 12.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
