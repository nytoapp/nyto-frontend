import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:nyto_app/core/api/nyto_api.dart';
import 'package:nyto_app/core/theme/app_theme.dart';

/// Guest Help Center → live `POST /support`.
Future<void> showOpenTicketSheet(BuildContext context) async {
  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: NytoColors.surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
    ),
    builder: (ctx) => const _OpenTicketSheet(),
  );
}

class _OpenTicketSheet extends StatefulWidget {
  const _OpenTicketSheet();

  @override
  State<_OpenTicketSheet> createState() => _OpenTicketSheetState();
}

class _OpenTicketSheetState extends State<_OpenTicketSheet> {
  final _subject = TextEditingController();
  final _message = TextEditingController();
  String _category = 'OTHER';
  bool _busy = false;
  String? _error;

  static const _categories = <(String, String)>[
    ('BOOKING', 'Booking'),
    ('PAYMENT', 'Payment'),
    ('DOOR', 'Check-in / door'),
    ('NIGHT', 'Night experience'),
    ('FEEDBACK', 'Feedback'),
    ('OTHER', 'Other'),
  ];

  @override
  void dispose() {
    _subject.dispose();
    _message.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final subject = _subject.text.trim();
    final message = _message.text.trim();
    if (subject.isEmpty || message.isEmpty) {
      setState(() => _error = 'Subject and details are required.');
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await supportApi.createTicket(
        subject: subject,
        category: _category,
        message: message,
      );
      if (!mounted) return;
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Ticket sent — NYTO will follow up.'),
          backgroundColor: NytoColors.surface,
        ),
      );
    } catch (err) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _error = err.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final inset = MediaQuery.viewInsetsOf(context).bottom;
    return Padding(
      padding: EdgeInsets.fromLTRB(20, 16, 20, 20 + inset),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: NytoColors.cream.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(99),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Open a ticket',
              style: GoogleFonts.dmSerifDisplay(
                fontSize: 24,
                color: NytoColors.cream,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Goes to NYTO ops — same inbox as venue Contact NYTO.',
              style: GoogleFonts.dmSans(
                fontSize: 13,
                color: NytoColors.cream.withValues(alpha: 0.55),
              ),
            ),
            const SizedBox(height: 18),
            Text(
              'Category',
              style: GoogleFonts.dmSans(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: NytoColors.creamMuted,
              ),
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              // ignore: deprecated_member_use
              value: _category,
              dropdownColor: NytoColors.surface,
              style: GoogleFonts.dmSans(color: NytoColors.cream),
              decoration: InputDecoration(
                filled: true,
                fillColor: NytoColors.bg,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
              items: [
                for (final c in _categories)
                  DropdownMenuItem(value: c.$1, child: Text(c.$2)),
              ],
              onChanged: _busy
                  ? null
                  : (v) {
                      if (v != null) setState(() => _category = v);
                    },
            ),
            const SizedBox(height: 14),
            TextField(
              controller: _subject,
              enabled: !_busy,
              style: GoogleFonts.dmSans(color: NytoColors.cream),
              decoration: InputDecoration(
                labelText: 'Subject',
                labelStyle: GoogleFonts.dmSans(color: NytoColors.creamMuted),
                filled: true,
                fillColor: NytoColors.bg,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _message,
              enabled: !_busy,
              maxLines: 4,
              style: GoogleFonts.dmSans(color: NytoColors.cream),
              decoration: InputDecoration(
                labelText: 'Details',
                labelStyle: GoogleFonts.dmSans(color: NytoColors.creamMuted),
                filled: true,
                fillColor: NytoColors.bg,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            if (_error != null) ...[
              const SizedBox(height: 10),
              Text(
                _error!,
                style: GoogleFonts.dmSans(
                  fontSize: 13,
                  color: const Color(0xFFE57373),
                ),
              ),
            ],
            const SizedBox(height: 16),
            FilledButton(
              onPressed: _busy ? null : _submit,
              style: FilledButton.styleFrom(
                backgroundColor: NytoColors.cta,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: Text(
                _busy ? 'Sending…' : 'Send to NYTO',
                style: GoogleFonts.dmSans(fontWeight: FontWeight.w700),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
