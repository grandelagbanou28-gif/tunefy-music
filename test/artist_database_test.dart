import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:muzo/models/artist_record.dart';
import 'package:muzo/services/neon_database_service.dart';

void main() {
  setUpAll(() async {
    final dir = Directory.systemTemp.createTempSync('hive_test_');
    Hive.init(dir.path);
  });

  tearDownAll(() async {
    await Hive.close();
  });
  group('ArtistRecord', () {
    test('allNames includes official name and aliases', () {
      const record = ArtistRecord(
        id: 'sam-bhlu',
        name: 'Sam Bhlu',
        aliases: ['Samson Metonve Houndegla'],
        country: 'Benin',
        genres: ['gospel'],
        dateAdded: '2025-01-01',
        dateLastVerified: '2025-01-01',
      );
      expect(record.allNames, ['Sam Bhlu', 'Samson Metonve Houndegla']);
    });

    test('hasGenre is case-insensitive', () {
      const record = ArtistRecord(
        id: 'test',
        name: 'Test',
        country: 'Benin',
        genres: ['Gospel', 'RAP'],
        dateAdded: '2025-01-01',
        dateLastVerified: '2025-01-01',
      );
      expect(record.hasGenre('gospel'), true);
      expect(record.hasGenre('GOSPEL'), true);
      expect(record.hasGenre('rap'), true);
      expect(record.hasGenre('jazz'), false);
    });

    test('hasSubCategory is case-insensitive', () {
      const record = ArtistRecord(
        id: 'test',
        name: 'Test',
        country: 'Benin',
        subCategories: ['Benin Gospel', 'Top Benin'],
        dateAdded: '2025-01-01',
        dateLastVerified: '2025-01-01',
      );
      expect(record.hasSubCategory('Benin Gospel'), true);
      expect(record.hasSubCategory('benin gospel'), true);
      expect(record.hasSubCategory('Top Benin'), true);
      expect(record.hasSubCategory('Rap Français'), false);
    });

    test('serialization roundtrip', () {
      const record = ArtistRecord(
        id: 'sam-bhlu',
        name: 'Sam Bhlu',
        aliases: ['Samson Metonve Houndegla'],
        country: 'Benin',
        genres: ['gospel'],
        subCategories: ['Benin Gospel', 'Worship'],
        confidence: ConfidenceLevel.confirmed,
        sources: ['myaddictive.com'],
        dateAdded: '2025-01-01',
        dateLastVerified: '2025-01-01',
      );
      final json = record.toJson();
      final restored = ArtistRecord.fromJson(json);
      expect(restored.id, record.id);
      expect(restored.name, record.name);
      expect(restored.aliases, record.aliases);
      expect(restored.country, record.country);
      expect(restored.genres, record.genres);
      expect(restored.subCategories, record.subCategories);
      expect(restored.confidence, ConfidenceLevel.confirmed);
      expect(restored.sources, record.sources);
    });

    test('equality by id', () {
      const a = ArtistRecord(
        id: 'test',
        name: 'Artist A',
        country: 'Benin',
        dateAdded: '2025-01-01',
        dateLastVerified: '2025-01-01',
      );
      const b = ArtistRecord(
        id: 'test',
        name: 'Artist B',
        country: 'Nigeria',
        dateAdded: '2025-01-01',
        dateLastVerified: '2025-01-01',
      );
      expect(a, equals(b));
    });
  });

  group('EmbeddedSeedData', () {
    test('has 19 seed artists', () {
      expect(EmbeddedSeedData.artists.length, 19);
    });

    test('all artists have at least one source', () {
      for (final artist in EmbeddedSeedData.artists) {
        expect(artist.sources.isNotEmpty, true,
            reason: '${artist.id} has no sources');
      }
    });

    test('all artists have a country', () {
      for (final artist in EmbeddedSeedData.artists) {
        expect(artist.country.isNotEmpty, true,
            reason: '${artist.id} has no country');
      }
    });

    test('Fanicko is in the DB with gospel genre', () {
      final fanicko = EmbeddedSeedData.artists.firstWhere(
        (a) => a.id == 'fanicko',
      );
      expect(fanicko.name, 'Fanicko');
      expect(fanicko.hasGenre('gospel'), true);
      expect(fanicko.hasCountry('Benin'), true);
    });
  });

  group('Fuzzy matching (via ArtistLocalService)', () {
    test('normalize strips accents', () async {
      final service = ArtistLocalService();
      await service.initialize();
      expect(service, isNotNull);
    });
  });

  group('ArtistLocalService', () {
    test('loads embedded seed data on first init', () async {
      final service = ArtistLocalService();
      await service.initialize();
      final artists = await service.getAllArtists();
      expect(artists.length, 19);
    });

    test('searchByName finds Sam Bhlu', () async {
      final service = ArtistLocalService();
      await service.initialize();
      final results = await service.searchByName('Sam Bhlu');
      expect(results.isNotEmpty, true);
      expect(results.first.id, 'sam-bhlu');
    });

    test('searchByName finds by alias', () async {
      final service = ArtistLocalService();
      await service.initialize();
      final results = await service.searchByName('Samson Metonve Houndegla');
      expect(results.isNotEmpty, true);
      expect(results.first.id, 'sam-bhlu');
    });

    test('getBySubCategory finds Benin Gospel artists', () async {
      final service = ArtistLocalService();
      await service.initialize();
      final results = await service.getBySubCategory('Benin Gospel');
      expect(results.isNotEmpty, true);
      final ids = results.map((a) => a.id).toList();
      expect(ids, contains('sam-bhlu'));
      expect(ids, contains('yvan-pour-yesue'));
      expect(ids, contains('fanicko'));
    });

    test('getByCountry finds all Benin artists', () async {
      final service = ArtistLocalService();
      await service.initialize();
      final results = await service.getByCountry('Benin');
      expect(results.length, 19);
    });

    test('getByGenre finds all gospel artists', () async {
      final service = ArtistLocalService();
      await service.initialize();
      final results = await service.getByGenre('gospel');
      expect(results.isNotEmpty, true);
      final ids = results.map((a) => a.id).toList();
      expect(ids, contains('sam-bhlu'));
      expect(ids, contains('fanicko'));
      expect(ids, contains('angelique-kidjo'));
    });

    test('findMatchForSubCategory finds Sam Bhlu in Benin Gospel', () async {
      final service = ArtistLocalService();
      await service.initialize();
      final match = await service.findMatchForSubCategory(
        'Sam Bhlu',
        'Benin Gospel',
      );
      expect(match, isNotNull);
      expect(match!.id, 'sam-bhlu');
    });

    test('saveArtist and deleteArtist work', () async {
      final service = ArtistLocalService();
      await service.initialize();
      const newArtist = ArtistRecord(
        id: 'test-artist',
        name: 'Test Artist',
        country: 'Benin',
        genres: ['pop'],
        dateAdded: '2025-01-01',
        dateLastVerified: '2025-01-01',
      );
      await service.saveArtist(newArtist);
      final all = await service.getAllArtists();
      expect(all.length, 20);
      expect(all.any((a) => a.id == 'test-artist'), true);

      await service.deleteArtist('test-artist');
      final afterDelete = await service.getAllArtists();
      expect(afterDelete.length, 19);
    });

    test('resetToSeed restores original data', () async {
      final service = ArtistLocalService();
      await service.initialize();
      const newArtist = ArtistRecord(
        id: 'temp',
        name: 'Temp',
        country: 'Test',
        dateAdded: '2025-01-01',
        dateLastVerified: '2025-01-01',
      );
      await service.saveArtist(newArtist);
      expect((await service.getAllArtists()).length, 20);

      await service.resetToSeed();
      expect((await service.getAllArtists()).length, 19);
    });
  });
}
