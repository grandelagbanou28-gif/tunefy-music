CREATE TABLE IF NOT EXISTS sync_config (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  source TEXT NOT NULL UNIQUE,
  enabled BOOLEAN NOT NULL DEFAULT true,
  frequency_hours INTEGER NOT NULL DEFAULT 6,
  batch_size INTEGER NOT NULL DEFAULT 50,
  last_run TIMESTAMPTZ,
  last_success TIMESTAMPTZ,
  last_error TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

INSERT INTO sync_config (source, enabled, frequency_hours, batch_size) VALUES
  ('jamendo', true, 6, 50),
  ('audius', true, 6, 50),
  ('youtube', true, 2, 50),
  ('itunes', true, 3, 50)
ON CONFLICT (source) DO NOTHING;

CREATE TABLE IF NOT EXISTS categories (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name TEXT NOT NULL UNIQUE,
  slug TEXT NOT NULL UNIQUE,
  description TEXT,
  genre_filter TEXT,
  source TEXT,
  sort_order INTEGER DEFAULT 0,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

INSERT INTO categories (name, slug, genre_filter, sort_order) VALUES
  ('Nouveautes aujourd''hui', 'nouveautes-aujourd-hui', NULL, 1),
  ('Nouveaux albums', 'nouveaux-albums', NULL, 2),
  ('Nouveaux EP', 'nouveaux-ep', NULL, 3),
  ('Nouveaux singles', 'nouveaux-singles', NULL, 4),
  ('Nouvelles playlists', 'nouvelles-playlists', NULL, 5),
  ('Nouveautes de la semaine', 'nouveautes-semaine', NULL, 6),
  ('Nouveautes du mois', 'nouveautes-mois', NULL, 7),
  ('Tendances', 'tendances', NULL, 8),
  ('Decouvertes', 'decouvertes', NULL, 9),
  ('Rap FR', 'rap-fr', 'rap fr', 10),
  ('Rap US', 'rap-us', 'rap us', 11),
  ('Afro', 'afro', 'afrobeat', 12),
  ('Amapiano', 'ampiano', 'ampiano', 13),
  ('RnB', 'rnb', 'rnb', 14),
  ('Hip-Hop', 'hip-hop', 'hip hop', 15),
  ('Pop', 'pop', 'pop', 16),
  ('Gospel', 'gospel', 'gospel', 17),
  ('Dancehall', 'dancehall', 'dancehall', 18),
  ('Reggae', 'reggae', 'reggae', 19),
  ('Musique africaine', 'african', NULL, 20)
ON CONFLICT (slug) DO NOTHING;