import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:muzo/models/muzo_item.dart';
import 'package:muzo/providers/player_provider.dart';
import 'package:muzo/widgets/playlist_collage.dart';
import 'package:muzo/widgets/spotify_back_button.dart';
import 'package:muzo/widgets/spotify_chips.dart';

/// A Spotify-style playlist page opened from a category: big cover collage,
/// playlist name, Play/Shuffle buttons, then the track list.
/// Auto-plays the first song on open (Spotify behavior).
class CategoryPlaylistScreen extends ConsumerStatefulWidget {
  const CategoryPlaylistScreen({
    super.key,
    required this.title,
    required this.songs,
    required this.color,
    this.subtitle,
    this.coverUrl,
  });

  final String title;
  final List<MuzoItem> songs;
  final Color color;
  final String? subtitle;
  final String? coverUrl;

  @override
  ConsumerState<CategoryPlaylistScreen> createState() =>
      _CategoryPlaylistScreenState();
}

class _CategoryPlaylistScreenState
    extends ConsumerState<CategoryPlaylistScreen> {

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final songs = dedupeMuzoSongs(widget.songs);
    final urls = songs
        .map((s) => s.thumbnails.isNotEmpty ? s.thumbnails.last.url : '')
        .toList();
    final cover = widget.coverUrl;
    final color = widget.color;

    return Scaffold(
      backgroundColor: spotifyBlack,
      body: SafeArea(
        bottom: false,
        child: CustomScrollView(
          slivers: [
            SliverAppBar(
              backgroundColor: color,
              surfaceTintColor: Colors.transparent,
              elevation: 0,
              pinned: true,
              leading: const SpotifyBackButton(),
              title: Text(
                widget.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: spotifyWhite,
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                ),
              ),
              centerTitle: true,
            ),
            SliverToBoxAdapter(
              child: Container(
                padding: const EdgeInsets.fromLTRB(24, 28, 24, 22),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [color, Color.lerp(color, spotifyBlack, 0.7)!],
                  ),
                ),
                child: Column(
                  children: [
                    SizedBox(
                      width: 160,
                      height: 160,
                      child: cover != null && cover.isNotEmpty
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: CachedNetworkImage(
                                imageUrl: cover,
                                fit: BoxFit.cover,
                                errorWidget: (_, __, ___) => Container(
                                  color: Colors.black26,
                                  child: const Icon(
                                    Icons.album,
                                    color: spotifyWhite,
                                    size: 32,
                                  ),
                                ),
                              ),
                            )
                          : PlaylistCollage(urls: urls),
                    ),
                    const SizedBox(height: 18),
                    Text(
                      widget.title,
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: spotifyWhite,
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      widget.subtitle ?? 'Playlist • ${songs.length} songs',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: spotifyLightGrey.withValues(alpha: 0.9),
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 18),
                    Row(
                      children: [
                        GestureDetector(
                          onTap: songs.isEmpty
                              ? null
                              : () async {
                                  HapticFeedback.lightImpact();
                                  final handler =
                                      ref.read(audioHandlerProvider);
                                  final current = ref
                                      .read(playerUiStateProvider)
                                      .valueOrNull
                                      ?.currentMediaItem;
                                  final isCurrentInList = current != null &&
                                      songs.any((s) =>
                                          s.videoId == current.id);
                                  final isPlaying = ref
                                          .read(playerUiStateProvider)
                                          .valueOrNull
                                          ?.isPlaying ??
                                      false;
                                  if (isCurrentInList && isPlaying) {
                                    await handler.pause();
                                  } else if (isCurrentInList) {
                                    await handler.resume();
                                  } else {
                                    handler.isShuffleModeNotifier.value = false;
                                    await handler.playAll(songs);
                                  }
                                },
                          behavior: HitTestBehavior.opaque,
                          child: Container(
                            width: 56,
                            height: 56,
                            decoration: const BoxDecoration(
                              color: Color(0xFF1DDA63),
                              shape: BoxShape.circle,
                            ),
                            child: Builder(builder: (context) {
                              final ui = ref
                                  .watch(playerUiStateProvider)
                                  .valueOrNull;
                              final current = ui?.currentMediaItem;
                              final isPlaying = ui?.isPlaying ?? false;
                              final inList = current != null &&
                                  songs.any((s) => s.videoId == current.id);
                              return Icon(
                                inList && isPlaying
                                    ? Icons.pause_rounded
                                    : Icons.play_arrow_rounded,
                                color: spotifyBlack,
                                size: 32,
                              );
                            }),
                          ),
                        ),
                        const SizedBox(width: 20),
                        ValueListenableBuilder<bool>(
                          valueListenable:
                              ref.watch(shuffleModeNotifierProvider),
                          builder: (context, shuffleOn, _) {
                            return GestureDetector(
                              onTap: songs.isEmpty
                                  ? null
                                  : () async {
                                      HapticFeedback.lightImpact();
                                      final handler =
                                          ref.read(audioHandlerProvider);
                                      if (shuffleOn) {
                                        handler.isShuffleModeNotifier.value =
                                            false;
                                      } else {
                                        handler.isShuffleModeNotifier.value =
                                            true;
                                        final shuffled = [...songs]..shuffle();
                                        await handler.playAll(shuffled);
                                      }
                                    },
                              behavior: HitTestBehavior.opaque,
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.shuffle,
                                    color: shuffleOn
                                        ? const Color(0xFF1DDA63)
                                        : spotifyWhite,
                                    size: 24,
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    'Shuffle',
                                    style: TextStyle(
                                      color: shuffleOn
                                          ? const Color(0xFF1DDA63)
                                          : spotifyWhite.withValues(
                                              alpha: 0.9),
                                      fontSize: 15,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final song = songs[index];
                    final img = song.thumbnails.isNotEmpty
                        ? song.thumbnails.last.url
                        : '';
                    return SpotifySongChip(
                      imageUrl: img,
                      songTitle: song.title,
                      singerName: song.displayArtist,
                      size: 47,
                      videoId: song.videoId,
                      isExplicit: song.isExplicit,
                      onTap: () async {
                        HapticFeedback.lightImpact();
                        await ref
                            .read(audioHandlerProvider)
                            .playAll(songs, startIndex: index);
                      },
                    );
                  },
                  childCount: songs.length,
                ),
              ),
            ),
            const SliverPadding(padding: EdgeInsets.only(bottom: 130)),
          ],
        ),
      ),
    );
  }
}
