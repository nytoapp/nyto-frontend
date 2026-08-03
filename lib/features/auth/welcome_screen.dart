import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:nyto_app/core/theme/app_theme.dart';
import 'package:nyto_app/features/auth/sign_in_screen.dart';
import 'package:nyto_app/features/auth/sign_up_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:video_player/video_player.dart';

/// Screen 2 — cinematic welcome (video or stills), language, NYTO CTAs.
class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> {
  static const _prefsKey = 'nyto_language_code';
  static const _stills = <String>[
    'assets/video/welcome_01.jpg',
    'assets/video/welcome_02.jpg',
    'assets/video/welcome_03.jpg',
    'assets/video/welcome_04.jpg',
    'assets/video/welcome_05.jpg',
  ];

  VideoPlayerController? _video;
  bool _useVideo = false;
  int _stillIndex = 0;
  Timer? _stillTimer;
  String _languageCode = 'en';

  static const _languages = <_NytoLanguage>[
    _NytoLanguage('en', 'English', '🇺🇸 🇬🇧'),
    _NytoLanguage('hi', 'हिन्दी', '🇮🇳'),
    _NytoLanguage('te', 'తెలుగు', '🇮🇳'),
    _NytoLanguage('ta', 'தமிழ்', '🇮🇳'),
    _NytoLanguage('kn', 'ಕನ್ನಡ', '🇮🇳'),
    _NytoLanguage('mr', 'मराठी', '🇮🇳'),
  ];

  @override
  void initState() {
    super.initState();
    _loadLanguage();
    _bootMedia();
  }

  Future<void> _loadLanguage() async {
    final prefs = await SharedPreferences.getInstance();
    final code = prefs.getString(_prefsKey) ?? 'en';
    if (!mounted) return;
    setState(() => _languageCode = code);
  }

  Future<void> _bootMedia() async {
    // Prefer a real loop when the asset exists; otherwise cinematic stills.
    try {
      final controller =
          VideoPlayerController.asset('assets/video/welcome_loop.mp4');
      await controller.initialize();
      await controller.setLooping(true);
      await controller.setVolume(0);
      await controller.play();
      if (!mounted) {
        await controller.dispose();
        return;
      }
      setState(() {
        _video = controller;
        _useVideo = true;
      });
      return;
    } catch (_) {
      // Asset not bundled yet — fall through to stills.
    }
    _startStillLoop();
  }

  void _startStillLoop() {
    _stillTimer?.cancel();
    _stillTimer = Timer.periodic(const Duration(seconds: 4), (_) {
      if (!mounted || _useVideo) return;
      setState(() => _stillIndex = (_stillIndex + 1) % _stills.length);
    });
  }

