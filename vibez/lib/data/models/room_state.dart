import 'queue_item.dart';
import 'room.dart';

class RoomState {
  final Room room;
  final int participants;
  final List<String> participantsInitials;
  final List<QueueItem>? queue;

  const RoomState({
    required this.room,
    required this.participants,
    required this.participantsInitials,
    this.queue,
  });

  factory RoomState.fromJson(Map<String, dynamic> json) {
    return RoomState(
      room: Room.fromJson(json['room'] as Map<String, dynamic>),
      participants: json['participants'] as int,
      participantsInitials: List<String>.from(json['participantsInitials'] as List? ?? []),
      queue: (json['queue'] as List?)
          ?.map((e) => QueueItem.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList(),
    );
  }
}
