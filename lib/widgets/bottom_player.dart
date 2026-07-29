import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:tunefy/constants/constants.dart';
import 'package:tunefy/DI/service_locator.dart';
import 'package:tunefy/models/track.dart';
import 'package:tunefy/services/liked_service.dart';
import 'package:tunefy/ui/track_view_screen.dart';
import 'package:tunefy/widgets/add_to_playlist_sheet.dart';
import 'package:tunefy/widgets/device_sheet.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:tunefy/services/haptic_service.dart';

class BottomPlayer extends StatefulWidget {
  const BottomPlayer({super.key});

  @override
  State<BottomPlayer> createState() => _BottomPlayerState();
}

class _BottomPlayerState extends State<BottomPlayer> {
  final LikedService _likedService = LikedService();

  PlayerProvider get _player => playerProvider;

  @override
  void initState() {
    super.initState();
    _player.addListener(_onUpdate);
  }

  void _onUpdate() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _player.removeListener(_onUpdate);
    super.dispose();
  }

  Widget _buildCover(Track? track) {
    final img = track?.albumImage;
    if (img == null || img.isEmpty) {
      return const Icon(Icons.music_note, color: MyColors.lightGrey, size: 20);
    }
    return CachedNetworkImage(
      imageUrl: img,
      fit: BoxFit.cover,
      width: 42,
      height: 42,
      errorWidget: (_, __, ___) => const Icon(Icons.music_note, color: MyColors.lightGrey, size: 20),
    );
  }

  void _onPlusTap(Track track) {
    final isLiked = _likedService.isLiked(track.videoId);
    if (isLiked) {
      AddToPlaylistSheet.show(context, track);
    } else {
      _likedService.toggle(track);
    }
  }

  @override
  Widget build(BuildContext context) {
    final track = _player.currentTrack;
    if (track == null) return const SizedBox.shrink();

    final position = _player.position;
    final duration = _player.duration;
    final progress = duration.inMilliseconds > 0 ? position.inMilliseconds / duration.inMilliseconds : 0.0;
    final isLiked = _likedService.isLiked(track.videoId);

    return GestureDetector(
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const TrackViewScreen())),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 8),
        decoration: BoxDecoration(
          color: MyColors.darkGreyColor,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: SizedBox(
                    width: 42,
                    height: 42,
                    child: _buildCover(track),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        track.title,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontFamily: "AM",
                          color: Colors.white,
                          fontSize: 13,
                        ),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        track.artist,
                        style: const TextStyle(
                          fontFamily: "AM",
                          fontSize: 11,
                          color: Colors.white70,
                        ),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                    ],
                  ),
                ),
                GestureDetector(
                  onTap: () => _onPlusTap(track),
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 200),
                    child: isLiked
                        ? const Icon(Icons.check_circle, key: ValueKey('check'), color: MyColors.greenColor, size: 22)
                        : const Icon(Icons.add_circle_outline, key: ValueKey('plus'), color: Colors.white, size: 22),
                  ),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: () => DeviceSheet.show(context),
                  child: const Icon(Icons.speaker, color: Colors.white, size: 20),
                ),
                const SizedBox(width: 8),
                SizedBox(
                  width: 32,
                  height: 32,
                  child: StreamBuilder<PlayerState>(
                    stream: _player.player.playerStateStream,
                    builder: (context, snapshot) {
                      final state = snapshot.data;
                      final playing = state?.playing ?? false;
                      return IconButton(
                        padding: EdgeInsets.zero,
                        icon: Icon(
                          playing ? Icons.pause_rounded : Icons.play_arrow_rounded,
                          color: Colors.white,
                          size: 30,
                        ),
                        onPressed: _player.togglePlay,
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: progress.clamp(0.0, 1.0),
                backgroundColor: Colors.white24,
                valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                minHeight: 2,
              ),
            ),
          ),
          const SizedBox(height: 4),
        ],
      ),
    ),
    );
  }
}
