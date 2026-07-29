import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:tunefy/data/home_data.dart';
import 'package:tunefy/data/album_catalog.dart';
import 'package:tunefy/models/home_track.dart';
import 'package:tunefy/models/track.dart';
import 'package:tunefy/services/itunes_service.dart';
import 'package:tunefy/services/muzo_service.dart';
import 'package:tunefy/services/search_service.dart';
import 'package:tunefy/services/liked_service.dart';
import 'package:tunefy/DI/service_locator.dart';
import 'package:tunefy/helpers/tunefy_helpers.dart';
import 'package:tunefy/services/haptic_service.dart';
import 'package:tunefy/theme/tunefy_colors.dart';
export 'package:tunefy/theme/tunefy_colors.dart';
import 'package:tunefy/theme/tunefy_theme.dart';
import 'package:tunefy/ui/collection_detail_page.dart';
import 'package:tunefy/ui/profile_screen.dart';
import 'package:tunefy/ui/embedded_search_screen.dart';
import 'package:tunefy/ui/qr_scanner_screen.dart';
import 'package:tunefy/ui/liked_tracks_page.dart';
import 'package:tunefy/widgets/add_to_playlist_sheet.dart';
import 'package:tunefy/widgets/device_sheet.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:share_plus/share_plus.dart';
import 'package:just_audio/just_audio.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
    systemNavigationBarColor: Color(0xFF000000),
    systemNavigationBarIconBrightness: Brightness.light,
  ));
  runApp(const TunefyApp());
}

class TunefyApp extends StatelessWidget {
  const TunefyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Tunefy',
      debugShowCheckedModeBanner: false,
      theme: TunefyTheme.darkTheme,
      home: const TunefyHome(),
    );
  }
}

class HivefyIcon extends StatelessWidget {
  final double size;
  const HivefyIcon({super.key, this.size = 30});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(size, size),
      painter: _HivefyIconPainter(),
    );
  }
}

