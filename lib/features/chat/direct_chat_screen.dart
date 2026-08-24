import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:nyto_app/core/api/api_client.dart';
import 'package:nyto_app/core/api/chat_api.dart';
import 'package:nyto_app/core/realtime/chat_socket.dart';
import 'package:nyto_app/core/theme/app_theme.dart';
import 'package:socket_io_client/socket_io_client.dart' as io;

class _Msg {
  _Msg({
    required this.id,
    required this.senderId,
    required this.text,
    required this.createdAt,
    required this.isYou,
  });

  final String id;
  final String senderId;
  final String text;
  final DateTime createdAt;
  final bool isYou;
}

/// 1-to-1 chat + incoming request accept/decline + block.
class DirectChatScreen extends StatefulWidget {
  const DirectChatScreen({
    super.key,
    required this.threadId,
    required this.peerName,
    required this.peerUserId,
    this.incomingRequest = false,
  });

  final String threadId;
  final String peerName;
  final String peerUserId;
  final bool incomingRequest;

  @override
  State<DirectChatScreen> createState() => _DirectChatScreenState();
}

class _DirectChatScreenState extends State<DirectChatScreen> {
  final _controller = TextEditingController();
  final _scrollController = ScrollController();
  final _messages = <_Msg>[];
  final _seenIds = <String>{};

  bool _loading = true;
  bool _sending = false;
  bool _incomingRequest = false;
  String? _error;
  String _status = 'PENDING';
  io.Socket? _socket;

  @override
  void initState() {
    super.initState();
    _incomingRequest = widget.incomingRequest;
    _bootstrap();
  }

