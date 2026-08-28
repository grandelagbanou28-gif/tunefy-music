import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:muzo/models/muzo_item.dart';
import 'package:muzo/providers/category_providers.dart';
import 'package:muzo/providers/download_provider.dart';
import 'package:muzo/providers/player_provider.dart';
import 'package:muzo/providers/search_provider.dart';
import 'package:muzo/services/storage_service.dart';
import 'package:muzo/widgets/spotify_back_button.dart';
import 'package:muzo/widgets/spotify_chips.dart';
import 'package:share_plus/share_plus.dart';

/// A full Spotify-style artist page opened from a category or sub-category:
/// large cover header, verified badge, monthly listeners, Play / Shuffle,
/// then "Populaires" (30+ songs, expandable), discography, and similar
/// artists — mirroring the real Spotify artist screen.
class ArtistPageScreen extends ConsumerStatefulWidget {
  const ArtistPageScreen({
    super.key,
    required this.artistName,
    this.imageUrl,
    this.color = const Color(0xFF1DDA63),
    this.fallbackAsset,
  });

  final String artistName;
  final String? imageUrl;
  final Color color;
  final String? fallbackAsset;

  @override
  ConsumerState<ArtistPageScreen> createState() => _ArtistPageScreenState();
}

class _ArtistPageScreenState extends ConsumerState<ArtistPageScreen> {
  String get artistName => widget.artistName;

  Color get color => widget.color;

  String? get imageUrl => widget.imageUrl;

  String? get fallbackAsset => widget.fallbackAsset;

  int _selectedSongIndex = -1;

  /// Deterministic pseudo monthly-listener count derived from the artist
  /// name, so the figure is stable across visits (like a cached stat).
  int get _monthlyListeners {
    var h = 0;
    for (final c in artistName.toLowerCase().codeUnits) {
      h = h * 31 + c;
    }
    return 850_000 + (h.abs() % 47_000_000);
  }

  String get _listenersLabel {
    final n = _monthlyListeners;
    if (n >= 1_000_000) {
      return '${(n / 1_000_000).toStringAsFixed(1).replaceAll('.', ',')} M';
    }
    return '${(n / 1000).round()} k';
  }

