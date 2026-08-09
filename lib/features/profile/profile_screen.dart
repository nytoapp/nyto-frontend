import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:nyto_app/core/theme/app_theme.dart';
import 'package:nyto_app/core/widgets/nyto_glass.dart';

/// Profile — ice blue glass surfaces over dark ambient.
class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        bottom: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 120),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
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
                  const Spacer(),
                  Text(
                    'Profile',
                    style: GoogleFonts.dmSans(
                      fontSize: 14,
                      color: NytoColors.subtext,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Container(
                    width: 72,
                    height: 72,
                    alignment: Alignment.center,
                    decoration: const BoxDecoration(
                      color: NytoColors.cta,
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      'A',
                      style: GoogleFonts.fraunces(
                        fontSize: 32,
                        color: NytoColors.cream,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Flexible(
                              child: Text(
                                'Aanya Mehta',
                                style: GoogleFonts.fraunces(
                                  fontSize: 26,
                                  fontWeight: FontWeight.w400,
                                  color: NytoColors.cream,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            const Icon(
                              Icons.verified,
                              size: 18,
                              color: NytoColors.cta,
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Hyderabad · Jubilee Hills',
                          style: GoogleFonts.dmSans(
                            fontSize: 13,
                            color: NytoColors.creamMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              NytoGlass.panel(
                borderRadius: 16,
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.restaurant,
                          size: 14,
                          color: NytoColors.creamMuted,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'TABLES ATTENDED',
                          style: GoogleFonts.dmSans(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 1.2,
                            color: NytoColors.creamMuted,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          '3',
                          style: GoogleFonts.fraunces(
                            fontSize: 48,
                            fontWeight: FontWeight.w400,
                            color: NytoColors.cream,
                            height: 1,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Text(
                            'shared dinners attended',
                            style: GoogleFonts.dmSans(
                              fontSize: 14,
                              color: NytoColors.creamMuted,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              NytoGlass.panel(
                borderRadius: 16,
                padding: const EdgeInsets.all(18),
                child: Column(
                  children: [
                    Row(
                      children: [
                        const Icon(
                          Icons.local_fire_department,
                          size: 16,
                          color: NytoColors.orange,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'Streak',
                          style: GoogleFonts.dmSans(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: NytoColors.cream,
                          ),
                        ),
                        const Spacer(),
                        Text(
                          '2 / 3 to unlock next discount',
                          style: GoogleFonts.dmSans(
                            fontSize: 12,
                            color: NytoColors.creamMuted,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: 2 / 3,
                        minHeight: 6,
                        backgroundColor:
                            NytoColors.cream.withValues(alpha: 0.1),
                        color: NytoColors.orange,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: ['1', '2', '3']
                          .map(
                            (n) => Text(
                              n,
                              style: GoogleFonts.dmSans(
                                fontSize: 11,
                                color: NytoColors.creamMuted,
                              ),
                            ),
                          )
                          .toList(),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              NytoGlass.panel(
                borderRadius: 16,
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                child: Column(
                  children: [
                    _ProfileLink(
                      icon: Icons.event_note_outlined,
                      label: 'My Bookings',
                      badge: '2',
                      onTap: () {},
                    ),
                    _ProfileLink(
                      icon: Icons.settings_outlined,
                      label: 'Settings',
                      onTap: () {},
                    ),
                    _ProfileLink(
                      icon: Icons.help_outline_rounded,
                      label: 'Help',
                      onTap: () {},
                    ),
                    Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Sign out — auth wiring later.'),
                              backgroundColor: NytoColors.surface,
                            ),
                          );
                        },
                        borderRadius: BorderRadius.circular(12),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 14,
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.logout,
                                size: 20,
                                color: NytoColors.muted,
                              ),
                              const SizedBox(width: 12),
                              Text(
                                'Sign Out',
                                style: GoogleFonts.dmSans(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                  color: NytoColors.muted,
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
              const SizedBox(height: 28),
              Center(
                child: Text(
                  'NAVIGATE YOUR TIME OUT',
                  style: GoogleFonts.dmSans(
                    fontSize: 11,
                    letterSpacing: 1.4,
                    color: NytoColors.muted,
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

class _ProfileLink extends StatelessWidget {
  const _ProfileLink({
    required this.icon,
    required this.label,
    required this.onTap,
    this.badge,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final String? badge;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 14),
          child: Row(
            children: [
              Container(
                width: 34,
                height: 34,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  color: Colors.white.withValues(alpha: 0.06),
                ),
                child: Icon(icon, size: 18, color: NytoColors.ctaSoft),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  label,
                  style: GoogleFonts.dmSans(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: NytoColors.cream,
                  ),
                ),
              ),
              if (badge != null)
                Container(
                  margin: const EdgeInsets.only(right: 8),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: NytoColors.cta,
                    borderRadius: BorderRadius.circular(99),
                  ),
                  child: Text(
                    badge!,
                    style: GoogleFonts.dmSans(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ),
              Icon(
                Icons.chevron_right_rounded,
                color: NytoColors.muted,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