  @override
  void dispose() {
    ChatSocket.leaveDm(widget.threadId);
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
      final meta = await chatApi.directThread(widget.threadId);
      final conversation = meta['conversation'] as Map<String, dynamic>?;
      _status = conversation?['status'] as String? ?? 'PENDING';
      _incomingRequest =
          _status == 'PENDING' && conversation?['initiatedByMe'] != true;

      final hist = await chatApi.directMessages(widget.threadId);
      final rows = hist['messages'];
      final msgs = <_Msg>[];
      if (rows is List) {
        for (final row in rows) {
          if (row is! Map) continue;
          final msg = _fromApi(row.cast<String, dynamic>());
          if (_seenIds.add(msg.id)) msgs.add(msg);
        }
      }
      if (!mounted) return;
      setState(() {
        _messages
          ..clear()
          ..addAll(msgs);
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
        _error = 'Could not open chat.';
        _loading = false;
      });
    }
  }

  Future<void> _connectSocket() async {
    try {
      final socket = await ChatSocket.connect();
      _socket = socket;
      ChatSocket.joinDm(widget.threadId);
      socket.off('message.created');
      socket.on('message.created', (data) {
        if (data is! Map) return;
        final payload = data['payload'];
        if (payload is! Map) return;
        if (payload['kind'] == 'TABLE') return;
        final message = payload['message'];
        if (message is! Map) return;
        final threadId = message['threadId'] as String?;
        if (threadId != widget.threadId) return;
        _ingest(message.cast<String, dynamic>());
      });
    } catch (_) {}
  }

  _Msg _fromApi(Map<String, dynamic> json) {
    final sender = json['sender'];
    final senderMap = sender is Map ? sender.cast<String, dynamic>() : null;
    final senderId = senderMap?['id'] as String? ?? '';
    final isYou = senderId.isNotEmpty && senderId != widget.peerUserId;
    final created =
        DateTime.tryParse(json['createdAt'] as String? ?? '') ?? DateTime.now();
    return _Msg(
      id: json['id'] as String? ?? created.microsecondsSinceEpoch.toString(),
      senderId: senderId,
      text: json['body'] as String? ?? '',
      createdAt: created.toLocal(),
      isYou: isYou,
    );
  }

  void _ingest(Map<String, dynamic> json) {
    final msg = _fromApi(json);
    if (!_seenIds.add(msg.id)) return;
    if (!mounted) return;
    setState(() => _messages.add(msg));
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
    if (text.isEmpty || _sending) return;
    setState(() => _sending = true);
    final clientId =
        'd_${DateTime.now().microsecondsSinceEpoch}_${text.hashCode}';
    try {
      final res = await chatApi.sendDirectMessage(
        threadId: widget.threadId,
        body: text,
        clientMessageId: clientId,
      );
      final message = res['message'];
      if (message is Map) {
        _ingest(message.cast<String, dynamic>());
      }
      _controller.clear();
      if (_incomingRequest) {
        setState(() {
          _incomingRequest = false;
          _status = 'ACTIVE';
        });
      }
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message), backgroundColor: NytoColors.surface),
      );
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  Future<void> _accept() async {
    try {
      await chatApi.acceptDirect(widget.threadId);
      if (!mounted) return;
      setState(() {
        _incomingRequest = false;
        _status = 'ACTIVE';
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message), backgroundColor: NytoColors.surface),
      );
    }
  }

  Future<void> _decline() async {
    try {
      await chatApi.declineDirect(widget.threadId);
      if (!mounted) return;
      Navigator.of(context).pop();
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message), backgroundColor: NytoColors.surface),
      );
    }
  }

  Future<void> _block() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: NytoColors.surface,
        title: Text(
          'Block ${widget.peerName}?',
          style: GoogleFonts.dmSans(color: NytoColors.cream),
        ),
        content: Text(
          'They won’t be able to message you.',
          style: GoogleFonts.dmSans(
            color: NytoColors.cream.withValues(alpha: 0.7),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(
              'Block',
              style: GoogleFonts.dmSans(color: NytoColors.ctaSoft),
            ),
          ),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await chatApi.blockUser(widget.peerUserId);
      if (!mounted) return;
      Navigator.of(context).pop();
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message), backgroundColor: NytoColors.surface),
      );
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: NytoColors.bg,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 8, 8, 8),
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
                          widget.peerName,
                          style: GoogleFonts.dmSans(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: NytoColors.cream,
                          ),
                        ),
                        Text(
                          _incomingRequest
                              ? 'Message request'
                              : _status == 'PENDING'
                                  ? 'Request sent'
                                  : 'Private',
                          style: GoogleFonts.dmSans(
                            fontSize: 12,
                            color: NytoColors.creamMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: _block,
                    tooltip: 'Block',
                    icon: Icon(
                      Icons.block,
                      color: NytoColors.cream.withValues(alpha: 0.65),
                    ),
                  ),
                ],
              ),
            ),
            Divider(
              height: 1,
              color: NytoColors.cream.withValues(alpha: 0.08),
            ),
            Expanded(child: _body()),
            if (_incomingRequest) _requestBar(),
            if (!_incomingRequest) _composer(),
            Padding(
              padding: const EdgeInsets.only(bottom: 10, top: 4),
              child: Text(
                'Private · from a NYTO table',
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

  Widget _body() {
    if (_loading) {
      return const Center(
        child: CircularProgressIndicator(color: NytoColors.ctaSoft),
      );
    }
    if (_error != null) {
      return Center(
        child: Text(
          _error!,
          style: GoogleFonts.dmSans(
            color: NytoColors.cream.withValues(alpha: 0.7),
          ),
        ),
      );
    }
    if (_messages.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Text(
            'Say hi. They’ll get a message request.',
            textAlign: TextAlign.center,
            style: GoogleFonts.dmSans(
              color: NytoColors.cream.withValues(alpha: 0.5),
            ),
          ),
        ),
      );
    }
    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
      itemCount: _messages.length,
      itemBuilder: (_, i) {
        final msg = _messages[i];
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Align(
            alignment: msg.isYou ? Alignment.centerRight : Alignment.centerLeft,
            child: Column(
              crossAxisAlignment:
                  msg.isYou ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              children: [
                Container(
                  constraints: BoxConstraints(
                    maxWidth: MediaQuery.sizeOf(context).width * 0.78,
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    gradient: msg.isYou
                        ? const LinearGradient(
                            colors: [NytoColors.ctaDeep, NytoColors.cta],
                          )
                        : null,
                    color: msg.isYou ? null : NytoColors.surface,
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
          ),
        );
      },
    );
  }

  Widget _requestBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: Column(
        children: [
          Text(
            '${widget.peerName} wants to chat. Accept, or reply to accept.',
            textAlign: TextAlign.center,
            style: GoogleFonts.dmSans(
              fontSize: 13,
              color: NytoColors.cream.withValues(alpha: 0.65),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: _decline,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: NytoColors.cream,
                    side: BorderSide(
                      color: NytoColors.cream.withValues(alpha: 0.25),
                    ),
                  ),
                  child: const Text('Decline'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: FilledButton(
                  onPressed: _accept,
                  style: FilledButton.styleFrom(
                    backgroundColor: NytoColors.cta,
                    foregroundColor: NytoColors.cream,
                  ),
                  child: const Text('Accept'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          _composer(),
        ],
      ),
    );
  }

  Widget _composer() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _controller,
              enabled: !_sending,
              style: GoogleFonts.dmSans(fontSize: 15, color: NytoColors.cream),
              minLines: 1,
              maxLines: 4,
              textInputAction: TextInputAction.send,
              onSubmitted: (_) => _send(),
              decoration: InputDecoration(
                hintText: 'Message…',
                hintStyle: GoogleFonts.dmSans(color: NytoColors.creamMuted),
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
              child: const SizedBox(
                width: 46,
                height: 46,
                child: Icon(Icons.send_rounded, size: 20, color: NytoColors.cream),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
