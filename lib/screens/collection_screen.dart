import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:muzo/models/muzo_item.dart';
import 'package:muzo/providers/download_provider.dart';
import 'package:muzo/providers/player_provider.dart';
import 'package:muzo/providers/search_provider.dart';
import 'package:muzo/services/storage_service.dart';
import 'package:muzo/widgets/spotify_back_button.dart';
import 'package:muzo/widgets/spotify_chips.dart';
import 'package:muzo/widgets/song_options_menu.dart';
import 'package:share_plus/share_plus.dart';

/// The exact Spotify-style collection page (album or playlist) opened from
/// search: large cover header, type badge, big title, meta line, Play /
/// Shuffle actions and the numbered track list — mirroring the artist page.
class CollectionScreen extends ConsumerStatefulWidget {
  const CollectionScreen({
    super.key,
    required this.title,
    required this.artist,
    required this.tracks,
    this.isAlbum = false,
    this.coverUrl,
    this.color = spotifyDarkGrey,
  });

  final String title;
  final String artist;
  final List<MuzoItem> tracks;
  final bool isAlbum;
  final String? coverUrl;
  final Color color;

  @override
  ConsumerState<CollectionScreen> createState() => _CollectionScreenState();
}

class _CollectionScreenState extends ConsumerState<CollectionScreen> {
  String get title => widget.title;

  String get artist => widget.artist;

  List<MuzoItem> get tracks => widget.tracks;

  bool get isAlbum => widget.isAlbum;

  Color get color => widget.color;

  String? get coverUrl => widget.coverUrl;

