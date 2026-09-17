import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:nyto_app/core/api/api_client.dart';
import 'package:nyto_app/core/api/nyto_api.dart';
import 'package:nyto_app/core/theme/app_theme.dart';
import 'package:nyto_app/core/widgets/nyto_glass.dart';
import 'package:nyto_app/domain/booking.dart';
import 'package:nyto_app/features/booking/booking_detail_screen.dart';
import 'package:nyto_app/features/profile/my_bookings_screen.dart';
import 'package:nyto_app/features/settings/settings_chrome.dart';

/// Compact upcoming booking on Home — links to full My Bookings.
class MyBookingsStrip extends StatefulWidget {
  const MyBookingsStrip({super.key});

  @override
  State<MyBookingsStrip> createState() => _MyBookingsStripState();
}

class _MyBookingsStripState extends State<MyBookingsStrip> {
  BookingSummary? _next;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final rows = await bookingsApi
          .listMine()
          .timeout(const Duration(seconds: 8));
      if (!mounted) return;
      final bookings = rows.map(BookingSummary.fromJson).toList();
      final now = DateTime.now();
      BookingSummary? upcoming;
      for (final b in bookings) {
        if (!b.isConfirmed) continue;
        final start = b.table?.startsAt;
        if (start != null && start.isBefore(now)) continue;
        upcoming = b;
        break;
      }
      setState(() {
        _next = upcoming;
        _loading = false;
      });
    } on ApiException catch (_) {
      if (!mounted) return;
      setState(() {
        _next = null;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _next = null;
        _loading = false;
      });
    }
  }

  Future<void> _openAll() async {
    await openSettingsPage<void>(context, const MyBookingsScreen());
    if (mounted) _load();
  }

  Future<void> _openBooking(BookingSummary booking) async {
    final table = booking.table;
    if (table == null) return;
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => BookingDetailScreen(
          table: table,
          bookingId: booking.id,
          checkInCode: booking.checkInCode,
          status: booking.status,
        ),
      ),
    );
    if (mounted) _load();
  }

  @override
  Widget build(BuildContext context) {
    if (_loading || _next == null) return const SizedBox.shrink();
    final b = _next!;
    final table = b.table;

    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 0, 18, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'MY BOOKINGS',
                style: GoogleFonts.dmSans(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.4,
                  color: NytoColors.cream.withValues(alpha: 0.42),
                ),
              ),
              const Spacer(),
              TextButton(
                onPressed: _openAll,
                style: TextButton.styleFrom(
                  foregroundColor: NytoColors.ctaSoft,
                  padding: EdgeInsets.zero,
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: Text(
                  'See all',
                  style: GoogleFonts.dmSans(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(18),
              onTap: () => _openBooking(b),
              child: NytoGlass.panel(
                borderRadius: 18,
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            table?.fullDateLabel ?? 'Upcoming night',
                            style: GoogleFonts.dmSerifDisplay(
                              fontSize: 18,
                              color: NytoColors.cream,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${table?.mealLabel ?? 'Dinner'} · ${table?.timeLabel ?? ''} · ${b.venueName ?? b.area ?? 'Venue'}',
                            style: GoogleFonts.dmSans(
                              fontSize: 13,
                              color: NytoColors.cream.withValues(alpha: 0.55),
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
          ),
        ],
      ),
    );
  }
}
