import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:muzo/services/storage_service.dart';
import 'package:muzo/screens/playlist_details_screen.dart';
import 'package:muzo/utils/page_routes.dart';
import 'package:muzo/l10n/app_localizations.dart';
import 'package:muzo/widgets/spotify_chips.dart';
import 'package:muzo/widgets/spotify_back_button.dart';
import 'package:muzo/widgets/spotify_search_bar.dart';

class LibraryPlaylistsScreen extends ConsumerStatefulWidget {
  const LibraryPlaylistsScreen({super.key});

  @override
  ConsumerState<LibraryPlaylistsScreen> createState() =>
      _LibraryPlaylistsScreenState();
}

class _LibraryPlaylistsScreenState
    extends ConsumerState<LibraryPlaylistsScreen> {
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
          animation: storage.playlistsListenable,
          builder: (context, _) {
            final allNames = storage.getPlaylistNames();
            final filtered = _searchQuery.isEmpty
                ? allNames
                : allNames
                    .where((n) =>
                        n.toLowerCase().contains(_searchQuery.toLowerCase()))
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
                            l10n.playlistsFilter,
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w800,
                              color: spotifyWhite,
                            ),
                          ),
                        ),
                        GestureDetector(
                          onTap: () => _showCreatePlaylistDialog(context, storage),
                          child: const Icon(
                            FluentIcons.add_24_regular,
                            color: spotifyWhite,
                            size: 24,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
                          Icon(
                            FluentIcons.music_note_2_24_regular,
                            size: 64,
                            color: spotifyLightGrey,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            l10n.yourLibrary,
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
                          final name = filtered[index];
                          final songs = storage.getPlaylistSongs(name);
                          final img = songs.isNotEmpty &&
                                  songs.first.thumbnails.isNotEmpty
                              ? songs.first.thumbnails.last.url
                              : '';
                          return SpotifyAlbumChip(
                            imageUrl: img,
                            albumName: name,
                            artistName:
                                l10n.playlistCount(songs.length),
                            size: 56,
                            onTap: () {
                              Navigator.push(
                                context,
                                SlidePageRoute(
                                  page: PlaylistDetailsScreen(
                                      playlistName: name),
                                ),
                              );
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

  Widget _buildSearchBar(AppLocalizations l10n) {
    return SpotifySearchBar(
      controller: _searchController,
      onChanged: (v) => setState(() => _searchQuery = v),
      hintText: l10n.search,
      height: 40,
    );
  }

  Future<void> _showCreatePlaylistDialog(
      BuildContext context, StorageService storage) async {
    final l10n = AppLocalizations.of(context);
    final controller = TextEditingController();
    final name = await showDialog<String>(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: const Color(0xFF282828),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        insetPadding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n.createPlaylist,
                style: const TextStyle(
                  color: spotifyWhite,
                  fontSize: 19,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: controller,
                autofocus: true,
                style: const TextStyle(color: spotifyWhite, fontSize: 15),
                cursorColor: spotifyWhite,
                decoration: InputDecoration(
                  hintText: l10n.playlistNameHint,
                  hintStyle: const TextStyle(color: spotifyLightGrey),
                  filled: true,
                  fillColor: const Color(0xFF3E3E3E),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 12,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide.none,
                  ),
                ),
                onSubmitted: (value) {
                  final n = value.trim();
                  if (n.isNotEmpty) Navigator.pop(ctx, n);
                },
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(ctx),
                    child: const Text(
                      'Cancel',
                      style: TextStyle(color: spotifyWhite, fontSize: 15),
                    ),
                  ),
                  const SizedBox(width: 4),
                  TextButton(
                    onPressed: () {
                      final n = controller.text.trim();
                      if (n.isNotEmpty) Navigator.pop(ctx, n);
                    },
                    child: Text(
                      l10n.createBtn,
                      style: const TextStyle(
                        color: Color(0xFF1DDA63),
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
    if (name == null || name.isEmpty) return;
    storage.createPlaylist(name);
  }
}
