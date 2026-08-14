import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:nyto_app/core/theme/app_theme.dart';
import 'package:nyto_app/core/widgets/nyto_glass.dart';
import 'package:nyto_app/features/settings/settings_chrome.dart';

/// Your reserved nights — UI placeholder until bookings API is wired.
class MyBookingsScreen extends StatelessWidget {
  const MyBookingsScreen({super.key});

  static const _demo = <({
    String day,
    String date,
    String meal,
    String area,
    String status,
  })>[
    (
      day: 'Friday',
      date: 'August 14',
      meal: 'Dinner · 8:00 PM',
      area: 'Jubilee Hills',
      status: 'Confirmed',
    ),
    (
      day: 'Wednesday',
      date: 'August 19',
      meal: 'Dinner · 8:00 PM',
      area: 'Gachibowli',
      status: 'Awaiting venue',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return SettingsPageScaffold(
      title: 'My Bookings',
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
        children: [
          Text(
            'Your nights\nahead.',
            style: GoogleFonts.fraunces(
              fontSize: 28,
              height: 1.15,
              color: NytoColors.cream,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Seats you’ve reserved — separate from open tables on Home.',
            style: GoogleFonts.dmSans(
              fontSize: 14,
              height: 1.4,
              color: NytoColors.cream.withValues(alpha: 0.48),
            ),
          ),
          const SizedBox(height: 22),
          for (final b in _demo) ...[
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: NytoGlass.panel(
                borderRadius: 18,
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            b.day,
                            style: GoogleFonts.fraunces(
                              fontSize: 22,
                              color: NytoColors.cream,
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(999),
                            color: NytoColors.cta.withValues(alpha: 0.2),
                            border: Border.all(
                              color: NytoColors.ctaSoft.withValues(alpha: 0.45),
                            ),
                          ),
                          child: Text(
                            b.status,
                            style: GoogleFonts.dmSans(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: NytoColors.ctaSoft,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      b.date,
                      style: GoogleFonts.dmSans(
                        fontSize: 14,
                        color: NytoColors.cream.withValues(alpha: 0.65),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      b.meal,
                      style: GoogleFonts.dmSans(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: NytoColors.cream,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${b.area} · Hyderabad',
                      style: GoogleFonts.dmSans(
                        fontSize: 13,
                        color: NytoColors.cream.withValues(alpha: 0.45),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
