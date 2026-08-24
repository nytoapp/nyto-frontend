import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:nyto_app/core/api/api_client.dart';
import 'package:nyto_app/core/api/chat_api.dart';
import 'package:nyto_app/core/realtime/chat_socket.dart';
import 'package:nyto_app/core/theme/app_theme.dart';
import 'package:nyto_app/features/chat/direct_chat_screen.dart';
import 'package:socket_io_client/socket_io_client.dart' as io;

class _Member {
  const _Member({
    required this.id,
    required this.initial,
    required this.name,
    required this.color,
    this.isYou = false,
  });

  final String id;
  final String initial;
  final String name;
  final Color color;
  final bool isYou;
}

class _ChatMessage {
  _ChatMessage({
    required this.id,
    required this.senderId,
    required this.senderName,
    required this.text,
    required this.createdAt,
    this.isYou = false,
    this.isSystem = false,
  });

  final String id;
  final String senderId;
  final String senderName;
  final String text;
  final DateTime createdAt;
  final bool isYou;
  final bool isSystem;
}

/// Real table group chat — HTTP history + Socket.IO live updates.
class TableChatScreen extends StatefulWidget {
  const TableChatScreen({
    super.key,
    required this.tableId,
    this.venueName = 'Venue',
    this.dayLabel = '',
    this.timeLabel = '',
  });

  final String tableId;
  final String venueName;
  final String dayLabel;
  final String timeLabel;

  @override
  State<TableChatScreen> createState() => _TableChatScreenState();
}

class _TableChatScreenState extends State<TableChatScreen> {
  static const _palette = [
    Color(0xFF2B5CE8),
    Color(0xFF3D5C48),
    Color(0xFF5C4638),
    Color(0xFF8A7358),
    Color(0xFF2F4F3E),
    NytoColors.cta,
  ];

  final _controller = TextEditingController();
  final _scrollController = ScrollController();
  final _messages = <_ChatMessage>[];
  final _seenIds = <String>{};

