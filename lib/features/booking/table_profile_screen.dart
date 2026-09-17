import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:nyto_app/core/api/nyto_api.dart';
import 'package:nyto_app/core/theme/app_theme.dart';
import 'package:nyto_app/domain/table.dart';

/// W2 table profile — collected once at booking, then reused.
/// Singles also ask who they want to meet.
class TableProfileScreen extends StatefulWidget {
  const TableProfileScreen({
    super.key,
    required this.table,
  });

  final UpcomingTable table;

  @override
  State<TableProfileScreen> createState() => _TableProfileScreenState();
}

class _TableProfileScreenState extends State<TableProfileScreen> {
  String? _style;
  String? _intent;
  final _line = TextEditingController();
  bool _saving = false;

  bool get _singles => widget.table.tableType == NytoTableType.singles;

  bool get _canSave {
    if (_style == null) return false;
    if (_singles && _intent == null) return false;
    return true;
  }

  @override
  void dispose() {
    _line.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_canSave || _saving) return;
    FocusScope.of(context).unfocus();
    setState(() => _saving = true);
    try {
      await authApi.updateMe({
        'conversationStyle': _style,
        if (_line.text.trim().isNotEmpty) 'tableOneLiner': _line.text.trim(),
        if (_singles) 'datingIntent': _intent,
      });
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (_) {
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not save. Try again.'),
          backgroundColor: NytoColors.surface,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: NytoColors.bg,
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 8, 24, 0),
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
                    style: GoogleFonts.dmSerifDisplay(
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
              child: ListView(
                padding: const EdgeInsets.fromLTRB(28, 16, 28, 24),
                children: [
                  Text(
                    'TABLE PROFILE',
                    style: GoogleFonts.dmSans(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 1.6,
                      color: NytoColors.cta,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'How should we seat you?',
                    style: GoogleFonts.dmSerifDisplay(
                      fontSize: 32,
                      color: NytoColors.cream,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Used for matching. Not shown on Home.',
                    style: GoogleFonts.dmSans(
                      fontSize: 14,
                      color: NytoColors.creamMuted,
                    ),
                  ),
                  const SizedBox(height: 28),
                  _label('AT THE TABLE'),
                  const SizedBox(height: 10),
                  _choice('Calm', 'calm'),
                  _choice('A mix', 'mixed'),
                  _choice('Lively', 'lively'),
                  const SizedBox(height: 22),
                  _label('ONE LINE ABOUT YOU · OPTIONAL'),
                  const SizedBox(height: 10),
                  TextField(
                    controller: _line,
                    maxLength: 80,
                    style: GoogleFonts.dmSans(color: NytoColors.cream),
                    decoration: InputDecoration(
                      hintText: 'New in the city, into long dinners',
                      hintStyle: GoogleFonts.dmSans(
                        color: NytoColors.cream.withValues(alpha: 0.35),
                      ),
                      counterStyle: GoogleFonts.dmSans(
                        color: NytoColors.creamMuted,
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide(
                          color: NytoColors.cream.withValues(alpha: 0.12),
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: const BorderSide(color: NytoColors.cta),
                      ),
                    ),
                  ),
                  if (_singles) ...[
                    const SizedBox(height: 8),
                    _label('WHO DO YOU WANT TO MEET'),
                    const SizedBox(height: 10),
                    _intentChoice('Women', 'women'),
                    _intentChoice('Men', 'men'),
                    _intentChoice('Open', 'open'),
                  ],
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(28, 8, 28, 24),
              child: SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  onPressed: _canSave && !_saving ? _save : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: NytoColors.cta,
                    disabledBackgroundColor: NytoColors.cta.withValues(alpha: 0.35),
                    foregroundColor: NytoColors.cream,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: Text(
                    _saving ? 'Saving…' : 'Continue',
                    style: GoogleFonts.dmSans(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
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

  Widget _label(String text) {
    return Text(
      text,
      style: GoogleFonts.dmSans(
        fontSize: 11,
        fontWeight: FontWeight.w700,
        letterSpacing: 1.3,
        color: NytoColors.creamMuted,
      ),
    );
  }

  Widget _choice(String label, String id) {
    final selected = _style == id;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: _tile(
        label: label,
        selected: selected,
        onTap: () => setState(() => _style = id),
      ),
    );
  }

  Widget _intentChoice(String label, String id) {
    final selected = _intent == id;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: _tile(
        label: label,
        selected: selected,
        onTap: () => setState(() => _intent = id),
      ),
    );
  }

  Widget _tile({
    required String label,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: selected
                  ? NytoColors.cta
                  : NytoColors.cream.withValues(alpha: 0.12),
            ),
          ),
          child: Text(
            label,
            style: GoogleFonts.dmSans(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: selected ? NytoColors.ctaSoft : NytoColors.cream,
            ),
          ),
        ),
      ),
    );
  }
}

bool tableProfileComplete(Map<String, dynamic>? user, NytoTableType type) {
  if (user == null) return false;
  final style = user['conversationStyle'] as String?;
  if (style == null || style.isEmpty) return false;
  if (type == NytoTableType.singles) {
    final intent = user['datingIntent'] as String?;
    if (intent == null || intent.isEmpty) return false;
  }
  return true;
}
