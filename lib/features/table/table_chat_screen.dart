import 'dart:io';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:nyto_app/core/theme/app_theme.dart';

class _Member {
  const _Member({
    required this.initial,
    required this.name,
    required this.color,
    this.isYou = false,
  });

  final String initial;
  final String name;
  final Color color;
  final bool isYou;
}

class _ChatMessage {
  _ChatMessage({
    required this.sender,
    this.text,
    this.imagePath,
    required this.time,
  });

  final String sender;
  final String? text;
  final String? imagePath;
  final String time;
}

/// Ice-blue table chat — text + images. Real-time sync via backend later.
class TableChatScreen extends StatefulWidget {
  const TableChatScreen({
    super.key,
    this.venueName = 'Venue',
    this.dayLabel = 'Friday',
    this.timeLabel = '8:30 PM',
  });

  final String venueName;
  final String dayLabel;
  final String timeLabel;

  @override
  State<TableChatScreen> createState() => _TableChatScreenState();
}

class _TableChatScreenState extends State<TableChatScreen> {
  static const _members = [
    _Member(initial: 'A', name: 'Arjun', color: Color(0xFF2B5CE8)),
    _Member(initial: 'S', name: 'Sara', color: Color(0xFF3D5C48)),
    _Member(initial: 'R', name: 'Riya', color: Color(0xFF5C4638)),
    _Member(initial: 'K', name: 'Karan', color: Color(0xFF8A7358)),
    _Member(initial: 'D', name: 'Dev', color: Color(0xFF2F4F3E)),
    _Member(
      initial: 'Y',
      name: 'You',
      color: NytoColors.cta,
      isYou: true,
    ),
  ];

  final _messages = <_ChatMessage>[
    _ChatMessage(
      sender: 'System',
      text: "You're first — others will join here once they book.",
      time: '',
    ),
    _ChatMessage(
      sender: 'Arjun',
      text: 'Hey everyone! Excited for this one.',
      time: '6:12 PM',
    ),
    _ChatMessage(
      sender: 'Sara',
      text: 'Same here! Anyone been to this venue before?',
      time: '6:14 PM',
    ),
    _ChatMessage(
      sender: 'Riya',
      text: 'First time. Heard great things though.',
      time: '6:15 PM',
    ),
  ];

  final _controller = TextEditingController();
  final _scrollController = ScrollController();
  final _picker = ImagePicker();

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _send() {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    setState(() {
      _messages.add(_ChatMessage(sender: 'You', text: text, time: 'Now'));
      _controller.clear();
    });
    _scrollToBottom();
  }

