import 'package:flutter/material.dart';
import 'package:tunefy/constants/constants.dart';
import 'package:tunefy/data/model/podcast_models.dart';
import 'package:tunefy/services/podcast_search_service.dart';
import 'package:tunefy/DI/service_locator.dart';
import 'package:tunefy/models/track.dart';
import 'package:tunefy/services/haptic_service.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:tunefy/theme/tunefy_theme.dart';

class PodcastDetailScreen extends StatefulWidget {
  final String title;
  final String? imageUrl;
  final String? description;

  const PodcastDetailScreen({
    super.key,
    required this.title,
    this.imageUrl,
    this.description,
  });

  @override
  State<PodcastDetailScreen> createState() => _PodcastDetailScreenState();
}

class _PodcastDetailScreenState extends State<PodcastDetailScreen> {
  List<PodcastEpisode> _episodes = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadEpisodes();
  }

  Future<void> _loadEpisodes() async {
    setState(() => _isLoading = true);
    final results = await PodcastSearchService.searchEpisodes(
      '${widget.title} podcast',
      limit: 30,
    );
    if (mounted) {
      setState(() {
        _episodes = results;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: MyColors.blackColor,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 250,
            pinned: true,
            backgroundColor: MyColors.darkGreyColor,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Color(0xff282828),
                      MyColors.blackColor,
                    ],
                  ),
                ),
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        if (widget.imageUrl != null)
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: CachedNetworkImage(
                              imageUrl: widget.imageUrl!,
                              width: 120,
                              height: 120,
                              fit: BoxFit.cover,
                              errorWidget: (_, __, ___) => Container(
                                width: 120,
                                height: 120,
                                color: MyColors.darkGreyColor,
                                child: const Icon(Icons.podcasts, color: MyColors.whiteColor, size: 50),
                              ),
                            ),
                          )
                        else
                          Container(
                            width: 120,
                            height: 120,
                            decoration: BoxDecoration(
                              color: MyColors.darkGreyColor,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(Icons.podcasts, color: MyColors.whiteColor, size: 50),
                          ),
                        const SizedBox(height: 12),
                        Text(
                          widget.title,
                          style: const TextStyle(
                            fontFamily: "AB",
                            fontSize: 22,
                            color: MyColors.whiteColor,
                          ),
                          textAlign: TextAlign.center,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (widget.description != null && widget.description!.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(
                            widget.description!,
                            style: const TextStyle(
                              fontFamily: "AM",
                              fontSize: 13,
                              color: MyColors.lightGrey,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
          if (_isLoading)
            const SliverFillRemaining(
              child: Center(child: CircularProgressIndicator(color: MyColors.whiteColor)),
            )
          else if (_episodes.isEmpty)
            const SliverFillRemaining(
              child: Center(
                child: Text("No episodes found", style: TextStyle(fontFamily: "AM", color: MyColors.lightGrey)),
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 15),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) => _EpisodeTile(
                    episode: _episodes[index],
                    onTap: () => _playEpisode(_episodes[index]),
                  ),
                  childCount: _episodes.length,
                ),
              ),
            ),
          const SliverPadding(padding: EdgeInsets.only(bottom: 100)),
        ],
      ),
    );
  }

  void _playEpisode(PodcastEpisode episode) {
    if (episode.videoId == null) return;
    final track = Track(
      videoId: episode.videoId,
      title: episode.title,
      artist: episode.channelTitle,
      albumImage: episode.imageUrl,
    );
    playerProvider.playTrack(track);
  }
}

class _EpisodeTile extends StatelessWidget {
  final PodcastEpisode episode;
  final VoidCallback onTap;

  const _EpisodeTile({required this.episode, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            color: MyColors.darkGreyColor,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: episode.imageUrl != null
                      ? CachedNetworkImage(
                          imageUrl: episode.imageUrl!,
                          width: 56,
                          height: 56,
                          fit: BoxFit.cover,
                          errorWidget: (_, __, ___) => Container(
                            width: 56,
                            height: 56,
                            color: MyColors.blackColor,
                            child: const Icon(Icons.podcasts, color: MyColors.whiteColor, size: 24),
                          ),
                        )
                      : Container(
                          width: 56,
                          height: 56,
                          color: MyColors.blackColor,
                          child: const Icon(Icons.podcasts, color: MyColors.whiteColor, size: 24),
                        ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        episode.title,
                        style: const TextStyle(
                          fontFamily: "AM",
                          fontSize: 14,
                          color: MyColors.whiteColor,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        episode.channelTitle,
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
                const SizedBox(width: 8),
                Container(
                  decoration: BoxDecoration(
                    color: MyColors.blackColor,
                    shape: BoxShape.circle,
                  ),
                  padding: const EdgeInsets.all(6),
                  child: const Icon(Icons.play_arrow, color: MyColors.whiteColor, size: 20),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
