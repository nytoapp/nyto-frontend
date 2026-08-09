import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:nyto_app/core/theme/app_theme.dart';
import 'package:nyto_app/core/widgets/nyto_glass.dart';
import 'package:nyto_app/features/onboarding/onboarding_data.dart';
import 'package:nyto_app/features/onboarding/widgets/google_g_logo.dart';
import 'package:nyto_app/features/onboarding/widgets/onboarding_chrome.dart';

/// Exclusive auth path — pick Google OR email, never both at once.
class AuthStep extends StatefulWidget {
  const AuthStep({
    super.key,
    required this.data,
    required this.onContinue,
  });

  final OnboardingData data;
  final VoidCallback onContinue;

  @override
  State<AuthStep> createState() => _AuthStepState();
}

class _AuthStepState extends State<AuthStep> {
  late final TextEditingController _email;
  late final TextEditingController _password;
  late final TextEditingController _confirm;
  bool _obscure = true;
  bool _obscureConfirm = true;
  String? _mode; // null | email | google

  static const _total = 8;

  @override
  void initState() {
    super.initState();
    _email = TextEditingController(text: widget.data.email);
    _password = TextEditingController(text: widget.data.password);
    _confirm = TextEditingController();
  }

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    _confirm.dispose();
    super.dispose();
  }

  bool get _emailValid {
    final e = _email.text.trim();
    return e.contains('@') && e.contains('.');
  }

  bool _passwordStrong(String p) {
    final hasUpper = p.contains(RegExp(r'[A-Z]'));
    final hasDigit = p.contains(RegExp(r'[0-9]'));
    final hasSpecial = p.contains(RegExp(r'[!@#\$%^&*(),.?":{}|<>_\-]'));
    return p.length >= 8 && hasUpper && hasDigit && hasSpecial;
  }

  bool get _canContinue {
    if (_mode == 'google') return widget.data.googleAccount != null;
    if (_mode == 'email') {
      return _emailValid &&
          _passwordStrong(_password.text) &&
          _confirm.text == _password.text &&
          _confirm.text.isNotEmpty;
    }
    return false;
  }

  void _resetMode() {
    setState(() {
      _mode = null;
      widget.data.googleAccount = null;
    });
  }

  void _persistAndGo() {
    if (_mode == 'email') {
      widget.data.authMethod = 'email';
      widget.data.email = _email.text.trim();
      widget.data.password = _password.text;
      widget.data.googleAccount = null;
    } else {
      widget.data.authMethod = 'google';
      widget.data.email = widget.data.googleAccount ?? '';
    }
    widget.onContinue();
  }

  Future<void> _pickGoogle() async {
    final picked = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.72),
      builder: (ctx) {
        return Container(
          decoration: const BoxDecoration(
            color: Color(0xFF14101A),
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: NytoColors.cream.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(99),
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  Text(
                    'Choose a Google account',
                    style: GoogleFonts.fraunces(
                      fontSize: 22,
                      color: NytoColors.cream,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Preview picker — real Google Sign-In comes later.',
                    style: GoogleFonts.dmSans(
                      fontSize: 13,
                      color: NytoColors.cream.withValues(alpha: 0.5),
                    ),
                  ),
                  const SizedBox(height: 16),
                  ...OnboardingOptions.mockGoogleAccounts.map((a) {
                    return ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: CircleAvatar(
                        backgroundColor:
                            NytoColors.brandViolet.withValues(alpha: 0.35),
                        child: Text(
                          a.name[0],
                          style: const TextStyle(color: Colors.white),
                        ),
                      ),
                      title: Text(
                        a.name,
                        style: GoogleFonts.dmSans(
                          color: NytoColors.cream,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      subtitle: Text(
                        a.email,
                        style: GoogleFonts.dmSans(
                          color: NytoColors.cream.withValues(alpha: 0.5),
                          fontSize: 13,
                        ),
                      ),
                      onTap: () => Navigator.pop(ctx, a.email),
                    );
                  }),
                ],
              ),
            ),
          ),
        );
      },
    );
    if (!mounted) return;
    if (picked != null) {
      setState(() {
        _mode = 'google';
        widget.data.googleAccount = picked;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return OnboardingScaffold(
      step: 4,
      totalSteps: _total,
      footer: _mode == null
          ? null
          : NytoPrimaryButton(
              label: 'Continue',
              enabled: _canContinue,
              onPressed: _canContinue ? _persistAndGo : null,
            ),
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 320),
        switchInCurve: Curves.easeOutCubic,
        switchOutCurve: Curves.easeInCubic,
        child: _mode == null
            ? _ChoiceView(
                key: const ValueKey('choice'),
                onGoogle: _pickGoogle,
                onEmail: () => setState(() => _mode = 'email'),
              )
            : _mode == 'google'
                ? _GoogleConfirmView(
                    key: const ValueKey('google'),
                    email: widget.data.googleAccount!,
                    onChange: _resetMode,
                    onSwitchAccount: _pickGoogle,
                  )
                : _EmailFormView(
                    key: const ValueKey('email'),
                    email: _email,
                    password: _password,
                    confirm: _confirm,
                    obscure: _obscure,
                    obscureConfirm: _obscureConfirm,
                    onToggleObscure: () => setState(() => _obscure = !_obscure),
                    onToggleConfirm: () =>
                        setState(() => _obscureConfirm = !_obscureConfirm),
                    onChanged: () => setState(() {}),
                    onChangeMethod: _resetMode,
                    passwordOk: _passwordStrong,
                  ),
      ),
    );
  }
}