  bool get _isCurrentInList {
    final currentId = ref
        .read(playerUiStateProvider)
        .valueOrNull
        ?.currentMediaItem
        ?.id;
    if (currentId == null) return false;
    return tracks.any((t) => t.videoId == currentId);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: spotifyBlack,
      body: SafeArea(
        bottom: false,
        child: CustomScrollView(
          slivers: [
            // ─── Collapsing cover header ───
            SliverAppBar(
              pinned: true,
              stretch: true,
              expandedHeight: 360,
              backgroundColor: color,
              surfaceTintColor: Colors.transparent,
              elevation: 0,
              leading: const SpotifyBackButton(),
              flexibleSpace: FlexibleSpaceBar(
                collapseMode: CollapseMode.parallax,
                stretchModes: const [StretchMode.zoomBackground],
                titlePadding: const EdgeInsetsDirectional.only(
                  start: 56,
                  end: 48,
                  bottom: 14,
                ),
                title: Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: spotifyWhite,
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                background: Stack(
                  fit: StackFit.expand,
                  children: [
                    _headerCover(),
                    DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            color.withValues(alpha: 0.10),
                            spotifyBlack,
                          ],
                          stops: const [0.3, 1.0],
                        ),
                      ),
                    ),
                    Positioned(
                      left: 20,
                      right: 20,
                      bottom: 46,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Type badge — exact Spotify row.
                          Row(
                            children: [
                              Container(
                                width: 22,
                                height: 22,
                                decoration: const BoxDecoration(
                                  color: Color(0xFF3D91F4),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  isAlbum
                                      ? Icons.album_rounded
                                      : Icons.queue_music_rounded,
                                  color: spotifyWhite,
                                  size: 14,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                isAlbum ? 'Album' : 'Playlist',
                                style: const TextStyle(
                                  color: spotifyWhite,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Text(
                            title,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: spotifyWhite,
                              fontSize: 34,
                              height: 1.02,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '${artist.isNotEmpty ? artist : 'Compilation'}'
                            '${tracks.isEmpty ? '' : ' • ${tracks.length} titres'}',
                            style: TextStyle(
                              color: spotifyWhite.withValues(alpha: 0.85),
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // ─── Play / Shuffle ───
            SliverToBoxAdapter(child: _buildActionBar(context)),

            if (tracks.isEmpty)
              SliverFillRemaining(
                hasScrollBody: false,
                child: Center(
                  child: Text(
                    'Aucun titre trouvé',
                    style: TextStyle(color: spotifyLightGrey, fontSize: 15),
                  ),
                ),
              )
            else ...[
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 22, 16, 8),
                  child: Row(
                    children: [
                      const Expanded(
                        child: Text(
                          'Titres',
                          style: TextStyle(
                            color: spotifyWhite,
                            fontSize: 19,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      Text(
                        '${tracks.length} titres',
                        style: TextStyle(
                          color: spotifyLightGrey.withValues(alpha: 0.9),
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final song = tracks[index];
                      return _trackRow(context, index, song);
                    },
                    childCount: tracks.length,
                  ),
                ),
              ),
              const SliverToBoxAdapter(
                child: SizedBox(height: 140),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _headerCover() {
    if (coverUrl != null && coverUrl!.isNotEmpty) {
      return CachedNetworkImage(
        imageUrl: coverUrl!,
        fit: BoxFit.cover,
        errorWidget: (_, __, ___) => Container(color: color),
      );
    }
    return Container(color: color);
  }

  Widget _buildActionBar(BuildContext context) {
    final storage = ref.watch(storageServiceProvider);
    final allDownloaded = tracks.isNotEmpty &&
        tracks.every((t) =>
            t.videoId != null && storage.isDownloaded(t.videoId!));

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 4),
      child: Row(
        children: [
          // Share
          GestureDetector(
            behavior: HitTestBehavior.translucent,
            onTap: () {
              HapticFeedback.lightImpact();
              // ignore: deprecated_member_use
              Share.share('Share $title via Muzo');
            },
            child: Container(
              padding: const EdgeInsets.all(12),
              child: Image.asset(
                'assets/icons/share.png',
                width: 24,
                height: 24,
                color: Colors.grey.shade600,
              ),
            ),
          ),
          // Download (all)
          GestureDetector(
            behavior: HitTestBehavior.translucent,
            onTap: tracks.isEmpty
                ? null
                : () async {
                    HapticFeedback.lightImpact();
                    if (allDownloaded) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('All songs already downloaded'),
                          backgroundColor: spotifyDarkGrey,
                          duration: Duration(seconds: 2),
                        ),
                      );
                      return;
                    }
                    final pending = tracks
                        .where((s) =>
                            s.videoId != null &&
                            !storage.isDownloaded(s.videoId!))
                        .toList();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content:
                            Text('Downloading ${pending.length} songs...'),
                        backgroundColor: spotifyDarkGrey,
                        duration: const Duration(seconds: 3),
                      ),
                    );
                    for (final s in pending) {
                      ref.read(downloadProvider.notifier).startDownload(s);
                      await Future.delayed(const Duration(milliseconds: 700));
                    }
                  },
            child: Container(
              padding: const EdgeInsets.all(12),
              child: ValueListenableBuilder(
                valueListenable: storage.downloadsListenable,
                builder: (context, _, __) {
                  final allDone = tracks.isNotEmpty &&
                      tracks.every((s) =>
                          s.videoId != null &&
                          storage.isDownloaded(s.videoId!));
                  return Image.asset(
                    allDone
                        ? 'assets/icons/complete_download.png'
                        : 'assets/icons/download.png',
                    width: 24,
                    height: 24,
                    color:
                        allDone ? const Color(0xFF1DDA63) : Colors.white70,
                  );
                },
              ),
            ),
          ),
          const Spacer(),
          // Shuffle — green while shuffle is on.
          ValueListenableBuilder<bool>(
            valueListenable: ref.watch(shuffleModeNotifierProvider),
            builder: (context, shuffleOn, _) {
              return GestureDetector(
                onTap: tracks.isEmpty
                    ? null
                    : () async {
                        HapticFeedback.lightImpact();
                        final handler = ref.read(audioHandlerProvider);
                        if (shuffleOn) {
                          handler.isShuffleModeNotifier.value = false;
                        } else {
                          handler.isShuffleModeNotifier.value = true;
                          final shuffled = [...tracks]..shuffle();
                          await handler.playAll(shuffled);
                        }
                      },
                behavior: HitTestBehavior.opaque,
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: const BoxDecoration(shape: BoxShape.circle),
                  child: Image.asset(
                    'assets/icons/shuffle.png',
                    width: 24,
                    height: 24,
                    color: shuffleOn
                        ? const Color(0xFF1DDA63)
                        : Colors.grey.shade600,
                  ),
                ),
              );
            },
          ),
          const SizedBox(width: 8),
          // Play (green circle) — driven by the REAL audio engine state.
          GestureDetector(
            onTap: tracks.isEmpty
                ? null
                : () async {
                    HapticFeedback.lightImpact();
                    final handler = ref.read(audioHandlerProvider);
                    final enginePlaying = handler.player.playing;
                    if (_isCurrentInList && enginePlaying) {
                      await handler.pause();
                    } else if (_isCurrentInList) {
                      await handler.resume();
                    } else {
                      handler.isShuffleModeNotifier.value = false;
                      await handler.playAll(tracks);
                    }
                  },
            behavior: HitTestBehavior.opaque,
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: Color(0xFF1DDA63),
              ),
              child: StreamBuilder<bool>(
                stream: ref
                    .read(audioHandlerProvider)
                    .player
                    .playerStateStream
                    .map((state) => state.playing),
                initialData:
                    ref.read(audioHandlerProvider).player.playing,
                builder: (context, snap) {
                  final enginePlaying = snap.data ?? false;
                  return Icon(
                    _isCurrentInList && enginePlaying
                        ? Icons.pause_rounded
                        : Icons.play_arrow,
                    color: Colors.black,
                    size: 30,
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _trackRow(BuildContext context, int index, MuzoItem song) {
    final img = song.thumbnails.isNotEmpty ? song.thumbnails.last.url : '';
    final currentId =
        ref.watch(playerUiStateProvider).valueOrNull?.currentMediaItem?.id;
    final isCurrent = currentId != null && currentId == song.videoId;

    return InkWell(
      onTap: () async {
        HapticFeedback.lightImpact();
        final handler = ref.read(audioHandlerProvider);
        final currentId = ref
            .read(playerUiStateProvider)
            .valueOrNull
            ?.currentMediaItem
            ?.id;
        if (currentId != null && currentId == song.videoId) {
          if (handler.player.playing) {
            await handler.pause();
          } else {
            await handler.resume();
          }
          return;
        }
        // Queue the whole collection and start at this exact track — songs
        // then chain automatically without any suggestion autoplay.
        handler.isShuffleModeNotifier.value = false;
        await handler.playAll(tracks, startIndex: index);
      },
      onLongPress: () {
        HapticFeedback.mediumImpact();
        SongOptionsMenu.show(ref, song);
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            SizedBox(
              width: 26,
              child: Text(
                '${index + 1}'.padLeft(2, '0'),
                style: TextStyle(
                  color: isCurrent
                      ? const Color(0xFF1DDA63)
                      : spotifyLightGrey.withValues(alpha: 0.7),
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(width: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: SizedBox(
                width: 46,
                height: 46,
                child: img.isNotEmpty
                    ? CachedNetworkImage(
                        imageUrl: img,
                        fit: BoxFit.cover,
                        errorWidget: (_, __, ___) => Container(
                          color: spotifyDarkGrey,
                          child: const Icon(Icons.music_note,
                              color: spotifyLightGrey, size: 20),
                        ),
                      )
                    : Container(
                        color: spotifyDarkGrey,
                        child: const Icon(Icons.music_note,
                            color: spotifyLightGrey, size: 20),
                      ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    song.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: isCurrent
                          ? const Color(0xFF1DDA63)
                          : spotifyWhite,
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    song.displayArtist,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: spotifyLightGrey.withValues(alpha: 0.75),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
