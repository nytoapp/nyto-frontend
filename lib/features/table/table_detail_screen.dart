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
  bool _booking = false;

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
    if (_booking) return;
    setState(() => _booking = true);
    try {
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
    } finally {
      if (mounted) setState(() => _booking = false);
    }
  }

  /// Meal / offer chip — prefer inclusion copy over generic payment label.
  String _offerChip(UpcomingTable t) {
    for (final item in t.inclusions) {
      final lower = item.toLowerCase();
      if (lower.contains('course') || lower.contains('dinner')) {
        return item;
      }
    }
    if (t.paymentType == TablePaymentType.allInclusive) {
      return '3-course dinner';
    }
    return t.paymentTypeLabel;
  }

  /// Customer-facing inclusions only — drop ops jargon, keep it short.
  List<String> _customerInclusions(UpcomingTable t) {
    final filtered = <String>[];
    for (final raw in t.inclusions) {
      final item = raw.trim();
      if (item.isEmpty) continue;
      final lower = item.toLowerCase();
      if (lower.contains('host facilitation') ||
          lower.contains('facilitation') ||
          lower == 'host') {
        continue;
      }
      filtered.add(item);
      if (filtered.length >= 2) break;
    }
    return filtered;
  }

  @override
  Widget build(BuildContext context) {
    final t = _table;
    final inclusions = _customerInclusions(t);
    final bottomInset = MediaQuery.paddingOf(context).bottom;
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
                    // ── Hero media (unboxed) ─────────────────────────────
                    TableMenuGallery(
                      tableId: t.id,
                      inclusions: t.inclusions,
                    ),

                    // ── Identity ─────────────────────────────────────────
                    const SizedBox(height: 24),
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
                          color: NytoColors.ctaSoft.withValues(alpha: 0.9),
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

                    // ── When / what (date → time → cadence → experience)
                    const SizedBox(height: 16),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _MetaChip(label: '${t.weekday} · ${t.dateLabel}'),
                        _MetaChip(label: t.timeLabel),
                        _MetaChip(label: t.tableTypeLabel),
                        _MetaChip(label: _offerChip(t)),
                      ],
                    ),

                    // ── Price (only LEVEL-2 transactional surface) ───────
                    const SizedBox(height: 24),
                    _PriceSurface(
                      priceLabel: '₹${t.priceInr} / seat',
                      support: t.paymentType == TablePaymentType.payOwnBill
                          ? 'Connection fee · Food paid at the venue'
                          : 'Includes food, drinks & the table',
                      availability: t.seatMixLabel,
                    ),

                    // ── Editorial vibe ───────────────────────────────────
                    if (t.vibeCopy != null &&
                        t.vibeCopy!.trim().isNotEmpty) ...[
                      const SizedBox(height: 28),
                      Text(
                        t.vibeCopy!,
                        style: GoogleFonts.dmSans(
                          fontSize: 16,
                          height: 1.5,
                          fontWeight: FontWeight.w400,
                          color: NytoColors.cream.withValues(alpha: 0.78),
                        ),
                      ),
                    ],

                    // ── What's included (LEVEL 0 — typography only) ──────
                    if (inclusions.isNotEmpty) ...[
                      const SizedBox(height: 28),
                      _SectionRule(),
                      const SizedBox(height: 20),
                      Text(
                        "WHAT'S INCLUDED",
                        style: GoogleFonts.dmSans(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 1.2,
                          color: NytoColors.cream.withValues(alpha: 0.4),
                        ),
                      ),
                      const SizedBox(height: 14),
                      for (final item in inclusions)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Padding(
                                padding: const EdgeInsets.only(top: 1),
                                child: Icon(
                                  Icons.check_rounded,
                                  size: 16,
                                  color: NytoColors.ctaSoft
                                      .withValues(alpha: 0.85),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  item,
                                  style: GoogleFonts.dmSans(
                                    fontSize: 14,
                                    height: 1.4,
                                    color: NytoColors.cream
                                        .withValues(alpha: 0.78),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],

                    // ── Matching (quiet differentiator) ──────────────────
                    const SizedBox(height: 28),
                    _SectionRule(),
                    const SizedBox(height: 20),
                    const _MatchingBlock(),
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
              onPressed: _booking ? null : _book,
              bottomInset: bottomInset,
            ),
          ),
        ],
      ),
    );
  }
}

/// Soft transactional surface — price only. No glass on supporting sections.
class _PriceSurface extends StatelessWidget {
  const _PriceSurface({
    required this.priceLabel,
    required this.support,
    required this.availability,
  });

  final String priceLabel;
  final String support;
  final String availability;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        color: Colors.white.withValues(alpha: 0.055),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.1),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              priceLabel,
              style: GoogleFonts.dmSerifDisplay(
                fontSize: 28,
                height: 1.1,
                color: NytoColors.cream,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              support,
              style: GoogleFonts.dmSans(
                fontSize: 13,
                height: 1.4,
                color: NytoColors.cream.withValues(alpha: 0.52),
              ),
            ),
            const SizedBox(height: 10),
            Text(
              availability,
              style: GoogleFonts.dmSans(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: NytoColors.ctaSoft,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionRule extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      height: 1,
      color: Colors.white.withValues(alpha: 0.08),
    );
  }
}

class _MatchingBlock extends StatelessWidget {
  const _MatchingBlock();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'MATCHED BY',
          style: GoogleFonts.dmSans(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            letterSpacing: 1.2,
            color: NytoColors.cream.withValues(alpha: 0.4),
          ),
        ),
        const SizedBox(height: 10),
        Text(
          'Age · interests · personality',
          style: GoogleFonts.dmSans(
            fontSize: 15,
            height: 1.4,
            color: NytoColors.cream.withValues(alpha: 0.72),
          ),
        ),
      ],
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
  final VoidCallback? onPressed;
  final double bottomInset;

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null;

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
                    gradient: LinearGradient(
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                      colors: enabled
                          ? const [
                              NytoColors.ctaSoft,
                              NytoColors.cta,
                              NytoColors.ctaDeep,
                            ]
                          : [
                              NytoColors.cta.withValues(alpha: 0.45),
                              NytoColors.ctaDeep.withValues(alpha: 0.45),
                            ],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: NytoColors.cta.withValues(
                          alpha: enabled ? 0.28 : 0.12,
                        ),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Center(
                    child: Text(
                      label,
                      style: GoogleFonts.dmSans(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: Colors.white.withValues(
                          alpha: enabled ? 1 : 0.7,
                        ),
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

class _MetaChip extends StatelessWidget {
  const _MetaChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        color: NytoColors.cta.withValues(alpha: 0.1),
        border: Border.all(
          color: NytoColors.ctaSoft.withValues(alpha: 0.28),
        ),
      ),
      child: Text(
        label,
        style: GoogleFonts.dmSans(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: NytoColors.ctaSoft.withValues(alpha: 0.92),
        ),
      ),
    );
  }
}
