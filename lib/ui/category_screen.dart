import 'package:flutter/material.dart';
import 'package:tunefy/constants/constants.dart';
import 'package:tunefy/services/search_service.dart';
import 'package:tunefy/services/podcast_search_service.dart';
import 'package:tunefy/data/model/podcast_models.dart';
import 'package:tunefy/ui/podcast_detail_screen.dart';
import 'package:tunefy/ui/artist_detail_screen.dart';
import 'package:tunefy/services/haptic_service.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:tunefy/theme/tunefy_theme.dart';

class CategoryScreen extends StatefulWidget {
  final String title;
  final Color color;

  const CategoryScreen({super.key, required this.title, required this.color});

  @override
  State<CategoryScreen> createState() => _CategoryScreenState();
}

class _CategoryScreenState extends State<CategoryScreen> {
  List<SearchResult> _playlists = [];
  List<SearchResult> _charts = [];
  List<SearchResult> _newReleases = [];
  List<PodcastChannel> _podcasts = [];
  bool _isLoading = true;
  bool _isPodcastCategory = false;
  bool _isHeaderReady = false;

  static const Map<String, List<String>> _moodMap = {
    'Hip-Hop': ['Chill Rap', 'Workout Hip-Hop', 'Party Hip-Hop', 'Sad Rap'],
    'Pop': ['Chill Pop', 'Workout Pop', 'Party Pop', 'Sad Pop'],
    'Rock': ['Chill Rock', 'Workout Rock', 'Party Rock', 'Classic Rock'],
    'R&B': ['Chill R&B', 'Party R&B', 'Romantic R&B', 'Workout R&B'],
    'Latin': ['Chill Latin', 'Party Latin', 'Workout Latin', 'Reggaeton'],
    'Dance/Electronic': ['Chill EDM', 'Workout EDM', 'Party EDM', 'Deep House'],
    'Indie': ['Chill Indie', 'Workout Indie', 'Party Indie', 'Sad Indie'],
    'Mood': ['Happy', 'Sad', 'Chill', 'Energetic', 'Focus', 'Sleep'],
    'Workout': ['Running', 'Gym', 'Cardio', 'HIIT', 'Yoga'],
    'Party': ['Dance Pop', 'Club', 'Throwback', 'Hip-Hop Party'],
    'Chill': ['Lo-Fi', 'Ambient', 'Acoustic', 'Jazz Chill'],
    'Focus': ['Study', 'Deep Focus', 'Classical Focus', 'Ambient Focus'],
    'Sleep': ['Relax', 'Meditation', 'Nature Sounds', 'Lullaby'],
    'Country': ['Chill Country', 'Workout Country', 'Party Country', 'Country Pop'],
    'Jazz': ['Chill Jazz', 'Jazz Funk', 'Bebop', 'Smooth Jazz'],
    'Classical': ['Relaxing Classical', 'Piano', 'Orchestra', 'Baroque'],
    'K-Pop': ['K-Pop Dance', 'K-Pop Chill', 'K-Pop Party', 'K-Pop Ballad'],
    'Rap': ['Trap', 'Old School', 'Drill', 'Conscious Rap'],
  };

  @override
  void initState() {
    super.initState();
    _isPodcastCategory = widget.title.toLowerCase().contains('podcast');
    _startLoading();
  }

  Future<void> _startLoading() async {
    await Future.delayed(const Duration(milliseconds: 800));
    if (mounted) setState(() => _isHeaderReady = true);
    _loadContent();
  }

  Future<void> _loadContent() async {
    setState(() => _isLoading = true);

    if (_isPodcastCategory) {
      final podcasts = await PodcastSearchService.searchPodcasts(
        '${widget.title} podcast',
        limit: 20,
      );
      if (mounted) {
        setState(() {
          _podcasts = podcasts;
          _isLoading = false;
        });
      }
    } else {
      final queries = await Future.wait([
        SearchService.search('${widget.title} playlist', filter: SearchFilter.playlists, limit: 20),
        SearchService.search('${widget.title} charts top', filter: SearchFilter.playlists, limit: 10),
        SearchService.search('${widget.title} new music', filter: SearchFilter.songs, limit: 10),
      ]);
      if (mounted) {
        setState(() {
          _playlists = queries[0];
          _charts = queries[1];
          _newReleases = queries[2];
          _isLoading = false;
        });
      }
    }
  }

  List<String> _getMoods() {
    return _moodMap[widget.title] ?? [
      '${widget.title} Chill',
      '${widget.title} Workout',
      '${widget.title} Party',
      '${widget.title} Focus',
    ];
  }

