import 'package:flutter/material.dart';
import 'package:tunefy/constants/constants.dart';
import 'package:tunefy/services/search_service.dart';
import 'package:tunefy/ui/artist_detail_screen.dart';
import 'package:tunefy/services/haptic_service.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:tunefy/theme/tunefy_theme.dart';

class ArtistCategoryScreen extends StatefulWidget {
  final String title;
  final Color color;

  const ArtistCategoryScreen({super.key, required this.title, required this.color});

  @override
  State<ArtistCategoryScreen> createState() => _ArtistCategoryScreenState();
}

class _ArtistCategoryScreenState extends State<ArtistCategoryScreen> {
  List<SearchResult> _artists = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadArtists();
  }

  Future<void> _loadArtists() async {
    setState(() => _isLoading = true);
    final results = await SearchService.search(
      widget.title,
      filter: SearchFilter.artists,
      limit: 10,
    );
    if (mounted) {
      setState(() {
        _artists = results;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenW = MediaQuery.of(context).size.width;
    final cardSize = screenW * 0.33;
    final expandedHeight = screenW * 0.55;
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
          else if (_artists.isEmpty)
            const SliverFillRemaining(
              child: Center(
                child: Text("No artists found", style: TextStyle(fontFamily: "AM", color: MyColors.lightGrey)),
              ),
            )
          else
            SliverToBoxAdapter(
              child: SizedBox(
                height: cardSize + 60,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 15),
                  itemCount: _artists.length,
                  itemBuilder: (context, index) {
                    return _ArtistTile(
                      artist: _artists[index],
                      onTap: () => _openArtist(_artists[index]),
                      cardSize: cardSize,
                    );
                  },
                ),
              ),
            ),
          const SliverPadding(padding: EdgeInsets.only(bottom: 100)),
        ],
      ),
    );
  }

  void _openArtist(SearchResult artist) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ArtistDetailScreen(
          title: artist.title,
          imageUrl: artist.imageUrl,
          subtitle: artist.subtitle,
        ),
      ),
    );
  }
}

class _ArtistTile extends StatelessWidget {
  final SearchResult artist;
  final VoidCallback onTap;
  final double cardSize;

  const _ArtistTile({required this.artist, required this.onTap, required this.cardSize});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.only(right: 20),
        child: Column(
          children: [
            Container(
              width: cardSize,
              height: cardSize,
              decoration: const BoxDecoration(
                color: MyColors.darkGreyColor,
                shape: BoxShape.circle,
              ),
              child: ClipOval(
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    if (artist.imageUrl != null)
                      CachedNetworkImage(
                        imageUrl: artist.imageUrl!,
                        fit: BoxFit.cover,
                        errorWidget: (_, __, ___) => const Center(
                          child: Icon(Icons.person, color: MyColors.lightGrey, size: 50),
                        ),
                      )
                    else
                      const Center(
                        child: Icon(Icons.person, color: MyColors.lightGrey, size: 50),
                      ),
                    Positioned(
                      bottom: 8,
                      right: 8,
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.7),
                          shape: BoxShape.circle,
                        ),
                        padding: const EdgeInsets.all(6),
                        child: const Icon(Icons.play_arrow, color: MyColors.whiteColor, size: 18),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: cardSize,
              child: Text(
                artist.title,
                style: const TextStyle(fontFamily: "AM", fontSize: 13, color: MyColors.whiteColor),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 2),
            SizedBox(
              width: cardSize,
              child: Text(
                artist.subtitle,
                style: const TextStyle(fontFamily: "AM", fontSize: 11, color: MyColors.lightGrey),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
