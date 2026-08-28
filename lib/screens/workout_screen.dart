import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:muzo/providers/workout_providers.dart';
import 'package:muzo/screens/category_playlist_screen.dart';
import 'package:muzo/screens/global_search_screen.dart';
import 'package:muzo/widgets/playlist_collage.dart';
import 'package:muzo/widgets/spotify_back_button.dart';
import 'package:muzo/widgets/spotify_chips.dart';

/// Spotify-style Workout page: workout types, albums, playlists and round
/// artist avatars, all backed by the free Audius + Jamendo catalogs.
class WorkoutScreen extends ConsumerWidget {
  const WorkoutScreen({super.key});

  static const Color _color = Color(0xFF777777);

  static const List<({String title, String query, IconData icon, Color color})>
      _types = [
    (
      title: 'Running',
      query: 'running',
      icon: Icons.directions_run,
      color: Color(0xFFE11D48),
    ),
    (
      title: 'Cardio',
      query: 'cardio',
      icon: Icons.favorite,
      color: Color(0xFFF97316),
    ),
    (
      title: 'HIIT',
      query: 'hiit',
      icon: Icons.timer,
      color: Color(0xFF8B5CF6),
    ),
    (
      title: 'Dance',
      query: 'dance',
      icon: Icons.celebration,
      color: Color(0xFFEC4899),
    ),
    (
      title: 'Hip-Hop',
      query: 'hip hop',
      icon: Icons.mic,
      color: Color(0xFFF59E0B),
    ),
    (
      title: 'EDM',
      query: 'edm',
      icon: Icons.graphic_eq,
      color: Color(0xFF06B6D4),
    ),
    (
      title: 'Rock',
      query: 'rock',
      icon: Icons.album,
      color: Color(0xFFEF4444),
    ),
    (
      title: 'Yoga',
      query: 'yoga',
      icon: Icons.self_improvement,
      color: Color(0xFF10B981),
    ),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final albumsAsync = ref.watch(workoutAlbumsProvider('workout'));
    final playlistsAsync = ref.watch(workoutPlaylistsProvider('workout'));
    final artistsAsync = ref.watch(workoutArtistsProvider('workout'));
    final albums = albumsAsync.value ?? [];
    final playlists = playlistsAsync.value ?? [];
    final artists = artistsAsync.value ?? [];

    return Scaffold(
      backgroundColor: spotifyBlack,
      body: SafeArea(
        bottom: false,
        child: CustomScrollView(
          slivers: [
            SliverAppBar(
              backgroundColor: _color,
              surfaceTintColor: Colors.transparent,
              elevation: 0,
              pinned: true,
              leading: const SpotifyBackButton(),
              title: const Text(
                'Workout',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: spotifyWhite,
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                ),
              ),
              centerTitle: true,
            ),

            // ─── Banner ───
            SliverToBoxAdapter(child: _banner(context)),

            // ─── Workout types ───
            _section(
              'Workout types',
              child: _typesRow(context),
            ),

            // ─── Albums ───
            if (albumsAsync.isLoading)
              _section('Albums', child: _loadingRow(square: true))
            else if (albums.isNotEmpty)
              _section('Albums', child: _albumsRow(albums, ref)),

            // ─── Playlists ───
            if (playlistsAsync.isLoading)
              _section('Playlists', child: _loadingRow(square: true))
            else if (playlists.isNotEmpty)
              _section('Playlists', child: _playlistsRow(playlists, ref)),

            // ─── Artists ───
            if (artistsAsync.isLoading)
              _section('Artists', child: _loadingRow(square: false))
            else if (artists.isNotEmpty)
              _section('Artists', child: _artistsRow(artists, ref)),

            const SliverPadding(padding: EdgeInsets.only(bottom: 130)),
          ],
        ),
      ),
    );
  }

  Widget _banner(BuildContext context) {
    return Container(
      height: 200,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [_color, Color.lerp(_color, spotifyBlack, 0.7)!],
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            top: 4,
            left: 12,
            right: 12,
            child: Row(
              children: [
                const SpotifyBackButton(),
                const Spacer(),
                _iconButton(
                  Icons.search,
                  () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const GlobalSearchScreen(),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Positioned(
            left: 20,
            right: 140,
            bottom: 26,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Workout',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: spotifyWhite,
                    fontSize: 36,
                    height: 1.02,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Run, lift and sweat to fresh tracks — free music '
                  'from Audius and Jamendo.',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: spotifyWhite.withValues(alpha: 0.75),
                    fontSize: 13,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
          Positioned(
            right: 16,
            bottom: 22,
            child: Transform.rotate(
              angle: 0.12,
              child: Container(
                width: 92,
                height: 92,
                decoration: const BoxDecoration(
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black38,
                      blurRadius: 14,
                      offset: Offset(0, 4),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: Image.asset(
                    'assets/spotify/home/Rap-Workout.jpg',
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      color: Colors.black26,
                      child: const Icon(
                        Icons.fitness_center,
                        color: spotifyWhite,
                        size: 30,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _iconButton(IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.all(6),
        child: Icon(icon, color: spotifyWhite, size: 24),
      ),
    );
  }

  // ─── Sections ───

  SliverToBoxAdapter _section(String title, {required Widget child}) {
    return SliverToBoxAdapter(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 22, 8, 12),
            child: Text(
              title,
              style: const TextStyle(
                color: spotifyWhite,
                fontSize: 17,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          child,
        ],
      ),
    );
  }

  // ─── Types ───

  Widget _typesRow(BuildContext context) {
    return SizedBox(
      height: 104,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: _types.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          final t = _types[index];
          return GestureDetector(
            onTap: () => _openType(context, t.title, t.query),
            child: Container(
              width: 150,
              height: 104,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    t.color,
                    Color.lerp(t.color, spotifyBlack, 0.45)!,
                  ],
                ),
              ),
              child: Stack(
                children: [
                  Positioned(
                    right: 8,
                    top: 6,
                    child: Container(
                      width: 34,
                      height: 34,
                      decoration: BoxDecoration(
                        color: spotifyBlack.withValues(alpha: 0.25),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(t.icon, color: spotifyWhite, size: 20),
                    ),
                  ),
                  Positioned(
                    left: 10,
                    right: 10,
                    bottom: 8,
                    child: Text(
                      t.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: spotifyWhite,
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        height: 1.15,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  /// Placeholder row shown while albums/playlists/artists are loading.
  Widget _loadingRow({required bool square}) {
    return SizedBox(
      height: square ? 218 : 150,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: 6,
        separatorBuilder: (_, __) => const SizedBox(width: 14),
        itemBuilder: (context, index) {
          if (square) {
            return SizedBox(
              width: 140,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 140,
                    height: 140,
                    decoration: BoxDecoration(
                      color: spotifyDarkGrey,
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  const SizedBox(height: 10),
                  _shimmerBar(width: 110),
                  const SizedBox(height: 6),
                  _shimmerBar(width: 70),
                ],
              ),
            );
          }
          return Column(
            children: [
              Container(
                width: 88,
                height: 88,
                decoration: const BoxDecoration(
                  color: spotifyDarkGrey,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(height: 10),
              _shimmerBar(width: 80),
            ],
          );
        },
      ),
    );
  }

  Widget _shimmerBar({required double width}) {
    return Container(
      width: width,
      height: 10,
      decoration: BoxDecoration(
        color: spotifyDarkGrey,
        borderRadius: BorderRadius.circular(4),
      ),
    );
  }

  void _openType(BuildContext context, String title, String query) {
    HapticFeedback.lightImpact();
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => WorkoutTypeScreen(title: title, query: query),
      ),
    );
  }

  // ─── Albums ───

  Widget _albumsRow(List<WorkoutAlbum> albums, WidgetRef ref) {
    return SizedBox(
      height: 218,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: albums.length,
        separatorBuilder: (_, __) => const SizedBox(width: 14),
        itemBuilder: (context, index) {
          final album = albums[index];
          return GestureDetector(
            onTap: () => _openCollection(
              context,
              ref,
              title: album.name,
              subtitle: album.artist,
              coverUrl: album.coverUrl,
              source: album.source,
              type: 'album',
              id: album.id,
            ),
            child: SizedBox(
              width: 140,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _squareCover(album.coverUrl, 140),
                  const SizedBox(height: 8),
                  Text(
                    album.name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: spotifyWhite,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      height: 1.2,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    album.artist,
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
        },
      ),
    );
  }

  // ─── Playlists ───

  Widget _playlistsRow(List<WorkoutPlaylist> playlists, WidgetRef ref) {
    return SizedBox(
      height: 180,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: playlists.length,
        separatorBuilder: (_, __) => const SizedBox(width: 14),
        itemBuilder: (context, index) {
          final p = playlists[index];
          return GestureDetector(
            onTap: () => _openCollection(
              context,
              ref,
              title: p.name,
              coverUrl: p.coverUrl,
              source: p.source,
              type: 'playlist',
              id: p.id,
            ),
            child: SizedBox(
              width: 150,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: 150,
                    height: 150,
                    child: p.coverUrl.isNotEmpty
                        ? _squareCover(p.coverUrl, 150)
                        : const PlaylistCollage(urls: []),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    p.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: spotifyWhite,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // ─── Artists ───

  Widget _artistsRow(List<WorkoutArtist> artists, WidgetRef ref) {
    return SizedBox(
      height: 150,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: artists.length,
        separatorBuilder: (_, __) => const SizedBox(width: 18),
        itemBuilder: (context, index) {
          final artist = artists[index];
          return GestureDetector(
            onTap: () => _openArtist(context, ref, artist.name),
            child: SizedBox(
              width: 100,
              child: Column(
                children: [
                  _avatar(artist.imageUrl, artist.name, 88),
                  const SizedBox(height: 10),
                  Text(
                    artist.name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: spotifyWhite,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      height: 1.15,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _avatar(String imageUrl, String name, double size) {
    if (imageUrl.isEmpty) return _initialsAvatar(name, size);
    return ClipOval(
      child: CachedNetworkImage(
        imageUrl: imageUrl,
        width: size,
        height: size,
        fit: BoxFit.cover,
        errorWidget: (_, __, ___) => _initialsAvatar(name, size),
      ),
    );
  }

  Widget _initialsAvatar(String name, double size) {
    final letters = name
        .split(' ')
        .where((w) => w.isNotEmpty)
        .take(2)
        .map((w) => w[0])
        .join()
        .toUpperCase();
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: Color.lerp(_color, spotifyBlack, 0.25),
        shape: BoxShape.circle,
      ),
      alignment: Alignment.center,
      child: Text(
        letters,
        style: TextStyle(
          color: spotifyWhite,
          fontSize: size * 0.32,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }

  // ─── Actions ───

  void _openCollection(
    BuildContext context,
    WidgetRef ref, {
    required String title,
    String? subtitle,
    String? coverUrl,
    required String source,
    required String type,
    required String id,
  }) {
    HapticFeedback.lightImpact();
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => WorkoutCollectionScreen(
          title: title,
          subtitle: subtitle,
          coverUrl: coverUrl,
          source: source,
          type: type,
          id: id,
        ),
      ),
    );
  }

  void _openArtist(BuildContext context, WidgetRef ref, String name) {
    HapticFeedback.lightImpact();
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => WorkoutTypeScreen(title: name, query: name),
      ),
    );
  }

  Widget _squareCover(String url, double size) {
    final placeholder = Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [spotifyDarkGrey, _color.withValues(alpha: 0.35)],
        ),
        borderRadius: BorderRadius.circular(8),
      ),
      child: const Icon(Icons.music_note, color: spotifyWhite, size: 30),
    );
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.4),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: url.isEmpty
          ? placeholder
          : ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: CachedNetworkImage(
                imageUrl: url,
                width: size,
                height: size,
                fit: BoxFit.cover,
                errorWidget: (_, __, ___) => placeholder,
              ),
            ),
    );
  }
}

/// Tracks page for a workout type or artist (search query backed).
class WorkoutTypeScreen extends ConsumerWidget {
  const WorkoutTypeScreen({super.key, required this.title, required this.query});

  final String title;
  final String query;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final songsAsync = ref.watch(workoutSongsProvider(query));

    return Scaffold(
      backgroundColor: spotifyBlack,
      body: songsAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: Color(0xFF1DDA63)),
        ),
        error: (_, __) => Center(
          child: Text(
            'Failed to load "$title"',
            style: const TextStyle(color: spotifyWhite),
          ),
        ),
        data: (songs) => songs.isEmpty
            ? Center(
                child: Text(
                  'No tracks found for "$title"',
                  style: const TextStyle(color: spotifyLightGrey),
                ),
              )
            : CategoryPlaylistScreen(
                title: title,
                songs: songs,
                color: WorkoutScreen._color,
                subtitle: '${songs.length} tracks • Free music',
              ),
      ),
    );
  }
}

/// Tracks page for a specific album / playlist (Audius or Jamendo).
class WorkoutCollectionScreen extends ConsumerWidget {
  const WorkoutCollectionScreen({
    super.key,
    required this.title,
    this.subtitle,
    this.coverUrl,
    required this.source,
    required this.type,
    required this.id,
  });

  final String title;
  final String? subtitle;
  final String? coverUrl;
  final String source;
  final String type;
  final String id;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final songsAsync = ref.watch(
      workoutCollectionTracksProvider((source: source, type: type, id: id)),
    );

    return Scaffold(
      backgroundColor: spotifyBlack,
      body: songsAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: Color(0xFF1DDA63)),
        ),
        error: (_, __) => Center(
          child: Text(
            'Failed to load "$title"',
            style: const TextStyle(color: spotifyWhite),
          ),
        ),
        data: (songs) => songs.isEmpty
            ? Center(
                child: Text(
                  'No tracks found for "$title"',
                  style: const TextStyle(color: spotifyLightGrey),
                ),
              )
            : CategoryPlaylistScreen(
                title: title,
                songs: songs,
                color: WorkoutScreen._color,
                subtitle: subtitle,
                coverUrl: coverUrl,
              ),
      ),
    );
  }
}
