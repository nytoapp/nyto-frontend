import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:nyto_app/core/theme/app_theme.dart';
import 'package:nyto_app/core/widgets/nyto_glass.dart';
import 'package:nyto_app/features/booking/payment_screen.dart';
import 'package:nyto_app/features/home/home_screen.dart';
import 'package:share_plus/share_plus.dart';

/// Share table invite — friends open link, join same table, pay their own seat.
/// Deep-link routing is UI/demo until backend + app links are wired.
class InviteFriendsScreen extends StatelessWidget {
  const InviteFriendsScreen({
    super.key,
    required this.table,
    required this.bookingId,
    required this.seatSubtotal,
    required this.gst,
    required this.total,
  });

  final UpcomingTable table;
  final String bookingId;
  final int seatSubtotal;
  final int gst;
  final int total;

  String get _inviteUrl =>
      'https://nyto.app/join/${table.id}?src=invite';

  String get _shareText =>
      'Join me at NYTO — ${table.weekday} ${table.dateLabel}, '
      '${table.timeLabel}, ${table.area}. '
      'Same table, you pay your own seat: $_inviteUrl';

  Future<void> _copyLink(BuildContext context) async {
    await Clipboard.setData(ClipboardData(text: _inviteUrl));
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Invite link copied'),
        backgroundColor: NytoColors.surface,
      ),
    );
  }

  Future<void> _shareInvite() async {
    await SharePlus.instance.share(
      ShareParams(text: _shareText),
    );
  }

  void _toPayment(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => PaymentScreen(
          table: table,
          seatCount: 1,
          bookingId: bookingId,
          seatSubtotal: seatSubtotal,
          gst: gst,
          total: total,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: NytoColors.bg,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 12, 24, 0),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: Icon(
                      Icons.arrow_back_ios_new,
                      size: 18,
                      color: NytoColors.cream.withValues(alpha: 0.8),
                    ),
                  ),
                  Text(
                    'NYTO',
                    style: GoogleFonts.fraunces(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: NytoColors.cta,
                      letterSpacing: 3.5,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(28, 16, 28, 16),
                children: [
                  Text(
                    'Invite friends',
                    style: GoogleFonts.fraunces(
                      fontSize: 30,
                      color: NytoColors.cream,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Send a link. They join the same table and pay for their own seat — you only pay yours.',
                    style: GoogleFonts.dmSans(
                      fontSize: 14,
                      height: 1.45,
                      color: NytoColors.creamMuted,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${table.weekday} ${table.dateLabel} · ${table.timeLabel} · ${table.area}',
                    style: GoogleFonts.dmSans(
                      fontSize: 12,
                      color: NytoColors.cream.withValues(alpha: 0.45),
                    ),
                  ),
                  const SizedBox(height: 24),
                  _ShareAction(
                    icon: Icons.ios_share_rounded,
                    label: 'Share invite',
                    subtitle: 'WhatsApp, Telegram, Messages…',
                    onTap: _shareInvite,
                  ),
                  const SizedBox(height: 10),
                  _ShareAction(
                    icon: Icons.link_rounded,
                    label: 'Copy link',
                    subtitle: 'Paste anywhere',
                    onTap: () => _copyLink(context),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'If they don’t have the app yet, they install → finish signup → land on this same table.',
                    style: GoogleFonts.dmSans(
                      fontSize: 13,
                      height: 1.4,
                      color: NytoColors.cream.withValues(alpha: 0.4),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(28, 8, 28, 24),
              child: Column(
                children: [
                  SizedBox(
                    width: double.infinity,
                    height: 54,
                    child: FilledButton(
                      onPressed: () => _toPayment(context),
                      style: FilledButton.styleFrom(
                        backgroundColor: NytoColors.cta,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(28),
                        ),
                      ),
                      child: Text(
                        'Continue to payment',
                        style: GoogleFonts.dmSans(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextButton(
                    onPressed: () => _toPayment(context),
                    child: Text(
                      'Skip invite for now',
                      style: GoogleFonts.dmSans(
                        color: NytoColors.cream.withValues(alpha: 0.5),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ShareAction extends StatelessWidget {
  const _ShareAction({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: NytoGlass.panel(
          borderRadius: 16,
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: NytoColors.cta.withValues(alpha: 0.16),
                ),
                child: Icon(icon, color: NytoColors.ctaSoft),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: GoogleFonts.dmSans(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: NytoColors.cream,
                      ),
                    ),
                    Text(
                      subtitle,
                      style: GoogleFonts.dmSans(
                        fontSize: 12,
                        color: NytoColors.creamMuted,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                color: NytoColors.cream.withValues(alpha: 0.35),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
