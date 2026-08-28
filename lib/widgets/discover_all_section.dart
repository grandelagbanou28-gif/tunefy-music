import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:muzo/models/muzo_item.dart';
import 'package:muzo/providers/home_charts_provider.dart';
import 'package:muzo/providers/player_provider.dart';
import 'package:muzo/screens/album_screen.dart';
import 'package:muzo/screens/playlist_screen.dart';
import 'package:muzo/widgets/spotify_chips.dart';

class DiscoverAllSection extends ConsumerWidget {
  const DiscoverAllSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 26),
        const Padding(
          padding: EdgeInsets.fromLTRB(16, 0, 16, 18),
          child: Text(
            'Découvrir tout',
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w700,
              color: spotifyWhite,
            ),
          ),
        ),

        // ─── Charts Top 20 ───
        const _ChartsTopSection(),
        const SizedBox(height: 28),

        // ─── Charts — Top by genre ───
        const _ChartsGridSection(),
        const SizedBox(height: 28),

        // ─── Playlists éditoriales ───
        const _PlaylistsSection(),
        const SizedBox(height: 28),

        // ─── Nouveautés albums ───
        const _NewReleasesSection(),
        const SizedBox(height: 28),

        // ─── Nouveautés titres ───
        const _NewTracksSection(),
        const SizedBox(height: 100),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
//  CHARTS TOP 20 — horizontal scrollable with ranking
// ═══════════════════════════════════════════════════════════════════

