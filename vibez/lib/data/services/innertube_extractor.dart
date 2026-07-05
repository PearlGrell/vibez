import 'dart:convert';
import 'dart:io';

import 'package:vibez/core/utils/app_logger.dart';
import 'package:vibez/data/models/playback_info.dart';

class InnertubeClient {
  final String clientName;
  final String clientVersion;
  final int clientId;
  final String userAgent;
  final int? androidSdkVersion;
  final String? deviceMake;
  final String? deviceModel;
  final String? osName;
  final String? osVersion;

  const InnertubeClient({
    required this.clientName,
    required this.clientVersion,
    required this.clientId,
    required this.userAgent,
    this.androidSdkVersion,
    this.deviceMake,
    this.deviceModel,
    this.osName,
    this.osVersion,
  });

  Map<String, dynamic> toContext(String visitorData) => {
    'clientName': clientName,
    'clientVersion': clientVersion,
    'userAgent': userAgent,
    'hl': 'en',
    'timeZone': 'UTC',
    'utcOffsetMinutes': 0,

    'visitorData': visitorData,
    if (androidSdkVersion != null) 'androidSdkVersion': androidSdkVersion,
    if (deviceMake != null) 'deviceMake': deviceMake,
    if (deviceModel != null) 'deviceModel': deviceModel,
    if (osName != null) 'osName': osName,
    if (osVersion != null) 'osVersion': osVersion,
  };
}

class _SessionRejected implements Exception {
  final String message;
  const _SessionRejected(this.message);
  @override
  String toString() => '_SessionRejected: $message';
}

class _VisitorSession {
  final String visitorData;
  final List<Cookie> cookies;
  final DateTime createdAt;

  _VisitorSession(this.visitorData, this.cookies) : createdAt = DateTime.now();

  bool get isStale =>
      DateTime.now().difference(createdAt) > const Duration(hours: 3);
}

class InnertubeExtractor {
  InnertubeExtractor._();
  static final InnertubeExtractor instance = InnertubeExtractor._();

  static const List<InnertubeClient> _clients = [
    InnertubeClient(
      clientName: 'ANDROID_VR',
      clientVersion: '1.65.10',
      clientId: 28,
      userAgent:
          'com.google.android.apps.youtube.vr.oculus/1.65.10 (Linux; U; Android 12L; eureka-user Build/SQ3A.220605.009.A1) gzip',
      androidSdkVersion: 32,
      deviceMake: 'Oculus',
      deviceModel: 'Quest 3',
      osName: 'Android',
      osVersion: '12L',
    ),
  ];

  static final Uri _playerEndpoint = Uri.parse(
    'https://www.youtube.com/youtubei/v1/player?prettyPrint=false',
  );
  static final Uri _warmupEndpoint = Uri.parse('https://www.youtube.com/');

  static const String _warmupUserAgent =
      'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 '
      '(KHTML, like Gecko) Chrome/126.0.0.0 Safari/537.36';

  final HttpClient _http = HttpClient()
    ..connectionTimeout = const Duration(seconds: 10);

  _VisitorSession? _session;

  Future<_VisitorSession>? _pendingSession;

  Future<PlaybackInfo?> resolve(String videoId) async {
    for (final client in _clients) {
      for (var attempt = 0; attempt < 2; attempt++) {
        try {
          final session = await _ensureSession(forceRefresh: attempt > 0);
          final info = await _tryClient(client, videoId, session);
          if (info != null) return info;
          break;
        } on _SessionRejected {
          continue;
        } catch (e) {
          AppLogger.instance.error(
            'Innertube ${client.clientName} failed for $videoId',
            error: e,
          );
          break;
        }
      }
    }
    return null;
  }

  Future<_VisitorSession> _ensureSession({bool forceRefresh = false}) {
    final current = _session;
    if (!forceRefresh && current != null && !current.isStale) {
      return Future.value(current);
    }
    final pending = _pendingSession;
    if (!forceRefresh && pending != null) return pending;

    final future = _warmupSession();
    _pendingSession = future;
    return future
        .then((session) {
          _session = session;
          _pendingSession = null;
          return session;
        })
        .catchError((Object e) {
          _pendingSession = null;
          throw e;
        });
  }

