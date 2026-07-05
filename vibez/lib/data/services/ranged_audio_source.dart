// ignore_for_file: experimental_member_use

import 'dart:async';
import 'dart:io';

import 'package:just_audio/just_audio.dart';

class RangedCachingAudioSource extends StreamAudioSource {
  final Uri uri;
  final String contentType;
  final File? cacheFile;
  final Map<String, String>? headers;

  int? _sourceLength;
  bool _writingCache = false;

  static const int _chunkSize = 1 << 20;

  static final HttpClient _http = HttpClient()
    ..connectionTimeout = const Duration(seconds: 15);

  RangedCachingAudioSource(
    this.uri, {
    required this.contentType,
    this.cacheFile,
    this.headers,
    super.tag,
  });

  @override
  Future<StreamAudioResponse> request([int? start, int? end]) async {
    start ??= 0;

    final cache = cacheFile;
    if (cache != null && cache.existsSync()) {
      final total = cache.lengthSync();
      final effectiveEnd = (end == null || end > total) ? total : end;
      return StreamAudioResponse(
        sourceLength: total,
        contentLength: effectiveEnd - start,
        offset: start,
        stream: cache.openRead(start, effectiveEnd),
        contentType: contentType,
      );
    }

    final first = await _fetchChunk(start, _chunkEndFor(start, end));
    var total = _sourceLength;
    final contentRange = first.headers.value(HttpHeaders.contentRangeHeader);
    if (contentRange != null && contentRange.contains('/')) {
      total = int.tryParse(contentRange.split('/').last) ?? total;
    } else if (first.statusCode == 200 && first.contentLength > 0) {
      total = first.contentLength;
    }
    _sourceLength = total;

    final endExclusive = end ?? total;
    final shouldCache =
        cache != null &&
        start == 0 &&
        end == null &&
        total != null &&
        !_writingCache;
    if (shouldCache) _writingCache = true;

    return StreamAudioResponse(
      sourceLength: total,
      contentLength: endExclusive != null ? endExclusive - start : null,
      offset: start,
      stream: _chunkedStream(
        first,
        start,
        endExclusive,
        shouldCache ? cache : null,
        total,
      ),
      contentType: contentType,
    );
  }

  int _chunkEndFor(int from, int? endExclusive) {
    var to = from + _chunkSize - 1;
    if (endExclusive != null && to > endExclusive - 1) to = endExclusive - 1;
    final total = _sourceLength;
    if (total != null && to > total - 1) to = total - 1;
    return to;
  }

  Future<HttpClientResponse> _fetchChunk(int from, int to) async {
    final request = await _http.getUrl(uri);
    headers?.forEach((name, value) => request.headers.set(name, value));
    request.headers.set(HttpHeaders.rangeHeader, 'bytes=$from-$to');
    final response = await request.close();
    if (response.statusCode != 200 && response.statusCode != 206) {
      response.listen((_) {}).cancel();
      throw HttpException(
        'Stream request failed: HTTP ${response.statusCode} (bytes=$from-$to)',
        uri: uri,
      );
    }
    return response;
  }

  Stream<List<int>> _chunkedStream(
    HttpClientResponse first,
    int start,
    int? endExclusive,
    File? cacheTarget,
    int? total,
  ) async* {
    final partFile = cacheTarget != null
        ? File('${cacheTarget.path}.part')
        : null;
    IOSink? sink;
    var written = 0;
    var completed = false;
    try {
      if (partFile != null) {
        try {
          sink = partFile.openWrite();
        } catch (_) {}
      }
      var pos = start;
      var response = first;
      while (true) {
        await for (final chunk in response) {
          pos += chunk.length;
          if (sink != null) {
            written += chunk.length;
            sink.add(chunk);
          }
          yield chunk;
        }
        final stop = endExclusive ?? total;
        if (stop == null || pos >= stop) break;
        response = await _fetchChunk(pos, _chunkEndFor(pos, endExclusive));
      }
      completed = true;
    } finally {
      if (cacheTarget != null) {
        _writingCache = false;
        try {
          await sink?.close();
          if (completed && total != null && written == total) {
            await partFile!.rename(cacheTarget.path);
          } else if (partFile != null && partFile.existsSync()) {
            await partFile.delete();
          }
        } catch (_) {}
      }
    }
  }
}
