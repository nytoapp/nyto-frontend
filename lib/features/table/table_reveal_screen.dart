import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:nyto_app/core/theme/app_theme.dart';
import 'package:nyto_app/features/table/table_chat_screen.dart';

/// Table reveal (~24h before) — match `designs/Screenshot (3724–3726)`.
class TableRevealScreen extends StatefulWidget {
  const TableRevealScreen({super.key});

  @override
  State<TableRevealScreen> createState() => _TableRevealScreenState();
}

class _TableRevealScreenState extends State<TableRevealScreen> {
  static const _mates = [
    'Product Designer · Indiranagar',
    'Architect · Koramangala',
    'Writer & Podcaster · Bandra',
    'Investment Analyst · Church Street',
    'Restaurateur · Whitefield',
  ];

  static const _menu = [
    ('I FIRST', 'Burrata, heirloom tomato, aged balsamic.'),
    ('II SECOND', 'Sea bass, saffron beurre blanc, crisp fennel.'),
    ('III THIRD', 'Valrhona fondant, salted caramel, praline.'),
  ];

  static const _starters = [
    'What’s the last meal that genuinely surprised you?',
    'If you could eat anywhere in the world tomorrow — where?',
    'One food opinion you’d defend to the bitter end.',
  ];

  late Duration _remaining;
  Timer? _timer;
  bool _pressed = false;

