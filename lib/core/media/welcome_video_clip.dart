import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:video_player/video_player.dart';

/// One welcome hero clip — path, loop window, headline + caption copy.
class WelcomeClipConfig {
  const WelcomeClipConfig({
    required this.assetPath,
    required this.loopEnd,
    required this.headline,
    required this.caption,
  });

  final String assetPath;
  final Duration loopEnd;
  final String headline;
  final String caption;
}

/// All controllers warmed for splash → welcome (zero gap on first frame).
class WelcomeCarouselSession {
  const WelcomeCarouselSession({
    required this.clips,
    required this.controllers,
  });

  final List<WelcomeClipConfig> clips;
  final List<VideoPlayerController> controllers;
}

/// Welcome hero clips — carousel order.
abstract final class WelcomeVideoClip {
  static const clips = <WelcomeClipConfig>[
    WelcomeClipConfig(
      assetPath: 'assets/video/welcome_01.mp4',
      loopEnd: Duration(milliseconds: 7280),
      headline: 'Your vibe.\nYour experience.',
      caption: 'Find something you want to do, or create it yourself.',
    ),
    WelcomeClipConfig(
      assetPath: 'assets/video/welcome_02.mp4',
      loopEnd: Duration(milliseconds: 7480),
      headline: 'Real people.\nReal plans.',
      caption: 'Verified guests, clear details. Your table, your night.',
    ),
    WelcomeClipConfig(
      assetPath: 'assets/video/welcome_03.mp4',
      loopEnd: Duration(milliseconds: 7480),
      headline: 'You choose\nthe experience.',
      caption: 'Dinner, runs, parties, or create your own.',
    ),
    WelcomeClipConfig(
      assetPath: 'assets/video/welcome_04.mp4',
      loopEnd: Duration(milliseconds: 7480),
      headline: 'Host it. Join it.\nBuild your people.',
      caption: 'Set the vibe, invite your crowd. Grow together.',
    ),
  ];

  static const crossfadeDuration = Duration(milliseconds: 850);
  static const _initTimeout = Duration(milliseconds: 12000);

  static Future<bool> assetExists(String path) async {
    try {
      await rootBundle.load(path);
      return true;
    } catch (_) {
      return false;
    }
  }

  /// Clips whose asset files exist on disk, in carousel order.
  static Future<List<WelcomeClipConfig>> availableClips() async {
    final out = <WelcomeClipConfig>[];
    for (final clip in clips) {
      if (await assetExists(clip.assetPath)) out.add(clip);
    }
    return out;
  }

  static Future<VideoPlayerController?> _initController(String path) async {
    try {
      final controller = VideoPlayerController.asset(path);
      await controller.initialize().timeout(_initTimeout);
      await controller.setLooping(false);
      await controller.setVolume(0);
      return controller;
    } catch (_) {
      return null;
    }
  }

  /// Warm first clip only — full carousel loads on welcome after navigate.
  static Future<({VideoPlayerController controller, String assetPath})?>
      warmFirstClip() async {
    final available = await availableClips();
    if (available.isEmpty) return null;

    final clip = available.first;
    final controller = await _initController(clip.assetPath);
    if (controller == null) return null;

    try {
      await controller.setLooping(true);
      await controller.play();
    } catch (_) {
      await controller.dispose();
      return null;
    }

    return (controller: controller, assetPath: clip.assetPath);
  }

