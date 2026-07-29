import 'package:flutter/material.dart';
import 'package:tunefy/constants/constants.dart';
import 'package:tunefy/DI/service_locator.dart';
import 'package:tunefy/models/track.dart';
import 'package:tunefy/widgets/stream_buttons.dart';
import 'package:tunefy/services/haptic_service.dart';
import 'package:tunefy/theme/tunefy_theme.dart';

class LyricsScreen extends StatefulWidget {
  final Track? track;
  const LyricsScreen({super.key, this.track});

  @override
  State<LyricsScreen> createState() => _LyricsScreenState();
}

class _LyricsScreenState extends State<LyricsScreen> {
  PlayerProvider get _player => playerProvider;

  @override
  void initState() {
    super.initState();
    _player.addListener(_onUpdate);
  }

  void _onUpdate() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _player.removeListener(_onUpdate);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final lyrics = _player.currentLyrics;
    final isLoading = _player.isLoadingLyrics;
    final track = widget.track ?? _player.currentTrack;

    return Scaffold(
      backgroundColor: const Color(0xff2b8094),
      body: Column(
        children: [
          _Header(track: track),
          const SizedBox(height: 20),
          Expanded(
            child: _LyricsContent(lyrics: lyrics, isLoading: isLoading),
          ),
          Padding(
            padding: const EdgeInsets.only(bottom: 20),
            child: _ActionButtons(position: _player.position, duration: _player.duration),
          ),
        ],
      ),
    );
  }
}

class _LyricsContent extends StatelessWidget {
  final dynamic lyrics;
  final bool isLoading;

  const _LyricsContent({required this.lyrics, required this.isLoading});

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator(color: Colors.white));
    }
    if (lyrics == null) {
      return const Center(
        child: Text(
          "No lyrics found",
          style: TextStyle(color: Colors.white70, fontFamily: "AM", fontSize: 16),
        ),
      );
    }

    final plainLyrics = lyrics.plainLyrics as String;
    if (plainLyrics.isEmpty) {
      return const Center(
        child: Text("No lyrics available", style: TextStyle(color: Colors.white70, fontFamily: "AM", fontSize: 16)),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 25),
      child: SizedBox(
        height: MediaQuery.of(context).size.height - 310,
        width: MediaQuery.of(context).size.width,
        child: SingleChildScrollView(
          child: Text(
            plainLyrics,
            style: const TextStyle(
              color: MyColors.whiteColor,
              fontFamily: "AM",
              fontWeight: FontWeight.w700,
              fontSize: 24,
              height: 1.5,
            ),
          ),
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  final Track? track;
  const _Header({this.track});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 20, left: 20, top: 35),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          GestureDetector(
            onTap: () { HapticService.tap(); Navigator.pop(context); },
            child: Container(
              height: 32, width: 32,
              decoration: BoxDecoration(shape: BoxShape.circle, color: const Color(0xff000000).withValues(alpha: 0.4)),
              child: const Center(child: Icon(Icons.keyboard_arrow_down, color: Colors.white, size: 26)),
            ),
          ),
          Column(
            children: [
              Text(
                track?.title ?? "Unknown",
                style: const TextStyle(fontWeight: FontWeight.w700, fontFamily: "AM", color: MyColors.whiteColor, fontSize: 18),
              ),
              Text(
                track?.artist ?? "Unknown",
                style: const TextStyle(fontFamily: "AM", fontSize: 12, color: Color.fromARGB(255, 253, 239, 239)),
              ),
            ],
          ),
          Image.asset('images/icon_flag.png', height: 24, width: 24),
        ],
      ),
    );
  }
}

class _ActionButtons extends StatelessWidget {
  final Duration position;
  final Duration duration;
  const _ActionButtons({required this.position, required this.duration});

  String _format(Duration d) {
    final m = d.inMinutes;
    final s = (d.inSeconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: [
          SliderTheme(
            data: const SliderThemeData(
              trackHeight: 2,
              thumbShape: RoundSliderThumbShape(enabledThumbRadius: 6.0),
              overlayShape: RoundSliderOverlayShape(overlayRadius: 0.0),
            ),
            child: Slider(
              min: 0, max: duration.inMilliseconds > 0 ? duration.inMilliseconds.toDouble() : 1,
              activeColor: const Color.fromARGB(255, 230, 229, 229),
              inactiveColor: const Color.fromARGB(255, 199, 196, 196),
              value: position.inMilliseconds.toDouble().clamp(0, duration.inMilliseconds.toDouble()),
              onChanged: (val) {
                playerProvider.seek(Duration(milliseconds: val.toInt()));
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 3),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(_format(position), style: const TextStyle(fontFamily: "AM", fontSize: 12, color: Color.fromARGB(255, 230, 229, 229))),
                Text(_format(duration), style: const TextStyle(fontFamily: "AM", fontSize: 12, color: Color.fromARGB(255, 230, 229, 229))),
              ],
            ),
          ),
          const SizedBox(height: 2),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Image.asset('images/icon_sing.png', height: 20, width: 20, color: Colors.white),
              GestureDetector(
                onTap: () => playerProvider.togglePlay(),
                child: playerProvider.isPlaying
                    ? const PauseButton(iconWidth: 5, color: MyColors.whiteColor, height: 60, width: 60, iconHeight: 20)
                    : const PlayButton(color: MyColors.whiteColor, height: 60, width: 60),
              ),
              Image.asset('images/share.png', color: Colors.white, height: 20, width: 20),
            ],
          ),
        ],
      ),
    );
  }
}
