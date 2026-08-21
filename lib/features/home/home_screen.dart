import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:nyto_app/core/api/api_client.dart';
import 'package:nyto_app/core/api/nyto_api.dart';
import 'package:nyto_app/core/theme/app_theme.dart';
import 'package:nyto_app/core/widgets/nyto_glass.dart';
import 'package:nyto_app/features/booking/booking_type_screen.dart';
import 'package:nyto_app/features/onboarding/widgets/onboarding_chrome.dart';
import 'package:nyto_app/features/profile/my_bookings_screen.dart';
import 'package:nyto_app/features/profile/profile_screen.dart';
import 'package:nyto_app/domain/table.dart';
import 'package:nyto_app/features/table/table_chat_screen.dart';

/// Soft client lanes until backend visibility windows ship (Phase B).
class _HomeLanes {
  const _HomeLanes({
    this.invitation,
    this.open = const [],
    this.instant = const [],
    this.comingUp = const [],
  });

  final UpcomingTable? invitation;
  final List<UpcomingTable> open;
  final List<UpcomingTable> instant;
  final List<UpcomingTable> comingUp;

  bool get isEmpty =>
      invitation == null && open.isEmpty && instant.isEmpty && comingUp.isEmpty;

  /// Phase A heuristics:
  /// - Instant: starts within ~48h (last-minute lane)
  /// - Open: bookable curated window (~2–5 days out)
  /// - Coming up: further ahead
  /// - Invitation: soonest open (or soonest overall)
  static _HomeLanes from(List<UpcomingTable> tables, {DateTime? now}) {
    if (tables.isEmpty) return const _HomeLanes();
    final n = now ?? DateTime.now();
    final sorted = [...tables]..sort((a, b) {
        final aT = a.startsAt ?? DateTime.fromMillisecondsSinceEpoch(0);
        final bT = b.startsAt ?? DateTime.fromMillisecondsSinceEpoch(0);
        return aT.compareTo(bT);
      });

    final instant = <UpcomingTable>[];
    final open = <UpcomingTable>[];
    final coming = <UpcomingTable>[];

    for (final t in sorted) {
      final start = t.startsAt;
      if (start == null) {
        open.add(t);
        continue;
      }
      final hours = start.difference(n).inHours;
      if (hours < 0) continue; // already started
      if (hours <= 48) {
        instant.add(t);
      } else if (hours <= 120) {
        open.add(t);
      } else {
        coming.add(t);
      }
    }

    // Keep sections useful with thin seed data.
    if (open.isEmpty && coming.isNotEmpty) {
      open.addAll(coming.take(2));
      coming.removeRange(0, open.length.clamp(0, coming.length));
    }
    if (instant.isEmpty && open.length > 2) {
      instant.add(open.removeLast());
    }
    if (open.isEmpty && instant.isNotEmpty) {
      open.add(instant.removeAt(0));
    }

    UpcomingTable? invitation;
    if (open.isNotEmpty) {
      invitation = open.removeAt(0);
    } else if (instant.isNotEmpty) {
      invitation = instant.removeAt(0);
    } else if (coming.isNotEmpty) {
      invitation = coming.removeAt(0);
    }

    return _HomeLanes(
      invitation: invitation,
      open: open,
      instant: instant,
      comingUp: coming,
    );
  }
}

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
      menSeated: 1,
      womenSeated: 2,
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
      menSeated: 1,
      womenSeated: 1,
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
      womenSeated: 4,
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
      nonBinarySeated: 1,
      section: 'In 2 weeks',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);

    try {
      final rows = await tablesApi
          .list(filter: 'this_week')
          .timeout(const Duration(seconds: 8));
      if (!mounted) return;
      final parsed = rows.map(UpcomingTable.fromJson).toList();
      setState(() {
        _tables = parsed.isNotEmpty ? parsed : _demoTables;
        _loading = false;
      });
    } on ApiException catch (_) {
      if (!mounted) return;
      setState(() {
        _tables = _demoTables;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _tables = _demoTables;
        _loading = false;
      });
    }
  }

  Future<void> _openTable(UpcomingTable table) async {
    if (!mounted) return;
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
                  _HomeDiscoverTab(
                    loading: _loading,
                    lanes: _HomeLanes.from(_tables),
                    onOpen: _openTable,
                    onBell: () {},
                    onRefresh: _load,
                  ),
                  const _ChatListTab(),
                  const MyBookingsScreen(embedded: true),
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

class _HomeDiscoverTab extends StatefulWidget {
  const _HomeDiscoverTab({
    required this.loading,
    required this.lanes,
    required this.onOpen,
    required this.onBell,
    required this.onRefresh,
  });

  final bool loading;
  final _HomeLanes lanes;
  final ValueChanged<UpcomingTable> onOpen;
  final VoidCallback onBell;
  final Future<void> Function() onRefresh;

  @override
  State<_HomeDiscoverTab> createState() => _HomeDiscoverTabState();
}

class _HomeDiscoverTabState extends State<_HomeDiscoverTab>
    with SingleTickerProviderStateMixin {
  late final AnimationController _enter;
  late final Animation<double> _fade;
  late final Animation<Offset> _slide;
  final _scroll = ScrollController();
  final _instantKey = GlobalKey();

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
    _scroll.dispose();
    _enter.dispose();
    super.dispose();
  }

  void _jumpToInstant() {
    final ctx = _instantKey.currentContext;
    if (ctx == null) return;
    Scrollable.ensureVisible(
      ctx,
      duration: const Duration(milliseconds: 420),
      curve: Curves.easeOutCubic,
      alignment: 0.08,
    );
  }

  String get _city {
    final lanes = widget.lanes;
    return lanes.invitation?.city ??
        (lanes.open.isNotEmpty ? lanes.open.first.city : null) ??
        (lanes.instant.isNotEmpty ? lanes.instant.first.city : null) ??
        'Hyderabad';
  }

  @override
  Widget build(BuildContext context) {
    final lanes = widget.lanes;
    final hasInstant = lanes.instant.isNotEmpty;

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
                    _city,
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
            Padding(
              padding: const EdgeInsets.fromLTRB(22, 6, 22, 0),
              child: Text(
                'One invite. Then the open seats.',
                style: GoogleFonts.dmSans(
                  fontSize: 13,
                  height: 1.35,
                  color: NytoColors.cream.withValues(alpha: 0.4),
                ),
              ),
            ),
            if (hasInstant && !widget.loading) ...[
              const SizedBox(height: 12),
              Padding(
                padding: const EdgeInsets.fromLTRB(22, 0, 22, 0),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: _InstantShortcut(
                    count: lanes.instant.length,
                    onTap: _jumpToInstant,
                  ),
                ),
              ),
            ],
            const SizedBox(height: 12),
            Expanded(
              child: widget.loading
                  ? const Center(
                      child: CircularProgressIndicator(
                        color: NytoColors.brandPink,
                      ),
                    )
                  : lanes.isEmpty
                      ? _HomeEmptyState(onRefresh: widget.onRefresh)
                      : RefreshIndicator(
                          color: NytoColors.cta,
                          backgroundColor: NytoColors.surfaceElevated,
                          onRefresh: widget.onRefresh,
                          child: ListView(
                            controller: _scroll,
                            physics: const AlwaysScrollableScrollPhysics(),
                            padding: const EdgeInsets.fromLTRB(18, 0, 18, 28),
                            children: [
                              if (lanes.invitation != null) ...[
                                const _SectionLabel(
                                  eyebrow: 'THE INVITE',
                                  title: 'Tonight’s invitation',
                                ),
                                const SizedBox(height: 10),
                                SizedBox(
                                  height: 300,
                                  child: _InvitationCard(
                                    table: lanes.invitation!,
                                    onTap: () =>
                                        widget.onOpen(lanes.invitation!),
                                  ),
                                ),
                                const SizedBox(height: 26),
                              ],
                              if (hasInstant) ...[
                                KeyedSubtree(
                                  key: _instantKey,
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const _SectionLabel(
                                        eyebrow: 'INSTANT',
                                        title: 'Going soon',
                                        subtitle:
                                            'Last-minute seats — book fast.',
                                        accent: NytoColors.orange,
                                      ),
                                      const SizedBox(height: 10),
                                      SizedBox(
                                        height: 168,
                                        child: ListView.separated(
                                          scrollDirection: Axis.horizontal,
                                          itemCount: lanes.instant.length,
                                          separatorBuilder: (_, __) =>
                                              const SizedBox(width: 10),
                                          itemBuilder: (context, i) {
                                            final t = lanes.instant[i];
                                            return _InstantRailCard(
                                              table: t,
                                              onTap: () => widget.onOpen(t),
                                            );
                                          },
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 26),
                              ],
                              if (lanes.open.isNotEmpty) ...[
                                const _SectionLabel(
                                  eyebrow: 'OPEN',
                                  title: 'Bookable now',
                                  subtitle: 'Until 2 hours before the night.',
                                ),
                                const SizedBox(height: 10),
                                for (final t in lanes.open) ...[
                                  _OpenTableRow(
                                    table: t,
                                    onTap: () => widget.onOpen(t),
                                  ),
                                  const SizedBox(height: 8),
                                ],
                                const SizedBox(height: 22),
                              ],
                              if (lanes.comingUp.isNotEmpty) ...[
                                Opacity(
                                  opacity: 0.72,
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const _SectionLabel(
                                        eyebrow: 'LATER',
                                        title: 'Coming up',
                                        subtitle:
                                            'Opens when the next drop hits.',
                                      ),
                                      const SizedBox(height: 10),
                                      SizedBox(
                                        height: 128,
                                        child: ListView.separated(
                                          scrollDirection: Axis.horizontal,
                                          itemCount: lanes.comingUp.length,
                                          separatorBuilder: (_, __) =>
                                              const SizedBox(width: 10),
                                          itemBuilder: (context, i) {
                                            final t = lanes.comingUp[i];
                                            return _ComingUpRailCard(
                                              table: t,
                                              onTap: () => widget.onOpen(t),
                                            );
                                          },
                                        ),
                                      ),
                                    ],
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

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({
    required this.eyebrow,
    required this.title,
    this.subtitle,
    this.accent,
  });

  final String eyebrow;
  final String title;
  final String? subtitle;
  final Color? accent;

  @override
  Widget build(BuildContext context) {
    final a = accent ?? NytoColors.ctaSoft;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          eyebrow,
          style: GoogleFonts.dmSans(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.5,
            color: a,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          title,
          style: GoogleFonts.fraunces(
            fontSize: 22,
            height: 1.15,
            color: NytoColors.cream,
          ),
        ),
        if (subtitle != null) ...[
          const SizedBox(height: 4),
          Text(
            subtitle!,
            style: GoogleFonts.dmSans(
              fontSize: 12,
              height: 1.35,
              color: NytoColors.cream.withValues(alpha: 0.4),
            ),
          ),
        ],
      ],
    );
  }
}

class _InstantShortcut extends StatelessWidget {
  const _InstantShortcut({
    required this.count,
    required this.onTap,
  });

  final int count;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
              color: NytoColors.orange.withValues(alpha: 0.55),
            ),
            gradient: LinearGradient(
              colors: [
                NytoColors.orange.withValues(alpha: 0.28),
                NytoColors.orange.withValues(alpha: 0.12),
              ],
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(14, 9, 12, 9),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.bolt_rounded,
                  size: 16,
                  color: NytoColors.orange,
                ),
                const SizedBox(width: 6),
                Text(
                  'Instant',
                  style: GoogleFonts.dmSans(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: NytoColors.cream,
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 7,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(999),
                    color: Colors.black.withValues(alpha: 0.28),
                  ),
                  child: Text(
                    '$count',
                    style: GoogleFonts.dmSans(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: NytoColors.cream.withValues(alpha: 0.85),
                    ),
                  ),
                ),
                const SizedBox(width: 2),
                Icon(
                  Icons.keyboard_arrow_down_rounded,
                  size: 18,
                  color: NytoColors.cream.withValues(alpha: 0.65),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _HomeEmptyState extends StatelessWidget {
  const _HomeEmptyState({required this.onRefresh});

  final Future<void> Function() onRefresh;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.event_seat_outlined,
              size: 36,
              color: NytoColors.ctaSoft.withValues(alpha: 0.7),
            ),
            const SizedBox(height: 14),
            Text(
              'No tables open yet',
              style: GoogleFonts.fraunces(
                fontSize: 22,
                color: NytoColors.cream,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'When the next drop goes live, your invite lands here.',
              textAlign: TextAlign.center,
              style: GoogleFonts.dmSans(
                fontSize: 14,
                height: 1.4,
                color: NytoColors.cream.withValues(alpha: 0.45),
              ),
            ),
            const SizedBox(height: 18),
            TextButton(
              onPressed: () => onRefresh(),
              child: Text(
                'Refresh',
                style: GoogleFonts.dmSans(
                  fontWeight: FontWeight.w700,
                  color: NytoColors.ctaSoft,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SeatMixBadge extends StatelessWidget {
  const _SeatMixBadge({required this.table});

  final UpcomingTable table;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        color: Colors.black.withValues(alpha: 0.35),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.14),
        ),
      ),
      child: Text(
        table.seatMixLabel,
        style: GoogleFonts.dmSans(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: NytoColors.cream,
        ),
      ),
    );
  }
}

class _InvitationCard extends StatelessWidget {
  const _InvitationCard({required this.table, required this.onTap});

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
              DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: isLunch
                        ? const [
                            Color(0xFF1A2438),
                            Color(0xFF0B1220),
                            Color(0xFF15100C),
                          ]
                        : const [
                            Color(0xFF101B33),
                            Color(0xFF070B14),
                            Color(0xFF0C1424),
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
                          isLunch ? 'LUNCH INVITE' : 'NIGHT INVITE',
                          style: GoogleFonts.dmSans(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1.6,
                            color: NytoColors.ctaSoft,
                          ),
                        ),
                        const Spacer(),
                        _SeatMixBadge(table: table),
                      ],
                    ),
                    const Spacer(),
                    Text(
                      table.weekday,
                      style: GoogleFonts.fraunces(
                        fontSize: 42,
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
                    const SizedBox(height: 12),
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
                      '${table.area} · ${table.city}',
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

class _OpenTableRow extends StatelessWidget {
  const _OpenTableRow({required this.table, required this.onTap});

  final UpcomingTable table;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: NytoGlass.panel(
          borderRadius: 18,
          padding: const EdgeInsets.fromLTRB(16, 14, 14, 14),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${table.weekday} · ${table.dateLabel}',
                      style: GoogleFonts.fraunces(
                        fontSize: 18,
                        color: NytoColors.cream,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${table.mealLabel} · ${table.timeLabel}',
                      style: GoogleFonts.dmSans(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: NytoColors.cream.withValues(alpha: 0.78),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${table.area} · ${table.city}',
                      style: GoogleFonts.dmSans(
                        fontSize: 12,
                        color: NytoColors.cream.withValues(alpha: 0.42),
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '₹${table.priceInr}',
                    style: GoogleFonts.fraunces(
                      fontSize: 18,
                      color: NytoColors.cream,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    table.seatMixLabel,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.end,
                    style: GoogleFonts.dmSans(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: NytoColors.ctaSoft,
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 6),
              Icon(
                Icons.chevron_right_rounded,
                color: NytoColors.cream.withValues(alpha: 0.35),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _InstantRailCard extends StatelessWidget {
  const _InstantRailCard({required this.table, required this.onTap});

  final UpcomingTable table;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 178,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: NytoColors.orange.withValues(alpha: 0.5),
                width: 1.2,
              ),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  NytoColors.orange.withValues(alpha: 0.28),
                  const Color(0xFF1A120C),
                  NytoColors.surfaceElevated,
                ],
              ),
              boxShadow: [
                BoxShadow(
                  color: NytoColors.orange.withValues(alpha: 0.22),
                  blurRadius: 18,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(999),
                        color: NytoColors.orange.withValues(alpha: 0.22),
                      ),
                      child: Text(
                        'INSTANT',
                        style: GoogleFonts.dmSans(
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.1,
                          color: NytoColors.orange,
                        ),
                      ),
                    ),
                    const Spacer(),
                    Text(
                      table.seatMixLabel,
                      style: GoogleFonts.dmSans(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: NytoColors.cream.withValues(alpha: 0.55),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  '${table.weekday} ${table.dateLabel}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.fraunces(
                    fontSize: 18,
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
                    color: NytoColors.cream.withValues(alpha: 0.5),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '₹${table.priceInr}',
                  style: GoogleFonts.fraunces(
                    fontSize: 16,
                    color: NytoColors.cream,
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

class _ComingUpRailCard extends StatelessWidget {
  const _ComingUpRailCard({required this.table, required this.onTap});

  final UpcomingTable table;
  final VoidCallback onTap;

  String get _dayShort {
    final w = table.weekday;
    if (w.length <= 3) return w.toUpperCase();
    return w.substring(0, 3).toUpperCase();
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
                Text(
                  _dayShort,
                  style: GoogleFonts.dmSans(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.1,
                    color: NytoColors.cream.withValues(alpha: 0.4),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  table.dateLabel,
                  style: GoogleFonts.fraunces(
                    fontSize: 20,
                    height: 1.05,
                    color: NytoColors.cream.withValues(alpha: 0.85),
                  ),
                ),
                const Spacer(),
                Text(
                  '${table.mealLabel} · ${table.timeLabel}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.dmSans(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: NytoColors.cream.withValues(alpha: 0.7),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  table.area,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.dmSans(
                    fontSize: 11,
                    color: NytoColors.cream.withValues(alpha: 0.4),
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
                      icon: Icons.event_seat_outlined,
                      label: 'Bookings',
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

/// Chat tab — lists booked table chats. Demo data until backend.
class _ChatListTab extends StatelessWidget {
  const _ChatListTab();

  static const _demoChats = [
    (
      venue: 'Jubilee Hills',
      day: 'Friday',
      time: '8:00 PM',
      lastMsg: 'Hey everyone! Excited for this one.',
      joined: 3,
      capacity: 6,
    ),
    (
      venue: 'Gachibowli',
      day: 'Wednesday',
      time: '8:00 PM',
      lastMsg: 'Say hi to your table',
      joined: 1,
      capacity: 6,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(22, 12, 22, 0),
          child: Text(
            'Chats',
            style: GoogleFonts.dmSans(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.6,
              color: NytoColors.cream.withValues(alpha: 0.45),
            ),
          ),
        ),
        Expanded(
          child: _demoChats.isEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.chat_bubble_outline_rounded,
                            size: 40,
                            color: NytoColors.cta.withValues(alpha: 0.85)),
                        const SizedBox(height: 16),
                        Text(
                          'Chat',
                          style: GoogleFonts.fraunces(
                            fontSize: 26,
                            color: NytoColors.cream,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Your table chats unlock after you book a seat.',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.dmSans(
                            fontSize: 14,
                            color: NytoColors.cream.withValues(alpha: 0.45),
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              : ListView.separated(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
                  itemCount: _demoChats.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    final c = _demoChats[index];
                    return Material(
                      color: Colors.transparent,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(16),
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute<void>(
                              builder: (_) => TableChatScreen(
                                venueName: c.venue,
                                dayLabel: c.day,
                                timeLabel: c.time,
                              ),
                            ),
                          );
                        },
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: NytoColors.surface,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color:
                                  NytoColors.cream.withValues(alpha: 0.08),
                            ),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                width: 48,
                                height: 48,
                                alignment: Alignment.center,
                                decoration: BoxDecoration(
                                  color:
                                      NytoColors.cta.withValues(alpha: 0.18),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  Icons.chat_bubble_outline_rounded,
                                  size: 22,
                                  color: NytoColors.ctaSoft,
                                ),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Expanded(
                                          child: Text(
                                            c.venue,
                                            style: GoogleFonts.dmSans(
                                              fontSize: 15,
                                              fontWeight: FontWeight.w600,
                                              color: NytoColors.cream,
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 8,
                                            vertical: 4,
                                          ),
                                          decoration: BoxDecoration(
                                            color: NytoColors.cta
                                                .withValues(alpha: 0.15),
                                            borderRadius:
                                                BorderRadius.circular(8),
                                          ),
                                          child: Text(
                                            '${c.joined}/${c.capacity}',
                                            style: GoogleFonts.dmSans(
                                              fontSize: 11,
                                              fontWeight: FontWeight.w700,
                                              color: NytoColors.ctaSoft,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      '${c.day} · ${c.time}',
                                      style: GoogleFonts.dmSans(
                                        fontSize: 12,
                                        color: NytoColors.cream
                                            .withValues(alpha: 0.45),
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      c.lastMsg,
                                      style: GoogleFonts.dmSans(
                                        fontSize: 13,
                                        color: NytoColors.cream
                                            .withValues(alpha: 0.5),
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }
}
