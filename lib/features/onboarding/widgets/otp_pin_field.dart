import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:nyto_app/core/theme/app_theme.dart';

/// Six-cell OTP input with focus ring and auto-advance.
class OtpPinField extends StatefulWidget {
  const OtpPinField({
    super.key,
    required this.controller,
    this.onChanged,
    this.onCompleted,
  });

  final TextEditingController controller;
  final ValueChanged<String>? onChanged;
  final VoidCallback? onCompleted;

  @override
  State<OtpPinField> createState() => _OtpPinFieldState();
}

class _OtpPinFieldState extends State<OtpPinField> {
  final FocusNode _focus = FocusNode();

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onText);
    _focus.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onText);
    _focus.dispose();
    super.dispose();
  }

  void _onText() {
    widget.onChanged?.call(widget.controller.text);
    if (widget.controller.text.length >= 6) {
      widget.onCompleted?.call();
    }
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final text = widget.controller.text;
    final focused = _focus.hasFocus;

    return GestureDetector(
      onTap: () => _focus.requestFocus(),
      child: Stack(
        children: [
          Row(
            children: List.generate(6, (i) {
              final char = text.length > i ? text[i] : '';
              final active = focused &&
                  (text.length == i || (text.length >= 6 && i == 5));
              return Expanded(
                child: Padding(
                  padding: EdgeInsets.only(right: i < 5 ? 8 : 0),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    curve: Curves.easeOutCubic,
                    height: 56,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(14),
                      color: NytoColors.cream.withValues(alpha: 0.04),
                      border: Border.all(
                        color: active
                            ? NytoColors.ctaSoft
                            : char.isNotEmpty
                                ? NytoColors.cta.withValues(alpha: 0.45)
                                : NytoColors.cream.withValues(alpha: 0.12),
                        width: active ? 1.6 : 1,
                      ),
                      boxShadow: active
                          ? [
                              BoxShadow(
                                color: NytoColors.cta.withValues(alpha: 0.18),
                                blurRadius: 12,
                                offset: const Offset(0, 4),
                              ),
                            ]
                          : null,
                    ),
                    child: Text(
                      char,
                      style: GoogleFonts.dmSans(
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        color: NytoColors.cream,
                        height: 1,
                      ),
                    ),
                  ),
                ),
              );
            }),
          ),
          Positioned.fill(
            child: Opacity(
              opacity: 0,
              child: TextField(
                focusNode: _focus,
                controller: widget.controller,
                keyboardType: TextInputType.number,
                maxLength: 6,
                autofocus: true,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: const InputDecoration(
                  counterText: '',
                  border: InputBorder.none,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
