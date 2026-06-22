import 'package:go_router/go_router.dart';
import 'package:vibez/data/models/playlist.dart';
import 'package:vibez/presentation/common/app_shell.dart';
import 'package:vibez/presentation/profile/profile_screen.dart';
import 'routes.dart';
export 'routes.dart';

class AppRouter {
  static final AppRouter instance = AppRouter._();
  late final GoRouter _router;

  AppRouter._() {
    _router = GoRouter(
      initialLocation: RouteLocation.splash,
      routes: [
        GoRoute(
          path: RouteLocation.splash,
          name: RouteName.splash,
          builder: (context, state) => SplashScreen(),
        ),
        GoRoute(
          path: RouteLocation.welcome,
          name: RouteName.welcome,
          builder: (context, state) => WelcomeScreen(),
        ),
        GoRoute(
          path: RouteLocation.login,
          name: RouteName.login,
          builder: (context, state) => LoginScreen(),
        ),
        GoRoute(
          path: RouteLocation.register,
          name: RouteName.register,
          builder: (context, state) => RegisterScreen(),
        ),
        GoRoute(
          path: RouteLocation.forgotPassword,
          name: RouteName.forgotPassword,
          builder: (context, state) => ForgotPasswordScreen(),
        ),
        ShellRoute(
          builder: (context, state, child) {
            return AppShell(location: state.matchedLocation, child: child);
          },
          routes: [
            GoRoute(
              path: RouteLocation.discover,
              name: RouteName.discover,
              builder: (context, state) =>
                  LandingScreen(currentPage: Page.discover),
            ),
            GoRoute(
              path: RouteLocation.profile,
              name: RouteName.profile,
              builder: (context, state) => ProfileScreen(),
            ),
            GoRoute(
              path: RouteLocation.playlistDetail,
              name: RouteName.playlistDetail,
              builder: (context, state) {
                final id = state.pathParameters['id']!;
                return PlaylistDetailScreen(playlistId: id);
              },
            ),
            GoRoute(
              path: RouteLocation.albumDetail,
              name: RouteName.albumDetail,
              builder: (context, state) {
                final id = state.pathParameters['id']!;
                return AlbumDetailScreen(albumId: id);
              },
            ),
            GoRoute(
              path: RouteLocation.artistDetail,
              name: RouteName.artistDetail,
              builder: (context, state) {
                final id = state.pathParameters['id']!;
                return ArtistDetailScreen(artistId: id);
              },
            ),
            GoRoute(
              path: RouteLocation.artistSongs,
              name: RouteName.artistSongs,
              builder: (context, state) {
                final id = state.pathParameters['id']!;
                final extra = state.extra as Map<String, String>? ?? {};
                return ArtistSongsScreen(
                  artistId: id,
                  artistName: extra['artistName'] ?? '',
                  browseId: extra['browseId'] ?? '',
                );
              },
            ),
            GoRoute(
              path: RouteLocation.artistAlbums,
              name: RouteName.artistAlbums,
              builder: (context, state) {
                final id = state.pathParameters['id']!;
                final extra = state.extra as Map<String, String>? ?? {};
                return ArtistAlbumsScreen(
                  artistId: id,
                  artistName: extra['artistName'] ?? '',
                  browseId: extra['browseId'],
                  params: extra['params'],
                );
              },
            ),
            GoRoute(
              path: RouteLocation.playlistAdd,
              name: RouteName.playlistAdd,
              builder: (context, state) {
                final playlist = state.extra as Playlist?;
                return PlaylistAddScreen(playlist: playlist);
              },
            ),
            GoRoute(
              path: RouteLocation.playlistAddSong,
              name: RouteName.playlistAddSong,
              builder: (context, state) {
                final extra = state.extra as Map<String, String>? ?? {};
                return PlaylistAddSongScreen(
                  playlistId: extra['playlistId'] ?? '',
                  playlistName: extra['playlistName'] ?? 'Playlist',
                );
              },
            ),
            GoRoute(
              path: RouteLocation.editProfile,
              name: RouteName.editProfile,
              builder: (context, state) => const EditProfileScreen(),
            ),
          ],
        ),
      ],
    );
  }

  GoRouter get router => _router;

  void go(String location, {Object? extra}) =>
      _router.go(location, extra: extra);

  Future<T?> push<T extends Object?>(String location, {Object? extra}) =>
      _router.push<T>(location, extra: extra);

  Future<T?> pushReplacement<T extends Object?>(
    String location, {
    Object? extra,
  }) => _router.pushReplacement<T>(location, extra: extra);

  void pop<T extends Object?>([T? result]) => _router.pop<T>(result);
}
