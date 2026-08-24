import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:nyto_app/core/api/api_client.dart';
import 'package:nyto_app/core/api/chat_api.dart';
import 'package:nyto_app/core/theme/app_theme.dart';
import 'package:nyto_app/features/chat/direct_chat_screen.dart';
import 'package:nyto_app/features/table/table_chat_screen.dart';

/// Chat tab — Groups (real table chats) · Individual · Requests (Phase 2).
class ChatListTab extends StatefulWidget {
  const ChatListTab({super.key, this.active = false});

  /// IndexedStack keeps this widget alive — reload when the Chat tab is shown.
  final bool active;

  @override
  State<ChatListTab> createState() => _ChatListTabState();
}

class _ChatListTabState extends State<ChatListTab> {
  int _filter = 0;
  bool _loading = true;
  String? _error;
  List<Map<String, dynamic>> _conversations = [];
  List<Map<String, dynamic>> _individual = [];
  List<Map<String, dynamic>> _requests = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didUpdateWidget(covariant ChatListTab oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.active && !oldWidget.active) _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final rows = await chatApi.conversations();
      final individual = await chatApi.directConversations('individual');
      final requests = await chatApi.directConversations('requests');
      if (!mounted) return;
      setState(() {
        _conversations = rows;
        _individual = individual;
        _requests = requests;
        _loading = false;
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.message;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _error = 'Could not load chats. Is the server running?';
        _loading = false;
      });
    }
  }

  String _formatWhen(String? iso) {
    if (iso == null || iso.isEmpty) return '';
    final dt = DateTime.tryParse(iso)?.toLocal();
    if (dt == null) return '';
    const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    final day = days[(dt.weekday - 1).clamp(0, 6)];
    final h = dt.hour % 12 == 0 ? 12 : dt.hour % 12;
    final m = dt.minute.toString().padLeft(2, '0');
    final ap = dt.hour >= 12 ? 'PM' : 'AM';
    return '$day · $h:$m $ap';
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(22, 12, 22, 0),
          child: Text(
            'Chats',
            style: GoogleFonts.dmSans(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.6,
              color: NytoColors.cream.withValues(alpha: 0.45),
            ),
          ),
        ),
        const SizedBox(height: 12),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _FilterChip(
                  label: 'Groups',
                  selected: _filter == 0,
                  onTap: () => setState(() => _filter = 0),
                ),
                const SizedBox(width: 8),
                _FilterChip(
                  label: 'Individual',
                  selected: _filter == 1,
                  onTap: () => setState(() => _filter = 1),
                ),
                const SizedBox(width: 8),
                _FilterChip(
                  label: 'Requests',
                  selected: _filter == 2,
                  onTap: () => setState(() => _filter = 2),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 8),
        Expanded(child: _body()),
      ],
    );
  }

  Widget _body() {
    if (_loading) {
      return const Center(
        child: SizedBox(
          width: 28,
          height: 28,
          child: CircularProgressIndicator(
            strokeWidth: 2.2,
            color: NytoColors.ctaSoft,
          ),
        ),
      );
    }

    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                _error!,
                textAlign: TextAlign.center,
                style: GoogleFonts.dmSans(
                  color: NytoColors.cream.withValues(alpha: 0.7),
                ),
              ),
              const SizedBox(height: 14),
              TextButton(
                onPressed: _load,
                child: Text(
                  'Retry',
                  style: GoogleFonts.dmSans(
                    fontWeight: FontWeight.w700,
                    color: NytoColors.ctaSoft,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (_filter == 1) return _directList(_individual, inbox: 'individual');
    if (_filter == 2) return _directList(_requests, inbox: 'requests');

    if (_conversations.isEmpty) {
      return const _EmptyPane(
        title: 'No table chats yet',
        subtitle: 'Book a seat and your table group chat appears here.',
      );
    }

    return RefreshIndicator(
      color: NytoColors.ctaSoft,
      backgroundColor: NytoColors.surface,
      onRefresh: _load,
      child: ListView.separated(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
        itemCount: _conversations.length,
        separatorBuilder: (_, __) => const SizedBox(height: 10),
        itemBuilder: (context, index) {
          final c = _conversations[index];
          final venue = c['venueName'] as String? ?? 'Table';
          final startsAt = c['startsAt'] as String?;
          final memberCount = c['memberCount'] as int? ?? 0;
          final capacity = c['capacity'] as int? ?? 6;
          final chat = c['chat'] as Map?;
          final state = chat?['state'] as String? ?? 'ACTIVE';
          final last = c['lastMessage'] as Map?;
          final lastBody = last?['body'] as String? ?? 'Say hi to your table';
          final tableId = c['tableId'] as String? ?? '';

          return Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: tableId.isEmpty
                  ? null
                  : () async {
                      await Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => TableChatScreen(
                            tableId: tableId,
                            venueName: venue,
                            dayLabel: _formatWhen(startsAt),
                          ),
                        ),
                      );
                      if (mounted) _load();
                    },
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: NytoColors.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: NytoColors.cream.withValues(alpha: 0.08),
                  ),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: NytoColors.cta.withValues(alpha: 0.18),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.chat_bubble_outline_rounded,
                        size: 22,
                        color: NytoColors.ctaSoft,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  venue,
                                  style: GoogleFonts.dmSans(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w600,
                                    color: NytoColors.cream,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: NytoColors.cta.withValues(alpha: 0.2),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  '$memberCount/$capacity',
                                  style: GoogleFonts.dmSans(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    color: NytoColors.ctaSoft,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            state == 'DISABLED'
                                ? 'Ended · ${_formatWhen(startsAt)}'
                                : _formatWhen(startsAt),
                            style: GoogleFonts.dmSans(
                              fontSize: 12,
                              color: NytoColors.cream.withValues(alpha: 0.45),
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            lastBody,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.dmSans(
                              fontSize: 13,
                              color: NytoColors.cream.withValues(alpha: 0.6),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _directList(
    List<Map<String, dynamic>> rows, {
    required String inbox,
  }) {
    if (rows.isEmpty) {
      return _EmptyPane(
        title: inbox == 'requests' ? 'No requests' : 'No private chats yet',
        subtitle: inbox == 'requests'
            ? 'When someone messages you, requests show up here.'
            : 'Tap a person in a table chat to message them privately.',
      );
    }

    return RefreshIndicator(
      color: NytoColors.ctaSoft,
      backgroundColor: NytoColors.surface,
      onRefresh: _load,
      child: ListView.separated(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
        itemCount: rows.length,
        separatorBuilder: (_, __) => const SizedBox(height: 10),
        itemBuilder: (context, index) {
          final c = rows[index];
          final peer = c['peer'] as Map?;
          final name = peer?['firstName'] as String? ?? 'Guest';
          final initial = peer?['initial'] as String? ?? '?';
          final peerId = peer?['id'] as String? ?? '';
          final last = c['lastMessage'] as Map?;
          final lastBody = last?['body'] as String? ?? '';
          final status = c['status'] as String? ?? 'PENDING';
          final threadId = c['threadId'] as String? ?? '';
          final incoming = inbox == 'requests';
          final subtitle = incoming
              ? 'Wants to chat'
              : status == 'PENDING'
                  ? 'Request sent'
                  : lastBody;

          return Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: threadId.isEmpty || peerId.isEmpty
                  ? null
                  : () async {
                      await Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => DirectChatScreen(
                            threadId: threadId,
                            peerName: name,
                            peerUserId: peerId,
                            incomingRequest: incoming,
                          ),
                        ),
                      );
                      if (mounted) _load();
                    },
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: NytoColors.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: NytoColors.cream.withValues(alpha: 0.08),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: NytoColors.cta.withValues(alpha: 0.18),
                        shape: BoxShape.circle,
                      ),
                      child: Text(
                        initial,
                        style: GoogleFonts.dmSans(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: NytoColors.ctaSoft,
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            name,
                            style: GoogleFonts.dmSans(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: NytoColors.cream,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            subtitle,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.dmSans(
                              fontSize: 13,
                              color: NytoColors.cream.withValues(alpha: 0.6),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(999),
            color: selected
                ? NytoColors.cta.withValues(alpha: 0.22)
                : Colors.transparent,
            border: Border.all(
              color: selected
                  ? NytoColors.ctaSoft.withValues(alpha: 0.55)
                  : NytoColors.cream.withValues(alpha: 0.18),
            ),
          ),
          child: Text(
            label,
            style: GoogleFonts.dmSans(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: selected
                  ? NytoColors.ctaSoft
                  : NytoColors.cream.withValues(alpha: 0.65),
            ),
          ),
        ),
      ),
    );
  }
}

class _EmptyPane extends StatelessWidget {
  const _EmptyPane({required this.title, required this.subtitle});

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.chat_bubble_outline_rounded,
              size: 40,
              color: NytoColors.cta.withValues(alpha: 0.85),
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: GoogleFonts.fraunces(
                fontSize: 24,
                color: NytoColors.cream,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: GoogleFonts.dmSans(
                fontSize: 14,
                color: NytoColors.cream.withValues(alpha: 0.45),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
