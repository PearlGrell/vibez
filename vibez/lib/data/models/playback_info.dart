class PlaybackInfo {
  final String id;
  final String playbackUrl;
  final String mimeType;

  const PlaybackInfo({
    required this.id,
    required this.playbackUrl,
    required this.mimeType,
  });

  factory PlaybackInfo.fromJson(Map<String, dynamic> json) {
    return PlaybackInfo(
      id: json['id'] as String? ?? '',
      playbackUrl: json['playbackUrl'] as String? ?? '',
      mimeType: json['mimeType'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'playbackUrl': playbackUrl,
      'mimeType': mimeType,
    };
  }
}
