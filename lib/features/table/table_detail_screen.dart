import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:nyto_app/core/api/nyto_api.dart';
import 'package:nyto_app/core/theme/app_theme.dart';
import 'package:nyto_app/core/widgets/nyto_glass.dart';
import 'package:nyto_app/domain/table.dart';
import 'package:nyto_app/features/booking/booking_opens_screen.dart';
import 'package:nyto_app/features/booking/booking_type_screen.dart';
import 'package:nyto_app/features/onboarding/widgets/onboarding_chrome.dart';

/// Full-screen table detail before booking (boss Home → Detail flow).
class TableDetailScreen extends StatefulWidget {
  const TableDetailScreen({super.key, required this.table});

  final UpcomingTable table;

  @override
  State<TableDetailScreen> createState() => _TableDetailScreenState();
}

class _TableDetailScreenState extends State<TableDetailScreen> {
  late UpcomingTable _table;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _table = widget.table;
    _refresh();
  }

  Future<void> _refresh() async {
    try {
      final res = await tablesApi
          .getById(widget.table.id)
          .timeout(const Duration(seconds: 8));
      final raw = res['table'];
      if (raw is Map<String, dynamic> && mounted) {
        setState(() {
          _table = UpcomingTable.fromJson(raw);
          _loading = false;
        });
        return;
      }
    } catch (_) {}
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _book() async {
    if (!_table.bookable) {
      await Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => BookingOpensScreen(table: _table),
        ),
      );
      return;
    }
    await Navigator.of(context).push(
      onboardingRoute(BookingTypeScreen(table: _table)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = _table;
    return Scaffold(
      backgroundColor: NytoColors.brandInk,
      body: Stack(
        children: [
          const NytoAmbientField(intense: true),
          SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(8, 4, 20, 0),
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
                        'Table detail',
                        style: GoogleFonts.dmSans(
                          fontSize: 14,
                          color: NytoColors.cream.withValues(alpha: 0.55),
                        ),
                      ),
                      const Spacer(),
                      if (_loading)
                        const SizedBox(
                          width: 16,
                          height: 16,
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
                    padding: const EdgeInsets.fromLTRB(22, 8, 22, 24),
                    children: [
                      Text(
                        t.venueName ?? t.area,
                        style: GoogleFonts.fraunces(
                          fontSize: 30,
                          height: 1.15,
                          color: NytoColors.cream,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(
                            Icons.location_on_outlined,
                            size: 16,
                            color: NytoColors.ctaSoft,
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              '${t.area} · ${t.city}',
                              style: GoogleFonts.dmSans(
                                fontSize: 14,
                                color: NytoColors.cream.withValues(alpha: 0.55),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 18),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          _Pill(label: t.tableTypeLabel),
                          _Pill(label: '${t.weekday} · ${t.dateLabel}'),
                          _Pill(label: t.timeLabel),
                          _Pill(label: t.paymentTypeLabel),
                        ],
                      ),
                      const SizedBox(height: 18),
                      NytoGlass.panel(
                        borderRadius: 20,
                        padding: const EdgeInsets.all(18),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '₹${t.priceInr} / seat',
                              style: GoogleFonts.fraunces(
                                fontSize: 28,
                                color: NytoColors.cream,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              t.seatMixLabel,
                              style: GoogleFonts.dmSans(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: NytoColors.ctaSoft,
                              ),
                            ),
                            if (t.vibeCopy != null &&
                                t.vibeCopy!.trim().isNotEmpty) ...[
                              const SizedBox(height: 14),
                              Text(
                                t.vibeCopy!,
                                style: GoogleFonts.dmSans(
                                  fontSize: 14,
                                  height: 1.45,
                                  color:
                                      NytoColors.cream.withValues(alpha: 0.7),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(height: 14),
                      NytoGlass.panel(
                        borderRadius: 20,
                        padding: const EdgeInsets.all(18),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "What's included",
                              style: GoogleFonts.dmSans(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.6,
                                color: NytoColors.cream.withValues(alpha: 0.45),
                              ),
                            ),
                            const SizedBox(height: 10),
                            if (t.inclusions.isEmpty)
                              Text(
                                t.paymentType == TablePaymentType.allInclusive
                                    ? 'All-inclusive experience — details from the venue.'
                                    : 'Pay your own bill at the venue.',
                                style: GoogleFonts.dmSans(
                                  fontSize: 14,
                                  height: 1.4,
                                  color:
                                      NytoColors.cream.withValues(alpha: 0.7),
                                ),
                              )
                            else
                              for (final item in t.inclusions)
                                Padding(
                                  padding: const EdgeInsets.only(bottom: 8),
                                  child: Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Icon(
                                        Icons.check_circle_outline,
                                        size: 16,
                                        color: NytoColors.ctaSoft,
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          item,
                                          style: GoogleFonts.dmSans(
                                            fontSize: 14,
                                            height: 1.35,
                                            color: NytoColors.cream
                                                .withValues(alpha: 0.8),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 14),
                      NytoGlass.panel(
                        borderRadius: 20,
                        padding: const EdgeInsets.all(18),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Matching',
                              style: GoogleFonts.dmSans(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.6,
                                color: NytoColors.cream.withValues(alpha: 0.45),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              t.matchingLine ??
                                  'Matched by age, interests, and personality.',
                              style: GoogleFonts.dmSans(
                                fontSize: 14,
                                height: 1.4,
                                color: NytoColors.cream.withValues(alpha: 0.75),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(22, 8, 22, 20),
                  child: SizedBox(
                    width: double.infinity,
                    height: 54,
                    child: FilledButton(
                      onPressed: _book,
                      style: FilledButton.styleFrom(
                        backgroundColor: NytoColors.cta,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(28),
                        ),
                      ),
                      child: Text(
                        t.bookable ? 'Book this table' : 'Opens soon',
                        style: GoogleFonts.dmSans(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
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

class _Pill extends StatelessWidget {
  const _Pill({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        color: NytoColors.cta.withValues(alpha: 0.14),
        border: Border.all(color: NytoColors.ctaSoft.withValues(alpha: 0.35)),
      ),
      child: Text(
        label,
        style: GoogleFonts.dmSans(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: NytoColors.ctaSoft,
        ),
      ),
    );
  }
}
