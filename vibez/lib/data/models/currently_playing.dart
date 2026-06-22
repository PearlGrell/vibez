enum PlayingSourceType { song, album, playlist, artist }

class CurrentlyPlaying {
  final PlayingSourceType type;
  final String sourceId;
  final String sourceName;
  final String? thumbnail;

  const CurrentlyPlaying({
    required this.type,
    required this.sourceId,
    required this.sourceName,
    this.thumbnail,
  });

  String get typeLabel {
    switch (type) {
      case PlayingSourceType.song:
        return 'Song';
      case PlayingSourceType.album:
        return 'Album';
      case PlayingSourceType.playlist:
        return 'Playlist';
      case PlayingSourceType.artist:
        return 'Artist';
    }
  }
}
