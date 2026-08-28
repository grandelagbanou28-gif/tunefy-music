/// Architecture de résolution de catégorie par type.
///
/// Chaque type de catégorie a une stratégie différente :
/// - **Genre musical** : tag structuré Jamendo/Audius + fallback ytify/iTunes
/// - **Géo-spécifique** : base d'artistes confirmés + validation stricte
/// - **Decades** : filtrer par date réelle de sortie API, pas de mot-clé
/// - **Mood** : croiser genre + énergie/BPM si dispo, sinon tags éditoriaux
/// - **Charts** : endpoints de classement officiels, pas de popularité de recherche
/// - **Default** : recherche texte libre avec validation
library;

import 'package:muzo/models/muzo_item.dart';

// ═══════════════════════════════════════════════════════════════════════════════
// TYPES DE CATÉGORIE
// ═══════════════════════════════════════════════════════════════════════════════

enum CategoryType {
  /// Genre musical large (Pop, Rock, Jazz, Hip-Hop, Gospel, Afrobeats...).
  /// Stratégie : tag structuré sur APIs qui le supportent.
  genre,

  /// Géo-spécifique de niche (Hit Benin, Rap Français, Benin Gospel...).
  /// Stratégie : base d'artistes confirmés + validation stricte.
  geoSpecific,

  /// Décennie (1990s, 2000s...).
  /// Stratégie : filtrer par date réelle de sortie retournée par l'API.
  decades,

  /// Mood (Chill, Energetic, Focus...).
  /// Stratégie : croiser genre + BPM/énergie si dispo, sinon tags.
  mood,

  /// Charts / Trending (Global Top 50, Benin Charts...).
  /// Stratégie : endpoints de classement officiels.
  charts,

  /// Podcasts / contenu non-musical.
  /// Stratégie : sources dédiées distinctes.
  podcast,

  /// Stratégie par défaut (fallback).
  /// Stratégie : recherche texte libre avec validation.
  fallback,
}

// ═══════════════════════════════════════════════════════════════════════════════
// LOGGING STRUCTURÉ
// ═══════════════════════════════════════════════════════════════════════════════

/// Log détaillé d'une tentative de résolution pour une source donnée.
class ResolutionLog {
  final String source;
  final String query;
  final int rawCount;
  final int accepted;
  final int rejected;
  final String decision;
  final Duration duration;

  const ResolutionLog({
    required this.source,
    required this.query,
    required this.rawCount,
    required this.accepted,
    required this.rejected,
    required this.decision,
    required this.duration,
  });

  @override
  String toString() =>
      '[$source] "$query" → $rawCount raw, $accepted accepted, '
      '$rejected rejected ($decision) in ${duration.inMilliseconds}ms';
}

/// Résultat complet de la résolution d'une sous-catégorie.
class CategoryResolutionResult {
  final List<MuzoItem> songs;
  final List<ResolutionLog> logs;
  final CategoryType type;

  const CategoryResolutionResult({
    required this.songs,
    required this.logs,
    required this.type,
  });

