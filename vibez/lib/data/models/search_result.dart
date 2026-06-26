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

class SearchPlaylist {
  final String id;
  final String name;
  final String? description;
  final String? thumbnail;
  final List<String> tags;

  const SearchPlaylist({
    required this.id,
    required this.name,
    this.description,
    this.thumbnail,
    this.tags = const [],
  });

  factory SearchPlaylist.fromJson(Map<String, dynamic> json) {
    return SearchPlaylist(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      description: json['description'] as String?,
      thumbnail: json['thumbnail'] as String?,
      tags: json['tags'] != null ? List<String>.from(json['tags'] as List) : [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      if (description != null) 'description': description,
      if (thumbnail != null) 'thumbnail': thumbnail,
      'tags': tags,
    };
  }
}

class SearchRoom {
  final String id;
  final String name;
  final String description;
  final List<String> tags;
  final bool playing;
  final int participants;

  const SearchRoom({
    required this.id,
    required this.name,
    required this.description,
    this.tags = const [],
    this.playing = false,
    this.participants = 0,
  });

  factory SearchRoom.fromJson(Map<String, dynamic> json) {
    return SearchRoom(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      description: json['description'] as String? ?? '',
      tags: json['tags'] != null ? List<String>.from(json['tags'] as List) : [],
      playing: json['playing'] as bool? ?? false,
      participants: json['participants'] as int? ?? 0,
    );
  }

  SearchRoom copyWith({
    String? name,
    String? description,
    List<String>? tags,
    bool? playing,
    int? participants,
  }) {
    return SearchRoom(
      id: id,
      name: name ?? this.name,
      description: description ?? this.description,
      tags: tags ?? this.tags,
      playing: playing ?? this.playing,
      participants: participants ?? this.participants,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'tags': tags,
      'playing': playing,
      'participants': participants,
    };
  }
}

class SearchUser {
  final String id;
  final String name;
  final String? username;
  final String? profileUrl;

  const SearchUser({
    required this.id,
    required this.name,
    this.username,
    this.profileUrl,
  });

  factory SearchUser.fromJson(Map<String, dynamic> json) {
    return SearchUser(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      username: json['username'] as String?,
      profileUrl: json['profileUrl'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      if (username != null) 'username': username,
      if (profileUrl != null) 'profileUrl': profileUrl,
    };
  }
}

class SearchResult {
  final List<SearchSong> songs;
  final List<SearchArtist> artists;
  final List<SearchAlbum> albums;
  final List<SearchPlaylist> playlists;
  final List<SearchRoom> rooms;
  final List<SearchUser> users;

  const SearchResult({
    required this.songs,
    required this.artists,
    required this.albums,
    this.playlists = const [],
    this.rooms = const [],
    this.users = const [],
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
      playlists: json['playlists'] != null
          ? (json['playlists'] as List)
              .map((e) => SearchPlaylist.fromJson(e as Map<String, dynamic>))
              .toList()
          : [],
      rooms: json['rooms'] != null
          ? (json['rooms'] as List)
              .map((e) => SearchRoom.fromJson(e as Map<String, dynamic>))
              .toList()
          : [],
      users: json['users'] != null
          ? (json['users'] as List)
              .map((e) => SearchUser.fromJson(e as Map<String, dynamic>))
              .toList()
          : [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'songs': songs.map((e) => e.toJson()).toList(),
      'artists': artists.map((e) => e.toJson()).toList(),
      'albums': albums.map((e) => e.toJson()).toList(),
      'playlists': playlists.map((e) => e.toJson()).toList(),
      'rooms': rooms.map((e) => e.toJson()).toList(),
      'users': users.map((e) => e.toJson()).toList(),
    };
  }

  int get totalCount =>
      songs.length +
      artists.length +
      albums.length +
      playlists.length +
      rooms.length +
      users.length;
}
