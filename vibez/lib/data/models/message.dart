import 'package:vibez/data/models/user.dart';

class Message {
  final String roomId;
  final String message;
  final User sentBy;

  const Message({
    required this.roomId,
    required this.message,
    required this.sentBy,
  });

  factory Message.fromJson(Map<String, dynamic> data) {
    return Message(
      roomId: data["roomId"],
      message: data["message"],
      sentBy: User.fromJson(data["sentBy"]),
    );
  }

  @override
  String toString() {
    return "$roomId :: $message :: ${sentBy.name}";
  }
}
