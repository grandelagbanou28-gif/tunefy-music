import 'package:flutter_test/flutter_test.dart';
import 'package:muzo/models/muzo_item.dart';
import 'package:muzo/services/gospel_artist_database.dart';
import 'package:muzo/services/strict_category_filter.dart';

MuzoItem song(String title, String artist, {String? album, int duration = 240}) {
  return MuzoItem(
    title: title,
    thumbnails: const [],
    resultType: 'video',
    isExplicit: false,
    videoId: 'v-$title-$artist',
    artists: [MuzoArtist(name: artist, id: null)],
    album: album != null ? MuzoAlbum(name: album, id: '') : null,
    durationSeconds: duration,
  );
}

void main() {
  group('constraint resolution', () {
    test('Gospel Benin -> genre gospel + geo benin', () {
      final c = categoryConstraintFor('Gospel', 'Benin Gospel');
      expect(c.genre, 'gospel');
      expect(c.geo, 'benin');
      expect(c.isGeoScoped, isTrue);
      expect(c.includeMarkers, contains('benin'));
      expect(c.includeMarkers, contains('cotonou'));
      expect(c.excludeMarkers, isNot(contains('benin')));
      expect(c.excludeMarkers, contains('lagos'));
      expect(c.excludeMarkers, contains('american'));
    });

    test('African Gospel -> geo africa, keeps same-region markers as includes',
        () {
      final c = categoryConstraintFor('Gospel', 'African Gospel');
      expect(c.geo, 'africa');
      expect(c.excludeMarkers, isNot(contains('nigerian')));
      expect(c.excludeMarkers, isNot(contains('lagos')));
      expect(c.excludeMarkers, contains('american'));
      expect(c.excludeMarkers, contains('bollywood'));
    });

    test('scoped search term is composite, never bare category name', () {
      expect(
        buildScopedSearchTerm('Gospel', 'Benin Gospel', 'gospel'),
        'gospel benin',
      );
      expect(
        buildScopedSearchTerm('Rap', 'Rap Français', 'rap'),
        'rap français',
      );
    });
  });

  group('gospel artist database', () {
    test('Fanicko is NOT gospel (R&B/afrobeat)', () {
      expect(gospelArtistGeo('Fanicko'), isNull);
      expect(gospelArtistGeo('Fanicko Officiel'), isNull);
    });

    test('Siano Bless is confirmed Beninese gospel', () {
      expect(gospelArtistGeo('Siano Bless'), 'benin');
      expect(gospelArtistGeo('Siano Bless Officiel'), 'benin');
    });

    test('Sinach is confirmed Nigerian gospel', () {
      expect(gospelArtistGeo('Sinach'), 'nigeria');
      expect(gospelArtistGeo('Sinach - Topic'), 'nigeria');
    });

    test('region containment', () {
      expect(regionContainsGeo('africa', 'nigeria'), isTrue);
      expect(regionContainsGeo('africa', 'usa'), isFalse);
      expect(regionContainsGeo('benin', 'nigeria'), isFalse);
      expect(regionContainsGeo('benin', 'benin'), isTrue);
    });
  });

  group('Gospel Benin strict validation', () {
    final c = categoryConstraintFor('Gospel', 'Benin Gospel');

    test('real Beninese gospel artists are ACCEPTED', () {
      expect(acceptsForCategory(song('Oh Merci Seigneur', 'Siano Bless'), c),
          isTrue);
      expect(acceptsForCategory(song('Dossou Idjè', 'Anna Tèko'), c), isTrue);
    });

    test('Fanicko (Beninese but R&B, not gospel) is REJECTED', () {
      expect(acceptsForCategory(song('Folies', 'Fanicko'), c), isFalse);
    });

    test('Nigerian gospel is REJECTED from Benin Gospel', () {
      expect(
        acceptsForCategory(song('Tobechukwu', 'Nathaniel Bassey'), c),
        isFalse,
      );
      expect(acceptsForCategory(song('Excess Love', 'Mercy Chinwo'), c),
          isFalse);
      expect(acceptsForCategory(song('Way Maker', 'Sinach'), c), isFalse);
    });

    test('US gospel is REJECTED', () {
      expect(
        acceptsForCategory(song('American Gospel Hits', 'Bethel Music'), c),
        isFalse,
      );
    });

    test('unknown artist: genre word AND country marker both required', () {
      // "Gospel" word + Cotonou marker -> in.
      expect(
        acceptsForCategory(
            song('Gospel Praise from Cotonou', 'Chorale Alleluia'), c),
        isTrue,
      );
      // Genre word but no Benin marker -> out.
      expect(acceptsForCategory(song('Gospel Hymns', 'Unknown Choir'), c),
          isFalse);
      // No genre word, no country -> out.
      expect(acceptsForCategory(song('Folies', 'X-TIME'), c), isFalse);
    });
  });

  group('African Gospel (region) validation', () {
    final c = categoryConstraintFor('Gospel', 'African Gospel');

    test('Nigerian gospel is ACCEPTED inside the Africa region', () {
      expect(acceptsForCategory(song('Tobechukwu', 'Nathaniel Bassey'), c),
          isTrue);
      expect(acceptsForCategory(song('Excess Love', 'Mercy Chinwo'), c),
          isTrue);
    });

    test('Beninese gospel is ACCEPTED inside the Africa region', () {
      expect(acceptsForCategory(song('Oh Merci Seigneur', 'Siano Bless'), c),
          isTrue);
    });

    test('US gospel is REJECTED from African Gospel', () {
      expect(acceptsForCategory(song('Way Maker', 'Bethel Music'), c), isFalse);
    });
  });

  group('Ghana gospel validation', () {
    final c = categoryConstraintFor('Gospel', 'Ghana Gospel');

    test('Ghanaian gospel accepted, Nigerian rejected', () {
      expect(acceptsForCategory(song('Nhyira', 'Joe Mettle'), c), isTrue);
      expect(acceptsForCategory(song('Tobechukwu', 'Nathaniel Bassey'), c),
          isFalse);
    });
  });

  group('pure genre section (non-geo)', () {
    test('genre word or confirmed gospel artist required', () {
      final c = categoryConstraintFor('Gospel', 'Gospel');
      expect(c.geo, isEmpty);
      expect(acceptsForCategory(song('Gospel Sunday Service', 'Kirk Franklin'), c),
          isTrue);
      // Confirmed gospel artist without "gospel" in the title.
      expect(acceptsForCategory(song('Way Maker', 'Sinach'), c), isTrue);
      // R&B artist, no genre word -> out.
      expect(acceptsForCategory(song('Party All Night', 'DJ Random'), c),
          isFalse);
    });
  });

  group('detectGeo', () {
    test('never guesses a country from a bare genre', () {
      expect(detectGeo('Gospel', 'Gospel'), isNull);
      expect(detectGeo('Rap', 'Gangster Rap'), isNull);
    });
  });
}
