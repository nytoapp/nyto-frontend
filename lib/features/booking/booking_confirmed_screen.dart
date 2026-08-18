import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:nyto_app/core/theme/app_theme.dart';
import 'package:nyto_app/features/booking/booking_detail_screen.dart';
import 'package:nyto_app/features/home/home_screen.dart';

/// Brief success splash after payment completes.
class BookingConfirmedScreen extends StatefulWidget {
  const BookingConfirmedScreen({
    super.key,
    required this.table,
    required this.bookingId,
    required this.amountPaid,
  });

  final UpcomingTable table;
  final String bookingId;
  final int amountPaid;

  @override
  State<BookingConfirmedScreen> createState() => _BookingConfirmedScreenState();
}

class _BookingConfirmedScreenState extends State<BookingConfirmedScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _scale;
  late final Animation<double> _fade;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _scale = Tween<double>(begin: 0.6, end: 1.0).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.elasticOut),
    );
    _fade = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);
    _ctrl.forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  String _formatInr(int amount) {
    final raw = amount.toString();
    if (raw.length <= 3) return '₹$raw';
    final head = raw.substring(0, raw.length - 3);
    final tail = raw.substring(raw.length - 3);
    return '₹$head,$tail';
  }

  void _viewBooking() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute<void>(
        builder: (_) => BookingDetailScreen(
          table: widget.table,
          bookingId: widget.bookingId,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: NytoColors.bg,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28),
          child: Column(
            children: [
              const Spacer(flex: 3),
              FadeTransition(
                opacity: _fade,
                child: ScaleTransition(
                  scale: _scale,
                  child: Container(
                    width: 88,
                    height: 88,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          NytoColors.ctaSoft.withValues(alpha: 0.25),
                          NytoColors.cta.withValues(alpha: 0.15),
                        ],
                      ),
                    ),
                    child: const Icon(
                      Icons.check_rounded,
                      size: 48,
                      color: NytoColors.ctaSoft,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 28),
              FadeTransition(
                opacity: _fade,
                child: Text(
                  "You're in.",
                  style: GoogleFonts.fraunces(
                    fontSize: 34,
                    fontWeight: FontWeight.w400,
                    color: NytoColors.cream,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              FadeTransition(
                opacity: _fade,
                child: Text(
                  '${_formatInr(widget.amountPaid)} paid · ${widget.table.area}',
                  style: GoogleFonts.dmSans(
                    fontSize: 15,
                    color: NytoColors.creamMuted,
                  ),
                ),
              ),
              const SizedBox(height: 6),
              FadeTransition(
                opacity: _fade,
                child: Text(
                  '${widget.table.dateLabel} · ${widget.table.timeLabel}',
                  style: GoogleFonts.dmSans(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: NytoColors.cream,
                  ),
                ),
              ),
              const Spacer(flex: 4),
              FadeTransition(
                opacity: _fade,
                child: SizedBox(
                  width: double.infinity,
                  height: 54,
                  child: ElevatedButton(
                    onPressed: _viewBooking,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: NytoColors.cta,
                      foregroundColor: NytoColors.cream,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      textStyle: GoogleFonts.dmSans(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    child: const Text('View your booking'),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              FadeTransition(
                opacity: _fade,
                child: TextButton(
                  onPressed: () {
                    Navigator.of(context).pushAndRemoveUntil(
                      MaterialPageRoute<void>(
                        builder: (_) => const HomeScreen(),
                      ),
                      (_) => false,
                    );
                  },
                  child: Text(
                    'Back to Home',
                    style: GoogleFonts.dmSans(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: NytoColors.ctaSoft,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}
