import 'room.dart';

class RoomState {
  final Room room;
  final int participants;
  final List<String> participantsInitials;

  const RoomState({
    required this.room,
    required this.participants,
    required this.participantsInitials,
  });

  factory RoomState.fromJson(Map<String, dynamic> json) {
    return RoomState(
      room: Room.fromJson(json['room'] as Map<String, dynamic>),
      participants: json['participants'] as int,
      participantsInitials: List<String>.from(json['participantsInitials'] as List? ?? []),
    );
  }
}
