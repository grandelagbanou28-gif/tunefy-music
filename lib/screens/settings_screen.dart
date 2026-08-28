import 'package:disk_space_plus/disk_space_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

import 'package:muzo/services/storage_service.dart';
import 'package:muzo/screens/artist_database_debug_screen.dart';
import 'package:muzo/utils/app_colors.dart';

const Color _hivefyBgColor = Color(0xFF121212);
const Color _hivefyGreen = Color(0xFF1DDA63);

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  bool notificationsEnabled = false;
  bool _isTitleCollapsed = false;
  late ScrollController _scrollController;
  final DiskSpacePlus diskSpacePlus = DiskSpacePlus();
  late Future<List<dynamic>> _storageFuture;
  final String _selectedServer = 'Main Server';
  @override
  void initState() {
    super.initState();

    _scrollController =
        ScrollController()..addListener(() {
          final offset = _scrollController.offset;
          if (offset > 120 && !_isTitleCollapsed) {
            setState(() => _isTitleCollapsed = true);
          } else if (offset <= 120 && _isTitleCollapsed) {
            setState(() => _isTitleCollapsed = false);
          }
        });
    _checkNotificationStatus();
    _refreshStorageFuture();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _checkNotificationStatus() async {
    final status = await Permission.notification.status;
    if (mounted) setState(() => notificationsEnabled = status.isGranted);
  }

  Future<void> _requestNotificationPermission() async {
    final status = await Permission.notification.request();
    if (mounted) setState(() => notificationsEnabled = status.isGranted);
    if (!status.isGranted) openAppSettings();
  }

  Future<double> getDeviceStorageInBytes() async {
    try {
      // Total disk space in MB
      final totalMB = await diskSpacePlus.getTotalDiskSpace ?? 0;

      // Optional: free space in app directory
      final dir = await getApplicationDocumentsDirectory();
      final freeMB = await diskSpacePlus.getFreeDiskSpaceForPath(dir.path) ?? 0;

      debugPrint('--> free space $freeMB MB, total $totalMB MB');

      // Use totalMB if valid, otherwise fallback to 32 GB (converted to MB)
      final safeMB =
          (totalMB > 0 && totalMB < 1024 * 1024) ? totalMB : 32 * 1024;

      return safeMB * 1024 * 1024; // convert MB → bytes
    } catch (_) {
      return 32 * 1024 * 1024 * 1024; // fallback 32 GB in bytes
    }
  }

  // Refresh the storage future whenever needed
  void _refreshStorageFuture() {
    final storage = ref.read(storageServiceProvider);
    _storageFuture = Future.wait([
      storage.downloadsTotalBytes().then((b) => b.toDouble()), // offline bytes
      storage.downloadsTotalBytes().then((b) => _formatBytes(b.toDouble())),
      getDeviceStorageInBytes(), // returns totalBytes in bytes
    ]);
    if (mounted) setState(() {});
  }

  void _showSnack(String message, {bool error = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: error ? Colors.redAccent : _hivefyGreen,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _hivefyBgColor,
      body: CustomScrollView(
        controller: _scrollController,
        slivers: [
          // --- Collapsible AppBar ---
          SliverAppBar(
            pinned: true,
            expandedHeight: 160,
            backgroundColor: _darkerGreen(_hivefyGreen),
            leading: const BackButton(color: Colors.white),
            flexibleSpace: LayoutBuilder(
              builder: (context, constraints) {
                final minHeight = kToolbarHeight;
                final maxHeight = 160.0;
                final collapsePercent = ((constraints.maxHeight - minHeight) /
                        (maxHeight - minHeight))
                    .clamp(0.0, 1.0);

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
                    child: const Text(
                      "Settings",
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 22,
                      ),
                    ),
                  ),
                  background: Container(
                    color: _hivefyBgColor,
                    child: Padding(
                      padding: const EdgeInsets.only(left: 16, bottom: 32),
                      child: Align(
                        alignment: Alignment.bottomLeft,
                        child: Opacity(
                          opacity: collapsePercent,
                          child: const Text(
                            "Settings",
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                              fontSize: 28,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),

          // --- Notifications ---
          _buildSectionTitle(
            "Notifications",
            subtitle: "Manage app notification settings",
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        color: _hivefyGreen.withValues(alpha: 0.14),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        notificationsEnabled
                            ? Icons.notifications
                            : Icons.notifications_off,
                        size: 22,
                        color: _hivefyGreen,
                      ),
                    ),
                    const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "App Notifications",
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                            fontSize: 15,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          notificationsEnabled
                              ? "You will receive notifications for updates"
                              : "Notifications are off, tap to enable",
                          style: const TextStyle(
                            color: Colors.white54,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (!notificationsEnabled)
                    TextButton(
                      onPressed: _requestNotificationPermission,
                      style: TextButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        side: const BorderSide(
                          color: Colors.greenAccent,
                          width: 1,
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),
                      child: const Text(
                        "Enable",
                        style: TextStyle(
                          color: Colors.greenAccent,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
          _buildDivider(),

          // --- User Preferences ---
          _buildSectionTitle(
            "Preferences",
            subtitle: "Manage your recent activity and search history",
          ),
          SliverList(
            delegate: SliverChildListDelegate([
              SettingsRow(
                icon: Icons.music_note,
                title: "Last Played Songs",
                content: "Clear your recent song history",
                onDelete: () async {
                  final storage = ref.read(storageServiceProvider);
                  await storage.clearHistory();
                  _showSnack('Last Played Songs cleared');
                },
              ),
              SettingsRow(
                icon: Icons.search,
                title: "Search History",
                content: "Clear all previous searches",
                onDelete: () async {
                  final storage = ref.read(storageServiceProvider);
                  await storage.clearSearchHistory();
                  _showSnack('Search History cleared');
                },
              ),
            ]),
          ),
          _buildDivider(),

          // --- Offline Manager Section ---
          _buildSectionTitle(
            "Offline Manager",
            subtitle: "Manage all downloaded songs and albums",
          ),
          SliverList(
            delegate: SliverChildListDelegate([
              SettingsRow(
                icon: Icons.download_done,
                title: "Delete All Offline Songs",
                content: "Remove all downloaded songs.",
                onDelete: () async {
                  final storage = ref.read(storageServiceProvider);
                  await storage.clearDownloads();
                  _showSnack('All offline songs deleted');
                  _refreshStorageFuture(); // refresh storage info after deletion
                },
              ),
            ]),
          ),

          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: FutureBuilder<List<dynamic>>(
                future: _storageFuture,
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return const Center(
                      child: SizedBox(
                        height: 40,
                        width: 40,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    );
                  }

                  final offlineBytes = snapshot.data![0] as double; // our app
                  final usedFormatted = snapshot.data![1] as String;
                  final totalBytes = snapshot.data![2] as double; // total
                  final freeBytes = totalBytes - offlineBytes; // rough free

                  // fractions for bar
                  final appFraction =
                      (offlineBytes / totalBytes).clamp(0.0, 1.0) + 0.01;
                  final otherFraction =
                      ((freeBytes - (totalBytes - freeBytes)) / totalBytes)
                          .clamp(0.0, 1.0);
                  final freeFraction = (freeBytes / totalBytes).clamp(0.0, 1.0);

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Offline Songs: $usedFormatted",
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Expanded(
                            flex: (appFraction * 1000).toInt(),
                            child: ClipRRect(
                              borderRadius: const BorderRadius.only(
                                topLeft: Radius.circular(5),
                                bottomLeft: Radius.circular(5),
                              ),
                              child: Container(
                                height: 6,
                                color: _hivefyGreen,
                              ),
                            ),
                          ),
                          Expanded(
                            flex: (otherFraction * 1000).toInt(),
                            child: Container(
                              height: 6,
                              decoration: BoxDecoration(
                                color: Colors.grey.shade700,
                              ),
                            ),
                          ),
                          Expanded(
                            flex: (freeFraction * 1000).toInt(),
                            child: ClipRRect(
                              borderRadius: const BorderRadius.only(
                                topRight: Radius.circular(5),
                                bottomRight: Radius.circular(5),
                              ),
                              child: Container(
                                height: 6,
                                color: Colors.white12,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            "${_formatBytes(offlineBytes)} used",
                            style: const TextStyle(
                              color: Colors.white54,
                              fontSize: 11,
                            ),
                          ),
                          Text(
                            "${_formatBytes(totalBytes)} total",
                            style: const TextStyle(
                              color: Colors.white54,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
          _buildDivider(),

          // --- API Server Selection (static) ---
          _buildSectionTitle(
            "Stream Server",
            subtitle: "Choose which server the app will use for APIs",
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      'Main Server',
                      'Mirror Server',
                      'Dupe Server',
                    ].map((server) {
                      final isSelected = server == _selectedServer;

                      return ChoiceChip(
                        label: Text(
                          isSelected
                              ? server
                              : server.replaceAll(" Server", ""),
                          style: TextStyle(
                            color: isSelected ? _hivefyGreen : Colors.white,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        selected: isSelected,
                        color: WidgetStateProperty.resolveWith<Color?>((states) {
                          return AppColors.cardTranslucent;
                        }),
                        selectedColor: _hivefyGreen.withAlpha(51),
                        backgroundColor: AppColors.cardTranslucent,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                          side: BorderSide(
                            color: isSelected
                                ? _hivefyGreen
                                : Colors.grey.shade800,
                            width: isSelected ? 1 : 0,
                          ),
                        ),
                        showCheckmark: false,
                        onSelected: (_) {},
                      );
                    }).toList(),
                  ),

                  const SizedBox(height: 12),
                  const Text(
                    "If you face any playback or streaming issues, try switching servers. "
                    "Best performance is usually with the Main server.",
                    style: TextStyle(
                      color: Colors.white60,
                      fontSize: 12.5,
                      height: 1.3,
                    ),
                  ),
                ],
              ),
            ),
          ),
          _buildDivider(),

          // --- Debug Section ---
          _buildSectionTitle(
            "Debug",
            subtitle: "Developer tools and diagnostics",
          ),
          SliverList(
            delegate: SliverChildListDelegate([
              _buildDebugTile(
                icon: Icons.storage,
                title: "Artist Database",
                subtitle: "View, search and test the artist DB",
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const ArtistDatabaseDebugScreen(),
                    ),
                  );
                },
              ),
            ]),
          ),
          _buildDivider(),

          // --- Main Database Caches ---
          _buildSectionTitle(
            "Caches",
            subtitle: "Remove caches, only when you face some caches issue!",
          ),
          SliverList(
            delegate: SliverChildListDelegate([
              SettingsRow(
                icon: Icons.music_note,
                title: "Songs Cache",
                content: "Remove saved songs.",
                onDelete: () async {
                  final storage = ref.read(storageServiceProvider);
                  await storage.clearSongsCache();
                  _showSnack('Songs cleared');
                },
              ),
              SettingsRow(
                icon: Icons.person,
                title: "Artist Cache",
                content: "Remove saved artists information",
                onDelete: () async {
                  final storage = ref.read(storageServiceProvider);
                  await storage.clearArtistCache();
                  _showSnack('Artist cleared');
                },
              ),
              SettingsRow(
                icon: Icons.album,
                title: "Album Cache",
                content: "Remove saved albums data",
                onDelete: () async {
                  final storage = ref.read(storageServiceProvider);
                  await storage.clearAlbumCache();
                  _showSnack('Album cleared');
                },
              ),
              SettingsRow(
                icon: Icons.queue_music,
                title: "Playlist Cache",
                content: "Remove saved playlists",
                onDelete: () async {
                  final storage = ref.read(storageServiceProvider);
                  await storage.clearPlaylistCache();
                  _showSnack('Playlists cleared');
                },
              ),
            ]),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 100)),
        ],
      ),
    );
  }

  SliverToBoxAdapter _buildSectionTitle(String title, {String? subtitle}) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                color: Colors.white70,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            if (subtitle != null)
              Padding(
                padding: const EdgeInsets.only(top: 2),
                child: Text(
                  subtitle,
                  style: const TextStyle(
                    color: Colors.white38,
                    fontSize: 13,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  SliverToBoxAdapter _buildDivider() {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Divider(color: Colors.white12, thickness: 1),
      ),
    );
  }

  Widget _buildDebugTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(icon, color: Colors.white70),
      title: Text(
        title,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w500,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 12),
      ),
      trailing: Icon(
        Icons.chevron_right,
        color: Colors.white.withOpacity(0.3),
      ),
      onTap: onTap,
    );
  }
}

Color _darkerGreen(Color color, {double darkenFactor = 0.18}) {
  final hsl = HSLColor.fromColor(color);
  final newLight = (hsl.lightness - darkenFactor).clamp(0.12, 1.0);
  final newSat = (hsl.saturation + 0.1).clamp(0.0, 1.0);
  return hsl.withLightness(newLight).withSaturation(newSat).toColor();
}

// --- SettingsRow with improved spacing ---
class SettingsRow extends StatelessWidget {
  final String title;
  final String content;
  final IconData icon;
  final VoidCallback onDelete;
  final bool showDelete;

  const SettingsRow({
    super.key,
    required this.title,
    required this.content,
    required this.icon,
    required this.onDelete,
    this.showDelete = true,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: _hivefyGreen.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 22, color: _hivefyGreen),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  content,
                  style: const TextStyle(color: Colors.white54, fontSize: 13),
                ),
              ],
            ),
          ),
          if (showDelete)
            TextButton(
              onPressed: onDelete,
              style: TextButton.styleFrom(
                backgroundColor: Colors.transparent,
                side: const BorderSide(color: Colors.white30, width: 1),
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
              child: const Text(
                "Clear",
                style: TextStyle(
                  color: Colors.redAccent,
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

String _formatBytes(double bytes) {
  if (bytes <= 0) return "0 B";

  const kb = 1024;
  const mb = kb * 1024;
  const gb = mb * 1024;

  if (bytes >= gb) return "${(bytes / gb).toStringAsFixed(2)} GB";
  if (bytes >= mb) return "${(bytes / mb).toStringAsFixed(2)} MB";
  if (bytes >= kb) return "${(bytes / kb).toStringAsFixed(2)} KB";
  return "${bytes.toStringAsFixed(0)} B";
}