  @override
  void initState() {
    super.initState();
    _remaining = const Duration(hours: 23, minutes: 39, seconds: 48);
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      if (_remaining.inSeconds <= 0) return;
      setState(() => _remaining -= const Duration(seconds: 1));
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  String get _countdown {
    final h = _remaining.inHours.toString().padLeft(2, '0');
    final m = (_remaining.inMinutes % 60).toString().padLeft(2, '0');
    final s = (_remaining.inSeconds % 60).toString().padLeft(2, '0');
    return '$h:$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: NytoColors.bg,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
              child: Row(
                children: [
                  Text(
                    'NYTO',
                    style: GoogleFonts.fraunces(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: NytoColors.orange,
                      letterSpacing: 3.5,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    'TABLE REVEAL',
                    style: GoogleFonts.dmSans(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      letterSpacing: 1.2,
                      color: NytoColors.creamMuted,
                    ),
                  ),
                  const Spacer(),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        'OPENS IN',
                        style: GoogleFonts.dmSans(
                          fontSize: 10,
                          letterSpacing: 1.1,
                          color: NytoColors.creamMuted,
                        ),
                      ),
                      Text(
                        _countdown,
                        style: GoogleFonts.jetBrainsMono(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: NytoColors.cream,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 28, 24, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Your table is ready.',
                      style: GoogleFonts.fraunces(
                        fontSize: 32,
                        fontWeight: FontWeight.w400,
                        color: NytoColors.cream,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Six strangers. One fixed menu. Tonight.',
                      style: GoogleFonts.dmSans(
                        fontSize: 14,
                        color: NytoColors.creamMuted,
                      ),
                    ),
                    const SizedBox(height: 28),
                    Text(
                      'VENUE',
                      style: GoogleFonts.dmSans(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 1.4,
                        color: NytoColors.creamMuted,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(18),
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
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  'Caperberry',
                                  style: GoogleFonts.fraunces(
                                    fontSize: 24,
                                    fontWeight: FontWeight.w400,
                                    color: NytoColors.cream,
                                  ),
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 5,
                                ),
                                decoration: BoxDecoration(
                                  color: NytoColors.moss.withValues(alpha: 0.25),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 6,
                                      height: 6,
                                      decoration: const BoxDecoration(
                                        color: Color(0xFF7CB88A),
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      'CONFIRMED',
                                      style: GoogleFonts.dmSans(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w700,
                                        letterSpacing: 0.8,
                                        color: const Color(0xFFC8D9CE),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Lavelle Road · Central Bengaluru',
                            style: GoogleFonts.dmSans(
                              fontSize: 13,
                              color: NytoColors.creamMuted,
                            ),
                          ),
                          const SizedBox(height: 14),
                          Text(
                            'Sat, 26 Jul  |  8:30 PM',
                            style: GoogleFonts.jetBrainsMono(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              color: NytoColors.orange,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 28),
                    Row(
                      children: [
                        Text(
                          'FIXED MENU',
                          style: GoogleFonts.dmSans(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 1.4,
                            color: NytoColors.creamMuted,
                          ),
                        ),
                        const Spacer(),
                        Container(
                          width: 8,
                          height: 8,
                          margin: const EdgeInsets.only(right: 6),
                          decoration: BoxDecoration(
                            color: NytoColors.moss,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                        Text(
                          'VEG / NON-VEG',
                          style: GoogleFonts.dmSans(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.8,
                            color: NytoColors.creamMuted,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    ...List.generate(_menu.length, (i) {
                      final item = _menu[i];
                      final primary = i == 0;
                      return Padding(
                        padding: EdgeInsets.only(
                          bottom: i == _menu.length - 1 ? 0 : 14,
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              width: 3,
                              height: 48,
                              margin: const EdgeInsets.only(right: 14, top: 2),
                              decoration: BoxDecoration(
                                color: NytoColors.orange.withValues(
                                  alpha: primary ? 1 : 0.4,
                                ),
                                borderRadius: BorderRadius.circular(2),
                              ),
                            ),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    item.$1,
                                    style: GoogleFonts.dmSans(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                      letterSpacing: 1.1,
                                      color: NytoColors.orange.withValues(
                                        alpha: primary ? 1 : 0.4,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    item.$2,
                                    style: GoogleFonts.fraunces(
                                      fontSize: 16,
                                      fontStyle: FontStyle.italic,
                                      fontWeight: FontWeight.w400,
                                      color: NytoColors.cream,
                                      height: 1.35,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                    const SizedBox(height: 28),
                    Row(
                      children: [
                        Text(
                          'YOUR TABLEMATES',
                          style: GoogleFonts.dmSans(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 1.4,
                            color: NytoColors.creamMuted,
                          ),
                        ),
                        const Spacer(),
                        Text(
                          '${_mates.length}',
                          style: GoogleFonts.dmSans(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: NytoColors.orange,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    ...List.generate(_mates.length, (i) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Row(
                          children: [
                            SizedBox(
                              width: 22,
                              child: Text(
                                '${i + 1}',
                                style: GoogleFonts.dmSans(
                                  fontSize: 13,
                                  color: NytoColors.creamMuted,
                                ),
                              ),
                            ),
                            Expanded(
                              child: Text(
                                _mates[i],
                                style: GoogleFonts.dmSans(
                                  fontSize: 14,
                                  color: NytoColors.cream,
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                    const SizedBox(height: 16),
                    Text(
                      'CONVERSATION STARTERS',
                      style: GoogleFonts.dmSans(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 1.4,
                        color: NytoColors.creamMuted,
                      ),
                    ),
                    const SizedBox(height: 12),
                    ...List.generate(_starters.length, (i) {
                      final primary = i == 0;
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: Container(
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: NytoColors.surface,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: IntrinsicHeight(
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Container(
                                  width: 3,
                                  decoration: BoxDecoration(
                                    color: NytoColors.orange.withValues(
                                      alpha: primary ? 1 : 0.4,
                                    ),
                                    borderRadius: const BorderRadius.horizontal(
                                      left: Radius.circular(12),
                                    ),
                                  ),
                                ),
                                Expanded(
                                  child: Padding(
                                    padding: const EdgeInsets.fromLTRB(
                                      14,
                                      14,
                                      14,
                                      14,
                                    ),
                                    child: Text(
                                      '“${_starters[i]}”',
                                      style: GoogleFonts.fraunces(
                                        fontSize: 15,
                                        fontStyle: FontStyle.italic,
                                        color: NytoColors.cream,
                                        height: 1.4,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    }),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
              child: Column(
                children: [
                  GestureDetector(
                    onTapDown: (_) => setState(() => _pressed = true),
                    onTapUp: (_) {
                      setState(() => _pressed = false);
                      Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => const TableChatScreen(),
                        ),
                      );
                    },
                    onTapCancel: () => setState(() => _pressed = false),
                    child: AnimatedScale(
                      scale: _pressed ? 0.98 : 1,
                      duration: const Duration(milliseconds: 90),
                      child: Container(
                        width: double.infinity,
                        height: 54,
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        decoration: BoxDecoration(
                          color: NytoColors.orange,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Row(
                          children: [
                            Text(
                              'Open table chat',
                              style: GoogleFonts.dmSans(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: NytoColors.cream,
                              ),
                            ),
                            const Spacer(),
                            const Icon(
                              Icons.arrow_forward,
                              size: 18,
                              color: NytoColors.cream,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Identities stay private until you choose otherwise.',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.dmSans(
                      fontSize: 12,
                      color: NytoColors.creamMuted,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
