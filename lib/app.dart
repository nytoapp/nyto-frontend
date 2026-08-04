import 'package:flutter/material.dart';
import 'package:nyto_app/core/theme/app_theme.dart';
import 'package:nyto_app/features/auth/welcome_screen.dart';
import 'package:nyto_app/features/splash/splash_screen.dart';

class NytoApp extends StatefulWidget {
  const NytoApp({super.key});

  @override
  State<NytoApp> createState() => _NytoAppState();
}

class _NytoAppState extends State<NytoApp> with WidgetsBindingObserver {
  final GlobalKey<NavigatorState> _navKey = GlobalKey<NavigatorState>();

  /// Sticky — Android often does paused → inactive → resumed.
  bool _wasBackground = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.hidden ||
        state == AppLifecycleState.detached) {
      _wasBackground = true;
      return;
    }

    // Warm re-open from home/drawer: Flutter splash beat (cold start uses native overlay).
    if (state == AppLifecycleState.resumed && _wasBackground) {
      _wasBackground = false;
      _navKey.currentState?.pushAndRemoveUntil(
        PageRouteBuilder<void>(
          pageBuilder: (_, __, ___) => const SplashScreen(),
          transitionDuration: Duration.zero,
        ),
        (_) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'NYTO',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.dark,
      navigatorKey: _navKey,
      // Cold start: native overlay shows wordmark; Flutter starts on Welcome underneath.
      home: const WelcomeScreen(),
    );
  }
}
