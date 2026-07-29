import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:tunefy/models/home_track.dart';
import 'package:tunefy/models/track.dart';
import 'package:tunefy/helpers/tunefy_helpers.dart';
import 'package:tunefy/theme/tunefy_colors.dart';

class LikedTracksPage extends StatelessWidget {
  final List<Track> tracks;
  const LikedTracksPage({super.key, required this.tracks});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: TunefyColors.black,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () { haptic(); Navigator.pop(context); },
                    child: const Icon(Icons.arrow_back, color: TunefyColors.white, size: 24),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text('Titres likés', style: TextStyle(
                      fontFamily: 'AB', fontSize: 20, color: TunefyColors.white, fontWeight: FontWeight.w700,
                    )),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text('${tracks.length} titres', style: const TextStyle(
                fontFamily: 'AM', fontSize: 13, color: TunefyColors.grey,
              )),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: tracks.isEmpty
                  ? const Center(child: Text('Aucun titre liké', style: TextStyle(fontFamily: 'AM', fontSize: 15, color: TunefyColors.grey)))
                  : ListView.builder(
                      padding: const EdgeInsets.only(bottom: 80),
                      itemCount: tracks.length,
                      itemBuilder: (ctx, i) {
                        final t = tracks[i];
                        final homeTrack = HomeTrack(
                          videoId: t.videoId ?? '',
                          title: t.title,
                          artist: t.artist,
                          duration: t.duration != null ? '${t.duration!.inMinutes}:${(t.duration!.inSeconds % 60).toString().padLeft(2, '0')}' : '0:00',
                          imageUrl: t.albumImage,
                        );
                        return ListTile(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                          leading: ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: t.albumImage != null
                                ? CachedNetworkImage(imageUrl: t.albumImage!, width: 48, height: 48, fit: BoxFit.cover,
                                    errorWidget: (_, __, ___) => Container(width: 48, height: 48, color: TunefyColors.darkCard,
                                        child: const Icon(Icons.music_note, color: TunefyColors.grey, size: 20)))
                                : Container(width: 48, height: 48, color: TunefyColors.darkCard,
                                    child: const Icon(Icons.music_note, color: TunefyColors.grey, size: 20)),
                          ),
                          title: Text(t.title, style: const TextStyle(fontFamily: 'AB', fontSize: 15, color: TunefyColors.white),
                            maxLines: 1, overflow: TextOverflow.ellipsis),
                          subtitle: Text(t.artist, style: const TextStyle(fontFamily: 'AM', fontSize: 13, color: TunefyColors.grey),
                            maxLines: 1, overflow: TextOverflow.ellipsis),
                          onTap: () {
                            haptic();
                            selectTrack(homeTrack);
                            Navigator.pop(context);
                          },
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
