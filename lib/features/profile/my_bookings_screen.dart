import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:nyto_app/core/api/api_client.dart';
import 'package:nyto_app/core/api/nyto_api.dart';
import 'package:nyto_app/core/theme/app_theme.dart';
import 'package:nyto_app/core/widgets/nyto_glass.dart';
import 'package:nyto_app/domain/booking.dart';
import 'package:nyto_app/features/booking/booking_detail_screen.dart';
import 'package:nyto_app/features/settings/settings_chrome.dart';

/// Reserved nights for the signed-in guest — loaded from `/bookings/me`.
class MyBookingsScreen extends StatefulWidget {
  const MyBookingsScreen({
    super.key,
    this.embedded = false,
    this.active = false,
  });

  /// When true (bottom-nav Bookings tab): no back chrome.
  final bool embedded;

  /// When used as a tab, reload whenever this becomes the selected tab.
  final bool active;

  @override
  State<MyBookingsScreen> createState() => _MyBookingsScreenState();
}

class _MyBookingsScreenState extends State<MyBookingsScreen> {
  List<BookingSummary> _bookings = const [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didUpdateWidget(covariant MyBookingsScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.active && !oldWidget.active) _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final rows = await bookingsApi
          .listMine()
          .timeout(const Duration(seconds: 10));
      if (!mounted) return;
      setState(() {
        _bookings = rows.map(BookingSummary.fromJson).toList();
        _loading = false;
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.message;
        _bookings = const [];
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _error = 'Couldn’t load bookings.';
        _bookings = const [];
        _loading = false;
      });
    }
  }

  Future<void> _open(BookingSummary booking) async {
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
    final body = RefreshIndicator(
      color: NytoColors.cta,
      backgroundColor: NytoColors.surface,
      onRefresh: _load,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
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
            'Seats you’ve reserved — show your entry code at the venue.',
            style: GoogleFonts.dmSans(
              fontSize: 14,
              height: 1.4,
              color: NytoColors.cream.withValues(alpha: 0.48),
            ),
          ),
          const SizedBox(height: 22),
          if (_loading)
            const Padding(
              padding: EdgeInsets.only(top: 48),
              child: Center(
                child: CircularProgressIndicator(color: NytoColors.cta),
              ),
            )
          else if (_error != null)
            Padding(
              padding: const EdgeInsets.only(top: 48),
              child: Column(
                children: [
                  Text(
                    _error!,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.dmSans(
                      fontSize: 14,
                      color: NytoColors.cream.withValues(alpha: 0.55),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextButton(
                    onPressed: _load,
                    child: Text(
                      'Try again',
                      style: GoogleFonts.dmSans(color: NytoColors.ctaSoft),
                    ),
                  ),
                ],
              ),
            )
          else if (_bookings.isEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 48),
              child: Text(
                'No nights booked yet.\nReserve a seat from Home.',
                textAlign: TextAlign.center,
                style: GoogleFonts.dmSans(
                  fontSize: 14,
                  height: 1.45,
                  color: NytoColors.cream.withValues(alpha: 0.45),
                ),
              ),
            )
          else
            for (final b in _bookings) ...[
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(18),
                    onTap: () => _open(b),
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
                                  b.table?.weekday ?? 'Night',
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
                                    color: NytoColors.ctaSoft
                                        .withValues(alpha: 0.45),
                                  ),
                                ),
                                child: Text(
                                  b.statusLabel,
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
                            b.table?.dateLabel ?? '',
                            style: GoogleFonts.dmSans(
                              fontSize: 14,
                              color: NytoColors.cream.withValues(alpha: 0.65),
                            ),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            '${b.table?.mealLabel ?? 'Dinner'} · ${b.table?.timeLabel ?? ''}',
                            style: GoogleFonts.dmSans(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: NytoColors.cream,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${b.area ?? b.venueName ?? 'Venue'} · ${b.city ?? ''}',
                            style: GoogleFonts.dmSans(
                              fontSize: 13,
                              color: NytoColors.cream.withValues(alpha: 0.45),
                            ),
                          ),
                          if (b.checkInCode != null && b.isConfirmed) ...[
                            const SizedBox(height: 12),
                            Text(
                              'Entry code  ${b.checkInCode}',
                              style: GoogleFonts.jetBrainsMono(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                letterSpacing: 1.2,
                                color: NytoColors.ctaSoft,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
        ],
      ),
    );

    if (widget.embedded) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(22, 12, 22, 0),
            child: Text(
              'Bookings',
              style: GoogleFonts.dmSans(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.6,
                color: NytoColors.cream.withValues(alpha: 0.45),
              ),
            ),
          ),
          Expanded(child: body),
        ],
      );
    }

    return SettingsPageScaffold(
      title: 'My Bookings',
      child: body,
    );
  }
}
