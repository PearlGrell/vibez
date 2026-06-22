import 'album.dart';
import 'artist.dart';
import 'playlist.dart';
import 'room.dart';
import 'song.dart';

class User {
  final String id;
  final String name;
  final String email;
  final String? username;
  final String? profileUrl;
  final String? bio;
  final List<String>? tags;
  final List<Playlist>? playlists;
  final List<Song>? likedSongs;
  final List<Album>? likedAlbums;
  final List<Playlist>? likedPlaylists;
  final List<Artist>? followedArtists;
  final List<Room>? joinedRooms;
  final List<User>? followers;
  final List<User>? following;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const User({
    required this.id,
    required this.name,
    required this.email,
    this.username,
    this.profileUrl,
    this.bio,
    this.tags,
    this.playlists,
    this.likedSongs,
    this.likedAlbums,
    this.likedPlaylists,
    this.followedArtists,
    this.joinedRooms,
    this.followers,
    this.following,
    this.createdAt,
    this.updatedAt,
  });

  User copyWith({
    String? id,
    String? name,
    String? email,
    String? username,
    String? profileUrl,
    String? bio,
    List<String>? tags,
    List<Playlist>? playlists,
    List<Song>? likedSongs,
    List<Album>? likedAlbums,
    List<Playlist>? likedPlaylists,
    List<Artist>? followedArtists,
    List<Room>? joinedRooms,
    List<User>? followers,
    List<User>? following,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return User(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      username: username ?? this.username,
      profileUrl: profileUrl ?? this.profileUrl,
      bio: bio ?? this.bio,
      tags: tags ?? this.tags,
      playlists: playlists ?? this.playlists,
      likedSongs: likedSongs ?? this.likedSongs,
      likedAlbums: likedAlbums ?? this.likedAlbums,
      likedPlaylists: likedPlaylists ?? this.likedPlaylists,
      followedArtists: followedArtists ?? this.followedArtists,
      joinedRooms: joinedRooms ?? this.joinedRooms,
      followers: followers ?? this.followers,
      following: following ?? this.following,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      email: json['email'] as String? ?? '',
      username: json['username'] as String?,
      profileUrl: json['profileUrl'] as String?,
      bio: json['bio'] as String?,
      tags: json['tags'] != null ? List<String>.from(json['tags'] as List) : null,
      playlists: json['playlists'] != null
          ? (json['playlists'] as List).map((e) => Playlist.fromJson(e as Map<String, dynamic>)).toList()
          : null,
      likedSongs: json['likedSongs'] != null
          ? (json['likedSongs'] as List).map((e) => Song.fromJson(e as Map<String, dynamic>)).toList()
          : null,
      likedAlbums: json['likedAlbums'] != null
          ? (json['likedAlbums'] as List).map((e) => Album.fromJson(e as Map<String, dynamic>)).toList()
          : null,
      likedPlaylists: json['likedPlaylists'] != null
          ? (json['likedPlaylists'] as List).map((e) => Playlist.fromJson(e as Map<String, dynamic>)).toList()
          : null,
      followedArtists: json['followedArtists'] != null
          ? (json['followedArtists'] as List).map((e) => Artist.fromJson(e as Map<String, dynamic>)).toList()
          : null,
      joinedRooms: json['joinedRooms'] != null
          ? (json['joinedRooms'] as List).map((e) => Room.fromJson(e as Map<String, dynamic>)).toList()
          : null,
      followers: json['followers'] != null
          ? (json['followers'] as List).map((e) => User.fromJson(e as Map<String, dynamic>)).toList()
          : null,
      following: json['following'] != null
          ? (json['following'] as List).map((e) => User.fromJson(e as Map<String, dynamic>)).toList()
          : null,
      createdAt: json['createdAt'] != null ? DateTime.tryParse(json['createdAt'] as String) : null,
      updatedAt: json['updatedAt'] != null ? DateTime.tryParse(json['updatedAt'] as String) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      if (username != null) 'username': username,
      if (profileUrl != null) 'profileUrl': profileUrl,
      if (bio != null) 'bio': bio,
      if (tags != null) 'tags': tags,
      if (playlists != null) 'playlists': playlists?.map((e) => e.toJson()).toList(),
      if (likedSongs != null) 'likedSongs': likedSongs?.map((e) => e.toJson()).toList(),
      if (likedAlbums != null) 'likedAlbums': likedAlbums?.map((e) => e.toJson()).toList(),
      if (likedPlaylists != null) 'likedPlaylists': likedPlaylists?.map((e) => e.toJson()).toList(),
      if (followedArtists != null) 'followedArtists': followedArtists?.map((e) => e.toJson()).toList(),
      if (joinedRooms != null) 'joinedRooms': joinedRooms?.map((e) => e.toJson()).toList(),
      if (followers != null) 'followers': followers?.map((e) => e.toJson()).toList(),
      if (following != null) 'following': following?.map((e) => e.toJson()).toList(),
      if (createdAt != null) 'createdAt': createdAt?.toIso8601String(),
      if (updatedAt != null) 'updatedAt': updatedAt?.toIso8601String(),
    };
  }
}