import 'package:tunefy/DI/service_locator.dart';
import 'package:tunefy/data/datasource/playlist_datasource.dart';
import 'package:tunefy/data/model/playlist.dart';

abstract class PLaylistRepository {
  Future<Playlist> getList(String mix);
}

class PlaylistLocalRepository extends PLaylistRepository {
  final PlaylistDatasource _datasource = locator.get();
  @override
  Future<Playlist> getList(String mix) async {
    return await _datasource.trackList(mix);
  }
}
