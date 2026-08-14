import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:nyto_app/core/theme/app_theme.dart';
import 'package:nyto_app/core/widgets/nyto_glass.dart';
import 'package:nyto_app/features/settings/city_settings_screen.dart';
import 'package:nyto_app/features/settings/help_center_screen.dart';
import 'package:nyto_app/features/settings/language_settings_screen.dart';
import 'package:nyto_app/features/settings/login_security_screen.dart';
import 'package:nyto_app/features/settings/notification_preferences_screen.dart';
import 'package:nyto_app/features/settings/rate_app_sheet.dart';
import 'package:nyto_app/features/settings/settings_chrome.dart';

/// Full Settings hub — glass sections, no subscription.
class SettingsHubScreen extends StatefulWidget {
  const SettingsHubScreen({super.key});

  @override
  State<SettingsHubScreen> createState() => _SettingsHubScreenState();
}

class _SettingsHubScreenState extends State<SettingsHubScreen> {
  String _city = 'Hyderabad, India';
  String _language = 'English';

  @override
  Widget build(BuildContext context) {
    return SettingsPageScaffold(
      title: 'Settings',
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
        children: [
          Text(
            'Your table,\nyour control.',
            style: GoogleFonts.fraunces(
              fontSize: 28,
              fontWeight: FontWeight.w400,
              height: 1.15,
              color: NytoColors.cream,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Account, preferences, and help — kept simple.',
            style: GoogleFonts.dmSans(
              fontSize: 14,
              height: 1.4,
              color: NytoColors.cream.withValues(alpha: 0.5),
            ),
          ),
          const SizedBox(height: 28),
          const SettingsSectionLabel('Account'),
          SettingsGlassGroup(
            children: [
              SettingsNavRow(
                icon: Icons.shield_outlined,
                label: 'Login & Security',
                subtitle: 'Email, password, account',
                onTap: () => openSettingsPage(
                  context,
                  const LoginSecurityScreen(),
                ),
              ),
            ],
          ),
          const SizedBox(height: 22),
          const SettingsSectionLabel('Preferences'),
          SettingsGlassGroup(
            children: [
              SettingsNavRow(
                icon: Icons.public_rounded,
                label: 'City',
                subtitle: _city,
                onTap: () async {
                  final next = await openSettingsPage<String>(
                    context,
                    CitySettingsScreen(selectedCity: _city.split(',').first),
                  );
                  if (next != null && mounted) {
                    setState(() => _city = next);
                  }
                },
              ),
              SettingsNavRow(
                icon: Icons.translate_rounded,
                label: 'App language',
                subtitle: _language,
                onTap: () async {
                  final next = await openSettingsPage<String>(
                    context,
                    LanguageSettingsScreen(selected: _language),
                  );
                  if (next != null && mounted) {
                    setState(() => _language = next);
                  }
                },
              ),
              SettingsNavRow(
                icon: Icons.notifications_none_rounded,
                label: 'Notification preferences',
                subtitle: 'Push, email, SMS',
                onTap: () => openSettingsPage(
                  context,
                  const NotificationPreferencesScreen(),
                ),
              ),
            ],
          ),
          const SizedBox(height: 22),
          const SettingsSectionLabel('Resources'),
          SettingsGlassGroup(
            children: [
              SettingsNavRow(
                icon: Icons.help_outline_rounded,
                label: 'Help Center',
                onTap: () => openSettingsPage(
                  context,
                  const HelpCenterScreen(),
                ),
              ),
              SettingsNavRow(
                icon: Icons.menu_book_outlined,
                label: 'NYTO guide',
                subtitle: 'How nights at the table work',
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('NYTO guide — content coming soon.'),
                      backgroundColor: NytoColors.surface,
                    ),
                  );
                },
              ),
              SettingsNavRow(
                icon: Icons.alternate_email_rounded,
                label: 'Follow NYTO',
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Social links — coming soon.'),
                      backgroundColor: NytoColors.surface,
                    ),
                  );
                },
              ),
              SettingsNavRow(
                icon: Icons.star_outline_rounded,
                label: 'Rate the app',
                iconColor: NytoColors.orange,
                onTap: () => showRateAppSheet(context),
              ),
            ],
          ),
          const SizedBox(height: 28),
          NytoGlass.panel(
            borderRadius: 999,
            padding: EdgeInsets.zero,
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Sign out — auth wiring later.'),
                      backgroundColor: NytoColors.surface,
                    ),
                  );
                },
                borderRadius: BorderRadius.circular(999),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  child: Center(
                    child: Text(
                      'Log out',
                      style: GoogleFonts.dmSans(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: NytoColors.cream,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 32),
          Center(
            child: Column(
              children: [
                Text(
                  'NYTO',
                  style: GoogleFonts.fraunces(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 3.2,
                    color: NytoColors.ctaSoft.withValues(alpha: 0.85),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Version 0.1.0',
                  style: GoogleFonts.dmSans(
                    fontSize: 12,
                    color: NytoColors.cream.withValues(alpha: 0.35),
                  ),
                ),
                const SizedBox(height: 16),
                Wrap(
                  alignment: WrapAlignment.center,
                  spacing: 16,
                  children: [
                    _LegalLink(label: 'Terms', onTap: () {}),
                    _LegalLink(label: 'Privacy', onTap: () {}),
                    _LegalLink(label: 'Community', onTap: () {}),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _LegalLink extends StatelessWidget {
  const _LegalLink({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Text(
        label,
        style: GoogleFonts.dmSans(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: NytoColors.cream.withValues(alpha: 0.45),
          decoration: TextDecoration.underline,
          decorationColor: NytoColors.cream.withValues(alpha: 0.25),
        ),
      ),
    );
  }
}