  Future<void> _saveLanguage(String code) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefsKey, code);
    if (!mounted) return;
    setState(() => _languageCode = code);
  }

  void _openLanguageSheet() {
    var draft = _languageCode;
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModal) {
            return Container(
              height: MediaQuery.of(context).size.height * 0.82,
              decoration: const BoxDecoration(
                color: Color(0xFFF4F0EA),
                borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
              ),
              child: Column(
                children: [
                  const SizedBox(height: 10),
                  Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(99),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 14, 8, 8),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            'Language',
                            style: GoogleFonts.dmSans(
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                              color: Colors.black87,
                            ),
                          ),
                        ),
                        IconButton(
                          onPressed: () => Navigator.pop(context),
                          icon: const Icon(Icons.close_rounded),
                          color: Colors.black54,
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: ListView.separated(
                      padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
                      itemCount: _languages.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 10),
                      itemBuilder: (context, index) {
                        final lang = _languages[index];
                        final selected = draft == lang.code;
                        return Material(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(18),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(18),
                            onTap: () => setModal(() => draft = lang.code),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 180),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 16,
                              ),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(18),
                                border: Border.all(
                                  color: selected
                                      ? Colors.black
                                      : Colors.black.withValues(alpha: 0.08),
                                  width: selected ? 2 : 1,
                                ),
                              ),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      '${lang.label}  ${lang.flags}',
                                      style: GoogleFonts.dmSans(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.black87,
                                      ),
                                    ),
                                  ),
                                  Icon(
                                    selected
                                        ? Icons.radio_button_checked_rounded
                                        : Icons.radio_button_off_rounded,
                                    color: selected
                                        ? Colors.black
                                        : Colors.black38,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  SafeArea(
                    top: false,
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                      child: SizedBox(
                        width: double.infinity,
                        height: 54,
                        child: FilledButton(
                          style: FilledButton.styleFrom(
                            backgroundColor: Colors.black,
                            foregroundColor: Colors.white,
                            shape: const StadiumBorder(),
                          ),
                          onPressed: () async {
                            await _saveLanguage(draft);
                            if (context.mounted) Navigator.pop(context);
                          },
                          child: Text(
                            'Confirm',
                            style: GoogleFonts.dmSans(
                              fontWeight: FontWeight.w700,
                              fontSize: 16,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _goSignUp() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => const SignUpScreen()),
    );
  }

  void _goSignIn() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => const SignInScreen()),
    );
  }

  @override
  void dispose() {
    _stillTimer?.cancel();
    _video?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: NytoColors.brandInk,
      body: Stack(
        fit: StackFit.expand,
        children: [
          _MediaBackdrop(
            useVideo: _useVideo,
            video: _video,
            stills: _stills,
            stillIndex: _stillIndex,
          ),
          const _BottomScrim(),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Align(
                    alignment: Alignment.topRight,
                    child: _GlobeButton(onTap: _openLanguageSheet),
                  ),
                  const Spacer(),
                  Text(
                    "You've been invited to dinner.",
                    textAlign: TextAlign.center,
                    style: GoogleFonts.fraunces(
                      fontSize: 34,
                      fontWeight: FontWeight.w500,
                      height: 1.15,
                      color: NytoColors.cream,
                      shadows: [
                        Shadow(
                          color: Colors.black.withValues(alpha: 0.55),
                          blurRadius: 18,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Verified strangers. A paid seat. Nothing left to figure out.',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.dmSans(
                      fontSize: 14,
                      height: 1.45,
                      color: NytoColors.cream.withValues(alpha: 0.82),
                    ),
                  ),
                  const SizedBox(height: 28),
                  _PrimaryCta(
                    label: 'Find your table',
                    onTap: _goSignUp,
                  ),
                  const SizedBox(height: 12),
                  _SecondaryCta(
                    label: 'Already on NYTO? Sign in',
                    onTap: _goSignIn,
                  ),
                  const SizedBox(height: 18),
                  Text.rich(
                    TextSpan(
                      text: 'By continuing you agree to the ',
                      style: GoogleFonts.dmSans(
                        fontSize: 11,
                        height: 1.45,
                        color: NytoColors.cream.withValues(alpha: 0.7),
                      ),
                      children: [
                        TextSpan(
                          text: 'Terms',
                          style: GoogleFonts.dmSans(
                            fontSize: 11,
                            decoration: TextDecoration.underline,
                            color: NytoColors.cream,
                          ),
                        ),
                        const TextSpan(text: ', '),
                        TextSpan(
                          text: 'Privacy Policy',
                          style: GoogleFonts.dmSans(
                            fontSize: 11,
                            decoration: TextDecoration.underline,
                            color: NytoColors.cream,
                          ),
                        ),
                        const TextSpan(text: ' & '),
                        TextSpan(
                          text: 'Community Guidelines',
                          style: GoogleFonts.dmSans(
                            fontSize: 11,
                            decoration: TextDecoration.underline,
                            color: NytoColors.cream,
                          ),
                        ),
                        const TextSpan(text: '.'),
                      ],
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _NytoLanguage {
  const _NytoLanguage(this.code, this.label, this.flags);
  final String code;
  final String label;
  final String flags;
}

class _MediaBackdrop extends StatelessWidget {
  const _MediaBackdrop({
    required this.useVideo,
    required this.video,
    required this.stills,
    required this.stillIndex,
  });

  final bool useVideo;
  final VideoPlayerController? video;
  final List<String> stills;
  final int stillIndex;

  @override
  Widget build(BuildContext context) {
    if (useVideo && video != null && video!.value.isInitialized) {
      return FittedBox(
        fit: BoxFit.cover,
        clipBehavior: Clip.hardEdge,
        child: SizedBox(
          width: video!.value.size.width,
          height: video!.value.size.height,
          child: VideoPlayer(video!),
        ),
      );
    }

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 900),
      switchInCurve: Curves.easeInOut,
      switchOutCurve: Curves.easeInOut,
      child: Image.asset(
        stills[stillIndex],
        key: ValueKey(stills[stillIndex]),
        fit: BoxFit.cover,
        width: double.infinity,
        height: double.infinity,
      ),
    );
  }
}

class _BottomScrim extends StatelessWidget {
  const _BottomScrim();

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.transparent,
              NytoColors.brandInk.withValues(alpha: 0.15),
              NytoColors.brandInk.withValues(alpha: 0.72),
              NytoColors.brandInk.withValues(alpha: 0.94),
            ],
            stops: const [0.35, 0.52, 0.74, 1],
          ),
        ),
      ),
    );
  }
}

class _GlobeButton extends StatelessWidget {
  const _GlobeButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white.withValues(alpha: 0.92),
      shape: const CircleBorder(),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: const SizedBox(
          width: 44,
          height: 44,
          child: Icon(Icons.public_rounded, color: Colors.black87, size: 22),
        ),
      ),
    );
  }
}

class _PrimaryCta extends StatelessWidget {
  const _PrimaryCta({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 56,
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(999),
          gradient: const LinearGradient(
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
            colors: [
              NytoColors.brandViolet,
              NytoColors.brandMagenta,
              NytoColors.brandPink,
            ],
          ),
          boxShadow: [
            BoxShadow(
              color: NytoColors.brandMagenta.withValues(alpha: 0.35),
              blurRadius: 22,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(999),
            onTap: onTap,
            child: Center(
              child: Text(
                label,
                style: GoogleFonts.dmSans(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                  letterSpacing: 0.2,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SecondaryCta extends StatelessWidget {
  const _SecondaryCta({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 56,
      child: Material(
        color: Colors.white.withValues(alpha: 0.12),
        shape: const StadiumBorder(
          side: BorderSide(color: Colors.white54),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Center(
            child: Text(
              label,
              style: GoogleFonts.dmSans(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: NytoColors.cream,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
