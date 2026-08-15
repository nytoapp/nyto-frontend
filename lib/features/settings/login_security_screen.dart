import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:nyto_app/core/theme/app_theme.dart';
import 'package:nyto_app/core/widgets/nyto_glass.dart';
import 'package:nyto_app/features/settings/settings_chrome.dart';

class LoginSecurityScreen extends StatelessWidget {
  const LoginSecurityScreen({super.key});

  Future<void> _confirmDelete(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => const _DeleteAccountDialog(),
    );
    if (confirmed != true || !context.mounted) return;

    // UI-only — no backend delete yet.
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Account delete confirmed in UI — backend coming later.'),
        backgroundColor: NytoColors.surface,
      ),
    );
  }

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
                const _CredRow(
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
              onPressed: () => _confirmDelete(context),
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

class _DeleteAccountDialog extends StatefulWidget {
  const _DeleteAccountDialog();

  @override
  State<_DeleteAccountDialog> createState() => _DeleteAccountDialogState();
}

class _DeleteAccountDialogState extends State<_DeleteAccountDialog> {
  static const _required = 'DELETE';
  final _controller = TextEditingController();

  bool get _matches =>
      _controller.text.trim().toUpperCase() == _required;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: NytoColors.surfaceElevated,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      title: Text(
        'Delete account?',
        style: GoogleFonts.fraunces(
          fontSize: 22,
          color: NytoColors.cream,
        ),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'This permanently removes your NYTO account. Type DELETE to confirm.',
            style: GoogleFonts.dmSans(
              fontSize: 14,
              height: 1.4,
              color: NytoColors.cream.withValues(alpha: 0.65),
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _controller,
            autofocus: true,
            textCapitalization: TextCapitalization.characters,
            style: GoogleFonts.dmSans(
              color: NytoColors.cream,
              fontWeight: FontWeight.w600,
              letterSpacing: 1.2,
            ),
            cursorColor: NytoColors.ctaSoft,
            decoration: InputDecoration(
              hintText: 'DELETE',
              hintStyle: GoogleFonts.dmSans(
                color: NytoColors.cream.withValues(alpha: 0.28),
                letterSpacing: 1.2,
              ),
              filled: true,
              fillColor: Colors.black.withValues(alpha: 0.28),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 12,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: NytoColors.cream.withValues(alpha: 0.12),
                ),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: NytoColors.cream.withValues(alpha: 0.12),
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: _matches
                      ? const Color(0xFFE57373)
                      : NytoColors.ctaSoft.withValues(alpha: 0.7),
                ),
              ),
            ),
            onChanged: (_) => setState(() {}),
            onSubmitted: (_) {
              if (_matches) Navigator.pop(context, true);
            },
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: Text(
            'Cancel',
            style: GoogleFonts.dmSans(color: NytoColors.ctaSoft),
          ),
        ),
        TextButton(
          onPressed: _matches ? () => Navigator.pop(context, true) : null,
          child: Text(
            'Delete',
            style: GoogleFonts.dmSans(
              fontWeight: FontWeight.w700,
              color: _matches
                  ? const Color(0xFFE57373)
                  : NytoColors.cream.withValues(alpha: 0.28),
            ),
          ),
        ),
      ],
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
