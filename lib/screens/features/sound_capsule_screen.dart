import 'dart:io';
import 'dart:ui' as ui;
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:muzo/l10n/app_localizations.dart';
import 'package:muzo/services/listening_stats_service.dart';
import 'package:muzo/services/storage_service.dart';
import 'package:muzo/utils/format.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

const Color hivefyBg = Color(0xFF121212);
const Color hivefyGreen = Color(0xFF1DDA63);

Color _darkerGreen(Color color, {double darkenFactor = 0.18}) {
  final hsl = HSLColor.fromColor(color);
  final newLight = (hsl.lightness - darkenFactor).clamp(0.12, 1.0);
  final newSat = (hsl.saturation + 0.1).clamp(0.0, 1.0);
  return hsl.withLightness(newLight).withSaturation(newSat).toColor();
}

class SoundCapsuleScreen extends ConsumerStatefulWidget {
  const SoundCapsuleScreen({super.key});

  @override
  ConsumerState<SoundCapsuleScreen> createState() => _SoundCapsuleScreenState();
}

class _SoundCapsuleScreenState extends ConsumerState<SoundCapsuleScreen> {
  final GlobalKey _shareKey = GlobalKey();
  bool _isTitleCollapsed = false;
  late ScrollController _scrollController;
  int _topLimit = 5;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController()
      ..addListener(() {
        final offset = _scrollController.offset;
        if (offset > 120 && !_isTitleCollapsed) {
          setState(() => _isTitleCollapsed = true);
        } else if (offset <= 120 && _isTitleCollapsed) {
          setState(() => _isTitleCollapsed = false);
        }
      });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  String get _monthYear {
    final now = DateTime.now();
    const months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December',
    ];
    return '${months[now.month - 1]} ${now.year}';
  }

  Future<File?> _capturePng() async {
    final boundary =
        _shareKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
    if (boundary == null) return null;
    final image = await boundary.toImage(pixelRatio: 2.0);
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    image.dispose();
    if (byteData == null) return null;
    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/sound_capsule.png');
    await file.writeAsBytes(byteData.buffer.asUint8List());
    return file;
  }

  Future<void> _openShareSheet() async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      await showModalBottomSheet<void>(
        context: context,
        backgroundColor: const Color(0xFF0F0F0F),
        isScrollControlled: true,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        builder: (sheetContext) => _ShareCardSheet(
          boundaryKey: _shareKey,
          card: _buildCapsuleCard(),
          onDownload: () => _downloadPng(sheetContext),
          onShare: () => _sharePng(sheetContext),
        ),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _downloadPng(BuildContext sheetContext) async {
    final file = await _capturePng();
    if (file == null) return;
    final docs = await getApplicationDocumentsDirectory();
    final saved = File('${docs.path}/sound_capsule.png');
    await saved.writeAsBytes(await file.readAsBytes());
    if (!mounted || !sheetContext.mounted) return;
    Navigator.of(sheetContext).pop();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('PNG saved to ${saved.path}'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _sharePng(BuildContext sheetContext) async {
    final file = await _capturePng();
    if (!mounted || !sheetContext.mounted) return;
    Navigator.of(sheetContext).pop();
    if (file == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not create image')),
      );
      return;
    }
    await Share.shareXFiles(
      [XFile(file.path, mimeType: 'image/png')],
      text: 'My Sound Capsule on Tunefy 🎧',
      subject: 'Tunefy Sound Capsule',
    );
  }

  Widget _buildCapsuleCard() {
    final storage = ref.read(storageServiceProvider);
    final stats = storage.stats;
    final topArtists = stats.topArtists(5);
    final topSongs = stats.topSongs(5);
    return _CapsuleShareCard(
      username: storage.username ?? 'Listener',
      monthYear: _monthYear,
      minutes: stats.minutesThisMonth,
      songs: stats.songsThisMonth,
      totalSongs: stats.totalSongs,
      topArtist: topArtists.isNotEmpty ? topArtists.first.name : '—',
      topSong: topSongs.isNotEmpty ? topSongs.first.name : '—',
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final storage = ref.watch(storageServiceProvider);
    final stats = storage.stats;

    return Scaffold(
      backgroundColor: hivefyBg,
      body: ValueListenableBuilder(
        valueListenable: stats.statsListenable,
        builder: (context, box, _) {
          final topSongs = stats.topSongs(_topLimit);
          final topArtists = stats.topArtists(_topLimit);
          final topAlbums = stats.topAlbums(_topLimit);
          final lovedAlbums = stats.topLovedAlbums(_topLimit);
          final genres = stats.topGenres(_topLimit);
          final hasStats = stats.totalSongs > 0;

          return CustomScrollView(
            controller: _scrollController,
            slivers: [
              _buildAppBar(context, l10n),
              if (!hasStats)
                _buildEmptyState(context, l10n)
              else ...[
                _buildSummary(context, l10n, stats),
                _buildStatsRow(context, l10n, stats),
                _buildActivity(context, l10n, stats),
                _buildTopSelector(context, l10n),
                if (topArtists.isNotEmpty)
                  _buildRankSection(context, l10n.yourTopArtists, topArtists),
                if (topSongs.isNotEmpty)
                  _buildRankSection(context, l10n.yourTopSongs, topSongs, image: true),
                if (topAlbums.isNotEmpty)
                  _buildRankSection(context, l10n.yourTopAlbums, topAlbums),
                if (lovedAlbums.isNotEmpty)
                  _buildRankSection(context, l10n.mostLoved, lovedAlbums,
                      subtitle: l10n.lovedAlbums),
                if (genres.isNotEmpty)
                  _buildRankSection(context, l10n.yourTopGenres, genres),
                _buildShareSection(context, l10n),
              ],
              const SliverToBoxAdapter(child: SizedBox(height: 100)),
            ],
          );
        },
      ),
    );
  }

  Widget _buildAppBar(BuildContext context, AppLocalizations l10n) {
    return SliverAppBar(
      pinned: true,
      expandedHeight: 160,
      elevation: 0,
      backgroundColor: _darkerGreen(hivefyGreen),
      leading: const BackButton(color: Colors.white),
      flexibleSpace: LayoutBuilder(
        builder: (context, constraints) {
          final rawCollapse = (constraints.maxHeight - kToolbarHeight) / 80.0;
          final collapsePercent = rawCollapse.clamp(0.0, 1.0);
          return FlexibleSpaceBar(
            centerTitle: false,
            titlePadding: EdgeInsets.only(
              left: _isTitleCollapsed ? 72 : 16,
              bottom: 16,
              right: 16,
            ),
            title: AnimatedOpacity(
              duration: const Duration(milliseconds: 200),
              opacity: _isTitleCollapsed ? 1.0 : 0.0,
              child: Text(
                l10n.soundCapsule,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 17,
                  letterSpacing: 0.3,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            background: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [_darkerGreen(hivefyGreen), hivefyBg],
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.only(left: 24, bottom: 32),
                child: Align(
                  alignment: Alignment.bottomLeft,
                  child: Opacity(
                    opacity: 0.95 * collapsePercent,
                    child: Text(
                      l10n.soundCapsule,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 28,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, AppLocalizations l10n) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 60),
        child: Column(
          children: [
            const Icon(Icons.music_note_rounded, color: hivefyGreen, size: 64),
            const SizedBox(height: 16),
            Text(
              l10n.noStatsYet,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              l10n.listenSomeMusic,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white54, fontSize: 14, height: 1.4),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummary(BuildContext context, AppLocalizations l10n, ListeningStatsService stats) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              _monthYear,
              style: const TextStyle(color: Colors.white54, fontSize: 14),
            ),
            const SizedBox(height: 16),
            Text(
              l10n.userListened,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.w500,
                height: 1.2,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              formatMinutes(stats.minutesThisMonth),
              style: const TextStyle(
                color: hivefyGreen,
                fontSize: 26,
                fontWeight: FontWeight.bold,
                height: 1.2,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '${stats.songsThisMonth} ${l10n.songsThisMonth}',
              style: const TextStyle(color: Colors.white54, fontSize: 14),
            ),
            const SizedBox(height: 20),
            Center(child: Container(height: 1, width: 120, color: Colors.white12)),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsRow(BuildContext context, AppLocalizations l10n, ListeningStatsService stats) {
    final items = [
      (l10n.totalMinutes, formatMinutes(stats.totalMinutes)),
      (l10n.totalSongs, '${stats.totalSongs}'),
      (l10n.totalArtists, '${stats.totalArtists}'),
      (l10n.totalAlbums, '${stats.totalAlbums}'),
    ];
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: items.map((item) {
            return Expanded(
              child: Column(
                children: [
                  Text(
                    item.$2,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    item.$1,
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.white54, fontSize: 11),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildActivity(BuildContext context, AppLocalizations l10n, ListeningStatsService stats) {
    final rows = [
      (l10n.thisWeek, formatMinutes(stats.minutesThisWeek), stats.songsThisWeek),
      (l10n.thisMonth, formatMinutes(stats.minutesThisMonth), stats.songsThisMonth),
      (l10n.thisYear, formatMinutes(stats.minutesThisYear), stats.songsThisYear),
    ];
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(left: 4, bottom: 8),
              child: Text(
                l10n.activity,
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            Container(
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.04),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  for (var i = 0; i < rows.length; i++) ...[
                    if (i > 0)
                      const Divider(height: 1, indent: 16, endIndent: 16, color: Colors.white12),
                    ListTile(
                      title: Text(
                        rows[i].$1,
                        style: const TextStyle(color: Colors.white, fontSize: 14),
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            rows[i].$2,
                            style: const TextStyle(
                              color: hivefyGreen,
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '${rows[i].$3} ${l10n.songs}',
                            style: const TextStyle(color: Colors.white38, fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopSelector(BuildContext context, AppLocalizations l10n) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Text(
              l10n.topSongs,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const Spacer(),
            Container(
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                children: [5, 10, 50].map((n) {
                  final selected = _topLimit == n;
                  return GestureDetector(
                    onTap: () => setState(() => _topLimit = n),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: selected ? hivefyGreen : Colors.transparent,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        'Top $n',
                        style: TextStyle(
                          color: selected ? Colors.black : Colors.white54,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRankSection(
    BuildContext context,
    String title,
    List<RankedItem> items, {
    bool image = false,
    String? subtitle,
  }) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              subtitle ?? title,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            if (subtitle != null) ...[
              const SizedBox(height: 4),
              Text(
                title,
                style: const TextStyle(color: Colors.white38, fontSize: 12),
              ),
            ],
            const SizedBox(height: 8),
            Container(
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.04),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  for (var i = 0; i < items.length; i++) ...[
                    if (i > 0)
                      const Divider(height: 1, indent: 52, endIndent: 16, color: Colors.white12),
                    _RankTile(rank: i + 1, item: items[i], image: image),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildShareSection(BuildContext context, AppLocalizations l10n) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.shareCard,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            RepaintBoundary(
              key: _shareKey,
              child: _buildCapsuleCard(),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _ActionButton(
                    icon: Icons.download,
                    label: l10n.downloadPng,
                    onTap: _busy ? null : _openShareSheet,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _ActionButton(
                    icon: Icons.share,
                    label: l10n.share,
                    onTap: _busy ? null : _openShareSheet,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _RankTile extends StatelessWidget {
  final int rank;
  final RankedItem item;
  final bool image;

  const _RankTile({required this.rank, required this.item, this.image = false});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        children: [
          SizedBox(
            width: 24,
            child: Text(
              '$rank',
              style: const TextStyle(
                color: Colors.white38,
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          if (image) ...[
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(6),
                color: Colors.grey.shade800,
                image: item.thumbnail != null && item.thumbnail!.isNotEmpty
                    ? DecorationImage(
                        image: CachedNetworkImageProvider(item.thumbnail!),
                        fit: BoxFit.cover,
                      )
                    : null,
              ),
              child: (item.thumbnail == null || item.thumbnail!.isEmpty)
                  ? const Icon(Icons.music_note, color: Colors.white38, size: 18)
                  : null,
            ),
            const SizedBox(width: 10),
          ],
          Expanded(
            child: Text(
              item.name,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            '${item.count}',
            style: const TextStyle(
              color: Colors.white54,
              fontSize: 13,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback? onTap;

  const _ActionButton({required this.icon, required this.label, this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: Colors.black, size: 18),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  label,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.black,
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ShareCardSheet extends StatelessWidget {
  final GlobalKey boundaryKey;
  final Widget card;
  final Future<void> Function() onDownload;
  final Future<void> Function() onShare;

  const _ShareCardSheet({
    required this.boundaryKey,
    required this.card,
    required this.onDownload,
    required this.onShare,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Share your capsule',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 12),
              RepaintBoundary(key: boundaryKey, child: card),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: onDownload,
                      icon: const Icon(Icons.download, size: 18),
                      label: const Text('Download PNG'),
                      style: FilledButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: Colors.black,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: onShare,
                      icon: const Icon(Icons.share, size: 18),
                      label: const Text('Share'),
                      style: FilledButton.styleFrom(
                        backgroundColor: hivefyGreen,
                        foregroundColor: Colors.black,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                alignment: WrapAlignment.center,
                children: [
                  _ShareTargetButton(icon: Icons.chat, label: 'WhatsApp', onTap: onShare),
                  _ShareTargetButton(icon: Icons.thumb_up, label: 'Facebook', onTap: onShare),
                  _ShareTargetButton(
                    icon: Icons.photo_camera,
                    label: 'Instagram',
                    onTap: onShare,
                  ),
                ],
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }
}

class _ShareTargetButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Future<void> Function() onTap;

  const _ShareTargetButton({required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: onTap,
      icon: Icon(icon, size: 18, color: Colors.white),
      label: Text(label, style: const TextStyle(color: Colors.white)),
      style: OutlinedButton.styleFrom(
        side: const BorderSide(color: Colors.white24),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
    );
  }
}

/// The shareable capsule card.
class _CapsuleShareCard extends StatelessWidget {
  final String username;
  final String monthYear;
  final int minutes;
  final int songs;
  final int totalSongs;
  final String topArtist;
  final String topSong;

  const _CapsuleShareCard({
    required this.username,
    required this.monthYear,
    required this.minutes,
    required this.songs,
    required this.totalSongs,
    required this.topArtist,
    required this.topSong,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF1A1A1A), Color(0xFF0E0E0E)],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: hivefyGreen.withValues(alpha: 0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: hivefyGreen,
                ),
                child: ClipOval(
                  child: Image.asset(
                    'assets/hivefy_icon.png',
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Tunefy',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  Text(
                    monthYear,
                    style: const TextStyle(color: Colors.white54, fontSize: 12),
                  ),
                ],
              ),
              const Spacer(),
              const Icon(Icons.bubble_chart, color: hivefyGreen, size: 28),
            ],
          ),
          const SizedBox(height: 18),
          Text(
            '$username · Sound Capsule',
            style: const TextStyle(color: Colors.white70, fontSize: 12),
          ),
          const SizedBox(height: 12),
          Text(
            formatMinutes(minutes),
            style: const TextStyle(
              color: hivefyGreen,
              fontSize: 40,
              fontWeight: FontWeight.bold,
              height: 1.0,
            ),
          ),
          Text(
            '$songs songs this month',
            style: const TextStyle(color: Colors.white54, fontSize: 13),
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: _cardStat('Total songs', '$totalSongs'),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _cardStat('Top artist', topArtist),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _cardStat('Top song', topSong),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _cardStat(String label, String value) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(color: Colors.white38, fontSize: 10),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 13,
              fontWeight: FontWeight.bold,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
