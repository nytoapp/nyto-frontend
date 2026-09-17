import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:nyto_app/core/theme/app_theme.dart';
import 'package:nyto_app/core/widgets/nyto_glass.dart';
import 'package:nyto_app/domain/table.dart';
import 'package:nyto_app/features/booking/payment_screen.dart';
import 'package:nyto_app/features/onboarding/widgets/onboarding_chrome.dart';
import 'package:share_plus/share_plus.dart';

/// How the guest handled invites before payment.
enum InviteHandlingChoice { shared, copied, skipped }

/// Share table invite — friends open link, join same table, pay their own seat.
/// Deep-link routing is UI/demo until backend + app links are wired.
class InviteFriendsScreen extends StatefulWidget {
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

  @override
  State<InviteFriendsScreen> createState() => _InviteFriendsScreenState();
}

class _InviteFriendsScreenState extends State<InviteFriendsScreen> {
  InviteHandlingChoice? _choice;
  bool _sharing = false;
  bool _navigating = false;
  String? _inlineHint;

  UpcomingTable get table => widget.table;

  bool get _canContinue => _choice != null && !_navigating;

  String get _inviteUrl =>
      'https://nyto.app/join/${table.id}?src=invite';

  String get _shareText =>
      'Join me at NYTO. ${table.weekday} ${table.dateLabel}, '
      '${table.timeLabel}, ${table.area}. '
      'Same table, you pay your own seat: $_inviteUrl';

  void _setChoice(InviteHandlingChoice value, {String? hint}) {
    if (!mounted) return;
    HapticFeedback.selectionClick();
    setState(() {
      _choice = value;
      _inlineHint = hint;
    });
  }

  Future<void> _shareInvite() async {
    if (_sharing) return;
    setState(() => _sharing = true);
    try {
      // Opening the system sheet counts as handling the invite once the
      // user returns — even if they dismiss without sending.
      await SharePlus.instance.share(ShareParams(text: _shareText));
      if (!mounted) return;
      _setChoice(
        InviteHandlingChoice.shared,
        hint: 'Invite shared. You can continue to payment.',
      );
    } catch (_) {
      if (!mounted) return;
      _setChoice(
        InviteHandlingChoice.shared,
        hint: 'Share sheet opened. You can continue to payment.',
      );
    } finally {
      if (mounted) setState(() => _sharing = false);
    }
  }

