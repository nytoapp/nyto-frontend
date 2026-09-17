import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:nyto_app/core/api/nyto_api.dart';
import 'package:nyto_app/core/theme/app_theme.dart';
import 'package:nyto_app/core/widgets/nyto_glass.dart';
import 'package:nyto_app/domain/table.dart';
import 'package:nyto_app/features/booking/booking_opens_screen.dart';
import 'package:nyto_app/features/booking/booking_type_screen.dart';
import 'package:nyto_app/features/onboarding/widgets/onboarding_chrome.dart';
import 'package:nyto_app/features/table/table_menu_gallery.dart';

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
    final bottomInset = MediaQuery.paddingOf(context).bottom;
    // Fade + padding + button + safe area — keeps last cards readable.
    final ctaReserve = 28.0 + 56.0 + 16.0 + bottomInset;

    return Scaffold(
      backgroundColor: NytoColors.brandInk,
      resizeToAvoidBottomInset: true,
      body: Stack(
        children: [
          const NytoAmbientField(intense: true),
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SafeArea(
                bottom: false,
                child: Padding(
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
              ),
              Expanded(
                child: ListView(
                  padding: EdgeInsets.fromLTRB(22, 8, 22, ctaReserve),
                  children: [
                    TableMenuGallery(
                      tableId: t.id,
                      inclusions: t.inclusions,
                    ),
                    const SizedBox(height: 18),
                    Text(
                      t.venueName ?? t.area,
                      style: GoogleFonts.dmSerifDisplay(
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
                            style: GoogleFonts.dmSerifDisplay(
                              fontSize: 28,
                              color: NytoColors.cream,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            t.paymentType == TablePaymentType.payOwnBill
                                ? 'Connection fee · Food paid at the venue'
                                : 'Includes food, drinks & the table',
                            style: GoogleFonts.dmSans(
                              fontSize: 13,
                              height: 1.35,
                              color: NytoColors.cream.withValues(alpha: 0.55),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            t.seatMixLabel,
                            style: GoogleFonts.dmSans(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: NytoColors.ctaSoft,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (t.vibeCopy != null &&
                        t.vibeCopy!.trim().isNotEmpty) ...[
                      const SizedBox(height: 14),
                      Text(
                        t.vibeCopy!,
                        style: GoogleFonts.dmSans(
                          fontSize: 15,
                          height: 1.45,
                          color: NytoColors.cream.withValues(alpha: 0.72),
                        ),
                      ),
                    ],
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
                                  : 'Connection fee with a complimentary drink. Food paid at the venue.',
                              style: GoogleFonts.dmSans(
                                fontSize: 14,
                                height: 1.4,
                                color: NytoColors.cream.withValues(alpha: 0.7),
                              ),
                            )
                          else
                            for (final item in t.inclusions)
                              Padding(
                                padding: const EdgeInsets.only(bottom: 8),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
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
                          if (t.paymentType == TablePaymentType.payOwnBill) ...[
                            const SizedBox(height: 6),
                            Text(
                              'You order food at the venue. NYTO covers the seat, matching, and a complimentary drink or snack.',
                              style: GoogleFonts.dmSans(
                                fontSize: 13,
                                height: 1.4,
                                color: NytoColors.cream.withValues(alpha: 0.5),
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
            ],
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: _BookCtaBar(
              label: t.bookable ? 'Book this table' : 'Opens soon',
              onPressed: _book,
              bottomInset: bottomInset,
            ),
          ),
        ],
      ),
    );
  }
}

/// Sticky CTA that dissolves into the ambient field — no solid black slab.
class _BookCtaBar extends StatelessWidget {
  const _BookCtaBar({
    required this.label,
    required this.onPressed,
    required this.bottomInset,
  });

  final String label;
  final VoidCallback onPressed;
  final double bottomInset;

  @override
  Widget build(BuildContext context) {
    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 22, sigmaY: 22),
        child: DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                NytoColors.brandInk.withValues(alpha: 0.0),
                NytoColors.brandInk.withValues(alpha: 0.42),
                NytoColors.brandInk.withValues(alpha: 0.78),
                NytoColors.brandInk.withValues(alpha: 0.88),
              ],
              stops: const [0.0, 0.28, 0.65, 1.0],
            ),
          ),
          child: Padding(
            padding: EdgeInsets.fromLTRB(22, 28, 22, 14 + bottomInset),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: onPressed,
                borderRadius: BorderRadius.circular(28),
                splashColor: Colors.white24,
                highlightColor: Colors.white10,
                child: Ink(
                  height: 56,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(28),
                    gradient: const LinearGradient(
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                      colors: [
                        NytoColors.ctaSoft,
                        NytoColors.cta,
                        NytoColors.ctaDeep,
                      ],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: NytoColors.cta.withValues(alpha: 0.28),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      ),
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.25),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Center(
                    child: Text(
                      label,
                      style: GoogleFonts.dmSans(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                        letterSpacing: 0.2,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
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
