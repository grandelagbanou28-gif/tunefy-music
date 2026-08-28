import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:muzo/services/storage_service.dart';
import 'package:muzo/services/muzo_api_service.dart';
import 'package:muzo/providers/player_provider.dart';
import 'package:muzo/models/muzo_item.dart';
import 'package:muzo/l10n/app_localizations.dart';
import 'package:muzo/widgets/spotify_chips.dart';
import 'package:muzo/widgets/spotify_back_button.dart';
import 'package:muzo/widgets/spotify_search_bar.dart';

class LibraryEpisodesScreen extends ConsumerStatefulWidget {
  const LibraryEpisodesScreen({super.key});

  @override
  ConsumerState<LibraryEpisodesScreen> createState() =>
      _LibraryEpisodesScreenState();
}

class _LibraryEpisodesScreenState extends ConsumerState<LibraryEpisodesScreen> {
  String _searchQuery = '';
  final _searchController = TextEditingController();
  late final _apiService = ref.read(muzoApiServiceProvider);

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final storage = ref.watch(storageServiceProvider);
    final l10n = AppLocalizations.of(context);
    final subscriptions = storage.getSubscriptions();
    final channelIds = subscriptions
        .where((c) => c.channelId != null)
        .map((c) => c.channelId!)
        .toList();

    return Scaffold(
      backgroundColor: spotifyBlack,
      body: SafeArea(
        bottom: false,
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 20, 16, 12),
                child: Row(
                  children: [
                    const SpotifyBackButton(),
                    const SizedBox(width: 16),
                    const Expanded(
                      child: Text(
                        'Your Episodes',
                        style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: spotifyWhite),
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
            if (channelIds.isEmpty)
              const SliverFillRemaining(
                hasScrollBody: false,
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(FluentIcons.headphones_24_regular, size: 64, color: spotifyLightGrey),
                      SizedBox(height: 16),
                      Text(
                        'Follow channels to see their latest videos here.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: spotifyLightGrey, fontSize: 14),
                      ),
                    ],
                  ),
                ),
              )
            else
              FutureBuilder<List<MuzoItem>>(
                future: _apiService.getSubscriptionsFeed(channelIds),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const SliverFillRemaining(
                      hasScrollBody: false,
                      child: Center(child: CircularProgressIndicator(color: Color(0xFF1DDA63))),
                    );
                  }
                  final episodes = snapshot.data ?? [];
                  final filtered = _searchQuery.isEmpty
                      ? episodes
                      : episodes
                          .where((e) => e.title.toLowerCase().contains(_searchQuery.toLowerCase()))
                          .toList();

                  if (filtered.isEmpty) {
                    return const SliverFillRemaining(
                      hasScrollBody: false,
                      child: Center(
                        child: Text('No episodes found', style: TextStyle(color: spotifyLightGrey)),
                      ),
                    );
                  }

                  return SliverPadding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          final episode = filtered[index];
                          final img = episode.thumbnails.isNotEmpty ? episode.thumbnails.last.url : '';
                          return SpotifySongChip(
                            imageUrl: img,
                            songTitle: episode.title,
                            singerName: episode.displayArtist,
                            size: 47,
                            videoId: episode.videoId,
                            onTap: () {
                              HapticFeedback.lightImpact();
                              ref.read(audioHandlerProvider).playVideo(episode);
                            },
                          );
                        },
                        childCount: filtered.length,
                      ),
                    ),
                  );
                },
              ),
            const SliverPadding(padding: EdgeInsets.only(bottom: 130)),
          ],
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
