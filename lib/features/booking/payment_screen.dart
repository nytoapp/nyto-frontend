import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:nyto_app/core/api/nyto_api.dart';
import 'package:nyto_app/core/theme/app_theme.dart';
import 'package:nyto_app/features/home/home_screen.dart';
import 'package:nyto_app/features/table/table_reveal_screen.dart';

enum PayMethod { upi, card }

/// Payment — visual match to `designs/Screenshot (3718–3719)`.
class PaymentScreen extends StatefulWidget {
  const PaymentScreen({
    super.key,
    required this.table,
    required this.seatCount,
    required this.bookingId,
    required this.seatSubtotal,
    required this.gst,
    required this.total,
  });

  final UpcomingTable table;
  final int seatCount;
  final String bookingId;
  final int seatSubtotal;
  final int gst;
  final int total;

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  PayMethod _method = PayMethod.upi;
  bool _pressed = false;
  bool _paying = false;

  int get _seatSubtotal => widget.seatSubtotal;
  int get _gst => widget.gst;
  int get _total => widget.total;

  Future<void> _pay() async {
    if (_paying) return;
    setState(() {
      _pressed = false;
      _paying = true;
    });
    try {
      if (!widget.bookingId.startsWith('demo-')) {
        await bookingsApi
            .pay(
              bookingId: widget.bookingId,
              method: _method == PayMethod.upi ? 'UPI' : 'CARD',
            )
            .timeout(const Duration(seconds: 2));
      }
      if (!mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute<void>(
          builder: (_) => const TableRevealScreen(),
        ),
        (route) => route.isFirst,
      );
    } catch (_) {
      // Demo / offline: still continue the UX path.
      if (!mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute<void>(
          builder: (_) => const TableRevealScreen(),
        ),
        (route) => route.isFirst,
      );
    } finally {
      if (mounted) setState(() => _paying = false);
    }
  }

  String _formatInr(int amount) {
    final raw = amount.toString();
    if (raw.length <= 3) return '₹$raw';
    final head = raw.substring(0, raw.length - 3);
    final tail = raw.substring(raw.length - 3);
    return '₹$head,$tail';
  }

  String get _dayLong {
    const map = {
      'Fri': 'Friday',
      'Sat': 'Saturday',
      'Sun': 'Sunday',
      'Wed': 'Wednesday',
      'Thu': 'Thursday',
      'Mon': 'Monday',
      'Tue': 'Tuesday',
    };
    return map[widget.table.weekday] ?? widget.table.weekday;
  }

