import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:nyto_app/core/theme/app_theme.dart';
import 'package:nyto_app/core/widgets/nyto_glass.dart';
import 'package:nyto_app/features/settings/settings_chrome.dart';

class LoginSecurityScreen extends StatelessWidget {
  const LoginSecurityScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return SettingsPageScaffold(
      title: 'Login & Security',
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
        children: [
          Text(
            'Keep your seat\nsecure.',
            style: GoogleFonts.fraunces(
              fontSize: 26,
              height: 1.15,
              color: NytoColors.cream,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Manage how you sign in to NYTO.',
            style: GoogleFonts.dmSans(
              fontSize: 14,
              color: NytoColors.cream.withValues(alpha: 0.5),
            ),
          ),
          const SizedBox(height: 24),
          NytoGlass.panel(
            borderRadius: 18,
            padding: const EdgeInsets.fromLTRB(18, 6, 18, 6),
            child: Column(
              children: [
                _CredRow(
                  label: 'Email',
                  value: 'aanya.mehta@email.com',
                ),
                Divider(
                  height: 1,
                  color: NytoColors.cream.withValues(alpha: 0.08),
                ),
                _CredRow(
                  label: 'Password',
                  value: '••••••••',
                  actionLabel: 'Modify',
                  onAction: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Password change — coming soon.'),
                        backgroundColor: NytoColors.surface,
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 48),
          Center(
            child: TextButton(
              onPressed: () {
                showDialog<void>(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    backgroundColor: NytoColors.surfaceElevated,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    title: Text(
                      'Delete account?',
                      style: GoogleFonts.fraunces(color: NytoColors.cream),
                    ),
                    content: Text(
                      'This is UI-only for now. No account will be deleted.',
                      style: GoogleFonts.dmSans(
                        color: NytoColors.cream.withValues(alpha: 0.65),
                      ),
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(ctx),
                        child: Text(
                          'Cancel',
                          style: GoogleFonts.dmSans(color: NytoColors.ctaSoft),
                        ),
                      ),
                    ],
                  ),
                );
              },
              child: Text(
                'Delete my account',
                style: GoogleFonts.dmSans(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFFE57373),
                  decoration: TextDecoration.underline,
                  decorationColor: const Color(0x80E57373),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CredRow extends StatelessWidget {
  const _CredRow({
    required this.label,
    required this.value,
    this.actionLabel,
    this.onAction,
  });

  final String label;
  final String value;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: GoogleFonts.dmSans(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: NytoColors.cream,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: GoogleFonts.dmSans(
                    fontSize: 14,
                    color: NytoColors.cream.withValues(alpha: 0.5),
                  ),
                ),
              ],
            ),
          ),
          if (actionLabel != null)
            GestureDetector(
              onTap: onAction,
              child: Text(
                actionLabel!,
                style: GoogleFonts.dmSans(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: NytoColors.ctaSoft,
                  decoration: TextDecoration.underline,
                  decorationColor: NytoColors.ctaSoft.withValues(alpha: 0.5),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
