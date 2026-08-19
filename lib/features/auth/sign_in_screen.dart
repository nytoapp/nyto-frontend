import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:nyto_app/app/session.dart';
import 'package:nyto_app/core/api/api_client.dart';
import 'package:nyto_app/core/api/nyto_api.dart';
import 'package:nyto_app/core/auth/google_auth.dart';
import 'package:nyto_app/core/config/app_env.dart';
import 'package:nyto_app/core/theme/app_theme.dart';
import 'package:nyto_app/features/home/home_screen.dart';
import 'package:nyto_app/features/onboarding/widgets/google_g_logo.dart';

/// Returning-user entry — email + OTP.
class SignInScreen extends StatefulWidget {
  const SignInScreen({super.key});

  @override
  State<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends State<SignInScreen> {
  final _emailController = TextEditingController();
  final _otpController = TextEditingController();
  final _emailFocus = FocusNode();
  final _otpFocus = FocusNode();

  bool _otpSent = false;
  bool _loading = false;
  String? _devOtpHint;
  String? _error;

  @override
  void dispose() {
    _emailController.dispose();
    _otpController.dispose();
    _emailFocus.dispose();
    _otpFocus.dispose();
    super.dispose();
  }

  bool get _emailValid {
    final e = _emailController.text.trim();
    return RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(e);
  }

  String _reachError() =>
      'Could not reach NYTO. Is the server running? On a phone, run adb reverse tcp:3000 tcp:3000.';

  Future<void> _sendOtp() async {
    if (!_emailValid) {
      setState(() => _error = 'Enter a valid email address.');
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
      _devOtpHint = null;
    });
    final email = _emailController.text.trim();
    try {
      final json = await authApi.requestEmailOtp(email);
      if (!mounted) return;
      setState(() {
        _loading = false;
        _otpSent = true;
        final hint = json['devOtp'] as String?;
        if (AppEnv.allowDevOtp && hint != null && hint.isNotEmpty) {
          _devOtpHint = hint;
        }
      });
      _otpFocus.requestFocus();
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = e.message;
      });
    } catch (_) {
      if (!mounted) return;
      if (AppEnv.allowDevOtp) {
        setState(() {
          _loading = false;
          _otpSent = true;
          _devOtpHint = AppEnv.devOtp;
        });
        _otpFocus.requestFocus();
        return;
      }
      setState(() {
        _loading = false;
        _error = _reachError();
      });
    }
  }

  Future<void> _verifyOtp() async {
    final otp = _otpController.text.trim();
    if (otp.length != 6) {
      setState(() => _error = 'Enter the 6-digit code.');
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    final email = _emailController.text.trim();
    try {
      await authApi.verifyEmailOtp(email: email, code: otp);
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = e.message;
      });
      return;
    } catch (_) {
      if (AppEnv.allowDevOtp && otp == AppEnv.devOtp) {
        await NytoSession.markSignedIn();
      } else {
        if (!mounted) return;
        setState(() {
          _loading = false;
          _error = _reachError();
        });
        return;
      }
    }
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute<void>(builder: (_) => const HomeScreen()),
      (_) => false,
    );
  }

  Future<void> _googleSignIn() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final google = await NytoGoogleAuth.signIn();
      if (google == null) {
        if (!mounted) return;
        setState(() => _loading = false);
        return;
      }
      await authApi.googleSignIn(google.idToken);
      if (!mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute<void>(builder: (_) => const HomeScreen()),
        (_) => false,
      );
    } on GoogleAuthException catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = e.message;
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = e.message;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = _reachError();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: NytoColors.bg,
      appBar: AppBar(
        backgroundColor: NytoColors.bg,
        elevation: 0,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
          color: NytoColors.cream,
        ),
      ),
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Welcome back',
                      style: GoogleFonts.fraunces(
                        fontSize: 32,
                        fontWeight: FontWeight.w500,
                        color: NytoColors.cream,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Sign in with the email on your NYTO account.',
                      style: GoogleFonts.dmSans(
                        fontSize: 15,
                        height: 1.4,
                        color: NytoColors.cream.withValues(alpha: 0.55),
                      ),
                    ),
                    const SizedBox(height: 28),
                    SizedBox(
                      height: 54,
                      child: OutlinedButton(
                        onPressed: _loading || _otpSent ? null : _googleSignIn,
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(
                            color: NytoColors.cream.withValues(alpha: 0.18),
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const GoogleGLogo(size: 20),
                            const SizedBox(width: 10),
                            Text(
                              'Continue with Google',
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
                    const SizedBox(height: 18),
                    Row(
                      children: [
                        Expanded(
                          child: Divider(
                            color: NytoColors.cream.withValues(alpha: 0.12),
                          ),
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
                          child: Divider(
                            color: NytoColors.cream.withValues(alpha: 0.12),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),
                    Text(
                      'EMAIL',
                      style: GoogleFonts.dmSans(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.2,
                        color: NytoColors.cream.withValues(alpha: 0.45),
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _emailController,
                      focusNode: _emailFocus,
                      enabled: !_otpSent && !_loading,
                      keyboardType: TextInputType.emailAddress,
                      style: GoogleFonts.dmSans(color: NytoColors.cream),
                      cursorColor: NytoColors.ctaSoft,
                      decoration: InputDecoration(
                        hintText: 'you@gmail.com',
                        hintStyle: GoogleFonts.dmSans(
                          color: NytoColors.cream.withValues(alpha: 0.28),
                        ),
                        filled: true,
                        fillColor: NytoColors.cream.withValues(alpha: 0.05),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide.none,
                        ),
                      ),
                      onChanged: (_) => setState(() => _error = null),
                    ),
                    if (_otpSent) ...[
                      const SizedBox(height: 18),
                      Text(
                        'OTP',
                        style: GoogleFonts.dmSans(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.2,
                          color: NytoColors.cream.withValues(alpha: 0.45),
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _otpController,
                        focusNode: _otpFocus,
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                          LengthLimitingTextInputFormatter(6),
                        ],
                        style: GoogleFonts.dmSans(
                          color: NytoColors.cream,
                          letterSpacing: 4,
                          fontWeight: FontWeight.w600,
                        ),
                        cursorColor: NytoColors.ctaSoft,
                        decoration: InputDecoration(
                          hintText: '6-digit code',
                          hintStyle: GoogleFonts.dmSans(
                            color: NytoColors.cream.withValues(alpha: 0.28),
                            letterSpacing: 0,
                          ),
                          filled: true,
                          fillColor: NytoColors.cream.withValues(alpha: 0.05),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: BorderSide.none,
                          ),
                        ),
                        onChanged: (_) => setState(() => _error = null),
                      ),
                      if (AppEnv.allowDevOtp) ...[
                        const SizedBox(height: 8),
                        Text(
                          'Dev OTP: ${_devOtpHint ?? AppEnv.devOtp}',
                          style: GoogleFonts.dmSans(
                            fontSize: 12,
                            color: NytoColors.cream.withValues(alpha: 0.4),
                          ),
                        ),
                      ],
                    ],
                    if (_error != null) ...[
                      const SizedBox(height: 12),
                      Text(
                        _error!,
                        style: GoogleFonts.dmSans(
                          fontSize: 13,
                          color: const Color(0xFFE57373),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
              child: SizedBox(
                height: 54,
                child: FilledButton(
                  onPressed: _loading
                      ? null
                      : (_otpSent ? _verifyOtp : _sendOtp),
                  style: FilledButton.styleFrom(
                    backgroundColor: NytoColors.cta,
                    disabledBackgroundColor: NytoColors.ctaDisabled,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                  child: _loading
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : Text(
                          _otpSent ? 'Sign in' : 'Send code',
                          style: GoogleFonts.dmSans(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
