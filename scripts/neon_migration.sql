-- ═══════════════════════════════════════════════════════════════════════════════
-- Migration: Create artists table for Tunefy
-- Execute this in the Neon SQL editor or via psql
-- ═══════════════════════════════════════════════════════════════════════════════

CREATE TABLE IF NOT EXISTS artists (
  id TEXT PRIMARY KEY,
  nom_officiel TEXT NOT NULL,
  alias JSONB DEFAULT '[]'::jsonb,
  pays TEXT NOT NULL,
  genres JSONB DEFAULT '[]'::jsonb,
  sous_categories JSONB DEFAULT '[]'::jsonb,
  niveau_confiance TEXT NOT NULL DEFAULT 'confirmed'
    CHECK (niveau_confiance IN ('confirmed', 'probable')),
  sources JSONB DEFAULT '[]'::jsonb,
  date_ajout TEXT NOT NULL DEFAULT '',
  date_derniere_verification TEXT NOT NULL DEFAULT '',
  ids_externes JSONB DEFAULT '{}'::jsonb,
  exclusions JSONB DEFAULT '[]'::jsonb,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Indexes for fast lookups
CREATE INDEX IF NOT EXISTS idx_artists_pays ON artists (pays);
CREATE INDEX IF NOT EXISTS idx_artists_niveau ON artists (niveau_confiance);
CREATE INDEX IF NOT EXISTS idx_artists_genres ON artists USING gin (genres);
CREATE INDEX IF NOT EXISTS idx_artists_sous_categories ON artists USING gin (sous_categories);

-- Updated_at trigger
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ language 'plpgsql';

DROP TRIGGER IF EXISTS update_artists_updated_at ON artists;
CREATE TRIGGER update_artists_updated_at
  BEFORE UPDATE ON artists
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();

-- ═══════════════════════════════════════════════════════════════════════════════
-- Seed data — 18 confirmed Beninese artists
-- ═══════════════════════════════════════════════════════════════════════════════

INSERT INTO artists (id, nom_officiel, alias, pays, genres, sous_categories, niveau_confiance, sources, date_ajout, date_derniere_verification)
VALUES
  ('sam-bhlu', 'Sam Bhlu', '["Samson Metonve Houndegla"]', 'Benin', '["gospel"]', '["Benin Gospel", "Worship"]', 'confirmed', '["myaddictive.com"]', '2025-01-01', '2025-01-01'),
  ('yvan-pour-yesue', 'Yvan pour Yésué', '[]', 'Benin', '["gospel"]', '["Benin Gospel", "Worship"]', 'confirmed', '["myaddictive.com"]', '2025-01-01', '2025-01-01'),
  ('sir-abile', 'Sir Abilé', '[]', 'Benin', '["gospel"]', '["Benin Gospel"]', 'probable', '["myaddictive.com"]', '2025-01-01', '2025-01-01'),
  ('fanicko', 'Fanicko', '["Olivier Fanicko Adjanohoun", "Fanicko de Jésus"]', 'Benin', '["gospel", "urban"]', '["Benin Gospel", "Top Benin"]', 'confirmed', '["streetartparis.fr"]', '2025-01-01', '2025-01-01'),
  ('le-renoi', 'Le Renoi', '["Hounye Francois-Xavier Noutin"]', 'Benin', '["rap"]', '["Benin Rap", "Top Benin"]', 'confirmed', '["streetartparis.fr"]', '2025-01-01', '2025-01-01'),
  ('dibi-dobo', 'Dibi Dobo', '[]', 'Benin', '["hip-hop", "rnb"]', '["Benin Rap", "Top Benin"]', 'confirmed', '["lepetitjournal.com"]', '2025-01-01', '2025-01-01'),
  ('axel-merryl', 'Axel Merryl', '[]', 'Benin', '["afrobeats", "pop"]', '["Benin Afrobeats", "Benin Pop", "Top Benin"]', 'confirmed', '["critikmag.com"]', '2025-01-01', '2025-01-01'),
  ('nikanor', 'Nikanor', '[]', 'Benin', '["afrobeats", "pop"]', '["Benin Afrobeats", "Top Benin"]', 'probable', '["redlist.com"]', '2025-01-01', '2025-01-01'),
  ('santrinos-raphael', 'Santrinos Raphael', '[]', 'Benin', '["afrobeats"]', '["Benin Afrobeats", "Top Benin"]', 'probable', '["redlist.com"]', '2025-01-01', '2025-01-01'),
  ('vano-baby', 'Vano Baby', '[]', 'Benin', '["afrobeats"]', '["Benin Afrobeats", "Top Benin"]', 'probable', '["redlist.com"]', '2025-01-01', '2025-01-01'),
  ('madano', 'Madano', '[]', 'Benin', '["afrobeats"]', '["Benin Afrobeats", "Top Benin"]', 'probable', '["redlist.com"]', '2025-01-01', '2025-01-01'),
  ('gg-lapino', 'GG Lapino', '[]', 'Benin', '["afrobeats", "urban"]', '["Benin Afrobeats", "Top Benin"]', 'probable', '["streetartparis.fr"]', '2025-01-01', '2025-01-01'),
  ('sessime', 'Sessimè', '[]', 'Benin', '["pop", "world"]', '["Benin Pop", "Top Benin"]', 'confirmed', '["streetartparis.fr"]', '2025-01-01', '2025-01-01'),
  ('angelique-kidjo', 'Angélique Kidjo', '[]', 'Benin', '["world", "jazz", "gospel", "afrobeats"]', '["Benin Afrobeats", "Afro Hits", "Top Benin"]', 'confirmed', '["critikmag.com", "wikipedia.org"]', '2025-01-01', '2025-01-01'),
  ('gangbe-brass-band', 'Gangbé Brass Band', '[]', 'Benin', '["jazz", "traditional"]', '["Afro Hits", "Jazz"]', 'confirmed', '["lepetitjournal.com"]', '2025-01-01', '2025-01-01'),
  ('zeynab-habib', 'Zeynab Habib', '[]', 'Benin', '["world"]', '["Afro Hits", "Top Benin"]', 'confirmed', '["lepetitjournal.com", "wikipedia.org"]', '2025-01-01', '2025-01-01'),
  ('dossi-dossi', 'Dossi Dossi', '[]', 'Benin', '["tradi-moderne"]', '["Top Benin"]', 'probable', '["voluncorp.com"]', '2025-01-01', '2025-01-01'),
  ('teriba', 'Teriba', '[]', 'Benin', '["tradi-moderne"]', '["Top Benin"]', 'probable', '["voluncorp.com"]', '2025-01-01', '2025-01-01'),
  ('sandra-heriti', 'Sandra Heriti', '[]', 'Benin', '["gospel"]', '["Benin Gospel"]', 'probable', '["voluncorp.com"]', '2025-01-01', '2025-01-01')
ON CONFLICT (id) DO UPDATE SET
  nom_officiel = EXCLUDED.nom_officiel,
  alias = EXCLUDED.alias,
  pays = EXCLUDED.pays,
  genres = EXCLUDED.genres,
  sous_categories = EXCLUDED.sous_categories,
  niveau_confiance = EXCLUDED.niveau_confiance,
  sources = EXCLUDED.sources,
  date_derniere_verification = EXCLUDED.date_derniere_verification;
