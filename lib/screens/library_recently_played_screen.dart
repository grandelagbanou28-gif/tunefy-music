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

class LibraryRecentlyPlayedScreen extends ConsumerStatefulWidget {
  const LibraryRecentlyPlayedScreen({super.key});

  @override
  ConsumerState<LibraryRecentlyPlayedScreen> createState() =>
      _LibraryRecentlyPlayedScreenState();
}

class _LibraryRecentlyPlayedScreenState
    extends ConsumerState<LibraryRecentlyPlayedScreen> {
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
          animation: storage.historyListenable,
          builder: (context, _) {
            final history = storage.getHistory();
            final filtered = _searchQuery.isEmpty
                ? history
                : history
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
                            l10n.recentlyPlayed,
                            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: spotifyWhite),
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
                          const Icon(FluentIcons.history_24_regular, size: 64, color: spotifyLightGrey),
                          const SizedBox(height: 16),
                          Text(l10n.recentlyPlayed, style: const TextStyle(color: spotifyLightGrey, fontSize: 16)),
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
                          final img = song.thumbnails.isNotEmpty ? song.thumbnails.last.url : '';
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

  Widget _buildSearchBar(AppLocalizations l10n) {
    return SpotifySearchBar(
      controller: _searchController,
      onChanged: (v) => setState(() => _searchQuery = v),
      hintText: l10n.search,
      height: 40,
    );
  }
}
