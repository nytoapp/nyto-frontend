import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:nyto_app/app/session.dart';
import 'package:nyto_app/core/api/api_client.dart';
import 'package:nyto_app/core/api/nyto_api.dart';
import 'package:nyto_app/core/auth/google_auth.dart';
import 'package:nyto_app/core/config/app_env.dart';
import 'package:nyto_app/core/theme/app_theme.dart';
import 'package:nyto_app/core/widgets/nyto_glass.dart';
import 'package:nyto_app/features/onboarding/onboarding_data.dart';
import 'package:nyto_app/features/onboarding/widgets/google_g_logo.dart';
import 'package:nyto_app/features/onboarding/widgets/onboarding_chrome.dart';

/// Exclusive auth path — Google OR email OTP (no password).
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
  late final TextEditingController _otp;
  String? _mode; // null | email | google
  bool _otpSent = false;
  bool _sending = false;
  bool _verifying = false;
  bool _googleBusy = false;
  String? _devOtpHint;
  String? _error;

  @override
  void initState() {
    super.initState();
    _email = TextEditingController(text: widget.data.email);
    _otp = TextEditingController();
  }

  @override
  void dispose() {
    _email.dispose();
    _otp.dispose();
    super.dispose();
  }

  bool get _emailValid {
    final e = _email.text.trim();
    return RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(e);
  }

  bool get _otpValid => _otp.text.trim().length == 6;

  bool get _canContinue {
    if (_verifying) return false;
    if (_mode == 'google') return widget.data.googleAccount != null;
    if (_mode == 'email') return _otpSent && _otpValid;
    return false;
  }

  void _resetMode() {
    setState(() {
      _mode = null;
      _otpSent = false;
      _sending = false;
      _verifying = false;
      _googleBusy = false;
      _devOtpHint = null;
      _error = null;
      _otp.clear();
      widget.data.googleAccount = null;
    });
  }

  String _reachError() =>
      'Could not reach NYTO. Is the server running? On a phone, run adb reverse tcp:3000 tcp:3000.';

  Future<void> _sendOtp() async {
    if (!_emailValid) {
      setState(() => _error = 'Enter a valid email address.');
      return;
    }
    setState(() {
      _sending = true;
      _error = null;
      _devOtpHint = null;
    });
    final email = _email.text.trim();
    try {
      final json = await authApi.requestEmailOtp(email);
      if (!mounted) return;
      setState(() {
        _sending = false;
        _otpSent = true;
        widget.data.email = email;
        final hint = json['devOtp'] as String?;
        if (AppEnv.allowDevOtp && hint != null && hint.isNotEmpty) {
          _devOtpHint = hint;
        }
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _sending = false;
        _error = e.message;
      });
    } catch (_) {
      if (!mounted) return;
      if (AppEnv.allowDevOtp) {
        setState(() {
          _sending = false;
          _otpSent = true;
          widget.data.email = email;
          _devOtpHint = AppEnv.devOtp;
        });
        return;
      }
      setState(() {
        _sending = false;
        _error = _reachError();
      });
    }
  }

  Future<void> _persistAndGo() async {
    if (_mode == 'email') {
      final code = _otp.text.trim();
      final email = _email.text.trim();
      setState(() {
        _verifying = true;
        _error = null;
      });
      try {
        await authApi.verifyEmailOtp(email: email, code: code);
      } on ApiException catch (e) {
        if (!mounted) return;
        setState(() {
          _verifying = false;
          _error = e.message;
        });
        return;
      } catch (_) {
        if (AppEnv.allowDevOtp && code == AppEnv.devOtp) {
          await NytoSession.markSignedIn();
        } else {
          if (!mounted) return;
          setState(() {
            _verifying = false;
            _error = _reachError();
          });
          return;
        }
      }
      if (!mounted) return;
      widget.data.authMethod = 'email';
      widget.data.email = email;
      widget.data.googleAccount = null;
      setState(() => _verifying = false);
      widget.onContinue();
      return;
    }

    widget.data.authMethod = 'google';
    widget.data.email = widget.data.googleAccount ?? '';
    widget.onContinue();
  }

  Future<void> _pickGoogle({bool switchAccount = false}) async {
    if (_googleBusy) return;
    setState(() {
      _googleBusy = true;
      _error = null;
    });
    try {
      final google = await NytoGoogleAuth.signIn(switchAccount: switchAccount);
      if (!mounted) return;
      if (google == null) {
        setState(() => _googleBusy = false);
        return;
      }
      final json = await authApi.googleSignIn(google.idToken);
      if (!mounted) return;
      final user = json['user'];
      final email = user is Map && user['email'] is String
          ? user['email'] as String
          : google.email;
      setState(() {
        _googleBusy = false;
        _mode = 'google';
        widget.data.googleAccount = email;
        widget.data.email = email;
        widget.data.authMethod = 'google';
      });
    } on GoogleAuthException catch (e) {
      if (!mounted) return;
      setState(() {
        _googleBusy = false;
        _error = e.message;
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _googleBusy = false;
        _error = e.message;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _googleBusy = false;
        _error = _reachError();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return OnboardingScaffold(
      step: 4,
      totalSteps: OnboardingData.totalSteps,
      footer: _mode == null
          ? null
          : NytoPrimaryButton(
              label: _mode == 'email' && !_otpSent
                  ? (_sending ? 'Sending…' : 'Send code')
                  : (_verifying ? 'Verifying…' : 'Continue'),
              enabled: _mode == 'email' && !_otpSent
                  ? (_emailValid && !_sending)
                  : _canContinue,
              onPressed: _mode == 'email' && !_otpSent
                  ? (_emailValid && !_sending ? _sendOtp : null)
                  : (_canContinue ? _persistAndGo : null),
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
                googleBusy: _googleBusy,
                error: _error,
              )
            : _mode == 'google'
                ? _GoogleConfirmView(
                    key: const ValueKey('google'),
                    email: widget.data.googleAccount!,
                    onChange: _resetMode,
                    onSwitchAccount: () => _pickGoogle(switchAccount: true),
                  )
                : _EmailOtpView(
                    key: const ValueKey('email'),
                    email: _email,
                    otp: _otp,
                    otpSent: _otpSent,
                    error: _error,
                    devOtpHint: _devOtpHint,
                    onChanged: () => setState(() => _error = null),
                    onChangeMethod: _resetMode,
                    onEditEmail: () => setState(() {
                      _otpSent = false;
                      _otp.clear();
                      _error = null;
                      _devOtpHint = null;
                    }),
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
    required this.googleBusy,
    this.error,
  });

  final VoidCallback onGoogle;
  final VoidCallback onEmail;
  final bool googleBusy;
  final String? error;

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
          label: googleBusy ? 'Opening Google…' : 'Continue with Google',
          leading: googleBusy
              ? const SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: NytoColors.cream,
                  ),
                )
              : const GoogleGLogo(size: 22),
          onTap: googleBusy ? null : onGoogle,
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
          onTap: googleBusy ? null : onEmail,
        ),
        if (error != null) ...[
          const SizedBox(height: 16),
          Text(
            error!,
            style: GoogleFonts.dmSans(
              fontSize: 13,
              color: const Color(0xFFE57373),
            ),
          ),
        ],
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

class _EmailOtpView extends StatelessWidget {
  const _EmailOtpView({
    super.key,
    required this.email,
    required this.otp,
    required this.otpSent,
    required this.error,
    required this.devOtpHint,
    required this.onChanged,
    required this.onChangeMethod,
    required this.onEditEmail,
  });

  final TextEditingController email;
  final TextEditingController otp;
  final bool otpSent;
  final String? error;
  final String? devOtpHint;
  final VoidCallback onChanged;
  final VoidCallback onChangeMethod;
  final VoidCallback onEditEmail;

  @override
  Widget build(BuildContext context) {
    return ListView(
      children: [
        OnboardingTitle(
          otpSent ? 'Check your inbox' : 'Sign up with email',
          subtitle: otpSent
              ? 'Enter the 6-digit code we sent to ${email.text.trim()}.'
              : 'We’ll email you a one-time code — no password.',
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
          enabled: !otpSent,
          onChanged: (_) => onChanged(),
        ),
        if (otpSent) ...[
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton(
              onPressed: onEditEmail,
              child: Text(
                'Change email',
                style: GoogleFonts.dmSans(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: NytoColors.ctaSoft,
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          _Field(
            controller: otp,
            label: 'OTP',
            keyboardType: TextInputType.number,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(6),
            ],
            onChanged: (_) => onChanged(),
          ),
          if (AppEnv.allowDevOtp &&
              (devOtpHint?.isNotEmpty ?? false)) ...[
            const SizedBox(height: 10),
            Text(
              'Dev OTP: $devOtpHint',
              style: GoogleFonts.dmSans(
                fontSize: 12,
                color: NytoColors.cream.withValues(alpha: 0.4),
              ),
            ),
          ],
        ],
        if (error != null) ...[
          const SizedBox(height: 12),
          Text(
            error!,
            style: GoogleFonts.dmSans(
              fontSize: 13,
              color: const Color(0xFFE57373),
            ),
          ),
        ],
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
  final VoidCallback? onTap;

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
    this.keyboardType,
    this.enabled = true,
    this.inputFormatters,
    this.onChanged,
  });

  final TextEditingController controller;
  final String label;
  final TextInputType? keyboardType;
  final bool enabled;
  final List<TextInputFormatter>? inputFormatters;
  final ValueChanged<String>? onChanged;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      enabled: enabled,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
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
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(
            color: NytoColors.cream.withValues(alpha: 0.12),
          ),
        ),
        disabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(
            color: NytoColors.cream.withValues(alpha: 0.08),
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
