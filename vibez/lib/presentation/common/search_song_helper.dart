import 'package:vibez/data/models/search_result.dart';
import 'package:vibez/data/models/song.dart';

class SearchSongHelper {
  static SearchSong fromSong(Song song, {String? albumTitle, String? artistName}) {
    return SearchSong(
      id: song.id,
      title: song.title,
      album: albumTitle ?? song.album?.title ?? '',
      duration: song.duration,
      thumbnail: song.thumbnail ?? '',
      artists: song.artists?.map((a) => a.name).join(', ') ?? artistName ?? '',
    );
  }
}