class _HivefyIconPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final r = size.width * 0.46;
    final path = Path();
    for (int i = 0; i < 6; i++) {
      final angle = (60 * i - 90) * 3.14159265 / 180;
      final dx = cx + r * math.cos(angle);
      final dy = cy + r * math.sin(angle);
      if (i == 0) path.moveTo(dx, dy);
      else path.lineTo(dx, dy);
    }
    path.close();
    final gradient = LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [Color(0xFF1DB954), Color(0xFF158A3E)],
    );
    final paint = Paint()
      ..shader = gradient.createShader(Rect.fromLTWH(0, 0, size.width, size.height))
      ..style = PaintingStyle.fill;
    canvas.drawPath(path, paint);
    final textPainter = TextPainter(
      text: TextSpan(
        text: 'H',
        style: TextStyle(
          color: Colors.white,
          fontSize: size.width * 0.52,
          fontWeight: FontWeight.w900,
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();
    textPainter.paint(
      canvas,
      Offset(cx - textPainter.width / 2, cy - textPainter.height / 2 - size.width * 0.02),
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

final List<String> _trackNames = [
  'Mauvais Ordre', 'Versus', 'Amour et Admiration', 'La Mort D\'Artiste',
  'Macarena', 'Laissez passer', 'Bande organisée', 'Billets Violets',
  'Fais les backs', 'Cash', 'Réseaux', 'La Puerta',
  'Désolé', 'KMT', 'Ninja', 'Bâtiment',
  'Peur de rien', 'J\'ai vu', 'Zoo', 'Orchestre',
  'Tokoo', 'Brume', 'Ébène', 'Diamant Noir',
  'Alambik', 'Tchoin', 'Bande Organisée', 'En PLS',
  'Risibles Amours', 'Biscotte', 'Champion', 'Moulaga',
  'Hé oh', 'Gros', 'Naha', 'Petite École',
  'Laissez-les kouler', 'VVS', 'Hasta Luego', 'Éternité',
  'Princesse', 'Bonne', 'Loca', 'On m\'a dit',
  'Zumba', 'Dommage', 'Mikey', 'Héroe',
  'Suerte', 'Jenny', 'Plusrien', 'Elle a',
  'Reine', 'Roi', 'Prince', 'Princesse',
  'Soleil', 'Lune', 'Étoile', 'Ciel',
  'Feu', 'Eau', 'Terre', 'Air',
  'Lumière', 'Ombre', 'Jour', 'Nuit',
  'Rouge', 'Bleu', 'Vert', 'Noir',
  'Blanc', 'Or', 'Argent', 'Bronze',
  'Vitesse', 'Puissance', 'Force', 'Courage',
];

final List<String> _artistNames = [
  'Damso', 'PNL', 'Ninho', 'MHD', 'Kaaris', 'Booba', 'Soprano', 'Jul',
  'Lartiste', 'Dadju', 'Soolking', 'Maitre Gims', 'Aya Nakamura', 'Stromae',
  'Angèle', 'Slimane', 'Vitaa', 'Gims', 'Sofiane', 'Nekfeu', 'Orelsan',
  'Gradur', 'Black M', 'Fouki', 'Lomepal', 'Laylow', 'Kalash', 'Tayc',
  'Diam\'s', 'IAM', 'NTM', 'MC Solaar', 'Busta Flex', 'Rohff',
  'La Fouine', 'Kery James', 'Sinik', 'Oxmo Puccino', 'Mister You',
  'Julien Clerc', 'Goldman', 'Renaud', 'Patrick Bruel', 'Francis Cabrel',
  'Joe Dassin', 'Jacques Dutronc', 'Serge Gainsbourg', 'Charles Trenet', 'Edith Piaf',
  'Yseult', 'Niska', 'Gazo', 'Freeze Corleone', 'Kaiya', 'Elia',
  'Hamza', 'Sch', 'Luv Resval', 'Alpha Wann', 'Davodka',
  'Casseurs Flowters', 'Deen Burbigo', 'Mister V', 'Hugo TSR', 'Hippocampe Fou',
  'Caballero & JeanJass', 'Dosseh', 'Bosh', 'Sidi', 'Lyra',
  'Kenza Farah', 'Sina', 'GIMS', 'Fally Ipupa', 'Innoss\'B', 'Inna',
  'Helly Luv', 'Tlinaman', 'ElGrandeToto', 'Manal', 'Malika',
  'Sniper', 'Tunisiano', 'Aketo', 'Blacko', 'Tunski',
];

final List<String> _coverUrls = [
  'https://picsum.photos/seed/a1/300/300',
  'https://picsum.photos/seed/b2/300/300',
  'https://picsum.photos/seed/c3/300/300',
  'https://picsum.photos/seed/d4/300/300',
  'https://picsum.photos/seed/e5/300/300',
  'https://picsum.photos/seed/f6/300/300',
  'https://picsum.photos/seed/g7/300/300',
  'https://picsum.photos/seed/h8/300/300',
  'https://picsum.photos/seed/i9/300/300',
  'https://picsum.photos/seed/j10/300/300',
  'https://picsum.photos/seed/k11/300/300',
  'https://picsum.photos/seed/l12/300/300',
  'https://picsum.photos/seed/m13/300/300',
  'https://picsum.photos/seed/n14/300/300',
  'https://picsum.photos/seed/o15/300/300',
  'https://picsum.photos/seed/p16/300/300',
];

String _trackName(int i) => _trackNames[i % _trackNames.length];
String _artistName(int i) => _artistNames[i % _artistNames.length];
String _coverUrl(int i) => _coverUrls[i % _coverUrls.length];

class TunefyHome extends StatefulWidget {
  const TunefyHome({super.key});
  @override
  State<TunefyHome> createState() => _TunefyHomeState();
}

class _TunefyHomeState extends State<TunefyHome> {
  int _currentTab = 0;
  bool _isShuffle = false;
  bool _isRepeat = false;
  bool _isAddedToLibrary = false;
  int _currentTrackIndex = 0;
  final ScrollController _scrollController = ScrollController();
  bool _isLoading = true;
  final List<HomeTrack> _recentlyPlayed = [];
  final List<HomeTrack> _dailyRecommendations = [];
  int _likedCount = 0;
  List<Map<String, dynamic>> _topArtistsFromLiked = [];
  VoidCallback? _globalTrackListener;

  @override
  void initState() {
    super.initState();
    _globalTrackListener = () => _onGlobalTrackChanged();
    globalActiveTrack.addListener(_globalTrackListener!);
    HomeData.onSectionsUpdated = () { if (mounted) setState(() {}); };
    _initData();
  }

  @override
  void dispose() {
    HomeData.onSectionsUpdated = null;
    if (_globalTrackListener != null) {
      globalActiveTrack.removeListener(_globalTrackListener!);
    }
    _scrollController.dispose();
    super.dispose();
  }

  void _onGlobalTrackChanged() {
    final track = globalActiveTrack.value;
    if (track == null) return;
    _recentlyPlayed.removeWhere((t) => t.videoId == track.videoId);
    _recentlyPlayed.insert(0, track);
    if (_recentlyPlayed.length > 20) _recentlyPlayed.removeLast();
    _refreshLikedCount();
    _generateDailyRecommendations();
    if (mounted) setState(() {});
  }

  Future<void> _initData() async {
    try { await Permission.bluetoothConnect.request(); } catch (_) {}
    await HomeData.load();
    _refreshLikedCount();
    _generateDailyRecommendations();
    if (mounted) setState(() => _isLoading = false);
  }

  void _refreshLikedCount() {
    _likedCount = LikedService().getAll().length;
    _computeTopArtists();
  }

  void _computeTopArtists() {
    final likedTracks = LikedService().getAll();
    final artistCount = <String, int>{};
    for (final t in likedTracks) {
      if (t.artist.isNotEmpty) {
        artistCount[t.artist] = (artistCount[t.artist] ?? 0) + 1;
      }
    }
    final sorted = artistCount.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    _topArtistsFromLiked = sorted.take(3).map((e) => {
      'name': e.key,
      'count': e.value,
    }).toList();
  }

  void _loadRecentlyPlayed() {
    try {
      final box = Hive.box('settings');
      final List? stored = box.get('recently_played');
      if (stored != null) {
        _recentlyPlayed.clear();
        for (final item in stored) {
          _recentlyPlayed.add(HomeTrack(
            videoId: item['videoId'] ?? '',
            title: item['title'] ?? '',
            artist: item['artist'] ?? '',
            duration: item['duration'] ?? '0:00',
            imageUrl: item['imageUrl'],
          ));
        }
      }
    } catch (e) {
      debugPrint('Error loading recently played: $e');
    }
  }

  void _saveRecentlyPlayed() {
    try {
      final box = Hive.box('settings');
      final List<Map<String, dynamic>> data = _recentlyPlayed.map((t) => {
        'videoId': t.videoId,
        'title': t.title,
        'artist': t.artist,
        'duration': t.duration,
        'imageUrl': t.imageUrl,
      }).toList();
      box.put('recently_played', data);
    } catch (e) {
      debugPrint('Error saving recently played: $e');
    }
  }

  void _generateDailyRecommendations() {
    final allTracks = HomeData.sections.expand((s) => s.tracks).toList();
    if (allTracks.isEmpty) return;

    final now = DateTime.now();
    final seed = now.year * 10000 + now.month * 100 + now.day;
    final rng = math.Random(seed);

    final likedTracks = LikedService().getAll();
    final knownArtists = <String>{};
    for (final t in likedTracks) {
      if (t.artist.isNotEmpty) knownArtists.add(t.artist.toLowerCase());
    }
    for (final t in _recentlyPlayed) {
      if (t.artist.isNotEmpty) knownArtists.add(t.artist.toLowerCase());
    }

    final shuffled = List<HomeTrack>.from(allTracks)..shuffle(rng);

    final selected = <HomeTrack>[];
    final usedArtists = <String>{};
    for (final t in shuffled) {
      if (selected.length >= 10) break;
      final artist = t.artist.toLowerCase();
      if (usedArtists.length < 6 || !usedArtists.contains(artist)) {
        selected.add(t);
        usedArtists.add(artist);
      }
    }
    _dailyRecommendations.clear();
    _dailyRecommendations.addAll(selected);
  }

  void _togglePlay() {
    haptic();
    playerProvider.togglePlay();
  }

  void _toggleShuffle() {
    haptic();
    setState(() => _isShuffle = !_isShuffle);
    playerProvider.player.setShuffleModeEnabled(_isShuffle);
  }
  void _toggleRepeat() {
    haptic();
    setState(() => _isRepeat = !_isRepeat);
    playerProvider.player.setLoopMode(_isRepeat ? LoopMode.one : LoopMode.off);
  }
  void _nextTrack() => setState(() { _currentTrackIndex = (_currentTrackIndex + 1) % 80; });
  void _prevTrack() => setState(() { _currentTrackIndex = (_currentTrackIndex - 1 + 80) % 80; });

  void _playTrack(HomeTrack track) {
    haptic();
    final trackModel = Track(
      videoId: track.videoId,
      title: track.title,
      artist: track.artist,
      albumImage: track.imageUrl,
      duration: _parseDuration(track.duration),
    );
    setState(() { _currentTrackIndex = 0; });
    globalActiveTrack.value = track;
    playerProvider.playTrack(trackModel);
  }

  Duration _parseDuration(String dur) {
    final parts = dur.split(':');
    if (parts.length == 2) {
      return Duration(minutes: int.tryParse(parts[0]) ?? 0, seconds: int.tryParse(parts[1]) ?? 0);
    }
    return Duration.zero;
  }

  String _formatDuration(Duration d) {
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    if (d.inHours > 0) return '${d.inHours}:$m:$s';
    return '$m:$s';
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    final prefix = hour < 12 ? 'Bonjour' : hour < 18 ? 'Bon après-midi' : 'Bonsoir';
    final userName = Hive.box('settings').get('userName', defaultValue: '') as String;
    return userName.isNotEmpty ? '$prefix $userName' : prefix;
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: ThemeData(brightness: Brightness.dark, scaffoldBackgroundColor: TunefyColors.black),
        home: Scaffold(
          backgroundColor: TunefyColors.black,
          body: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const HivefyIcon(size: 60),
                const SizedBox(height: 20),
                const CircularProgressIndicator(color: TunefyColors.green, strokeWidth: 3),
              ],
            ),
          ),
        ),
      );
    }
    final safeBottom = MediaQuery.of(context).padding.bottom;
    return Scaffold(
      backgroundColor: TunefyColors.black,
      body: Stack(
        children: [
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            bottom: 64 + 62 + safeBottom,
            child: IndexedStack(
              index: _currentTab,
              children: [
                _buildHomeTab(),
                _buildSearchTab(),
                _buildLibraryTab(),
              ],
            ),
          ),
          Positioned(
            left: 8,
            right: 8,
            bottom: 64 + safeBottom,
            child: RepaintBoundary(child: _buildMiniPlayer()),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: RepaintBoundary(child: _buildBottomNavBar()),
          ),
        ],
      ),
    );
  }

  Widget _buildHomeTab() {
    final sections = HomeData.sections;
    return CustomScrollView(
      controller: _scrollController,
      slivers: [
        SliverToBoxAdapter(child: RepaintBoundary(child: _buildHomeHeader())),
        if (_dailyRecommendations.isNotEmpty) ...[
          SliverToBoxAdapter(child: RepaintBoundary(child: _buildSectionHeader('Recommandé pour vous aujourd\'hui'))),
          SliverToBoxAdapter(child: RepaintBoundary(child: _buildHorizontalRecommendations())),
        ],
        if (_recentlyPlayed.isNotEmpty) ...[
          SliverToBoxAdapter(child: RepaintBoundary(child: _buildSectionHeader('Écoutés récemment'))),
          SliverToBoxAdapter(child: RepaintBoundary(child: _buildHorizontalRecent())),
        ],
        for (final section in sections) ...[
          SliverToBoxAdapter(child: RepaintBoundary(child: _buildSectionHeader(section.title))),
          SliverToBoxAdapter(child: RepaintBoundary(child: _buildHorizontalSection(section))),
        ],
        const SliverPadding(padding: EdgeInsets.only(bottom: 120)),
      ],
    );
  }

  Widget _buildHorizontalRecent() {
    final w = MediaQuery.of(context).size.width;
    final n = _recentlyPlayed.length;
    return SizedBox(
      height: w * 0.38 + 44,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 10),
        itemCount: n,
        itemBuilder: (context, i) => _buildTrackCard(_recentlyPlayed[i], i, w),
      ),
    );
  }

  Widget _buildHorizontalLiked(List likedTracks) {
    final w = MediaQuery.of(context).size.width;
    final n = likedTracks.length;
    return SizedBox(
      height: w * 0.38 + 44,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 10),
        itemCount: n,
        itemBuilder: (context, i) {
          final t = likedTracks[i];
          final ht = HomeTrack(videoId: t.videoId, title: t.title, artist: t.artist, duration: '', imageUrl: t.albumImage);
          return _buildTrackCard(ht, i, w);
        },
      ),
    );
  }

  Widget _buildHorizontalRecommendations() {
    final w = MediaQuery.of(context).size.width;
    final itemW = w * 0.38;
    return SizedBox(
      height: itemW + 44,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 10),
        itemCount: _dailyRecommendations.length,
        itemBuilder: (context, i) => _buildTrackCard(_dailyRecommendations[i], i, w),
      ),
    );
  }

  Widget _buildHomeHeader() {
    final w = MediaQuery.of(context).size.width;
    final statusBar = MediaQuery.of(context).padding.top;
    return Padding(
      padding: EdgeInsets.fromLTRB(w * 0.04, statusBar + 12, w * 0.04, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              GestureDetector(
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ProfileScreen())),
                child: Row(
                  children: [
                    Image.asset('images/hivefy_logo.png', width: w * 0.12, height: w * 0.12),
                    SizedBox(width: w * 0.03),
                    Text(
                      _getGreeting(),
                      style: TextStyle(
                        fontFamily: "AB",
                        color: TunefyColors.white,
                        fontSize: w * 0.065,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: w * 0.04),
          ..._buildQuickChips(w),
        ],
      ),
    );
  }

  List<Widget> _buildQuickChips(double w) {
    final chips = <Widget>[];
    final chipWidth = (w - w * 0.08 - w * 0.03) / 2;
    chips.add(
      Row(
        children: [
          _buildQuickChip("Liked Songs", "images/liked_songs.png", true, chipWidth, null),
          SizedBox(width: w * 0.03),
          if (_topArtistsFromLiked.isNotEmpty)
            _buildQuickChip(
              _topArtistsFromLiked[0]['name'] as String,
              '',
              false, chipWidth, _topArtistsFromLiked[0]['name'] as String,
            ),
        ],
      ),
    );
    if (_topArtistsFromLiked.length >= 2 || _topArtistsFromLiked.length >= 3) {
      chips.add(Padding(
        padding: EdgeInsets.only(top: w * 0.01),
        child: Row(
          children: [
            if (_topArtistsFromLiked.length >= 2)
              _buildQuickChip(
                _topArtistsFromLiked[1]['name'] as String,
                '',
                false, chipWidth, _topArtistsFromLiked[1]['name'] as String,
              ),
            if (_topArtistsFromLiked.length >= 2) SizedBox(width: w * 0.03),
            if (_topArtistsFromLiked.length >= 3)
              _buildQuickChip(
                _topArtistsFromLiked[2]['name'] as String,
                '',
                false, chipWidth, _topArtistsFromLiked[2]['name'] as String,
              ),
          ],
        ),
      ));
    }
    return chips;
  }

  Widget _buildQuickChip(String title, String image, bool isLiked, double chipWidth, String? artistName) {
    final h = chipWidth * 0.34;
    return GestureDetector(
      onTap: () {
        haptic();
        if (isLiked) {
          Navigator.push(context, MaterialPageRoute(builder: (_) => LikedTracksPage(tracks: LikedService().getAll())));
        } else if (artistName != null) {
          Navigator.push(context, MaterialPageRoute(
            builder: (_) => CollectionDetailPage(
              heroTrack: HomeTrack(videoId: 'placeholder', title: artistName, artist: artistName, duration: '0:00',
                imageUrl: ''),
              allTracks: HomeData.sections.expand((s) => s.tracks).toList(),
            ),
          ));
        }
      },
      child: Container(
        height: h,
        width: chipWidth,
        decoration: BoxDecoration(
          color: TunefyColors.darkCard,
          borderRadius: const BorderRadius.all(Radius.circular(6)),
          border: Border.all(color: TunefyColors.white.withValues(alpha: 0.06)),
        ),
        child: Row(
          children: [
            if (isLiked)
              Stack(
                alignment: AlignmentDirectional.center,
                children: [
                  Container(
                    height: h,
                    width: h,
                    decoration: const BoxDecoration(
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(6),
                        bottomLeft: Radius.circular(6),
                      ),
                      image: DecorationImage(image: AssetImage("images/liked_songs.png"), fit: BoxFit.cover),
                    ),
                  ),
                  Image.asset('images/icon_heart_white.png', height: h * 0.4, width: h * 0.4),
                ],
              )
            else
              ClipRRect(
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(6),
                  bottomLeft: Radius.circular(6),
                ),
                child: SizedBox(
                  height: h,
                  width: h,
                  child: image.isNotEmpty && image.startsWith('http')
                      ? CachedNetworkImage(
                          imageUrl: image, fit: BoxFit.cover,
                          placeholder: (_, __) => Container(color: TunefyColors.darkCard, child: const Icon(Icons.person, color: TunefyColors.grey, size: 20)),
                          errorWidget: (_, __, ___) => Container(color: TunefyColors.darkCard, child: const Icon(Icons.person, color: TunefyColors.grey, size: 20)),
                        )
                      : image.isNotEmpty
                          ? Image.asset(image, fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => Container(color: TunefyColors.darkCard, child: const Icon(Icons.person, color: TunefyColors.grey, size: 20)),
                            )
                          : Container(color: TunefyColors.darkCard, child: const Icon(Icons.person, color: TunefyColors.grey, size: 20)),
                ),
              ),
            SizedBox(width: chipWidth * 0.04),
            Expanded(
              child: Text(
                title,
                style: TextStyle(fontFamily: "AB", fontSize: chipWidth * 0.055, color: TunefyColors.white),
                maxLines: 1, overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 12),
      child: Text(title, style: const TextStyle(
        fontFamily: 'AB', fontSize: 18, color: TunefyColors.white, fontWeight: FontWeight.w700,
      )),
    );
  }

  Widget _buildHorizontalSection(HomeSection section) {
    final w = MediaQuery.of(context).size.width;
    if (section.type == HomeSectionType.artists) {
      return SizedBox(
        height: w * 0.30 + 44,
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          itemCount: section.artists.length,
          itemBuilder: (context, i) => _buildArtistCard(section.artists[i], w),
        ),
      );
    }
    if (section.type == HomeSectionType.albums) {
      return SizedBox(
        height: w * 0.38 + 44,
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          itemCount: section.albums.length,
          itemBuilder: (context, i) => _buildAlbumCard(section.albums[i], w),
        ),
      );
    }
    return SizedBox(
      height: w * 0.38 + 44,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        itemCount: section.tracks.length,
        itemBuilder: (context, i) => _buildTrackCard(section.tracks[i], i, w),
      ),
    );
  }

  Widget _buildTrackCard(HomeTrack track, int i, double w) {
    final imgH = w * 0.38;
    return GestureDetector(
      onTap: () {
        haptic();
        Navigator.push(context, MaterialPageRoute(
          builder: (_) => CollectionDetailPage(
            heroTrack: track,
            allTracks: HomeData.sections.expand((s) => s.tracks).toList(),
          ),
        ));
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: Stack(
                children: [
                  TrackImage(track: track, width: w * 0.38, height: imgH),
                  Positioned(
                    top: 3, left: 3,
                    child: Container(
                      width: 16, height: 16,
                      decoration: const BoxDecoration(
                        color: Color(0xB2000000),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.music_note, color: Colors.white, size: 10),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: w * 0.38,
              child: Text(track.title,
                style: const TextStyle(fontFamily: 'AB', fontSize: 12, color: TunefyColors.white),
                maxLines: 1, overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(height: 2),
            SizedBox(
              width: w * 0.38,
              child: Text(track.artist,
                style: const TextStyle(fontFamily: 'AM', fontSize: 11, color: TunefyColors.grey),
                maxLines: 1, overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildArtistCard(HomeArtist artist, double w) {
    final imgUrl = artist.imageUrl ?? '';
    final circleSize = w * 0.30;
    return GestureDetector(
      onTap: () {
        haptic();
        Navigator.push(context, MaterialPageRoute(
          builder: (_) => CollectionDetailPage(
            heroTrack: HomeTrack(
              videoId: 'placeholder',
              title: artist.name,
              artist: artist.name,
              duration: '0:00',
              imageUrl: imgUrl.isNotEmpty ? imgUrl : '',
            ),
            allTracks: HomeData.sections.expand((s) => s.tracks).toList(),
          ),
        ));
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6),
        child: Column(
          children: [
            ClipOval(
              child: SizedBox(
                width: circleSize, height: circleSize,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    imgUrl.isNotEmpty
                        ? CachedNetworkImage(
                            imageUrl: imgUrl, fit: BoxFit.cover,
                            placeholder: (_, __) => Container(color: TunefyColors.darkCard, child: const Icon(Icons.person, color: TunefyColors.grey, size: 28)),
                            errorWidget: (_, __, ___) => Image.asset(artist.image, fit: BoxFit.cover,
                              errorBuilder: (_, ___, ____) => Container(color: TunefyColors.darkCard, child: const Icon(Icons.person, color: TunefyColors.grey, size: 28)),
                            ),
                          )
                        : Image.asset(
                            artist.image, fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => Container(color: TunefyColors.darkCard, child: const Icon(Icons.person, color: TunefyColors.grey, size: 28)),
                          ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(width: circleSize * 1.3,
              child: Text(artist.name, style: const TextStyle(fontFamily: 'AB', fontSize: 12, color: TunefyColors.white),
                maxLines: 1, overflow: TextOverflow.ellipsis, textAlign: TextAlign.center)),
          ],
        ),
      ),
    );
  }

  Widget _buildAlbumCard(HomeAlbum album, double w) {
    final imgUrl = album.imageUrl ?? '';
    final albumImg = imgUrl.isNotEmpty ? imgUrl : album.image;
    return GestureDetector(
      onTap: () async {
        haptic();
        debugPrint('ALBUM CARD TAPPED: "${album.title}" by ${album.artist}, collectionId=${album.collectionId}, browseId=${album.browseId}');
        List<HomeTrack> albumTracks = [];

        // 1) iTunes Lookup by collectionId (fastest & most reliable)
        if (album.collectionId != null) {
          try {
            albumTracks = await ItunesService.fetchAlbumTracks(album.collectionId!);
            debugPrint('  iTunes Lookup returned ${albumTracks.length} tracks');
          } catch (_) { debugPrint('  iTunes Lookup FAILED'); }
        }

        // 2) iTunes search by title (lenient match)
        if (albumTracks.isEmpty) {
          try {
            albumTracks = await ItunesService.fetchAlbumTracksByTitle(album.title, album.artist);
            debugPrint('  iTunes search by title returned ${albumTracks.length} tracks');
          } catch (_) { debugPrint('  iTunes search by title FAILED'); }
        }

        // 3) Last resort: artist top tracks
        if (albumTracks.isEmpty) {
          try {
            albumTracks = await ItunesService.fetchArtistTopTracks(album.artist);
            debugPrint('  iTunes artist top tracks: ${albumTracks.length} tracks');
          } catch (_) { debugPrint('  iTunes artist top tracks FAILED'); }
        }

        debugPrint('  FINAL albumTracks count = ${albumTracks.length}');
        if (!context.mounted) return;
        Navigator.push(context, MaterialPageRoute(
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
            heroTrackList: albumTracks,
            isAlbumView: true,
            collectionId: album.collectionId,
            browseId: album.browseId,
          ),
        ));
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: w * 0.38, height: w * 0.38,
              decoration: BoxDecoration(color: TunefyColors.darkCard, borderRadius: BorderRadius.circular(6)),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: albumImg.isNotEmpty && !albumImg.startsWith('images/')
                    ? CachedNetworkImage(
                        imageUrl: albumImg, fit: BoxFit.cover,
                        placeholder: (_, __) => Container(color: TunefyColors.darkCard),
                        errorWidget: (_, __, ___) => const Center(child: Icon(Icons.album, color: TunefyColors.grey, size: 32)),
                      )
                    : Image.asset(
                        album.image, fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => const Center(child: Icon(Icons.album, color: TunefyColors.grey, size: 32)),
                      ),
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(width: w * 0.38, child: Text(album.title,
              style: const TextStyle(fontFamily: 'AB', fontSize: 12, color: TunefyColors.white),
              maxLines: 1, overflow: TextOverflow.ellipsis)),
            const SizedBox(height: 2),
            SizedBox(width: w * 0.38, child: Text('${album.artist} • ${album.year}',
              style: const TextStyle(fontFamily: 'AM', fontSize: 11, color: TunefyColors.grey),
              maxLines: 1, overflow: TextOverflow.ellipsis)),
          ],
        ),
      ),
    );
  }

  Widget _buildMiniPlayer() {
    return ValueListenableBuilder<HomeTrack?>(
      valueListenable: globalActiveTrack,
      builder: (ctx, track, _) {
        final displayTitle = track?.title ?? _trackName(_currentTrackIndex);
        final displayArtist = track?.artist ?? _artistName(_currentTrackIndex);
        final deezerUrl = track?.imageUrl ?? '';
        final localImg = artistImage(displayArtist);
        final hasTrack = track != null;
        return ValueListenableBuilder<bool>(
          valueListenable: globalIsPlaying,
          builder: (ctx, playing, _) {
            return GestureDetector(
              onTap: () { haptic(); _showFullPlayer(context); },
              child: Container(
                decoration: BoxDecoration(
                  color: TunefyColors.miniPlayerBg,
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.5), blurRadius: 12, offset: const Offset(0, 4))],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                     SizedBox(
                      height: 58,
                      child: Row(
                        children: [
                          const SizedBox(width: 4),
                          SizedBox(
                            width: 46,
                            height: 46,
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(6),
                              child: hasTrack
                                  ? (deezerUrl.isNotEmpty
                                      ? CachedNetworkImage(imageUrl: deezerUrl, width: 46, height: 46, fit: BoxFit.cover,
                                          placeholder: (_, __) => Container(width: 46, height: 46, color: TunefyColors.darkCard),
                                          errorWidget: (_, __, ___) => _miniFallback(localImg))
                                      : Image.asset('assets/tracks/${track.videoId}.jpg',
                                          width: 46, height: 46, fit: BoxFit.cover,
                                          errorBuilder: (_, __, ___) => _miniFallback(localImg)))
                                  : Container(width: 46, height: 46, color: TunefyColors.darkCard,
                                      child: const Icon(Icons.music_note, color: TunefyColors.grey, size: 20)),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(displayTitle, style: TextStyle(
                                  fontFamily: 'AB', fontSize: 13,
                                  color: hasTrack && playing ? TunefyColors.green : TunefyColors.white,
                                ), maxLines: 1, overflow: TextOverflow.ellipsis),
                                Text(displayArtist, style: const TextStyle(fontFamily: 'AM', fontSize: 11, color: TunefyColors.grey),
                                  maxLines: 1, overflow: TextOverflow.ellipsis),
                              ],
                            ),
                          ),
                           if (hasTrack) ...[
                            GestureDetector(
                              onTap: () async {
                                haptic();
                                final trackModel = Track(videoId: track.videoId, title: track.title, artist: track.artist, albumImage: track.imageUrl);
                                final likedService = LikedService();
                                await likedService.toggle(trackModel);
                                if (mounted) setState(() {});
                              },
                              child: Icon(
                                LikedService().isLiked(track.videoId) ? Icons.check_circle : Icons.add_circle_outline,
                                color: LikedService().isLiked(track.videoId) ? TunefyColors.green : TunefyColors.white,
                                size: 22,
                              ),
                            ),
                            const SizedBox(width: 16),
                            GestureDetector(
                              onTap: () { haptic(); DeviceSheet.show(context); },
                              child: const Icon(Icons.speaker, color: TunefyColors.white, size: 22),
                            ),
                            const SizedBox(width: 16),
                            GestureDetector(onTap: () {
                              haptic();
                              _togglePlay();
                            },
                              child: Icon(playing ? Icons.pause_rounded : Icons.play_arrow_rounded, color: TunefyColors.white, size: 26)),
                            const SizedBox(width: 12),
                          ],
                        ],
                      ),
                    ),
                    if (hasTrack)
                      StreamBuilder<Duration>(
                        stream: playerProvider.player.positionStream,
                        builder: (ctx, posSnap) {
                          final pos = posSnap.data ?? Duration.zero;
                          return StreamBuilder<Duration?>(
                            stream: playerProvider.player.durationStream,
                            builder: (ctx, durSnap) {
                              final dur = durSnap.data ?? Duration.zero;
                              final progress = dur.inSeconds > 0 ? (pos.inSeconds / dur.inSeconds).clamp(0.0, 1.0) : 0.0;
                              return Container(
                                height: 2,
                                margin: const EdgeInsets.symmetric(horizontal: 4),
                                child: LinearProgressIndicator(
                                  value: progress,
                                  backgroundColor: TunefyColors.darkCard,
                                  valueColor: const AlwaysStoppedAnimation<Color>(TunefyColors.white),
                                  minHeight: 2,
                                ),
                              );
                            },
                          );
                        },
                      ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _miniFallback(String? localImg) {
    if (localImg != null) {
      return Image.asset(localImg, width: 46, height: 46, fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => Container(width: 46, height: 46, color: TunefyColors.darkCard,
          child: const Icon(Icons.music_note, color: TunefyColors.grey, size: 20)));
    }
    return Container(width: 46, height: 46, color: TunefyColors.darkCard,
      child: const Icon(Icons.music_note, color: TunefyColors.grey, size: 20));
  }

  Widget _buildBottomNavBar() {
    return Container(
      height: 64,
      color: TunefyColors.black,
      child: SafeArea(
        top: false,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _navItem(0, 'images/icon_home.png', 'images/icon_home_active.png', 'Home'),
            _navItem(1, 'images/icon_search_bottomnav.png', 'images/icon_search_active.png', 'Search'),
            _navItem(2, 'images/icon_library.png', 'images/icon_library_active.png', 'Your Library'),
          ],
        ),
      ),
    );
  }

  Widget _navItem(int index, String iconPath, String activeIconPath, String label) {
    final isActive = _currentTab == index;
    return GestureDetector(
      onTap: () { haptic(); setState(() => _currentTab = index); },
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: 80,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(
              isActive ? activeIconPath : iconPath,
              width: 24,
              height: 24,
              color: TunefyColors.white,
            ),
            const SizedBox(height: 4),
            Text(label, style: TextStyle(
              fontFamily: 'AM', fontSize: 13,
              color: isActive ? const Color(0xFFE5E5E5) : TunefyColors.lightGrey,
            )),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchTab() {
    return SafeArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Recherche', style: TextStyle(
                  fontFamily: 'AB', fontSize: 24, color: TunefyColors.white, fontWeight: FontWeight.w800,
                )),
                GestureDetector(
                  onTap: () async {
                    haptic();
                    final result = await Navigator.push<String>(context, MaterialPageRoute(
                      builder: (_) => const QrScannerScreen(),
                    ));
                    if (result != null && result.isNotEmpty && mounted) {
                      Navigator.push(context, MaterialPageRoute(
                        builder: (_) => EmbeddedSearchScreen(initialQuery: result),
                      ));
                    }
                  },
                  child: Container(
                    width: 40, height: 40,
                    decoration: BoxDecoration(
                      color: TunefyColors.darkCard,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Icon(Icons.camera_alt_outlined, color: TunefyColors.white, size: 20),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
            child: GestureDetector(
              onTap: () {
                haptic();
                Navigator.push(context, MaterialPageRoute(
                  builder: (_) => const EmbeddedSearchScreen(),
                ));
              },
              child: Container(
                height: 48,
                decoration: BoxDecoration(color: TunefyColors.white, borderRadius: BorderRadius.circular(8)),
                child: const Row(
                  children: [
                    SizedBox(width: 14),
                    Icon(Icons.search, color: TunefyColors.black, size: 22),
                    SizedBox(width: 10),
                    Text('Que souhaitez-vous écouter ?', style: TextStyle(
                      fontFamily: 'AM', fontSize: 15, color: TunefyColors.darkGrey,
                    )),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2, mainAxisSpacing: 12, crossAxisSpacing: 12, childAspectRatio: 1.65,
              ),
              itemCount: _categories.length,
              itemBuilder: (context, i) => GestureDetector(
                onTap: () {
                  haptic();
                  Navigator.push(context, MaterialPageRoute(
                    builder: (_) => EmbeddedSearchScreen(initialQuery: _categories[i]),
                  ));
                },
                child: Container(
                  decoration: BoxDecoration(
                    color: _categoryColors[i % _categoryColors.length],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Stack(
                    children: [
                      Positioned(
                        top: 12, left: 14,
                        child: Text(_categories[i], style: const TextStyle(
                          fontFamily: 'AB', fontSize: 15, color: TunefyColors.white, fontWeight: FontWeight.w700,
                        )),
                      ),
                      Positioned(
                        bottom: -10, right: -10,
                        child: Transform.rotate(
                          angle: 0.4,
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(6),
                            child: CachedNetworkImage(
                              imageUrl: 'https://picsum.photos${_categoryImages[i]}',
                              width: 85, height: 85, fit: BoxFit.cover,
                              errorWidget: (_, __, ___) => Container(
                                width: 85, height: 85, color: Colors.black12,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLibraryTab() {
    return SafeArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 16, 16, 16),
            child: Text('Votre Bibliothèque', style: TextStyle(
              fontFamily: 'AB', fontSize: 24, color: TunefyColors.white, fontWeight: FontWeight.w800,
            )),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: TunefyColors.darkCard, borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.swap_vert, color: TunefyColors.white, size: 16),
                      SizedBox(width: 6),
                      Text('Récents', style: TextStyle(fontFamily: 'AM', fontSize: 13, color: TunefyColors.white)),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: TunefyColors.darkCard, borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text('Playlists', style: TextStyle(fontFamily: 'AM', fontSize: 13, color: TunefyColors.white)),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: _libraryItemCount,
              itemBuilder: (context, index) => _buildLibraryItemAtIndex(index),
            ),
          ),
        ],
      ),
    );
  }

  int get _libraryItemCount {
    int count = 0;
    if (_likedCount > 0) count++;
    count += 5;
    return count;
  }

  Widget _buildLibraryItemAtIndex(int index) {
    int idx = 0;

    if (_likedCount > 0) {
      if (idx == index) return _buildLikedSongsTile();
      idx++;
    }

    if (idx == index) return const SizedBox(height: 8);
    idx++;
    if (idx == index) return const Divider(color: TunefyColors.darkCard);
    idx++;
    if (idx == index) return _buildLibraryItem(Icons.queue_music, 'Playlists', '${AlbumCatalog.playlists.length} playlists', false, onTap: _navigateToPlaylists);
    idx++;
    if (idx == index) return _buildLibraryItem(Icons.album, 'Albums', '${AlbumCatalog.playlistTracks.length} albums', false, onTap: _navigateToAlbums);
    idx++;
    if (idx == index) return _buildLibraryItem(Icons.person, 'Artistes', 'Artistes suivis', false, onTap: _navigateToArtists);
    idx++;
    if (idx == index) return const SizedBox(height: 100);
    return const SizedBox.shrink();
  }

  void _navigateToPlaylists() {
    final allPlaylists = AlbumCatalog.playlists;
    showModalBottomSheet(
      context: context,
      backgroundColor: TunefyColors.black,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.85, maxChildSize: 0.95, minChildSize: 0.5,
        expand: false,
        builder: (ctx, scrollCtrl) => Column(
          children: [
            Center(child: Container(width: 36, height: 4, margin: const EdgeInsets.only(top: 12, bottom: 16),
              decoration: BoxDecoration(color: TunefyColors.grey.withValues(alpha: 0.3), borderRadius: BorderRadius.circular(2)))),
            const Padding(
              padding: EdgeInsets.fromLTRB(20, 0, 20, 16),
              child: Text('Playlists', style: TextStyle(
                fontFamily: 'AB', fontSize: 20, color: TunefyColors.white, fontWeight: FontWeight.w700)),
            ),
            Expanded(
              child: ListView.builder(
                controller: scrollCtrl,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: allPlaylists.length,
                itemBuilder: (ctx, i) {
                  final category = allPlaylists.keys.elementAt(i);
                  final playlists = allPlaylists[category]!;
                  return ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Container(width: 52, height: 52, decoration: BoxDecoration(
                      color: TunefyColors.darkCard, borderRadius: BorderRadius.circular(4)),
                      child: const Icon(Icons.queue_music, color: TunefyColors.white, size: 24)),
                    title: Text(category, style: const TextStyle(
                      fontFamily: 'AB', fontSize: 15, color: TunefyColors.white)),
                    subtitle: Text('${playlists.length} playlists', style: const TextStyle(
                      fontFamily: 'AM', fontSize: 12, color: TunefyColors.grey)),
                    trailing: const Icon(Icons.chevron_right, color: TunefyColors.grey, size: 22),
                    onTap: () {
                      haptic();
                      Navigator.pop(ctx);
                      if (playlists.isNotEmpty) {
                        final firstTitle = playlists.first['title'] ?? '';
                        final tracks = AlbumCatalog.playlistTracks[firstTitle] ?? [];
                        if (tracks.isNotEmpty) {
                          Navigator.push(context, MaterialPageRoute(
                            builder: (_) => CollectionDetailPage(
                              heroTrack: tracks.first,
                              allTracks: tracks,
                              albumTitle: firstTitle,
                              albumImage: playlists.first['img'],
                              isPlaylistView: true,
                              heroTrackList: tracks,
                            ),
                          ));
                        }
                      }
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

  void _navigateToAlbums() {
    final allAlbums = AlbumCatalog.playlistTracks;
    showModalBottomSheet(
      context: context,
      backgroundColor: TunefyColors.black,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.85, maxChildSize: 0.95, minChildSize: 0.5,
        expand: false,
        builder: (ctx, scrollCtrl) => Column(
          children: [
            Center(child: Container(width: 36, height: 4, margin: const EdgeInsets.only(top: 12, bottom: 16),
              decoration: BoxDecoration(color: TunefyColors.grey.withValues(alpha: 0.3), borderRadius: BorderRadius.circular(2)))),
            const Padding(
              padding: EdgeInsets.fromLTRB(20, 0, 20, 16),
              child: Text('Albums', style: TextStyle(
                fontFamily: 'AB', fontSize: 20, color: TunefyColors.white, fontWeight: FontWeight.w700)),
            ),
            Expanded(
              child: ListView.builder(
                controller: scrollCtrl,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: allAlbums.length,
                itemBuilder: (ctx, i) {
                  final title = allAlbums.keys.elementAt(i);
                  final tracks = allAlbums[title]!;
                  final img = tracks.isNotEmpty ? tracks.first.imageUrl : null;
                  return ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: ClipRRect(borderRadius: BorderRadius.circular(4),
                      child: img != null
                        ? CachedNetworkImage(imageUrl: img, width: 52, height: 52, fit: BoxFit.cover,
                            errorWidget: (_, __, ___) => Container(width: 52, height: 52, color: TunefyColors.darkCard,
                              child: const Icon(Icons.album, color: TunefyColors.grey, size: 24)))
                        : Container(width: 52, height: 52, color: TunefyColors.darkCard,
                            child: const Icon(Icons.album, color: TunefyColors.grey, size: 24))),
                    title: Text(title, style: const TextStyle(
                      fontFamily: 'AB', fontSize: 15, color: TunefyColors.white)),
                    subtitle: Text('${tracks.length} titres', style: const TextStyle(
                      fontFamily: 'AM', fontSize: 12, color: TunefyColors.grey)),
                    trailing: const Icon(Icons.chevron_right, color: TunefyColors.grey, size: 22),
                    onTap: () {
                      haptic();
                      Navigator.pop(ctx);
                      if (tracks.isNotEmpty) {
                        Navigator.push(context, MaterialPageRoute(
                          builder: (_) => CollectionDetailPage(
                            heroTrack: tracks.first,
                            allTracks: tracks,
                            albumTitle: title,
                            albumImage: img,
                            isPlaylistView: true,
                            heroTrackList: tracks,
                          ),
                        ));
                      }
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

  void _navigateToArtists() {
    final artists = <String, String>{};
    for (final tracks in AlbumCatalog.playlistTracks.values) {
      for (final t in tracks) {
        if (!artists.containsKey(t.artist)) {
          artists[t.artist] = t.imageUrl ?? '';
        }
      }
    }
    showModalBottomSheet(
      context: context,
      backgroundColor: TunefyColors.black,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.85, maxChildSize: 0.95, minChildSize: 0.5,
        expand: false,
        builder: (ctx, scrollCtrl) => Column(
          children: [
            Center(child: Container(width: 36, height: 4, margin: const EdgeInsets.only(top: 12, bottom: 16),
              decoration: BoxDecoration(color: TunefyColors.grey.withValues(alpha: 0.3), borderRadius: BorderRadius.circular(2)))),
            const Padding(
              padding: EdgeInsets.fromLTRB(20, 0, 20, 16),
              child: Text('Artistes', style: TextStyle(
                fontFamily: 'AB', fontSize: 20, color: TunefyColors.white, fontWeight: FontWeight.w700)),
            ),
            Expanded(
              child: ListView.builder(
                controller: scrollCtrl,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: artists.length,
                itemBuilder: (ctx, i) {
                  final name = artists.keys.elementAt(i);
                  final img = artists[name];
                  return ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: ClipRRect(borderRadius: BorderRadius.circular(26),
                      child: img != null && img.isNotEmpty
                        ? CachedNetworkImage(imageUrl: img, width: 52, height: 52, fit: BoxFit.cover,
                            errorWidget: (_, __, ___) => Container(width: 52, height: 52, color: TunefyColors.darkCard,
                              child: const Icon(Icons.person, color: TunefyColors.grey, size: 24)))
                        : Container(width: 52, height: 52, color: TunefyColors.darkCard,
                            child: const Icon(Icons.person, color: TunefyColors.grey, size: 24))),
                    title: Text(name, style: const TextStyle(
                      fontFamily: 'AB', fontSize: 15, color: TunefyColors.white)),
                    trailing: const Icon(Icons.chevron_right, color: TunefyColors.grey, size: 22),
                    onTap: () {
                      haptic();
                      Navigator.pop(ctx);
                      Navigator.push(context, MaterialPageRoute(
                        builder: (_) => CollectionDetailPage(
                          heroTrack: HomeTrack(videoId: '', title: name, artist: name, duration: ''),
                          allTracks: AlbumCatalog.playlistTracks.values.expand((l) => l).where((t) => t.artist == name).toList(),
                        ),
                      ));
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

  Widget _buildLikedSongsTile() {
    _refreshLikedCount();
    final likedTracks = LikedService().getAll();
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Container(
        width: 52, height: 52,
        decoration: BoxDecoration(
          gradient: const LinearGradient(colors: [Color(0xFF450AF5), Color(0xFF8E8EE5)], begin: Alignment.topLeft, end: Alignment.bottomRight),
          borderRadius: BorderRadius.circular(4),
        ),
        child: const Icon(Icons.favorite, color: TunefyColors.white, size: 24),
      ),
      title: Text('Titres likés', style: const TextStyle(
        fontFamily: 'AB', fontSize: 16, color: TunefyColors.white, fontWeight: FontWeight.w600,
      )),
      subtitle: Text('${likedTracks.length} titres', style: const TextStyle(
        fontFamily: 'AM', fontSize: 13, color: TunefyColors.grey,
      )),
      trailing: const Icon(Icons.chevron_right, color: TunefyColors.grey, size: 22),
      onTap: () {
        haptic();
        Navigator.push(context, MaterialPageRoute(
          builder: (_) => LikedTracksPage(tracks: likedTracks),
        ));
      },
    );
  }

  Widget _buildLibraryItem(IconData icon, String title, String subtitle, bool isRounded, {VoidCallback? onTap}) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Container(
        width: 52, height: 52,
        decoration: BoxDecoration(
          color: TunefyColors.darkCard,
          borderRadius: isRounded ? BorderRadius.circular(26) : BorderRadius.circular(4),
        ),
        child: Icon(icon, color: TunefyColors.white, size: 24),
      ),
      title: Text(title, style: const TextStyle(
        fontFamily: 'AB', fontSize: 16, color: TunefyColors.white, fontWeight: FontWeight.w600,
      )),
      subtitle: Text(subtitle, style: const TextStyle(
        fontFamily: 'AM', fontSize: 13, color: TunefyColors.grey,
      )),
      trailing: const Icon(Icons.chevron_right, color: TunefyColors.grey, size: 22),
      onTap: onTap != null ? () { haptic(); onTap(); } : null,
    );
  }

  Widget _fullPlayerFallback(String? localImg) {
    if (localImg != null) {
      return Image.asset(localImg, fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => Container(color: TunefyColors.darkCard,
          child: const Icon(Icons.music_note, color: TunefyColors.grey, size: 64)));
    }
    return Container(color: TunefyColors.darkCard,
      child: const Icon(Icons.music_note, color: TunefyColors.grey, size: 64));
  }

  void _showDevicesSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF181818),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Center(child: Container(
              width: 36, height: 4, margin: const EdgeInsets.only(top: 12, bottom: 16),
              decoration: BoxDecoration(color: TunefyColors.grey.withValues(alpha: 0.3), borderRadius: BorderRadius.circular(2)),
            )),
            const Padding(
              padding: EdgeInsets.fromLTRB(20, 0, 20, 16),
              child: Text('Appareils disponibles', style: TextStyle(
                fontFamily: 'AB', fontSize: 18, color: TunefyColors.white, fontWeight: FontWeight.w700)),
            ),
            ListTile(
              leading: Container(
                width: 44, height: 44,
                decoration: const BoxDecoration(color: TunefyColors.green, shape: BoxShape.circle),
                child: const Icon(Icons.smartphone, color: TunefyColors.white, size: 22),
              ),
              title: const Text('Cet appareil', style: TextStyle(fontFamily: 'AB', fontSize: 15, color: TunefyColors.white)),
              subtitle: const Text('En lecture', style: TextStyle(fontFamily: 'AM', fontSize: 12, color: TunefyColors.green)),
              trailing: const Icon(Icons.check_circle, color: TunefyColors.green, size: 22),
            ),
            ListTile(
              leading: Container(
                width: 44, height: 44,
                decoration: BoxDecoration(color: TunefyColors.darkCard, borderRadius: BorderRadius.circular(22)),
                child: const Icon(Icons.speaker, color: TunefyColors.grey, size: 22),
              ),
              title: const Text('Tunefy Connect', style: TextStyle(fontFamily: 'AB', fontSize: 15, color: TunefyColors.grey)),
              subtitle: const Text('Non disponible', style: TextStyle(fontFamily: 'AM', fontSize: 12, color: TunefyColors.darkGrey)),
            ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Container(
                width: double.infinity, height: 48,
                decoration: BoxDecoration(
                  color: TunefyColors.darkCard,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: const Center(
                  child: Text('Lancer un Jam', style: TextStyle(fontFamily: 'AB', fontSize: 14, color: TunefyColors.grey)),
                ),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  void _showFullPlayer(BuildContext context) {
    final activeTrack = globalActiveTrack.value;
    bool isLiked = activeTrack != null ? LikedService().isLiked(activeTrack.videoId) : false;
    final displayTitle = activeTrack?.title ?? _trackName(_currentTrackIndex);
    final displayArtist = activeTrack?.artist ?? _artistName(_currentTrackIndex);
    final deezerUrl = activeTrack?.imageUrl ?? '';
    final localImg = artistImage(displayArtist);
    showModalBottomSheet(
      context: context,
      backgroundColor: TunefyColors.black,
      isScrollControlled: true,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) {
          final pp = playerProvider;
          return ListenableBuilder(
            listenable: pp,
            builder: (ctx, _) {
              final playing = pp.isPlaying;
              final pos = pp.position;
              final dur = pp.duration;
              return SizedBox(
                height: MediaQuery.of(context).size.height * 0.92,
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      const SizedBox(height: 12),
                      Center(child: Container(
                        width: 36, height: 4,
                        decoration: BoxDecoration(color: TunefyColors.grey.withValues(alpha: 0.3), borderRadius: BorderRadius.circular(2)),
                      )),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          const SizedBox(width: 16),
                          GestureDetector(
                            onTap: () { haptic(); Navigator.pop(ctx); },
                            child: const Icon(Icons.keyboard_arrow_down, color: TunefyColors.white, size: 28),
                          ),
                          const Spacer(),
                          const Column(
                            children: [
                              Text('En lecture', style: TextStyle(fontFamily: 'AM', fontSize: 11, color: TunefyColors.grey)),
                              Text('Lecture en cours sur cet appareil', style: TextStyle(fontFamily: 'AM', fontSize: 9, color: TunefyColors.grey)),
                            ],
                          ),
                          const Spacer(),
                          GestureDetector(
                            onTap: () {
                              haptic();
                              if (activeTrack == null) return;
                              _showFullPlayerMenu(context, activeTrack, setSheetState);
                            },
                            child: const Icon(Icons.more_vert, color: TunefyColors.white, size: 24),
                          ),
                          const SizedBox(width: 16),
                        ],
                      ),
                      const SizedBox(height: 24),
                      Center(
                        child: Container(
                          width: MediaQuery.of(context).size.width * 0.78,
                          height: MediaQuery.of(context).size.width * 0.78,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(color: TunefyColors.green.withValues(alpha: 0.2), blurRadius: 50, offset: const Offset(0, 20)),
                            ],
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: activeTrack != null
                                ? (deezerUrl.isNotEmpty
                                    ? CachedNetworkImage(imageUrl: deezerUrl, fit: BoxFit.cover,
                                        placeholder: (_, __) => Container(color: TunefyColors.darkCard),
                                        errorWidget: (_, __, ___) => _fullPlayerFallback(localImg))
                                    : Image.asset('assets/tracks/${activeTrack!.videoId}.jpg',
                                        fit: BoxFit.cover,
                                        errorBuilder: (_, __, ___) => _fullPlayerFallback(localImg)))
                                : _fullPlayerFallback(localImg),
                          ),
                        ),
                      ),
                      SizedBox(height: MediaQuery.of(context).size.height * 0.04),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(displayTitle, style: TextStyle(
                                    fontFamily: 'AB', fontSize: 22,
                                    color: playing ? TunefyColors.green : TunefyColors.white,
                                    fontWeight: FontWeight.w700,
                                  ), maxLines: 1, overflow: TextOverflow.ellipsis),
                                  const SizedBox(height: 4),
                                  Text(displayArtist, style: const TextStyle(
                                    fontFamily: 'AM', fontSize: 15, color: TunefyColors.grey,
                                  )),
                                  const SizedBox(height: 6),
                                ],
                              ),
                            ),
                            GestureDetector(
                              onTap: () {
                                haptic();
                                setSheetState(() {
                                  isLiked = !isLiked;
                                  if (activeTrack != null) {
                                    final trackModel = Track(
                                      videoId: activeTrack!.videoId,
                                      title: activeTrack!.title,
                                      artist: activeTrack!.artist,
                                      albumImage: activeTrack!.imageUrl,
                                    );
                                    if (isLiked) {
                                      LikedService().add(trackModel);
                                    } else {
                                      LikedService().remove(activeTrack!.videoId);
                                    }
                                  }
                                });
                              },
                              child: Icon(
                                isLiked ? Icons.favorite : Icons.favorite_border,
                                color: isLiked ? TunefyColors.green : TunefyColors.grey, size: 28,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: Column(
                          children: [
                            SliderTheme(
                              data: SliderTheme.of(context).copyWith(trackHeight: 3, thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 5)),
                              child: Slider(
                                value: dur.inMilliseconds > 0 ? pos.inMilliseconds.toDouble().clamp(0.0, dur.inMilliseconds.toDouble()) : 0,
                                max: dur.inMilliseconds > 0 ? dur.inMilliseconds.toDouble() : 1,
                                onChanged: (v) => pp.seek(Duration(milliseconds: v.toInt())),
                                activeColor: TunefyColors.white,
                                inactiveColor: TunefyColors.darkGrey,
                              ),
                            ),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(_formatDuration(pos), style: TextStyle(fontFamily: 'AM', fontSize: 11, color: TunefyColors.white.withValues(alpha: 0.6))),
                                Text(_formatDuration(dur), style: TextStyle(fontFamily: 'AM', fontSize: 11, color: TunefyColors.white.withValues(alpha: 0.6))),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          GestureDetector(
                            onTap: () { haptic(); _toggleShuffle(); },
                            child: Icon(Icons.shuffle, color: _isShuffle ? TunefyColors.green : TunefyColors.grey, size: 24),
                          ),
                          GestureDetector(
                            onTap: () { haptic(); pp.skipToPrevious(); },
                            child: const Icon(Icons.skip_previous_rounded, color: TunefyColors.white, size: 36),
                          ),
                          GestureDetector(
                            onTap: () {
                              haptic();
                              _togglePlay();
                            },
                            child: Container(
                              width: 68, height: 68,
                              decoration: const BoxDecoration(color: TunefyColors.green, shape: BoxShape.circle),
                              child: Icon(
                                playing ? Icons.pause_rounded : Icons.play_arrow_rounded,
                                color: TunefyColors.white, size: 38,
                              ),
                            ),
                          ),
                          GestureDetector(
                            onTap: () { haptic(); pp.skipToNext(); },
                            child: const Icon(Icons.skip_next_rounded, color: TunefyColors.white, size: 36),
                          ),
                          GestureDetector(
                            onTap: () { haptic(); _toggleRepeat(); },
                            child: Icon(Icons.repeat, color: _isRepeat ? TunefyColors.green : TunefyColors.grey, size: 24),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 40),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            GestureDetector(
                              onTap: () { haptic(); _showDevicesSheet(context); },
                              child: const Icon(Icons.devices_outlined, color: TunefyColors.grey, size: 20),
                            ),
                            GestureDetector(
                              onTap: () {
                                haptic();
                                final track = activeTrack;
                                if (track != null) {
                                  Share.share('${track.title} - ${track.artist}');
                                }
                              },
                              child: const Icon(Icons.share_outlined, color: TunefyColors.grey, size: 20),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 32),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  void _showFullPlayerMenu(BuildContext context, HomeTrack activeTrack, StateSetter setSheetState) {
    showModalBottomSheet(
      context: context,
      backgroundColor: TunefyColors.black,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Center(child: Container(width: 36, height: 4, margin: const EdgeInsets.only(top: 12, bottom: 16),
              decoration: BoxDecoration(color: TunefyColors.grey.withValues(alpha: 0.3), borderRadius: BorderRadius.circular(2)))),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  ClipRRect(borderRadius: BorderRadius.circular(6),
                    child: img(activeTrack.imageUrl ?? '', w: 48, h: 48, err: (_, __, ___) => Container(
                      width: 48, height: 48, color: TunefyColors.darkCard,
                      child: const Icon(Icons.music_note, color: TunefyColors.grey, size: 20)))),
                  const SizedBox(width: 12),
                  Expanded(child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(activeTrack.title, style: const TextStyle(fontFamily: 'AB', fontSize: 14, color: TunefyColors.white),
                        maxLines: 1, overflow: TextOverflow.ellipsis),
                      Text(activeTrack.artist, style: const TextStyle(fontFamily: 'AM', fontSize: 12, color: TunefyColors.grey),
                        maxLines: 1, overflow: TextOverflow.ellipsis),
                    ],
                  )),
                ],
              ),
            ),
            const SizedBox(height: 8),
            _fullPlayerMenuItem(Icons.share_outlined, 'Partager', () {
              Share.share('${activeTrack.title} - ${activeTrack.artist}');
              Navigator.pop(ctx);
            }),
            _fullPlayerMenuItem(Icons.favorite_border, LikedService().isLiked(activeTrack.videoId) ? 'Retiré des Titres likés' : 'Ajouter aux Titres likés', () {
              final trackModel = Track(videoId: activeTrack.videoId, title: activeTrack.title, artist: activeTrack.artist, albumImage: activeTrack.imageUrl);
              LikedService().toggle(trackModel);
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                content: const Text('Mis à jour', style: TextStyle(fontFamily: 'AM', color: TunefyColors.white)),
                backgroundColor: TunefyColors.darkCard, duration: const Duration(seconds: 1),
                behavior: SnackBarBehavior.floating, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ));
            }),
            _fullPlayerMenuItem(Icons.playlist_add, 'Ajouter à la playlist', () {
              Navigator.pop(ctx);
              AddToPlaylistSheet.show(context, Track(
                videoId: activeTrack.videoId, title: activeTrack.title, artist: activeTrack.artist, albumImage: activeTrack.imageUrl,
              ));
            }),
            _fullPlayerMenuItem(Icons.queue_music, 'Ajouter à la file d\'attente', () {
              Navigator.pop(ctx);
              final trackModel = Track(videoId: activeTrack.videoId, title: activeTrack.title, artist: activeTrack.artist, albumImage: activeTrack.imageUrl, duration: parseDuration(activeTrack.duration));
              playerProvider.addToQueue(trackModel);
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                content: Text('${activeTrack.title} ajouté à la file d\'attente',
                  style: const TextStyle(fontFamily: 'AM', color: TunefyColors.white)),
                backgroundColor: TunefyColors.darkCard, duration: const Duration(seconds: 1),
                behavior: SnackBarBehavior.floating, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ));
            }),
            _fullPlayerMenuItem(Icons.album_outlined, 'Accéder à l\'album', () {
              Navigator.pop(ctx);
              Navigator.push(context, MaterialPageRoute(
                builder: (_) => CollectionDetailPage(
                  heroTrack: HomeTrack(videoId: activeTrack.videoId, title: activeTrack.title, artist: activeTrack.artist,
                    duration: activeTrack.duration, imageUrl: activeTrack.imageUrl),
                  allTracks: HomeData.sections.expand((s) => s.tracks).toList(),
                  albumTitle: activeTrack.artist, albumImage: activeTrack.imageUrl, isAlbumView: true,
                ),
              ));
            }),
            _fullPlayerMenuItem(Icons.person_outline, 'Accéder aux artistes', () {
              Navigator.pop(ctx);
              Navigator.push(context, MaterialPageRoute(
                builder: (_) => CollectionDetailPage(
                  heroTrack: HomeTrack(videoId: activeTrack.videoId, title: activeTrack.title, artist: activeTrack.artist,
                    duration: activeTrack.duration, imageUrl: activeTrack.imageUrl),
                  allTracks: HomeData.sections.expand((s) => s.tracks).toList(),
                ),
              ));
            }),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Widget _fullPlayerMenuItem(IconData icon, String label, VoidCallback onTap) {
    return ListTile(
      leading: Icon(icon, color: TunefyColors.white, size: 24),
      title: Text(label, style: const TextStyle(fontFamily: 'AM', fontSize: 14, color: TunefyColors.white)),
      onTap: () { haptic(); onTap(); },
    );
  }
}

const List<String> _categories = [
  'Pop', 'Hip-Hop', 'Rock', 'Latin', 'Humeur', 'Dance/Electro',
  'Indie', 'Sport', 'Country', 'R&B', 'K-Pop', 'Détente',
  'Sommeil', 'Fête', 'Romance', 'Concentration',
  'Jazz', 'Classique', 'Metal', 'Reggaeton',
  'Afrobeats', 'Gaming', 'Anime', 'Charts',
  'Par décennies', 'Comédie', 'Chanteur-auteur', 'Ambient',
  'Reggae', 'Blues',
];

const List<Color> _categoryColors = [
  Color(0xFF148A08), Color(0xFFBA5D07), Color(0xFFE91429), Color(0xFFE1118C),
  Color(0xFF477D95), Color(0xFF0D73EC),
  Color(0xFF608108), Color(0xFF777777), Color(0xFFB06239), Color(0xFF8D67AB),
  Color(0xFF0D73EC), Color(0xFF509BF5),
  Color(0xFF1E3264), Color(0xFFE13300), Color(0xFFDB0059), Color(0xFF503D58),
  Color(0xFF477D95), Color(0xFF7D4B32), Color(0xFF537AA1), Color(0xFFE1118C),
  Color(0xFF148A08), Color(0xFF503D58), Color(0xFFE13300), Color(0xFF8D67AB),
  Color(0xFF8D67AB), Color(0xFFE13300), Color(0xFFBA5D07), Color(0xFF509BF5),
  Color(0xFF608108), Color(0xFF477D95),
];

const List<String> _categoryImages = [
  '/id/1080/200/200', '/id/1012/200/200', '/id/1019/200/200', '/id/1025/200/200',
  '/id/1035/200/200', '/id/1044/200/200',
  '/id/1043/200/200', '/id/1060/200/200', '/id/1058/200/200', '/id/1062/200/200',
  '/id/1074/200/200', '/id/1015/200/200',
  '/id/1045/200/200', '/id/1059/200/200', '/id/1027/200/200', '/id/1069/200/200',
  '/id/1056/200/200', '/id/1048/200/200', '/id/1065/200/200', '/id/1070/200/200',
  '/id/1084/200/200', '/id/1083/200/200', '/id/1079/200/200', '/id/1064/200/200',
  '/id/1040/200/200', '/id/1067/200/200', '/id/1028/200/200', '/id/1036/200/200',
  '/id/1039/200/200', '/id/1047/200/200',
];

class _SpotifyConnectIcon extends StatelessWidget {
  final Color color;
  final double size;
  const _SpotifyConnectIcon({required this.color, required this.size});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(size, size),
      painter: _SpotifyConnectPainter(color: color),
    );
  }
}

class _SpotifyConnectPainter extends CustomPainter {
  final Color color;
  _SpotifyConnectPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final strokePaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4
      ..strokeCap = StrokeCap.round;

    final fillPaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final w = size.width;
    final h = size.height;

    final screenRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(0, 0, w * 0.7, h * 0.5),
      const Radius.circular(2),
    );
    canvas.drawRRect(screenRect, strokePaint);

    canvas.drawLine(
      Offset(w * 0.25, h * 0.5),
      Offset(w * 0.25, h * 0.65),
      strokePaint,
    );
    canvas.drawLine(
      Offset(w * 0.45, h * 0.5),
      Offset(w * 0.45, h * 0.65),
      strokePaint,
    );

    final baseRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(w * 0.12, h * 0.65, w * 0.46, h * 0.07),
      const Radius.circular(1),
    );
    canvas.drawRRect(baseRect, fillPaint);

    final waveY = h * 0.85;
    final wavePaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      Rect.fromCenter(center: Offset(w * 0.35, waveY), width: w * 0.12, height: w * 0.12),
      3.14 * 0.8, 3.14 * 0.4, false, wavePaint,
    );
    canvas.drawArc(
      Rect.fromCenter(center: Offset(w * 0.35, waveY), width: w * 0.28, height: w * 0.28),
      3.14 * 0.8, 3.14 * 0.4, false, wavePaint,
    );
  }

  @override
  bool shouldRepaint(covariant _SpotifyConnectPainter oldDelegate) =>
      color != oldDelegate.color;
}
