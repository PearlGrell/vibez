import 'dart:async';

import 'package:flutter/services.dart';

class AudioReactiveService {
  AudioReactiveService._();
  static final AudioReactiveService instance = AudioReactiveService._();

  static const _method = MethodChannel('vibez/audio_reactive');
  static const _events = EventChannel('vibez/audio_reactive/events');

  final _controller = StreamController<double>.broadcast();
  StreamSubscription<dynamic>? _sub;
  int? _sessionId;

  Stream<double> get level => _controller.stream;

  Future<void> start(int sessionId) async {
    if (_sessionId == sessionId && _sub != null) return;
    _sessionId = sessionId;
    _sub ??= _events.receiveBroadcastStream().listen((event) {
      if (event is num) _controller.add(event.toDouble());
    }, onError: (_) {});
    try {
      await _method.invokeMethod('start', {'sessionId': sessionId});
    } catch (_) {}
  }

  Future<void> stop() async {
    _sessionId = null;
    try {
      await _method.invokeMethod('stop');
    } catch (_) {}
  }
}
