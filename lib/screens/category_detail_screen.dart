import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:muzo/models/muzo_item.dart';
import 'package:muzo/screens/category_playlist_screen.dart';
import 'package:muzo/services/muzo_api_service.dart';
import 'package:muzo/widgets/spotify_back_button.dart';
import 'package:muzo/widgets/spotify_chips.dart';

/// Hivefy-style detail page opened from a category card: it fetches the real
/// tracks for an album/artist/single, then shows a page that lists every
/// title with Play/Shuffle. Loading / error / empty states are handled here so
/// a tap always lands on a page, never on a silent return.
class CategoryDetailScreen extends ConsumerStatefulWidget {
  const CategoryDetailScreen({
    super.key,
    required this.title,
    required this.query,
    required this.color,
    this.subtitle,
    this.coverUrl,
    this.fallbackAsset,
  });

  final String title;

  /// Search query used to fetch the real tracks (album+artist, artist name…).
  final String query;
  final Color color;
  final String? subtitle;
  final String? coverUrl;

  /// Local bundled cover shown when no remote artwork can be fetched.
  final String? fallbackAsset;

  @override
  ConsumerState<CategoryDetailScreen> createState() =>
      _CategoryDetailScreenState();
}

class _CategoryDetailScreenState extends ConsumerState<CategoryDetailScreen> {
  late Future<List<MuzoItem>> _future;

  @override
  void initState() {
    super.initState();
    _future = _fetch();
  }

  Future<List<MuzoItem>> _fetch() async {
    final api = ref.read(muzoApiServiceProvider);
    final response = await api
        .search(widget.query, filter: 'songs')
        .timeout(const Duration(seconds: 15));
    return dedupeMuzoSongs(response.results);
  }

  void _retry() {
    setState(() => _future = _fetch());
  }

  String get _cover =>
      (widget.coverUrl != null && widget.coverUrl!.isNotEmpty)
          ? widget.coverUrl!
          : '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: spotifyBlack,
      body: SafeArea(
        bottom: false,
        child: FutureBuilder<List<MuzoItem>>(
          future: _future,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return _shell(
                Center(
                  child: CircularProgressIndicator(color: widget.color),
                ),
              );
            }
            if (snapshot.hasError || snapshot.data == null) {
              return _shell(_buildErrorState());
            }
            final songs = snapshot.data!;
            if (songs.isEmpty) {
              return _shell(_buildEmptyState());
            }
            return CategoryPlaylistScreen(
              title: widget.title,
              songs: songs,
              color: widget.color,
              subtitle: widget.subtitle,
              coverUrl: _cover,
            );
          },
        ),
      ),
    );
  }

  /// Pinned bar + state content, so the screen stays consistent (Hivefy-like)
  /// even while loading or when the network fails.
  Widget _shell(Widget body) {
    return CustomScrollView(
      slivers: [
        SliverAppBar(
          backgroundColor: widget.color,
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
                colors: [widget.color, Color.lerp(widget.color, spotifyBlack, 0.7)!],
              ),
            ),
            child: Column(
              children: [
                SizedBox(width: 160, height: 160, child: _coverBox()),
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
                if (widget.subtitle != null) ...[
                  const SizedBox(height: 6),
                  Text(
                    widget.subtitle!,
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: spotifyLightGrey.withValues(alpha: 0.9),
                      fontSize: 13,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
        SliverFillRemaining(hasScrollBody: false, child: body),
      ],
    );
  }

  Widget _coverBox() {
    if (_cover.isNotEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: CachedNetworkImage(
          imageUrl: _cover,
          fit: BoxFit.cover,
          errorWidget: (_, __, ___) => _fallbackCover(),
        ),
      );
    }
    return _fallbackCover();
  }

  Widget _fallbackCover() {
    final asset = widget.fallbackAsset;
    if (asset != null && asset.isNotEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Image.asset(
          asset,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => _iconCover(),
        ),
      );
    }
    return _iconCover();
  }

  Widget _iconCover() {
    return Container(
      color: Colors.black26,
      alignment: Alignment.center,
      child: const Icon(Icons.album, color: spotifyWhite, size: 32),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.cloud_off, color: spotifyLightGrey, size: 48),
            const SizedBox(height: 14),
            Text(
              "Couldn't load ${widget.title}",
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
            _retryButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.music_off, color: spotifyLightGrey, size: 48),
            const SizedBox(height: 14),
            Text(
              'No tracks found for "${widget.title}"',
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: spotifyWhite,
                fontSize: 17,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              "We couldn't find any tracks. Try again or pick another one.",
              textAlign: TextAlign.center,
              style: TextStyle(
                color: spotifyLightGrey.withValues(alpha: 0.9),
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 22),
            _retryButton(),
          ],
        ),
      ),
    );
  }

  Widget _retryButton() {
    return GestureDetector(
      onTap: _retry,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 11),
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
    );
  }
}
