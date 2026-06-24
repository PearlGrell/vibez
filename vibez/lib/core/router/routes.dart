export 'package:vibez/data/models/playlist.dart';
export 'package:vibez/presentation/common/app_shell.dart';
export 'package:vibez/presentation/splash/splash_screen.dart';
export 'package:vibez/presentation/auth/welcome_screen.dart';
export 'package:vibez/presentation/auth/login_screen.dart';
export 'package:vibez/presentation/auth/register_screen.dart';
export 'package:vibez/presentation/auth/forgot_password_screen.dart';
export 'package:vibez/presentation/landing/landing_screen.dart';
export 'package:vibez/presentation/playlist/playlist_detail_screen.dart';
export 'package:vibez/presentation/album/album_detail_screen.dart';
export 'package:vibez/presentation/artist/artist_detail_screen.dart';
export 'package:vibez/presentation/artist/artist_songs_screen.dart';
export 'package:vibez/presentation/artist/artist_albums_screen.dart';
export 'package:vibez/presentation/playlist/playlist_add_screen.dart';
export 'package:vibez/presentation/playlist/playlist_add_song_screen.dart';
export 'package:vibez/presentation/profile/edit_profile_screen.dart';
export 'package:vibez/presentation/profile/user_profile_screen.dart';
export 'package:vibez/presentation/profile/profile_screen.dart';
export 'package:vibez/presentation/room/room_add_screen.dart';
export 'package:vibez/presentation/room/room_details_screen.dart';

class RouteLocation {
  static const String splash = '/splash';
  static const String welcome = '/welcome';
  static const String login = '/login';
  static const String register = '/register';
  static const String forgotPassword = '/forgot-password';
  static const String discover = '/discover';
  static const String profile = '/profile';
  static const String playlistDetail = '/playlist/:id';
  static const String albumDetail = '/album/:id';
  static const String artistDetail = '/artist/:id';
  static const String artistSongs = '/artist/:id/songs';
  static const String artistAlbums = '/artist/:id/albums';
  static const String playlistAdd = '/playlist-add';
  static const String playlistAddSong = '/search-add-song';
  static const String editProfile = '/edit-profile';
  static const String userProfile = '/user/:id';
  static const String roomAdd = '/room-add';
  static const String roomDetail = '/room/:id';
}

class RouteName {
  static const String splash = 'splash';
  static const String welcome = 'welcome';
  static const String login = 'login';
  static const String register = 'register';
  static const String forgotPassword = 'forgot-password';
  static const String discover = 'discover';
  static const String profile = 'profile';
  static const String playlistDetail = 'playlist-detail';
  static const String albumDetail = 'album-detail';
  static const String artistDetail = 'artist-detail';
  static const String artistSongs = 'artist-songs';
  static const String artistAlbums = 'artist-albums';
  static const String playlistAdd = 'playlist-add';
  static const String playlistAddSong = 'playlist-add-song';
  static const String editProfile = 'edit-profile';
  static const String userProfile = 'user-profile';
  static const String roomAdd = 'room-add';
  static const String roomDetail = 'room-detail';
}
