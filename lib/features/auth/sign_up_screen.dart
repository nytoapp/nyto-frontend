import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:nyto_app/core/theme/app_theme.dart';
import 'package:nyto_app/features/auth/phone_otp_screen.dart';

/// Sign up — visual match to `designs/Screenshot (3699).png`.
class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final _nameController = TextEditingController();
  final _dobController = TextEditingController();
  final _nameFocus = FocusNode();
  final _dobFocus = FocusNode();

  bool _phonePressed = false;

  @override
  void initState() {
    super.initState();
    _nameController.addListener(_onChanged);
    _dobController.addListener(_onChanged);
    _nameFocus.addListener(_onChanged);
    _dobFocus.addListener(_onChanged);
  }

  void _onChanged() => setState(() {});

  bool get _isValid {
    final name = _nameController.text.trim();
    final dob = _dobController.text.trim();
    if (name.length < 2) return false;
    if (!_isValidDob(dob)) return false;
    return true;
  }

  bool _isValidDob(String value) {
    final match = RegExp(r'^(\d{2})-(\d{2})-(\d{4})$').firstMatch(value);
    if (match == null) return false;
    final day = int.tryParse(match.group(1)!);
    final month = int.tryParse(match.group(2)!);
    final year = int.tryParse(match.group(3)!);
    if (day == null || month == null || year == null) return false;
    if (month < 1 || month > 12) return false;
    if (day < 1 || day > 31) return false;
    if (year < 1900 || year > DateTime.now().year) return false;
    try {
      final date = DateTime(year, month, day);
      if (date.day != day || date.month != month || date.year != year) {
        return false;
      }
      final now = DateTime.now();
      var age = now.year - year;
      if (now.month < month || (now.month == month && now.day < day)) {
        age -= 1;
      }
      return age >= 18;
    } catch (_) {
      return false;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _dobController.dispose();
    _nameFocus.dispose();
    _dobFocus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: NytoColors.bg,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(28, 20, 28, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'NYTO',
                style: GoogleFonts.fraunces(
                  fontSize: 22,
                  fontWeight: FontWeight.w600,
                  color: NytoColors.orange,
                  letterSpacing: 4.5,
                ),
              ),
              const SizedBox(height: 40),
              Text.rich(
                TextSpan(
                  children: [
                    TextSpan(
                      text: 'Create your\n',
                      style: GoogleFonts.dmSans(
                        fontSize: 34,
                        fontWeight: FontWeight.w400,
                        color: NytoColors.cream,
                        height: 1.15,
                      ),
                    ),
                    TextSpan(
                      text: 'account',
                      style: GoogleFonts.fraunces(
                        fontSize: 36,
                        fontWeight: FontWeight.w400,
                        fontStyle: FontStyle.italic,
                        color: const Color(0xFFE8DCC8),
                        height: 1.15,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              Text(
                'Matched strangers. A paid seat.\nNothing left to figure out.',
                style: GoogleFonts.dmSans(
                  fontSize: 14,
                  fontWeight: FontWeight.w400,
                  color: NytoColors.creamMuted,
                  height: 1.55,
                ),
              ),
              const SizedBox(height: 40),
              _UnderlineField(
                label: 'FULL NAME',
                hint: 'As on your ID',
                controller: _nameController,
                focusNode: _nameFocus,
                keyboardType: TextInputType.name,
                textCapitalization: TextCapitalization.words,
              ),
              const SizedBox(height: 28),
              _UnderlineField(
                label: 'DATE OF BIRTH',
                hint: 'dd-mm-yyyy',
                controller: _dobController,
                focusNode: _dobFocus,
                keyboardType: TextInputType.number,
                inputFormatters: [_DobInputFormatter()],
              ),
              const Spacer(),
              _PressScaleButton(
                pressed: _phonePressed,
                onPressedChange: (v) => setState(() => _phonePressed = v),
                enabled: _isValid,
                onTap: _isValid
                    ? () {
                        Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (_) => PhoneOtpScreen(
                              fullName: _nameController.text.trim(),
                              dateOfBirth: _dobController.text.trim(),
                            ),
                          ),
                        );
                      }
                    : null,
                child: Container(
                  width: double.infinity,
                  height: 54,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: _isValid
                        ? NytoColors.orange
                        : NytoColors.orangeDisabled,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    'Continue with phone',
                    style: GoogleFonts.dmSans(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: NytoColors.cream.withValues(
                        alpha: _isValid ? 1 : 0.55,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                height: 54,
                child: OutlinedButton(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Google sign-in — wiring later.'),
                        backgroundColor: NytoColors.surface,
                      ),
                    );
                  },
                  style: OutlinedButton.styleFrom(
                    foregroundColor: NytoColors.cream,
                    side: BorderSide(
                      color: NytoColors.cream.withValues(alpha: 0.18),
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    'Continue with Google',
                    style: GoogleFonts.dmSans(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: NytoColors.cream.withValues(alpha: 0.9),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.lock_outline,
                    size: 14,
                    color: NytoColors.creamMuted.withValues(alpha: 0.85),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'You must be 18 or older',
                    style: GoogleFonts.dmSans(
                      fontSize: 12,
                      fontWeight: FontWeight.w400,
                      color: NytoColors.creamMuted,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _UnderlineField extends StatelessWidget {
  const _UnderlineField({
    required this.label,
    required this.hint,
    required this.controller,
    required this.focusNode,
    this.keyboardType,
    this.textCapitalization = TextCapitalization.none,
    this.inputFormatters,
  });

  final String label;
  final String hint;
  final TextEditingController controller;
  final FocusNode focusNode;
  final TextInputType? keyboardType;
  final TextCapitalization textCapitalization;
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
          keyboardType: keyboardType,
          textCapitalization: textCapitalization,
          inputFormatters: inputFormatters,
          cursorColor: NytoColors.orange,
          style: GoogleFonts.dmSans(
            fontSize: 17,
            fontWeight: FontWeight.w400,
            color: NytoColors.cream,
          ),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: GoogleFonts.dmSans(
              fontSize: 17,
              fontWeight: FontWeight.w400,
              color: NytoColors.creamMuted.withValues(alpha: 0.55),
            ),
            isDense: true,
            contentPadding: const EdgeInsets.only(top: 10, bottom: 12),
            border: InputBorder.none,
            enabledBorder: InputBorder.none,
            focusedBorder: InputBorder.none,
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

class _PressScaleButton extends StatelessWidget {
  const _PressScaleButton({
    required this.child,
    required this.pressed,
    required this.onPressedChange,
    required this.enabled,
    required this.onTap,
  });

  final Widget child;
  final bool pressed;
  final ValueChanged<bool> onPressedChange;
  final bool enabled;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: enabled ? (_) => onPressedChange(true) : null,
      onTapUp: enabled
          ? (_) {
              onPressedChange(false);
              onTap?.call();
            }
          : null,
      onTapCancel: enabled ? () => onPressedChange(false) : null,
      child: AnimatedScale(
        scale: pressed ? 0.98 : 1,
        duration: const Duration(milliseconds: 90),
        curve: Curves.easeOut,
        child: child,
      ),
    );
  }
}

/// Formats DOB as `dd-mm-yyyy` while typing.
class _DobInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final digits = newValue.text.replaceAll(RegExp(r'\D'), '');
    final clipped = digits.length > 8 ? digits.substring(0, 8) : digits;

    final buffer = StringBuffer();
    for (var i = 0; i < clipped.length; i++) {
      if (i == 2 || i == 4) buffer.write('-');
      buffer.write(clipped[i]);
    }

    final formatted = buffer.toString();
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}
