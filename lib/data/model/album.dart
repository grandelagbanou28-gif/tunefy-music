import 'package:flutter/widgets.dart';
import 'package:tunefy/data/model/album_track.dart';
import 'package:tunefy/models/track.dart';

class Album {
  String albumName;
  String year;
  String singerName;
  String albumImage;
  String artistImage;
  List<AlbumTrack> trackList;
  List<Track> tracks;
  List<Color> colorPallete;

  Album(this.albumImage, this.albumName, this.singerName, this.trackList,
      this.year, this.artistImage, this.colorPallete, {this.tracks = const []});
}
