import 'artist.dart';
import 'song.dart';

class Album {
  final String id;
  final String title;
  final String? type;
  final String? thumbnail;
  final bool isExplicit;
  final String? description;
  final String? year;
  final int? trackCount;
  final int? durationSeconds;
  final List<Artist>? artists;
  final List<Song>? songs;

  const Album({
    required this.id,
    required this.title,
    this.type,
    this.thumbnail,
    this.isExplicit = false,
    this.description,
    this.year,
    this.trackCount,
    this.durationSeconds,
    this.artists,
    this.songs,
  });

  Album copyWith({
    String? id,
    String? title,
    String? type,
    String? thumbnail,
    bool? isExplicit,
    String? description,
    String? year,
    int? trackCount,
    int? durationSeconds,
    List<Artist>? artists,
    List<Song>? songs,
  }) {
    return Album(
      id: id ?? this.id,
      title: title ?? this.title,
      type: type ?? this.type,
      thumbnail: thumbnail ?? this.thumbnail,
      isExplicit: isExplicit ?? this.isExplicit,
      description: description ?? this.description,
      year: year ?? this.year,
      trackCount: trackCount ?? this.trackCount,
      durationSeconds: durationSeconds ?? this.durationSeconds,
      artists: artists ?? this.artists,
      songs: songs ?? this.songs,
    );
  }

  factory Album.fromJson(Map<String, dynamic> json) {
    return Album(
      id: json['id'] as String? ?? '',
      title: json['title'] as String? ?? '',
      type: json['type'] as String?,
      thumbnail: json['thumbnail'] as String?,
      isExplicit: json['isExplicit'] as bool? ?? false,
      description: json['description'] as String?,
      year: json['year'] as String?,
      trackCount: json['trackCount'] as int?,
      durationSeconds: json['durationSeconds'] as int?,
      artists: json['artists'] != null
          ? (json['artists'] as List).map((e) => Artist.fromJson(e as Map<String, dynamic>)).toList()
          : null,
      songs: json['songs'] != null
          ? (json['songs'] as List).map((e) => Song.fromJson(e as Map<String, dynamic>)).toList()
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      if (type != null) 'type': type,
      if (thumbnail != null) 'thumbnail': thumbnail,
      'isExplicit': isExplicit,
      if (description != null) 'description': description,
      if (year != null) 'year': year,
      if (trackCount != null) 'trackCount': trackCount,
      if (durationSeconds != null) 'durationSeconds': durationSeconds,
      if (artists != null) 'artists': artists?.map((e) => e.toJson()).toList(),
      if (songs != null) 'songs': songs?.map((e) => e.toJson()).toList(),
    };
  }
}
