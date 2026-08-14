import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:nyto_app/core/api/api_client.dart';
import 'package:nyto_app/core/api/nyto_api.dart';
import 'package:nyto_app/core/theme/app_theme.dart';
import 'package:nyto_app/core/widgets/nyto_glass.dart';
import 'package:nyto_app/features/booking/booking_type_screen.dart';
import 'package:nyto_app/features/onboarding/widgets/onboarding_chrome.dart';
import 'package:nyto_app/features/profile/profile_screen.dart';

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
    this.section = 'This week',
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
  final String section;

  int get seatsLeft => capacity - seatsTaken;

  String get mealLabel => switch (slot) {
        MealSlot.daytimeLunch => 'Lunch',
        MealSlot.eveningDinner => 'Dinner',
      };

  String get fullDateLabel => '$weekday, $dateLabel';

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
      section: json['section'] as String? ?? 'This week',
    );
  }
}

/// Post-onboarding home — All tables layout (NYTO brand, Hyderabad).
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _tab = 0;
  List<UpcomingTable> _tables = const [];
  bool _loading = true;

  static const _demoTables = <UpcomingTable>[
    UpcomingTable(
      id: 'demo-1',
      weekday: 'Friday',
      dateLabel: 'August 14',
      timeLabel: '8:00 PM',
      priceInr: 1499,
      slot: MealSlot.eveningDinner,
      area: 'Jubilee Hills',
      seatsTaken: 3,
      section: 'This week',
    ),
    UpcomingTable(
      id: 'demo-2',
      weekday: 'Saturday',
      dateLabel: 'August 15',
      timeLabel: '1:00 PM',
      priceInr: 1299,
      slot: MealSlot.daytimeLunch,
      area: 'Banjara Hills',
      seatsTaken: 2,
      section: 'This week',
    ),
    UpcomingTable(
      id: 'demo-3',
      weekday: 'Wednesday',
      dateLabel: 'August 19',
      timeLabel: '8:00 PM',
      priceInr: 1499,
      slot: MealSlot.eveningDinner,
      area: 'Gachibowli',
      seatsTaken: 4,
      womenOnly: true,
      section: 'Next week',
    ),
    UpcomingTable(
      id: 'demo-4',
      weekday: 'Wednesday',
      dateLabel: 'August 26',
      timeLabel: '8:00 PM',
      priceInr: 1499,
      slot: MealSlot.eveningDinner,
      area: 'Madhapur',
      seatsTaken: 1,
      section: 'In 2 weeks',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    // Show demo instantly so Home never hangs when API is unreachable.
    setState(() {
      _tables = _demoTables;
      _loading = false;
    });

    try {
      final rows = await tablesApi
          .list(filter: 'this_week')
          .timeout(const Duration(seconds: 2));
      if (!mounted) return;
      final parsed = rows.map(UpcomingTable.fromJson).toList();
      if (parsed.isEmpty) return;
      setState(() => _tables = parsed);
    } on ApiException catch (_) {
      // Keep demo tables.
    } catch (_) {
      // Timeout / network — keep demo tables.
    }
  }

  Map<String, List<UpcomingTable>> get _grouped {
    final map = <String, List<UpcomingTable>>{};
    for (final t in _tables) {
      map.putIfAbsent(t.section, () => []).add(t);
    }
    // Stable order
    const order = ['This week', 'Next week', 'In 2 weeks'];
    final sorted = <String, List<UpcomingTable>>{};
    for (final key in order) {
      if (map.containsKey(key)) sorted[key] = map[key]!;
    }
    for (final e in map.entries) {
      if (!sorted.containsKey(e.key)) sorted[e.key] = e.value;
    }
    return sorted;
  }

  void _openTable(UpcomingTable table) {
    Navigator.of(context).push(
      onboardingRoute(BookingTypeScreen(table: table)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        systemNavigationBarColor: NytoColors.brandInk,
        systemNavigationBarIconBrightness: Brightness.light,
      ),
      child: Scaffold(
        backgroundColor: NytoColors.brandInk,
        extendBody: false,
        body: Stack(
          children: [
            const NytoAmbientField(intense: true),
            SafeArea(
              bottom: false,
              child: IndexedStack(
                index: _tab,
                children: [
                  _TablesTab(
                    loading: _loading,
                    tables: _grouped.values.expand((e) => e).toList(),
                    onOpen: _openTable,
                    onBell: () {},
                  ),
                  const _PlaceholderTab(
                    title: 'Chat',
                    body: 'Your table chats unlock after you book a seat.',
                    icon: Icons.chat_bubble_outline_rounded,
                  ),
                  const _PlaceholderTab(
                    title: 'Events',
                    body: 'Past nights and upcoming bookings will live here.',
                    icon: Icons.calendar_today_outlined,
                  ),
                  const ProfileScreen(),
                ],
              ),
            ),
          ],
        ),
        bottomNavigationBar: _NytoBottomNav(
          index: _tab,
          onChanged: (i) => setState(() => _tab = i),
        ),
      ),
    );
  }
}