class _ChartsTopSection extends ConsumerWidget {
  const _ChartsTopSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final chartsAsync = ref.watch(homeChartsProvider);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Charts du moment',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: spotifyWhite,
                ),
              ),
              Text(
                'Top 20',
                style: TextStyle(
                  color: const Color(0xFF1DDA63),
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
        SizedBox(
          height: 200,
          child: chartsAsync.when(
            loading: () => const Center(
              child: CircularProgressIndicator(
                  color: Color(0xFF1DDA63), strokeWidth: 2),
            ),
            error: (_, __) => const SizedBox.shrink(),
            data: (charts) {
              final tracks = charts.tracks;
              if (tracks.isEmpty) return const SizedBox.shrink();
              final top = tracks.take(20).toList();
              return ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: top.length,
                itemExtent: 150,
                itemBuilder: (context, i) => _ChartCard(
                    track: top[i], rank: i + 1, allTracks: top),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _ChartCard extends ConsumerWidget {
  const _ChartCard({
    required this.track,
    required this.rank,
    required this.allTracks,
  });

  final MuzoItem track;
  final int rank;
  final List<MuzoItem> allTracks;

  Color get _rankColor {
    if (rank == 1) return const Color(0xFFFFD700);
    if (rank == 2) return const Color(0xFFC0C0C0);
    if (rank == 3) return const Color(0xFFCD7F32);
    return Colors.white24;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final thumb =
        track.thumbnails.isNotEmpty ? track.thumbnails.last.url : '';
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        ref
            .read(audioHandlerProvider)
            .playAll(allTracks, startIndex: rank - 1);
      },
      child: SizedBox(
        width: 140,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Positioned(
              top: 22,
              left: 0,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: SizedBox(
                  width: 120,
                  height: 120,
                  child: thumb.isNotEmpty
                      ? CachedNetworkImage(
                          imageUrl: thumb,
                          fit: BoxFit.cover,
                          placeholder: (_, __) => _thumbPlaceholder(),
                          errorWidget: (_, __, ___) =>
                              _thumbPlaceholder(),
                        )
                      : _thumbPlaceholder(),
                ),
              ),
            ),
            Positioned(
              top: 0,
              left: 0,
              child: Text(
                '$rank',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                  color: _rankColor,
                  shadows: [
                    Shadow(
                      color: Colors.black.withValues(alpha: 0.6),
                      blurRadius: 4,
                    ),
                  ],
                ),
              ),
            ),
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    track.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: spotifyWhite,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    track.displayArtist,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: spotifyLightGrey.withValues(alpha: 0.8),
                      fontSize: 11,
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

// ═══════════════════════════════════════════════════════════════════
//  CHARTS GRID — compact numbered list (ranked 1-20)
// ═══════════════════════════════════════════════════════════════════

class _ChartsGridSection extends ConsumerWidget {
  const _ChartsGridSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final chartsAsync = ref.watch(homeChartsProvider);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.fromLTRB(16, 0, 16, 12),
          child: Text(
            'Classement complet',
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w700,
              color: spotifyWhite,
            ),
          ),
        ),
        chartsAsync.when(
          loading: () => const Center(
            child: CircularProgressIndicator(
                color: Color(0xFF1DDA63), strokeWidth: 2),
          ),
          error: (_, __) => const SizedBox.shrink(),
          data: (charts) {
            final tracks = charts.tracks;
            if (tracks.isEmpty) return const SizedBox.shrink();
            final top = tracks.take(20).toList();
            return Column(
              children: top.asMap().entries.map((entry) {
                final i = entry.key;
                final track = entry.value;
                final rank = i + 1;
                final thumb = track.thumbnails.isNotEmpty
                    ? track.thumbnails.last.url
                    : '';
                return GestureDetector(
                  onTap: () {
                    HapticFeedback.lightImpact();
                    ref.read(audioHandlerProvider).playAll(
                          top,
                          startIndex: i,
                        );
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 8),
                    child: Row(
                      children: [
                        SizedBox(
                          width: 28,
                          child: Text(
                            '$rank',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: rank <= 3
                                  ? const Color(0xFFFFD700)
                                  : spotifyLightGrey,
                            ),
                          ),
                        ),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: SizedBox(
                            width: 48,
                            height: 48,
                            child: thumb.isNotEmpty
                                ? CachedNetworkImage(
                                    imageUrl: thumb,
                                    fit: BoxFit.cover,
                                    errorWidget: (_, __, ___) =>
                                        _thumbPlaceholder(),
                                  )
                                : _thumbPlaceholder(),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment:
                                CrossAxisAlignment.start,
                            children: [
                              Text(
                                track.title,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: spotifyWhite,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                track.displayArtist,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: spotifyLightGrey
                                      .withValues(alpha: 0.7),
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (track.duration != null)
                          Text(
                            track.duration!,
                            style: TextStyle(
                              color: spotifyLightGrey
                                  .withValues(alpha: 0.5),
                              fontSize: 12,
                            ),
                          ),
                        const SizedBox(width: 4),
                        Icon(
                          Icons.more_vert_rounded,
                          color: spotifyLightGrey.withValues(alpha: 0.4),
                          size: 20,
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            );
          },
        ),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
//  PLAYLISTS — editorial playlists (iTunes RSS → YouTube)
// ═══════════════════════════════════════════════════════════════════

class _PlaylistsSection extends ConsumerWidget {
  const _PlaylistsSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final chartsAsync = ref.watch(homeChartsProvider);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.fromLTRB(16, 0, 16, 12),
          child: Text(
            'Playlists à écouter',
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w700,
              color: spotifyWhite,
            ),
          ),
        ),
        SizedBox(
          height: 200,
          child: chartsAsync.when(
            loading: () => const Center(
              child: CircularProgressIndicator(
                  color: Color(0xFF1DDA63), strokeWidth: 2),
            ),
            error: (_, __) => const SizedBox.shrink(),
            data: (charts) {
final playlists = charts.playlists;
              if (playlists.isEmpty) return const SizedBox.shrink();
              return ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: playlists.length.clamp(0, 15),
                itemExtent: 150,
                itemBuilder: (context, i) {
                  final pl = playlists[i];
                  final plThumb = pl.thumbnails.isNotEmpty
                      ? pl.thumbnails.last.url
                      : '';
                  return GestureDetector(
                    onTap: () {
                      HapticFeedback.lightImpact();
                      _openPlaylist(context, pl);
                    },
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(6),
                          child: SizedBox(
                            width: 138,
                            height: 138,
                            child: plThumb.isNotEmpty
                                ? CachedNetworkImage(
                                    imageUrl: plThumb,
                                    fit: BoxFit.cover,
                                    placeholder: (_, __) =>
                                        _thumbPlaceholder(),
                                    errorWidget: (_, __, ___) =>
                                        _thumbPlaceholder(),
                                  )
                                : _thumbPlaceholder(),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          pl.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: spotifyWhite,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          pl.displayArtist,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: spotifyLightGrey
                                .withValues(alpha: 0.8),
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  void _openPlaylist(BuildContext context, MuzoItem pl) {
    final id = pl.browseId ?? pl.videoId;
    if (id == null) return;
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => PlaylistScreen(
          playlistId: id,
          title: pl.title,
          thumbnailUrl:
              pl.thumbnails.isNotEmpty ? pl.thumbnails.last.url : null,
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
//  NEW RELEASES — albums
// ═══════════════════════════════════════════════════════════════════

class _NewReleasesSection extends ConsumerWidget {
  const _NewReleasesSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final chartsAsync = ref.watch(homeChartsProvider);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.fromLTRB(16, 0, 16, 12),
          child: Text(
            'Nouveaux albums',
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w700,
              color: spotifyWhite,
            ),
          ),
        ),
        SizedBox(
          height: 200,
          child: chartsAsync.when(
            loading: () => const Center(
              child: CircularProgressIndicator(
                  color: Color(0xFF1DDA63), strokeWidth: 2),
            ),
            error: (_, __) => const SizedBox.shrink(),
            data: (charts) {
final albums = charts.albums;
              if (albums.isEmpty) return const SizedBox.shrink();
              return ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: albums.length.clamp(0, 20),
                itemExtent: 150,
                itemBuilder: (context, i) {
                  final album = albums[i];
                  final albumThumb = album.thumbnails.isNotEmpty
                      ? album.thumbnails.last.url
                      : '';
                  return GestureDetector(
                    onTap: () {
                      HapticFeedback.lightImpact();
                      final id = album.browseId ?? album.videoId;
                      if (id == null) return;
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => AlbumScreen(
                            albumId: id,
                            albumName: album.title,
                            thumbnailUrl: albumThumb,
                          ),
                        ),
                      );
                    },
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(6),
                          child: SizedBox(
                            width: 138,
                            height: 138,
                            child: albumThumb.isNotEmpty
                                ? CachedNetworkImage(
                                    imageUrl: albumThumb,
                                    fit: BoxFit.cover,
                                    placeholder: (_, __) =>
                                        _thumbPlaceholder(),
                                    errorWidget: (_, __, ___) =>
                                        _thumbPlaceholder(),
                                  )
                                : _thumbPlaceholder(),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          album.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: spotifyWhite,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          album.displayArtist,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: spotifyLightGrey
                                .withValues(alpha: 0.8),
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
//  NEW TRACKS — additional tracks row
// ═══════════════════════════════════════════════════════════════════

class _NewTracksSection extends ConsumerWidget {
  const _NewTracksSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final chartsAsync = ref.watch(homeChartsProvider);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.fromLTRB(16, 0, 16, 12),
          child: Text(
            'Titres populaires',
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w700,
              color: spotifyWhite,
            ),
          ),
        ),
        SizedBox(
          height: 200,
          child: chartsAsync.when(
            loading: () => const Center(
              child: CircularProgressIndicator(
                  color: Color(0xFF1DDA63), strokeWidth: 2),
            ),
            error: (_, __) => const SizedBox.shrink(),
            data: (charts) {
              final tracks = charts.tracks;
              if (tracks.isEmpty) return const SizedBox.shrink();
              // Second half of charts as "popular tracks"
              final popular = tracks.length > 10
                  ? tracks.sublist(10, tracks.length.clamp(10, 30))
                  : tracks;
              return ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: popular.length,
                itemExtent: 150,
                itemBuilder: (context, i) {
                  final track = popular[i];
                  final thumb = track.thumbnails.isNotEmpty
                      ? track.thumbnails.last.url
                      : '';
                  return GestureDetector(
                    onTap: () {
                      HapticFeedback.lightImpact();
                      ref.read(audioHandlerProvider).playAll(
                            popular,
                            startIndex: i,
                          );
                    },
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(6),
                          child: SizedBox(
                            width: 138,
                            height: 138,
                            child: thumb.isNotEmpty
                                ? CachedNetworkImage(
                                    imageUrl: thumb,
                                    fit: BoxFit.cover,
                                    placeholder: (_, __) =>
                                        _thumbPlaceholder(),
                                    errorWidget: (_, __, ___) =>
                                        _thumbPlaceholder(),
                                  )
                                : _thumbPlaceholder(),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          track.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: spotifyWhite,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          track.displayArtist,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: spotifyLightGrey
                                .withValues(alpha: 0.8),
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
//  SHARED
// ═══════════════════════════════════════════════════════════════════

Widget _thumbPlaceholder() {
  return Container(
    color: spotifyDarkGrey,
    child: const Center(
      child: Icon(Icons.music_note_rounded,
          color: Colors.white24, size: 32),
    ),
  );
}

