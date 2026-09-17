import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:nyto_app/core/theme/app_theme.dart';
import 'package:video_player/video_player.dart';

/// Editorial food reel: metadata on the page, hero media, story progress.
/// Local assets for now — swap paths for S3 URLs later without changing UI.
class TableMenuGallery extends StatefulWidget {
  const TableMenuGallery({
    super.key,
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

  static const _mediaRadius = 18.0;

  @override
  State<TableMenuGallery> createState() => _TableMenuGalleryState();
}

class _TableMenuGalleryState extends State<TableMenuGallery>
    with WidgetsBindingObserver {
  late final List<({String label, String asset})> _clips;
  int _index = 0;
  VideoPlayerController? _current;
  VideoPlayerController? _next;
  bool _ready = false;
  double _progress = 0;
  bool _advancing = false;
  bool _prefetching = false;
  int _loadGen = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _clips = _clipsForTable();
    unawaited(_loadIndex(0, prefetchNext: true));
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _current?.removeListener(_onTick);
    _current?.dispose();
    _next?.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      unawaited(_ensurePlaying(_current));
    } else if (state == AppLifecycleState.inactive ||
        state == AppLifecycleState.paused) {
      _current?.pause();
    }
  }

  List<({String label, String asset})> _clipsForTable() {
    final seed = widget.tableId.hashCode.abs();
    final order = List<String>.from(TableMenuGallery._allClips);
    order.sort((a, b) => (a.hashCode ^ seed).compareTo(b.hashCode ^ seed));
    return [
      for (var i = 0; i < order.length; i++)
        (
          label: TableMenuGallery._labels[i % TableMenuGallery._labels.length],
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

  Future<void> _ensurePlaying(VideoPlayerController? controller) async {
    if (controller == null || !controller.value.isInitialized) return;
    try {
      if (!controller.value.isPlaying) {
        await controller.play();
      }
      await Future<void>.delayed(const Duration(milliseconds: 80));
      if (!mounted || !identical(_current, controller)) return;
      if (!controller.value.isPlaying &&
          controller.value.position <
              controller.value.duration - const Duration(milliseconds: 200)) {
        await controller.seekTo(controller.value.position);
        await controller.play();
      }
    } catch (_) {}
  }

  Future<void> _loadIndex(int index, {required bool prefetchNext}) async {
    if (_clips.isEmpty) return;
    final gen = ++_loadGen;
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

    if (gen != _loadGen) {
      await controller?.dispose();
      return;
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
    await _ensurePlaying(controller);
    await old?.dispose();

    if (!prefetchNext || _clips.length <= 1 || gen != _loadGen) return;

    Future<void>.delayed(const Duration(milliseconds: 350), () {
      if (!mounted || gen != _loadGen) return;
      unawaited(_prefetchNext(i));
    });
  }

  Future<void> _prefetchNext(int currentIndex) async {
    if (_prefetching || _clips.length <= 1) return;
    _prefetching = true;
    try {
      final nextIndex = (currentIndex + 1) % _clips.length;
      if (_next != null) return;
      final warmed = await _init(_clips[nextIndex].asset);
      if (!mounted) {
        await warmed?.dispose();
        return;
      }
      await _ensurePlaying(_current);
      await _next?.dispose();
      _next = warmed;
    } finally {
      _prefetching = false;
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

    final nearEnd =
        c.value.duration > Duration.zero &&
        c.value.position >=
            c.value.duration - const Duration(milliseconds: 120);
    final stalled = !c.value.isPlaying &&
        !nearEnd &&
        c.value.position > Duration.zero;

    if (nearEnd && !_advancing) {
      _advancing = true;
      c.removeListener(_onTick);
      unawaited(_goTo(_index + 1));
      return;
    }

    if (stalled) {
      unawaited(_ensurePlaying(c));
    }
  }

  Future<void> _goTo(int index) async {
    await _loadIndex(index, prefetchNext: true);
  }

  void _onTapDown(TapDownDetails details, BoxConstraints constraints) {
    final x = details.localPosition.dx;
    if (x < constraints.maxWidth * 0.35) {
      unawaited(_goTo(_index - 1 < 0 ? _clips.length - 1 : _index - 1));
    } else {
      unawaited(_goTo(_index + 1));
    }
  }

  @override
  Widget build(BuildContext context) {
    final label = _clips.isEmpty ? '' : _clips[_index].label;

    return LayoutBuilder(
      builder: (context, constraints) {
        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTapDown: (d) => _onTapDown(d, constraints),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(TableMenuGallery._mediaRadius),
            child: AspectRatio(
              aspectRatio: 1.85,
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
                  const DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Color(0x00000000),
                          Color(0x00000000),
                          Color(0x4D000000),
                          Color(0x8A000000),
                        ],
                        stops: [0.0, 0.52, 0.78, 1.0],
                      ),
                    ),
                  ),
                  Positioned(
                    left: 12,
                    right: 12,
                    top: 12,
                    child: Row(
                      children: [
                        for (var i = 0; i < _clips.length; i++) ...[
                          if (i > 0) const SizedBox(width: 3),
                          Expanded(
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(99),
                              child: LinearProgressIndicator(
                                value: i < _index
                                    ? 1
                                    : i == _index
                                        ? _progress
                                        : 0,
                                minHeight: 2,
                                backgroundColor:
                                    Colors.white.withValues(alpha: 0.22),
                                color: Colors.white.withValues(alpha: 0.92),
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  Positioned(
                    left: 14,
                    bottom: 14,
                    right: 14,
                    child: Text(
                      '$label  ›',
                      style: GoogleFonts.dmSans(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.2,
                        color: Colors.white,
                        shadows: const [
                          Shadow(
                            blurRadius: 10,
                            color: Color(0x99000000),
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
    );
  }
}
