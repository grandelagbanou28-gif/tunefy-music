class PodcastChannel {
  final String id;
  final String title;
  final String description;
  final String? imageUrl;
  final String? channelUrl;

  const PodcastChannel({
    required this.id,
    required this.title,
    required this.description,
    this.imageUrl,
    this.channelUrl,
  });
}

class PodcastEpisode {
  final String id;
  final String title;
  final String channelTitle;
  final String? description;
  final String? imageUrl;
  final String? videoId;
  final String? duration;

  const PodcastEpisode({
    required this.id,
    required this.title,
    required this.channelTitle,
    this.description,
    this.imageUrl,
    this.videoId,
    this.duration,
  });
}