  @override
  Widget build(BuildContext context) {
    final screenW = MediaQuery.of(context).size.width;
    final cardSize = screenW * 0.38;
    final expandedHeight = screenW * 0.55;

    if (!_isHeaderReady) {
      return Scaffold(
        backgroundColor: MyColors.blackColor,
        body: const Center(
          child: CircularProgressIndicator(color: MyColors.greenColor),
        ),
      );
    }

    return Scaffold(
      backgroundColor: MyColors.blackColor,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: expandedHeight,
            pinned: true,
            backgroundColor: widget.color,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      widget.color,
                      widget.color.withValues(alpha: 0.7),
                      MyColors.blackColor,
                    ],
                  ),
                ),
                child: Center(
                  child: Text(
                    widget.title,
                    style: TextStyle(
                      fontFamily: "AB",
                      fontSize: screenW * 0.07,
                      color: MyColors.whiteColor,
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
          else if (_isPodcastCategory)
            _buildPodcastSection(cardSize)
          else ...[
            if (_playlists.isNotEmpty) _buildPlaylistsSection(cardSize),
            if (_charts.isNotEmpty) _buildChartsSection(cardSize),
            _buildMoodSection(),
            if (_newReleases.isNotEmpty) _buildNewReleasesSection(cardSize),
          ],
          const SliverPadding(padding: EdgeInsets.only(bottom: 100)),
        ],
      ),
    );
  }

  Widget _buildPodcastSection(double cardSize) {
    if (_podcasts.isEmpty) {
      return const SliverFillRemaining(
        child: Center(
          child: Text("No podcasts found", style: TextStyle(fontFamily: "AM", color: MyColors.lightGrey)),
        ),
      );
    }
    return SliverPadding(
      padding: const EdgeInsets.only(top: 15),
      sliver: SliverList(
        delegate: SliverChildListDelegate([
          _SectionTitle(title: "Podcasts"),
          SizedBox(
            height: cardSize + 55,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 15),
              itemCount: _podcasts.length,
              itemBuilder: (context, index) {
                final podcast = _podcasts[index];
                return GestureDetector(
                  onTap: () {
                    HapticService.tap();
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => PodcastDetailScreen(
                          title: podcast.title,
                          imageUrl: podcast.imageUrl,
                          description: podcast.description,
                        ),
                      ),
                    );
                  },
                  child: _PodcastCard(channel: podcast, cardSize: cardSize),
                );
              },
            ),
          ),
        ]),
      ),
    );
  }

  Widget _buildPlaylistsSection(double cardSize) {
    return SliverPadding(
      padding: const EdgeInsets.only(top: 15),
      sliver: SliverList(
        delegate: SliverChildListDelegate([
          _SectionTitle(title: "Popular playlists"),
          SizedBox(
            height: cardSize + 55,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 15),
              itemCount: _playlists.length,
              itemBuilder: (context, index) {
                final playlist = _playlists[index];
                return GestureDetector(
                  onTap: () => _openDetail(playlist),
                  child: _PlaylistCard(result: playlist, cardSize: cardSize),
                );
              },
            ),
          ),
        ]),
      ),
    );
  }

  Widget _buildChartsSection(double cardSize) {
    return SliverPadding(
      padding: const EdgeInsets.only(top: 20),
      sliver: SliverList(
        delegate: SliverChildListDelegate([
          _SectionTitle(title: "Charts"),
          SizedBox(
            height: cardSize + 55,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 15),
              itemCount: _charts.length,
              itemBuilder: (context, index) {
                final chart = _charts[index];
                return GestureDetector(
                  onTap: () => _openDetail(chart),
                  child: _PlaylistCard(result: chart, cardSize: cardSize),
                );
              },
            ),
          ),
        ]),
      ),
    );
  }

  Widget _buildMoodSection() {
    final moods = _getMoods();
    return SliverPadding(
      padding: const EdgeInsets.only(top: 20),
      sliver: SliverList(
        delegate: SliverChildListDelegate([
          _SectionTitle(title: "Browse by mood"),
          SizedBox(
            height: 45,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 15),
              itemCount: moods.length,
              itemBuilder: (context, index) {
                return _MoodChip(title: moods[index], color: widget.color);
              },
            ),
          ),
        ]),
      ),
    );
  }

  Widget _buildNewReleasesSection(double cardSize) {
    return SliverPadding(
      padding: const EdgeInsets.only(top: 20),
      sliver: SliverList(
        delegate: SliverChildListDelegate([
          _SectionTitle(title: "New releases"),
          SizedBox(
            height: cardSize + 55,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 15),
              itemCount: _newReleases.length,
              itemBuilder: (context, index) {
                final release = _newReleases[index];
                return GestureDetector(
                  onTap: () => _openDetail(release),
                  child: _TrackCard(result: release, cardSize: cardSize),
                );
              },
            ),
          ),
        ]),
      ),
    );
  }

  void _openDetail(SearchResult result) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ArtistDetailScreen(
          title: result.title,
          imageUrl: result.imageUrl,
          subtitle: result.subtitle,
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;
  const _SectionTitle({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 15, bottom: 12),
      child: Text(
        title,
        style: const TextStyle(
          fontFamily: "AB",
          fontSize: 20,
          fontWeight: FontWeight.w700,
          color: MyColors.whiteColor,
        ),
      ),
    );
  }
}

