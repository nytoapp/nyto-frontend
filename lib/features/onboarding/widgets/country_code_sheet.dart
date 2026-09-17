import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:nyto_app/core/theme/app_theme.dart';
import 'package:nyto_app/features/onboarding/onboarding_data.dart';

Future<CountryDial?> showCountryCodeSheet(
  BuildContext context, {
  required CountryDial selected,
}) {
  return showModalBottomSheet<CountryDial>(
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
            decoration: BoxDecoration(
              color: const Color(0xFF14101A),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
              border: Border.all(color: NytoColors.cream.withValues(alpha: 0.08)),
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
                      style: GoogleFonts.dmSerifDisplay(
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
                      final isSelected = c.dial == selected.dial;
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
                            color: isSelected
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
}
