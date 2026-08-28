import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:muzo/models/muzo_item.dart';
import 'package:muzo/services/storage_service.dart';
import 'package:muzo/providers/player_provider.dart';
import 'package:muzo/l10n/app_localizations.dart';
import 'package:muzo/widgets/spotify_chips.dart';
import 'package:muzo/widgets/spotify_back_button.dart';
import 'package:muzo/widgets/spotify_search_bar.dart';
import 'package:muzo/widgets/app_alert_dialog.dart';

class LibraryDownloadsScreen extends ConsumerStatefulWidget {
  const LibraryDownloadsScreen({super.key});

  @override
  ConsumerState<LibraryDownloadsScreen> createState() =>
      _LibraryDownloadsScreenState();
}

class _LibraryDownloadsScreenState extends ConsumerState<LibraryDownloadsScreen> {
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
          animation: storage.downloadsListenable,
          builder: (context, _) {
            final downloads = storage.getDownloads();
            final filtered = _searchQuery.isEmpty
                ? downloads
                : downloads.where((d) {
                    final result = d['result'];
                    if (result == null) return false;
                    final title = result['title']?.toString() ?? '';
                    return title.toLowerCase().contains(_searchQuery.toLowerCase());
                  }).toList();

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
                            'Downloads',
                            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: spotifyWhite),
                          ),
                        ),
                        if (downloads.isNotEmpty)
                          GestureDetector(
                            onTap: () => _showClearAllDialog(context, storage, l10n),
                            child: const Icon(FluentIcons.delete_24_regular, color: spotifyLightGrey, size: 20),
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
                          const Icon(FluentIcons.arrow_download_24_regular, size: 64, color: spotifyLightGrey),
                          const SizedBox(height: 16),
                          Text(
                            'No downloads yet',
                            style: const TextStyle(color: spotifyLightGrey, fontSize: 16),
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
                          final d = filtered[index];
                          final result = d['result'];
                          if (result == null) return const SizedBox.shrink();
                          final song = MuzoItem.fromJson(Map<String, dynamic>.from(result));
                          final img = song.thumbnails.isNotEmpty ? song.thumbnails.last.url : '';
                          return SpotifySongChip(
                            imageUrl: img,
                            songTitle: song.title,
                            singerName: song.displayArtist,
                            size: 47,
                            videoId: song.videoId,
                            isDeletable: true,
                            onTap: () {
                              HapticFeedback.lightImpact();
                              ref.read(audioHandlerProvider).playVideo(song);
                            },
                            onDelete: () => _removeDownload(context, storage, d['videoId'], l10n),
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

  void _removeDownload(BuildContext context, StorageService storage, String videoId, AppLocalizations l10n) {
    storage.removeDownload(videoId);
  }

  void _showClearAllDialog(BuildContext context, StorageService storage, AppLocalizations l10n) {
    showAppAlertDialog(
      context: context,
      title: 'Clear All Downloads',
      content: const Text('Remove all downloaded files?', style: TextStyle(color: spotifyWhite)),
      actions: [
        TextButton(
          onPressed: () { if (context.mounted && Navigator.canPop(context)) Navigator.pop(context); },
          child: Text(l10n.cancel, style: const TextStyle(color: spotifyWhite)),
        ),
        TextButton(
          onPressed: () {
            storage.clearDownloads();
            if (context.mounted && Navigator.canPop(context)) Navigator.pop(context);
          },
          child: Text('Delete All', style: TextStyle(color: Theme.of(context).colorScheme.error, fontWeight: FontWeight.bold)),
        ),
      ],
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
