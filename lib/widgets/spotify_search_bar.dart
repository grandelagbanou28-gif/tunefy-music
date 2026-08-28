import 'package:flutter/material.dart';
import 'package:muzo/widgets/spotify_chips.dart';

/// Spotify's exact search bar: white full-rounded pill, search icon on the
/// left, grey placeholder, no underline/border, clear button when typing.
class SpotifySearchBar extends StatelessWidget {
  const SpotifySearchBar({
    super.key,
    required this.controller,
    required this.onChanged,
    this.hintText = 'Artists, songs, or podcasts',
    this.autofocus = false,
    this.onSubmitted,
    this.trailing,
    this.showMic = false,
    this.onMicTap,
    this.isListening = false,
    this.height = 48,
  });

  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final String hintText;
  final bool autofocus;
  final ValueChanged<String>? onSubmitted;
  final Widget? trailing;
  final bool showMic;
  final VoidCallback? onMicTap;
  final bool isListening;
  final double height;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      decoration: const BoxDecoration(
        color: spotifyWhite,
        borderRadius: BorderRadius.all(Radius.circular(500)),
      ),
      child: Row(
        children: [
          const SizedBox(width: 16),
          Icon(Icons.search, color: spotifyDarkGrey.withOpacity(0.7), size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: TextField(
              controller: controller,
              autofocus: autofocus,
              onChanged: onChanged,
              onSubmitted: onSubmitted,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w500,
                color: spotifyBlack,
              ),
              cursorColor: spotifyDarkGrey,
              decoration: InputDecoration(
                hintText: hintText,
                hintStyle: TextStyle(
                  color: spotifyDarkGrey.withOpacity(0.55),
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                ),
                border: InputBorder.none,
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
          if (trailing != null)
            trailing!
          else
            ValueListenableBuilder<TextEditingValue>(
              valueListenable: controller,
              builder: (context, value, _) {
                if (value.text.isEmpty && showMic) {
                  return GestureDetector(
                    onTap: onMicTap,
                    behavior: HitTestBehavior.opaque,
                    child: Padding(
                      padding: const EdgeInsets.only(right: 12, left: 8),
                      child: Icon(
                        Icons.mic,
                        color: isListening ? const Color(0xFF1DB954) : spotifyDarkGrey,
                        size: 20,
                      ),
                    ),
                  );
                }
                if (value.text.isEmpty) return const SizedBox(width: 12);
                return GestureDetector(
                  onTap: () {
                    controller.clear();
                    onChanged('');
                  },
                  child: const Padding(
                    padding: EdgeInsets.only(right: 12),
                    child: Icon(Icons.close, color: spotifyDarkGrey, size: 18),
                  ),
                );
              },
            ),
        ],
      ),
    );
  }
}