  /// Loads every clip it can — partial success is OK (skips failed inits).
  static Future<WelcomeCarouselSession?> createCarousel({
    VideoPlayerController? preloadedFirst,
    String? preloadedAssetPath,
  }) async {
    final available = await availableClips();
    if (available.isEmpty) return null;

    final loadedClips = <WelcomeClipConfig>[];
    final controllers = <VideoPlayerController>[];

    final usePreloaded = preloadedFirst != null &&
        preloadedFirst.value.isInitialized &&
        available.isNotEmpty &&
        (preloadedAssetPath == null ||
            preloadedAssetPath == available.first.assetPath);

    if (usePreloaded) {
      loadedClips.add(available.first);
      controllers.add(preloadedFirst);
      // Parallel for speed — splash/welcome already has clip 0 playing.
      final restClips = available.skip(1).toList();
      if (restClips.isNotEmpty) {
        final restControllers = await Future.wait(
          restClips.map((clip) => _initController(clip.assetPath)),
        );
        for (var i = 0; i < restClips.length; i++) {
          final controller = restControllers[i];
          if (controller != null) {
            loadedClips.add(restClips[i]);
            controllers.add(controller);
          }
        }
      }
    } else {
      final initialized = await Future.wait(
        available.map((clip) => _initController(clip.assetPath)),
      );
      for (var i = 0; i < available.length; i++) {
        final controller = initialized[i];
        if (controller != null) {
          loadedClips.add(available[i]);
          controllers.add(controller);
        }
      }
    }

    if (controllers.isEmpty) return null;

    if (!usePreloaded) {
      await _applyLoopPolicy(controllers, loadedClips.length == 1);
    } else if (loadedClips.length == 1) {
      // Keep native loop on the clip splash is already playing.
      for (var i = 1; i < controllers.length; i++) {
        try {
          await controllers[i].setLooping(false);
        } catch (_) {}
      }
    } else {
      for (var i = 1; i < controllers.length; i++) {
        try {
          await controllers[i].setLooping(false);
        } catch (_) {}
      }
    }

    final first = controllers.first;
    if (!first.value.isPlaying) {
      try {
        await first.play();
      } catch (_) {}
    }

    return WelcomeCarouselSession(
      clips: loadedClips,
      controllers: controllers,
    );
  }

  static Future<void> _applyLoopPolicy(
    List<VideoPlayerController> controllers,
    bool singleClip,
  ) async {
    for (final c in controllers) {
      try {
        await c.setLooping(singleClip);
      } catch (_) {}
    }
  }

  static Future<void> disableNativeLoop(
    List<VideoPlayerController> controllers,
  ) async {
    await _applyLoopPolicy(controllers, false);
  }

  static Future<void> disposeSession(
    WelcomeCarouselSession session, {
    VideoPlayerController? keep,
  }) async {
    for (final c in session.controllers) {
      if (c != keep) {
        await c.dispose();
      }
    }
  }
}

/// Drives clip playback → soft crossfade → next clip (loops).
class WelcomeCarouselController extends ChangeNotifier {
  WelcomeCarouselController({
    required WelcomeCarouselSession session,
    required TickerProvider vsync,
  }) : session = session {
    _clips.addAll(session.clips);
    _controllers.addAll(session.controllers);

    _crossfade = AnimationController(
      vsync: vsync,
      duration: WelcomeVideoClip.crossfadeDuration,
    )..addStatusListener(_onCrossfadeStatus);

    _crossfadeCurve = CurvedAnimation(
      parent: _crossfade,
      curve: Curves.easeInOutCubic,
    );

    _activeIndex = 0;
    _incomingIndex = 0;
    for (final c in _controllers) {
      c.addListener(_onVideoTick);
    }

    _watchdog = Timer.periodic(const Duration(milliseconds: 400), (_) {
      _pollPlayback();
    });

    if (_clips.length > 1) {
      unawaited(WelcomeVideoClip.disableNativeLoop(_controllers));
    }
  }

  WelcomeCarouselSession session;
  final List<WelcomeClipConfig> _clips = [];
  final List<VideoPlayerController> _controllers = [];

  late final AnimationController _crossfade;
  late final Animation<double> _crossfadeCurve;
  late final Timer _watchdog;

  late int _activeIndex;
  late int _incomingIndex;
  bool _isTransitioning = false;
  bool _singleRestarting = false;

  Animation<double> get crossfade => _crossfadeCurve;
  bool get isTransitioning => _isTransitioning;
  int get activeIndex => _activeIndex;
  int get incomingIndex => _incomingIndex;
  List<WelcomeClipConfig> get clips => _clips;
  List<VideoPlayerController> get controllers => _controllers;

  WelcomeClipConfig get activeClip => _clips[_activeIndex];

  int get displayClipIndex {
    if (!_isTransitioning) return _activeIndex;
    return crossfade.value >= 0.5 ? _incomingIndex : _activeIndex;
  }

