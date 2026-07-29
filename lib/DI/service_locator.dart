import 'package:get_it/get_it.dart';
import 'package:tunefy/data/datasource/album_datasource.dart';
import 'package:tunefy/data/datasource/artist_datasource.dart';
import 'package:tunefy/data/datasource/playlist_datasource.dart';
import 'package:tunefy/data/datasource/podcast_datasource.dart';
import 'package:tunefy/data/repository/album_repository.dart';
import 'package:tunefy/data/repository/artist_repository.dart';
import 'package:tunefy/data/repository/playlist_repository.dart';
import 'package:tunefy/data/repository/podcast_repository.dart';
import 'package:tunefy/providers/player_provider.dart';
export 'package:tunefy/providers/player_provider.dart';

var locator = GetIt.instance;

PlayerProvider? _playerProvider;

PlayerProvider get playerProvider {
  _playerProvider ??= PlayerProvider();
  return _playerProvider!;
}

void initServiceLocator() {
  locator.registerSingleton<ArtistDatasource>(ArtistLocalDatasource());
  locator.registerSingleton<PodcastDatasource>(PodcastLocalDatasource());
  locator.registerSingleton<AlbumDatasource>(AlbumDatasource());
  locator.registerSingleton<PlaylistDatasource>(PLaylistLocalDatasource());

  locator.registerSingleton<ArtistRepository>(ArtistLocalRepository());
  locator.registerSingleton<PodcastRepository>(PodcastLocalRepository());
  locator.registerSingleton<AlbumRepository>(AlbumLocalRepository());
  locator.registerSingleton<PLaylistRepository>(PlaylistLocalRepository());
}
