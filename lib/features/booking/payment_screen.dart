import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:nyto_app/core/api/nyto_api.dart';
import 'package:nyto_app/core/theme/app_theme.dart';
import 'package:nyto_app/features/booking/booking_confirmed_screen.dart';
import 'package:nyto_app/features/home/home_screen.dart';

enum PayMethod { upi, card }

class PaymentScreen extends StatefulWidget {
  const PaymentScreen({
    super.key,
    required this.table,
    required this.seatCount,
    required this.bookingId,
    required this.seatSubtotal,
    required this.gst,
    required this.total,
  });

  final UpcomingTable table;
  final int seatCount;
  final String bookingId;
  final int seatSubtotal;
  final int gst;
  final int total;

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  PayMethod _method = PayMethod.upi;
  bool _pressed = false;
  bool _paying = false;

  // Card fields
  final _cardNumCtrl = TextEditingController();
  final _expiryCtrl = TextEditingController();
  final _cvvCtrl = TextEditingController();
  final _nameCtrl = TextEditingController();

  int get _seatSubtotal => widget.seatSubtotal;
  int get _gst => widget.gst;
  int get _total => widget.total;

  bool get _cardValid {
    final num = _cardNumCtrl.text.replaceAll(' ', '');
    final exp = _expiryCtrl.text;
    final cvv = _cvvCtrl.text;
    final name = _nameCtrl.text.trim();
    return num.length >= 15 &&
        exp.length == 5 &&
        cvv.length >= 3 &&
        name.isNotEmpty;
  }

  bool get _canPay {
    if (_method == PayMethod.card) return _cardValid;
    return true;
  }

  String get _payButtonLabel {
    if (_method == PayMethod.upi) return 'Continue with UPI';
    return 'Pay ${_formatInr(_total)}';
  }

  String get _payingLabel {
    if (_method == PayMethod.upi) return 'Opening payment…';
    return 'Processing…';
  }

  @override
  void dispose() {
    _cardNumCtrl.dispose();
    _expiryCtrl.dispose();
    _cvvCtrl.dispose();
    _nameCtrl.dispose();
    super.dispose();
  }

