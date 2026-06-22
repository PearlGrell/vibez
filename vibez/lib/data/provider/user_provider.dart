import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vibez/data/models/song.dart';
import 'package:vibez/data/models/artist.dart';
import 'package:vibez/data/models/album.dart';
import 'package:vibez/data/models/playlist.dart';
import 'package:vibez/data/provider/song_cache_provider.dart';
import 'package:vibez/data/repositories/playlist_repository.dart';
import '../models/user.dart';
import '../repositories/auth_repository.dart';
import '../repositories/user_repository.dart';

final userProvider = NotifierProvider<UserNotifier, User?>(UserNotifier.new);

class UserNotifier extends Notifier<User?> {
  @override
  User? build() {
    return null;
  }

  bool _isLiked(String id) =>
      state?.likedSongs?.any((song) => song.id == id) ?? false;

  Future<void> fetchMe() async {
    final user = await UserRepository.instance.me();
    state = user;
  }

  Future<bool> login({required String email, required String password}) async {
    final success = await AuthRepository.instance.login(
      email: email,
      password: password,
    );
    if (success) {
      await fetchMe();
      return state != null;
    }
    return false;
  }

  Future<bool> register({
    required String name,
    required String email,
    required String password,
  }) async {
    final success = await AuthRepository.instance.register(
      name: name,
      email: email,
      password: password,
    );
    if (success) {
      await fetchMe();
      return state != null;
    }
    return false;
  }

  Future<void> logout() async {
    await AuthRepository.instance.logout();
    clearUser();
  }

  void setUser(User user) {
    state = user;
  }

  void updateUser(User Function(User current) updater) {
    if (state != null) {
      state = updater(state!);
    }
  }

  Future<bool> updateProfile(Map<String, dynamic> data) async {
    if (state == null) return false;
    final updated = await UserRepository.instance.update(state!.id, data);
    if (updated != null) {
      state = updated;
      return true;
    }
    return false;
  }

  Future<bool> likeSong(String id) async {
    if (state == null) return false;

    final song = await ref.read(songCacheProvider.notifier).fetchSong(id);

    if (song == null) return false;

    final wasLiked = _isLiked(id);
    final prevState = List<Song>.from(state!.likedSongs ?? []);
    final liked = List<Song>.from(state!.likedSongs ?? []);

    if (wasLiked) {
      liked.removeWhere((e) => e.id == id);
    } else {
      liked.add(song);
    }

    state = state?.copyWith(likedSongs: liked);

    try {
      final success = wasLiked
          ? await UserRepository.instance.unlikeSong(id)
          : await UserRepository.instance.likeSong(id);

      if (!success) {
        state = state?.copyWith(likedSongs: prevState);
      }

      return success;
    } catch (_) {
      state = state!.copyWith(likedSongs: prevState);
      return false;
    }
  }

  Future<bool> likeAlbum(Album album) async {
    if (state == null) return false;

    final prevState = List<Album>.from(state!.likedAlbums ?? []);
    final liked = List<Album>.from(state!.likedAlbums ?? []);
    
    if (liked.any((a) => a.id == album.id)) {
      liked.removeWhere((a) => a.id == album.id);
    } else {
      liked.add(album);
    }

    state = state?.copyWith(likedAlbums: liked);

    try {
      final success = await UserRepository.instance.likeAlbum(album.id);
      if (!success) {
        state = state?.copyWith(likedAlbums: prevState);
      }
      return success;
    } catch (_) {
      state = state?.copyWith(likedAlbums: prevState);
      return false;
    }
  }

  Future<bool> unlikeAlbum(String albumId) async {
    if (state == null) return false;

    final prevState = List<Album>.from(state!.likedAlbums ?? []);
    final liked = List<Album>.from(state!.likedAlbums ?? [])..removeWhere((a) => a.id == albumId);

    state = state?.copyWith(likedAlbums: liked);

    try {
      final success = await UserRepository.instance.unlikeAlbum(albumId);
      if (!success) {
        state = state?.copyWith(likedAlbums: prevState);
      }
      return success;
    } catch (_) {
      state = state?.copyWith(likedAlbums: prevState);
      return false;
    }
  }