  List<_Member> _members = [];
  int _capacity = 6;
  bool _loading = true;
  bool _sending = false;
  bool _canSend = true;
  String _chatState = 'ACTIVE';
  String? _error;
  String? _myUserId;
  io.Socket? _socket;

  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  @override
  void dispose() {
    ChatSocket.leaveTable(widget.tableId);
    _socket?.off('message.created');
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _bootstrap() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final meta = await chatApi.tableConversation(widget.tableId);
      final conversation = meta['conversation'] as Map<String, dynamic>?;
      final chat = conversation?['chat'] as Map?;
      final membersRaw = conversation?['members'];
      final members = <_Member>[];
      if (membersRaw is List) {
        for (var i = 0; i < membersRaw.length; i++) {
          final m = membersRaw[i] as Map;
          final isYou = m['isYou'] == true;
          if (isYou) _myUserId = m['id'] as String?;
          members.add(
            _Member(
              id: m['id'] as String? ?? '$i',
              initial: m['initial'] as String? ?? '?',
              name: isYou ? 'You' : (m['firstName'] as String? ?? 'Guest'),
              color: _palette[i % _palette.length],
              isYou: isYou,
            ),
          );
        }
      }

      final hist = await chatApi.messages(widget.tableId);
      final rows = hist['messages'];
      final msgs = <_ChatMessage>[];
      if (rows is List) {
        for (final row in rows) {
          if (row is! Map) continue;
          final msg = _fromApi(row.cast<String, dynamic>());
          if (_seenIds.add(msg.id)) msgs.add(msg);
        }
      }

      if (!mounted) return;
      setState(() {
        _members = members;
        _capacity = conversation?['capacity'] as int? ?? 6;
        _messages
          ..clear()
          ..addAll(msgs);
        if (_messages.isEmpty) {
          _messages.add(
            _ChatMessage(
              id: 'system-empty',
              senderId: 'system',
              senderName: 'System',
              text: "You're here — say hi. Others appear as they book.",
              createdAt: DateTime.now(),
              isSystem: true,
            ),
          );
        }
        _canSend = chat?['canSend'] == true;
        _chatState = chat?['state'] as String? ?? 'ACTIVE';
        _loading = false;
      });
      _scrollToBottom();
      await _connectSocket();
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.message;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _error = 'Could not open chat. Is the server running?';
        _loading = false;
      });
    }
  }

  Future<void> _connectSocket() async {
    try {
      final socket = await ChatSocket.connect();
      _socket = socket;
      ChatSocket.joinTable(widget.tableId);
      socket.off('message.created');
      socket.on('message.created', (data) {
        if (data is! Map) return;
        final payload = data['payload'];
        if (payload is! Map) return;
        final message = payload['message'];
        if (message is! Map) return;
        if (message['tableId'] != widget.tableId) return;
        _ingest(message.cast<String, dynamic>());
      });
    } catch (_) {
      // History still works over HTTP if socket fails.
    }
  }

  _ChatMessage _fromApi(Map<String, dynamic> json) {
    final sender = json['sender'];
    final senderMap = sender is Map ? sender.cast<String, dynamic>() : null;
    final senderId = senderMap?['id'] as String? ?? '';
    final name = senderMap?['firstName'] as String? ?? 'Guest';
    final isYou = senderId.isNotEmpty && senderId == _myUserId;
    final created = DateTime.tryParse(json['createdAt'] as String? ?? '') ??
        DateTime.now();
    return _ChatMessage(
      id: json['id'] as String? ?? created.microsecondsSinceEpoch.toString(),
      senderId: senderId,
      senderName: isYou ? 'You' : name,
      text: json['body'] as String? ?? '',
      createdAt: created.toLocal(),
      isYou: isYou,
    );
  }

  void _ingest(Map<String, dynamic> json) {
    final msg = _fromApi(json);
    if (!_seenIds.add(msg.id)) return;
    if (!mounted) return;
    setState(() {
      _messages.removeWhere((m) => m.isSystem && m.id == 'system-empty');
      _messages.add(msg);
    });
    _scrollToBottom();
  }

  String _timeLabel(DateTime dt) {
    final h = dt.hour % 12 == 0 ? 12 : dt.hour % 12;
    final m = dt.minute.toString().padLeft(2, '0');
    final ap = dt.hour >= 12 ? 'PM' : 'AM';
    return '$h:$m $ap';
  }

  Future<void> _send() async {
    final text = _controller.text.trim();
    if (text.isEmpty || _sending || !_canSend) return;
    setState(() => _sending = true);
    final clientId =
        'c_${DateTime.now().microsecondsSinceEpoch}_${text.hashCode}';
    try {
      final res = await chatApi.sendMessage(
        tableId: widget.tableId,
        body: text,
        clientMessageId: clientId,
      );
      final message = res['message'];
      if (message is Map) {
        _ingest(message.cast<String, dynamic>());
      }
      _controller.clear();
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.message),
          backgroundColor: NytoColors.surface,
        ),
      );
      if (e.statusCode == 403) {
        setState(() {
          _canSend = false;
          _chatState = 'DISABLED';
        });
      }
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not send. Try again.'),
          backgroundColor: NytoColors.surface,
        ),
      );
    } finally {
      if (mounted) setState(() => _sending = false);
    }
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

  Color _colorFor(String senderId) {
    for (final m in _members) {
      if (m.id == senderId) return m.color;
    }
    return NytoColors.surface;
  }

  Future<void> _openDirect(_Member member) async {
    try {
      final res = await chatApi.openDirect(member.id);
      final conversation = res['conversation'] as Map<String, dynamic>?;
      final threadId = conversation?['threadId'] as String? ?? '';
      final peer = conversation?['peer'] as Map?;
      if (!mounted || threadId.isEmpty) return;
      await Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => DirectChatScreen(
            threadId: threadId,
            peerName: peer?['firstName'] as String? ?? member.name,
            peerUserId: member.id,
            incomingRequest: conversation?['status'] == 'PENDING' &&
                conversation?['initiatedByMe'] != true,
          ),
        ),
      );
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message), backgroundColor: NytoColors.surface),
      );
    }
  }

  String _initialFor(String senderId, String name) {
    for (final m in _members) {
      if (m.id == senderId) return m.initial;
    }
    return name.isEmpty ? '?' : name[0].toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: NytoColors.bg,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            if (!_loading && _error == null) _buildMemberStrip(),
            Divider(
              height: 1,
              color: NytoColors.cream.withValues(alpha: 0.08),
            ),
            if (!_canSend)
              Container(
                width: double.infinity,
                margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: NytoColors.cta.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'This table chat has ended. You can still message participants individually.',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.dmSans(
                    fontSize: 13,
                    height: 1.35,
                    color: NytoColors.ctaSoft,
                  ),
                ),
              ),
            Expanded(child: _buildBody()),
            if (_canSend) _buildComposer(),
            Padding(
              padding: const EdgeInsets.only(bottom: 10, top: 4),
              child: Text(
                _chatState == 'DISABLED'
                    ? 'Read-only · Table chat ended'
                    : 'Private to this table',
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

  Widget _buildBody() {
    if (_loading) {
      return const Center(
        child: CircularProgressIndicator(color: NytoColors.ctaSoft),
      );
    }
    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
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
              const SizedBox(height: 12),
              TextButton(
                onPressed: _bootstrap,
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

    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
      itemCount: _messages.length,
      itemBuilder: (_, i) => _buildMessage(i),
    );
  }

  Widget _buildHeader() {
    final when = [
      if (widget.dayLabel.isNotEmpty) widget.dayLabel,
      if (widget.timeLabel.isNotEmpty) widget.timeLabel,
    ].join(' · ');

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
                  widget.venueName,
                  style: GoogleFonts.dmSans(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: NytoColors.cream,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  when.isEmpty ? 'Table group · Private' : when,
                  style: GoogleFonts.dmSans(
                    fontSize: 12,
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

  Widget _buildMemberStrip() {
    if (_members.length <= 1) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
        child: Text(
          'Waiting for your table · ${_members.length} of $_capacity seated',
          style: GoogleFonts.dmSans(
            fontSize: 13,
            color: NytoColors.cream.withValues(alpha: 0.5),
          ),
        ),
      );
    }
    return SizedBox(
      height: 78,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: _members.length,
        separatorBuilder: (_, __) => const SizedBox(width: 14),
        itemBuilder: (_, index) {
          final m = _members[index];
          return GestureDetector(
            onTap: m.isYou ? null : () => _openDirect(m),
            child: Column(
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
            ),
          );
        },
      ),
    );
  }

  Widget _buildMessage(int index) {
    final msg = _messages[index];
    if (msg.isSystem) {
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
              msg.text,
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

    final isYou = msg.isYou;
    final showHeader = !isYou &&
        (index == 0 ||
            _messages[index - 1].isSystem ||
            _messages[index - 1].senderId != msg.senderId);

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
                      color: _colorFor(msg.senderId).withValues(alpha: 0.35),
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      _initialFor(msg.senderId, msg.senderName),
                      style: GoogleFonts.dmSans(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: NytoColors.cream,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    msg.senderName,
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
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
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
            _timeLabel(msg.createdAt),
            style: GoogleFonts.dmSans(
              fontSize: 11,
              color: NytoColors.creamMuted,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildComposer() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _controller,
              enabled: !_sending,
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
              onTap: _sending ? null : _send,
              child: SizedBox(
                width: 46,
                height: 46,
                child: _sending
                    ? const Padding(
                        padding: EdgeInsets.all(12),
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: NytoColors.cream,
                        ),
                      )
                    : const Icon(
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