class _ChoiceView extends StatelessWidget {
  const _ChoiceView({
    super.key,
    required this.onGoogle,
    required this.onEmail,
  });

  final VoidCallback onGoogle;
  final VoidCallback onEmail;

  @override
  Widget build(BuildContext context) {
    return ListView(
      children: [
        const OnboardingTitle(
          'Create your seat',
          subtitle: 'Pick one way in. You can always change it later.',
        ),
        const SizedBox(height: 36),
        _BigAuthButton(
          label: 'Continue with Google',
          leading: const GoogleGLogo(size: 22),
          onTap: onGoogle,
        ),
        const SizedBox(height: 14),
        Row(
          children: [
            Expanded(
              child: Divider(color: NytoColors.cream.withValues(alpha: 0.12)),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Text(
                'or',
                style: GoogleFonts.dmSans(
                  color: NytoColors.cream.withValues(alpha: 0.4),
                ),
              ),
            ),
            Expanded(
              child: Divider(color: NytoColors.cream.withValues(alpha: 0.12)),
            ),
          ],
        ),
        const SizedBox(height: 14),
        _BigAuthButton(
          label: 'Continue with email',
          leading: Icon(
            Icons.mail_outline_rounded,
            color: NytoColors.cream,
            size: 22,
          ),
          onTap: onEmail,
        ),
      ],
    );
  }
}

class _GoogleConfirmView extends StatelessWidget {
  const _GoogleConfirmView({
    super.key,
    required this.email,
    required this.onChange,
    required this.onSwitchAccount,
  });

  final String email;
  final VoidCallback onChange;
  final VoidCallback onSwitchAccount;

