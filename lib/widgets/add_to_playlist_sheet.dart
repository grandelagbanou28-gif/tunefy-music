import 'package:flutter/material.dart';
import 'package:tunefy/constants/constants.dart';
import 'package:tunefy/models/track.dart';
import 'package:tunefy/services/liked_service.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:tunefy/services/haptic_service.dart';

class AddToPlaylistSheet extends StatelessWidget {
  final Track track;

  const AddToPlaylistSheet({super.key, required this.track});

  static void show(BuildContext context, Track track) {
    showModalBottomSheet(
      context: context,
      backgroundColor: MyColors.darkGreyColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
      ),
      builder: (_) => AddToPlaylistSheet(track: track),
    );
  }

  @override
  Widget build(BuildContext context) {
    final likedService = LikedService();
    final isLiked = likedService.isLiked(track.videoId);

    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            margin: const EdgeInsets.only(top: 10),
            width: 36,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.white30,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: SizedBox(
                    width: 44,
                    height: 44,
                    child: track.albumImage != null && track.albumImage!.isNotEmpty
                        ? CachedNetworkImage(imageUrl: track.albumImage!, fit: BoxFit.cover,
                            errorWidget: (_, __, ___) => const Icon(Icons.music_note, color: Colors.white54, size: 22))
                        : const Icon(Icons.music_note, color: Colors.white54, size: 22),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        track.title,
                        style: const TextStyle(fontFamily: "AM", fontSize: 14, color: Colors.white),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                      Text(
                        track.artist,
                        style: const TextStyle(fontFamily: "AM", fontSize: 12, color: Colors.white54),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const Divider(color: Colors.white12, height: 1),
          _Tile(
            icon: isLiked ? Icons.favorite : Icons.favorite_border,
            iconColor: isLiked ? MyColors.greenColor : Colors.white,
            label: 'Liked Songs',
            onTap: () async {
              HapticService.tap();
              await likedService.toggle(track);
              if (context.mounted) Navigator.pop(context);
            },
          ),
          const _Tile(
            icon: Icons.playlist_add,
            label: 'Add to playlist',
            onTap: null,
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

class _Tile extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback? onTap;
  final Color? iconColor;

  const _Tile({required this.icon, required this.label, this.onTap, this.iconColor});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: iconColor ?? Colors.white, size: 24),
      title: Text(label, style: const TextStyle(fontFamily: "AM", fontSize: 14, color: Colors.white)),
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16),
    );
  }
}
