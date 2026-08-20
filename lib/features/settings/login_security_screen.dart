import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:nyto_app/app/session.dart';
import 'package:nyto_app/core/api/api_client.dart';
import 'package:nyto_app/core/api/nyto_api.dart';
import 'package:nyto_app/core/auth/google_auth.dart';
import 'package:nyto_app/core/theme/app_theme.dart';
import 'package:nyto_app/core/widgets/nyto_glass.dart';
import 'package:nyto_app/features/auth/welcome_screen.dart';
import 'package:nyto_app/features/settings/settings_chrome.dart';

class LoginSecurityScreen extends StatefulWidget {
  const LoginSecurityScreen({super.key});

  @override
  State<LoginSecurityScreen> createState() => _LoginSecurityScreenState();
}

class _LoginSecurityScreenState extends State<LoginSecurityScreen> {
  String? _email;
  String? _phone;
  String? _provider;
  bool _loading = true;
  bool _loggingOut = false;
  bool _deleting = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  String get _methodLabel {
    switch (_provider) {
      case 'GOOGLE':
        return 'Google';
      case 'EMAIL':
        return 'Email';
      case 'PHONE':
        return 'Phone';
      default:
        return 'NYTO';
    }
  }

  String get _methodDetail {
    switch (_provider) {
      case 'GOOGLE':
        return 'You sign in with your Google account.';
      case 'EMAIL':
        return 'You sign in with a one-time code sent to your email.';
      case 'PHONE':
        return 'You sign in with a one-time code sent to your phone.';
      default:
        return 'NYTO uses Google or an email code. There is no password.';
    }
  }

  IconData get _methodIcon {
    switch (_provider) {
      case 'GOOGLE':
        return Icons.g_mobiledata_rounded;
      case 'EMAIL':
        return Icons.mail_outline_rounded;
      case 'PHONE':
        return Icons.sms_outlined;
      default:
        return Icons.lock_outline_rounded;
    }
  }

  String _formatPhone(String raw) {
    final digits = raw.replaceAll(RegExp(r'\D'), '');
    if (digits.length == 12 && digits.startsWith('91')) {
      return '+91 ${digits.substring(2, 7)} ${digits.substring(7)}';
    }
    if (digits.length == 10) {
      return '+91 ${digits.substring(0, 5)} ${digits.substring(5)}';
    }
    if (digits.length > 10 && digits.startsWith('91')) {
      final local = digits.substring(2);
      if (local.length == 10) {
        return '+91 ${local.substring(0, 5)} ${local.substring(5)}';
      }
    }
    return raw.startsWith('+') ? raw : '+$digits';
  }

  Future<void> _load() async {
    try {
      final json = await authApi.me();
      final user = json['user'];
      if (user is! Map || !mounted) return;
      setState(() {
        _email = user['email'] as String?;
        _phone = user['phone'] as String?;
        _provider = user['authProvider'] as String?;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  Future<void> _logOut() async {
    if (_loggingOut) return;
    setState(() => _loggingOut = true);
    await NytoGoogleAuth.signOut();
    await NytoSession.signOut();
    if (!mounted) return;
    Navigator.of(context, rootNavigator: true).pushAndRemoveUntil(
      MaterialPageRoute<void>(builder: (_) => const WelcomeScreen()),
      (_) => false,
    );
  }

  Future<void> _confirmDelete() async {
    if (_deleting) return;
    final confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => const _DeleteAccountDialog(),
    );
    if (confirmed != true || !mounted) return;

    setState(() => _deleting = true);
    try {
      await authApi.deleteMe();
      await NytoGoogleAuth.signOut();
      await NytoSession.signOut();
      if (!mounted) return;
      Navigator.of(context, rootNavigator: true).pushAndRemoveUntil(
        MaterialPageRoute<void>(builder: (_) => const WelcomeScreen()),
        (_) => false,
      );
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _deleting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.message),
          backgroundColor: NytoColors.surface,
        ),
      );
    } catch (_) {
      if (!mounted) return;
      setState(() => _deleting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not delete account. Is the server running?'),
          backgroundColor: NytoColors.surface,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final email = (_email != null && _email!.trim().isNotEmpty)
        ? _email!.trim()
        : null;
    final phone = (_phone != null && _phone!.trim().isNotEmpty)
        ? _formatPhone(_phone!.trim())
        : null;

    return SettingsPageScaffold(
      title: 'Login & Security',
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
        children: [
          Text(
            'How you sign in',
            style: GoogleFonts.fraunces(
              fontSize: 26,
              height: 1.15,
              color: NytoColors.cream,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'No password — just Google or an email code.',
            style: GoogleFonts.dmSans(
              fontSize: 14,
              color: NytoColors.cream.withValues(alpha: 0.5),
            ),
          ),
          const SizedBox(height: 24),
          NytoGlass.panel(
            borderRadius: 18,
            padding: const EdgeInsets.fromLTRB(18, 18, 18, 18),
            child: _loading
                ? const Padding(
                    padding: EdgeInsets.symmetric(vertical: 20),
                    child: Center(
                      child: SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: NytoColors.ctaSoft,
                        ),
                      ),
                    ),
                  )
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12),
                              color: NytoColors.cream.withValues(alpha: 0.08),
                            ),
                            child: Icon(
                              _methodIcon,
                              size: 22,
                              color: NytoColors.ctaSoft,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Signed in with $_methodLabel',
                                  style: GoogleFonts.dmSans(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w700,
                                    color: NytoColors.cream,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  _methodDetail,
                                  style: GoogleFonts.dmSans(
                                    fontSize: 12,
                                    height: 1.35,
                                    color: NytoColors.cream
                                        .withValues(alpha: 0.45),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      if (email != null) ...[
                        const SizedBox(height: 18),
                        Divider(
                          height: 1,
                          color: NytoColors.cream.withValues(alpha: 0.08),
                        ),
                        const SizedBox(height: 14),
                        _InfoLine(
                          label: 'Email',
                          value: email,
                        ),
                      ],
                      if (phone != null) ...[
                        const SizedBox(height: 14),
                        _InfoLine(
                          label: 'Phone on your profile',
                          value: phone,
                        ),
                      ],
                    ],
                  ),
          ),
          const SizedBox(height: 16),
          NytoGlass.panel(
            borderRadius: 999,
            padding: EdgeInsets.zero,
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: _loggingOut || _deleting ? null : _logOut,
                borderRadius: BorderRadius.circular(999),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  child: Center(
                    child: Text(
                      _loggingOut ? 'Signing out…' : 'Log out',
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
          const SizedBox(height: 40),
          Center(
            child: TextButton(
              onPressed: _deleting || _loggingOut ? null : _confirmDelete,
              child: Text(
                _deleting ? 'Deleting…' : 'Delete my account',
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

class _InfoLine extends StatelessWidget {
  const _InfoLine({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.dmSans(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: NytoColors.cream.withValues(alpha: 0.4),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: GoogleFonts.dmSans(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: NytoColors.cream,
          ),
        ),
      ],
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
