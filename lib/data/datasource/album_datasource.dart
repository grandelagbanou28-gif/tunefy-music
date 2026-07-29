import 'dart:ui';
import 'package:tunefy/data/model/album.dart';
import 'package:tunefy/data/model/album_track.dart';
import 'package:tunefy/models/track.dart';

class AlbumDatasource {
  Future<Album> albumList(String singer) async {
    if (singer == "Drake") {
      final tracks = [
        const Track(videoId: "2a-RlrJYzWw", title: "Virginia Beach", artist: "Drake", albumImage: "For-All-The-Dogs.jpg", artistImage: "Drake.jpg", duration: Duration(minutes: 3, seconds: 49)),
        const Track(videoId: "gOFzknzJvRk", title: "Amen (feat. Teezo Touchdown)", artist: "Drake, Teezo Touchdown", albumImage: "For-All-The-Dogs.jpg", artistImage: "Drake.jpg", duration: Duration(minutes: 3, seconds: 35)),
        const Track(videoId: "0b4R4dC0HBo", title: "Calling For You", artist: "Drake, 21 Savage", albumImage: "For-All-The-Dogs.jpg", artistImage: "Drake.jpg", duration: Duration(minutes: 3, seconds: 51)),
        const Track(videoId: "xI6GnR5sRiE", title: "Fear Of Heights", artist: "Drake", albumImage: "For-All-The-Dogs.jpg", artistImage: "Drake.jpg", duration: Duration(minutes: 2, seconds: 45)),
        const Track(videoId: "YfDmNMaQ2Kk", title: "Daylight", artist: "Drake", albumImage: "For-All-The-Dogs.jpg", artistImage: "Drake.jpg", duration: Duration(minutes: 2, seconds: 44)),
        const Track(videoId: "3fMCJm7X3JI", title: "First Person Shooter (feat. J.Cole)", artist: "Drake, J.Cole", albumImage: "For-All-The-Dogs.jpg", artistImage: "Drake.jpg", duration: Duration(minutes: 4, seconds: 15)),
        const Track(videoId: "049jphNTX2Q", title: "IDGAF", artist: "Drake, Yeat", albumImage: "For-All-The-Dogs.jpg", artistImage: "Drake.jpg", duration: Duration(minutes: 3, seconds: 8)),
        const Track(videoId: "hRVOoQG6QVE", title: "Slime You Out (feat. SZA)", artist: "Drake, SZA", albumImage: "For-All-The-Dogs.jpg", artistImage: "Drake.jpg", duration: Duration(minutes: 4, seconds: 2)),
      ];
      final albumTracks = tracks.map((t) => AlbumTrack(t.title, t.artist)).toList();
      return Album(
        'For-All-The-Dogs.jpg', "For All The Dogs", "Drake", albumTracks,
        "2023", "Drake.jpg",
        [const Color(0xff7c837b), const Color(0xff313330), const Color(0xff151515)],
        tracks: tracks,
      );
    } else if (singer == "Travis Scott") {
      final tracks = [
        const Track(videoId: "FW3Pd7KwNc4", title: "HYENA", artist: "Travis Scott", albumImage: "UTOPIA.jpg", artistImage: "Travis-Scott.jpg", duration: Duration(minutes: 3, seconds: 4)),
        const Track(videoId: "Y2WjKJI2cVY", title: "THANK GOD", artist: "Travis Scott", albumImage: "UTOPIA.jpg", artistImage: "Travis-Scott.jpg", duration: Duration(minutes: 2, seconds: 48)),
        const Track(videoId: "5KZ0b4YsCbY", title: "MODERN JAM", artist: "Travis Scott", albumImage: "UTOPIA.jpg", artistImage: "Travis-Scott.jpg", duration: Duration(minutes: 3, seconds: 20)),
        const Track(videoId: "kYHsDqIk95o", title: "MY EYES", artist: "Travis Scott", albumImage: "UTOPIA.jpg", artistImage: "Travis-Scott.jpg", duration: Duration(minutes: 4, seconds: 50)),
        const Track(videoId: "qQ5RVHx0h4o", title: "GOD'S COUNTRY", artist: "Travis Scott", albumImage: "UTOPIA.jpg", artistImage: "Travis-Scott.jpg", duration: Duration(minutes: 3, seconds: 6)),
        const Track(videoId: "VZQKw8D8m6Q", title: "SIRENS", artist: "Travis Scott", albumImage: "UTOPIA.jpg", artistImage: "Travis-Scott.jpg", duration: Duration(minutes: 3, seconds: 30)),
        const Track(videoId: "tSj0w34WQxY", title: "MELTDOWN (feat. Drake)", artist: "Travis Scott, Drake", albumImage: "UTOPIA.jpg", artistImage: "Travis-Scott.jpg", duration: Duration(minutes: 3, seconds: 33)),
        const Track(videoId: "oTfOaV7sMhI", title: "FE!N (feat. Playboi Carti)", artist: "Travis Scott, Playboi Carti", albumImage: "UTOPIA.jpg", artistImage: "Travis-Scott.jpg", duration: Duration(minutes: 3, seconds: 12)),
      ];
      final albumTracks = tracks.map((t) => AlbumTrack(t.title, t.artist)).toList();
      return Album(
        'UTOPIA.jpg', "UTOPIA", "Travis Scott", albumTracks,
        "2023", "Travis-Scott.jpg",
        [const Color(0xff544444), const Color(0xff252120), const Color(0xff131313)],
        tracks: tracks,
      );
    } else if (singer == "Post Malone") {
      final tracks = [
        const Track(videoId: "e5xRqbF9FbI", title: "Don't Understand", artist: "Post Malone", albumImage: "AUSTIN.jpg", artistImage: "Post-Malone.jpg", duration: Duration(minutes: 3, seconds: 14)),
        const Track(videoId: "Z6d7mVfFbHQ", title: "Something Real", artist: "Post Malone", albumImage: "AUSTIN.jpg", artistImage: "Post-Malone.jpg", duration: Duration(minutes: 2, seconds: 56)),
        const Track(videoId: "Q1pGebdCqOY", title: "Chemical", artist: "Post Malone", albumImage: "AUSTIN.jpg", artistImage: "Post-Malone.jpg", duration: Duration(minutes: 3, seconds: 18)),
        const Track(videoId: "oFnJxV9bKuY", title: "Novacandy", artist: "Post Malone", albumImage: "AUSTIN.jpg", artistImage: "Post-Malone.jpg", duration: Duration(minutes: 3, seconds: 23)),
        const Track(videoId: "QfW9GfK1a_0", title: "Mourning", artist: "Post Malone", albumImage: "AUSTIN.jpg", artistImage: "Post-Malone.jpg", duration: Duration(minutes: 2, seconds: 48)),
        const Track(videoId: "u6PwVkOQ0aY", title: "Too Cool To Die", artist: "Post Malone", albumImage: "AUSTIN.jpg", artistImage: "Post-Malone.jpg", duration: Duration(minutes: 3, seconds: 6)),
        const Track(videoId: "cZpK0pDqTcM", title: "Sign Me Up", artist: "Post Malone", albumImage: "AUSTIN.jpg", artistImage: "Post-Malone.jpg", duration: Duration(minutes: 3, seconds: 37)),
        const Track(videoId: "vP0R1N7W3eQ", title: "Socialite", artist: "Post Malone", albumImage: "AUSTIN.jpg", artistImage: "Post-Malone.jpg", duration: Duration(minutes: 3, seconds: 11)),
        const Track(videoId: "HfBHsCpB0kE", title: "Enough Is Enough", artist: "Post Malone", albumImage: "AUSTIN.jpg", artistImage: "Post-Malone.jpg", duration: Duration(minutes: 2, seconds: 45)),
      ];
      final albumTracks = tracks.map((t) => AlbumTrack(t.title, t.artist)).toList();
      return Album(
        'AUSTIN.jpg', "AUSTIN", "Post Malone", albumTracks,
        "2023", "Post-Malone.jpg",
        [const Color(0xff8b9a63), const Color(0xff363a2b), const Color(0xff151513)],
        tracks: tracks,
      );
    } else if (singer == "21 Savage") {
      final tracks = [
        const Track(videoId: "DydRf3fY8rI", title: "american dream", artist: "21 Savage", albumImage: "american-dream.jpg", artistImage: "21-Savage.jpg", duration: Duration(minutes: 3, seconds: 17)),
        const Track(videoId: "aLdY7KJq3Gg", title: "all of me", artist: "21 Savage", albumImage: "american-dream.jpg", artistImage: "21-Savage.jpg", duration: Duration(minutes: 3, seconds: 5)),
        const Track(videoId: "gHwFSMN2pE8", title: "redrum", artist: "21 Savage", albumImage: "american-dream.jpg", artistImage: "21-Savage.jpg", duration: Duration(minutes: 3, seconds: 38)),
        const Track(videoId: "vKkxQzR9GPw", title: "n.h.i.e", artist: "21 Savage, Doja Cat", albumImage: "american-dream.jpg", artistImage: "21-Savage.jpg", duration: Duration(minutes: 3, seconds: 0)),
        const Track(videoId: "xq7WcMnL6WY", title: "sneaky", artist: "21 Savage", albumImage: "american-dream.jpg", artistImage: "21-Savage.jpg", duration: Duration(minutes: 2, seconds: 48)),
        const Track(videoId: "V5Kz6ZfFx1I", title: "pop ur shit", artist: "21 Savage, Young Thug, Metro Boomin", albumImage: "american-dream.jpg", artistImage: "21-Savage.jpg", duration: Duration(minutes: 3, seconds: 22)),
        const Track(videoId: "Q2F9cE6hX5o", title: "letter to my brudda", artist: "21 Savage", albumImage: "american-dream.jpg", artistImage: "21-Savage.jpg", duration: Duration(minutes: 2, seconds: 54)),
      ];
      final albumTracks = tracks.map((t) => AlbumTrack(t.title, t.artist)).toList();
      return Album(
        'american-dream.jpg', "american dream", "21 Savage", albumTracks,
        "2023", "21-Savage.jpg",
        [const Color(0xff747474), const Color(0xff343434), const Color(0xff121212)],
        tracks: tracks,
      );
    }
    return Album("", "", "", [], "", "", []);
  }
}
