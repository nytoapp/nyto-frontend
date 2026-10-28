import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:nyto_app/core/api/nyto_api.dart';
import 'package:nyto_app/core/theme/app_theme.dart';
import 'package:nyto_app/features/table/table_chat_screen.dart';

/// Table reveal (~24h before) — live mates/menu/countdown from `/bookings/:id/reveal`.
class TableRevealScreen extends StatefulWidget {
  const TableRevealScreen({
    super.key,
    required this.bookingId,
    this.tableId,
    this.venueName = 'Your table',
  });

  final String bookingId;
  final String? tableId;
  final String venueName;

  @override
  State<TableRevealScreen> createState() => _TableRevealScreenState();
}

class _TableRevealScreenState extends State<TableRevealScreen> {
  Duration _remaining = Duration.zero;
  Timer? _timer;
  bool _loading = true;
  String? _error;
  Map<String, dynamic>? _reveal;
  bool _pressed = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final res = await bookingsApi.reveal(widget.bookingId);
      final reveal = res['reveal'];
      if (reveal is! Map<String, dynamic>) {
        throw Exception('Reveal payload missing');
      }
      final ms = (reveal['msUntilStart'] as num?)?.toInt() ?? 0;
      if (!mounted) return;
      setState(() {
        _reveal = reveal;
        _remaining = Duration(milliseconds: ms.clamp(0, 1 << 31));
        _loading = false;
      });
      _timer?.cancel();
      _timer = Timer.periodic(const Duration(seconds: 1), (_) {
        if (!mounted) return;
        if (_remaining.inSeconds <= 0) return;
        setState(() => _remaining -= const Duration(seconds: 1));
      });
    } catch (err) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = err.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  String get _countdown {
    final h = _remaining.inHours.toString().padLeft(2, '0');
    final m = (_remaining.inMinutes % 60).toString().padLeft(2, '0');
    final s = (_remaining.inSeconds % 60).toString().padLeft(2, '0');
    return '$h:$m:$s';
  }

  String? get _tableId =>
      (_reveal?['tableId'] as String?) ?? widget.tableId;

  bool get _revealed => _reveal?['revealed'] == true;

  List<String> get _mates {
    final raw = _reveal?['mates'];
    if (raw is! List) return const [];
    return raw
        .map((e) {
          if (e is Map && e['label'] is String) return e['label'] as String;
          return null;
        })
        .whereType<String>()
        .toList();
  }

  List<String> get _courses {
    final menu = _reveal?['menu'];
    if (menu is! Map) return const [];
    final courses = menu['courses'];
    if (courses is! List) return const [];
    return courses.whereType<String>().toList();
  }

  String get _venueTitle {
    final venue = _reveal?['venue'];
    if (venue is Map && venue['name'] is String) {
      return venue['name'] as String;
    }
    return widget.venueName;
  }

  String get _venueSub {
    final venue = _reveal?['venue'];
    if (venue is! Map) return '';
    final area = venue['area'] as String? ?? '';
    final city = venue['city'] as String? ?? '';
    return [area, city].where((s) => s.trim().isNotEmpty).join(' · ');
  }

  String get _statusBadge =>
      (_reveal?['bookingStatus'] as String?) ?? 'CONFIRMED';

  void _openChat() {
    final id = _tableId;
    if (id == null || id.isEmpty) return;
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => TableChatScreen(
          tableId: id,
          venueName: _venueTitle,
        ),
      ),
    );
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
                    style: GoogleFonts.dmSerifDisplay(
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
                        _remaining.inSeconds > 0 ? 'STARTS IN' : 'STARTED',
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
              child: _loading
                  ? const Center(
                      child: CircularProgressIndicator(color: NytoColors.cta),
                    )
                  : _error != null
                      ? Center(
                          child: Padding(
                            padding: const EdgeInsets.all(24),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  _error!,
                                  textAlign: TextAlign.center,
                                  style: GoogleFonts.dmSans(
                                    color: NytoColors.creamMuted,
                                  ),
                                ),
                                const SizedBox(height: 16),
                                TextButton(
                                  onPressed: _load,
                                  child: const Text('Retry'),
                                ),
                              ],
                            ),
                          ),
                        )
                      : SingleChildScrollView(
                          padding: const EdgeInsets.fromLTRB(24, 28, 24, 16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _revealed
                                    ? 'Your table is ready.'
                                    : 'Reveal opens closer to dinner.',
                                style: GoogleFonts.dmSerifDisplay(
                                  fontSize: 32,
                                  fontWeight: FontWeight.w400,
                                  color: NytoColors.cream,
                                ),
                              ),
                              const SizedBox(height: 10),
                              Text(
                                _revealed
                                    ? 'Strangers at one fixed menu. Tonight.'
                                    : 'Mates unlock within 24 hours of start.',
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
                                    color: NytoColors.cream
                                        .withValues(alpha: 0.08),
                                  ),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Expanded(
                                          child: Text(
                                            _venueTitle,
                                            style: GoogleFonts.dmSerifDisplay(
                                              fontSize: 24,
                                              color: NytoColors.cream,
                                            ),
                                          ),
                                        ),
                                        Text(
                                          _statusBadge,
                                          style: GoogleFonts.dmSans(
                                            fontSize: 10,
                                            fontWeight: FontWeight.w700,
                                            letterSpacing: 0.8,
                                            color: const Color(0xFFC8D9CE),
                                          ),
                                        ),
                                      ],
                                    ),
                                    if (_venueSub.isNotEmpty) ...[
                                      const SizedBox(height: 8),
                                      Text(
                                        _venueSub,
                                        style: GoogleFonts.dmSans(
                                          fontSize: 13,
                                          color: NytoColors.creamMuted,
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                              const SizedBox(height: 28),
                              Text(
                                'FIXED MENU',
                                style: GoogleFonts.dmSans(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: 1.4,
                                  color: NytoColors.creamMuted,
                                ),
                              ),
                              const SizedBox(height: 14),
                              if (_courses.isEmpty)
                                Text(
                                  (_reveal?['menu'] is Map
                                          ? (_reveal!['menu']
                                              as Map)['name'] as String?
                                          : null) ??
                                      'Menu details land with the kitchen package.',
                                  style: GoogleFonts.dmSans(
                                    fontSize: 14,
                                    color: NytoColors.creamMuted,
                                  ),
                                )
                              else
                                ...List.generate(_courses.length, (i) {
                                  final line = _courses[i];
                                  return Padding(
                                    padding: EdgeInsets.only(
                                      bottom:
                                          i == _courses.length - 1 ? 0 : 12,
                                    ),
                                    child: Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Container(
                                          width: 3,
                                          height: 40,
                                          margin: const EdgeInsets.only(
                                            right: 14,
                                            top: 2,
                                          ),
                                          decoration: BoxDecoration(
                                            color: NytoColors.orange
                                                .withValues(
                                              alpha: i == 0 ? 1 : 0.4,
                                            ),
                                            borderRadius:
                                                BorderRadius.circular(2),
                                          ),
                                        ),
                                        Expanded(
                                          child: Text(
                                            line,
                                            style: GoogleFonts.dmSans(
                                              fontSize: 14,
                                              height: 1.35,
                                              color: NytoColors.cream,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                }),
                              const SizedBox(height: 28),
                              Text(
                                'TABLEMATES',
                                style: GoogleFonts.dmSans(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: 1.4,
                                  color: NytoColors.creamMuted,
                                ),
                              ),
                              const SizedBox(height: 12),
                              if (!_revealed)
                                Text(
                                  'Names unlock inside the 24-hour window.',
                                  style: GoogleFonts.dmSans(
                                    fontSize: 14,
                                    color: NytoColors.creamMuted,
                                  ),
                                )
                              else if (_mates.isEmpty)
                                Text(
                                  'You’re first at this table — more seats may fill.',
                                  style: GoogleFonts.dmSans(
                                    fontSize: 14,
                                    color: NytoColors.creamMuted,
                                  ),
                                )
                              else
                                ..._mates.map(
                                  (m) => Padding(
                                    padding: const EdgeInsets.only(bottom: 10),
                                    child: Text(
                                      m,
                                      style: GoogleFonts.dmSans(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w600,
                                        color: NytoColors.cream,
                                      ),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
            ),
            if (_tableId != null && _revealed)
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 20),
                child: GestureDetector(
                  onTapDown: (_) => setState(() => _pressed = true),
                  onTapUp: (_) {
                    setState(() => _pressed = false);
                    _openChat();
                  },
                  onTapCancel: () => setState(() => _pressed = false),
                  child: AnimatedScale(
                    scale: _pressed ? 0.98 : 1,
                    duration: const Duration(milliseconds: 120),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      decoration: BoxDecoration(
                        color: NytoColors.cta,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Text(
                        'Open table chat',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.dmSans(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
