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
        extendBody: true,
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
                    grouped: _grouped,
                    onOpen: _openTable,
                    onBell: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            'Notifications coming soon',
                            style: GoogleFonts.dmSans(),
                          ),
                          backgroundColor: NytoColors.surfaceElevated,
                        ),
                      );
                    },
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

class _TablesTab extends StatelessWidget {
  const _TablesTab({
    required this.loading,
    required this.grouped,
    required this.onOpen,
    required this.onBell,
  });

  final bool loading;
  final Map<String, List<UpcomingTable>> grouped;
  final ValueChanged<UpcomingTable> onOpen;
  final VoidCallback onBell;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 12, 16, 0),
          child: Row(
            children: [
              Text(
                'Hyderabad',
                style: GoogleFonts.fraunces(
                  fontSize: 28,
                  fontWeight: FontWeight.w500,
                  color: NytoColors.cream,
                  letterSpacing: -0.3,
                ),
              ),
              const SizedBox(width: 6),
              Icon(
                Icons.location_on_rounded,
                size: 20,
                color: NytoColors.brandPink.withValues(alpha: 0.95),
              ),
              const Spacer(),
              IconButton(
                onPressed: onBell,
                icon: Icon(
                  Icons.notifications_none_rounded,
                  color: NytoColors.cream.withValues(alpha: 0.85),
                ),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 18, 24, 8),
          child: Text(
            'All tables',
            style: GoogleFonts.dmSans(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: NytoColors.cream,
            ),
          ),
        ),
        Expanded(
          child: loading
              ? const Center(
                  child: CircularProgressIndicator(color: NytoColors.brandPink),
                )
              : grouped.isEmpty
                  ? Center(
                      child: Text(
                        'No tables yet — check back soon.',
                        style: GoogleFonts.dmSans(
                          color: NytoColors.cream.withValues(alpha: 0.5),
                        ),
                      ),
                    )
                  : ListView(
                      padding: const EdgeInsets.fromLTRB(24, 8, 24, 110),
                      children: [
                        for (final entry in grouped.entries) ...[
                          Padding(
                            padding: const EdgeInsets.only(top: 10, bottom: 12),
                            child: Text(
                              entry.key,
                              style: GoogleFonts.dmSans(
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                                color: NytoColors.cream.withValues(alpha: 0.45),
                              ),
                            ),
                          ),
                          for (final table in entry.value) ...[
                            _EventRow(
                              table: table,
                              onTap: () => onOpen(table),
                            ),
                            const SizedBox(height: 12),
                          ],
                        ],
                      ],
                    ),
        ),
      ],
    );
  }
}

class _EventRow extends StatelessWidget {
  const _EventRow({required this.table, required this.onTap});

  final UpcomingTable table;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: NytoGlass.panel(
          borderRadius: 20,
          padding: const EdgeInsets.fromLTRB(14, 14, 12, 14),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      NytoColors.ctaDeep.withValues(alpha: 0.85),
                      NytoColors.cta.withValues(alpha: 0.75),
                    ],
                  ),
                ),
                child: Icon(
                  table.slot == MealSlot.daytimeLunch
                      ? Icons.wb_sunny_outlined
                      : Icons.restaurant_rounded,
                  color: Colors.white,
                  size: 22,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      table.fullDateLabel,
                      style: GoogleFonts.dmSans(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: NytoColors.cream,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${table.mealLabel}  ·  ${table.timeLabel}',
                      style: GoogleFonts.dmSans(
                        fontSize: 13,
                        color: NytoColors.cream.withValues(alpha: 0.5),
                      ),
                    ),
                    if (table.womenOnly) ...[
                      const SizedBox(height: 4),
                      Text(
                        'Women-only table',
                        style: GoogleFonts.dmSans(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w600,
                          color: NytoColors.ctaSoft.withValues(alpha: 0.95),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              Container(
                width: 40,
                height: 40,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [
                      NytoColors.ctaSoft,
                      NytoColors.cta,
                    ],
                  ),
                ),
                child: const Icon(
                  Icons.arrow_forward_rounded,
                  color: Colors.white,
                  size: 20,
                ),
              ),
            ],
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
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
      child: SafeArea(
        top: false,
        child: NytoGlass(
          borderRadius: 28,
          blur: 36,
          tint: Colors.white.withValues(alpha: 0.14),
          borderColor: Colors.white.withValues(alpha: 0.24),
          padding: const EdgeInsets.fromLTRB(8, 10, 8, 10),
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
