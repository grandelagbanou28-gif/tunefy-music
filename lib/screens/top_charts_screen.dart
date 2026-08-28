import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:muzo/providers/category_providers.dart';
import 'package:muzo/providers/player_provider.dart';
import 'package:muzo/services/muzo_api_service.dart';
import 'package:muzo/widgets/spotify_back_button.dart';
import 'package:muzo/widgets/spotify_chips.dart';

/// "Tendances": the top N singles of a category (Top 10 / 50 / 100 tabs).
class TopChartsScreen extends ConsumerStatefulWidget {
  const TopChartsScreen({
    super.key,
    required this.title,
    required this.query,
    required this.color,
  });

  final String title;
  final String query;
  final Color color;

  @override
  ConsumerState<TopChartsScreen> createState() => _TopChartsScreenState();
}

class _TopChartsScreenState extends ConsumerState<TopChartsScreen> {
  int _limit = 10;

  static const _formats = ['10', '50', '100'];

  @override
  Widget build(BuildContext context) {
    final tracksAsync = ref.watch(categoryTracksProvider(widget.query));
    final tracks = tracksAsync.value ?? [];
    final shown = tracks.take(_limit).toList();

    return Scaffold(
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
                      'Top ${widget.title}',
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
            // Tabs Top 10 / 50 / 100
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  for (final f in _formats)
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: GestureDetector(
                        onTap: () {
                          HapticFeedback.lightImpact();
                          setState(() => _limit = int.parse(f));
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: _limit == int.parse(f)
                                ? spotifyWhite
                                : spotifyDarkGrey,
                            borderRadius: BorderRadius.circular(500),
                          ),
                          child: Text(
                            'Top $f',
                            style: TextStyle(
                              color: _limit == int.parse(f)
                                  ? spotifyBlack
                                  : spotifyWhite,
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: tracksAsync.isLoading
                  ? const Center(
                      child: CircularProgressIndicator(color: Color(0xFF1DDA63)),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 130),
                      itemCount: shown.length,
                      itemBuilder: (context, index) {
                        final track = shown[index];
                        return _row(context, index, track);
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _row(BuildContext context, int rank, CategoryTrack track) {
    return GestureDetector(
      onTap: () => _play(context, track),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          children: [
            SizedBox(
              width: 32,
              child: Text(
                '${rank + 1}',
                style: const TextStyle(
                  color: spotifyLightGrey,
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            _cover(track.coverUrl, 52),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    track.name,
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
                    track.artist,
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
            const SizedBox(width: 8),
            Text(
              _fmt(track.duration),
              style: const TextStyle(color: spotifyLightGrey, fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }

  Widget _cover(String url, double size) {
    if (url.isEmpty) {
      return Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: spotifyDarkGrey,
          borderRadius: BorderRadius.circular(6),
        ),
        child: const Icon(Icons.music_note, color: spotifyWhite, size: 22),
      );
    }
    return ClipRRect(
      borderRadius: BorderRadius.circular(6),
      child: CachedNetworkImage(
        imageUrl: url,
        width: size,
        height: size,
        fit: BoxFit.cover,
        errorWidget: (_, __, ___) => Container(
          color: spotifyDarkGrey,
          child: const Icon(Icons.music_note, color: spotifyWhite, size: 22),
        ),
      ),
    );
  }

  String _fmt(Duration d) {
    final m = d.inMinutes.remainder(60);
    final s = d.inSeconds.remainder(60);
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  Future<void> _play(BuildContext context, CategoryTrack track) async {
    HapticFeedback.lightImpact();
    try {
      final api = ref.read(muzoApiServiceProvider);
      final response = await api
          .search('${track.name} ${track.artist}', filter: 'songs')
          .timeout(const Duration(seconds: 10));
      if (response.results.isEmpty || !context.mounted) return;
      ref.read(audioHandlerProvider).playAll(response.results);
    } catch (_) {}
  }
}
