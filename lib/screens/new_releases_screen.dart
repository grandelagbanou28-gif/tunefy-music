import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:muzo/providers/category_providers.dart';
import 'package:muzo/screens/category_playlist_screen.dart';
import 'package:muzo/services/muzo_api_service.dart';
import 'package:muzo/widgets/spotify_back_button.dart';
import 'package:muzo/widgets/spotify_chips.dart';

/// "Nouvelles sorties": albums filtered by Today / This week / This month.
class NewReleasesScreen extends ConsumerWidget {
  const NewReleasesScreen({
    super.key,
    required this.title,
    required this.albums,
    required this.color,
  });

  final String title;
  final List<CategoryAlbum> albums;
  final Color color;

  static const _tabs = ['Today', 'This week', 'This month'];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return DefaultTabController(
      length: _tabs.length,
      child: Scaffold(
        backgroundColor: spotifyBlack,
        body: SafeArea(
          bottom: false,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
                child: Row(
                  children: [
                    const SpotifyBackButton(),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: spotifyWhite,
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              TabBar(
                isScrollable: true,
                labelColor: spotifyBlack,
                unselectedLabelColor: spotifyWhite,
                indicator: const BoxDecoration(
                  color: spotifyWhite,
                  borderRadius: BorderRadius.all(Radius.circular(500)),
                ),
                labelStyle: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
                dividerColor: Colors.transparent,
                indicatorSize: TabBarIndicatorSize.label,
                tabs: [for (final t in _tabs) Tab(text: t)],
              ),
              Expanded(
                child: TabBarView(
                  children: [
                    for (var i = 0; i < _tabs.length; i++)
                      _list(context, ref, _filter(i)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<CategoryAlbum> _filter(int tab) {
    final now = DateTime.now();
    final start = DateTime(now.year, now.month, now.day);
    return albums.where((a) {
      final d = a.releaseDate;
      if (d == null) return false;
      final day = DateTime(d.year, d.month, d.day);
      switch (tab) {
        case 0:
          return day.isAtSameMomentAs(start);
        case 1:
          return day.isAfter(start.subtract(const Duration(days: 7)));
        default:
          return day.isAfter(start.subtract(const Duration(days: 30)));
      }
    }).toList();
  }

  Widget _list(
    BuildContext context,
    WidgetRef ref,
    List<CategoryAlbum> list,
  ) {
    if (list.isEmpty) {
      return const Center(
        child: Text(
          'Nothing here yet',
          style: TextStyle(color: spotifyLightGrey),
        ),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 130),
      itemCount: list.length,
      itemBuilder: (context, index) {
        final album = list[index];
        return GestureDetector(
          onTap: () => _openAlbum(context, ref, album),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Row(
              children: [
                _cover(album.coverUrl),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        album.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: spotifyWhite,
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${album.artist} • ${album.year}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: spotifyLightGrey.withValues(alpha: 0.9),
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _cover(String url) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(6),
      child: CachedNetworkImage(
        imageUrl: url,
        width: 52,
        height: 52,
        fit: BoxFit.cover,
        errorWidget: (_, __, ___) => Container(
          width: 52,
          height: 52,
          color: spotifyDarkGrey,
          child: const Icon(Icons.album, color: spotifyWhite, size: 22),
        ),
      ),
    );
  }

  Future<void> _openAlbum(
    BuildContext context,
    WidgetRef ref,
    CategoryAlbum album,
  ) async {
    HapticFeedback.lightImpact();
    try {
      final api = ref.read(muzoApiServiceProvider);
      final response = await api
          .search('${album.name} ${album.artist}', filter: 'songs')
          .timeout(const Duration(seconds: 10));
      if (response.results.isEmpty || !context.mounted) return;
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => CategoryPlaylistScreen(
            title: album.name,
            subtitle: album.artist,
            coverUrl: album.coverUrl,
            songs: response.results,
            color: color,
          ),
        ),
      );
    } catch (_) {}
  }
}