  Future<bool> likePlaylist(Playlist playlist) async {
    if (state == null) return false;

    final prevState = List<Playlist>.from(state!.likedPlaylists ?? []);
    final liked = List<Playlist>.from(state!.likedPlaylists ?? []);
    
    if (liked.any((p) => p.id == playlist.id)) {
      liked.removeWhere((p) => p.id == playlist.id);
    } else {
      liked.add(playlist);
    }

    state = state?.copyWith(likedPlaylists: liked);

    try {
      final success = await UserRepository.instance.likePlaylist(playlist.id);
      if (!success) {
        state = state?.copyWith(likedPlaylists: prevState);
      }
      return success;
    } catch (_) {
      state = state?.copyWith(likedPlaylists: prevState);
      return false;
    }
  }

  Future<bool> unlikePlaylist(String playlistId) async {
    if (state == null) return false;

    final prevState = List<Playlist>.from(state!.likedPlaylists ?? []);
    final liked = List<Playlist>.from(state!.likedPlaylists ?? [])..removeWhere((p) => p.id == playlistId);

    state = state?.copyWith(likedPlaylists: liked);

    try {
      final success = await UserRepository.instance.unlikePlaylist(playlistId);
      if (!success) {
        state = state?.copyWith(likedPlaylists: prevState);
      }
      return success;
    } catch (_) {
      state = state?.copyWith(likedPlaylists: prevState);
      return false;
    }
  }

  Future<bool> followArtist(Artist artist) async {
    if (state == null) return false;

    final prevState = List<Artist>.from(state!.followedArtists ?? []);
    final followed = List<Artist>.from(state!.followedArtists ?? []);
    
    if (followed.any((a) => a.id == artist.id)) {
      followed.removeWhere((a) => a.id == artist.id);
    } else {
      followed.add(artist);
    }

    state = state?.copyWith(followedArtists: followed);

    try {
      final success = await UserRepository.instance.followArtist(artist.id);
      if (!success) {
        state = state?.copyWith(followedArtists: prevState);
      }
      return success;
    } catch (_) {
      state = state?.copyWith(followedArtists: prevState);
      return false;
    }
  }

  Future<bool> unfollowArtist(String artistId) async {
    if (state == null) return false;

    final prevState = List<Artist>.from(state!.followedArtists ?? []);
    final followed = List<Artist>.from(state!.followedArtists ?? [])..removeWhere((a) => a.id == artistId);

    state = state?.copyWith(followedArtists: followed);

    try {
      final success = await UserRepository.instance.unfollowArtist(artistId);
      if (!success) {
        state = state?.copyWith(followedArtists: prevState);
      }
      return success;
    } catch (_) {
      state = state?.copyWith(followedArtists: prevState);
      return false;
    }
  }

  Future<Playlist?> createPlaylist({
    required String name,
    required bool private,
    required List<String> tags,
    String? thumbnail,
    String? description,
  }) async {
    if (state == null) return null;

    final playlist = await PlaylistRepository.instance.createPlaylist(
      name: name,
      private: private,
      tags: tags,
      createdById: state!.id,
      thumbnail: thumbnail,
      description: description,
    );

    if (playlist != null) {
      final updatedPlaylists = List<Playlist>.from(state!.playlists ?? [])..add(playlist);
      state = state?.copyWith(playlists: updatedPlaylists);
      return playlist;
    }
    return null;
  }

  Future<Playlist?> updatePlaylist({
    required String id,
    String? name,
    bool? private,
    List<String>? tags,
    String? thumbnail,
    String? description,
  }) async {
    if (state == null) return null;

    final playlist = await PlaylistRepository.instance.updatePlaylist(
      id: id,
      name: name,
      private: private,
      tags: tags,
      thumbnail: thumbnail,
      description: description,
    );

    if (playlist != null) {
      final updatedPlaylists = List<Playlist>.from(state!.playlists ?? []);
      final index = updatedPlaylists.indexWhere((p) => p.id == id);
      if (index != -1) {
        updatedPlaylists[index] = playlist;
      }
      state = state?.copyWith(playlists: updatedPlaylists);
      return playlist;
    }
    return null;
  }

  Future<bool> addSongToPlaylist({
    required String playlistId,
    required String songId,
  }) async {
    if (state == null) return false;

    final playlist = await PlaylistRepository.instance.addSongToPlaylist(
      playlistId: playlistId,
      songId: songId,
    );

    if (playlist != null) {
      final updatedPlaylists = List<Playlist>.from(state!.playlists ?? []);
      final index = updatedPlaylists.indexWhere((p) => p.id == playlistId);
      if (index != -1) {
        updatedPlaylists[index] = playlist;
      }
      state = state?.copyWith(playlists: updatedPlaylists);
      return true;
    }
    return false;
  }

  void clearUser() {
    state = null;
  }
}
