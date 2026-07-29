class Track {
  final String? videoId;
  final String title;
  final String artist;
  final String? albumImage;
  final String? artistImage;
  final Duration? duration;
  final String? audioUrl;
  final List<String> genres;

  const Track({
    this.videoId,
    required this.title,
    required this.artist,
    this.albumImage,
    this.artistImage,
    this.duration,
    this.audioUrl,
    this.genres = const [],
  });

  Track copyWith({
    String? videoId,
    String? title,
    String? artist,
    String? albumImage,
    String? artistImage,
    Duration? duration,
    String? audioUrl,
    List<String>? genres,
  }) {
    return Track(
      videoId: videoId ?? this.videoId,
      title: title ?? this.title,
      artist: artist ?? this.artist,
      albumImage: albumImage ?? this.albumImage,
      artistImage: artistImage ?? this.artistImage,
      duration: duration ?? this.duration,
      audioUrl: audioUrl ?? this.audioUrl,
      genres: genres ?? this.genres,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'videoId': videoId,
      'title': title,
      'artist': artist,
      'albumImage': albumImage,
      'artistImage': artistImage,
      'duration': duration?.inSeconds,
      'audioUrl': audioUrl,
      'genres': genres,
    };
  }

  factory Track.fromMap(Map<String, dynamic> map) {
    return Track(
      videoId: map['videoId'],
      title: map['title'] ?? '',
      artist: map['artist'] ?? '',
      albumImage: map['albumImage'],
      artistImage: map['artistImage'],
      duration: map['duration'] != null ? Duration(seconds: map['duration']) : null,
      audioUrl: map['audioUrl'],
      genres: List<String>.from(map['genres'] ?? []),
    );
  }
}
