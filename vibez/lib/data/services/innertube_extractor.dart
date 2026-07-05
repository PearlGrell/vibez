import 'dart:convert';
import 'dart:io';

import 'package:vibez/core/utils/app_logger.dart';
import 'package:vibez/data/models/playback_info.dart';

/// A YouTube innertube API client definition.
///
/// Values are synced from yt-dlp master
/// (yt_dlp/extractor/youtube/_base.py, INNERTUBE_CLIENTS — last synced
/// 2026-07-05). When playback starts failing broadly, refreshing these
/// versions/user-agents against yt-dlp is the first thing to try.
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

  Map<String, dynamic> toContext() => {
    'clientName': clientName,
    'clientVersion': clientVersion,
    'userAgent': userAgent,
    'hl': 'en',
    'timeZone': 'UTC',
    'utcOffsetMinutes': 0,
    if (androidSdkVersion != null) 'androidSdkVersion': androidSdkVersion,
    if (deviceMake != null) 'deviceMake': deviceMake,
    if (deviceModel != null) 'deviceModel': deviceModel,
    if (osName != null) 'osName': osName,
    if (osVersion != null) 'osVersion': osVersion,
  };
}

/// Our own minimal YouTube audio extractor: talks to the innertube
/// `/player` endpoint directly, using client definitions kept in sync with
/// yt-dlp. Only clients that return direct (non-ciphered) stream URLs are
/// used, so no JS player or signature deciphering is ever needed.
///
/// Runs before youtube_explode_dart in the resolution chain: when YouTube
/// changes something, updating the constants above is enough — no waiting
/// on package releases.
class InnertubeExtractor {
  InnertubeExtractor._();
  static final InnertubeExtractor instance = InnertubeExtractor._();

  // ANDROID_VR is the only innertube client whose URLs are fully
  // downloadable without a PO token. ANDROID and IOS URLs are PO-token-gated:
  // they serve ~1MB (one request) and 403 everything after, so a song dies
  // mid-play — verified empirically 2026-07-05. Do not add them back without
  // a PO token provider; songs ANDROID_VR can't serve go to the backend relay.
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

  final HttpClient _http = HttpClient()
    ..connectionTimeout = const Duration(seconds: 10);

  Future<PlaybackInfo?> resolve(String videoId) async {
    for (final client in _clients) {
      try {
        final info = await _tryClient(client, videoId);
        if (info != null) return info;
      } catch (e) {
        AppLogger.instance.error(
          'Innertube ${client.clientName} failed for $videoId',
          error: e,
        );
      }
    }
    return null;
  }

  Future<PlaybackInfo?> _tryClient(
    InnertubeClient client,
    String videoId,
  ) async {
    final request = await _http.postUrl(_playerEndpoint);
    request.headers.set(HttpHeaders.contentTypeHeader, 'application/json');
    request.headers.set(HttpHeaders.userAgentHeader, client.userAgent);
    request.headers.set('X-YouTube-Client-Name', '${client.clientId}');
    request.headers.set('X-YouTube-Client-Version', client.clientVersion);
    request.headers.set('Origin', 'https://www.youtube.com');
    request.add(
      utf8.encode(
        jsonEncode({
          'videoId': videoId,
          'context': {'client': client.toContext()},
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
    if (playability?['status'] != 'OK') return null;

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

  /// Two-request validation under player-identical conditions (default Dart
  /// User-Agent, small bounded ranges). PO-token-gated URLs serve the first
  /// request and 403 afterwards — a single probe passes them and the song
  /// then dies mid-play, so the second probe from a later offset is what
  /// actually catches them. Also used by StreamResolverService to vet
  /// youtube_explode-produced URLs.
  Future<bool> urlServes(String url) => _urlServes(url);

  Future<bool> _urlServes(String url) async {
    return await _probe(url, 'bytes=0-1') && await _probe(url, 'bytes=65536-65537');
  }

  Future<bool> _probe(String url, String range) async {
    try {
      final request = await _http.getUrl(Uri.parse(url));
      request.headers.set(HttpHeaders.rangeHeader, range);
      final response = await request.close();
      await response.drain<void>();
      // 416 = requested range past EOF (very short file): not a block.
      return response.statusCode == 200 ||
          response.statusCode == 206 ||
          response.statusCode == 416;
    } catch (_) {
      return false;
    }
  }
}
