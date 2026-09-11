import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:nyto_app/core/api/nyto_api.dart';
import 'package:nyto_app/core/theme/app_theme.dart';
import 'package:nyto_app/core/widgets/nyto_glass.dart';
import 'package:nyto_app/domain/table.dart';
import 'package:nyto_app/features/booking/booking_opens_screen.dart';
import 'package:nyto_app/features/booking/booking_type_screen.dart';
import 'package:nyto_app/features/onboarding/widgets/onboarding_chrome.dart';
import 'package:video_player/video_player.dart';

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
                      _MenuGallery(
                        tableId: t.id,
                        inclusions: t.inclusions,
                      ),
                      const SizedBox(height: 18),
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
                                    : 'Connection fee with a complimentary drink. Food paid at the venue.',
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
                            if (t.paymentType == TablePaymentType.payOwnBill) ...[
                              const SizedBox(height: 6),
                              Text(
                                'You order food at the venue. NYTO covers the seat, matching, and a complimentary drink or snack.',
                                style: GoogleFonts.dmSans(
                                  fontSize: 13,
                                  height: 1.4,
                                  color:
                                      NytoColors.cream.withValues(alpha: 0.5),
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

/// Zomato-style food reel: one clip at a time, story bars, auto-advance.
/// Local assets for now — swap paths for S3 URLs later without changing UI.
class _MenuGallery extends StatefulWidget {
  const _MenuGallery({
    required this.tableId,
    required this.inclusions,
  });

  final String tableId;
  final List<String> inclusions;

  /// Prefer lighter clips first so the reel starts fast on device.
  static const _allClips = <String>[
    'assets/menu/videos/menu_05.mp4',
    'assets/menu/videos/menu_06.mp4',
    'assets/menu/videos/menu_07.mp4',
    'assets/menu/videos/menu_08.mp4',
    'assets/menu/videos/menu_09.mp4',
    'assets/menu/videos/menu_04.mp4',
  ];

  static const _labels = <String>[
    'Starter',
    'Main',
    'Biryani',
    'Dessert',
    'Drink',
    'Sides',
  ];

  @override
  State<_MenuGallery> createState() => _MenuGalleryState();
}

class _MenuGalleryState extends State<_MenuGallery> {
  late final List<({String label, String asset})> _clips;
  int _index = 0;
  VideoPlayerController? _current;
  VideoPlayerController? _next;
  bool _ready = false;
  double _progress = 0;
  bool _advancing = false;

  @override
  void initState() {
    super.initState();
    _clips = _clipsForTable();
    _loadIndex(0, prefetchNext: true);
  }

  List<({String label, String asset})> _clipsForTable() {
    final seed = widget.tableId.hashCode.abs();
    final order = List<String>.from(_MenuGallery._allClips);
    order.sort((a, b) => (a.hashCode ^ seed).compareTo(b.hashCode ^ seed));
    return [
      for (var i = 0; i < order.length; i++)
        (
          label: _MenuGallery._labels[i % _MenuGallery._labels.length],
          asset: order[i],
        ),
    ];
  }

  Future<VideoPlayerController?> _init(String asset) async {
    final controller = VideoPlayerController.asset(asset);
    try {
      await controller.initialize();
      await controller.setLooping(false);
      await controller.setVolume(0);
      return controller;
    } catch (_) {
      await controller.dispose();
      return null;
    }
  }

  Future<void> _loadIndex(int index, {required bool prefetchNext}) async {
    if (_clips.isEmpty) return;
    final i = index % _clips.length;

    VideoPlayerController? controller;
    final expectedNext = (_index + 1) % _clips.length;
    if (_next != null && i == expectedNext) {
      controller = _next;
      _next = null;
    } else {
      await _next?.dispose();
      _next = null;
      controller = await _init(_clips[i].asset);
    }

    final old = _current;
    old?.removeListener(_onTick);
    if (!mounted) {
      await controller?.dispose();
      return;
    }

    if (controller == null) {
      if (_clips.length > 1) {
        await _loadIndex(i + 1, prefetchNext: prefetchNext);
      }
      return;
    }

    setState(() {
      _current = controller;
      _index = i;
      _ready = true;
      _progress = 0;
      _advancing = false;
    });
    controller.addListener(_onTick);
    await controller.seekTo(Duration.zero);
    await controller.play();
    await old?.dispose();

    if (prefetchNext && _clips.length > 1) {
      final nextIndex = (i + 1) % _clips.length;
      final warmed = await _init(_clips[nextIndex].asset);
      if (!mounted) {
        await warmed?.dispose();
        return;
      }
      await _next?.dispose();
      _next = warmed;
    }
  }

  void _onTick() {
    final c = _current;
    if (c == null || !c.value.isInitialized || !mounted) return;
    final total = c.value.duration.inMilliseconds;
    if (total <= 0) return;
    final pos = c.value.position.inMilliseconds.clamp(0, total);
    final nextProgress = pos / total;
    if ((nextProgress - _progress).abs() > 0.008) {
      setState(() => _progress = nextProgress);
    }
    final ended =
        c.value.duration > Duration.zero &&
        c.value.position >=
            c.value.duration - const Duration(milliseconds: 120);
    if (ended && !_advancing) {
      _advancing = true;
      c.removeListener(_onTick);
      _goTo(_index + 1);
    }
  }

  Future<void> _goTo(int index) async {
    await _loadIndex(index, prefetchNext: true);
  }

  void _onTapDown(TapDownDetails details, BoxConstraints constraints) {
    final x = details.localPosition.dx;
    if (x < constraints.maxWidth * 0.35) {
      _goTo(_index - 1 < 0 ? _clips.length - 1 : _index - 1);
    } else {
      _goTo(_index + 1);
    }
  }

  @override
  void dispose() {
    _current?.removeListener(_onTick);
    _current?.dispose();
    _next?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final subtitle = widget.inclusions.isNotEmpty
        ? widget.inclusions.take(2).join(' · ')
        : 'Food & drinks included with your seat';
    final label = _clips.isEmpty ? '' : _clips[_index].label;

    return NytoGlass.panel(
      borderRadius: 20,
      padding: const EdgeInsets.fromLTRB(12, 14, 12, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6),
            child: Text(
              'On the table',
              style: GoogleFonts.dmSans(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.6,
                color: NytoColors.cream.withValues(alpha: 0.45),
              ),
            ),
          ),
          const SizedBox(height: 4),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6),
            child: Text(
              subtitle,
              style: GoogleFonts.dmSans(
                fontSize: 13,
                color: NytoColors.cream.withValues(alpha: 0.55),
              ),
            ),
          ),
          const SizedBox(height: 12),
          LayoutBuilder(
            builder: (context, constraints) {
              return GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTapDown: (d) => _onTapDown(d, constraints),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: AspectRatio(
                    aspectRatio: 16 / 10,
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        ColoredBox(
                          color: NytoColors.cta.withValues(alpha: 0.1),
                          child: _ready &&
                                  _current != null &&
                                  _current!.value.isInitialized
                              ? FittedBox(
                                  fit: BoxFit.cover,
                                  clipBehavior: Clip.hardEdge,
                                  child: SizedBox(
                                    width: _current!.value.size.width,
                                    height: _current!.value.size.height,
                                    child: VideoPlayer(_current!),
                                  ),
                                )
                              : const Center(
                                  child: SizedBox(
                                    width: 22,
                                    height: 22,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: NytoColors.cta,
                                    ),
                                  ),
                                ),
                        ),
                        Positioned(
                          left: 10,
                          right: 10,
                          top: 10,
                          child: Row(
                            children: [
                              for (var i = 0; i < _clips.length; i++) ...[
                                if (i > 0) const SizedBox(width: 4),
                                Expanded(
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(99),
                                    child: LinearProgressIndicator(
                                      value: i < _index
                                          ? 1
                                          : i == _index
                                              ? _progress
                                              : 0,
                                      minHeight: 3,
                                      backgroundColor:
                                          Colors.white.withValues(alpha: 0.28),
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                        Positioned(
                          left: 12,
                          right: 12,
                          bottom: 12,
                          child: Text(
                            '$label  ›',
                            style: GoogleFonts.dmSans(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                              shadows: const [
                                Shadow(
                                  blurRadius: 8,
                                  color: Colors.black54,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
