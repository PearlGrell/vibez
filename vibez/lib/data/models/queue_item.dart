import 'song.dart';
import 'user.dart';

class QueueItem {
  final String id;
  final Song song;
  final User addedBy;
  final int position;
  final DateTime? addedAt;

  const QueueItem({
    required this.id,
    required this.song,
    required this.addedBy,
    required this.position,
    this.addedAt,
  });

  factory QueueItem.fromJson(Map<String, dynamic> json) {
    return QueueItem(
      id: json['id'] as String,
      song: Song.fromJson(json['song'] as Map<String, dynamic>),
      addedBy: User.fromJson(json['addedBy'] as Map<String, dynamic>),
      position: json['position'] as int? ?? 0,
      addedAt: json['addedAt'] != null
          ? DateTime.tryParse(json['addedAt'] as String)
          : null,
    );
  }

  @override
  String toString() {
    return "id: $id, song: ${song.title}, addedBy: ${addedBy.name}, position: $position, addedAt: $addedAt";
  }
}