class _PlaylistCard extends StatelessWidget {
  final SearchResult result;
  final double cardSize;
  const _PlaylistCard({required this.result, required this.cardSize});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 15),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: cardSize,
            height: cardSize,
            decoration: BoxDecoration(
              color: MyColors.darkGreyColor,
              borderRadius: BorderRadius.circular(6),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  if (result.imageUrl != null)
                    CachedNetworkImage(
                      imageUrl: result.imageUrl!,
                      fit: BoxFit.cover,
                      errorWidget: (_, __, ___) => const Center(
                        child: Icon(Icons.queue_music, color: MyColors.lightGrey, size: 40),
                      ),
                    )
                  else
                    const Center(
                      child: Icon(Icons.queue_music, color: MyColors.lightGrey, size: 40),
                    ),
                  Positioned(
                    bottom: 8,
                    right: 8,
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.7),
                        shape: BoxShape.circle,
                      ),
                      padding: const EdgeInsets.all(8),
                      child: const Icon(Icons.play_arrow, color: MyColors.whiteColor, size: 22),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: cardSize,
            child: Text(
              result.title,
              style: const TextStyle(fontFamily: "AM", fontSize: 13, color: MyColors.whiteColor),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(height: 2),
          SizedBox(
            width: cardSize,
            child: Text(
              result.subtitle,
              style: const TextStyle(fontFamily: "AM", fontSize: 11, color: MyColors.lightGrey),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

class _TrackCard extends StatelessWidget {
  final SearchResult result;
  final double cardSize;
  const _TrackCard({required this.result, required this.cardSize});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 15),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: cardSize,
            height: cardSize,
            decoration: BoxDecoration(
              color: MyColors.darkGreyColor,
              borderRadius: BorderRadius.circular(6),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  if (result.imageUrl != null)
                    CachedNetworkImage(
                      imageUrl: result.imageUrl!,
                      fit: BoxFit.cover,
                      errorWidget: (_, __, ___) => const Center(
                        child: Icon(Icons.music_note, color: MyColors.lightGrey, size: 40),
                      ),
                    )
                  else
                    const Center(
                      child: Icon(Icons.music_note, color: MyColors.lightGrey, size: 40),
                    ),
                  Positioned(
                    bottom: 8,
                    right: 8,
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.7),
                        shape: BoxShape.circle,
                      ),
                      padding: const EdgeInsets.all(8),
                      child: const Icon(Icons.play_arrow, color: MyColors.whiteColor, size: 22),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: cardSize,
            child: Text(
              result.title,
              style: const TextStyle(fontFamily: "AM", fontSize: 13, color: MyColors.whiteColor),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(height: 2),
          SizedBox(
            width: cardSize,
            child: Text(
              result.subtitle,
              style: const TextStyle(fontFamily: "AM", fontSize: 11, color: MyColors.lightGrey),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

class _MoodChip extends StatelessWidget {
  final String title;
  final Color color;
  const _MoodChip({required this.title, required this.color});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 10),
      child: Container(
        height: 45,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.8),
          borderRadius: BorderRadius.circular(25),
        ),
        child: Center(
          child: Text(
            title,
            style: const TextStyle(
              fontFamily: "AM",
              fontSize: 13,
              color: MyColors.whiteColor,
            ),
          ),
        ),
      ),
    );
  }
}

class _PodcastCard extends StatelessWidget {
  final PodcastChannel channel;
  final double cardSize;
  const _PodcastCard({required this.channel, required this.cardSize});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 15),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: cardSize,
            height: cardSize,
            decoration: BoxDecoration(
              color: MyColors.darkGreyColor,
              borderRadius: BorderRadius.circular(6),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  if (channel.imageUrl != null)
                    CachedNetworkImage(
                      imageUrl: channel.imageUrl!,
                      fit: BoxFit.cover,
                      errorWidget: (_, __, ___) => const Center(
                        child: Icon(Icons.podcasts, color: MyColors.lightGrey, size: 40),
                      ),
                    )
                  else
                    const Center(
                      child: Icon(Icons.podcasts, color: MyColors.lightGrey, size: 40),
                    ),
                  Positioned(
                    bottom: 8,
                    right: 8,
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.7),
                        shape: BoxShape.circle,
                      ),
                      padding: const EdgeInsets.all(8),
                      child: const Icon(Icons.arrow_forward, color: MyColors.whiteColor, size: 22),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: cardSize,
            child: Text(
              channel.title,
              style: const TextStyle(fontFamily: "AM", fontSize: 13, color: MyColors.whiteColor),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(height: 2),
          SizedBox(
            width: cardSize,
            child: Text(
              channel.description,
              style: const TextStyle(fontFamily: "AM", fontSize: 11, color: MyColors.lightGrey),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
