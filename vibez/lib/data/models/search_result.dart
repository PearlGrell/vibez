class SearchSong {
  final String id;
  final String title;
  final String album;
  final String artists;
  final int duration;
  final String thumbnail;

  const SearchSong({
    required this.id,
    required this.title,
    required this.album,
    required this.artists,
    required this.duration,
    required this.thumbnail,
  });

  factory SearchSong.fromJson(Map<String, dynamic> json) {
    return SearchSong(
      id: json['id'] as String? ?? '',
      title: json['title'] as String? ?? '',
      album: json['album'] as String? ?? '',
      artists: json['artists'] as String? ?? '',
      duration: json['duration'] as int? ?? 0,
      thumbnail: json['thumbnail'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'album': album,
      'artists': artists,
      'duration': duration,
      'thumbnail': thumbnail,
    };
  }
}

class SearchArtist {
  final String id;
  final String name;
  final String thumbnail;

  const SearchArtist({
    required this.id,
    required this.name,
    required this.thumbnail,
  });

  factory SearchArtist.fromJson(Map<String, dynamic> json) {
    return SearchArtist(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      thumbnail: json['thumbnail'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'thumbnail': thumbnail,
    };
  }
}

class SearchAlbum {
  final String id;
  final String title;
  final String artists;
  final String thumbnail;
  final String type;
  final String year;

  const SearchAlbum({
    required this.id,
    required this.title,
    required this.artists,
    required this.thumbnail,
    required this.type,
    required this.year,
  });

  factory SearchAlbum.fromJson(Map<String, dynamic> json) {
    return SearchAlbum(
      id: json['id'] as String? ?? '',
      title: json['title'] as String? ?? '',
      artists: json['artists'] as String? ?? '',
      thumbnail: json['thumbnail'] as String? ?? '',
      type: json['type'] as String? ?? '',
      year: json['year'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'artists': artists,
      'thumbnail': thumbnail,
      'type': type,
      'year': year,
    };
  }
}

class SearchResult {
  final List<SearchSong> songs;
  final List<SearchArtist> artists;
  final List<SearchAlbum> albums;

  const SearchResult({
    required this.songs,
    required this.artists,
    required this.albums,
  });

  factory SearchResult.fromJson(Map<String, dynamic> json) {
    return SearchResult(
      songs: json['songs'] != null
          ? (json['songs'] as List)
              .map((e) => SearchSong.fromJson(e as Map<String, dynamic>))
              .toList()
          : [],
      artists: json['artists'] != null
          ? (json['artists'] as List)
              .map((e) => SearchArtist.fromJson(e as Map<String, dynamic>))
              .toList()
          : [],
      albums: json['albums'] != null
          ? (json['albums'] as List)
              .map((e) => SearchAlbum.fromJson(e as Map<String, dynamic>))
              .toList()
          : [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'songs': songs.map((e) => e.toJson()).toList(),
      'artists': artists.map((e) => e.toJson()).toList(),
      'albums': albums.map((e) => e.toJson()).toList(),
    };
  }
}
