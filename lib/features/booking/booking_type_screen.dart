import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:nyto_app/core/api/nyto_api.dart';
import 'package:nyto_app/core/theme/app_theme.dart';
import 'package:nyto_app/core/widgets/nyto_glass.dart';
import 'package:nyto_app/domain/table.dart';
import 'package:nyto_app/features/booking/invite_friends_screen.dart';
import 'package:nyto_app/features/booking/table_profile_screen.dart';
import 'package:nyto_app/features/verification/verify_identity_hub_screen.dart';

/// How are you booking? — options depend on table type.
class BookingTypeScreen extends StatefulWidget {
  const BookingTypeScreen({super.key, required this.table});

  final UpcomingTable table;

  @override
  State<BookingTypeScreen> createState() => _BookingTypeScreenState();
}

class _BookingTypeScreenState extends State<BookingTypeScreen> {
  bool _pressed = false;
  bool _loading = false;
  late String _bookingType;
  late int _seats;

  @override
  void initState() {
    super.initState();
    final t = widget.table.tableType;
    if (t == NytoTableType.couples) {
      _bookingType = 'COUPLE';
      _seats = 2;
    } else {
      _bookingType = 'SOLO';
      _seats = 1;
    }
  }

  bool get _allowsGroup =>
      widget.table.tableType == NytoTableType.weekly ||
      widget.table.tableType == NytoTableType.womenLed;

  String get _headline {
    switch (widget.table.tableType) {
      case NytoTableType.couples:
        return 'Book as a couple';
      case NytoTableType.singles:
        return 'Book your seat';
      default:
        return 'How are you booking?';
    }
  }

  String get _subtitle {
    switch (widget.table.tableType) {
      case NytoTableType.couples:
        return 'One booking covers both of you — 2 seats on a table of 3 couples.';
      case NytoTableType.singles:
        return 'Solo only. Live mix aims for 3 women · 3 men.';
      case NytoTableType.womenLed:
        return 'Women-Led table. Solo or a small group of 2–3.';
      case NytoTableType.weekly:
        return 'Solo or a small group of 2–3. Friends can also join later.';
    }
  }

  Future<void> _continue() async {
    if (_loading) return;
    setState(() {
      _pressed = false;
      _loading = true;
    });

    final verified = await openVerificationGate(
      context,
      reason: 'Verify before you reserve — so everyone at the table is real.',
    );
    if (!mounted) return;
    if (!verified) {
      setState(() => _loading = false);
      return;
    }

    if (!await _ensureTableProfile()) {
      if (!mounted) return;
      setState(() => _loading = false);
      return;
    }

    await _createBooking();
  }

