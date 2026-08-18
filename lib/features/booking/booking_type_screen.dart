import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:nyto_app/core/api/nyto_api.dart';
import 'package:nyto_app/core/theme/app_theme.dart';
import 'package:nyto_app/core/widgets/nyto_glass.dart';
import 'package:nyto_app/features/booking/invite_friends_screen.dart';
import 'package:nyto_app/features/home/home_screen.dart';

/// Book your own seat — friends join via invite link and pay themselves.
class BookingTypeScreen extends StatefulWidget {
  const BookingTypeScreen({super.key, required this.table});

  final UpcomingTable table;

  @override
  State<BookingTypeScreen> createState() => _BookingTypeScreenState();
}

class _BookingTypeScreenState extends State<BookingTypeScreen> {
  bool _pressed = false;
  bool _loading = false;

  Future<void> _continue() async {
    if (_loading) return;
    setState(() {
      _pressed = false;
      _loading = true;
    });

    const seats = 1;
    const gstRate = 0.05; // Match backend GST_RATE — confirm with CA for production.
    String bookingId = 'demo-${widget.table.id}-$seats';
    final seatSubtotal = widget.table.priceInr * seats;
    final gst = (seatSubtotal * gstRate).round();
    var total = seatSubtotal + gst;
    var sub = seatSubtotal;
    var gstAmt = gst;

    try {
      final res = await bookingsApi
          .create(
            tableId: widget.table.id,
            bookingType: 'SOLO',
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
      // Demo path when API is offline.
    }

    if (!mounted) return;
    setState(() => _loading = false);
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => InviteFriendsScreen(
          table: widget.table,
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
                      'Book your seat',
                      style: GoogleFonts.fraunces(
                        fontSize: 30,
                        fontWeight: FontWeight.w400,
                        color: NytoColors.cream,
                        height: 1.2,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'You pay for yourself. Friends can join the same table with an invite — they pay their own seat.',
                      style: GoogleFonts.dmSans(
                        fontSize: 14,
                        color: NytoColors.creamMuted,
                        height: 1.45,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${widget.table.weekday} ${widget.table.dateLabel} · ${widget.table.timeLabel} · ${widget.table.area}',
                      style: GoogleFonts.dmSans(
                        fontSize: 12,
                        color: NytoColors.cream.withValues(alpha: 0.45),
                      ),
                    ),
                    const SizedBox(height: 28),
                    NytoGlass.panel(
                      borderRadius: 18,
                      padding: const EdgeInsets.all(18),
                      child: Row(
                        children: [
                          Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: NytoColors.cta.withValues(alpha: 0.18),
                            ),
                            child: const Icon(
                              Icons.person_outline,
                              color: NytoColors.cta,
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Your seat',
                                  style: GoogleFonts.dmSans(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                    color: NytoColors.cream,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '1 seat · matched into a table of 6',
                                  style: GoogleFonts.dmSans(
                                    fontSize: 13,
                                    color: NytoColors.creamMuted,
                                    height: 1.35,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Text(
                            '₹${widget.table.priceInr}',
                            style: GoogleFonts.fraunces(
                              fontSize: 22,
                              color: NytoColors.cream,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Next: invite friends (optional), then pay for your seat only.',
                      style: GoogleFonts.dmSans(
                        fontSize: 13,
                        height: 1.4,
                        color: NytoColors.cream.withValues(alpha: 0.45),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Container(
              height: 1,
              margin: const EdgeInsets.symmetric(horizontal: 28),
              color: NytoColors.cream.withValues(alpha: 0.08),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(28, 16, 28, 24),
              child: GestureDetector(
                onTap: _loading ? null : _continue,
                onTapDown:
                    _loading ? null : (_) => setState(() => _pressed = true),
                onTapCancel:
                    _loading ? null : () => setState(() => _pressed = false),
                child: AnimatedScale(
                  scale: _pressed ? 0.98 : 1,
                  duration: const Duration(milliseconds: 90),
                  child: Container(
                    width: double.infinity,
                    height: 54,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: NytoColors.cta,
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
                        : Text(
                            'Continue',
                            style: GoogleFonts.dmSans(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
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