  Future<void> _pickImage() async {
    final file = await _picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1200,
    );
    if (file == null || !mounted) return;
    setState(() {
      _messages.add(
        _ChatMessage(sender: 'You', imagePath: file.path, time: 'Now'),
      );
    });
    _scrollToBottom();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOut,
      );
    });
  }

  Color _colorFor(String sender) {
    if (sender == 'System') return NytoColors.surface;
    for (final m in _members) {
      if (m.isYou && sender == 'You') return m.color;
      if (m.name == sender) return m.color;
    }
    return NytoColors.surface;
  }

  String _initialFor(String sender) {
    if (sender == 'You') return 'Y';
    return sender.isEmpty ? '?' : sender[0];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: NytoColors.bg,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            _buildHeader(),
            // Member row
            _buildMemberStrip(),
            Divider(
              height: 1,
              color: NytoColors.cream.withValues(alpha: 0.08),
            ),
            // Messages
            Expanded(
              child: ListView.builder(
                controller: _scrollController,
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
                itemCount: _messages.length,
                itemBuilder: (_, i) => _buildMessage(i),
              ),
            ),
            // Composer
            _buildComposer(),
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Text(
                'Private to this table only · No DMs · Report',
                style: GoogleFonts.dmSans(
                  fontSize: 11,
                  color: NytoColors.creamMuted,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 8, 16, 8),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.of(context).pop(),
            icon: Icon(
              Icons.arrow_back_ios_new,
              size: 18,
              color: NytoColors.cream.withValues(alpha: 0.85),
            ),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${widget.venueName} · ${widget.dayLabel} · ${widget.timeLabel}',
                  style: GoogleFonts.dmSans(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: NytoColors.cream,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Icon(
                      Icons.lock_outline,
                      size: 12,
                      color: NytoColors.creamMuted,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Table group · Private',
                      style: GoogleFonts.dmSans(
                        fontSize: 12,
                        color: NytoColors.creamMuted,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: NytoColors.cta,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              'NYTO',
              style: GoogleFonts.dmSans(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                letterSpacing: 1,
                color: NytoColors.cream,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMemberStrip() {
    return SizedBox(
      height: 78,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: _members.length,
        separatorBuilder: (_, __) => const SizedBox(width: 14),
        itemBuilder: (_, index) {
          final m = _members[index];
          return Column(
            children: [
              Container(
                width: 42,
                height: 42,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: m.color.withValues(alpha: 0.35),
                  shape: BoxShape.circle,
                  border: m.isYou
                      ? Border.all(color: NytoColors.ctaSoft, width: 1.5)
                      : null,
                ),
                child: Text(
                  m.initial,
                  style: GoogleFonts.dmSans(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: NytoColors.cream,
                  ),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                m.name,
                style: GoogleFonts.dmSans(
                  fontSize: 11,
                  color: m.isYou ? NytoColors.ctaSoft : NytoColors.creamMuted,
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildMessage(int index) {
    final msg = _messages[index];
    final isYou = msg.sender == 'You';
    final isSystem = msg.sender == 'System';

    if (isSystem) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 16),
        child: Center(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: NytoColors.cta.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              msg.text ?? '',
              textAlign: TextAlign.center,
              style: GoogleFonts.dmSans(
                fontSize: 13,
                color: NytoColors.ctaSoft,
              ),
            ),
          ),
        ),
      );
    }

    final showHeader = !isYou &&
        (index == 0 ||
            _messages[index - 1].sender != msg.sender ||
            _messages[index - 1].sender == 'System');

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment:
            isYou ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          if (showHeader)
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 22,
                    height: 22,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: _colorFor(msg.sender).withValues(alpha: 0.35),
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      _initialFor(msg.sender),
                      style: GoogleFonts.dmSans(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: NytoColors.cream,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    msg.sender,
                    style: GoogleFonts.dmSans(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: NytoColors.creamMuted,
                    ),
                  ),
                ],
              ),
            ),
          // Image message
          if (msg.imagePath != null)
            Container(
              constraints: BoxConstraints(
                maxWidth: MediaQuery.sizeOf(context).width * 0.68,
              ),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: NytoColors.cream.withValues(alpha: 0.08),
                ),
              ),
              clipBehavior: Clip.antiAlias,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: Image.file(
                  File(msg.imagePath!),
                  fit: BoxFit.cover,
                  width: double.infinity,
                  height: 200,
                ),
              ),
            ),
          // Text message
          if (msg.text != null)
            Container(
              constraints: BoxConstraints(
                maxWidth: MediaQuery.sizeOf(context).width * 0.78,
              ),
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                gradient: isYou
                    ? const LinearGradient(
                        colors: [NytoColors.ctaDeep, NytoColors.cta],
                      )
                    : null,
                color: isYou ? null : NytoColors.surface,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Text(
                msg.text!,
                style: GoogleFonts.dmSans(
                  fontSize: 14,
                  height: 1.4,
                  color: NytoColors.cream,
                ),
              ),
            ),
          if (msg.time.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              msg.time,
              style: GoogleFonts.dmSans(
                fontSize: 11,
                color: NytoColors.creamMuted,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildComposer() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: Row(
        children: [
          Material(
            color: NytoColors.surface,
            shape: const CircleBorder(),
            child: InkWell(
              customBorder: const CircleBorder(),
              onTap: _pickImage,
              child: const SizedBox(
                width: 42,
                height: 42,
                child: Icon(
                  Icons.add_rounded,
                  size: 22,
                  color: NytoColors.creamMuted,
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: TextField(
              controller: _controller,
              style: GoogleFonts.dmSans(
                fontSize: 15,
                color: NytoColors.cream,
              ),
              minLines: 1,
              maxLines: 4,
              textInputAction: TextInputAction.send,
              onSubmitted: (_) => _send(),
              decoration: InputDecoration(
                hintText: 'Message your table…',
                hintStyle: GoogleFonts.dmSans(
                  color: NytoColors.creamMuted,
                ),
                filled: true,
                fillColor: NytoColors.surface,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Material(
            color: NytoColors.cta,
            shape: const CircleBorder(),
            child: InkWell(
              customBorder: const CircleBorder(),
              onTap: _send,
              child: const SizedBox(
                width: 46,
                height: 46,
                child: Icon(
                  Icons.send_rounded,
                  size: 20,
                  color: NytoColors.cream,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
