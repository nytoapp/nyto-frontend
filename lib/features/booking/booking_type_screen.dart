import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:nyto_app/core/api/nyto_api.dart';
import 'package:nyto_app/core/theme/app_theme.dart';
import 'package:nyto_app/features/booking/payment_screen.dart';
import 'package:nyto_app/features/home/home_screen.dart';

enum BookingMode { solo, group }

/// Booking type — visual match to `designs/Screenshot (3716–3717)`.
class BookingTypeScreen extends StatefulWidget {
  const BookingTypeScreen({super.key, required this.table});

  final UpcomingTable table;

  @override
  State<BookingTypeScreen> createState() => _BookingTypeScreenState();
}

class _BookingTypeScreenState extends State<BookingTypeScreen> {
  BookingMode? _mode;
  int _groupSize = 2;
  bool _pressed = false;
  bool _loading = false;

  bool get _canContinue => _mode != null && !_loading;

  Future<void> _continueToPayment() async {
    if (_mode == null || _loading) return;
    final seats = _mode == BookingMode.solo ? 1 : _groupSize;
    setState(() {
      _pressed = false;
      _loading = true;
    });

    String bookingId = 'demo-${widget.table.id}-$seats';
    final seatSubtotal = widget.table.priceInr * seats;
    final gst = (seatSubtotal * 0.18).round();
    var total = seatSubtotal + gst;
    var sub = seatSubtotal;
    var gstAmt = gst;

    try {
      final res = await bookingsApi
          .create(
            tableId: widget.table.id,
            bookingType: _mode == BookingMode.solo ? 'SOLO' : 'GROUP',
            seatsBooked: seats,
          )
          .timeout(const Duration(seconds: 2));
      final booking = res['booking'] as Map<String, dynamic>?;
      final pricing = res['pricing'] as Map<String, dynamic>?;
      if (booking?['id'] is String) bookingId = booking!['id'] as String;
      if (pricing != null) {
        sub = pricing['seatSubtotal'] as int? ?? sub;
        gstAmt = pricing['gst'] as int? ?? gstAmt;
        total = pricing['total'] as int? ?? total;
      }
    } catch (_) {
      // Frontend demo: continue with local pricing when API is offline.
    }

    if (!mounted) return;
    setState(() => _loading = false);
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => PaymentScreen(
          table: widget.table,
          seatCount: seats,
          bookingId: bookingId,
          seatSubtotal: sub,
          gst: gstAmt,
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
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(28, 20, 28, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'How are you booking?',
                      style: GoogleFonts.fraunces(
                        fontSize: 30,
                        fontWeight: FontWeight.w400,
                        color: NytoColors.cream,
                        height: 1.2,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Choose how you\'d like to join the table.',
                      style: GoogleFonts.dmSans(
                        fontSize: 14,
                        color: NytoColors.creamMuted,
                        height: 1.45,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${widget.table.weekday} ${widget.table.dateLabel} · ${widget.table.timeLabel} · ${widget.table.area}',
                      style: GoogleFonts.jetBrainsMono(
                        fontSize: 12,
                        color: NytoColors.cream.withValues(alpha: 0.45),
                      ),
                    ),
                    const SizedBox(height: 28),
                    _BookingOptionCard(
                      selected: _mode == BookingMode.solo,
                      icon: Icons.person_outline,
                      title: 'Solo',
                      subtitle: 'I\'ll be matched individually',
                      onTap: () => setState(() => _mode = BookingMode.solo),
                    ),
                    const SizedBox(height: 12),
                    _BookingOptionCard(
                      selected: _mode == BookingMode.group,
                      icon: Icons.groups_outlined,
                      title: 'Group of 2 or 3',
                      subtitle:
                          'Friends book together, matched with others to fill 6',
                      onTap: () => setState(() => _mode = BookingMode.group),
                      footer: _mode == BookingMode.group
                          ? _GroupSizeStepper(
                              value: _groupSize,
                              onChanged: (v) =>
                                  setState(() => _groupSize = v),
                            )
                          : null,
                    ),
                    if (_mode == BookingMode.group) ...[
                      const SizedBox(height: 16),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            margin: const EdgeInsets.only(top: 6),
                            width: 6,
                            height: 6,
                            decoration: const BoxDecoration(
                              color: NytoColors.cta,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'Max 3 seats from one pre-formed group. Your party will be matched with others to complete a table of 6.',
                              style: GoogleFonts.dmSans(
                                fontSize: 13,
                                color: NytoColors.creamMuted,
                                height: 1.5,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ),
            Container(
              height: 1,
              margin: const EdgeInsets.symmetric(horizontal: 28),
              color: NytoColors.moss,
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(28, 16, 28, 24),
              child: GestureDetector(
                onTap: _canContinue ? _continueToPayment : null,
                onTapDown: _canContinue
                    ? (_) => setState(() => _pressed = true)
                    : null,
                onTapCancel: _canContinue
                    ? () => setState(() => _pressed = false)
                    : null,
                child: AnimatedScale(
                  scale: _pressed ? 0.98 : 1,
                  duration: const Duration(milliseconds: 90),
                  child: Container(
                    width: double.infinity,
                    height: 54,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: _canContinue
                          ? NytoColors.cta
                          : NytoColors.ctaDisabled,
                      borderRadius: BorderRadius.circular(28),
                    ),
                    child: _loading
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.2,
                              color: Colors.white,
                            ),
                          )
                        : Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                'Continue to payment',
                                style: GoogleFonts.dmSans(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: NytoColors.cream.withValues(
                                    alpha: _canContinue ? 1 : 0.55,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Icon(
                                Icons.arrow_forward,
                                size: 18,
                                color: NytoColors.cream.withValues(
                                  alpha: _canContinue ? 1 : 0.55,
                                ),
                              ),
                            ],
                          ),
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

class _BookingOptionCard extends StatelessWidget {
  const _BookingOptionCard({
    required this.selected,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.footer,
  });

  final bool selected;
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final Widget? footer;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: NytoColors.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: selected
                  ? NytoColors.cta
                  : NytoColors.cream.withValues(alpha: 0.12),
              width: selected ? 1.4 : 1,
            ),
          ),
          child: Column(
            children: [
              Row(
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: selected
                          ? NytoColors.cta.withValues(alpha: 0.18)
                          : NytoColors.cream.withValues(alpha: 0.06),
                    ),
                    child: Icon(
                      icon,
                      size: 22,
                      color: selected
                          ? NytoColors.cta
                          : NytoColors.creamMuted,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: GoogleFonts.dmSans(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: NytoColors.cream,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          subtitle,
                          style: GoogleFonts.dmSans(
                            fontSize: 13,
                            color: NytoColors.creamMuted,
                            height: 1.4,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  Container(
                    width: 22,
                    height: 22,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: selected
                            ? NytoColors.cta
                            : NytoColors.cream.withValues(alpha: 0.35),
                        width: 1.6,
                      ),
                    ),
                    child: selected
                        ? Center(
                            child: Container(
                              width: 12,
                              height: 12,
                              decoration: const BoxDecoration(
                                color: NytoColors.cta,
                                shape: BoxShape.circle,
                              ),
                            ),
                          )
                        : null,
                  ),
                ],
              ),
              if (footer != null) ...[
                const SizedBox(height: 16),
                footer!,
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _GroupSizeStepper extends StatelessWidget {
  const _GroupSizeStepper({required this.value, required this.onChanged});

  final int value;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    final canDec = value > 2;
    final canInc = value < 3;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: NytoColors.cream.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              'Seats in your group',
              style: GoogleFonts.dmSans(
                fontSize: 13,
                color: NytoColors.creamMuted,
              ),
            ),
          ),
          _StepButton(
            icon: Icons.remove,
            enabled: canDec,
            onTap: canDec ? () => onChanged(value - 1) : null,
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              '$value',
              style: GoogleFonts.fraunces(
                fontSize: 28,
                fontWeight: FontWeight.w400,
                color: NytoColors.cream,
              ),
            ),
          ),
          _StepButton(
            icon: Icons.add,
            enabled: canInc,
            onTap: canInc ? () => onChanged(value + 1) : null,
          ),
        ],
      ),
    );
  }
}

class _StepButton extends StatelessWidget {
  const _StepButton({
    required this.icon,
    required this.enabled,
    required this.onTap,
  });

  final IconData icon;
  final bool enabled;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: NytoColors.cream.withValues(alpha: enabled ? 0.35 : 0.12),
            ),
          ),
          child: Icon(
            icon,
            size: 18,
            color: NytoColors.cream.withValues(alpha: enabled ? 0.9 : 0.25),
          ),
        ),
      ),
    );
  }
}
