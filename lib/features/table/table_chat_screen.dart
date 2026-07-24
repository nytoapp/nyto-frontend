import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
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
  const _ChatMessage({
    required this.sender,
    required this.text,
    required this.time,
  });

  final String sender;
  final String text;
  final String time;
}

/// Table chat — visual match to `designs/Screenshot (3727)`.
class TableChatScreen extends StatefulWidget {
  const TableChatScreen({super.key});

  @override
  State<TableChatScreen> createState() => _TableChatScreenState();
}

class _TableChatScreenState extends State<TableChatScreen> {
  static const _members = [
    _Member(initial: 'M', name: 'Marcus', color: Color(0xFF6B4A3A)),
    _Member(initial: 'L', name: 'Lena', color: Color(0xFF3D5C48)),
    _Member(initial: 'T', name: 'Toshi', color: Color(0xFF5C4638)),
    _Member(initial: 'C', name: 'Chiara', color: Color(0xFF8A7358)),
    _Member(initial: 'D', name: 'Dev', color: Color(0xFF2F4F3E)),
    _Member(
      initial: 'P',
      name: 'You',
      color: NytoColors.orange,
      isYou: true,
    ),
  ];

  final _messages = <_ChatMessage>[
    const _ChatMessage(
      sender: 'You',
      text: 'Walking in now. This place smells incredible already.',
      time: '7:48 PM',
    ),
    const _ChatMessage(
      sender: 'Marcus',
      text: 'Dev claimed the window seat. Classic writer move.',
      time: '7:49 PM',
    ),
    const _ChatMessage(
      sender: 'Lena',
      text: 'Ha! I want to sit next to Toshi. I heard you actually cook?',
      time: '7:50 PM',
    ),
    const _ChatMessage(
      sender: 'Toshi',
      text: "I do. But tonight I'm just eating. Let someone else do the work 😄",
      time: '7:51 PM',
    ),
    const _ChatMessage(
      sender: 'Chiara',
      text: "What is everyone ordering? I'm already eyeing the lamb.",
      time: '7:52 PM',
    ),
  ];

  final _controller = TextEditingController();
  final _scrollController = ScrollController();

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
      _messages.add(
        _ChatMessage(sender: 'You', text: text, time: 'Now'),
      );
      _controller.clear();
    });
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
    for (final m in _members) {
      if (m.isYou && sender == 'You') return m.color;
      if (m.name == sender) return m.color;
    }
    return NytoColors.surface;
  }

  String _initialFor(String sender) {
    if (sender == 'You') return 'P';
    return sender.isEmpty ? '?' : sender[0];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: NytoColors.bg,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
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
                        Row(
                          children: [
                            Text(
                              'Friday table chat',
                              style: GoogleFonts.dmSans(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: NytoColors.cream,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Icon(
                              Icons.lock_outline,
                              size: 14,
                              color: NytoColors.creamMuted,
                            ),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            Icon(
                              Icons.groups_outlined,
                              size: 13,
                              color: NytoColors.creamMuted,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '6 seated tonight',
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
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: NytoColors.orange,
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
            ),
            SizedBox(
              height: 78,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                itemCount: _members.length,
                separatorBuilder: (_, __) => const SizedBox(width: 14),
                itemBuilder: (context, index) {
                  final m = _members[index];
                  return Column(
                    children: [
                      Container(
                        width: 42,
                        height: 42,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: m.color,
                          shape: BoxShape.circle,
                          border: m.isYou
                              ? Border.all(color: NytoColors.cream, width: 1.5)
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
                          color: m.isYou
                              ? NytoColors.orange
                              : NytoColors.creamMuted,
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
            Divider(
              height: 1,
              color: NytoColors.cream.withValues(alpha: 0.08),
            ),
            Expanded(
              child: ListView.builder(
                controller: _scrollController,
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
                itemCount: _messages.length,
                itemBuilder: (context, index) {
                  final msg = _messages[index];
                  final isYou = msg.sender == 'You';
                  final showHeader = !isYou &&
                      (index == 0 || _messages[index - 1].sender != msg.sender);

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Column(
                      crossAxisAlignment: isYou
                          ? CrossAxisAlignment.end
                          : CrossAxisAlignment.start,
                      children: [
                        if (showHeader)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 6),
                            child: Row(
                              children: [
                                Container(
                                  width: 22,
                                  height: 22,
                                  alignment: Alignment.center,
                                  decoration: BoxDecoration(
                                    color: _colorFor(msg.sender),
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
                        Container(
                          constraints: BoxConstraints(
                            maxWidth: MediaQuery.sizeOf(context).width * 0.78,
                          ),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 10,
                          ),
                          decoration: BoxDecoration(
                            color: isYou
                                ? const Color(0xFF3A2A22)
                                : NytoColors.surface,
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Text(
                            msg.text,
                            style: GoogleFonts.dmSans(
                              fontSize: 14,
                              height: 1.4,
                              color: NytoColors.cream,
                            ),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          msg.time,
                          style: GoogleFonts.dmSans(
                            fontSize: 11,
                            color: NytoColors.creamMuted,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
              child: Row(
                children: [
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
                        hintText: 'Message your table...',
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
                    color: NytoColors.orange,
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
            ),
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Text(
                'Private to this table only · No DMs',
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
}
