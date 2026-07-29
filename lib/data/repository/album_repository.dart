import 'package:tunefy/DI/service_locator.dart';
import 'package:tunefy/data/datasource/album_datasource.dart';
import 'package:tunefy/data/model/album.dart';

abstract class AlbumRepository {
  Future<Album> albumList(String singer);
}

class AlbumLocalRepository extends AlbumRepository {
  final AlbumDatasource _albumLocalDatasource = locator.get();
  @override
  Future<Album> albumList(String singer) async {
    return await _albumLocalDatasource.albumList(singer);
  }
}