  Future<bool> _ensureTableProfile() async {
    try {
      final me = await authApi.me().timeout(const Duration(seconds: 8));
      final raw = me['user'];
      final user = raw is Map ? raw.cast<String, dynamic>() : null;
      if (tableProfileComplete(user, widget.table.tableType)) return true;
    } catch (_) {
      // Still ask — matching needs these answers.
    }
    if (!mounted) return false;

    final saved = await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
        builder: (_) => TableProfileScreen(table: widget.table),
      ),
    );
    return saved == true;
  }

  Future<void> _createBooking() async {
    const gstRate = 0.05;
    late String bookingId;
    final seatSubtotal = widget.table.priceInr * _seats;
    final gst = (seatSubtotal * gstRate).round();
    var total = seatSubtotal + gst;
    var sub = seatSubtotal;
    var gstAmt = gst;

    try {
      final res = await bookingsApi
          .create(
            tableId: widget.table.id,
            bookingType: _bookingType,
            seatsBooked: _seats,
          )
          .timeout(const Duration(seconds: 8));
      final booking = res['booking'] as Map<String, dynamic>?;
      final pricing = res['pricing'] as Map<String, dynamic>?;
      final id = booking?['id'];
      if (id is! String || id.isEmpty) {
        throw StateError('Missing booking id');
      }
      bookingId = id;
      if (pricing != null) {
        sub = pricing['seatSubtotal'] as int? ?? sub;
        gstAmt = pricing['gst'] as int? ?? gstAmt;
        total = pricing['total'] as int? ?? total;
      }
    } catch (_) {
      if (!mounted) return;
      setState(() => _loading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not create booking. Try again.'),
          backgroundColor: NytoColors.surface,
        ),
      );
      return;
    }

    if (!mounted) return;
    setState(() => _loading = false);
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => InviteFriendsScreen(
          table: widget.table,
          bookingId: bookingId,
          seatSubtotal: sub,
          gst: gstAmt,
          total: total,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = widget.table;
    return Scaffold(
      backgroundColor: NytoColors.bg,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 12, 24, 0),
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
                    'NYTO',
                    style: GoogleFonts.fraunces(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: NytoColors.cta,
                      letterSpacing: 3.5,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(28, 20, 28, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _headline,
                      style: GoogleFonts.fraunces(
                        fontSize: 30,
                        fontWeight: FontWeight.w400,
                        color: NytoColors.cream,
                        height: 1.2,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      _subtitle,
                      style: GoogleFonts.dmSans(
                        fontSize: 14,
                        color: NytoColors.creamMuted,
                        height: 1.45,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${t.tableTypeLabel} · ${t.weekday} ${t.dateLabel} · ${t.timeLabel} · ${t.area}',
                      style: GoogleFonts.dmSans(
                        fontSize: 12,
                        color: NytoColors.cream.withValues(alpha: 0.45),
                      ),
                    ),
                    if (t.tableType == NytoTableType.singles) ...[
                      const SizedBox(height: 12),
                      Text(
                        t.seatMixLabel,
                        style: GoogleFonts.dmSans(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: NytoColors.ctaSoft,
                        ),
                      ),
                    ],
                    const SizedBox(height: 22),
                    if (_allowsGroup) ...[
                      _OptionCard(
                        selected: _bookingType == 'SOLO',
                        title: 'Solo',
                        subtitle: '1 seat · matched into a table of 6',
                        price: '₹${t.priceInr}',
                        onTap: () => setState(() {
                          _bookingType = 'SOLO';
                          _seats = 1;
                        }),
                      ),
                      const SizedBox(height: 10),
                      _OptionCard(
                        selected: _bookingType == 'GROUP' && _seats == 2,
                        title: 'Group of 2',
                        subtitle: 'You book 2 seats together',
                        price: '₹${t.priceInr * 2}',
                        onTap: () => setState(() {
                          _bookingType = 'GROUP';
                          _seats = 2;
                        }),
                      ),
                      const SizedBox(height: 10),
                      _OptionCard(
                        selected: _bookingType == 'GROUP' && _seats == 3,
                        title: 'Group of 3',
                        subtitle: 'You book 3 seats together',
                        price: '₹${t.priceInr * 3}',
                        onTap: () => setState(() {
                          _bookingType = 'GROUP';
                          _seats = 3;
                        }),
                      ),
                    ] else if (t.tableType == NytoTableType.couples)
                      _OptionCard(
                        selected: true,
                        title: '1 couple',
                        subtitle: '2 seats · pair on a table of 3 couples',
                        price: '₹${t.priceInr * 2}',
                        onTap: () {},
                      )
                    else
                      _OptionCard(
                        selected: true,
                        title: 'Your seat',
                        subtitle: '1 seat · Singles table of 6',
                        price: '₹${t.priceInr}',
                        onTap: () {},
                      ),
                  ],
                ),
              ),
            ),
            Container(
              height: 1,
              margin: const EdgeInsets.symmetric(horizontal: 28),
              color: NytoColors.cream.withValues(alpha: 0.08),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(28, 16, 28, 24),
              child: GestureDetector(
                onTap: _loading ? null : _continue,
                onTapDown:
                    _loading ? null : (_) => setState(() => _pressed = true),
                onTapCancel:
                    _loading ? null : () => setState(() => _pressed = false),
                child: AnimatedScale(
                  scale: _pressed ? 0.98 : 1,
                  duration: const Duration(milliseconds: 90),
                  child: Container(
                    width: double.infinity,
                    height: 54,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: NytoColors.cta,
                      borderRadius: BorderRadius.circular(28),
                    ),
                    child: _loading
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.2,
                              color: Colors.white,
                            ),
                          )
                        : Text(
                            'Continue',
                            style: GoogleFonts.dmSans(
                              fontSize: 16,
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

class _OptionCard extends StatelessWidget {
  const _OptionCard({
    required this.selected,
    required this.title,
    required this.subtitle,
    required this.price,
    required this.onTap,
  });

  final bool selected;
  final String title;
  final String subtitle;
  final String price;
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
          selected: selected,
          padding: const EdgeInsets.all(18),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.dmSans(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: NytoColors.cream,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: GoogleFonts.dmSans(
                        fontSize: 13,
                        color: NytoColors.creamMuted,
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                price,
                style: GoogleFonts.fraunces(
                  fontSize: 20,
                  color: NytoColors.cream,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
