import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:nyto_app/core/theme/app_theme.dart';
import 'package:nyto_app/core/widgets/nyto_glass.dart';
import 'package:nyto_app/features/settings/help_topic_screen.dart';
import 'package:nyto_app/features/settings/settings_chrome.dart';

class HelpCenterScreen extends StatelessWidget {
  const HelpCenterScreen({super.key});

  static const _topics = <({IconData icon, Color tint, String title})>[
    (
      icon: Icons.door_front_door_outlined,
      tint: Color(0xFF3D9B6E),
      title: 'Getting started',
    ),
    (
      icon: Icons.event_available_outlined,
      tint: Color(0xFF4A7CFF),
      title: 'Events & reservations',
    ),
    (
      icon: Icons.person_outline_rounded,
      tint: Color(0xFFE8843A),
      title: 'Your account & app',
    ),
    (
      icon: Icons.lock_outline_rounded,
      tint: Color(0xFFE57373),
      title: 'Safety & security',
    ),
    (
      icon: Icons.handshake_outlined,
      tint: Color(0xFFB388FF),
      title: 'Partnerships',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return SettingsPageScaffold(
      title: 'Help Center',
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 28),
        children: [
          NytoGlass.panel(
            borderRadius: 22,
            padding: const EdgeInsets.fromLTRB(20, 22, 20, 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'FAQS & HELP',
                  style: GoogleFonts.dmSans(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 1.3,
                    color: NytoColors.cream.withValues(alpha: 0.4),
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  'What can we\nassist you with?',
                  style: GoogleFonts.fraunces(
                    fontSize: 26,
                    height: 1.15,
                    color: NytoColors.cream,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Search common answers, or open a topic below.',
                  style: GoogleFonts.dmSans(
                    fontSize: 13,
                    height: 1.4,
                    color: NytoColors.cream.withValues(alpha: 0.48),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  style: GoogleFonts.dmSans(
                    color: NytoColors.cream,
                    fontSize: 14,
                  ),
                  cursorColor: NytoColors.ctaSoft,
                  decoration: InputDecoration(
                    hintText: 'Find the answers…',
                    hintStyle: GoogleFonts.dmSans(
                      color: NytoColors.cream.withValues(alpha: 0.35),
                    ),
                    prefixIcon: Icon(
                      Icons.search_rounded,
                      color: NytoColors.cream.withValues(alpha: 0.4),
                    ),
                    filled: true,
                    fillColor: Colors.black.withValues(alpha: 0.25),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(999),
                      borderSide: BorderSide(
                        color: NytoColors.cream.withValues(alpha: 0.1),
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(999),
                      borderSide: const BorderSide(
                        color: NytoColors.ctaSoft,
                        width: 1.2,
                      ),
                    ),
                    contentPadding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          for (final t in _topics) ...[
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: NytoGlass.panel(
                borderRadius: 16,
                padding: EdgeInsets.zero,
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () => openSettingsPage(
                      context,
                      HelpTopicScreen(
                        title: t.title,
                        articles: HelpTopics.articlesFor(t.title),
                      ),
                    ),
                    borderRadius: BorderRadius.circular(16),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 14,
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 40,
                            height: 40,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: t.tint.withValues(alpha: 0.22),
                            ),
                            child: Icon(t.icon, size: 20, color: t.tint),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              t.title,
                              style: GoogleFonts.dmSans(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                color: NytoColors.cream,
                              ),
                            ),
                          ),
                          Icon(
                            Icons.north_east_rounded,
                            size: 18,
                            color: NytoColors.cream.withValues(alpha: 0.35),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
          const SizedBox(height: 8),
          NytoGlass.panel(
            borderRadius: 20,
            padding: const EdgeInsets.fromLTRB(20, 22, 20, 22),
            child: Column(
              children: [
                Icon(
                  Icons.mail_outline_rounded,
                  size: 28,
                  color: NytoColors.ctaSoft,
                ),
                const SizedBox(height: 12),
                Text(
                  'Create a ticket',
                  style: GoogleFonts.fraunces(
                    fontSize: 22,
                    color: NytoColors.cream,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Couldn’t find an answer? Send us a note and we’ll get back soon.',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.dmSans(
                    fontSize: 13,
                    height: 1.4,
                    color: NytoColors.cream.withValues(alpha: 0.5),
                  ),
                ),
                const SizedBox(height: 16),
                SettingsPrimaryButton(
                  label: 'Open ticket',
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Support tickets — coming soon.'),
                        backgroundColor: NytoColors.surface,
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
