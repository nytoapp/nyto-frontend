import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:nyto_app/core/theme/app_theme.dart';
import 'package:nyto_app/core/widgets/nyto_glass.dart';
import 'package:nyto_app/features/settings/settings_chrome.dart';

class HelpTopicScreen extends StatelessWidget {
  const HelpTopicScreen({
    super.key,
    required this.title,
    required this.articles,
  });

  final String title;
  final List<({String heading, String body})> articles;

  @override
  Widget build(BuildContext context) {
    return SettingsPageScaffold(
      title: title,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
        children: [
          Text(
            title,
            style: GoogleFonts.fraunces(
              fontSize: 28,
              height: 1.15,
              color: NytoColors.cream,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Placeholder help for now — real articles later.',
            style: GoogleFonts.dmSans(
              fontSize: 13,
              color: NytoColors.cream.withValues(alpha: 0.45),
            ),
          ),
          const SizedBox(height: 20),
          for (final a in articles) ...[
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: NytoGlass.panel(
                borderRadius: 18,
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      a.heading,
                      style: GoogleFonts.dmSans(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: NytoColors.cream,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      a.body,
                      style: GoogleFonts.dmSans(
                        fontSize: 14,
                        height: 1.5,
                        color: NytoColors.cream.withValues(alpha: 0.62),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Temporary help copy — replace with real content later.
class HelpTopics {
  static List<({String heading, String body})> articlesFor(String title) {
    switch (title) {
      case 'Getting started':
        return const [
          (
            heading: 'How NYTO works',
            body:
                'Book a seat at a shared dinner or lunch. We match you with people in your city. Show up, meet the table, enjoy the night.',
          ),
          (
            heading: 'Your first booking',
            body:
                'Pick a night from Home, reserve your seat, and we’ll confirm the venue closer to the date. Keep notifications on so you don’t miss updates.',
          ),
        ];
      case 'Events & reservations':
        return const [
          (
            heading: 'Changing or cancelling',
            body:
                'You can manage upcoming reservations from My Bookings. Cancellation windows and refunds will follow NYTO’s booking policy (details coming soon).',
          ),
          (
            heading: 'Venue & timing',
            body:
                'Exact venue details are shared before the event. Arrive on time so the table can start together.',
          ),
        ];
      case 'Your account & app':
        return const [
          (
            heading: 'Profile basics',
            body:
                'Keep your name, city, and interests up to date so matching stays relevant. You can edit preferences from Profile.',
          ),
          (
            heading: 'Login issues',
            body:
                'If you can’t sign in, try resetting your password from Login & Security. Still stuck? Open a support ticket from Help Center.',
          ),
        ];
      case 'Safety & security':
        return const [
          (
            heading: 'At the table',
            body:
                'NYTO nights are social dinners — be respectful, listen more than you talk, and leave if you ever feel uncomfortable. Report concerns to support.',
          ),
          (
            heading: 'Your data',
            body:
                'We use your profile info to match tables. Full privacy details will live in Privacy Policy (linked from Profile).',
          ),
        ];
      case 'Partnerships':
        return const [
          (
            heading: 'Host with NYTO',
            body:
                'Restaurants and partners can collaborate on nights out. Partnership intake is coming soon — leave a ticket if you want early access.',
          ),
        ];
      default:
        return const [
          (
            heading: 'More soon',
            body: 'Real help articles will replace this placeholder text.',
          ),
        ];
    }
  }
}