  String get _slotShort =>
      widget.table.slot == MealSlot.daytimeLunch ? 'Daytime' : 'Evening';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: NytoColors.bg,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 24, 0),
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
                padding: const EdgeInsets.fromLTRB(28, 16, 28, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'SEAT PAYMENT',
                      style: GoogleFonts.dmSans(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 1.6,
                        color: NytoColors.cta,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Pay for your seat.',
                      style: GoogleFonts.fraunces(
                        fontSize: 32,
                        fontWeight: FontWeight.w400,
                        color: NytoColors.cream,
                      ),
                    ),
                    const SizedBox(height: 24),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: NytoColors.surface,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: NytoColors.cream.withValues(alpha: 0.08),
                        ),
                      ),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 46,
                                height: 46,
                                alignment: Alignment.center,
                                decoration: const BoxDecoration(
                                  color: NytoColors.moss,
                                  shape: BoxShape.circle,
                                ),
                                child: Text(
                                  widget.table.weekday,
                                  style: GoogleFonts.dmSans(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                    color: NytoColors.cream,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      '$_dayLong · $_slotShort',
                                      style: GoogleFonts.dmSans(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w600,
                                        color: NytoColors.cream,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'Table for 6 · Matched strangers',
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
                          const SizedBox(height: 20),
                          _MoneyRow(
                            label:
                                'Seat price × ${widget.seatCount}',
                            value: _formatInr(_seatSubtotal),
                          ),
                          const SizedBox(height: 10),
                          _MoneyRow(
                            label: 'GST (5%)',
                            value: _formatInr(_gst),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            child: Divider(
                              height: 1,
                              color: NytoColors.cream.withValues(alpha: 0.12),
                            ),
                          ),
                          _MoneyRow(
                            label: 'Total',
                            value: _formatInr(_total),
                            emphasize: true,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: NytoColors.cta.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: NytoColors.cta.withValues(alpha: 0.45),
                        ),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            Icons.lock_outline,
                            size: 16,
                            color: NytoColors.cta.withValues(alpha: 0.95),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'Payment is prepaid and final. No pay-at-venue. No bill splitting.',
                              style: GoogleFonts.dmSans(
                                fontSize: 13,
                                height: 1.45,
                                color: const Color(0xFFE8B896),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 28),
                    Text(
                      'PAY VIA',
                      style: GoogleFonts.dmSans(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 1.4,
                        color: NytoColors.creamMuted,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: _PayMethodTile(
                            selected: _method == PayMethod.upi,
                            icon: Icons.smartphone_outlined,
                            title: 'UPI',
                            subtitle: 'GPay · PhonePe · Paytm',
                            onTap: () =>
                                setState(() => _method = PayMethod.upi),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _PayMethodTile(
                            selected: _method == PayMethod.card,
                            icon: Icons.credit_card,
                            title: 'Card',
                            subtitle: 'Debit · Credit',
                            onTap: () =>
                                setState(() => _method = PayMethod.card),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(28, 8, 28, 24),
              child: Column(
                children: [
                  GestureDetector(
                    onTapDown: _paying
                        ? null
                        : (_) => setState(() => _pressed = true),
                    onTapUp: _paying ? null : (_) => _pay(),
                    onTapCancel: _paying
                        ? null
                        : () => setState(() => _pressed = false),
                    child: AnimatedScale(
                      scale: _pressed ? 0.98 : 1,
                      duration: const Duration(milliseconds: 90),
                      child: Container(
                        width: double.infinity,
                        height: 54,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: NytoColors.cta,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: _paying
                            ? const SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.2,
                                  color: NytoColors.cream,
                                ),
                              )
                            : Text(
                                'Pay ${_formatInr(_total)}',
                                style: GoogleFonts.dmSans(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                  color: NytoColors.cream,
                                ),
                              ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Secured · Non-refundable',
                    style: GoogleFonts.dmSans(
                      fontSize: 12,
                      color: NytoColors.creamMuted,
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

class _MoneyRow extends StatelessWidget {
  const _MoneyRow({
    required this.label,
    required this.value,
    this.emphasize = false,
  });

  final String label;
  final String value;
  final bool emphasize;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          label,
          style: GoogleFonts.dmSans(
            fontSize: emphasize ? 16 : 14,
            fontWeight: emphasize ? FontWeight.w600 : FontWeight.w400,
            color: emphasize ? NytoColors.cream : NytoColors.creamMuted,
          ),
        ),
        const Spacer(),
        Text(
          value,
          style: GoogleFonts.jetBrainsMono(
            fontSize: emphasize ? 20 : 15,
            fontWeight: emphasize ? FontWeight.w600 : FontWeight.w500,
            color: NytoColors.cream,
          ),
        ),
      ],
    );
  }
}

class _PayMethodTile extends StatelessWidget {
  const _PayMethodTile({
    required this.selected,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final bool selected;
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          padding: const EdgeInsets.fromLTRB(14, 16, 14, 16),
          decoration: BoxDecoration(
            color: NytoColors.surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: selected
                  ? NytoColors.cta
                  : NytoColors.cream.withValues(alpha: 0.1),
              width: selected ? 1.4 : 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                icon,
                size: 22,
                color: selected ? NytoColors.cta : NytoColors.creamMuted,
              ),
              const SizedBox(height: 12),
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
                  fontSize: 11,
                  color: NytoColors.creamMuted,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
