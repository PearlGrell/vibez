import 'song.dart';
import 'user.dart';

class Room {
  final String id;
  final String name;
  final String description;
  final List<String> tags;
  final bool private;
  final User? currentDj;
  final User? createdBy;
  final String? createdById;
  final Song? currentSong;
  final DateTime? startedAt;
  final bool playing;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const Room({
    required this.id,
    required this.name,
    required this.description,
    this.tags = const [],
    this.private = false,
    this.currentDj,
    this.createdBy,
    this.createdById,
    this.currentSong,
    this.startedAt,
    this.playing = false,
    this.createdAt,
    this.updatedAt,
  });

  Room copyWith({
    String? id,
    String? name,
    String? description,
    List<String>? tags,
    bool? private,
    User? currentDj,
    User? createdBy,
    String? createdById,
    Song? currentSong,
    DateTime? startedAt,
    bool? playing,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Room(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      tags: tags ?? this.tags,
      private: private ?? this.private,
      currentDj: currentDj ?? this.currentDj,
      createdBy: createdBy ?? this.createdBy,
      createdById: createdById ?? this.createdById,
      currentSong: currentSong ?? this.currentSong,
      startedAt: startedAt ?? this.startedAt,
      playing: playing ?? this.playing,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  factory Room.fromJson(Map<String, dynamic> json) {
    return Room(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String,
      tags: json['tags'] != null ? List<String>.from(json['tags'] as List) : [],
      private: json['private'] as bool? ?? false,
      currentDj: json['currentDj'] != null ? User.fromJson(json['currentDj'] as Map<String, dynamic>) : null,
      createdBy: json['createdBy'] != null ? User.fromJson(json['createdBy'] as Map<String, dynamic>) : null,
      createdById: json['createdById'] as String?,
      currentSong: json['currentSong'] != null ? Song.fromJson(json['currentSong'] as Map<String, dynamic>) : null,
      startedAt: json['startedAt'] != null ? DateTime.tryParse(json['startedAt'] as String) : null,
      playing: json['playing'] as bool? ?? false,
      createdAt: json['createdAt'] != null ? DateTime.tryParse(json['createdAt'] as String) : null,
      updatedAt: json['updatedAt'] != null ? DateTime.tryParse(json['updatedAt'] as String) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'tags': tags,
      'private': private,
      if (currentDj != null) 'currentDj': currentDj?.toJson(),
      if (createdBy != null) 'createdBy': createdBy?.toJson(),
      if (createdById != null) 'createdById': createdById,
      if (currentSong != null) 'currentSong': currentSong?.toJson(),
      if (startedAt != null) 'startedAt': startedAt?.toIso8601String(),
      'playing': playing,
      if (createdAt != null) 'createdAt': createdAt?.toIso8601String(),
      if (updatedAt != null) 'updatedAt': updatedAt?.toIso8601String(),
    };
  }
}
