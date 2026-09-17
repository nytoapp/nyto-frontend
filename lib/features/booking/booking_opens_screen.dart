import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:nyto_app/core/theme/app_theme.dart';
import 'package:nyto_app/core/widgets/nyto_glass.dart';
import 'package:nyto_app/domain/table.dart';

/// Shown when a guest taps a table before [UpcomingTable.bookingOpensAt].
class BookingOpensScreen extends StatefulWidget {
  const BookingOpensScreen({super.key, required this.table});

  final UpcomingTable table;

  @override
  State<BookingOpensScreen> createState() => _BookingOpensScreenState();
}

class _BookingOpensScreenState extends State<BookingOpensScreen> {
  Timer? _timer;
  Duration _left = Duration.zero;

  @override
  void initState() {
    super.initState();
    _tick();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) => _tick());
  }

  void _tick() {
    final opens = widget.table.bookingOpensAt;
    if (opens == null) {
      setState(() => _left = Duration.zero);
      return;
    }
    final diff = opens.difference(DateTime.now());
    setState(() => _left = diff.isNegative ? Duration.zero : diff);
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  String get _opensLabel {
    final opens = widget.table.bookingOpensAt;
    if (opens == null) return 'Soon';
    final local = opens.toLocal();
    final weekday = MaterialLocalizations.of(context).formatMediumDate(local);
    final time = TimeOfDay.fromDateTime(local).format(context);
    return '$weekday · $time';
  }

  String get _countdown {
    final d = _left.inDays;
    final h = _left.inHours % 24;
    final m = _left.inMinutes % 60;
    final s = _left.inSeconds % 60;
    if (d > 0) return '${d}d ${h}h ${m}m';
    if (h > 0) return '${h}h ${m}m ${s}s';
    return '${m}m ${s}s';
  }

  @override
  Widget build(BuildContext context) {
    final t = widget.table;
    return Scaffold(
      backgroundColor: NytoColors.bg,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: NytoColors.cream),
      ),
      body: Padding(
        padding: const EdgeInsets.fromLTRB(24, 8, 24, 28),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'BOOKING OPENS SOON',
              style: GoogleFonts.dmSans(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.4,
                color: NytoColors.cta,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'This table isn’t bookable yet.',
              style: GoogleFonts.dmSerifDisplay(
                fontSize: 28,
                height: 1.15,
                color: NytoColors.cream,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'You can look — booking unlocks on a schedule so everyone gets a fair shot.',
              style: GoogleFonts.dmSans(
                fontSize: 14,
                height: 1.4,
                color: NytoColors.cream.withValues(alpha: 0.5),
              ),
            ),
            const SizedBox(height: 24),
            NytoGlass.panel(
              borderRadius: 18,
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    t.area,
                    style: GoogleFonts.dmSerifDisplay(
                      fontSize: 22,
                      color: NytoColors.cream,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '${t.fullDateLabel} · ${t.timeLabel}',
                    style: GoogleFonts.dmSans(
                      fontSize: 14,
                      color: NytoColors.cream.withValues(alpha: 0.6),
                    ),
                  ),
                  const SizedBox(height: 18),
                  Text(
                    'Opens',
                    style: GoogleFonts.dmSans(
                      fontSize: 12,
                      color: NytoColors.cream.withValues(alpha: 0.45),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _opensLabel,
                    style: GoogleFonts.dmSans(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: NytoColors.ctaSoft,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Countdown',
                    style: GoogleFonts.dmSans(
                      fontSize: 12,
                      color: NytoColors.cream.withValues(alpha: 0.45),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _countdown,
                    style: GoogleFonts.jetBrainsMono(
                      fontSize: 28,
                      fontWeight: FontWeight.w700,
                      color: NytoColors.cream,
                    ),
                  ),
                ],
              ),
            ),
            const Spacer(),
            SizedBox(
              height: 52,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: NytoColors.cta,
                  foregroundColor: NytoColors.cream,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: Text(
                  'Back to Home',
                  style: GoogleFonts.dmSans(
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
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
