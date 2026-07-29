import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:tunefy/services/haptic_service.dart';

class ShareModal extends StatefulWidget {
  final String title;
  final String artist;
  final String? imageUrl;

  const ShareModal({
    super.key,
    required this.title,
    required this.artist,
    this.imageUrl,
  });

  @override
  State<ShareModal> createState() => _ShareModalState();
}

class _ShareModalState extends State<ShareModal> {
  final List<Color> _paletteColors = [
    const Color(0xFF1DB954),
    const Color(0xFFE13300),
    const Color(0xFFFFCD00),
    const Color(0xFF503750),
    const Color(0xFF283954),
    const Color(0xFF006B5E),
    const Color(0xFF8B1932),
    const Color(0xFF2D46B9),
    const Color(0xFF000000),
  ];

  Color _selectedColor = const Color(0xFF1DB954);

  @override
  Widget build(BuildContext context) {
    final screenW = MediaQuery.of(context).size.width;
    final artSize = screenW * 0.25;

    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFF121212),
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 36, height: 4,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 20),
              const Text('Partager',
                style: TextStyle(fontFamily: 'AB', fontSize: 18, color: Colors.white, fontWeight: FontWeight.w700)),
              const SizedBox(height: 20),
              Container(
                decoration: BoxDecoration(
                  color: _selectedColor.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: _selectedColor.withValues(alpha: 0.5), width: 1),
                ),
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        width: artSize,
                        height: artSize,
                        color: _selectedColor.withValues(alpha: 0.4),
                        child: widget.imageUrl != null
                            ? CachedNetworkImage(imageUrl: widget.imageUrl!, fit: BoxFit.cover,
                                errorWidget: (_, __, ___) => const Icon(Icons.music_note, color: Colors.white54, size: 30))
                            : const Icon(Icons.music_note, color: Colors.white54, size: 30),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(widget.title,
                            style: const TextStyle(fontFamily: 'AB', fontSize: 15, color: Colors.white),
                            maxLines: 2, overflow: TextOverflow.ellipsis),
                          const SizedBox(height: 4),
                          Text(widget.artist,
                            style: const TextStyle(fontFamily: 'AM', fontSize: 12, color: Colors.white70)),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              const Icon(Icons.headphones, color: Colors.white54, size: 14),
                              const SizedBox(width: 4),
                              const Text('Tunefy',
                                style: TextStyle(fontFamily: 'AM', fontSize: 11, color: Colors.white54)),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Couleur de fond',
                    style: TextStyle(fontFamily: 'AM', fontSize: 13, color: Color(0xFFB3B3B3))),
                  Container(
                    width: 24, height: 24,
                    decoration: BoxDecoration(
                      color: _selectedColor,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              SizedBox(
                height: 34,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: _paletteColors.map((color) {
                    final isSelected = _selectedColor == color;
                    return GestureDetector(
                      onTap: () => setState(() => _selectedColor = color),
                      child: Container(
                        width: 34,
                        height: 34,
                        margin: const EdgeInsets.only(right: 10),
                        decoration: BoxDecoration(
                          color: color,
                          borderRadius: BorderRadius.circular(8),
                          border: isSelected
                              ? Border.all(color: Colors.white, width: 2)
                              : null,
                        ),
                        child: isSelected
                            ? const Icon(Icons.check, color: Colors.white, size: 18)
                            : null,
                      ),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _shareTarget(Icons.chat, 'WhatsApp', () {
                    Share.share('${widget.title} - ${widget.artist} via Tunefy');
                  }),
                  _shareTarget(Icons.link, 'Copier le lien', () {
                    Clipboard.setData(ClipboardData(text: '${widget.title} - ${widget.artist} via Tunefy'));
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Lien copié !', style: TextStyle(fontFamily: 'AM')), backgroundColor: Color(0xFF282828), duration: Duration(seconds: 2)),
                    );
                  }),
                  _shareTarget(Icons.auto_stories, 'Stories', () {
                    Share.share('${widget.title} - ${widget.artist} via Tunefy');
                  }),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _shareTarget(IconData icon, String label, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 50, height: 50,
            decoration: BoxDecoration(
              color: const Color(0xFF282828),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: Colors.white, size: 22),
          ),
          const SizedBox(height: 6),
          Text(label,
            style: const TextStyle(fontFamily: 'AM', fontSize: 10, color: Color(0xFFB3B3B3))),
        ],
      ),
    );
  }
}