  Future<void> _copyLink() async {
    await Clipboard.setData(ClipboardData(text: _inviteUrl));
    if (!mounted) return;
    _setChoice(
      InviteHandlingChoice.copied,
      hint: 'Invite link copied',
    );
    final messenger = ScaffoldMessenger.of(context);
    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor: NytoColors.surfaceElevated,
        margin: const EdgeInsets.fromLTRB(20, 0, 20, 96),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        content: Text(
          'Invite link copied',
          style: GoogleFonts.dmSans(
            color: NytoColors.cream,
            fontWeight: FontWeight.w600,
          ),
        ),
        duration: const Duration(milliseconds: 1800),
      ),
    );
  }

  void _skipInvite() {
    _setChoice(
      InviteHandlingChoice.skipped,
      hint: 'You’ll continue without inviting for now.',
    );
  }

  void _toPayment() {
    if (!_canContinue) return;
    _navigating = true;
    setState(() {});
    Navigator.of(context)
        .push(
          MaterialPageRoute<void>(
            builder: (_) => PaymentScreen(
              table: table,
              seatCount: 1,
              bookingId: widget.bookingId,
              seatSubtotal: widget.seatSubtotal,
              gst: widget.gst,
              total: widget.total,
            ),
          ),
        )
        .whenComplete(() {
      if (mounted) setState(() => _navigating = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.paddingOf(context).bottom;

    return Scaffold(
      backgroundColor: NytoColors.brandInk,
      body: Stack(
        children: [
          const NytoAmbientField(intense: true),
          SafeArea(
            bottom: false,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 24, 0),
                  child: Row(
                    children: [
                      IconButton(
                        onPressed: () => Navigator.of(context).pop(),
                        icon: Icon(
                          Icons.arrow_back_ios_new_rounded,
                          size: 18,
                          color: NytoColors.cream.withValues(alpha: 0.85),
                        ),
                      ),
                      Text(
                        'NYTO',
                        style: GoogleFonts.dmSerifDisplay(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: NytoColors.ctaSoft,
                          letterSpacing: 3.2,
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(28, 12, 28, 20),
                    children: [
                      Text(
                        'Invite friends',
                        style: GoogleFonts.dmSerifDisplay(
                          fontSize: 30,
                          height: 1.15,
                          color: NytoColors.cream,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'Send a link. They join the same table and pay for their own seat. You only pay yours.',
                        style: GoogleFonts.dmSans(
                          fontSize: 14,
                          height: 1.45,
                          color: NytoColors.cream.withValues(alpha: 0.58),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        '${table.weekday} ${table.dateLabel} · ${table.timeLabel} · ${table.area}',
                        style: GoogleFonts.dmSans(
                          fontSize: 12,
                          letterSpacing: 0.2,
                          color: NytoColors.cream.withValues(alpha: 0.4),
                        ),
                      ),
                      const SizedBox(height: 28),
                      Text(
                        'Share, copy a link, or skip. Then continue to payment.',
                        style: GoogleFonts.dmSans(
                          fontSize: 13,
                          height: 1.4,
                          fontWeight: FontWeight.w500,
                          color: NytoColors.ctaSoft.withValues(alpha: 0.85),
                        ),
                      ),
                      const SizedBox(height: 14),
                      _InviteOptionCard(
                        icon: Icons.ios_share_rounded,
                        title: 'Share invite',
                        subtitle: 'WhatsApp, Telegram, Messages…',
                        trailing: Icons.chevron_right_rounded,
                        selected: _choice == InviteHandlingChoice.shared,
                        busy: _sharing,
                        semanticsLabel: 'Share invite via system share sheet',
                        onTap: _sharing ? null : _shareInvite,
                      ),
                      const SizedBox(height: 10),
                      _InviteOptionCard(
                        icon: Icons.link_rounded,
                        title: 'Copy invite link',
                        subtitle: 'Paste anywhere',
                        trailing: Icons.chevron_right_rounded,
                        selected: _choice == InviteHandlingChoice.copied,
                        semanticsLabel: 'Copy invite link to clipboard',
                        onTap: _copyLink,
                      ),
                      const SizedBox(height: 18),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: _SkipInviteAction(
                          selected: _choice == InviteHandlingChoice.skipped,
                          onTap: _skipInvite,
                        ),
                      ),
                      if (_inlineHint != null) ...[
                        const SizedBox(height: 18),
                        AnimatedSwitcher(
                          duration: const Duration(milliseconds: 240),
                          child: Text(
                            _inlineHint!,
                            key: ValueKey(_inlineHint),
                            style: GoogleFonts.dmSans(
                              fontSize: 13,
                              height: 1.4,
                              color: NytoColors.cream.withValues(alpha: 0.55),
                            ),
                          ),
                        ),
                      ],
                      const SizedBox(height: 22),
                      Text(
                        'If they don’t have the app yet, they install → finish signup → land on this same table.',
                        style: GoogleFonts.dmSans(
                          fontSize: 12.5,
                          height: 1.45,
                          color: NytoColors.cream.withValues(alpha: 0.38),
                        ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: EdgeInsets.fromLTRB(28, 8, 28, 16 + bottomInset),
                  child: NytoPrimaryButton(
                    label: 'Continue to payment',
                    enabled: _canContinue,
                    onPressed: _canContinue ? _toPayment : null,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _InviteOptionCard extends StatelessWidget {
  const _InviteOptionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.trailing,
    required this.selected,
    required this.onTap,
    required this.semanticsLabel,
    this.busy = false,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final IconData trailing;
  final bool selected;
  final bool busy;
  final VoidCallback? onTap;
  final String semanticsLabel;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      label: semanticsLabel,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(18),
          splashColor: NytoColors.cta.withValues(alpha: 0.08),
          highlightColor: Colors.transparent,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            curve: const Cubic(0.16, 1, 0.3, 1),
            child: NytoGlass.panel(
              selected: selected,
              borderRadius: 18,
              padding: const EdgeInsets.fromLTRB(14, 14, 12, 14),
              child: Row(
                children: [
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 220),
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      color: NytoColors.cta.withValues(
                        alpha: selected ? 0.22 : 0.14,
                      ),
                    ),
                    child: busy
                        ? const Padding(
                            padding: EdgeInsets.all(12),
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: NytoColors.ctaSoft,
                            ),
                          )
                        : Icon(icon, color: NytoColors.ctaSoft, size: 22),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: GoogleFonts.dmSans(
                            fontSize: 15.5,
                            fontWeight: FontWeight.w700,
                            color: NytoColors.cream,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          subtitle,
                          style: GoogleFonts.dmSans(
                            fontSize: 12.5,
                            color: NytoColors.cream.withValues(alpha: 0.5),
                          ),
                        ),
                      ],
                    ),
                  ),
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 200),
                    child: selected
                        ? Icon(
                            Icons.check_circle_rounded,
                            key: const ValueKey('check'),
                            color: NytoColors.ctaSoft,
                            size: 22,
                          )
                        : Icon(
                            trailing,
                            key: const ValueKey('chevron'),
                            color: NytoColors.cream.withValues(alpha: 0.32),
                            size: 22,
                          ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Secondary decision — not a peer of the share/copy cards.
class _SkipInviteAction extends StatelessWidget {
  const _SkipInviteAction({
    required this.selected,
    required this.onTap,
  });

  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      label: 'Skip invite for now',
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: selected
                  ? NytoColors.cta.withValues(alpha: 0.35)
                  : Colors.transparent,
            ),
            color: selected
                ? NytoColors.cta.withValues(alpha: 0.08)
                : Colors.transparent,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (selected) ...[
                Icon(
                  Icons.check_rounded,
                  size: 16,
                  color: NytoColors.ctaSoft.withValues(alpha: 0.9),
                ),
                const SizedBox(width: 6),
              ],
              Text(
                'Skip invite for now',
                style: GoogleFonts.dmSans(
                  fontSize: 14,
                  fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                  color: selected
                      ? NytoColors.cream.withValues(alpha: 0.85)
                      : NytoColors.cream.withValues(alpha: 0.48),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
