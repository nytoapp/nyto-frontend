import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:nyto_app/core/theme/app_theme.dart';
import 'package:nyto_app/features/onboarding/onboarding_data.dart';
import 'package:nyto_app/features/onboarding/widgets/onboarding_chrome.dart';

class PhoneStep extends StatefulWidget {
  const PhoneStep({
    super.key,
    required this.data,
    required this.onContinue,
  });

  final OnboardingData data;
  final VoidCallback onContinue;

  @override
  State<PhoneStep> createState() => _PhoneStepState();
}

class _PhoneStepState extends State<PhoneStep> {
  late final TextEditingController _phone;
  late CountryDial _country;

  @override
  void initState() {
    super.initState();
    _phone = TextEditingController(text: widget.data.phone);
    _country = OnboardingOptions.countries.firstWhere(
      (c) => c.dial == widget.data.countryDial,
      orElse: () => OnboardingOptions.countries.first,
    );
  }

  @override
  void dispose() {
    _phone.dispose();
    super.dispose();
  }

  bool get _ok {
    final digits = _phone.text.trim();
    return digits.length >= _country.minLen && digits.length <= _country.maxLen;
  }

  void _go() {
    widget.data.phone = _phone.text.trim();
    widget.data.countryDial = _country.dial;
    widget.data.countryCode = _country.code;
    widget.onContinue();
  }

  Future<void> _pickCountry() async {
    final picked = await showModalBottomSheet<CountryDial>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.72),
      builder: (ctx) {
        return DraggableScrollableSheet(
          initialChildSize: 0.7,
          minChildSize: 0.45,
          maxChildSize: 0.92,
          builder: (_, scroll) {
            return Container(
              decoration: const BoxDecoration(
                color: Color(0xFF14101A),
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: Column(
                children: [
                  const SizedBox(height: 12),
                  Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: NytoColors.cream.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(99),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Country code',
                        style: GoogleFonts.fraunces(
                          fontSize: 22,
                          color: NytoColors.cream,
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: ListView.builder(
                      controller: scroll,
                      itemCount: OnboardingOptions.countries.length,
                      itemBuilder: (_, i) {
                        final c = OnboardingOptions.countries[i];
                        final selected = c.dial == _country.dial;
                        return ListTile(
                          leading: Text(c.flag, style: const TextStyle(fontSize: 22)),
                          title: Text(
                            c.name,
                            style: GoogleFonts.dmSans(
                              color: NytoColors.cream,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          trailing: Text(
                            c.dial,
                            style: GoogleFonts.dmSans(
                              color: selected
                                  ? NytoColors.brandPink
                                  : NytoColors.cream.withValues(alpha: 0.55),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          onTap: () => Navigator.pop(ctx, c),
                        );
                      },
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
    if (picked != null && mounted) {
      setState(() => _country = picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    return OnboardingScaffold(
      step: 6,
      totalSteps: 8,
      footer: NytoPrimaryButton(
        label: 'Continue',
        enabled: _ok,
        onPressed: _ok ? _go : null,
      ),
      child: ListView(
        children: [
          OnboardingTitle(
            'Your mobile number',
            subtitle:
                'We’ll text a code when needed. Anywhere works — pick your country.',
          ),
          const SizedBox(height: 36),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: _pickCountry,
                  borderRadius: BorderRadius.circular(16),
                  child: Ink(
                    height: 58,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      color: NytoColors.cream.withValues(alpha: 0.05),
                      border: Border.all(
                        color: NytoColors.cream.withValues(alpha: 0.12),
                      ),
                    ),
                    child: Row(
                      children: [
                        Text(_country.flag, style: const TextStyle(fontSize: 18)),
                        const SizedBox(width: 6),
                        Text(
                          _country.dial,
                          style: GoogleFonts.dmSans(
                            color: NytoColors.cream,
                            fontWeight: FontWeight.w600,
                            fontSize: 15,
                          ),
                        ),
                        Icon(
                          Icons.keyboard_arrow_down_rounded,
                          color: NytoColors.cream.withValues(alpha: 0.5),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: TextField(
                  controller: _phone,
                  autofocus: true,
                  keyboardType: TextInputType.phone,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(_country.maxLen),
                  ],
                  onChanged: (_) => setState(() {}),
                  onSubmitted: (_) {
                    if (_ok) _go();
                  },
                  style:
                      GoogleFonts.dmSans(color: NytoColors.cream, fontSize: 18),
                  cursorColor: NytoColors.brandPink,
                  decoration: InputDecoration(
                    labelText: 'Number',
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
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: const BorderSide(
                        color: NytoColors.brandPink,
                        width: 1.4,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            '${_country.name} · ${_country.minLen}–${_country.maxLen} digits',
            style: GoogleFonts.dmSans(
              fontSize: 12.5,
              color: NytoColors.cream.withValues(alpha: 0.4),
            ),
          ),
        ],
      ),
    );
  }
}
