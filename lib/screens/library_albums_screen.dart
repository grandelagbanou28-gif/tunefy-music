import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:muzo/services/storage_service.dart';
import 'package:muzo/providers/player_provider.dart';
import 'package:muzo/l10n/app_localizations.dart';
import 'package:muzo/widgets/spotify_chips.dart';
import 'package:muzo/widgets/spotify_back_button.dart';
import 'package:muzo/widgets/spotify_search_bar.dart';

class LibraryAlbumsScreen extends ConsumerStatefulWidget {
  const LibraryAlbumsScreen({super.key});

  @override
  ConsumerState<LibraryAlbumsScreen> createState() =>
      _LibraryAlbumsScreenState();
}

class _LibraryAlbumsScreenState extends ConsumerState<LibraryAlbumsScreen> {
  String _searchQuery = '';
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
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
            storage.historyListenable,
          ]),
          builder: (context, _) {
            final history = storage.getHistory();
            final entries = _buildAlbumEntries(history, l10n);
            final filtered = _searchQuery.isEmpty
                ? entries
                : entries
                    .where((e) => e.name
                        .toLowerCase()
                        .contains(_searchQuery.toLowerCase()))
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
                            l10n.albumsFilter,
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w800,
                              color: spotifyWhite,
                            ),
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
                    child: _buildSearchBar(l10n),
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
                            l10n.albumsFilter,
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
                          final e = filtered[index];
                          return SpotifyAlbumChip(
                            imageUrl: e.imageUrl,
                            albumName: e.name,
                            artistName: e.artist,
                            size: 56,
                            onTap: () {
                              HapticFeedback.lightImpact();
                              if (e.firstSong != null) {
                                ref
                                    .read(audioHandlerProvider)
                                    .playVideo(e.firstSong!);
                              }
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

  List<_AlbumEntry> _buildAlbumEntries(List<dynamic> history, AppLocalizations l10n) {
    final entries = <_AlbumEntry>[];
    final seen = <String>{};
    for (final song in history) {
      final albumName = song.album?.name.trim() ?? '';
      if (albumName.isEmpty || albumName == 'Unknown') continue;
      if (seen.contains(albumName)) continue;
      seen.add(albumName);
      final img =
          song.thumbnails.isNotEmpty ? song.thumbnails.last.url : '';
      entries.add(_AlbumEntry(
        name: albumName,
        imageUrl: img,
        artist: l10n.albumDotArtist(song.displayArtist),
        firstSong: song,
      ));
    }
    return entries;
  }

  Widget _buildSearchBar(AppLocalizations l10n) {
    return SpotifySearchBar(
      controller: _searchController,
      onChanged: (v) => setState(() => _searchQuery = v),
      hintText: l10n.search,
      height: 40,
    );
  }
}

class _AlbumEntry {
  const _AlbumEntry({
    required this.name,
    required this.imageUrl,
    required this.artist,
    this.firstSong,
  });
  final String name;
  final String imageUrl;
  final String artist;
  final dynamic firstSong;
}
