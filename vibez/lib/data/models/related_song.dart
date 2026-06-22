class RelatedSong {
  final String id;
  final String title;
  final String thumbnail;
  final String artists;

  const RelatedSong({
    required this.id,
    required this.title,
    required this.thumbnail,
    required this.artists,
  });

  factory RelatedSong.fromJson(Map<String, dynamic> json) {
    return RelatedSong(
      id: json['id'] as String? ?? '',
      title: json['title'] as String? ?? '',
      thumbnail: json['thumbnail'] as String? ?? '',
      artists: json['artists'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'thumbnail': thumbnail,
      'artists': artists,
    };
  }
}
