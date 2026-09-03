import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:nyto_app/core/api/api_client.dart';
import 'package:nyto_app/core/api/nyto_api.dart';
import 'package:nyto_app/core/theme/app_theme.dart';
import 'package:nyto_app/core/widgets/nyto_glass.dart';
import 'package:nyto_app/domain/booking.dart';
import 'package:nyto_app/domain/table.dart';
import 'package:nyto_app/features/home/home_screen.dart';
import 'package:nyto_app/features/table/table_chat_screen.dart';

/// Post-payment booking detail — venue + entry code + chat.
class BookingDetailScreen extends StatefulWidget {
  const BookingDetailScreen({
    super.key,
    required this.table,
    required this.bookingId,
    this.checkInCode,
    this.status,
  });

  final UpcomingTable table;
  final String bookingId;
  final String? checkInCode;
  final String? status;

  @override
  State<BookingDetailScreen> createState() => _BookingDetailScreenState();
}

class _BookingDetailScreenState extends State<BookingDetailScreen> {
  late UpcomingTable _table;
  String? _checkInCode;
  String _status = 'CONFIRMED';
  bool _loading = false;
  bool _cancelling = false;

  static const _dayMap = {
    'Fri': 'Friday',
    'Sat': 'Saturday',
    'Sun': 'Sunday',
    'Wed': 'Wednesday',
    'Thu': 'Thursday',
    'Mon': 'Monday',
    'Tue': 'Tuesday',
  };

  @override
  void initState() {
    super.initState();
    _table = widget.table;
    _checkInCode = widget.checkInCode;
    _status = widget.status ?? 'CONFIRMED';
    _refresh();
  }

  String get _dayLong => _dayMap[_table.weekday] ?? _table.weekday;
  String get _slot =>
      _table.slot == MealSlot.daytimeLunch ? 'Daytime' : 'Evening';

  bool get _canCancel =>
      _status == 'PENDING_PAYMENT' || _status == 'CONFIRMED';

