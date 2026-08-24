import 'package:nyto_app/core/api/api_client.dart';

class ChatApi {
  ChatApi(this._api);

  final ApiClient _api;
  static const timeout = Duration(seconds: 12);

  Future<List<Map<String, dynamic>>> conversations() async {
    final json = await _api
        .get('/chat/conversations', auth: true)
        .timeout(timeout);
    final list = json['conversations'];
    if (list is! List) return [];
    return list.cast<Map<String, dynamic>>();
  }

  Future<Map<String, dynamic>> tableConversation(String tableId) {
    return _api
        .get('/chat/tables/$tableId', auth: true)
        .timeout(timeout);
  }

  Future<Map<String, dynamic>> messages(
    String tableId, {
    String? cursor,
    int limit = 50,
  }) {
    final query = <String, String>{'limit': '$limit'};
    if (cursor != null && cursor.isNotEmpty) query['cursor'] = cursor;
    return _api
        .get('/chat/tables/$tableId/messages', auth: true, query: query)
        .timeout(timeout);
  }

  Future<Map<String, dynamic>> sendMessage({
    required String tableId,
    required String body,
    String? clientMessageId,
  }) {
    return _api
        .post(
          '/chat/tables/$tableId/messages',
          auth: true,
          body: {
            'body': body,
            if (clientMessageId != null) 'clientMessageId': clientMessageId,
          },
        )
        .timeout(timeout);
  }

  Future<List<Map<String, dynamic>>> directConversations(String inbox) async {
    final json = await _api
        .get(
          '/chat/direct',
          auth: true,
          query: {'inbox': inbox},
        )
        .timeout(timeout);
    final list = json['conversations'];
    if (list is! List) return [];
    return list.cast<Map<String, dynamic>>();
  }

  Future<Map<String, dynamic>> openDirect(String userId) {
    return _api
        .post('/chat/direct/open', auth: true, body: {'userId': userId})
        .timeout(timeout);
  }

  Future<Map<String, dynamic>> directThread(String threadId) {
    return _api.get('/chat/direct/$threadId', auth: true).timeout(timeout);
  }

  Future<Map<String, dynamic>> directMessages(
    String threadId, {
    String? cursor,
    int limit = 50,
  }) {
    final query = <String, String>{'limit': '$limit'};
    if (cursor != null && cursor.isNotEmpty) query['cursor'] = cursor;
    return _api
        .get('/chat/direct/$threadId/messages', auth: true, query: query)
        .timeout(timeout);
  }

  Future<Map<String, dynamic>> sendDirectMessage({
    required String threadId,
    required String body,
    String? clientMessageId,
  }) {
    return _api
        .post(
          '/chat/direct/$threadId/messages',
          auth: true,
          body: {
            'body': body,
            if (clientMessageId != null) 'clientMessageId': clientMessageId,
          },
        )
        .timeout(timeout);
  }

  Future<Map<String, dynamic>> acceptDirect(String threadId) {
    return _api
        .post('/chat/direct/$threadId/accept', auth: true)
        .timeout(timeout);
  }

  Future<Map<String, dynamic>> declineDirect(String threadId) {
    return _api
        .post('/chat/direct/$threadId/decline', auth: true)
        .timeout(timeout);
  }

  Future<void> blockUser(String userId) async {
    await _api.post('/chat/direct/$userId/block', auth: true).timeout(timeout);
  }
}

final chatApi = ChatApi(apiClient);
