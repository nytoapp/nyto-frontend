import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:nyto_app/core/theme/app_theme.dart';
import 'package:nyto_app/core/widgets/nyto_glass.dart';

/// Client-side filter state mapped to `/tables` query params.
class HomeTableFilters {
  const HomeTableFilters({
    this.tableType,
    this.priceMin,
    this.priceMax,
    this.day,
    this.paymentType,
    this.tableTypeLabel = 'Table type',
    this.priceLabel = 'Price',
    this.dayLabel = 'Day',
    this.paymentLabel = 'Payment',
  });

  final String? tableType;
  final int? priceMin;
  final int? priceMax;
  final String? day;
  final String? paymentType;
  final String tableTypeLabel;
  final String priceLabel;
  final String dayLabel;
  final String paymentLabel;

  bool get hasActiveFilters =>
      tableType != null ||
      priceMin != null ||
      priceMax != null ||
      day != null ||
      paymentType != null;

  HomeTableFilters copyWith({
    String? tableType,
    bool clearTableType = false,
    int? priceMin,
    bool clearPriceMin = false,
    int? priceMax,
    bool clearPriceMax = false,
    String? day,
    bool clearDay = false,
    String? paymentType,
    bool clearPaymentType = false,
    String? tableTypeLabel,
    String? priceLabel,
    String? dayLabel,
    String? paymentLabel,
  }) {
    return HomeTableFilters(
      tableType: clearTableType ? null : (tableType ?? this.tableType),
      priceMin: clearPriceMin ? null : (priceMin ?? this.priceMin),
      priceMax: clearPriceMax ? null : (priceMax ?? this.priceMax),
      day: clearDay ? null : (day ?? this.day),
      paymentType:
          clearPaymentType ? null : (paymentType ?? this.paymentType),
      tableTypeLabel: tableTypeLabel ?? this.tableTypeLabel,
      priceLabel: priceLabel ?? this.priceLabel,
      dayLabel: dayLabel ?? this.dayLabel,
      paymentLabel: paymentLabel ?? this.paymentLabel,
    );
  }
}

class HomeTableFiltersBar extends StatelessWidget {
  const HomeTableFiltersBar({
    super.key,
    required this.filters,
    required this.onChanged,
  });

  final HomeTableFilters filters;
  final ValueChanged<HomeTableFilters> onChanged;