  Future<void> _refresh() async {
    if (widget.bookingId.startsWith('demo-')) return;
    setState(() => _loading = true);
    try {
      final res = await bookingsApi
          .get(widget.bookingId)
          .timeout(const Duration(seconds: 8));
      if (!mounted) return;
      final bookingMap = res['booking'];
      final summary = bookingMap is Map<String, dynamic>
          ? BookingSummary.fromJson({
              ...bookingMap,
              'checkInCode':
                  res['checkInCode'] ?? bookingMap['checkInCode'],
            })
          : null;
      setState(() {
        if (summary?.table != null) _table = summary!.table!;
        _checkInCode = summary?.checkInCode ??
            res['checkInCode'] as String? ??
            _checkInCode;
        _status = summary?.status ?? _status;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  void _openChat() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => TableChatScreen(
          tableId: _table.id,
          venueName: _table.area,
          dayLabel: _dayLong,
          timeLabel: _table.timeLabel,
        ),
      ),
    );
  }

  Future<void> _copyCode() async {
    final code = _checkInCode;
    if (code == null || code.isEmpty) return;
    await Clipboard.setData(ClipboardData(text: code));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Entry code copied'),
        backgroundColor: NytoColors.surface,
      ),
    );
  }

  Future<void> _cancel() async {
    if (!_canCancel || _cancelling) return;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: NytoColors.surface,
        title: Text(
          'Cancel this booking?',
          style: GoogleFonts.fraunces(color: NytoColors.cream),
        ),
        content: Text(
          'Your seat will be released. Paid bookings are refunded as a stub for now.',
          style: GoogleFonts.dmSans(
            color: NytoColors.cream.withValues(alpha: 0.7),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('Keep', style: GoogleFonts.dmSans(color: NytoColors.cream)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(
              'Cancel booking',
              style: GoogleFonts.dmSans(color: NytoColors.ctaSoft),
            ),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;

    setState(() => _cancelling = true);
    try {
      await bookingsApi
          .cancel(widget.bookingId)
          .timeout(const Duration(seconds: 8));
      if (!mounted) return;
      setState(() {
        _status = 'CANCELLED';
        _cancelling = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Booking cancelled'),
          backgroundColor: NytoColors.surface,
        ),
      );
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _cancelling = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.message),
          backgroundColor: NytoColors.surface,
        ),
      );
    } catch (_) {
      if (!mounted) return;
      setState(() => _cancelling = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Couldn’t cancel. Try again.'),
          backgroundColor: NytoColors.surface,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final showCode = _checkInCode != null &&
        _checkInCode!.isNotEmpty &&
        (_status == 'CONFIRMED' || _status == 'ATTENDED');

    return Scaffold(
      backgroundColor: NytoColors.bg,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 8, 24, 0),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () {
                      Navigator.of(context).pushAndRemoveUntil(
                        MaterialPageRoute<void>(
                          builder: (_) => const HomeScreen(),
                        ),
                        (_) => false,
                      );
                    },
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
                  const Spacer(),
                  if (_loading)
                    const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: NytoColors.cta,
                      ),
                    ),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(28, 24, 28, 28),
                children: [
                  Text(
                    'YOUR BOOKING',
                    style: GoogleFonts.dmSans(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 1.6,
                      color: NytoColors.cta,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    _status == 'CANCELLED'
                        ? 'Booking cancelled.'
                        : _status == 'ATTENDED'
                            ? 'You’re checked in.'
                            : 'Seat confirmed.',
                    style: GoogleFonts.fraunces(
                      fontSize: 32,
                      fontWeight: FontWeight.w400,
                      color: NytoColors.cream,
                    ),
                  ),
                  const SizedBox(height: 24),
                  NytoGlass.panel(
                    borderRadius: 18,
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                _table.area,
                                style: GoogleFonts.fraunces(
                                  fontSize: 24,
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
                                BookingSummary(
                                  id: widget.bookingId,
                                  status: _status,
                                  seatsBooked: 1,
                                  bookingType: 'SOLO',
                                ).statusLabel,
                                style: GoogleFonts.dmSans(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: NytoColors.ctaSoft,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          _table.city,
                          style: GoogleFonts.dmSans(
                            fontSize: 14,
                            color: NytoColors.creamMuted,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Divider(
                          height: 1,
                          color: NytoColors.cream.withValues(alpha: 0.1),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Icon(
                              Icons.calendar_today_outlined,
                              size: 16,
                              color: NytoColors.ctaSoft,
                            ),
                            const SizedBox(width: 10),
                            Text(
                              '$_dayLong, ${_table.dateLabel}',
                              style: GoogleFonts.dmSans(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                color: NytoColors.cream,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Icon(
                              Icons.access_time,
                              size: 16,
                              color: NytoColors.ctaSoft,
                            ),
                            const SizedBox(width: 10),
                            Text(
                              '${_table.timeLabel} · $_slot',
                              style: GoogleFonts.dmSans(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                color: NytoColors.cream,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Icon(
                              Icons.people_outline,
                              size: 16,
                              color: NytoColors.ctaSoft,
                            ),
                            const SizedBox(width: 10),
                            Text(
                              'Table for ${_table.capacity} · Matched strangers',
                              style: GoogleFonts.dmSans(
                                fontSize: 15,
                                color: NytoColors.creamMuted,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  if (showCode) ...[
                    const SizedBox(height: 20),
                    NytoGlass.panel(
                      borderRadius: 18,
                      padding: const EdgeInsets.fromLTRB(20, 20, 20, 18),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'VENUE ENTRY',
                            style: GoogleFonts.dmSans(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 1.4,
                              color: NytoColors.cta,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Show this code at the door.',
                            style: GoogleFonts.dmSans(
                              fontSize: 13,
                              color: NytoColors.cream.withValues(alpha: 0.55),
                            ),
                          ),
                          const SizedBox(height: 16),
                          Center(
                            child: Text(
                              _checkInCode!,
                              style: GoogleFonts.jetBrainsMono(
                                fontSize: 32,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 4,
                                color: NytoColors.cream,
                              ),
                            ),
                          ),
                          const SizedBox(height: 14),
                          SizedBox(
                            width: double.infinity,
                            child: OutlinedButton.icon(
                              onPressed: _copyCode,
                              icon: const Icon(Icons.copy_rounded, size: 18),
                              label: const Text('Copy code'),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: NytoColors.cream,
                                side: BorderSide(
                                  color: NytoColors.cream.withValues(alpha: 0.25),
                                ),
                                padding: const EdgeInsets.symmetric(vertical: 12),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: 20),
                  NytoGlass.panel(
                    borderRadius: 16,
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Icon(
                          Icons.info_outline,
                          size: 16,
                          color: NytoColors.ctaSoft.withValues(alpha: 0.7),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            "Table mates unlock closer to dinner. You'll be notified.",
                            style: GoogleFonts.dmSans(
                              fontSize: 13,
                              height: 1.4,
                              color: NytoColors.cream.withValues(alpha: 0.55),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (_status != 'CANCELLED') ...[
                    const SizedBox(height: 28),
                    SizedBox(
                      width: double.infinity,
                      height: 54,
                      child: ElevatedButton.icon(
                        onPressed: _openChat,
                        icon: const Icon(
                          Icons.chat_bubble_outline_rounded,
                          size: 20,
                        ),
                        label: const Text('Open table chat'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: NytoColors.cta,
                          foregroundColor: NytoColors.cream,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                          textStyle: GoogleFonts.dmSans(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                  ],
                  if (_canCancel) ...[
                    const SizedBox(height: 12),
                    TextButton(
                      onPressed: _cancelling ? null : _cancel,
                      child: Text(
                        _cancelling ? 'Cancelling…' : 'Cancel booking',
                        style: GoogleFonts.dmSans(
                          fontSize: 14,
                          color: NytoColors.cream.withValues(alpha: 0.45),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
