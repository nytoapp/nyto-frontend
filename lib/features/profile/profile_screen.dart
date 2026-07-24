import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:nyto_app/core/theme/app_theme.dart';

/// Profile — visual match to `designs/Screenshot (3728–3729)`.
class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: NytoColors.bg,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 28),
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
                      color: NytoColors.orange,
                      letterSpacing: 3.5,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: Icon(
                      Icons.close,
                      color: NytoColors.cream.withValues(alpha: 0.7),
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
                      color: NytoColors.orange,
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
                              color: NytoColors.orange,
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Mumbai · South Mumbai',
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
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: NytoColors.surface,
                  borderRadius: BorderRadius.circular(16),
                ),
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
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: NytoColors.surface,
                  borderRadius: BorderRadius.circular(16),
                ),
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
              const SizedBox(height: 24),
              Text(
                'BADGES',
                style: GoogleFonts.dmSans(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 1.4,
                  color: NytoColors.creamMuted,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: const [
                  Expanded(
                    child: _BadgeTile(
                      icon: Icons.ramen_dining,
                      label: 'First Table',
                      tint: Color(0xFF5B4A7A),
                    ),
                  ),
                  SizedBox(width: 8),
                  Expanded(
                    child: _BadgeTile(
                      icon: Icons.place,
                      label: 'Neighbourhood Regular',
                      tint: Color(0xFF7A3E4A),
                    ),
                  ),
                  SizedBox(width: 8),
                  Expanded(
                    child: _BadgeTile(
                      icon: Icons.local_florist,
                      label: 'Women-Only Table',
                      tint: Color(0xFF6A3A52),
                    ),
                  ),
                  SizedBox(width: 8),
                  Expanded(
                    child: _BadgeTile(
                      icon: Icons.lock_outline,
                      label: "Chef's Pick",
                      tint: Color(0xFF3A3530),
                      locked: true,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              const _SettingsRow(
                icon: Icons.calendar_today_outlined,
                title: 'My Bookings',
                trailing: '2 upcoming',
              ),
              const _SettingsRow(
                icon: Icons.verified_user_outlined,
                title: 'Verification',
                trailing: 'Verified',
                trailingColor: Color(0xFF7CB88A),
              ),
              const _SettingsRow(
                icon: Icons.restaurant_menu,
                title: 'Dietary Preferences',
                trailing: 'Vegetarian',
              ),
              const _SettingsRow(
                icon: Icons.support_agent,
                title: 'Support',
              ),
              const SizedBox(height: 8),
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
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    child: Row(
                      children: [
                        Icon(
                          Icons.logout,
                          size: 20,
                          color: NytoColors.orange.withValues(alpha: 0.95),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'Sign Out',
                          style: GoogleFonts.dmSans(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: NytoColors.orange,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 28),
              Center(
                child: Text(
                  'NAVIGATE YOUR TIME OUT',
                  style: GoogleFonts.dmSans(
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                    letterSpacing: 2.2,
                    color: NytoColors.creamMuted.withValues(alpha: 0.7),
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

class _BadgeTile extends StatelessWidget {
  const _BadgeTile({
    required this.icon,
    required this.label,
    required this.tint,
    this.locked = false,
  });

  final IconData icon;
  final String label;
  final Color tint;
  final bool locked;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 96,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: NytoColors.surface,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: tint,
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              size: 16,
              color: NytoColors.cream.withValues(alpha: locked ? 0.4 : 1),
            ),
          ),
          const Spacer(),
          Text(
            label,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.dmSans(
              fontSize: 10,
              height: 1.2,
              color: NytoColors.cream.withValues(alpha: locked ? 0.4 : 0.85),
            ),
          ),
        ],
      ),
    );
  }
}

class _SettingsRow extends StatelessWidget {
  const _SettingsRow({
    required this.icon,
    required this.title,
    this.trailing,
    this.trailingColor,
  });

  final IconData icon;
  final String title;
  final String? trailing;
  final Color? trailingColor;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          Icon(icon, size: 20, color: NytoColors.creamMuted),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              title,
              style: GoogleFonts.dmSans(
                fontSize: 15,
                color: NytoColors.cream,
              ),
            ),
          ),
          if (trailing != null)
            Text(
              trailing!,
              style: GoogleFonts.dmSans(
                fontSize: 13,
                color: trailingColor ?? NytoColors.creamMuted,
              ),
            ),
          const SizedBox(width: 6),
          Icon(
            Icons.chevron_right,
            size: 20,
            color: NytoColors.cream.withValues(alpha: 0.35),
          ),
        ],
      ),
    );
  }
}
