import 'package:flutter/material.dart';
import 'package:tunefy/constants/constants.dart';
import 'package:tunefy/ui/listening_on_screen.dart';
import 'package:tunefy/ui/song_control_screen.dart';
import 'package:tunefy/widgets/stream_buttons.dart';
import 'package:tunefy/widgets/video_player.dart';
import 'package:tunefy/DI/service_locator.dart';
import 'package:tunefy/models/track.dart';
import 'package:tunefy/ui/lyrics_screen.dart';
import 'dart:math';
import 'package:tunefy/services/haptic_service.dart';
import 'package:tunefy/theme/tunefy_theme.dart';

class TrackViewScreen extends StatefulWidget {
  final Track? track;
  final List<Track>? playlistTracks;
  final int? initialIndex;

  const TrackViewScreen({super.key, this.track, this.playlistTracks, this.initialIndex});

  @override
  State<TrackViewScreen> createState() => _TrackViewScreenState();
}

class _TrackViewScreenState extends State<TrackViewScreen> {
  bool isOnPlaying = true;
  bool isSwitchedToNextTab = false;
  bool shadowSwitcher = false;
  bool _isLiked = false;

  PlayerProvider get _player => playerProvider;

  @override
  void initState() {
    super.initState();
    if (widget.track != null && _player.currentTrack == null) {
      _player.playTrack(widget.track!);
    } else if (widget.playlistTracks != null && widget.playlistTracks!.isNotEmpty) {
      _player.playAll(widget.playlistTracks!);
    }
    _player.addListener(_onPlayerUpdate);
  }

