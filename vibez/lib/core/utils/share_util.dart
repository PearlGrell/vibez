import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

enum ShareMode { artist, album, playlist, room, user }

class SharePayload {
  final String subject;
  final String message;

  const SharePayload({required this.subject, required this.message});
}

class ShareUtil {
  final ShareMode shareMode;
  final String id;
  final String title;
  final String? url;

  const ShareUtil({
    required this.shareMode,
    required this.id,
    required this.title,
    this.url,
  });

  Future<bool> share() async {
    final payload = _payload;
    final link = 'https://vibez-chi.vercel.app/${shareMode.name}/$id';

    XFile? file;

    if (url != null && url!.isNotEmpty) {
      final dir = await getTemporaryDirectory();
      final path = '${dir.path}/share.jpg';

      await Dio().download(url!, path);

      file = XFile(path);
    }

    final result = await SharePlus.instance.share(
      ShareParams(
        subject: payload.subject,
        text: '${payload.message}\n\n$link',
        files: file != null ? [file] : null,
      ),
    );

    return result.status == ShareResultStatus.success;
  }

  SharePayload get _payload {
    switch (shareMode) {
      case ShareMode.artist:
        return SharePayload(
          subject: 'Discover $title on Vibez',
          message: 'Take a listen to $title on Vibez.',
        );

      case ShareMode.album:
        return SharePayload(
          subject: '$title on Vibez',
          message: 'I think you’ll enjoy this album on Vibez.',
        );

      case ShareMode.playlist:
        return SharePayload(
          subject: '$title Playlist',
          message: 'Check out this playlist I wanted to share.',
        );

      case ShareMode.room:
        return SharePayload(
          subject: 'Join "$title"',
          message:
              'Join my listening room on Vibez and listen together in real time.',
        );

      case ShareMode.user:
        return SharePayload(
          subject: '$title is on Vibez',
          message: 'Take a look at this Vibez profile.',
        );
    }
  }
}
