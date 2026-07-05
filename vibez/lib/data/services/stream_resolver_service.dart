import 'package:youtube_explode_dart/youtube_explode_dart.dart';
import 'package:vibez/core/utils/app_logger.dart';
import 'package:vibez/data/models/playback_info.dart';
import 'package:vibez/data/services/innertube_extractor.dart';

class StreamResolverService {
  StreamResolverService._();
  static final StreamResolverService instance = StreamResolverService._();

  final YoutubeExplode _yt = YoutubeExplode();

  static final List<List<YoutubeApiClient>> _clientChain = [
    [YoutubeApiClient.androidVr],
    [YoutubeApiClient.tv],
  ];

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
