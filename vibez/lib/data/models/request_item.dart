import 'song.dart';
import 'user.dart';

class RequestItem {
  final Song song;
  final User requestedBy;
  final DateTime addedAt;

  const RequestItem({
    required this.song,
    required this.requestedBy,
    required this.addedAt
  });

  factory RequestItem.fromJson(Map<String, dynamic> json) {
    return RequestItem(
      song: Song.fromJson(json['song'] as Map<String, dynamic>),
      requestedBy: User.fromJson(json['requestedBy'] as Map<String, dynamic>),
      addedAt: DateTime.parse(json['addedAt'])
    );
  }
}
