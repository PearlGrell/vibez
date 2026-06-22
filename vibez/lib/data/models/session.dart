import 'user.dart';

class Session {
  final String id;
  final User? user;
  final String userId;
  final String refreshToken;
  final DateTime expiresAt;
  final String? deviceName;
  final String? ipAddress;
  final String? userAgent;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Session({
    required this.id,
    this.user,
    required this.userId,
    required this.refreshToken,
    required this.expiresAt,
    this.deviceName,
    this.ipAddress,
    this.userAgent,
    required this.createdAt,
    required this.updatedAt,
  });

  Session copyWith({
    String? id,
    User? user,
    String? userId,
    String? refreshToken,
    DateTime? expiresAt,
    String? deviceName,
    String? ipAddress,
    String? userAgent,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Session(
      id: id ?? this.id,
      user: user ?? this.user,
      userId: userId ?? this.userId,
      refreshToken: refreshToken ?? this.refreshToken,
      expiresAt: expiresAt ?? this.expiresAt,
      deviceName: deviceName ?? this.deviceName,
      ipAddress: ipAddress ?? this.ipAddress,
      userAgent: userAgent ?? this.userAgent,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  factory Session.fromJson(Map<String, dynamic> json) {
    return Session(
      id: json['id'] as String,
      user: json['user'] != null ? User.fromJson(json['user'] as Map<String, dynamic>) : null,
      userId: json['userId'] as String,
      refreshToken: json['refreshToken'] as String,
      expiresAt: DateTime.parse(json['expiresAt'] as String),
      deviceName: json['deviceName'] as String?,
      ipAddress: json['ipAddress'] as String?,
      userAgent: json['userAgent'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      if (user != null) 'user': user?.toJson(),
      'userId': userId,
      'refreshToken': refreshToken,
      'expiresAt': expiresAt.toIso8601String(),
      if (deviceName != null) 'deviceName': deviceName,
      if (ipAddress != null) 'ipAddress': ipAddress,
      if (userAgent != null) 'userAgent': userAgent,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }
}