  /// Add newly loaded clips without tearing down the active player (Android-safe).
  Future<void> absorbSession(WelcomeCarouselSession expanded) async {
    if (expanded.controllers.length <= _controllers.length) return;

    session = expanded;
    for (var i = _controllers.length; i < expanded.controllers.length; i++) {
      _clips.add(expanded.clips[i]);
      _controllers.add(expanded.controllers[i]);
      expanded.controllers[i].addListener(_onVideoTick);
    }

    await WelcomeVideoClip.disableNativeLoop(_controllers);

    final active = _controllers[_activeIndex];
    if (active.value.isInitialized && !active.value.isPlaying) {
      try {
        await active.play();
      } catch (_) {}
    }

    notifyListeners();
  }

  void _onCrossfadeStatus(AnimationStatus status) {
    if (status == AnimationStatus.completed) {
      _finishCrossfade();
    }
  }

  void _onVideoTick() {
    _pollPlayback();
  }

  void _pollPlayback() {
    if (_isTransitioning || _singleRestarting || _controllers.isEmpty) return;
    _watchSingleClip(
      _controllers[_activeIndex],
      _clips[_activeIndex].loopEnd,
    );
  }

  void _watchSingleClip(VideoPlayerController controller, Duration loopEnd) {
    if (!controller.value.isInitialized) return;

    // Single clip + native loop: keep playing until more clips are absorbed.
    if (_clips.length == 1) {
      if (!controller.value.isPlaying) {
        unawaited(_ensurePlaying(controller));
      }
      return;
    }

    final pos = controller.value.position;
    final duration = controller.value.duration;
    final hitClipEnd = pos >= loopEnd;
    final hitFileEnd = duration > Duration.zero &&
        pos >= duration - const Duration(milliseconds: 150);
    final stalled = !controller.value.isPlaying && (hitClipEnd || hitFileEnd);

    if (hitClipEnd || hitFileEnd || stalled) {
      unawaited(_advance());
    } else if (!controller.value.isPlaying &&
        pos < loopEnd - const Duration(milliseconds: 300)) {
      unawaited(controller.play());
    }
  }

  Future<void> _ensurePlaying(VideoPlayerController controller) async {
    try {
      if (!controller.value.isPlaying) {
        await controller.play();
      }
    } catch (_) {}
  }

  Future<void> _advance() async {
    if (_isTransitioning || _singleRestarting) return;

    if (_clips.length == 1) {
      await _restartSingle(_controllers[0]);
      return;
    }

    _isTransitioning = true;
    _incomingIndex = (_activeIndex + 1) % _clips.length;
    final outgoing = _controllers[_activeIndex];
    final incoming = _controllers[_incomingIndex];

    try {
      await incoming.seekTo(Duration.zero);
      await outgoing.pause();
      await Future<void>.delayed(const Duration(milliseconds: 60));
      await incoming.play();
      if (!incoming.value.isPlaying) {
        await incoming.seekTo(Duration.zero);
        await incoming.play();
      }
      await _crossfade.forward(from: 0);
    } catch (_) {
      _isTransitioning = false;
      _crossfade.value = 0;
      notifyListeners();
      await _restartSingle(outgoing);
    }
  }

  Future<void> _restartSingle(VideoPlayerController controller) async {
    if (_singleRestarting || !controller.value.isInitialized) return;
    _singleRestarting = true;
    try {
      await controller.pause();
      await controller.seekTo(Duration.zero);
      await controller.play();
      await Future<void>.delayed(const Duration(milliseconds: 120));
      if (!controller.value.isPlaying) {
        await controller.seekTo(Duration.zero);
        await controller.play();
      }
    } catch (_) {
      // Ignore seek races on low-end GPUs.
    } finally {
      _singleRestarting = false;
      notifyListeners();
    }
  }

  void _finishCrossfade() {
    final outgoing = _controllers[_activeIndex];
    outgoing.pause();
    unawaited(outgoing.seekTo(Duration.zero));

    _activeIndex = _incomingIndex;
    _isTransitioning = false;
    _crossfade.value = 0;
    notifyListeners();
  }

  void resumePlayback() {
    final active = _controllers[_activeIndex];
    if (active.value.isInitialized && !active.value.isPlaying) {
      active.play();
    }
  }

  @override
  void dispose() {
    _watchdog.cancel();
    _crossfade.dispose();
    for (final c in _controllers) {
      c.removeListener(_onVideoTick);
    }
    super.dispose();
  }
}
