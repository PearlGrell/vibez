import 'song.dart';
import 'user.dart';

class RequestItem {
  final String id;
  final Song song;
  final User requestedBy;
  final int position;
  final DateTime? addedAt;

  const RequestItem({
    required this.id,
    required this.song,
    required this.requestedBy,
    required this.position,
    this.addedAt,
  });

  factory RequestItem.fromJson(Map<String, dynamic> json) {
    return RequestItem(
      id: json['id'] as String,
      song: Song.fromJson(json['song'] as Map<String, dynamic>),
      requestedBy: User.fromJson(json['requestedBy'] as Map<String, dynamic>),
      position: json['position'] as int? ?? 0,
      addedAt: json['addedAt'] != null
          ? DateTime.tryParse(json['addedAt'] as String)
          : null,
    );
  }
}
