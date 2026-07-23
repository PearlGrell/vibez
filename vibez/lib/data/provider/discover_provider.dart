import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vibez/data/models/playlist.dart';
import 'package:vibez/data/models/room.dart';
import 'package:vibez/data/repositories/playlist_repository.dart';
import 'package:vibez/data/repositories/room_repository.dart';

/// Public rooms surfaced on the Discover tab, live/playing ones first.
final trendingRoomsProvider = FutureProvider.autoDispose<List<Room>>((
  ref,
) async {
  final rooms = await RoomRepository.instance.getRooms(limit: 20, sort: 'newest');
  rooms.sort((a, b) {
    if (a.playing != b.playing) return a.playing ? -1 : 1;
    final aTime = a.updatedAt ?? a.createdAt;
    final bTime = b.updatedAt ?? b.createdAt;
    if (aTime == null || bTime == null) return 0;
    return bTime.compareTo(aTime);
  });
  return rooms;
});

/// Public playlists surfaced on the Discover tab.
final trendingPlaylistsProvider = FutureProvider.autoDispose<List<Playlist>>((
  ref,
) async {
  return PlaylistRepository.instance.getPlaylists(limit: 20);
});