  /// Résumé humain-readable pour le mode debug.
  String get summary {
    final buf = StringBuffer();
    buf.writeln('═══ ${type.name.toUpperCase()} ═══');
    for (final log in logs) {
      buf.writeln('  $log');
    }
    buf.writeln('  → ${songs.length} songs affichés');
    return buf.toString();
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// CLASSE ABSTRAITE
// ═══════════════════════════════════════════════════════════════════════════════

/// Un resolver résout une sous-catégorie en une liste de MuzoItem validés.
///
/// Chaque sous-classe implémente la stratégie adaptée à son type de catégorie.
abstract class CategoryResolver {
  /// Résout une sous-catégorie et retourne les résultats + logs.
  Future<CategoryResolutionResult> resolve({
    required String category,
    required String sub,
    required Set<String> excludedArtists,
  });
}

// ═══════════════════════════════════════════════════════════════════════════════
// FACTORY
// ═══════════════════════════════════════════════════════════════════════════════

/// Détermine le type de catégorie et retourne le resolver adapté.
///
/// Matrice de mapping (catégorie → type) basée sur la spec :
///
/// | Catégorie | Type | Résolveur |
/// |-----------|------|-----------|
/// | Pop, Rock, Jazz, Hip-Hop... | genre | GenreResolver |
/// | Hit Benin, Rap Français... | geoSpecific | GeoSpecificResolver |
/// | Decades 1990s, 2000s... | decades | DecadesResolver |
/// | Mood, Chill, Workout... | mood | MoodResolver |
/// | Charts, Top 50... | charts | ChartsResolver |
/// | Podcasts | podcast | PodcastResolver |
/// | Autre | default | DefaultResolver |
class CategoryResolverFactory {
  static final Map<String, CategoryType> _categoryTypes = {
    // Genre musical large
    'pop': CategoryType.genre,
    'rock': CategoryType.genre,
    'jazz': CategoryType.genre,
    'hip-hop': CategoryType.genre,
    'rap': CategoryType.genre,
    'r&b': CategoryType.genre,
    'soul': CategoryType.genre,
    'gospel': CategoryType.genre,
    'latin': CategoryType.genre,
    'country': CategoryType.genre,
    'classical': CategoryType.genre,
    'electronic': CategoryType.genre,
    'reggae': CategoryType.genre,
    'metal': CategoryType.genre,
    'blues': CategoryType.genre,
    'folk & acoustic': CategoryType.genre,
    'funk': CategoryType.genre,
    'house': CategoryType.genre,
    'afrobeats': CategoryType.genre,
    'afro hits': CategoryType.genre,
    'k-pop': CategoryType.genre,
    'indie': CategoryType.genre,
    'lo-fi beats': CategoryType.genre,
    'chanson francaise': CategoryType.genre,
    'rap francais': CategoryType.genre,
    'comedy': CategoryType.genre,
    'desi': CategoryType.genre,
    'reggae': CategoryType.genre,

    // Géo-spécifique
    'hit benin': CategoryType.geoSpecific,
    'trending': CategoryType.charts,

    // Decades
    'decades': CategoryType.decades,

    // Mood
    'mood': CategoryType.mood,
    'workout': CategoryType.mood,
    'focus': CategoryType.mood,
    'sleep': CategoryType.mood,
    'party': CategoryType.mood,
    'chill': CategoryType.mood,
    'romance': CategoryType.mood,
    'meditation': CategoryType.mood,

    // Charts
    'charts': CategoryType.charts,

    // Podcast
    'podcasts': CategoryType.podcast,

    // Default (tout le reste)
    'music': CategoryType.fallback,
    'new releases': CategoryType.fallback,
    'made for you': CategoryType.fallback,
    'news & politics': CategoryType.podcast,
    'amapiano': CategoryType.genre,
    'bande originale': CategoryType.genre,
    'dancehall': CategoryType.genre,
    'musique arabe': CategoryType.genre,
    'rumba congolaise': CategoryType.genre,
    'drill': CategoryType.genre,
    'caribbean': CategoryType.genre,
  };

  /// Détermine le type d'une catégorie.
  static CategoryType typeFor(String category) {
    final key = category.trim().toLowerCase();
    return _categoryTypes[key] ?? CategoryType.fallback;
  }

  /// Détermine le type d'une sous-catégorie en combinant catégorie + sub.
  ///
  /// Ex: ("Gospel", "Benin Gospel") → geoSpecific (pas genre, car geo-scopé)
  static CategoryType typeForSub(String category, String sub) {
    final catKey = category.trim().toLowerCase();
    final subKey = sub.trim().toLowerCase();

    // Si la sous-catégorie contient un nom de pays → geoSpecific
    const geoPatterns = [
      'benin', 'nigerian', 'ghana', 'french', 'african', 'us ', 'uk ',
      'american', 'british', 'cotonou', 'porto-novo',
    ];
    for (final p in geoPatterns) {
      if (subKey.contains(p)) return CategoryType.geoSpecific;
    }

    // Si la catégorie est geoSpecific, la sous-catégorie l'est aussi
    if (typeFor(catKey) == CategoryType.geoSpecific) {
      return CategoryType.geoSpecific;
    }

    // Sinon, le type de la catégorie parent
    return typeFor(catKey);
  }
}
