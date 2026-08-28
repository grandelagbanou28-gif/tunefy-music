import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:muzo/l10n/app_localizations.dart';
import 'package:muzo/providers/player_provider.dart';

const Color spotifyWhite = Color(0xffFFFFFF);
const Color spotifyBlack = Color(0xff121212);
const Color spotifyDarkGrey = Color(0xff282828);
const Color spotifyLightGrey = Color(0xff777777);

const Color spotifyGreen = Color(0xFF1DDA63);

Widget _chipImage(String source, double size,
    {bool circle = false, IconData placeholderIcon = Icons.music_note}) {
  if (source.isEmpty) {
    final placeholder = Container(
      width: size,
      height: size,
      color: spotifyDarkGrey,
      child: Icon(
        placeholderIcon,
        color: spotifyLightGrey,
        size: size * 0.4,
      ),
    );
    return circle ? ClipOval(child: placeholder) : placeholder;
  }
  final isNetwork = source.startsWith('http');
  final box = SizedBox(
    width: size,
    height: size,
    child: isNetwork
        ? CachedNetworkImage(
            imageUrl: source,
            fit: BoxFit.cover,
            width: size,
            height: size,
            placeholder: (c, u) => Container(
              width: size,
              height: size,
              color: spotifyDarkGrey,
            ),
            errorWidget: (c, u, e) => Container(
              width: size,
              height: size,
              color: spotifyDarkGrey,
              child: Icon(
                placeholderIcon,
                color: spotifyLightGrey,
                size: size * 0.4,
              ),
            ),
          )
        : Image.asset(
            source,
            width: size,
            height: size,
            fit: BoxFit.cover,
          ),
  );
  if (circle) return ClipOval(child: box);
  return box;
}

class SpotifySongChip extends ConsumerWidget {
  final String imageUrl;
  final String songTitle;
  final String singerName;
  final double size;
  final bool isDeletable;
  final VoidCallback? onTap;
  final VoidCallback? onDelete;
  final VoidCallback? onSingerTap;

  /// The song's video id. When it matches the currently playing track, the
  /// title is highlighted in green (Spotify-style now-playing indicator).
  final String? videoId;

  /// When true, shows the "E" explicit-content badge next to the artist name.
  final bool isExplicit;

  const SpotifySongChip({
    super.key,
    required this.imageUrl,
    required this.songTitle,
    required this.singerName,
    this.size = 47,
    this.isDeletable = false,
    this.onTap,
    this.onDelete,
    this.onSingerTap,
    this.videoId,
    this.isExplicit = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentId =
        ref.watch(playerUiStateProvider).valueOrNull?.currentMediaItem?.id;
    final isCurrent = videoId != null && videoId == currentId;
    final titleColor = isCurrent ? spotifyGreen : spotifyWhite;
    return Padding(
      padding: const EdgeInsets.only(bottom: 15),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Row(
                children: [
                  _chipImage(imageUrl, size),
                  const SizedBox(width: 15),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            if (isCurrent) ...[
                              const Icon(
                                Icons.graphic_eq,
                                color: spotifyGreen,
                                size: 14,
                              ),
                              const SizedBox(width: 6),
                            ],
                            Expanded(
                              child: Text(
                                songTitle,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 15,
                                  color: titleColor,
                                ),
                              ),
                            ),
                          ],
                        ),
                        Row(
                          children: [
                            if (isExplicit) ...[
                              Stack(
                                alignment: Alignment.center,
                                children: [
                                  Container(
                                    height: 13,
                                    width: 13,
                                    decoration: const BoxDecoration(
                                      color: Color(0xffC4C4C4),
                                      borderRadius: BorderRadius.all(
                                        Radius.circular(3),
                                      ),
                                    ),
                                  ),
                                  const Text(
                                    "E",
                                    style: TextStyle(
                                      fontSize: 8,
                                      color: spotifyBlack,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(width: 5),
                            ],
                            Expanded(
                              child: GestureDetector(
                                // Only taps directly on the artist-name text
                                // navigate; the rest of the row plays the song.
                                behavior: HitTestBehavior.translucent,
                                onTap: onSingerTap,
                                child: Row(
                                  children: [
                                    Flexible(
                                      child: Text(
                                        AppLocalizations.of(context)
                                            .songDotArtist(singerName),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                          fontSize: 13,
                                          color: spotifyLightGrey,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Visibility(
              visible: isDeletable,
              child: GestureDetector(
                onTap: onDelete,
                child: const Padding(
                  padding: EdgeInsets.all(4),
                  child: Icon(
                    Icons.close,
                    color: spotifyLightGrey,
                    size: 14,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class SpotifyArtistChip extends StatelessWidget {
  final String imageUrl;
  final String name;
  final double radius;
  final bool isDeletable;
  final VoidCallback? onTap;
  final VoidCallback? onDelete;

  const SpotifyArtistChip({
    super.key,
    required this.imageUrl,
    required this.name,
    this.radius = 35,
    this.isDeletable = false,
    this.onTap,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Row(
                children: [
                  _chipImage(imageUrl, radius * 2, circle: true),
                  const SizedBox(width: 15),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 15,
                            color: spotifyWhite,
                          ),
                        ),
                        Text(
                          AppLocalizations.of(context).artistType,
                          style: const TextStyle(
                            fontSize: 13,
                            color: spotifyLightGrey,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Visibility(
              visible: isDeletable,
              child: GestureDetector(
                onTap: onDelete,
                child: const Padding(
                  padding: EdgeInsets.all(4),
                  child: Icon(
                    Icons.close,
                    color: spotifyLightGrey,
                    size: 14,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class SpotifyAlbumChip extends StatelessWidget {
  final String imageUrl;
  final String albumName;
  final String artistName;
  final double size;
  final bool isDeletable;
  final VoidCallback? onTap;
  final VoidCallback? onDelete;

  const SpotifyAlbumChip({
    super.key,
    required this.imageUrl,
    required this.albumName,
    required this.artistName,
    this.size = 65,
    this.isDeletable = false,
    this.onTap,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Row(
                children: [
                  _chipImage(imageUrl, size),
                  const SizedBox(width: 15),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          albumName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 15,
                            color: spotifyWhite,
                          ),
                        ),
                        Text(
                          artistName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 13,
                            color: spotifyLightGrey,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Visibility(
              visible: isDeletable,
              child: GestureDetector(
                onTap: onDelete,
                child: const Padding(
                  padding: EdgeInsets.all(4),
                  child: Icon(
                    Icons.close,
                    color: spotifyLightGrey,
                    size: 14,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
