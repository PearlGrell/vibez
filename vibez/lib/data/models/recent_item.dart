enum RecentItemType { song, album, playlist, artist }

class RecentItem {
  final String id;
  final String name;
  final String? thumbnail;
  final RecentItemType type;

  const RecentItem({
    required this.id,
    required this.name,
    this.thumbnail,
    required this.type,
  });

  factory RecentItem.fromJson(Map<String, dynamic> json) {
    return RecentItem(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      thumbnail: json['thumbnail'] as String?,
      type: RecentItemType.values.firstWhere(
        (t) => t.name == json['type'],
        orElse: () => RecentItemType.song,
      ),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        if (thumbnail != null) 'thumbnail': thumbnail,
        'type': type.name,
      };

  String get routePath {
    switch (type) {
      case RecentItemType.album:
        return '/album/$id';
      case RecentItemType.playlist:
        return '/playlist/$id';
      case RecentItemType.artist:
        return '/artist/$id';
      case RecentItemType.song:
        return '';
    }
  }
}
