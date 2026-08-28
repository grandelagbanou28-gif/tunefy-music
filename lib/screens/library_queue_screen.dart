import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:just_audio_background/just_audio_background.dart';
import 'package:muzo/providers/player_provider.dart';
import 'package:muzo/l10n/app_localizations.dart';
import 'package:muzo/widgets/spotify_chips.dart';
import 'package:muzo/widgets/spotify_back_button.dart';

class LibraryQueueScreen extends ConsumerStatefulWidget {
  const LibraryQueueScreen({super.key});

  @override
  ConsumerState<LibraryQueueScreen> createState() => _LibraryQueueScreenState();
}

class _LibraryQueueScreenState extends ConsumerState<LibraryQueueScreen> {
  @override
  Widget build(BuildContext context) {
    final audioHandler = ref.watch(audioHandlerProvider);
    final sequence = audioHandler.player.sequenceState?.sequence ?? [];
    final currentIndex = audioHandler.player.currentIndex ?? 0;

    final upcoming = <MediaItem>[];
    for (var i = currentIndex + 1; i < sequence.length; i++) {
      upcoming.add(sequence[i].tag as MediaItem);
    }

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
                        'Queue',
                        style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: spotifyWhite),
                      ),
                    ),
                    if (upcoming.isNotEmpty)
                      GestureDetector(
                        onTap: () {
                          audioHandler.clearQueue();
                          setState(() {});
                        },
                        child: const Text('Clear', style: TextStyle(color: spotifyWhite, fontSize: 14)),
                      ),
                  ],
                ),
              ),
            ),
            if (upcoming.isEmpty)
              const SliverFillRemaining(
                hasScrollBody: false,
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(FluentIcons.play_24_filled, size: 64, color: spotifyLightGrey),
                      SizedBox(height: 16),
                      Text('Queue is empty', style: TextStyle(color: spotifyLightGrey, fontSize: 16)),
                    ],
                  ),
                ),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                sliver: SliverReorderableList(
                  itemCount: upcoming.length,
                  onReorder: (oldIndex, newIndex) {
                    final queueIndex = currentIndex + 1 + oldIndex;
                    final newQueueIndex = currentIndex + 1 + newIndex;
                    audioHandler.reorderQueue(queueIndex, newQueueIndex);
                    setState(() {});
                  },
                  itemBuilder: (context, index) {
                    final item = upcoming[index];
                    return ReorderableDragStartListener(
                      key: ValueKey(item.id),
                      index: index,
                      child: SpotifySongChip(
                        imageUrl: item.artUri?.toString() ?? '',
                        songTitle: item.title ?? '',
                        singerName: item.artist ?? '',
                        size: 47,
                        videoId: item.id,
                        isDeletable: true,
                        onTap: () {
                          HapticFeedback.lightImpact();
                          audioHandler.seek(Duration.zero, index: currentIndex + 1 + index);
                        },
                        onDelete: () {
                          audioHandler.removeQueueItem(currentIndex + 1 + index);
                          setState(() {});
                        },
                      ),
                    );
                  },
                ),
              ),
            const SliverPadding(padding: EdgeInsets.only(bottom: 130)),
          ],
        ),
      ),
    );
  }
}
