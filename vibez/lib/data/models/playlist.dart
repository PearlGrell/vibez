import 'song.dart';
import 'user.dart';

class Playlist {
  final String id;
  final String name;
  final String? description;
  final String? thumbnail;
  final List<String> tags;
  final bool private;
  final List<Song>? songs;
  final String createdById;
  final User? createdBy;

  const Playlist({
    required this.id,
    required this.name,
    this.description,
    this.thumbnail,
    this.tags = const [],
    this.private = false,
    this.songs,
    required this.createdById,
    this.createdBy,
  });

  Playlist copyWith({
    String? id,
    String? name,
    String? description,
    bool clearDescription = false,
    String? thumbnail,
    List<String>? tags,
    bool? private,
    List<Song>? songs,
    String? createdById,
    User? createdBy,
  }) {
    return Playlist(
      id: id ?? this.id,
      name: name ?? this.name,
      description: clearDescription ? null : (description ?? this.description),
      thumbnail: thumbnail ?? this.thumbnail,
      tags: tags ?? this.tags,
      private: private ?? this.private,
      songs: songs ?? this.songs,
      createdById: createdById ?? this.createdById,
      createdBy: createdBy ?? this.createdBy,
    );
  }

  factory Playlist.fromJson(Map<String, dynamic> json) {
    return Playlist(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      description: json['description'] as String?,
      thumbnail: json['thumbnail'] as String?,
      tags: json['tags'] != null ? List<String>.from(json['tags'] as List) : [],
      private: json['private'] as bool? ?? false,
      songs: json['songs'] != null
          ? (json['songs'] as List).map((e) => Song.fromJson(e as Map<String, dynamic>)).toList()
          : null,
      createdById: json['createdById'] as String? ?? '',
      createdBy: json['createdBy'] != null ? User.fromJson(json['createdBy'] as Map<String, dynamic>) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      if (description != null) 'description': description,
      if (thumbnail != null) 'thumbnail': thumbnail,
      'tags': tags,
      'private': private,
      if (songs != null) 'songs': songs?.map((e) => e.toJson()).toList(),
      'createdById': createdById,
      if (createdBy != null) 'createdBy': createdBy?.toJson(),
    };
  }
}
