import 'package:audio_service/audio_service.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:just_audio/just_audio.dart';
import 'package:palette_generator/palette_generator.dart';

import 'package:muzo/providers/player_provider.dart';
import 'package:muzo/models/muzo_item.dart';
import 'package:muzo/screens/player_screen.dart';
import 'package:muzo/services/navigator_key.dart';
import 'package:muzo/services/storage_service.dart';
import 'package:muzo/utils/app_colors.dart';

final playerColourProvider = StateProvider<Color>((ref) => Colors.black);

class HivefyMiniPlayer extends ConsumerStatefulWidget {
  const HivefyMiniPlayer({super.key});

  @override
  ConsumerState<HivefyMiniPlayer> createState() => _HivefyMiniPlayerState();
}

class _HivefyMiniPlayerState extends ConsumerState<HivefyMiniPlayer> {
  @override
  void initState() {
    super.initState();
    _updatePlayerCardColour();
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) _updatePlayerCardColour();
    });
  }

  Future<void> _updatePlayerCardColour() async {
    final mediaItem = ref.read(currentMediaItemProvider).valueOrNull;
    final url = mediaItem?.artUri?.toString() ?? '';
    if (url.isEmpty) return;
    try {
      final pi = await PaletteGenerator.fromImageProvider(
        CachedNetworkImageProvider(url),
      );
      if (!mounted) return;
      final c = pi.dominantColor?.color ?? Colors.black;
      final hsl = HSLColor.fromColor(c);
      ref.read(playerColourProvider.notifier).state =
          hsl.withLightness((hsl.lightness * 0.35).clamp(0.0, 1.0)).toColor();
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final audioHandler = ref.watch(audioHandlerProvider);
    final mediaItemAsync = ref.watch(currentMediaItemProvider);

    ref.listen<AsyncValue<MediaItem?>>(currentMediaItemProvider, (prev, next) {
      final item = next.valueOrNull;
      if (item != null && item != prev?.valueOrNull) {
        _updatePlayerCardColour();
      }
    });

    return mediaItemAsync.maybeWhen(
      data: (mediaItem) {
        if (mediaItem == null) return const SizedBox.shrink();
        final id = mediaItem.id;
        final storage = ref.read(storageServiceProvider);

        return GestureDetector(
          onHorizontalDragEnd: (details) async {
            final v = details.primaryVelocity ?? 0;
            if (v > 300) {
              await audioHandler.skipToPrevious();
            } else if (v < -300) {
              await audioHandler.skipToNext();
            }
          },
          onTap: () async {
            HapticFeedback.lightImpact();
            showModalBottomSheet(
              context: context,
              useRootNavigator: true,
              isScrollControlled: true,
              isDismissible: true,
              enableDrag: true,
              backgroundColor: Colors.transparent,
              barrierColor: Colors.black12,
              builder: (ctx) {
                return SizedBox(
                  width: MediaQuery.of(context).size.width,
                  height: MediaQuery.of(context).size.height,
                  child: Stack(
                    children: [
                      Container(color: AppColors.cardTranslucent),
                      Align(
                        alignment: Alignment.bottomCenter,
                        child: ClipRRect(
                          borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(24),
                          ),
                          child: SizedBox(
                            width: double.infinity,
                            height: double.infinity,
                            child: const ExpandedPlayer(),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            );
          },
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 8),
            padding: const EdgeInsets.only(top: 3),
            decoration: BoxDecoration(
              color: ref.watch(playerColourProvider),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(6),
                        child: CachedNetworkImage(
                          imageUrl: mediaItem.artUri?.toString() ?? '',
                          width: 40,
                          height: 40,
                          fit: BoxFit.cover,
                          errorWidget: (_, __, ___) => Container(
                            width: 40,
                            height: 40,
                            color: Colors.grey[800],
                            child: const Icon(Icons.music_note, color: Colors.white70, size: 20),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              mediaItem.title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                letterSpacing: -0.5,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              mediaItem.artist ?? '',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 12,
                                fontWeight: FontWeight.w400,
                              ),
                            ),
                          ],
                        ),
                      ),
                      GestureDetector(
                        behavior: HitTestBehavior.translucent,
                        onTap: () {
                          HapticFeedback.lightImpact();
                          storage.toggleFavorite(MuzoItem(
                            videoId: id,
                            title: mediaItem.title,
                            resultType: 'video',
                            isExplicit: false,
                            artists: [MuzoArtist(name: mediaItem.artist ?? '', id: null)],
                            thumbnails: mediaItem.artUri != null
                                ? [MuzoThumbnail(url: mediaItem.artUri.toString(), width: 0, height: 0)]
                                : [],
                          ));
                        },
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: ValueListenableBuilder<List<MuzoItem>>(
                            valueListenable: storage.favoritesListenable,
                            builder: (context, _, __) {
                              final liked = storage.isFavorite(id);
                              return Image.asset(
                                liked
                                    ? 'assets/icons/tick.png'
                                    : 'assets/icons/add.png',
                                width: 32,
                                height: 32,
                                color: liked
                                    ? const Color(0xFF1DDA63)
                                    : Colors.white70,
                              );
                            },
                          ),
                        ),
                      ),
                      const SizedBox(width: 3),
                      SizedBox(
                        width: 32,
                        height: 32,
                        child: Center(
                          child: StreamBuilder<PlayerState>(
                            stream: audioHandler.player.playerStateStream,
                            builder: (context, snapshot) {
                              final state = snapshot.data;
                              final playing = state?.playing ?? false;
                              final isLoading = state?.processingState == ProcessingState.loading ||
                                  state?.processingState == ProcessingState.buffering;

                              if (isLoading) {
                                return const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Color(0xFF1DB954),
                                  ),
                                );
                              }

                              return IconButton(
                                padding: EdgeInsets.zero,
                                icon: Icon(
                                  playing ? Icons.pause_outlined : Icons.play_arrow,
                                  color: Colors.white,
                                  size: 28,
                                ),
                                onPressed: () {
                                  playing ? audioHandler.pause() : audioHandler.resume();
                                },
                              );
                            },
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 3),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: StreamBuilder<Duration>(
                    stream: audioHandler.player.positionStream,
                    builder: (context, snapshot) {
                      final pos = snapshot.data ?? Duration.zero;
                      final total = audioHandler.player.duration ?? Duration.zero;
                      final progress = total.inMilliseconds > 0
                          ? pos.inMilliseconds / total.inMilliseconds
                          : 0.0;
                      return ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: progress.clamp(0.0, 1.0),
                          backgroundColor: Colors.white.withAlpha(51),
                          valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                          minHeight: 2,
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
      orElse: () => const SizedBox.shrink(),
    );
  }
}
