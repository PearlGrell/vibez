import 'album.dart';
import 'song.dart';

class Artist {
  final String id;
  final String name;
  final String? thumbnail;
  final String? description;
  final String? subscribers;
  final String? views;
  final String? monthlyListeners;
  final List<Song>? songs;
  final List<Album>? albums;
  final String? songsBrowseId;
  final String? albumsBrowseId;
  final String? albumsParams;

  const Artist({
    required this.id,
    required this.name,
    this.thumbnail,
    this.description,
    this.subscribers,
    this.views,
    this.monthlyListeners,
    this.songs,
    this.albums,
    this.songsBrowseId,
    this.albumsBrowseId,
    this.albumsParams,
  });

  Artist copyWith({
    String? id,
    String? name,
    String? thumbnail,
    String? description,
    String? subscribers,
    String? views,
    String? monthlyListeners,
    List<Song>? songs,
    List<Album>? albums,
    String? songsBrowseId,
    String? albumsBrowseId,
    String? albumsParams,
  }) {
    return Artist(
      id: id ?? this.id,
      name: name ?? this.name,
      thumbnail: thumbnail ?? this.thumbnail,
      description: description ?? this.description,
      subscribers: subscribers ?? this.subscribers,
      views: views ?? this.views,
      monthlyListeners: monthlyListeners ?? this.monthlyListeners,
      songs: songs ?? this.songs,
      albums: albums ?? this.albums,
      songsBrowseId: songsBrowseId ?? this.songsBrowseId,
      albumsBrowseId: albumsBrowseId ?? this.albumsBrowseId,
      albumsParams: albumsParams ?? this.albumsParams,
    );
  }

  factory Artist.fromJson(Map<String, dynamic> json) {
    return Artist(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      thumbnail: json['thumbnail'] as String?,
      description: json['description'] as String?,
      subscribers: json['subscribers'] as String?,
      views: json['views'] as String?,
      monthlyListeners: json['monthlyListeners'] as String?,
      songs: json['songs'] != null
          ? (json['songs'] as List).map((e) => Song.fromJson(e as Map<String, dynamic>)).toList()
          : null,
      albums: json['albums'] != null
          ? (json['albums'] as List).map((e) => Album.fromJson(e as Map<String, dynamic>)).toList()
          : null,
      songsBrowseId: json['songsBrowseId'] as String?,
      albumsBrowseId: json['albumsBrowseId'] as String?,
      albumsParams: json['albumsParams'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      if (thumbnail != null) 'thumbnail': thumbnail,
      if (description != null) 'description': description,
      if (subscribers != null) 'subscribers': subscribers,
      if (views != null) 'views': views,
      if (monthlyListeners != null) 'monthlyListeners': monthlyListeners,
      if (songs != null) 'songs': songs?.map((e) => e.toJson()).toList(),
      if (albums != null) 'albums': albums?.map((e) => e.toJson()).toList(),
    };
  }
}
