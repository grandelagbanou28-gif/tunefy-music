import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:muzo/models/muzo_item.dart';
import 'package:muzo/providers/player_provider.dart';
import 'package:muzo/services/storage_service.dart';
import 'package:muzo/l10n/app_localizations.dart';
import 'package:muzo/widgets/spotify_chips.dart';
import 'package:muzo/widgets/spotify_back_button.dart';
import 'package:muzo/widgets/spotify_search_bar.dart';

class LibrarySongsScreen extends ConsumerStatefulWidget {
  const LibrarySongsScreen({super.key});

  @override
  ConsumerState<LibrarySongsScreen> createState() =>
      _LibrarySongsScreenState();
}

class _LibrarySongsScreenState extends ConsumerState<LibrarySongsScreen> {
  String _searchQuery = '';
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<MuzoItem> _buildSongs(StorageService storage) {
    final seen = <String>{};
    final songs = <MuzoItem>[];
    void addSong(dynamic s) {
      final videoId = s.videoId?.toString() ?? '';
      if (videoId.isEmpty) return;
      if (seen.contains(videoId)) return;
      seen.add(videoId);
      songs.add(s as MuzoItem);
    }

    for (final s in storage.getFavorites()) {
      addSong(s);
    }
    for (final s in storage.getHistory()) {
      addSong(s);
    }
    return songs;
  }

  @override
  Widget build(BuildContext context) {
    final storage = ref.watch(storageServiceProvider);
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      backgroundColor: spotifyBlack,
      body: SafeArea(
        bottom: false,
        child: AnimatedBuilder(
          animation: Listenable.merge([
            storage.favoritesListenable,
            storage.historyListenable,
          ]),
          builder: (context, _) {
            final all = _buildSongs(storage);
            final filtered = _searchQuery.isEmpty
                ? all
                : all
                    .where((s) =>
                        s.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
                        s.displayArtist.toLowerCase().contains(_searchQuery.toLowerCase()))
                    .toList();

            return CustomScrollView(
              slivers: [
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 20, 16, 12),
                    child: Row(
                      children: [
                        const SpotifyBackButton(),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Text(
                            'Songs',
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w800,
                              color: spotifyWhite,
                            ),
                          ),
                        ),
                        if (all.isNotEmpty)
                          Text(
                            '${all.length}',
                            style: const TextStyle(
                              color: spotifyLightGrey,
                              fontSize: 14,
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: SpotifySearchBar(
                      controller: _searchController,
                      onChanged: (v) => setState(() => _searchQuery = v),
                      hintText: l10n.search,
                      height: 40,
                    ),
                  ),
                ),
                if (filtered.isEmpty)
                  SliverFillRemaining(
                    hasScrollBody: false,
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            FluentIcons.music_note_2_24_regular,
                            size: 64,
                            color: spotifyLightGrey,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'No songs yet',
                            style: const TextStyle(
                              color: spotifyLightGrey,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                else
                  SliverPadding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          final song = filtered[index];
                          final img = song.thumbnails.isNotEmpty
                              ? song.thumbnails.last.url
                              : '';
                          return SpotifySongChip(
                            imageUrl: img,
                            songTitle: song.title,
                            singerName: song.displayArtist,
                            size: 47,
                            videoId: song.videoId,
                            onTap: () {
                              HapticFeedback.lightImpact();
                              ref.read(audioHandlerProvider).playVideo(song);
                            },
                          );
                        },
                        childCount: filtered.length,
                      ),
                    ),
                  ),
                const SliverPadding(padding: EdgeInsets.only(bottom: 130)),
              ],
            );
          },
        ),
      ),
    );
  }
}
