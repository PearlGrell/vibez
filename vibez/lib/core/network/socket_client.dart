import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:socket_io_client/socket_io_client.dart' as ws;
import 'package:vibez/core/storage/token_storage.dart';

class SocketClient {
  static final SocketClient instance = SocketClient._();

  SocketClient._();

  final TokenStorage _tokenStorage = TokenStorage.instance;

  late final ws.Socket _socket;

  Future<void> initialize() async {
    final accessToken = await _tokenStorage.accessToken;

    _socket = ws.io(
      dotenv.get('API_URL', fallback: 'http://localhost:3000'),
      ws.OptionBuilder()
          .setTransports(['websocket'])
          .setAuth({'token': accessToken})
          .disableAutoConnect()
          .build(),
    );
  }

  void connect() => _socket.connect();
  void disconnect() => _socket.disconnect();

  Future<void> reconnect() async {
    _socket.disconnect();
    _socket.dispose();

    final accessToken = await _tokenStorage.accessToken;

    _socket = ws.io(
      dotenv.get('API_URL'),
      ws.OptionBuilder()
          .setTransports(['websocket'])
          .setAuth({'token': accessToken})
          .disableAutoConnect()
          .build(),
    );

    _socket.connect();
  }

  void emit(String event, [dynamic data]) => _socket.emit(event, data);
  void on(String event, Function(dynamic) callback) =>
      _socket.on(event, callback);
  void off(String event, [Function(dynamic)? callback]) =>
      _socket.off(event, callback);
}
