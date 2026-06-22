import 'album.dart';
import 'artist.dart';
import 'playlist.dart';

class Song {
  final String id;
  final String title;
  final int duration;
  final String? thumbnail;
  final String? year;
  final Album? album;
  final String? albumId;
  final List<Artist>? artists;
  final List<Playlist>? playlists;

  const Song({
    required this.id,
    required this.title,
    required this.duration,
    this.thumbnail,
    this.year,
    this.album,
    this.albumId,
    this.artists,
    this.playlists,
  });

  Song copyWith({
    String? id,
    String? title,
    int? duration,
    String? thumbnail,
    String? year,
    Album? album,
    String? albumId,
    List<Artist>? artists,
    List<Playlist>? playlists,
  }) {
    return Song(
      id: id ?? this.id,
      title: title ?? this.title,
      duration: duration ?? this.duration,
      thumbnail: thumbnail ?? this.thumbnail,
      year: year ?? this.year,
      album: album ?? this.album,
      albumId: albumId ?? this.albumId,
      artists: artists ?? this.artists,
      playlists: playlists ?? this.playlists,
    );
  }

  factory Song.fromJson(Map<String, dynamic> json) {
    return Song(
      id: json['id'] as String? ?? '',
      title: json['title'] as String? ?? '',
      duration: json['duration'] as int? ?? 0,
      thumbnail: json['thumbnail'] as String?,
      year: json['year'] as String?,
      album: json['album'] != null && json['album'] is Map<String, dynamic>
          ? Album.fromJson(json['album'] as Map<String, dynamic>)
          : null,
      albumId: json['albumId'] as String?,
      artists: json['artists'] != null
          ? (json['artists'] as List).map((e) => Artist.fromJson(e as Map<String, dynamic>)).toList()
          : null,
      playlists: json['playlists'] != null
          ? (json['playlists'] as List).map((e) => Playlist.fromJson(e as Map<String, dynamic>)).toList()
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'duration': duration,
      if (thumbnail != null) 'thumbnail': thumbnail,
      if (year != null) 'year': year,
      if (album != null) 'album': album?.toJson(),
      if (albumId != null) 'albumId': albumId,
      if (artists != null) 'artists': artists?.map((e) => e.toJson()).toList(),
      if (playlists != null) 'playlists': playlists?.map((e) => e.toJson()).toList(),
    };
  }
}
