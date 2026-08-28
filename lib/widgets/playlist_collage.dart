import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:muzo/widgets/spotify_chips.dart';

/// Spotify-style square collage (2x2) built from up to 4 images, with a
/// music-note placeholder for the missing cells.
class PlaylistCollage extends StatelessWidget {
  const PlaylistCollage({
    super.key,
    required this.urls,
    this.fallbackIcon = Icons.music_note,
  });

  final List<String> urls;
  final IconData fallbackIcon;

  @override
  Widget build(BuildContext context) {
    final images = urls.where((u) => u.isNotEmpty).take(4).toList();
    while (images.length < 4) {
      images.add('');
    }
    Widget cell(String url) {
      if (url.isEmpty) {
        return Container(
          color: Colors.black26,
          child: Icon(
            fallbackIcon,
            color: spotifyWhite.withValues(alpha: 0.5),
          ),
        );
      }
      return CachedNetworkImage(
        imageUrl: url,
        fit: BoxFit.cover,
        errorWidget: (_, __, ___) => Container(
          color: Colors.black26,
          child: Icon(
            fallbackIcon,
            color: spotifyWhite.withValues(alpha: 0.5),
          ),
        ),
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: Column(
        children: [
          Expanded(
            child: Row(
              children: [Expanded(child: cell(images[0])), Expanded(child: cell(images[1]))],
            ),
          ),
          Expanded(
            child: Row(
              children: [Expanded(child: cell(images[2])), Expanded(child: cell(images[3]))],
            ),
          ),
        ],
      ),
    );
  }
}