  Future<_VisitorSession> _warmupSession() async {
    final request = await _http.getUrl(_warmupEndpoint);
    request.headers.set(HttpHeaders.userAgentHeader, _warmupUserAgent);
    request.headers.set(HttpHeaders.acceptLanguageHeader, 'en-US,en;q=0.9');
    final response = await request.close();
    final cookies = response.cookies;
    final body = await utf8.decodeStream(response);

    final match = RegExp(r'"visitorData":"(.*?)"').firstMatch(body);
    if (match == null) {
      throw const _SessionRejected('visitorData missing from warmup page');
    }

    final visitorData = jsonDecode('"${match.group(1)}"') as String;
    return _VisitorSession(visitorData, cookies);
  }

  Future<PlaybackInfo?> _tryClient(
    InnertubeClient client,
    String videoId,
    _VisitorSession session,
  ) async {
    final request = await _http.postUrl(_playerEndpoint);
    request.headers.set(HttpHeaders.contentTypeHeader, 'application/json');
    request.headers.set(HttpHeaders.userAgentHeader, client.userAgent);
    request.headers.set('X-YouTube-Client-Name', '${client.clientId}');
    request.headers.set('X-YouTube-Client-Version', client.clientVersion);
    request.headers.set('X-Goog-Visitor-Id', session.visitorData);
    request.headers.set('Origin', 'https://www.youtube.com');
    request.cookies.addAll(session.cookies);
    request.add(
      utf8.encode(
        jsonEncode({
          'videoId': videoId,
          'context': {'client': client.toContext(session.visitorData)},
          'contentCheckOk': true,
          'racyCheckOk': true,
        }),
      ),
    );

    final response = await request.close();
    if (response.statusCode != 200) {
      await response.drain<void>();
      return null;
    }
    final json =
        jsonDecode(await utf8.decodeStream(response)) as Map<String, dynamic>;

    final playability = json['playabilityStatus'] as Map<String, dynamic>?;
    final status = playability?['status'];
    if (status != 'OK') {
      if (status == 'LOGIN_REQUIRED') {
        throw _SessionRejected('LOGIN_REQUIRED for $videoId');
      }
      return null;
    }

    final formats =
        (json['streamingData'] as Map<String, dynamic>?)?['adaptiveFormats']
            as List?;
    if (formats == null) return null;

    Map<String, dynamic>? best;
    var bestBitrate = -1;
    for (final format in formats.cast<Map<String, dynamic>>()) {
      final mime = format['mimeType'] as String? ?? '';
      final url = format['url'] as String?;
      if (!mime.startsWith('audio/') || url == null) continue;
      final bitrate = (format['bitrate'] as num?)?.toInt() ?? 0;
      if (bitrate > bestBitrate) {
        bestBitrate = bitrate;
        best = format;
      }
    }
    if (best == null) return null;

    final url = best['url'] as String;
    if (!await _urlServes(url)) return null;

    final mime = (best['mimeType'] as String).split(';').first.trim();
    return PlaybackInfo(id: videoId, playbackUrl: url, mimeType: mime);
  }

  Future<bool> urlServes(String url) => _urlServes(url);

  Future<bool> _urlServes(String url) async {
    return await _probe(url, 'bytes=0-1') &&
        await _probe(url, 'bytes=65536-65537');
  }

  Future<bool> _probe(String url, String range) async {
    try {
      final request = await _http.getUrl(Uri.parse(url));
      request.headers.set(HttpHeaders.rangeHeader, range);
      final response = await request.close();
      await response.drain<void>();

      return response.statusCode == 200 ||
          response.statusCode == 206 ||
          response.statusCode == 416;
    } catch (_) {
      return false;
    }
  }
}