  Future<void> _pay() async {
    if (_paying || !_canPay) return;
    setState(() {
      _pressed = false;
      _paying = true;
    });

    try {
      if (!widget.bookingId.startsWith('demo-')) {
        await bookingsApi
            .pay(
              bookingId: widget.bookingId,
              method: _method == PayMethod.upi ? 'UPI' : 'CARD',
            )
            .timeout(const Duration(seconds: 2));
      }
    } catch (_) {
      // Demo / offline — continue UX path.
    }

    // Simulate processing delay
    await Future<void>.delayed(const Duration(milliseconds: 1200));
    if (!mounted) return;
    setState(() => _paying = false);

    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute<void>(
        builder: (_) => BookingConfirmedScreen(
          table: widget.table,
          bookingId: widget.bookingId,
          amountPaid: _total,
        ),
      ),
      (route) => route.isFirst,
    );
  }

  String _formatInr(int amount) {
    final raw = amount.toString();
    if (raw.length <= 3) return '₹$raw';
    final head = raw.substring(0, raw.length - 3);
    final tail = raw.substring(raw.length - 3);
    return '₹$head,$tail';
  }

  String get _dayLong {
    const map = {
      'Fri': 'Friday',
      'Sat': 'Saturday',
      'Sun': 'Sunday',
      'Wed': 'Wednesday',
      'Thu': 'Thursday',
      'Mon': 'Monday',
      'Tue': 'Tuesday',
    };
    return map[widget.table.weekday] ?? widget.table.weekday;
  }

  String get _slotShort =>
      widget.table.slot == MealSlot.daytimeLunch ? 'Daytime' : 'Evening';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: NytoColors.bg,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 24, 0),
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
            // Scrollable body
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(28, 16, 28, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'SEAT PAYMENT',
                      style: GoogleFonts.dmSans(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 1.6,
                        color: NytoColors.cta,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Pay for your seat.',
                      style: GoogleFonts.fraunces(
                        fontSize: 32,
                        fontWeight: FontWeight.w400,
                        color: NytoColors.cream,
                      ),
                    ),
                    const SizedBox(height: 24),
                    // Price summary
                    _buildPriceSummary(),
                    const SizedBox(height: 16),
                    // Prepaid notice
                    _buildPrepaidNotice(),
                    const SizedBox(height: 28),
                    // Method selector
                    Text(
                      'PAY VIA',
                      style: GoogleFonts.dmSans(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 1.4,
                        color: NytoColors.creamMuted,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: _PayMethodTile(
                            selected: _method == PayMethod.upi,
                            icon: Icons.smartphone_outlined,
                            title: 'UPI',
                            subtitle: 'GPay · PhonePe · Paytm',
                            onTap: () =>
                                setState(() => _method = PayMethod.upi),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _PayMethodTile(
                            selected: _method == PayMethod.card,
                            icon: Icons.credit_card,
                            title: 'Card',
                            subtitle: 'Debit · Credit',
                            onTap: () =>
                                setState(() => _method = PayMethod.card),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    // Card form or UPI picker
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 250),
                      child: _method == PayMethod.card
                          ? _buildCardForm()
                          : _buildUpiSection(),
                    ),
                  ],
                ),
              ),
            ),
            // Pay button
            _buildPayButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildPriceSummary() {
    return Container(
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
        children: [
          Row(
            children: [
              Container(
                width: 46,
                height: 46,
                alignment: Alignment.center,
                decoration: const BoxDecoration(
                  color: NytoColors.moss,
                  shape: BoxShape.circle,
                ),
                child: Text(
                  widget.table.weekday,
                  style: GoogleFonts.dmSans(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: NytoColors.cream,
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '$_dayLong · $_slotShort',
                      style: GoogleFonts.dmSans(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: NytoColors.cream,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Table for 6 · Matched strangers',
                      style: GoogleFonts.dmSans(
                        fontSize: 13,
                        color: NytoColors.creamMuted,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          _MoneyRow(
            label: 'Seat price × ${widget.seatCount}',
            value: _formatInr(_seatSubtotal),
          ),
          const SizedBox(height: 10),
          _MoneyRow(
            label: 'GST (5%)',
            value: _formatInr(_gst),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 14),
            child: Divider(
              height: 1,
              color: NytoColors.cream.withValues(alpha: 0.12),
            ),
          ),
          _MoneyRow(
            label: 'Total',
            value: _formatInr(_total),
            emphasize: true,
          ),
        ],
      ),
    );
  }

  Widget _buildPrepaidNotice() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: NytoColors.cta.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: NytoColors.cta.withValues(alpha: 0.45),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.lock_outline,
            size: 16,
            color: NytoColors.cta.withValues(alpha: 0.95),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Payment is prepaid and final. No pay-at-venue. No bill splitting.',
              style: GoogleFonts.dmSans(
                fontSize: 13,
                height: 1.45,
                color: NytoColors.ctaSoft,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCardForm() {
    return Column(
      key: const ValueKey('card'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'CARD DETAILS',
          style: GoogleFonts.dmSans(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            letterSpacing: 1.4,
            color: NytoColors.creamMuted,
          ),
        ),
        const SizedBox(height: 14),
        _CardField(
          controller: _cardNumCtrl,
          label: 'Card number',
          hint: '1234 5678 9012 3456',
          keyboard: TextInputType.number,
          formatters: [
            FilteringTextInputFormatter.digitsOnly,
            _CardNumberFormatter(),
            LengthLimitingTextInputFormatter(19),
          ],
          icon: Icons.credit_card,
          onChanged: (_) => setState(() {}),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _CardField(
                controller: _expiryCtrl,
                label: 'Expiry',
                hint: 'MM/YY',
                keyboard: TextInputType.number,
                formatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  _ExpiryFormatter(),
                  LengthLimitingTextInputFormatter(5),
                ],
                onChanged: (_) => setState(() {}),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _CardField(
                controller: _cvvCtrl,
                label: 'CVV',
                hint: '•••',
                keyboard: TextInputType.number,
                obscure: true,
                formatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(4),
                ],
                onChanged: (_) => setState(() {}),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        _CardField(
          controller: _nameCtrl,
          label: 'Name on card',
          hint: 'Full name',
          keyboard: TextInputType.name,
          textCap: TextCapitalization.words,
          onChanged: (_) => setState(() {}),
        ),
      ],
    );
  }

  Widget _buildUpiSection() {
    return Container(
      key: const ValueKey('upi'),
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: NytoColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: NytoColors.cream.withValues(alpha: 0.08),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.account_balance_wallet_outlined,
            size: 22,
            color: NytoColors.ctaSoft,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Pay with UPI',
                  style: GoogleFonts.dmSans(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: NytoColors.cream,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Continue to choose GPay, PhonePe, Paytm, or any UPI app on your phone. Razorpay handles this at launch.',
                  style: GoogleFonts.dmSans(
                    fontSize: 13,
                    height: 1.45,
                    color: NytoColors.creamMuted,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPayButton() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(28, 8, 28, 24),
      child: Column(
        children: [
          GestureDetector(
            onTapDown:
                (_paying || !_canPay) ? null : (_) => setState(() => _pressed = true),
            onTapUp: (_paying || !_canPay) ? null : (_) => _pay(),
            onTapCancel:
                (_paying || !_canPay) ? null : () => setState(() => _pressed = false),
            child: AnimatedScale(
              scale: _pressed ? 0.98 : 1,
              duration: const Duration(milliseconds: 90),
              child: AnimatedOpacity(
                duration: const Duration(milliseconds: 200),
                opacity: _canPay ? 1 : 0.4,
                child: Container(
                  width: double.infinity,
                  height: 54,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: NytoColors.cta,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: _paying
                      ? Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.2,
                                color: NytoColors.cream,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Text(
                              _payingLabel,
                              style: GoogleFonts.dmSans(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: NytoColors.cream,
                              ),
                            ),
                          ],
                        )
                      : Text(
                          _payButtonLabel,
                          style: GoogleFonts.dmSans(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: NytoColors.cream,
                          ),
                        ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Secured · Non-refundable',
            style: GoogleFonts.dmSans(
              fontSize: 12,
              color: NytoColors.creamMuted,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Reusable widgets ──────────────────────────────────────────────────────

class _MoneyRow extends StatelessWidget {
  const _MoneyRow({
    required this.label,
    required this.value,
    this.emphasize = false,
  });

  final String label;
  final String value;
  final bool emphasize;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          label,
          style: GoogleFonts.dmSans(
            fontSize: emphasize ? 16 : 14,
            fontWeight: emphasize ? FontWeight.w600 : FontWeight.w400,
            color: emphasize ? NytoColors.cream : NytoColors.creamMuted,
          ),
        ),
        const Spacer(),
        Text(
          value,
          style: GoogleFonts.jetBrainsMono(
            fontSize: emphasize ? 20 : 15,
            fontWeight: emphasize ? FontWeight.w600 : FontWeight.w500,
            color: NytoColors.cream,
          ),
        ),
      ],
    );
  }
}

class _PayMethodTile extends StatelessWidget {
  const _PayMethodTile({
    required this.selected,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final bool selected;
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          padding: const EdgeInsets.fromLTRB(14, 16, 14, 16),
          decoration: BoxDecoration(
            color: NytoColors.surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: selected
                  ? NytoColors.cta
                  : NytoColors.cream.withValues(alpha: 0.1),
              width: selected ? 1.4 : 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                icon,
                size: 22,
                color: selected ? NytoColors.cta : NytoColors.creamMuted,
              ),
              const SizedBox(height: 12),
              Text(
                title,
                style: GoogleFonts.dmSans(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: NytoColors.cream,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: GoogleFonts.dmSans(
                  fontSize: 11,
                  color: NytoColors.creamMuted,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CardField extends StatelessWidget {
  const _CardField({
    required this.controller,
    required this.label,
    required this.hint,
    this.keyboard = TextInputType.text,
    this.obscure = false,
    this.formatters = const [],
    this.icon,
    this.textCap = TextCapitalization.none,
    this.onChanged,
  });

  final TextEditingController controller;
  final String label;
  final String hint;
  final TextInputType keyboard;
  final bool obscure;
  final List<TextInputFormatter> formatters;
  final IconData? icon;
  final TextCapitalization textCap;
  final ValueChanged<String>? onChanged;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: keyboard,
      obscureText: obscure,
      textCapitalization: textCap,
      inputFormatters: formatters,
      onChanged: onChanged,
      style: GoogleFonts.jetBrainsMono(
        fontSize: 16,
        color: NytoColors.cream,
      ),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: GoogleFonts.dmSans(
          fontSize: 13,
          color: NytoColors.creamMuted,
        ),
        hintText: hint,
        hintStyle: GoogleFonts.jetBrainsMono(
          fontSize: 15,
          color: NytoColors.cream.withValues(alpha: 0.2),
        ),
        prefixIcon: icon != null
            ? Icon(icon, size: 20, color: NytoColors.creamMuted)
            : null,
        filled: true,
        fillColor: NytoColors.surface,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: NytoColors.cream.withValues(alpha: 0.1),
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: NytoColors.cream.withValues(alpha: 0.1),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: NytoColors.cta, width: 1.4),
        ),
      ),
    );
  }
}

/// Formats card number as `1234 5678 9012 3456`.
class _CardNumberFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final digits = newValue.text.replaceAll(' ', '');
    final buf = StringBuffer();
    for (var i = 0; i < digits.length; i++) {
      if (i > 0 && i % 4 == 0) buf.write(' ');
      buf.write(digits[i]);
    }
    final text = buf.toString();
    return TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
  }
}

/// Formats expiry as `MM/YY`.
class _ExpiryFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final digits = newValue.text.replaceAll('/', '');
    final buf = StringBuffer();
    for (var i = 0; i < digits.length && i < 4; i++) {
      if (i == 2) buf.write('/');
      buf.write(digits[i]);
    }
    final text = buf.toString();
    return TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
  }
}
