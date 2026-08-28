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
      caption: 'Find something you want to do—or create it yourself.',
    ),
    WelcomeClipConfig(
      assetPath: 'assets/video/welcome_02.mp4',
      loopEnd: Duration(milliseconds: 7480),
      headline: 'Real people.\nReal plans.',
      caption: 'Verified guests, clear details — your table, your night.',
    ),
    WelcomeClipConfig(
      assetPath: 'assets/video/welcome_03.mp4',
      loopEnd: Duration(milliseconds: 7000),
      headline: 'You choose\nthe experience.',
      caption:
          'Dinner, workout, lunch, party, supper club—or whatever you want to bring to life.',
    ),
    WelcomeClipConfig(
      assetPath: 'assets/video/welcome_04.mp4',
      loopEnd: Duration(milliseconds: 7000),
      headline: 'Host it. Join it.\nBuild your people.',
      caption:
          'Pick the place, set the rules, choose the price, invite your crowd—and grow your community.',
    ),
  ];

  static const crossfadeDuration = Duration(milliseconds: 850);

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
      await controller
          .initialize()
          .timeout(const Duration(milliseconds: 4500));
      await controller.setLooping(false);
      await controller.setVolume(0);
      return controller;
    } catch (_) {
      return null;
    }
  }

  /// Warm every available clip in parallel; starts playback on clip 0.
  static Future<WelcomeCarouselSession?> createCarousel({
    VideoPlayerController? preloadedFirst,
    String? preloadedAssetPath,
  }) async {
    final available = await availableClips();
    if (available.isEmpty) return null;

    final controllers = <VideoPlayerController>[];
    try {
      for (var i = 0; i < available.length; i++) {
        final clip = available[i];
        final reuse = i == 0 &&
            preloadedFirst != null &&
            preloadedFirst.value.isInitialized &&
            (preloadedAssetPath == null ||
                preloadedAssetPath == clip.assetPath);
        if (reuse) {
          controllers.add(preloadedFirst);
          continue;
        }
        final controller = await _initController(clip.assetPath);
        if (controller == null) {
          await _disposeAll(controllers, keep: preloadedFirst);
          return null;
        }
        controllers.add(controller);
      }

      await controllers.first.play();
      return WelcomeCarouselSession(
        clips: available,
        controllers: controllers,
      );
    } catch (_) {
      await _disposeAll(controllers, keep: preloadedFirst);
      return null;
    }
  }

  static Future<void> _disposeAll(
    List<VideoPlayerController> controllers, {
    VideoPlayerController? keep,
  }) async {
    for (final c in controllers) {
      if (c != keep) {
        await c.dispose();
      }
    }
  }
}

/// Drives clip playback → soft crossfade → next clip (loops).
class WelcomeCarouselController {
  WelcomeCarouselController({
    required this.session,
    required TickerProvider vsync,
  }) : _clips = session.clips,
       _controllers = session.controllers {
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
  }

  final WelcomeCarouselSession session;
  final List<WelcomeClipConfig> _clips;
  final List<VideoPlayerController> _controllers;

  late final AnimationController _crossfade;
  late final Animation<double> _crossfadeCurve;

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

  void _onCrossfadeStatus(AnimationStatus status) {
    if (status == AnimationStatus.completed) {
      _finishCrossfade();
    }
  }

  void _onVideoTick() {
    if (_isTransitioning || _singleRestarting) return;
    if (_controllers.length == 1) {
      _watchSingleClip(_controllers[0], _clips[0].loopEnd);
      return;
    }
    _watchSingleClip(_controllers[_activeIndex], _clips[_activeIndex].loopEnd);
  }

  void _watchSingleClip(VideoPlayerController controller, Duration loopEnd) {
    if (!controller.value.isInitialized) return;
    final pos = controller.value.position;
    final hitClipEnd = pos >= loopEnd;
    final hitFileEnd = controller.value.duration > Duration.zero &&
        pos >= controller.value.duration - const Duration(milliseconds: 80);
    if (hitClipEnd || hitFileEnd) {
      unawaited(_advance());
    } else if (!controller.value.isPlaying &&
        pos < loopEnd - const Duration(milliseconds: 200)) {
      controller.play();
    }
  }

  Future<void> _advance() async {
    if (_isTransitioning || _singleRestarting) return;

    if (_clips.length == 1) {
      await _restartSingle(_controllers[0]);
      return;
    }

    _isTransitioning = true;
    _incomingIndex = (_activeIndex + 1) % _clips.length;
    final incoming = _controllers[_incomingIndex];

    try {
      await incoming.seekTo(Duration.zero);
      await incoming.play();
      await _crossfade.forward(from: 0);
    } catch (_) {
      _isTransitioning = false;
      _crossfade.value = 0;
      await _restartSingle(_controllers[_activeIndex]);
    }
  }

  Future<void> _restartSingle(VideoPlayerController controller) async {
    if (_singleRestarting || !controller.value.isInitialized) return;
    _singleRestarting = true;
    try {
      await controller.seekTo(Duration.zero);
      await controller.play();
    } catch (_) {
      // Ignore seek races on low-end GPUs.
    } finally {
      _singleRestarting = false;
    }
  }

  void _finishCrossfade() {
    final outgoing = _controllers[_activeIndex];
    outgoing.pause();
    unawaited(outgoing.seekTo(Duration.zero));

    _activeIndex = _incomingIndex;
    _isTransitioning = false;
    _crossfade.value = 0;
  }

  void resumePlayback() {
    final active = _controllers[_activeIndex];
    if (active.value.isInitialized && !active.value.isPlaying) {
      active.play();
    }
  }

  void dispose() {
    _crossfade.dispose();
    for (final c in _controllers) {
      c.removeListener(_onVideoTick);
    }
  }
}