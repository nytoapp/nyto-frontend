import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:nyto_app/core/api/api_client.dart';
import 'package:nyto_app/core/api/nyto_api.dart';
import 'package:nyto_app/core/theme/app_theme.dart';
import 'package:nyto_app/features/booking/booking_type_screen.dart';
import 'package:nyto_app/features/profile/profile_screen.dart';

enum TableFilter { thisWeek, daytime, evening, womenOnly }

enum MealSlot { daytimeLunch, eveningDinner }

class UpcomingTable {
  const UpcomingTable({
    required this.id,
    required this.weekday,
    required this.dateLabel,
    required this.timeLabel,
    required this.priceInr,
    required this.slot,
    required this.area,
    required this.seatsTaken,
    this.womenOnly = false,
    this.capacity = 6,
  });

  final String id;
  final String weekday;
  final String dateLabel;
  final String timeLabel;
  final int priceInr;
  final MealSlot slot;
  final String area;
  final int seatsTaken;
  final bool womenOnly;
  final int capacity;

  int get seatsLeft => capacity - seatsTaken;

  String get slotLabel => switch (slot) {
        MealSlot.daytimeLunch => 'Daytime Lunch',
        MealSlot.eveningDinner => 'Evening Dinner',
      };

  String get priceLabel {
    final raw = priceInr.toString();
    if (raw.length <= 3) return '₹$raw';
    final head = raw.substring(0, raw.length - 3);
    final tail = raw.substring(raw.length - 3);
    return '₹$head,$tail';
  }

  factory UpcomingTable.fromJson(Map<String, dynamic> json) {
    final slotRaw = json['slot'] as String? ?? 'EVENING_DINNER';
    return UpcomingTable(
      id: json['id'] as String,
      weekday: json['weekday'] as String? ?? '',
      dateLabel: json['dateLabel'] as String? ?? '',
      timeLabel: json['timeLabel'] as String? ?? '',
      priceInr: json['seatPrice'] as int? ?? 0,
      slot: slotRaw.contains('DAYTIME')
          ? MealSlot.daytimeLunch
          : MealSlot.eveningDinner,
      area: json['area'] as String? ?? '',
      seatsTaken: json['seatsTaken'] as int? ?? 0,
      womenOnly: json['womenOnly'] as bool? ?? false,
      capacity: json['capacity'] as int? ?? 6,
    );
  }
}

/// Home — visual match to `designs/Screenshot (3710–3715)`.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  TableFilter _filter = TableFilter.thisWeek;
  List<UpcomingTable> _tables = const [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  String get _apiFilter => switch (_filter) {
        TableFilter.thisWeek => 'this_week',
        TableFilter.daytime => 'daytime',
        TableFilter.evening => 'evening',
        TableFilter.womenOnly => 'women_only',
      };

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final rows = await tablesApi.list(filter: _apiFilter);
      if (!mounted) return;
      setState(() {
        _tables = rows.map(UpcomingTable.fromJson).toList();
        _loading = false;
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.message;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _error = 'Could not load tables. Is the backend running?';
        _loading = false;
      });
    }
  }

  Future<void> _setFilter(TableFilter filter) async {
    setState(() => _filter = filter);
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    final tables = _tables;

    return Scaffold(
      backgroundColor: NytoColors.bg,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
              child: Row(
                children: [
                  Text(
                    'NYTO',
                    style: GoogleFonts.fraunces(
                      fontSize: 22,
                      fontWeight: FontWeight.w600,
                      color: NytoColors.orange,
                      letterSpacing: 4,
                    ),
                  ),
                  const Spacer(),
                  GestureDetector(
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => const ProfileScreen(),
                        ),
                      );
                    },
                    child: Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: NytoColors.surface,
                        border: Border.all(
                          color: NytoColors.cream.withValues(alpha: 0.18),
                        ),
                      ),
                      child: Icon(
                        Icons.person_outline,
                        size: 20,
                        color: NytoColors.cream.withValues(alpha: 0.75),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 28, 24, 0),
              child: Text(
                'Upcoming tables',
                style: GoogleFonts.fraunces(
                  fontSize: 30,
                  fontWeight: FontWeight.w400,
                  color: NytoColors.cream,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 0),
              child: Text(
                'Pick a night and price tier. We handle the rest.',
                style: GoogleFonts.dmSans(
                  fontSize: 14,
                  color: NytoColors.creamMuted,
                  height: 1.45,
                ),
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              height: 40,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 24),
                children: [
                  _FilterChip(
                    label: 'This week',
                    selected: _filter == TableFilter.thisWeek,
                    onTap: () => _setFilter(TableFilter.thisWeek),
                  ),
                  const SizedBox(width: 8),
                  _FilterChip(
                    label: 'Daytime',
                    selected: _filter == TableFilter.daytime,
                    onTap: () => _setFilter(TableFilter.daytime),
                  ),
                  const SizedBox(width: 8),
                  _FilterChip(
                    label: 'Evening',
                    selected: _filter == TableFilter.evening,
                    onTap: () => _setFilter(TableFilter.evening),
                  ),
                  const SizedBox(width: 8),
                  _FilterChip(
                    label: 'Women-only',
                    selected: _filter == TableFilter.womenOnly,
                    onTap: () => _setFilter(TableFilter.womenOnly),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: _loading
                  ? const Center(
                      child: CircularProgressIndicator(
                        color: NytoColors.orange,
                      ),
                    )
                  : _error != null
                      ? Center(
                          child: Padding(
                            padding: const EdgeInsets.all(24),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  _error!,
                                  textAlign: TextAlign.center,
                                  style: GoogleFonts.dmSans(
                                    fontSize: 14,
                                    color: NytoColors.creamMuted,
                                  ),
                                ),
                                const SizedBox(height: 16),
                                TextButton(
                                  onPressed: _load,
                                  child: const Text('Retry'),
                                ),
                              ],
                            ),
                          ),
                        )
                      : tables.isEmpty
                          ? Center(
                              child: Text(
                                'No tables match this filter.',
                                style: GoogleFonts.dmSans(
                                  fontSize: 14,
                                  color: NytoColors.creamMuted,
                                ),
                              ),
                            )
                          : ListView.separated(
                              padding:
                                  const EdgeInsets.fromLTRB(24, 16, 24, 28),
                              itemCount: tables.length,
                              separatorBuilder: (_, __) =>
                                  const SizedBox(height: 12),
                              itemBuilder: (context, index) {
                                return _TableCard(
                                  table: tables[index],
                                  onTap: () {
                                    Navigator.of(context).push(
                                      MaterialPageRoute<void>(
                                        builder: (_) => BookingTypeScreen(
                                          table: tables[index],
                                        ),
                                      ),
                                    );
                                  },
                                );
                              },
                            ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(22),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: selected ? NytoColors.orange : NytoColors.surface,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(
              color: selected
                  ? NytoColors.orange
                  : NytoColors.cream.withValues(alpha: 0.14),
            ),
          ),
          child: Text(
            label,
            style: GoogleFonts.dmSans(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: selected
                  ? NytoColors.cream
                  : NytoColors.cream.withValues(alpha: 0.75),
            ),
          ),
        ),
      ),
    );
  }
}

