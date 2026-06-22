class LyricBlock {
  final String text;
  final int startTime;
  final int endTime;

  const LyricBlock({
    required this.text,
    required this.startTime,
    required this.endTime,
  });

  factory LyricBlock.fromJson(Map<String, dynamic> json) {
    return LyricBlock(
      text: json['text'] as String? ?? '',
      startTime: json['startTime'] as int? ?? 0,
      endTime: json['endTime'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'text': text,
      'startTime': startTime,
      'endTime': endTime,
    };
  }
}

class Lyrics {
  final List<LyricBlock> lyrics;
  final String source;
  final bool hasTimestamps;

  const Lyrics({
    required this.lyrics,
    required this.source,
    required this.hasTimestamps,
  });

  factory Lyrics.fromJson(Map<String, dynamic> json) {
    return Lyrics(
      lyrics: (json['lyrics'] as List?)
              ?.map((e) => LyricBlock.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      source: json['source'] as String? ?? '',
      hasTimestamps: json['hasTimestamps'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'lyrics': lyrics.map((e) => e.toJson()).toList(),
      'source': source,
      'hasTimestamps': hasTimestamps,
    };
  }
}
