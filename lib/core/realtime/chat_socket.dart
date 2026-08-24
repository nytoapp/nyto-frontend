import 'package:nyto_app/core/api/api_client.dart';
import 'package:nyto_app/core/config/api_config.dart';
import 'package:socket_io_client/socket_io_client.dart' as io;

/// Socket.IO client for table group chat realtime events.
class ChatSocket {
  ChatSocket._();

  static io.Socket? _socket;

  static io.Socket? get socket => _socket;

  static Future<io.Socket> connect() async {
    final existing = _socket;
    if (existing != null && existing.connected) return existing;

    final token = await apiClient.getToken();
    if (token == null || token.isEmpty) {
      throw StateError('Not signed in');
    }

    final socket = io.io(
      ApiConfig.baseUrl,
      io.OptionBuilder()
          .setTransports(['websocket'])
          .disableAutoConnect()
          .setAuth({'token': token})
          .build(),
    );
    socket.connect();
    _socket = socket;
    return socket;
  }

  static void disconnect() {
    _socket?.dispose();
    _socket = null;
  }

  static void joinTable(String tableId) {
    _socket?.emit('table.join', {'tableId': tableId});
  }

  static void leaveTable(String tableId) {
    _socket?.emit('table.leave', {'tableId': tableId});
  }

  static void joinDm(String threadId) {
    _socket?.emit('dm.join', {'threadId': threadId});
  }

  static void leaveDm(String threadId) {
    _socket?.emit('dm.leave', {'threadId': threadId});
  }
}
