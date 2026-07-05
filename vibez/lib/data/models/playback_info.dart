class PlaybackInfo {
  final String id;
  final String playbackUrl;
  final String mimeType;

  /// HTTP headers the player must send when fetching [playbackUrl].
  /// Some stream URLs are bound to the User-Agent of the innertube client
  /// that requested them and 403 without it.
  final Map<String, String>? headers;

  const PlaybackInfo({
    required this.id,
    required this.playbackUrl,
    required this.mimeType,
    this.headers,
  });

  factory PlaybackInfo.fromJson(Map<String, dynamic> json) {
    return PlaybackInfo(
      id: json['id'] as String? ?? '',
      playbackUrl: json['playbackUrl'] as String? ?? '',
      mimeType: json['mimeType'] as String? ?? '',
      headers: (json['headers'] as Map<String, dynamic>?)?.map(
        (k, v) => MapEntry(k, v as String),
      ),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'playbackUrl': playbackUrl,
      'mimeType': mimeType,
      if (headers != null) 'headers': headers,
    };
  }
}