  @override
  Widget build(BuildContext context) {
    final ref = this.ref;
    try {
    final songsAsync = ref.watch(artistSongsProvider(artistName));
    // Only keep playable tracks (non-null videoId) so tapping a row reliably
    // plays that exact song — playAll skips id-less items internally, which
    // used to shift the seek index and "play the wrong thing".
    final songs = (songsAsync.valueOrNull ?? [])
        .where((s) => s.videoId != null)
        .toList();
    final albumsAsync = ref.watch(categoryAlbumsProvider(artistName));
    final albums = albumsAsync.valueOrNull ?? [];

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        bottom: false,
        child: CustomScrollView(
          slivers: [
            // ─── Collapsing header ───
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
                  artistName,
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
                            Colors.black,
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
                          // Verified artist badge — exact Spotify row.
                          Row(
                            children: [
                              Container(
                                width: 22,
                                height: 22,
                                decoration: const BoxDecoration(
                                  color: Color(0xFF3D91F4),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.check_rounded,
                                  color: spotifyWhite,
                                  size: 15,
                                ),
                              ),
                              const SizedBox(width: 6),
                              const Text(
                                'Artiste vérifié',
                                style: TextStyle(
                                  color: spotifyWhite,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Expanded(
                                child: Text(
                                  artistName,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    color: spotifyWhite,
                                    fontSize: 34,
                                    height: 1.02,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '$_listenersLabel auditeurs mensuels',
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
            SliverToBoxAdapter(
              child: _buildActionBar(context, songs, ref),
            ),

            // ─── State: loading / error / empty / content ───
            if (songsAsync.isLoading)
              const SliverFillRemaining(
                hasScrollBody: false,
                child: Center(
                  child: CircularProgressIndicator(color: Color(0xFF1DDA63)),
                ),
              )
            else if (songsAsync.hasError)
              SliverFillRemaining(
                hasScrollBody: false,
                child: _buildErrorState(ref),
              )
            else if (songs.isEmpty)
              SliverFillRemaining(
                hasScrollBody: false,
                child: _buildEmptyState(ref),
              )
            else ...[
              // ─── Populaires (30+, Spotify-style expandable) ───
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 22, 16, 8),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Populaires',
                          style: const TextStyle(
                            color: spotifyWhite,
                            fontSize: 19,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      Text(
                        '${songs.length} titres',
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
                        onSingerTap: () {
                          final name = primaryArtistName(song.displayArtist);
                          if (name.isEmpty) return;
                          // Tapping the same artist on their own page should
                          // play the song, not re-open a duplicate artist page.
                          if (name.toLowerCase() == artistName.toLowerCase()) {
                            HapticFeedback.lightImpact();
                            final handler = ref.read(audioHandlerProvider);
                            handler.isShuffleModeNotifier.value = false;
                            handler.playAll(songs, startIndex: index);
                            return;
                          }
                          HapticFeedback.lightImpact();
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => ArtistPageScreen(
                                artistName: name,
                                imageUrl: img,
                                color: color,
                                fallbackAsset: fallbackAsset,
                              ),
                            ),
                          );
                        },
                        onTap: () {
                          HapticFeedback.lightImpact();
                          setState(() {
                            _selectedSongIndex = index;
                          });
                          final handler = ref.read(audioHandlerProvider);
                          handler.isShuffleModeNotifier.value = false;
                          handler.playAll(songs, startIndex: index);
                        },
                      );
                     },
                     childCount: songs.length,
                   ),
                 ),
               ),

              // ─── Discographie ───
              if (albums.isNotEmpty) ...[
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 24, 16, 12),
                    child: Text(
                      'Discographie',
                      style: const TextStyle(
                        color: spotifyWhite,
                        fontSize: 19,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
                SliverToBoxAdapter(
                  child: SizedBox(
                    height: 190,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: albums.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 16),
                      itemBuilder: (context, index) {
                        final album = albums[index];
                        return _albumCard(context, album);
                      },
                    ),
                  ),
                ),
              ],
            ],

              const SliverPadding(padding: EdgeInsets.only(bottom: 130)),
          ],
        ),
      ),
    );
    } catch (e, st) {
      debugPrint('ArtistPageScreen build error: $e\n$st');
      return Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, color: Colors.white70, size: 48),
              const SizedBox(height: 16),
              Text(
                'Error loading $artistName',
                style: const TextStyle(color: Colors.white70, fontSize: 16),
              ),
              const SizedBox(height: 12),
              GestureDetector(
                onTap: () => Navigator.of(context).pop(),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1DB954),
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: const Text('Back',
                      style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      );
    }
  }


  Widget _headerCover() {
    final url = imageUrl ?? '';
    Widget fallback() {
      final asset = fallbackAsset;
      if (asset != null && asset.isNotEmpty) {
        return Image.asset(
          asset,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => Container(
            color: color.withValues(alpha: 0.4),
            child: Icon(Icons.person, color: spotifyWhite, size: 90),
          ),
        );
      }
      return Container(
        color: color.withValues(alpha: 0.4),
        child: Icon(Icons.person, color: spotifyWhite, size: 90),
      );
    }

    if (url.isEmpty) return fallback();
    return CachedNetworkImage(
      imageUrl: url,
      fit: BoxFit.cover,
      errorWidget: (_, __, ___) => fallback(),
    );
  }

  Widget _buildActionBar(BuildContext context, List<MuzoItem> songs, WidgetRef ref) {
    final storage = ref.watch(storageServiceProvider);
    final allDownloaded = songs.isNotEmpty &&
        songs.every((s) =>
            s.videoId != null && storage.isDownloaded(s.videoId!));
    final ui = ref.watch(playerUiStateProvider).valueOrNull;
    final currentMedia = ui?.currentMediaItem;
    final isCurrentInList = currentMedia != null &&
        songs.any((s) => s.videoId == currentMedia.id);

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 6, 16, 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // ─── Left: + (add), Share, Download (Hivefy asset icons) ───
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // + (add all to favorites) — Hivefy add.png / tick.png
              GestureDetector(
                behavior: HitTestBehavior.translucent,
                onTap: songs.isEmpty
                    ? null
                    : () {
                        HapticFeedback.lightImpact();
                        final allFav = songs.isNotEmpty &&
                            songs.every((s) =>
                                s.videoId != null &&
                                storage.isFavorite(s.videoId!));
                        final playable = songs
                            .where((s) => s.videoId != null)
                            .toList();
                        storage.setFavoriteBatch(playable, favorite: !allFav);
                      },
                child: Container(
                  padding: const EdgeInsets.all(12),
                  child: ValueListenableBuilder<List<MuzoItem>>(
                    valueListenable: storage.favoritesListenable,
                    builder: (context, favorites, _) {
                      final allFav = songs.isNotEmpty &&
                          songs.every((s) =>
                              s.videoId != null &&
                              storage.isFavorite(s.videoId!));
                      return Image.asset(
                        allFav
                            ? 'assets/icons/tick.png'
                            : 'assets/icons/add.png',
                        width: 32,
                        height: 32,
                        color: allFav
                            ? const Color(0xFF1DDA63)
                            : Colors.white70,
                      );
                    },
                  ),
                ),
              ),
              // share — Hivefy share.png
              GestureDetector(
                behavior: HitTestBehavior.translucent,
                onTap: () {
                  HapticFeedback.lightImpact();
                  // ignore: deprecated_member_use
                  Share.share('Share $artistName via muzo');
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
              // download (all) — Hivefy download.png / complete_download.png
              GestureDetector(
                behavior: HitTestBehavior.translucent,
                onTap: songs.isEmpty
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
                        // Download sequentially (bounded concurrency) so a
                        // huge artist list doesn't hammer extraction with
                        // hundreds of simultaneous requests.
                        final pending = songs
                            .where((s) =>
                                s.videoId != null &&
                                !storage.isDownloaded(s.videoId!))
                            .toList();
                        int count = pending.length;
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Downloading $count songs...'),
                            backgroundColor: spotifyDarkGrey,
                            duration: const Duration(seconds: 3),
                          ),
                        );
                        for (final s in pending) {
                          ref
                              .read(downloadProvider.notifier)
                              .startDownload(s);
                          // Spread out extraction HTTP work.
                          await Future.delayed(
                            const Duration(milliseconds: 700),
                          );
                        }
                      },
                child: Container(
                  padding: const EdgeInsets.all(12),
                  child: ValueListenableBuilder(
                    // Rebuild when the downloads box changes so the icon
                    // flips to green as each song finishes downloading.
                    valueListenable: storage.downloadsListenable,
                    builder: (context, _, __) {
                      final allDone = songs.isNotEmpty &&
                          songs.every((s) =>
                              s.videoId != null &&
                              storage.isDownloaded(s.videoId!));
                      return Image.asset(
                        allDone
                            ? 'assets/icons/complete_download.png'
                            : 'assets/icons/download.png',
                        width: 32,
                        height: 32,
                        color: allDone
                            ? const Color(0xFF1DDA63)
                            : Colors.white70,
                      );
                    },
                  ),
                ),
              ),
            ],
          ),

          // ─── Right: Shuffle + Play (Hivefy layout) ───
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Shuffle — Hivefy shuffle.png (green while shuffle is on)
              ValueListenableBuilder<bool>(
                valueListenable: ref.watch(shuffleModeNotifierProvider),
                builder: (context, shuffleOn, _) {
                  return GestureDetector(
                    onTap: songs.isEmpty
                        ? null
                        : () async {
                            HapticFeedback.lightImpact();
                            final handler = ref.read(audioHandlerProvider);
                            if (shuffleOn) {
                              // Turn shuffle off, keep current order.
                              handler.isShuffleModeNotifier.value = false;
                            } else {
                              handler.isShuffleModeNotifier.value = true;
                              final shuffled = [...songs]..shuffle();
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
              // Play (green circle) — driven by the REAL audio engine state
              // so the icon can never drift from what is actually audible.
              GestureDetector(
                onTap: songs.isEmpty
                    ? null
                    : () async {
                         HapticFeedback.lightImpact();
                         final handler = ref.read(audioHandlerProvider);
                         final enginePlaying = handler.player.playing;
                         if (isCurrentInList && enginePlaying) {
                           await handler.pause();
                         } else if (isCurrentInList) {
                           await handler.resume();
                         } else {
                           handler.isShuffleModeNotifier.value = false;
                           final startIdx = _selectedSongIndex >= 0 ? _selectedSongIndex : 0;
                           await handler.playAll(songs, startIndex: startIdx);
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
                    initialData: ref
                        .read(audioHandlerProvider)
                        .player
                        .playing,
                    builder: (context, snap) {
                      final enginePlaying = snap.data ?? false;
                      return Icon(
                        isCurrentInList && enginePlaying
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
        ],
      ),
    );
  }

  Widget _albumCard(BuildContext context, CategoryAlbum album) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${album.name} • ${album.artist}'),
            duration: const Duration(seconds: 2),
            backgroundColor: spotifyDarkGrey,
          ),
        );
      },      child: SizedBox(
        width: 150,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: CachedNetworkImage(
                imageUrl: album.coverUrl,
                width: 150,
                height: 150,
                fit: BoxFit.cover,
                errorWidget: (_, __, ___) => Container(
                  color: color.withValues(alpha: 0.3),
                  child: Icon(
                    Icons.album,
                    color: spotifyWhite.withValues(alpha: 0.7),
                    size: 28,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              album.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: spotifyWhite,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              '${album.year}',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: spotifyLightGrey.withValues(alpha: 0.9),
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(WidgetRef ref) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.cloud_off, color: spotifyLightGrey, size: 48),
            const SizedBox(height: 14),
            Text(
              "Couldn't load $artistName",
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: spotifyWhite,
                fontSize: 17,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Check your connection and try again.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: spotifyLightGrey.withValues(alpha: 0.9),
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 22),
            GestureDetector(
              onTap: () {
                HapticFeedback.lightImpact();
                ref.invalidate(artistSongsProvider(artistName));
                ref.invalidate(categoryAlbumsProvider(artistName));
              },
              behavior: HitTestBehavior.opaque,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 28,
                  vertical: 11,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFF1DDA63),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: const Text(
                  'Réessayer',
                  style: TextStyle(
                    color: spotifyBlack,
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(WidgetRef ref) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.music_off, color: spotifyLightGrey, size: 48),
            const SizedBox(height: 14),
            Text(
              'No songs found for $artistName',
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: spotifyWhite,
                fontSize: 17,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 22),
            GestureDetector(
              onTap: () {
                HapticFeedback.lightImpact();
                ref.invalidate(artistSongsProvider(artistName));
                ref.invalidate(categoryAlbumsProvider(artistName));
              },
              behavior: HitTestBehavior.opaque,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 28,
                  vertical: 11,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFF1DDA63),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: const Text(
                  'Réessayer',
                  style: TextStyle(
                    color: spotifyBlack,
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
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