class _TableCard extends StatelessWidget {
  const _TableCard({required this.table, required this.onTap});

  final UpcomingTable table;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final urgent = table.seatsLeft == 1;
    final seatsLabel =
        '${table.seatsLeft} seat${table.seatsLeft == 1 ? '' : 's'} left';

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Ink(
          decoration: BoxDecoration(
            color: NytoColors.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: NytoColors.cream.withValues(alpha: 0.08),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                height: 2,
                decoration: BoxDecoration(
                  color: NytoColors.orange.withValues(alpha: 0.55),
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(16),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text.rich(
                                TextSpan(
                                  children: [
                                    TextSpan(
                                      text: '${table.weekday} ',
                                      style: GoogleFonts.fraunces(
                                        fontSize: 22,
                                        fontWeight: FontWeight.w500,
                                        color: NytoColors.cream,
                                      ),
                                    ),
                                    TextSpan(
                                      text: table.dateLabel,
                                      style: GoogleFonts.fraunces(
                                        fontSize: 22,
                                        fontWeight: FontWeight.w400,
                                        fontStyle: FontStyle.italic,
                                        color: NytoColors.cream,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                table.timeLabel,
                                style: GoogleFonts.jetBrainsMono(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w400,
                                  color: NytoColors.creamMuted,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              table.priceLabel,
                              style: GoogleFonts.jetBrainsMono(
                                fontSize: 20,
                                fontWeight: FontWeight.w600,
                                color: NytoColors.orange,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'per seat',
                              style: GoogleFonts.dmSans(
                                fontSize: 11,
                                color: NytoColors.creamMuted,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _MetaPill(label: table.slotLabel),
                        if (table.womenOnly)
                          const _MetaPill(
                            label: 'Women-only',
                            tone: _PillTone.moss,
                          ),
                        _MetaPill(label: table.area),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: _SeatFillBar(taken: table.seatsTaken),
                        ),
                        const SizedBox(width: 12),
                        Icon(
                          Icons.person_outline,
                          size: 14,
                          color: urgent
                              ? NytoColors.orange
                              : NytoColors.creamMuted,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          seatsLabel,
                          style: GoogleFonts.dmSans(
                            fontSize: 12,
                            fontWeight:
                                urgent ? FontWeight.w600 : FontWeight.w400,
                            color: urgent
                                ? NytoColors.orange
                                : NytoColors.creamMuted,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

enum _PillTone { neutral, moss }

class _MetaPill extends StatelessWidget {
  const _MetaPill({required this.label, this.tone = _PillTone.neutral});

  final String label;
  final _PillTone tone;

  @override
  Widget build(BuildContext context) {
    final isMoss = tone == _PillTone.moss;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: isMoss
            ? NytoColors.moss.withValues(alpha: 0.35)
            : NytoColors.cream.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isMoss
              ? NytoColors.moss.withValues(alpha: 0.55)
              : NytoColors.cream.withValues(alpha: 0.08),
        ),
      ),
      child: Text(
        label,
        style: GoogleFonts.dmSans(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: isMoss
              ? const Color(0xFFC8D9CE)
              : NytoColors.cream.withValues(alpha: 0.85),
        ),
      ),
    );
  }
}

class _SeatFillBar extends StatelessWidget {
  const _SeatFillBar({required this.taken});

  final int taken;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(6, (index) {
        final filled = index < taken;
        return Expanded(
          child: Container(
            margin: EdgeInsets.only(right: index == 5 ? 0 : 4),
            height: 5,
            decoration: BoxDecoration(
              color: filled
                  ? NytoColors.orange
                  : NytoColors.cream.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        );
      }),
    );
  }
}
