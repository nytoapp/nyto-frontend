import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:nyto_app/core/api/nyto_api.dart';
import 'package:nyto_app/core/theme/app_theme.dart';
import 'package:nyto_app/domain/table.dart';
import 'package:nyto_app/features/booking/booking_confirmed_screen.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';

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
  bool _loadingConfig = true;
  String _mode = 'stub'; // razorpay | stub
  String? _configError;

  Razorpay? _razorpay;
  Completer<PaymentSuccessResponse>? _checkoutCompleter;
  bool _checkoutSucceeded = false;

  int get _seatSubtotal => widget.seatSubtotal;
  int get _gst => widget.gst;
  int get _total => widget.total;

  bool get _isRazorpay => _mode == 'razorpay';

  bool get _canPay => !_loadingConfig && _configError == null;

  String get _payButtonLabel {
    if (_isRazorpay) return 'Pay ${_formatInr(_total)}';
    if (_method == PayMethod.upi) return 'Continue with UPI';
    return 'Pay ${_formatInr(_total)}';
  }

  String get _payingLabel {
    if (_isRazorpay) return 'Opening Razorpay…';
    if (_method == PayMethod.upi) return 'Opening payment…';
    return 'Processing…';
  }

  @override
  void initState() {
    super.initState();
    _loadPaymentConfig();
  }

  @override
  void dispose() {
    _razorpay?.clear();
    super.dispose();
  }

  Future<void> _loadPaymentConfig() async {
    try {
      final res = await bookingsApi
          .paymentConfig()
          .timeout(const Duration(seconds: 8));
      if (!mounted) return;
      setState(() {
        _mode = (res['mode'] as String?) ?? 'stub';
        _loadingConfig = false;
      });
      if (_mode == 'razorpay') {
        _razorpay = Razorpay();
        _razorpay!.on(Razorpay.EVENT_PAYMENT_SUCCESS, _onPaymentSuccess);
        _razorpay!.on(Razorpay.EVENT_PAYMENT_ERROR, _onPaymentError);
        _razorpay!.on(Razorpay.EVENT_EXTERNAL_WALLET, _onExternalWallet);
      }
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loadingConfig = false;
        _configError = 'Could not load payment settings';
      });
    }
  }

  void _onPaymentSuccess(PaymentSuccessResponse response) {
    if (_checkoutCompleter == null || _checkoutCompleter!.isCompleted) return;
    _checkoutSucceeded = true;
    _checkoutCompleter!.complete(response);
    _checkoutCompleter = null;
  }

  void _onPaymentError(PaymentFailureResponse response) {
    // Android often fires a cancel/error after a successful bank page.
    if (_checkoutSucceeded) return;
    if (_checkoutCompleter == null || _checkoutCompleter!.isCompleted) return;
    final code = response.code;
    final msg = response.message ?? 'Payment cancelled';
    // Ignore spurious dismiss codes when Success already processed.
    if (code == 2 || msg.toLowerCase().contains('cancelled')) {
      // Still treat as failure if we never got SUCCESS — but delay a beat
      // so a late SUCCESS can win the race.
      Future<void>.delayed(const Duration(milliseconds: 800), () {
        if (_checkoutSucceeded) return;
        if (_checkoutCompleter == null || _checkoutCompleter!.isCompleted) {
          return;
        }
        _checkoutCompleter!.completeError(StateError(msg));
        _checkoutCompleter = null;
      });
      return;
    }
    _checkoutCompleter!.completeError(StateError(msg));
    _checkoutCompleter = null;
  }

  void _onExternalWallet(ExternalWalletResponse response) {
    // No-op — user continues in wallet app; success/error still fire.
  }

  Future<void> _pay() async {
    if (_paying || !_canPay) return;
    setState(() {
      _pressed = false;
      _paying = true;
    });

    try {
      if (widget.bookingId.startsWith('demo-')) {
        throw StateError('Demo booking id');
      }

      final String? checkInCode;
      if (_isRazorpay) {
        checkInCode = await _payWithRazorpay();
      } else {
        checkInCode = await _payWithStub();
      }

      if (!mounted) return;
      setState(() => _paying = false);

      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute<void>(
          builder: (_) => BookingConfirmedScreen(
            table: widget.table,
            bookingId: widget.bookingId,
            amountPaid: _total,
            checkInCode: checkInCode,
          ),
        ),
        (route) => route.isFirst,
      );
    } catch (err) {
      if (!mounted) return;
      setState(() => _paying = false);
      final detail = err.toString().replaceFirst('Exception: ', '');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            detail.isEmpty ? 'Payment failed. Try again.' : detail,
            maxLines: 4,
          ),
          backgroundColor: NytoColors.surface,
          duration: const Duration(seconds: 6),
        ),
      );
    }
  }

  Future<String?> _payWithStub() async {
    final res = await bookingsApi
        .pay(
          bookingId: widget.bookingId,
          method: _method == PayMethod.upi ? 'UPI' : 'CARD',
        )
        .timeout(const Duration(seconds: 8));
    return _extractCheckInCode(res);
  }

  Future<String?> _payWithRazorpay() async {
    final order = await bookingsApi
        .createRazorpayOrder(widget.bookingId)
        .timeout(const Duration(seconds: 12));

    final keyId = order['keyId'] as String?;
    final orderId = order['orderId'] as String?;
    final amount = order['amount'];
    if (keyId == null || orderId == null || amount == null) {
      throw StateError('Invalid Razorpay order');
    }

    final completer = Completer<PaymentSuccessResponse>();
    _checkoutCompleter = completer;
    _checkoutSucceeded = false;

    _razorpay!.open({
      'key': keyId,
      'amount': amount is int ? amount : int.tryParse('$amount') ?? amount,
      'currency': 'INR',
      'name': 'NYTO',
      'description': 'Seat · ${widget.table.weekday} $_slotShort',
      'order_id': orderId,
      'theme': {'color': '#5B9FD4'},
      'retry': {'enabled': true, 'max_count': 1},
    });

    final success = await completer.future.timeout(
      const Duration(minutes: 5),
      onTimeout: () {
        _checkoutCompleter = null;
        throw TimeoutException('Checkout timed out');
      },
    );

    final paymentId = success.paymentId;
    final signature = success.signature;
    final paidOrderId = success.orderId ?? orderId;
    if (paymentId == null ||
        paymentId.isEmpty ||
        signature == null ||
        signature.isEmpty) {
      throw StateError(
        'Incomplete Razorpay response (paymentId/signature missing)',
      );
    }

    final confirmed = await bookingsApi
        .confirmRazorpay(
          bookingId: widget.bookingId,
          orderId: paidOrderId,
          paymentId: paymentId,
          signature: signature,
        )
        .timeout(const Duration(seconds: 12));

    return _extractCheckInCode(confirmed);
  }

  String? _extractCheckInCode(Map<String, dynamic> res) {
    var code = res['checkInCode'] as String?;
    final booking = res['booking'];
    if (code == null && booking is Map<String, dynamic>) {
      code = booking['checkInCode'] as String?;
    }
    return code;
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
                    _buildPriceSummary(),
                    const SizedBox(height: 16),
                    _buildPrepaidNotice(),
                    const SizedBox(height: 28),
                    if (_loadingConfig)
                      const Center(
                        child: Padding(
                          padding: EdgeInsets.all(24),
                          child: CircularProgressIndicator(
                            color: NytoColors.cta,
                            strokeWidth: 2,
                          ),
                        ),
                      )
                    else if (_configError != null)
                      Text(
                        _configError!,
                        style: GoogleFonts.dmSans(
                          fontSize: 14,
                          color: NytoColors.creamMuted,
                        ),
                      )
                    else if (_isRazorpay)
                      _buildRazorpaySection()
                    else
                      _buildStubMethodSection(),
                  ],
                ),
              ),
            ),
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

  Widget _buildRazorpaySection() {
    return Container(
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
                  'UPI · Card · Netbanking',
                  style: GoogleFonts.dmSans(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: NytoColors.cream,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Razorpay Checkout opens next. Use Test Mode cards/UPI from the Razorpay dashboard.',
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

  Widget _buildStubMethodSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'PAY VIA (DEV STUB)',
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
                subtitle: 'Stub confirm',
                onTap: () => setState(() => _method = PayMethod.upi),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _PayMethodTile(
                selected: _method == PayMethod.card,
                icon: Icons.credit_card,
                title: 'Card',
                subtitle: 'Stub confirm',
                onTap: () => setState(() => _method = PayMethod.card),
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        Text(
          'Backend has no Razorpay keys — payments confirm locally without charging.',
          style: GoogleFonts.dmSans(
            fontSize: 13,
            height: 1.4,
            color: NytoColors.creamMuted,
          ),
        ),
      ],
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
            _isRazorpay ? 'Secured by Razorpay · Non-refundable' : 'Dev stub · Non-refundable',
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
                  : NytoColors.cream.withValues(alpha: 0.08),
              width: selected ? 1.5 : 1,
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
              const SizedBox(height: 10),
              Text(
                title,
                style: GoogleFonts.dmSans(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: NytoColors.cream,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: GoogleFonts.dmSans(
                  fontSize: 12,
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