  @override
  Widget build(BuildContext context) {
    return ListView(
      children: [
        const OnboardingTitle(
          'You’re almost in',
          subtitle: 'We’ll use this Google account for your NYTO seat.',
        ),
        const SizedBox(height: 32),
        NytoGlass.panel(
          borderRadius: 20,
          padding: const EdgeInsets.all(18),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                alignment: Alignment.center,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [NytoColors.ctaSoft, NytoColors.cta],
                  ),
                ),
                child: Text(
                  email[0].toUpperCase(),
                  style: GoogleFonts.dmSans(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 18,
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Google',
                      style: GoogleFonts.dmSans(
                        fontSize: 12,
                        color: NytoColors.cream.withValues(alpha: 0.5),
                      ),
                    ),
                    Text(
                      email,
                      style: GoogleFonts.dmSans(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: NytoColors.cream,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),
        TextButton(
          onPressed: onSwitchAccount,
          child: Text(
            'Switch Google account',
            style: GoogleFonts.dmSans(
              color: NytoColors.brandPink,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        TextButton(
          onPressed: onChange,
          child: Text(
            'Use email instead',
            style: GoogleFonts.dmSans(
              color: NytoColors.cream.withValues(alpha: 0.55),
            ),
          ),
        ),
      ],
    );
  }
}

class _EmailFormView extends StatelessWidget {
  const _EmailFormView({
    super.key,
    required this.email,
    required this.password,
    required this.confirm,
    required this.obscure,
    required this.obscureConfirm,
    required this.onToggleObscure,
    required this.onToggleConfirm,
    required this.onChanged,
    required this.onChangeMethod,
    required this.passwordOk,
  });

  final TextEditingController email;
  final TextEditingController password;
  final TextEditingController confirm;
  final bool obscure;
  final bool obscureConfirm;
  final VoidCallback onToggleObscure;
  final VoidCallback onToggleConfirm;
  final VoidCallback onChanged;
  final VoidCallback onChangeMethod;
  final bool Function(String) passwordOk;

  @override
  Widget build(BuildContext context) {
    final match = confirm.text.isNotEmpty && confirm.text == password.text;
    return ListView(
      children: [
        const OnboardingTitle(
          'Sign up with email',
          subtitle: 'Create a password you’ll remember.',
        ),
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton(
            onPressed: onChangeMethod,
            style: TextButton.styleFrom(
              padding: EdgeInsets.zero,
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: Text(
              '← Other sign-up options',
              style: GoogleFonts.dmSans(
                fontSize: 13,
                color: NytoColors.brandPink.withValues(alpha: 0.9),
              ),
            ),
          ),
        ),
        const SizedBox(height: 18),
        _Field(
          controller: email,
          label: 'Email',
          keyboardType: TextInputType.emailAddress,
          onChanged: (_) => onChanged(),
        ),
        const SizedBox(height: 14),
        _Field(
          controller: password,
          label: 'Password',
          obscure: obscure,
          suffix: IconButton(
            onPressed: onToggleObscure,
            icon: Icon(
              obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined,
              color: NytoColors.cream.withValues(alpha: 0.45),
              size: 20,
            ),
          ),
          onChanged: (_) => onChanged(),
        ),
        const SizedBox(height: 14),
        _Field(
          controller: confirm,
          label: 'Confirm password',
          obscure: obscureConfirm,
          suffix: IconButton(
            onPressed: onToggleConfirm,
            icon: Icon(
              obscureConfirm
                  ? Icons.visibility_outlined
                  : Icons.visibility_off_outlined,
              color: NytoColors.cream.withValues(alpha: 0.45),
              size: 20,
            ),
          ),
          onChanged: (_) => onChanged(),
        ),
        const SizedBox(height: 16),
        _Rule(ok: password.text.length >= 8, label: 'At least 8 characters'),
        _Rule(
          ok: password.text.contains(RegExp(r'[A-Z]')),
          label: 'One uppercase letter',
        ),
        _Rule(
          ok: password.text.contains(RegExp(r'[0-9]')),
          label: 'One number',
        ),
        _Rule(
          ok: password.text.contains(RegExp(r'[!@#\$%^&*(),.?":{}|<>_\-]')),
          label: 'One special character',
        ),
        _Rule(ok: match, label: 'Passwords match'),
      ],
    );
  }
}

class _BigAuthButton extends StatelessWidget {
  const _BigAuthButton({
    required this.label,
    required this.leading,
    required this.onTap,
  });

  final String label;
  final Widget leading;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: NytoGlass.panel(
          borderRadius: 18,
          child: SizedBox(
            height: 58,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                leading,
                const SizedBox(width: 10),
                Text(
                  label,
                  style: GoogleFonts.dmSans(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: NytoColors.cream,
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

class _Field extends StatelessWidget {
  const _Field({
    required this.controller,
    required this.label,
    this.obscure = false,
    this.keyboardType,
    this.suffix,
    this.onChanged,
  });

  final TextEditingController controller;
  final String label;
  final bool obscure;
  final TextInputType? keyboardType;
  final Widget? suffix;
  final ValueChanged<String>? onChanged;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      obscureText: obscure,
      keyboardType: keyboardType,
      onChanged: onChanged,
      style: GoogleFonts.dmSans(color: NytoColors.cream, fontSize: 15),
      cursorColor: NytoColors.brandPink,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: GoogleFonts.dmSans(
          color: NytoColors.cream.withValues(alpha: 0.45),
        ),
        filled: true,
        fillColor: NytoColors.cream.withValues(alpha: 0.05),
        suffixIcon: suffix,
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(
            color: NytoColors.cream.withValues(alpha: 0.12),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: NytoColors.brandPink, width: 1.4),
        ),
      ),
    );
  }
}

class _Rule extends StatelessWidget {
  const _Rule({required this.ok, required this.label});

  final bool ok;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Icon(
            ok ? Icons.check_circle_rounded : Icons.circle_outlined,
            size: 16,
            color: ok
                ? NytoColors.brandPink
                : NytoColors.cream.withValues(alpha: 0.3),
          ),
          const SizedBox(width: 8),
          Text(
            label,
            style: GoogleFonts.dmSans(
              fontSize: 13,
              color: ok
                  ? NytoColors.cream.withValues(alpha: 0.8)
                  : NytoColors.cream.withValues(alpha: 0.4),
            ),
          ),
        ],
      ),
    );
  }
}