  Future<void> _pickTableType(BuildContext context) async {
    final choice = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: NytoColors.surfaceElevated,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => _FilterSheet(
        title: 'Table type',
        options: const [
          ('All types', 'ALL'),
          ('Weekly', 'WEEKLY'),
          ('Women-Led', 'WOMEN_LED'),
          ('Couples', 'COUPLES'),
          ('Singles', 'SINGLES'),
        ],
        selected: filters.tableType ?? 'ALL',
      ),
    );
    if (choice == null || !context.mounted) return;
    if (choice == 'ALL') {
      onChanged(
        filters.copyWith(
          clearTableType: true,
          tableTypeLabel: 'Table type',
        ),
      );
      return;
    }
    final label = switch (choice) {
      'WOMEN_LED' => 'Women-Led',
      'COUPLES' => 'Couples',
      'SINGLES' => 'Singles',
      _ => 'Weekly',
    };
    onChanged(
      filters.copyWith(tableType: choice, tableTypeLabel: label),
    );
  }

  Future<void> _pickPrice(BuildContext context) async {
    final selectedKey = switch (filters.priceLabel) {
      'Under ₹1,000' => 'under_1000',
      '₹1,000 – ₹1,200' => 'mid',
      'Over ₹1,200' => 'over_1200',
      _ => 'any',
    };
    final choice = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: NytoColors.surfaceElevated,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => _FilterSheet(
        title: 'Price per seat',
        options: const [
          ('Any price', 'any'),
          ('Under ₹1,000', 'under_1000'),
          ('₹1,000 – ₹1,200', 'mid'),
          ('Over ₹1,200', 'over_1200'),
        ],
        selected: selectedKey,
      ),
    );
    if (choice == null || !context.mounted) return;
    switch (choice) {
      case 'under_1000':
        onChanged(
          filters.copyWith(
            priceMin: null,
            clearPriceMin: true,
            priceMax: 999,
            priceLabel: 'Under ₹1,000',
          ),
        );
      case 'mid':
        onChanged(
          filters.copyWith(
            priceMin: 1000,
            priceMax: 1200,
            priceLabel: '₹1,000 – ₹1,200',
          ),
        );
      case 'over_1200':
        onChanged(
          filters.copyWith(
            priceMin: 1201,
            clearPriceMax: true,
            priceMax: null,
            priceLabel: 'Over ₹1,200',
          ),
        );
      default:
        onChanged(
          filters.copyWith(
            clearPriceMin: true,
            clearPriceMax: true,
            priceLabel: 'Any price',
          ),
        );
    }
  }

  Future<void> _pickDay(BuildContext context) async {
    final selectedKey = switch (filters.dayLabel) {
      'Today' => 'today',
      'This weekend' => 'weekend',
      _ => 'any',
    };
    final choice = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: NytoColors.surfaceElevated,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => _FilterSheet(
        title: 'Day',
        options: const [
          ('Any day', 'any'),
          ('Today', 'today'),
          ('This weekend', 'weekend'),
        ],
        selected: selectedKey,
      ),
    );
    if (choice == null || !context.mounted) return;
    if (choice == 'today') {
      final now = DateTime.now();
      final iso =
          '${now.year.toString().padLeft(4, '0')}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
      onChanged(filters.copyWith(day: iso, dayLabel: 'Today'));
      return;
    }
    if (choice == 'weekend') {
      onChanged(filters.copyWith(clearDay: true, dayLabel: 'This weekend'));
      return;
    }
    onChanged(filters.copyWith(clearDay: true, dayLabel: 'Any day'));
  }

  Future<void> _pickPayment(BuildContext context) async {
    final selectedKey = filters.paymentType ?? 'ALL';
    final choice = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: NytoColors.surfaceElevated,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => _FilterSheet(
        title: 'Payment type',
        options: const [
          ('All', 'ALL'),
          ('All-inclusive', 'ALL_INCLUSIVE'),
          ('Pay your own bill', 'PAY_OWN_BILL'),
        ],
        selected: selectedKey,
      ),
    );
    if (choice == null || !context.mounted) return;
    if (choice == 'ALL') {
      onChanged(
        filters.copyWith(
          clearPaymentType: true,
          paymentLabel: 'Payment',
        ),
      );
      return;
    }
    final label = choice == 'PAY_OWN_BILL' ? 'Pay your own' : 'All-inclusive';
    onChanged(
      filters.copyWith(paymentType: choice, paymentLabel: label),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 40,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 18),
        children: [
          _FilterChip(
            label: filters.tableTypeLabel,
            active: filters.tableType != null,
            onTap: () => _pickTableType(context),
          ),
          const SizedBox(width: 8),
          _FilterChip(
            label: filters.priceLabel,
            active: filters.priceMin != null || filters.priceMax != null,
            onTap: () => _pickPrice(context),
          ),
          const SizedBox(width: 8),
          _FilterChip(
            label: filters.dayLabel,
            active: filters.day != null || filters.dayLabel == 'This weekend',
            onTap: () => _pickDay(context),
          ),
          const SizedBox(width: 8),
          _FilterChip(
            label: filters.paymentLabel,
            active: filters.paymentType != null,
            onTap: () => _pickPayment(context),
          ),
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.active,
    required this.onTap,
  });

  final String label;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: NytoGlass.panel(
          borderRadius: 999,
          selected: active,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                style: GoogleFonts.dmSans(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: active ? NytoColors.ctaSoft : NytoColors.cream,
                ),
              ),
              const SizedBox(width: 4),
              Icon(
                Icons.keyboard_arrow_down_rounded,
                size: 16,
                color: NytoColors.cream.withValues(alpha: 0.45),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FilterSheet extends StatelessWidget {
  const _FilterSheet({
    required this.title,
    required this.options,
    required this.selected,
  });

  final String title;
  final List<(String, String)> options;
  final String selected;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: GoogleFonts.fraunces(
                fontSize: 22,
                color: NytoColors.cream,
              ),
            ),
            const SizedBox(height: 12),
            for (final (label, value) in options)
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(
                  label,
                  style: GoogleFonts.dmSans(
                    fontSize: 15,
                    color: NytoColors.cream,
                    fontWeight:
                        selected == value ? FontWeight.w700 : FontWeight.w400,
                  ),
                ),
                trailing: selected == value
                    ? const Icon(Icons.check_rounded, color: NytoColors.cta)
                    : null,
                onTap: () => Navigator.of(context).pop(value),
              ),
          ],
        ),
      ),
    );
  }
}
