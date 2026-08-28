import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:muzo/services/storage_service.dart';
import 'package:muzo/screens/artist_screen.dart';
import 'package:muzo/utils/page_routes.dart';
import 'package:muzo/l10n/app_localizations.dart';
import 'package:muzo/widgets/spotify_chips.dart';
import 'package:muzo/widgets/spotify_back_button.dart';
import 'package:muzo/widgets/spotify_search_bar.dart';

class LibraryArtistsScreen extends ConsumerStatefulWidget {
  const LibraryArtistsScreen({super.key});

  @override
  ConsumerState<LibraryArtistsScreen> createState() =>
      _LibraryArtistsScreenState();
}

class _LibraryArtistsScreenState extends ConsumerState<LibraryArtistsScreen> {
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
            final entries = _buildArtistEntries(history);
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
                            l10n.artistsFilter,
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
                            FluentIcons.person_24_regular,
                            size: 64,
                            color: spotifyLightGrey,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            l10n.artistsFilter,
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
                          return SpotifyArtistChip(
                            imageUrl: e.imageUrl,
                            name: e.name,
                            radius: 30,
                            onTap: e.id.isNotEmpty
                                ? () {
                                    Navigator.push(
                                      context,
                                      SlidePageRoute(
                                        page: ArtistScreen(
                                          browseId: e.id,
                                          artistName: e.name,
                                          thumbnailUrl: e.imageUrl,
                                        ),
                                      ),
                                    );
                                  }
                                : null,
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

  List<_ArtistEntry> _buildArtistEntries(List<dynamic> history) {
    final entries = <_ArtistEntry>[];
    final processed = <String>{};
    for (final song in history) {
      if (song.artists == null) continue;
      for (final artist in song.artists!) {
        final name = artist.name.trim();
        if (name.isEmpty || name == 'Unknown') continue;
        if (name.contains(',') ||
            name.contains('&') ||
            name.toLowerCase().contains(' feat ') ||
            name.toLowerCase().contains(' ft ')) {
          continue;
        }
        if (processed.contains(name)) continue;
        processed.add(name);
        final img =
            song.thumbnails.isNotEmpty ? song.thumbnails.last.url : '';
        final id =
            (artist.id != null && artist.id!.isNotEmpty) ? artist.id! : '';
        entries.add(_ArtistEntry(name: name, imageUrl: img, id: id));
      }
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

class _ArtistEntry {
  const _ArtistEntry({
    required this.name,
    required this.imageUrl,
    required this.id,
  });
  final String name;
  final String imageUrl;
  final String id;
}
