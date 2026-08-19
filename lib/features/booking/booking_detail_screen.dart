import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:nyto_app/core/theme/app_theme.dart';
import 'package:nyto_app/core/widgets/nyto_glass.dart';
import 'package:nyto_app/domain/table.dart';
import 'package:nyto_app/features/home/home_screen.dart';
import 'package:nyto_app/features/table/table_chat_screen.dart';

/// Post-payment booking detail — venue + date/time + chat entry.
class BookingDetailScreen extends StatelessWidget {
  const BookingDetailScreen({
    super.key,
    required this.table,
    required this.bookingId,
  });

  final UpcomingTable table;
  final String bookingId;

  static const _dayMap = {
    'Fri': 'Friday',
    'Sat': 'Saturday',
    'Sun': 'Sunday',
    'Wed': 'Wednesday',
    'Thu': 'Thursday',
    'Mon': 'Monday',
    'Tue': 'Tuesday',
  };

  String get _dayLong => _dayMap[table.weekday] ?? table.weekday;
  String get _slot =>
      table.slot == MealSlot.daytimeLunch ? 'Daytime' : 'Evening';

  void _openChat(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => TableChatScreen(
          venueName: table.area,
          dayLabel: _dayLong,
          timeLabel: table.timeLabel,
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
                    'Seat confirmed.',
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
                                table.area,
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
                                  color:
                                      NytoColors.ctaSoft.withValues(alpha: 0.45),
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                    width: 6,
                                    height: 6,
                                    decoration: const BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: NytoColors.ctaSoft,
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    'Confirmed',
                                    style: GoogleFonts.dmSans(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                      color: NytoColors.ctaSoft,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          table.city,
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
                              '$_dayLong, ${table.dateLabel}',
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
                              '${table.timeLabel} · $_slot',
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
                              'Table for ${table.capacity} · Matched strangers',
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
                            "Table details unlock closer to dinner. You'll be notified.",
                            style: GoogleFonts.dmSans(
                              fontSize: 13,
                              height: 1.4,
                              color:
                                  NytoColors.cream.withValues(alpha: 0.55),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 28),
                  SizedBox(
                    width: double.infinity,
                    height: 54,
                    child: ElevatedButton.icon(
                      onPressed: () => _openChat(context),
                      icon: const Icon(Icons.chat_bubble_outline_rounded,
                          size: 20),
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
              ),
            ),
          ],
        ),
      ),
    );
  }
}
