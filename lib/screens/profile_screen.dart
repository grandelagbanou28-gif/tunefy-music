import 'dart:io';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';

import 'package:muzo/services/storage_service.dart';
import 'package:muzo/utils/app_colors.dart';

const Color hivefyBgColor = Color(0xFF121212);
const Color hivefyGreen = Color(0xFF1DDA63);

Color _darkerGreen(Color color, {double darkenFactor = 0.18}) {
  final hsl = HSLColor.fromColor(color);
  final newLight = (hsl.lightness - darkenFactor).clamp(0.12, 1.0);
  final newSat = (hsl.saturation + 0.1).clamp(0.0, 1.0);
  return hsl.withLightness(newLight).withSaturation(newSat).toColor();
}

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  bool _isTitleCollapsed = false;
  late ScrollController _scrollController;

  bool _isEditingName = false;
  final TextEditingController _nameController = TextEditingController();

  String _username = 'Oreo';
  File? _profileFile;

  // Load stored data
  Future<void> _loadProfileData() async {
    final storage = ref.read(storageServiceProvider);
    final storedName = storage.username;
    final imagePath = storage.profilePhotoPath;

    _username = storedName ?? 'Oreo';
    if (imagePath != null && File(imagePath).existsSync()) {
      _profileFile = File(imagePath);
    }

    if (mounted) setState(() {});
  }

  // Pick image and persist it in documents directory
  Future<void> _pickAndStoreImage() async {
    try {
      final picker = ImagePicker();
      final picked = await picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
        maxWidth: 1024,
      );
      if (picked == null) return; // user cancelled — not an error
      if (!mounted) return;

      final dir = await getApplicationDocumentsDirectory();
      final newPath =
          '${dir.path}/profile_${DateTime.now().millisecondsSinceEpoch}.png';
      final newImage = await File(picked.path).copy(newPath);

      // Remove the previous photo so documents don't fill up.
      final storage = ref.read(storageServiceProvider);
      final oldPath = storage.profilePhotoPath;
      await storage.setProfilePhotoPath(newImage.path);
      if (oldPath != null && File(oldPath).existsSync()) {
        try {
          File(oldPath).deleteSync();
        } catch (_) {}
      }

      if (!mounted) return;
      setState(() {
        _profileFile = newImage;
      });
    } catch (e) {
      debugPrint('Photo pick failed: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Impossible de charger la photo'),
          backgroundColor: Color(0xFF282828),
        ),
      );
    }
  }

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
    _loadProfileData();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: hivefyBgColor,
      body: CustomScrollView(
        controller: _scrollController,
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          // --- Collapsible Sliver AppBar ---
          SliverAppBar(
            pinned: true,
            expandedHeight: 160,
            backgroundColor: _darkerGreen(hivefyGreen),
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
                      "Account",
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 22,
                      ),
                    ),
                  ),
                  background: Container(
                    color: hivefyBgColor,
                    child: Padding(
                      padding: const EdgeInsets.only(left: 16, bottom: 32),
                      child: Align(
                        alignment: Alignment.bottomLeft,
                        child: Opacity(
                          opacity: collapsePercent,
                          child: const Text(
                            "Account",
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

          // --- Username Section ---
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
              child: Row(
                children: [
                  // --- Avatar with edit overlay ---
                  Stack(
                    clipBehavior: Clip.none,
                    alignment: Alignment.bottomRight,
                    children: [
                      CircleAvatar(
                        radius: 35,
                        backgroundImage:
                            _profileFile != null
                                ? FileImage(_profileFile!)
                                : const AssetImage('assets/covers/app_icon.png')
                                    as ImageProvider,
                      ),
                      Positioned(
                        bottom: -3,
                        right: -3,
                        child: GestureDetector(
                          onTap: _pickAndStoreImage,
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.black54,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: Colors.white54,
                                width: .5,
                              ),
                            ),
                            padding: const EdgeInsets.all(6),
                            child: const Icon(
                              Icons.edit,
                              color: Colors.white,
                              size: 16,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(width: 16),

                  // --- Username display / edit field ---
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "Username",
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 4),
                        _isEditingName
                            ? Padding(
                              padding: const EdgeInsets.only(right: 6),
                              child: SizedBox(
                                height: 20,
                                child: TextField(
                                  autofocus: true,
                                  onTapOutside:
                                      (_) => FocusScope.of(context).unfocus(),
                                  controller: _nameController,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    height: 1,
                                  ),
                                  decoration: const InputDecoration(
                                    isDense: true,
                                    contentPadding: EdgeInsets.symmetric(
                                      vertical: 6,
                                    ),
                                    enabledBorder: UnderlineInputBorder(
                                      borderSide: BorderSide(
                                        color: Colors.white24,
                                      ),
                                    ),
                                    focusedBorder: UnderlineInputBorder(
                                      borderSide: BorderSide(
                                        color: hivefyGreen,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            )
                            : Text(
                              _username,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                height: 1,
                              ),
                            ),
                      ],
                    ),
                  ),

                  // --- Edit / Save Button ---
                  OutlinedButton(
                    onPressed: () async {
                      if (_isEditingName) {
                        final storage = ref.read(storageServiceProvider);
                        final trimmed = _nameController.text.trim();
                        final limited = trimmed.substring(
                          0,
                          min(20, trimmed.length),
                        );
                        await storage.setUsername(limited);
                        _username = limited;
                        _isEditingName = false;
                        setState(() {});
                      } else {
                        _isEditingName = true;
                        _nameController.text = _username;
                        setState(() {});
                      }
                    },
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Colors.white30),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                    child: Text(
                      _isEditingName ? "Save" : "Edit",
                      style: const TextStyle(color: Colors.white),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // --- Divider ---
          _buildDivider(),

          // --- Plan Section ---
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Your Plan",
                    style: TextStyle(
                      color: Colors.white70,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 8),

                  // --- Premium Card ---
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.cardTranslucent,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.music_note, color: hivefyGreen),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: const [
                            Text(
                              "Freemium",
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            // SizedBox(height: 4),
                            Text(
                              "Forever",
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 10)),

          // --- Benefits Section ---
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Snapshot of your benefits",
                    style: TextStyle(
                      color: Colors.white70,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.cardTranslucent,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      children: [
                        _buildBenefitItem("Ad-free music listening"),
                        _buildBenefitItem("Download to listen offline"),
                        _buildBenefitItem("High audio quality"),
                        _buildBenefitItem("Organise listening queue"),
                        _buildBenefitItem("Unlimited swipes and playbacks."),
                      ],
                    ),
                  ),
                  const SizedBox(height: 100),
                  // OutlinedButton(
                  //   onPressed: () {},
                  //   style: OutlinedButton.styleFrom(
                  //     side: const BorderSide(color: Colors.white30),
                  //     shape: RoundedRectangleBorder(
                  //       borderRadius: BorderRadius.circular(20),
                  //     ),
                  //     padding: const EdgeInsets.symmetric(
                  //       horizontal: 20,
                  //       vertical: 12,
                  //     ),
                  //   ),
                  //   child: const Text(
                  //     "Explore your benefits",
                  //     style: TextStyle(color: Colors.white),
                  //   ),
                  // ),
                  const SizedBox(height: 320),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  SliverToBoxAdapter _buildDivider() {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
        child: Divider(color: Colors.white12, thickness: 1),
      ),
    );
  }

  Widget _buildBenefitItem(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          const Icon(Icons.check, color: hivefyGreen, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _nameController.dispose();
    super.dispose();
  }
}
