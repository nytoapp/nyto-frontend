import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:nyto_app/core/theme/app_theme.dart';
import 'package:nyto_app/core/widgets/nyto_glass.dart';

/// Placeholder Events tab — no listing, booking, or host/venue portal here.
/// Venue/host signup belongs on the separate venue web portal.
class EventsPlaceholderScreen extends StatelessWidget {
  const EventsPlaceholderScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 28),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'NYTO',
              style: GoogleFonts.fraunces(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: NytoColors.cta,
                letterSpacing: 3.5,
              ),
            ),
            const SizedBox(height: 28),
            Expanded(
              child: Center(
                child: NytoGlass.panel(
                  borderRadius: 24,
                  padding: const EdgeInsets.fromLTRB(28, 32, 28, 32),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.celebration_outlined,
                        size: 40,
                        color: NytoColors.ctaSoft.withValues(alpha: 0.9),
                      ),
                      const SizedBox(height: 18),
                      Text(
                        'Curated events,\ncoming soon for you.',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.fraunces(
                          fontSize: 26,
                          height: 1.2,
                          color: NytoColors.cream,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Hosted nights, pop-ups, and one-off experiences — built for NYTO.',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.dmSans(
                          fontSize: 14,
                          height: 1.45,
                          color: NytoColors.cream.withValues(alpha: 0.5),
                        ),
                      ),
                      const SizedBox(height: 28),
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton(
                          onPressed: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  'We’ll notify you when Events launch.',
                                  style: GoogleFonts.dmSans(),
                                ),
                                backgroundColor: NytoColors.surfaceElevated,
                              ),
                            );
                          },
                          style: FilledButton.styleFrom(
                            backgroundColor: NytoColors.cta,
                            foregroundColor: NytoColors.brandInk,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          child: Text(
                            'Notify me',
                            style: GoogleFonts.dmSans(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                    ],
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
