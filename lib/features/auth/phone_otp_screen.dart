import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:nyto_app/core/api/api_client.dart';
import 'package:nyto_app/core/api/nyto_api.dart';
import 'package:nyto_app/core/theme/app_theme.dart';
import 'package:nyto_app/features/verification/id_verification_screen.dart';

/// Phone OTP step after sign up (dev OTP: 000000).
class PhoneOtpScreen extends StatefulWidget {
  const PhoneOtpScreen({
    super.key,
    required this.fullName,
    required this.dateOfBirth,
  });

  final String fullName;
  final String dateOfBirth;

  @override
  State<PhoneOtpScreen> createState() => _PhoneOtpScreenState();
}

class _PhoneOtpScreenState extends State<PhoneOtpScreen> {
  final _phoneController = TextEditingController();
  final _otpController = TextEditingController();
  final _phoneFocus = FocusNode();
  final _otpFocus = FocusNode();

  bool _otpSent = false;
  bool _loading = false;
  String? _error;
  String? _devHint;

  @override
  void initState() {
    super.initState();
    _phoneFocus.addListener(() => setState(() {}));
    _otpFocus.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _phoneController.dispose();
    _otpController.dispose();
    _phoneFocus.dispose();
    _otpFocus.dispose();
    super.dispose();
  }

  Future<void> _sendOtp() async {
    final phone = _phoneController.text.trim();
    if (phone.replaceAll(RegExp(r'\D'), '').length < 10) {
      setState(() => _error = 'Enter a valid phone number');
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final res = await authApi.register(
        fullName: widget.fullName,
        dateOfBirth: widget.dateOfBirth,
        phone: phone,
      );
      setState(() {
        _otpSent = true;
        _devHint = res['devOtp'] as String?;
      });
      _otpFocus.requestFocus();
    } on ApiException catch (e) {
      setState(() => _error = e.message);
    } catch (_) {
      setState(() => _error = 'Could not reach NYTO API. Is the backend running?');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _verify() async {
    final phone = _phoneController.text.trim();
    final code = _otpController.text.trim();
    if (code.length < 4) {
      setState(() => _error = 'Enter the OTP');
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      await authApi.verifyOtp(phone: phone, code: code);
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute<void>(
          builder: (_) => const IdVerificationScreen(),
        ),
      );
    } on ApiException catch (e) {
      setState(() => _error = e.message);
    } catch (_) {
      setState(() => _error = 'Could not verify OTP');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: NytoColors.bg,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(28, 16, 28, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              IconButton(
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                onPressed: () => Navigator.of(context).pop(),
                icon: Icon(
                  Icons.arrow_back_ios_new,
                  size: 18,
                  color: NytoColors.cream.withValues(alpha: 0.8),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'NYTO',
                style: GoogleFonts.fraunces(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: NytoColors.orange,
                  letterSpacing: 4,
                ),
              ),
              const SizedBox(height: 28),
              Text(
                _otpSent ? 'Enter the code' : 'Continue with phone',
                style: GoogleFonts.fraunces(
                  fontSize: 30,
                  fontWeight: FontWeight.w300,
                  color: NytoColors.cream,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                _otpSent
                    ? 'We sent a 6-digit code. In development use 000000.'
                    : 'We’ll text you a one-time code to verify your number.',
                style: GoogleFonts.dmSans(
                  fontSize: 14,
                  color: NytoColors.creamMuted,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 36),
              _LabelField(
                label: 'PHONE',
                hint: '10-digit mobile',
                controller: _phoneController,
                focusNode: _phoneFocus,
                keyboardType: TextInputType.phone,
                enabled: !_otpSent && !_loading,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(10),
                ],
              ),
              if (_otpSent) ...[
                const SizedBox(height: 28),
                _LabelField(
                  label: 'OTP',
                  hint: '000000',
                  controller: _otpController,
                  focusNode: _otpFocus,
                  keyboardType: TextInputType.number,
                  enabled: !_loading,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(6),
                  ],
                ),
              ],
              if (_devHint != null) ...[
                const SizedBox(height: 12),
                Text(
                  'Dev OTP: $_devHint',
                  style: GoogleFonts.jetBrainsMono(
                    fontSize: 12,
                    color: NytoColors.orange,
                  ),
                ),
              ],
              if (_error != null) ...[
                const SizedBox(height: 14),
                Text(
                  _error!,
                  style: GoogleFonts.dmSans(
                    fontSize: 13,
                    color: const Color(0xFFE8A090),
                  ),
                ),
              ],
              const Spacer(),
              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  onPressed: _loading
                      ? null
                      : (_otpSent ? _verify : _sendOtp),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: NytoColors.orange,
                    disabledBackgroundColor: NytoColors.orangeDisabled,
                    foregroundColor: NytoColors.cream,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _loading
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.2,
                            color: NytoColors.cream,
                          ),
                        )
                      : Text(
                          _otpSent ? 'Verify & continue' : 'Send OTP',
                          style: GoogleFonts.dmSans(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
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

class _LabelField extends StatelessWidget {
  const _LabelField({
    required this.label,
    required this.hint,
    required this.controller,
    required this.focusNode,
    this.keyboardType,
    this.enabled = true,
    this.inputFormatters,
  });

  final String label;
  final String hint;
  final TextEditingController controller;
  final FocusNode focusNode;
  final TextInputType? keyboardType;
  final bool enabled;
  final List<TextInputFormatter>? inputFormatters;

  @override
  Widget build(BuildContext context) {
    final focused = focusNode.hasFocus;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.dmSans(
            fontSize: 11,
            fontWeight: FontWeight.w500,
            letterSpacing: 1.4,
            color: NytoColors.creamMuted,
          ),
        ),
        TextField(
          controller: controller,
          focusNode: focusNode,
          enabled: enabled,
          keyboardType: keyboardType,
          inputFormatters: inputFormatters,
          cursorColor: NytoColors.orange,
          style: GoogleFonts.dmSans(
            fontSize: 17,
            color: NytoColors.cream,
          ),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: GoogleFonts.dmSans(
              color: NytoColors.creamMuted.withValues(alpha: 0.55),
            ),
            border: InputBorder.none,
            contentPadding: const EdgeInsets.only(top: 10, bottom: 12),
          ),
        ),
        AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          height: 1.2,
          color: focused
              ? NytoColors.orange
              : NytoColors.cream.withValues(alpha: 0.22),
        ),
      ],
    );
  }
}