  void _onPlayerUpdate() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _player.removeListener(_onPlayerUpdate);
    super.dispose();
  }

  String _formatDuration(Duration d) {
    final minutes = d.inMinutes;
    final seconds = (d.inSeconds % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  Track get _activeTrack => _player.currentTrack ?? widget.track ?? Track(title: '', artist: '');

  @override
  Widget build(BuildContext context) {
    final track = _activeTrack;
    final position = _player.position;
    final duration = _player.duration;
    final isPlaying = _player.isPlaying;

    return Scaffold(
      body: Stack(
        children: [
          Stack(
            children: [
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                switchInCurve: Curves.decelerate,
                switchOutCurve: Curves.decelerate,
                child: (isSwitchedToNextTab)
                    ? LyricsScreen(
                        key: const Key("lyrics"),
                        track: track,
                      )
                    : GestureDetector(
                        onTap: () {
                          HapticService.tap();
                          setState(() { shadowSwitcher = !shadowSwitcher; });
                        },
                        child: Stack(
                          children: [
                            const BackVideoPlayer(key: Key("2")),
                            Container(color: (!shadowSwitcher) ? MyColors.blackColor.withValues(alpha: 0.45) : Colors.transparent),
                            Positioned(
                              left: 25, bottom: 70,
                              child: AnimatedOpacity(
                                duration: const Duration(milliseconds: 200),
                                opacity: (shadowSwitcher) ? 1 : 0,
                                child: Row(
                                  children: [
                                    CircleAvatar(
                                      radius: 15,
                                      backgroundImage: track.artistImage != null
                                          ? AssetImage('images/artists/${track.artistImage!}')
                                          : null,
                                    ),
                                    const SizedBox(width: 15),
                                    Text(
                                      "by ${track.artist}",
                                      style: const TextStyle(fontFamily: "AM", fontSize: 16, color: Colors.white),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
              ),
              const _Header(),
              AnimatedPositioned(
                duration: const Duration(milliseconds: 200),
                top: (isSwitchedToNextTab)
                    ? (MediaQuery.of(context).size.height * 0.6)
                    : (MediaQuery.of(context).size.height * 0.5),
                right: 0, left: 0,
                child: AnimatedOpacity(
                  duration: const Duration(milliseconds: 200),
                  opacity: (shadowSwitcher) ? 0 : 1,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            AnimatedOpacity(
                              duration: const Duration(milliseconds: 250),
                              opacity: (isSwitchedToNextTab) ? 0 : 1,
                              child: SizedBox(
                                height: 120, width: 120,
                                child: Center(
                                  child: track.albumImage != null
                                      ? Image.asset("images/home/${track.albumImage!}")
                                      : const Icon(Icons.music_note, color: Colors.white, size: 60),
                                ),
                              ),
                            ),
                          ],
                        ),
                        Positioned(
                          right: 0, left: 0, top: 125,
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              AnimatedPadding(
                                duration: const Duration(milliseconds: 200),
                                padding: EdgeInsets.only(top: (isSwitchedToNextTab) ? 50 : 0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Padding(
                                      padding: const EdgeInsets.only(right: 25),
                                      child: SizedBox(
                                        width: MediaQuery.of(context).size.width - 95, height: 30,
                                        child: Text(
                                          track.title,
                                          style: const TextStyle(fontWeight: FontWeight.w700, fontFamily: "AM", color: MyColors.whiteColor, fontSize: 20),
                                        ),
                                      ),
                                    ),
                                    Text(
                                      track.artist,
                                      style: const TextStyle(fontFamily: "AM", fontSize: 14, color: MyColors.whiteColor),
                                    ),
                                  ],
                                ),
                              ),
                              Column(
                                children: [
                                  AnimatedOpacity(
                                    duration: const Duration(milliseconds: 250),
                                    opacity: (isSwitchedToNextTab) ? 0 : 1,
                                    child: GestureDetector(
                                      onTap: () {
                                        HapticService.tap();
                                        Navigator.push(context, MaterialPageRoute(
                                          builder: (context) => SongControlScreen(
                                            trackName: track.title, color: MyColors.greenColor,
                                            singer: track.artist, albumImage: track.albumImage ?? '',
                                          ),
                                        ));
                                      },
                                      child: const Icon(Icons.more_vert, color: Colors.white),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        Positioned(
                          top: 205, right: 0, left: 0,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  AnimatedPadding(
                                    duration: const Duration(milliseconds: 200),
                                    padding: EdgeInsets.only(top: (isSwitchedToNextTab) ? 40 : 0),
                                    child: GestureDetector(
                                      onTap: () => _player.skipToPrevious(),
                                      child: const PauseButton(iconWidth: 2.5, height: 40, iconHeight: 14, width: 40, color: MyColors.whiteColor),
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  AnimatedOpacity(
                                    duration: const Duration(milliseconds: 250),
                                    opacity: (isSwitchedToNextTab) ? 0 : 1,
                                    child: GestureDetector(
                                      onTap: () => _player.togglePlay(),
                                      child: Container(
                                        height: 40, width: 40,
                                        decoration: BoxDecoration(shape: BoxShape.circle, color: MyColors.blackColor.withValues(alpha: 0.3)),
                                        child: Center(
                                          child: _player.isLoadingStream
                                              ? const SizedBox(height: 16, width: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                                              : Icon(isPlaying ? Icons.pause : Icons.play_arrow, color: Colors.white, size: 24),
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  AnimatedOpacity(
                                    duration: const Duration(milliseconds: 250),
                                    opacity: (isSwitchedToNextTab) ? 0 : 1,
                                    child: GestureDetector(
                                      onTap: () => _player.skipToNext(),
                                      child: Container(
                                        height: 40, width: 40,
                                        decoration: BoxDecoration(shape: BoxShape.circle, color: MyColors.blackColor.withValues(alpha: 0.3)),
                                        child: Center(
                                          child: Image.asset("images/icon_next_song.png", height: 16, width: 16),
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              AnimatedOpacity(
                                duration: const Duration(milliseconds: 250),
                                opacity: (isSwitchedToNextTab) ? 0 : 1,
                                child: GestureDetector(
                                  onTap: () { setState(() { _isLiked = !_isLiked; }); },
                                  child: _isLiked
                                      ? Image.asset('images/icon_heart_filled.png', height: 22, width: 22)
                                      : Image.asset('images/icon_heart.png', color: Colors.white),
                                ),
                              ),
                            ],
                          ),
                        ),
                        Positioned(
                          top: 260, right: 0, left: 0,
                          child: AnimatedPadding(
                            duration: const Duration(milliseconds: 200),
                            padding: EdgeInsets.only(left: (isSwitchedToNextTab) ? 50 : 0),
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
                                    inactiveColor: const Color.fromARGB(255, 148, 147, 147),
                                    value: min(position.inMilliseconds.toDouble(), duration.inMilliseconds.toDouble()),
                                    onChanged: (val) {
                                      _player.seek(Duration(milliseconds: val.toInt()));
                                    },
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 3),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(_formatDuration(position), style: const TextStyle(fontFamily: "AM", fontSize: 12, color: Color.fromARGB(255, 230, 229, 229))),
                                      Text(_formatDuration(duration), style: const TextStyle(fontFamily: "AM", fontSize: 12, color: Color.fromARGB(255, 230, 229, 229))),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
          Positioned(
            top: 90, left: 0, right: 0,
            child: Padding(
              padding: const EdgeInsets.only(left: 20),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () { setState(() { isOnPlaying = !isOnPlaying; isSwitchedToNextTab = !isSwitchedToNextTab; }); },
                    child: Container(
                      height: 30,
                      decoration: BoxDecoration(borderRadius: BorderRadius.circular(20), color: (isOnPlaying) ? Colors.white : Colors.transparent),
                      child: Center(child: Padding(padding: const EdgeInsets.symmetric(horizontal: 15), child: Text("Playing", style: TextStyle(fontFamily: "AM", fontSize: 16, fontWeight: FontWeight.w700, color: (isOnPlaying) ? Colors.black : Colors.white)))),
                    ),
                  ),
                  GestureDetector(
                    onTap: () { setState(() { isOnPlaying = !isOnPlaying; isSwitchedToNextTab = !isSwitchedToNextTab; shadowSwitcher = false; }); },
                    child: Container(
                      height: 30,
                      decoration: BoxDecoration(borderRadius: BorderRadius.circular(15), color: (!isOnPlaying) ? Colors.white : Colors.transparent),
                      child: Center(child: Padding(padding: const EdgeInsets.symmetric(horizontal: 20), child: Text("Lyrics", style: TextStyle(fontFamily: "AM", fontSize: 16, fontWeight: FontWeight.w700, color: (!isOnPlaying) ? Colors.black : Colors.white)))),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 50, right: 20, left: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          GestureDetector(
            onTap: () { HapticService.tap(); Navigator.pop(context); },
            child: const Icon(Icons.keyboard_arrow_down, color: Colors.white),
          ),
          GestureDetector(
            onTap: () {
              HapticService.tap();
              Navigator.push(context, PageRouteBuilder(
                transitionDuration: const Duration(milliseconds: 250),
                pageBuilder: (context, animation, secondaryAnimation) => const ListeningOn(),
                transitionsBuilder: (context, animation, secondaryAnimation, child) {
                  return SlideTransition(position: animation.drive(Tween(begin: const Offset(0.0, 1.0), end: Offset.zero)), child: child);
                },
              ));
            },
            child: Image.asset('images/icon_listen.png', height: 20, width: 20, color: Colors.white),
          ),
        ],
      ),
    );
  }
}
