import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:nyto_app/core/theme/app_theme.dart';
import 'package:nyto_app/features/home/home_screen.dart';

/// Returning-user entry — email + OTP (dev code: 000000).
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
  String? _error;

  static const _devOtp = '000000';

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

  Future<void> _sendOtp() async {
    if (!_emailValid) {
      setState(() => _error = 'Enter a valid email address.');
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    await Future<void>.delayed(const Duration(milliseconds: 450));
    if (!mounted) return;
    setState(() {
      _loading = false;
      _otpSent = true;
    });
    _otpFocus.requestFocus();
  }

  Future<void> _verifyOtp() async {
    final otp = _otpController.text.trim();
    if (otp != _devOtp) {
      setState(() => _error = 'Invalid code. Use $_devOtp in development.');
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    await Future<void>.delayed(const Duration(milliseconds: 400));
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute<void>(builder: (_) => const HomeScreen()),
      (_) => false,
    );
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
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
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
                const SizedBox(height: 8),
                Text(
                  'Dev OTP: $_devOtp',
                  style: GoogleFonts.dmSans(
                    fontSize: 12,
                    color: NytoColors.cream.withValues(alpha: 0.4),
                  ),
                ),
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
              const Spacer(),
              SizedBox(
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
            ],
          ),
        ),
      ),
    );
  }
}
