import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:socket_io_client/socket_io_client.dart' as ws;
import 'package:vibez/core/storage/token_storage.dart';

class SocketClient {
  static final SocketClient instance = SocketClient._();

  SocketClient._();

  final TokenStorage _tokenStorage = TokenStorage.instance;

  late ws.Socket _socket;

  String _resolveUrl(String url) {
    if (Platform.isAndroid && url.contains('localhost')) {
      return url.replaceAll('localhost', '10.0.2.2');
    }
    return url;
  }

  Future<void> initialize() async {
    final accessToken = await _tokenStorage.accessToken;
    _socket = ws.io(
      _resolveUrl(dotenv.get('API_URL', fallback: 'http://localhost:3000')),
      ws.OptionBuilder()
          .setTransports(['websocket'])
          .setAuth({'token': accessToken})
          .disableAutoConnect()
          .build(),
    );

    final completer = Completer<void>();

    _socket.onConnect((_) {
      if (!completer.isCompleted) completer.complete();
    });
    _socket.onConnectError((err) {
      debugPrint('Socket connect error: $err');
      if (!completer.isCompleted) completer.completeError(err);
    });

    _socket.connect();

    return completer.future.timeout(
      const Duration(seconds: 10),
      onTimeout: () => throw TimeoutException('Socket connection timed out'),
    );
  }

  void connect() => _socket.connect();
  void disconnect() => _socket.disconnect();

  Future<void> reconnect() async {
    _socket.disconnect();
    _socket.dispose();

    final accessToken = await _tokenStorage.accessToken;

    _socket = ws.io(
      _resolveUrl(dotenv.get('API_URL')),
      ws.OptionBuilder()
          .setTransports(['websocket'])
          .setAuth({'token': accessToken})
          .disableAutoConnect()
          .build(),
    );

    final completer = Completer<void>();

    _socket.onConnect((_) {
      if (!completer.isCompleted) completer.complete();
    });
    _socket.onConnectError((err) {
      debugPrint('Socket reconnect error: $err');
      if (!completer.isCompleted) completer.completeError(err);
    });

    _socket.connect();

    return completer.future.timeout(
      const Duration(seconds: 10),
      onTimeout: () => throw TimeoutException('Socket connection timed out'),
    );
  }

  void emit(String event, [dynamic data]) => _socket.emit(event, data);

  Future<dynamic> emitWithAck(String event, [dynamic data, Duration? timeout]) {
    final completer = Completer<dynamic>();
    final effectiveTimeout = timeout ?? const Duration(seconds: 10);

    _socket.emitWithAck(event, data, ack: (dynamic response) {
      if (!completer.isCompleted) {
        completer.complete(response);
      }
    });

    return completer.future.timeout(
      effectiveTimeout,
      onTimeout: () => throw TimeoutException(
        'Socket event "$event" timed out after ${effectiveTimeout.inSeconds}s',
      ),
    );
  }

  void on(String event, Function(dynamic) callback) =>
      _socket.on(event, callback);
  void off(String event, [Function(dynamic)? callback]) =>
      _socket.off(event, callback);

  Stream<T> stream<T>(String event){
    late StreamController<T> controller;

    void listener(dynamic data) {
      controller.add(data as T);
    }

    controller = StreamController<T>.broadcast(
      onListen: () => _socket.on(event, listener),
      onCancel: () {
        _socket.off(event, listener);
        controller.close();
      }
    );
    return controller.stream;
  }

  Stream<bool> connectionStream() {
    late StreamController<bool> controller;

    controller = StreamController<bool>.broadcast(
      onListen: () {
        _socket.onConnect((_) => controller.add(true));
        _socket.onDisconnect((_) => controller.add(false));
        _socket.onConnectError((_) => controller.add(false));
      },
      onCancel: () {
        controller.close();
      }
    );
    return controller.stream;
  }
}
