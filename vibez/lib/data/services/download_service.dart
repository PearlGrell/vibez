import 'dart:async';
import 'dart:io';

import 'package:path_provider/path_provider.dart';

class DownloadService {
  DownloadService._();

  static Directory? _dir;

  static final HttpClient _http = HttpClient()
    ..connectionTimeout = const Duration(seconds: 20);

  static Future<void> init() async {
    try {
      final docs = await getApplicationDocumentsDirectory();
      final dir = Directory('${docs.path}/downloads');
      if (!await dir.exists()) await dir.create(recursive: true);
      _dir = dir;
    } catch (_) {}
  }

  static File? fileFor(String songId) {
    final dir = _dir;
    if (dir == null) return null;
    return File('${dir.path}/$songId.audio');
  }

  static bool isDownloaded(String songId) {
    final file = fileFor(songId);
    return file != null && file.existsSync();
  }

  static Future<bool> download(
    String songId,
    String url, {
    Map<String, String>? headers,
  }) async {
    final target = fileFor(songId);
    if (target == null) return false;
    if (await target.exists()) return true;

    final temp = File('${target.path}.part');
    IOSink? sink;
    try {
      final request = await _http.getUrl(Uri.parse(url));
      headers?.forEach((name, value) => request.headers.set(name, value));

      request.headers.set(HttpHeaders.rangeHeader, 'bytes=0-');
      final response = await request.close();
      if (response.statusCode != 200 && response.statusCode != 206) {
        await response.drain<void>();
        return false;
      }
      sink = temp.openWrite();
      await response.forEach(sink.add);
      await sink.close();
      sink = null;
      await temp.rename(target.path);
      return true;
    } catch (_) {
      try {
        await sink?.close();
      } catch (_) {}
      if (await temp.exists()) {
        try {
          await temp.delete();
        } catch (_) {}
      }
      return false;
    }
  }

  static Future<void> remove(String songId) async {
    final file = fileFor(songId);
    if (file != null && await file.exists()) {
      try {
        await file.delete();
      } catch (_) {}
    }
  }
}
