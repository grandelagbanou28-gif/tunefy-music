import 'package:flutter/material.dart';
import 'package:tunefy/constants/constants.dart';
import 'package:tunefy/models/home_track.dart';
import 'package:tunefy/ui/collection_detail_page.dart';
import 'package:tunefy/ui/track_detail_screen.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:tunefy/services/haptic_service.dart';

class HomeTrackCard extends StatelessWidget {
  final HomeTrack track;
  final int index;

  const HomeTrackCard({super.key, required this.track, this.index = 0});

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    return GestureDetector(
      onTap: () {
        HapticService.tap();
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => TrackDetailScreen(
              title: track.title,
              artist: track.artist,
              imageUrl: track.imageUrl ?? 'https://i.ytimg.com/vi/${track.videoId}/hqdefault.jpg',
              videoId: track.videoId,
            ),
          ),
        );
      },
      child: Padding(
        padding: EdgeInsets.only(right: w * 0.03),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
                Stack(
                  children: [
                    Container(
                      width: w * 0.38,
                      height: w * 0.38,
                      decoration: BoxDecoration(
                        color: MyColors.darkGreyColor,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(6),
                        child: CachedNetworkImage(
                          imageUrl: track.imageUrl ?? 'https://i.ytimg.com/vi/${track.videoId}/hqdefault.jpg',
                          fit: BoxFit.cover,
                          placeholder: (context, url) => const Center(
                            child: CircularProgressIndicator(color: MyColors.greenColor, strokeWidth: 2),
                          ),
                          errorWidget: (_, __, ___) => Container(
                            decoration: const BoxDecoration(
                              gradient: LinearGradient(
                                colors: [MyColors.darkGreyColor, Color(0xff1a1a1a)],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                            ),
                            child: Image.asset('images/icon_home.png', width: 40, height: 40),
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      top: 4,
                      left: 4,
                      child: Image.asset('images/hivefy_logo.png', width: 18, height: 18),
                    ),
                  ],
                ),
            SizedBox(height: w * 0.02),
            SizedBox(
              width: w * 0.38,
              child: Text(
                track.title,
                style: const TextStyle(
                  fontFamily: "AB",
                  fontSize: 12,
                  color: MyColors.whiteColor,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            SizedBox(
              width: w * 0.38,
              child: Text(
                '${track.artist} • ${track.duration}',
                style: const TextStyle(
                  fontFamily: "AM",
                  fontSize: 11,
                  color: MyColors.lightGrey,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class HomeTrackListTile extends StatelessWidget {
  final HomeTrack track;
  final int index;

  const HomeTrackListTile({super.key, required this.track, this.index = 0});

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    return GestureDetector(
      onTap: () {
        HapticService.tap();
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => TrackDetailScreen(
              title: track.title,
              artist: track.artist,
              imageUrl: track.imageUrl ?? 'https://i.ytimg.com/vi/${track.videoId}/hqdefault.jpg',
              videoId: track.videoId,
            ),
          ),
        );
      },
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: w * 0.04, vertical: w * 0.02),
        child: Row(
          children: [
            Stack(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: CachedNetworkImage(
                    imageUrl: track.imageUrl ?? 'https://i.ytimg.com/vi/${track.videoId}/hqdefault.jpg',
                    width: 48,
                    height: 48,
                    fit: BoxFit.cover,
                    placeholder: (context, url) => Container(
                      width: 48,
                      height: 48,
                      color: MyColors.darkGreyColor,
                      child: const Center(
                        child: SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(color: MyColors.greenColor, strokeWidth: 2),
                        ),
                      ),
                    ),
                    errorWidget: (_, __, ___) => Container(
                      width: 48,
                      height: 48,
                      color: MyColors.darkGreyColor,
                      child: const Icon(Icons.music_note, color: MyColors.lightGrey),
                    ),
                  ),
                ),
                Positioned(
                  top: 2,
                  left: 2,
                  child: Image.asset('images/hivefy_logo.png', width: 12, height: 12),
                ),
              ],
            ),
            SizedBox(width: w * 0.03),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    track.title,
                    style: const TextStyle(
                      fontFamily: "AB",
                      fontSize: 14,
                      color: MyColors.whiteColor,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${track.artist} • ${track.plays}',
                    style: const TextStyle(
                      fontFamily: "AM",
                      fontSize: 12,
                      color: MyColors.lightGrey,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            SizedBox(width: w * 0.02),
            const Icon(Icons.favorite_border, color: MyColors.lightGrey, size: 18),
            SizedBox(width: w * 0.03),
            Icon(Icons.more_vert, color: MyColors.lightGrey, size: 18),
          ],
        ),
      ),
    );
  }
}

class HomeArtistCard extends StatelessWidget {
  final HomeArtist artist;

  const HomeArtistCard({super.key, required this.artist});

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    final circleSize = w * 0.30;
    return Padding(
      padding: EdgeInsets.only(right: w * 0.035),
      child: Column(
        children: [
          ClipOval(
            child: SizedBox(
              width: circleSize, height: circleSize,
              child: artist.imageUrl != null && artist.imageUrl!.isNotEmpty
                  ? CachedNetworkImage(
                      imageUrl: artist.imageUrl!,
                      fit: BoxFit.cover,
                      placeholder: (_, __) => Container(
                        color: MyColors.darkGreyColor,
                        child: const Center(
                          child: SizedBox(
                            width: 16, height: 16,
                            child: CircularProgressIndicator(
                                color: MyColors.greenColor, strokeWidth: 2),
                          ),
                        ),
                      ),
                      errorWidget: (_, __, ___) => Container(
                        color: MyColors.darkGreyColor,
                        child: const Icon(Icons.person,
                            color: MyColors.lightGrey, size: 32),
                      ),
                    )
                  : Image.asset(
                      artist.image,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        color: MyColors.darkGreyColor,
                        child: const Icon(Icons.person,
                            color: MyColors.lightGrey, size: 32),
                      ),
                    ),
            ),
          ),
          SizedBox(height: w * 0.02),
          SizedBox(
            width: circleSize * 1.2,
            child: Text(
              artist.name,
              style: const TextStyle(
                fontFamily: "AB",
                fontSize: 12,
                color: MyColors.whiteColor,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 2),
          SizedBox(
            width: circleSize * 1.2,
            child: Text(
              artist.listeners,
              style: const TextStyle(
                fontFamily: "AM",
                fontSize: 11,
                color: MyColors.lightGrey,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }
}

class HomeAlbumCard extends StatelessWidget {
  final HomeAlbum album;

  const HomeAlbumCard({super.key, required this.album});

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    return GestureDetector(
      onTap: () {
        HapticService.tap();
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => CollectionDetailPage(
              heroTrack: HomeTrack(
                videoId: 'album_${album.collectionId ?? album.title}',
                title: album.title,
                artist: album.artist,
                duration: '',
                imageUrl: album.imageUrl,
              ),
              allTracks: const [],
              albumTitle: album.title,
              albumImage: album.imageUrl,
              isAlbumView: true,
              collectionId: album.collectionId,
              browseId: album.browseId,
            ),
          ),
        );
      },
      child: Padding(
      padding: EdgeInsets.only(right: w * 0.035),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Stack(
            children: [
              Container(
                width: w * 0.38,
                height: w * 0.38,
                decoration: BoxDecoration(
                  color: MyColors.darkGreyColor,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: album.imageUrl != null && album.imageUrl!.isNotEmpty
                      ? CachedNetworkImage(
                          imageUrl: album.imageUrl!,
                          fit: BoxFit.cover,
                          placeholder: (_, __) => Container(
                            color: MyColors.darkGreyColor,
                            child: const Center(
                              child: SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                    color: MyColors.greenColor, strokeWidth: 2),
                              ),
                            ),
                          ),
                          errorWidget: (_, __, ___) => Container(
                            decoration: const BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  MyColors.darkGreyColor,
                                  Color(0xff1a1a1a)
                                ],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                            ),
                            child: const Icon(Icons.album,
                                color: MyColors.lightGrey, size: 40),
                          ),
                        )
                      : Image.asset(
                          album.image,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Container(
                            decoration: const BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  MyColors.darkGreyColor,
                                  Color(0xff1a1a1a)
                                ],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                            ),
                            child: const Icon(Icons.album,
                                color: MyColors.lightGrey, size: 40),
                          ),
                        ),
                ),
              ),
              Positioned(
                top: 4,
                left: 4,
                child: Image.asset('images/hivefy_logo.png', width: 18, height: 18),
              ),
            ],
          ),
          SizedBox(height: w * 0.02),
          SizedBox(
            width: w * 0.38,
            child: Text(
              album.title,
              style: const TextStyle(
                fontFamily: "AB",
                fontSize: 12,
                color: MyColors.whiteColor,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          SizedBox(
            width: w * 0.38,
            child: Text(
              '${album.artist} • ${album.year}',
              style: const TextStyle(
                fontFamily: "AM",
                fontSize: 11,
                color: MyColors.lightGrey,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
      ),
    );
  }
}

class HomeSectionHeader extends StatelessWidget {
  final String title;

  const HomeSectionHeader({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.only(top: 28, bottom: 12),
        child: Text(
          title,
          style: const TextStyle(
            fontFamily: "AB",
            fontSize: 22,
            fontWeight: FontWeight.w700,
            color: MyColors.whiteColor,
          ),
        ),
      ),
    );
  }
}

class HomeTrackRow extends StatelessWidget {
  final HomeTrack track;
  final int? rank;

  const HomeTrackRow({super.key, required this.track, this.rank});

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    return GestureDetector(
      onTap: () {
        HapticService.tap();
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => TrackDetailScreen(
              title: track.title,
              artist: track.artist,
              imageUrl: track.imageUrl ?? 'https://i.ytimg.com/vi/${track.videoId}/hqdefault.jpg',
              videoId: track.videoId,
            ),
          ),
        );
      },
      child: Container(
        margin: EdgeInsets.only(bottom: w * 0.02),
        child: Row(
          children: [
            if (rank != null)
              SizedBox(
                width: 30,
                child: Text(
                  '$rank',
                  style: const TextStyle(
                    fontFamily: "AB",
                    fontSize: 16,
                    color: MyColors.lightGrey,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            if (rank != null) SizedBox(width: w * 0.02),
            Stack(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: CachedNetworkImage(
                    imageUrl: track.imageUrl ?? 'https://i.ytimg.com/vi/${track.videoId}/hqdefault.jpg',
                    width: 52,
                    height: 52,
                    fit: BoxFit.cover,
                    errorWidget: (_, __, ___) => Container(
                      width: 52,
                      height: 52,
                      color: MyColors.darkGreyColor,
                      child: const Icon(Icons.music_note, color: MyColors.lightGrey),
                    ),
                  ),
                ),
                Positioned(
                  top: 2,
                  left: 2,
                  child: Image.asset('images/hivefy_logo.png', width: 12, height: 12),
                ),
              ],
            ),
            SizedBox(width: w * 0.03),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    track.title,
                    style: const TextStyle(
                      fontFamily: "AB",
                      fontSize: 14,
                      color: MyColors.whiteColor,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 3),
                  Text(
                    '${track.artist} • ${track.plays}',
                    style: const TextStyle(
                      fontFamily: "AM",
                      fontSize: 12,
                      color: MyColors.lightGrey,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            SizedBox(width: w * 0.02),
            const Icon(Icons.favorite_border, color: MyColors.lightGrey, size: 18),
            SizedBox(width: w * 0.03),
            Icon(Icons.more_vert, color: MyColors.lightGrey, size: 18),
          ],
        ),
      ),
    );
  }
}
