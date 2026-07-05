import 'package:youtube_explode_dart/youtube_explode_dart.dart';
import 'package:vibez/core/utils/app_logger.dart';
import 'package:vibez/data/models/playback_info.dart';
import 'package:vibez/data/services/innertube_extractor.dart';

/// Resolves playback URLs directly on the device.
///
/// Stream URLs returned by YouTube are bound to the IP that requested them,
/// so resolving on-device (residential IP) avoids the 403 / bot-check errors
/// that server-side extraction hits from datacenter IPs.
class StreamResolverService {
  StreamResolverService._();
  static final StreamResolverService instance = StreamResolverService._();

  final YoutubeExplode _yt = YoutubeExplode();

  // Only clients whose URLs are fully downloadable without a PO token.
  // android/ios URLs die after ~1MB (GVS PO-token gating) so they are
  // deliberately excluded — a URL that can't finish a song is worse than
  // falling through to the backend relay.
  static final List<List<YoutubeApiClient>> _clientChain = [
    [YoutubeApiClient.androidVr],
    [YoutubeApiClient.tv],
  ];

  /// Compact identifier of a stream URL for logs: host + the innertube
  /// client id (`c`) and expiry that are baked into googlevideo URLs.
  static String _urlFingerprint(String url) {
    try {
      final uri = Uri.parse(url);
      return 'host=${uri.host} c=${uri.queryParameters['c']} '
          'expire=${uri.queryParameters['expire']}';
    } catch (_) {
      return url.length > 80 ? url.substring(0, 80) : url;
    }
  }

  Future<PlaybackInfo?> resolve(String videoId) async {
    // Our own extractor first: client definitions are synced from yt-dlp
    // master and validated before use, so it stays current without waiting
    // on youtube_explode_dart releases.
    final own = await InnertubeExtractor.instance.resolve(videoId);
    if (own != null) {
      AppLogger.instance.info(
        'Resolved $videoId via own extractor',
        data: _urlFingerprint(own.playbackUrl),
      );
      return own;
    }

    for (final clients in _clientChain) {
      try {
        // Skip the youtube.com/watch page fetch: the innertube API clients
        // below don't need it, and that page is where YouTube applies
        // bot/rate-limit checks (RequestLimitExceededException).
        final manifest = await _yt.videos.streams.getManifest(
          videoId,
          ytClients: clients,
          requireWatchPage: false,
        );

        final audioStreams = manifest.audioOnly;
        final stream = audioStreams.isNotEmpty
            ? audioStreams.withHighestBitrate()
            : (manifest.muxed.isNotEmpty
                  ? manifest.muxed.withHighestBitrate()
                  : null);
        if (stream == null) continue;

        final url = stream.url.toString();
        if (!await InnertubeExtractor.instance.urlServes(url)) {
          AppLogger.instance.info(
            'Explode tier ${_clientChain.indexOf(clients) + 1} URL rejected '
            'for $videoId (unplayable by player)',
          );
          continue;
        }

        final container = stream.container.name;
        AppLogger.instance.info(
          'Resolved $videoId via explode tier ${_clientChain.indexOf(clients) + 1}',
          data: _urlFingerprint(url),
        );
        return PlaybackInfo(
          id: videoId,
          playbackUrl: stream.url.toString(),
          mimeType: container == 'mp4' || container == 'm4a'
              ? 'audio/mp4'
              : 'audio/$container',
        );
      } catch (e) {
        AppLogger.instance.error(
          'Local stream resolution failed for $videoId',
          error: e,
        );
      }
    }
    return null;
  }
}