class _TablesTab extends StatefulWidget {
  const _TablesTab({
    required this.loading,
    required this.tables,
    required this.onOpen,
    required this.onBell,
  });

  final bool loading;
  final List<UpcomingTable> tables;
  final ValueChanged<UpcomingTable> onOpen;
  final VoidCallback onBell;

  @override
  State<_TablesTab> createState() => _TablesTabState();
}

class _TablesTabState extends State<_TablesTab>
    with SingleTickerProviderStateMixin {
  late final AnimationController _enter;
  late final Animation<double> _fade;
  late final Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _enter = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 720),
    );
    _fade = CurvedAnimation(parent: _enter, curve: Curves.easeOutCubic);
    _slide = Tween<Offset>(
      begin: const Offset(0, 0.04),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _enter, curve: Curves.easeOutCubic));
    _enter.forward();
  }

  @override
  void dispose() {
    _enter.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tables = widget.tables;
    final featured = tables.isEmpty ? null : tables.first;
    final rest =
        tables.length > 1 ? tables.sublist(1) : const <UpcomingTable>[];

    return FadeTransition(
      opacity: _fade,
      child: SlideTransition(
        position: _slide,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(22, 8, 12, 0),
              child: Row(
                children: [
                  Text(
                    'Hyderabad',
                    style: GoogleFonts.dmSans(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: NytoColors.cream.withValues(alpha: 0.55),
                    ),
                  ),
                  const SizedBox(width: 4),
                  Icon(
                    Icons.location_on_rounded,
                    size: 14,
                    color: NytoColors.ctaSoft.withValues(alpha: 0.85),
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: widget.onBell,
                    visualDensity: VisualDensity.compact,
                    icon: Icon(
                      Icons.notifications_none_rounded,
                      size: 22,
                      color: NytoColors.cream.withValues(alpha: 0.7),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(22, 4, 22, 0),
              child: Text(
                'What’s alive tonight',
                style: GoogleFonts.fraunces(
                  fontSize: 30,
                  fontWeight: FontWeight.w400,
                  height: 1.1,
                  color: NytoColors.cream,
                ),
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: widget.loading
                  ? const Center(
                      child: CircularProgressIndicator(
                        color: NytoColors.brandPink,
                      ),
                    )
                  : tables.isEmpty
                      ? Center(
                          child: Text(
                            'No tables yet — check back soon.',
                            style: GoogleFonts.dmSans(
                              color: NytoColors.cream.withValues(alpha: 0.5),
                            ),
                          ),
                        )
                      : Padding(
                          padding: const EdgeInsets.fromLTRB(18, 0, 18, 8),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (featured != null)
                                Expanded(
                                  child: _CinematicNightCard(
                                    table: featured,
                                    onTap: () => widget.onOpen(featured),
                                  ),
                                ),
                              if (rest.isNotEmpty) ...[
                                const SizedBox(height: 18),
                                Padding(
                                  padding: const EdgeInsets.only(left: 4),
                                  child: Text(
                                    'More nights',
                                    style: GoogleFonts.dmSans(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      letterSpacing: 0.8,
                                      color: NytoColors.cream
                                          .withValues(alpha: 0.4),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 10),
                                SizedBox(
                                  height: 148,
                                  child: ListView.separated(
                                    scrollDirection: Axis.horizontal,
                                    itemCount: rest.length,
                                    separatorBuilder: (_, __) =>
                                        const SizedBox(width: 10),
                                    itemBuilder: (context, i) {
                                      final t = rest[i];
                                      return _NightRailCard(
                                        table: t,
                                        onTap: () => widget.onOpen(t),
                                      );
                                    },
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Full-bleed cinematic featured night — atmosphere first, chrome second.
class _CinematicNightCard extends StatelessWidget {
  const _CinematicNightCard({required this.table, required this.onTap});

  final UpcomingTable table;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isLunch = table.slot == MealSlot.daytimeLunch;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(28),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(28),
          child: Stack(
            fit: StackFit.expand,
            children: [
              // Atmosphere field
              DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: isLunch
                        ? [
                            const Color(0xFF1A2438),
                            const Color(0xFF0B1220),
                            const Color(0xFF15100C),
                          ]
                        : [
                            const Color(0xFF101B33),
                            const Color(0xFF070B14),
                            const Color(0xFF0C1424),
                          ],
                  ),
                ),
              ),
              Positioned(
                top: -40,
                right: -30,
                child: Container(
                  width: 220,
                  height: 220,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        (isLunch ? NytoColors.orange : NytoColors.cta)
                            .withValues(alpha: 0.38),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ),
              Positioned(
                bottom: -60,
                left: -40,
                child: Container(
                  width: 260,
                  height: 260,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        NytoColors.ctaSoft.withValues(alpha: 0.22),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ),
              // Frost edge
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(28),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.16),
                    ),
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.white.withValues(alpha: 0.10),
                        Colors.transparent,
                        Colors.black.withValues(alpha: 0.35),
                      ],
                      stops: const [0, 0.45, 1],
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(22, 20, 22, 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          isLunch ? 'FEATURED DAY' : 'FEATURED NIGHT',
                          style: GoogleFonts.dmSans(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1.6,
                            color: NytoColors.ctaSoft,
                          ),
                        ),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(999),
                            color: Colors.black.withValues(alpha: 0.35),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.14),
                            ),
                          ),
                          child: Text(
                            '${table.seatsLeft} seats left',
                            style: GoogleFonts.dmSans(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: NytoColors.cream,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const Spacer(),
                    Text(
                      table.weekday,
                      style: GoogleFonts.fraunces(
                        fontSize: 44,
                        height: 0.95,
                        fontWeight: FontWeight.w400,
                        color: NytoColors.cream,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      table.dateLabel,
                      style: GoogleFonts.dmSans(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: NytoColors.cream.withValues(alpha: 0.7),
                      ),
                    ),
                    const SizedBox(height: 14),
                    Text(
                      '${table.mealLabel}  ·  ${table.timeLabel}',
                      style: GoogleFonts.dmSans(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: NytoColors.cream.withValues(alpha: 0.88),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '${table.area} · Hyderabad',
                      style: GoogleFonts.dmSans(
                        fontSize: 13,
                        color: NytoColors.cream.withValues(alpha: 0.45),
                      ),
                    ),
                    if (table.womenOnly) ...[
                      const SizedBox(height: 8),
                      Text(
                        'Women-only table',
                        style: GoogleFonts.dmSans(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: NytoColors.ctaSoft,
                        ),
                      ),
                    ],
                    const Spacer(),
                    Row(
                      children: [
                        Text(
                          '₹${table.priceInr}',
                          style: GoogleFonts.fraunces(
                            fontSize: 26,
                            color: NytoColors.cream,
                          ),
                        ),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 18,
                            vertical: 13,
                          ),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(999),
                            gradient: const LinearGradient(
                              colors: [NytoColors.ctaSoft, NytoColors.cta],
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: NytoColors.cta.withValues(alpha: 0.45),
                                blurRadius: 22,
                                offset: const Offset(0, 10),
                              ),
                            ],
                          ),
                          child: Text(
                            'Reserve',
                            style: GoogleFonts.dmSans(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
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

class _NightRailCard extends StatelessWidget {
  const _NightRailCard({required this.table, required this.onTap});

  final UpcomingTable table;
  final VoidCallback onTap;

  String get _dayShort {
    final w = table.weekday;
    if (w.length <= 3) return w.toUpperCase();
    return w.substring(0, 3).toUpperCase();
  }

  String get _dayNum {
    final m = RegExp(r'\d+').firstMatch(table.dateLabel);
    return m?.group(0) ?? '—';
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 148,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: NytoGlass.panel(
            borderRadius: 20,
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      _dayShort,
                      style: GoogleFonts.dmSans(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.1,
                        color: NytoColors.ctaSoft,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      '${table.seatsLeft} left',
                      style: GoogleFonts.dmSans(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: NytoColors.cream.withValues(alpha: 0.4),
                      ),
                    ),
                  ],
                ),
                Text(
                  _dayNum,
                  style: GoogleFonts.fraunces(
                    fontSize: 28,
                    height: 1.05,
                    color: NytoColors.cream,
                  ),
                ),
                const Spacer(),
                Text(
                  '${table.mealLabel} · ${table.timeLabel}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.dmSans(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: NytoColors.cream,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  table.area,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.dmSans(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: NytoColors.cream.withValues(alpha: 0.55),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _NytoBottomNav extends StatelessWidget {
  const _NytoBottomNav({
    required this.index,
    required this.onChanged,
  });

  final int index;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: NytoColors.ground,
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              height: 1,
              color: Colors.white.withValues(alpha: 0.08),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
              child: NytoGlass(
                borderRadius: 22,
                blur: 36,
                tint: Colors.white.withValues(alpha: 0.12),
                borderColor: Colors.white.withValues(alpha: 0.2),
                padding: const EdgeInsets.fromLTRB(6, 8, 6, 8),
                child: Row(
                  children: [
                    _NavItem(
                      icon: Icons.home_rounded,
                      label: 'Home',
                      selected: index == 0,
                      onTap: () => onChanged(0),
                    ),
                    _NavItem(
                      icon: Icons.chat_bubble_outline_rounded,
                      label: 'Chat',
                      selected: index == 1,
                      onTap: () => onChanged(1),
                    ),
                    _NavItem(
                      icon: Icons.calendar_today_outlined,
                      label: 'Events',
                      selected: index == 2,
                      onTap: () => onChanged(2),
                    ),
                    _NavItem(
                      icon: Icons.person_outline_rounded,
                      label: 'Profile',
                      selected: index == 3,
                      onTap: () => onChanged(3),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = selected
        ? NytoColors.cta
        : NytoColors.cream.withValues(alpha: 0.4);
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          padding: const EdgeInsets.symmetric(vertical: 6),
          decoration: selected
              ? BoxDecoration(
                  borderRadius: BorderRadius.circular(18),
                  color: NytoColors.cta.withValues(alpha: 0.16),
                )
              : null,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: color, size: 22),
              const SizedBox(height: 4),
              Text(
                label,
                style: GoogleFonts.dmSans(
                  fontSize: 11,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                  color: color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PlaceholderTab extends StatelessWidget {
  const _PlaceholderTab({
    required this.title,
    required this.body,
    required this.icon,
  });

  final String title;
  final String body;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 40, color: NytoColors.cta.withValues(alpha: 0.85)),
            const SizedBox(height: 16),
            Text(
              title,
              style: GoogleFonts.fraunces(
                fontSize: 26,
                color: NytoColors.cream,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              body,
              textAlign: TextAlign.center,
              style: GoogleFonts.dmSans(
                fontSize: 14,
                height: 1.45,
                color: NytoColors.cream.withValues(alpha: 0.5),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
