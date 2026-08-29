-- Tunefy Gospel catalog — 0002_gospel_artists
-- Public read-only catalog (seeded via SQL editor / service role; app users
-- only ever SELECT it). Run this in: Dashboard → SQL Editor → New query → Run.

create table if not exists public.gospel_artists (
  id               uuid primary key default gen_random_uuid(),
  name             text not null,
  type             text not null default 'artist',
  country          text,
  country_code     text,
  categories       text[] not null default '{}',
  languages        text[] not null default '{}',
  verified         boolean not null default false,
  image_url        text,
  official_website text,
  spotify_id       text,
  apple_music_id   text,
  youtube_channel_id text,
  source_url       text,
  last_verified    timestamptz,
  created_at       timestamptz not null default now(),
  updated_at       timestamptz not null default now()
);
create unique index if not exists gospel_artists_name_key
  on public.gospel_artists (lower(name));
create index if not exists gospel_artists_country_idx
  on public.gospel_artists (country_code);
create index if not exists gospel_artists_category_idx
  on public.gospel_artists using gin (categories);

-- RLS: everybody may read the catalog; rows are written only via the SQL
-- editor / service_role (no user write policies).
alter table public.gospel_artists enable row level security;
drop policy if exists "gospel_artists_read" on public.gospel_artists;
create policy "gospel_artists_read" on public.gospel_artists
  for select using (true);

drop trigger if exists gospel_artists_touch on public.gospel_artists;
create trigger gospel_artists_touch before update on public.gospel_artists
  for each row execute function public.touch_updated_at();

-- ═══════════════════════════ SEED ═══════════════════════════
-- Insertion idempotente (relançable sans doublons).
insert into public.gospel_artists
  (name, type, country, country_code, categories, languages, verified, source_url)
values
-- ─────────────── 🇧🇯 BÉNIN ───────────────
('John Migan',        'artist', 'Bénin', 'BJ', '{"Worship & Praise","Contemporary"}', '{Fr}', true, 'https://www.musicinafrica.net/node/15664'),
('Arnauld Migan',     'artist', 'Bénin', 'BJ', '{"Worship & Praise"}', '{Fr}', true, 'https://www.musicinafrica.net/node/15664'),
('Miriam Ayizansi',   'artist', 'Bénin', 'BJ', '{"Worship & Praise"}', '{Fr}', true, 'https://www.musicinafrica.net/node/15664'),
('Anna Tèko',         'artist', 'Bénin', 'BJ', '{"Worship & Praise"}', '{Fr}', true, 'https://www.musicinafrica.net/node/11704'),
('Jonny Sourou',      'artist', 'Bénin', 'BJ', '{"Worship & Praise"}', '{Fr}', true, 'https://www.musicinafrica.net/node/15664'),
('Sandra Heriti',     'artist', 'Bénin', 'BJ', '{"Worship & Praise"}', '{Fr}', true, 'https://www.musicinafrica.net/node/15664'),
('Sessimè',           'artist', 'Bénin', 'BJ', '{"Worship & Praise","Traditional"}', '{Fr}', true, 'https://www.musicinafrica.net/node/15664'),
('Kinzah',            'artist', 'Bénin', 'BJ', '{"Worship & Praise"}', '{Fr}', true, 'https://www.musicinafrica.net/node/15664'),
('Dossi',             'artist', 'Bénin', 'BJ', '{"Worship & Praise","Contemporary"}', '{Fr}', true, 'https://www.musicinafrica.net/node/15664'),
('Kinivi',            'artist', 'Bénin', 'BJ', '{"Worship & Praise"}', '{Fr}', true, 'https://www.musicinafrica.net/node/15664'),
('Ange Ahouangonou',  'artist', 'Bénin', 'BJ', '{"Worship & Praise"}', '{Fr}', true, 'https://www.musicinafrica.net/node/15664'),
('Désiré Kindomihou', 'artist', 'Bénin', 'BJ', '{"Worship & Praise","Contemporary"}', '{Fr}', true, 'https://www.musicinafrica.net/node/15664'),
('Apollinaire Gandonou', 'artist', 'Bénin', 'BJ', '{"Worship & Praise","Traditional"}', '{Fr}', true, 'https://www.musicinafrica.net/node/15664'),
('Carina Sen',        'artist', 'Bénin', 'BJ', '{"Worship & Praise","R&B"}', '{Fr}', true, 'https://musicinafrica.net/fr/directory/carina-sen/'),
('Kevynn',            'artist', 'Bénin', 'BJ', '{"Worship & Praise"}', '{Fr}', true, 'https://www.musicinafrica.net/fr/magazine/benin-la-decouverte-du-chanteur-kevynn-linconditionnel-de-la-foi-divine'),
('Sam Sèwèdo',        'artist', 'Bénin', 'BJ', '{"Worship & Praise","Traditional"}', '{Fr}', false, 'https://www.musicinafrica.net/node/21546'),
('Dandjiozon',        'artist', 'Bénin', 'BJ', '{"Worship & Praise","Traditional Gospel"}', '{Fr}', true, 'https://beninbookingpro.com/product-category/artistes-animation/artistes-de-musique-gospel/'),
('Chantreresse Mihodè', 'artist', 'Bénin', 'BJ', '{"Worship & Praise"}', '{Fr}', true, 'https://beninbookingpro.com/product-category/artistes-animation/artistes-de-musique-gospel/'),
-- Déjà curatés côté app (listes de référence existantes)
('Siano Bless',       'artist', 'Bénin', 'BJ', '{"Worship & Praise"}', '{Fr}', false, NULL),
('Sam Bhlu',          'artist', 'Bénin', 'BJ', '{"Worship & Praise"}', '{Fr}', false, NULL),
('Yvan pour Yésué',   'artist', 'Bénin', 'BJ', '{"Worship & Praise"}', '{Fr}', false, NULL),
('Yvan pour Yesue',   'artist', 'Bénin', 'BJ', '{"Worship & Praise"}', '{Fr}', false, NULL),
('Sir Abilé',         'artist', 'Bénin', 'BJ', '{"Worship & Praise"}', '{Fr}', false, NULL),
('Sir Abile',         'artist', 'Bénin', 'BJ', '{"Worship & Praise"}', '{Fr}', false, NULL),
('Paul Kouton',       'artist', 'Bénin', 'BJ', '{"Worship & Praise","Traditional"}', '{Fr}', false, NULL),
('Alphonse Gandonou', 'artist', 'Bénin', 'BJ', '{"Worship & Praise"}', '{Fr}', false, NULL),
('Félix Didolanvi',   'artist', 'Bénin', 'BJ', '{"Worship & Praise"}', '{Fr}', false, NULL),
('Felix Didolanvi',   'artist', 'Bénin', 'BJ', '{"Worship & Praise"}', '{Fr}', false, NULL),
('Zeynab Habib',      'artist', 'Bénin', 'BJ', '{"Worship & Praise"}', '{Fr}', false, NULL),

-- ─────────────── 🇳🇬 NIGÉRIA · Worship / Praise ───────────────
('Nathaniel Bassey',  'artist', 'Nigeria', 'NG', '{"Worship","Praise"}', '{En}', false, 'https://nathanielbassey.com/about-me/'),
('Sinach',            'artist', 'Nigeria', 'NG', '{"Worship","Praise"}', '{En}', false, NULL),
('Dunsin Oyekan',     'artist', 'Nigeria', 'NG', '{"Worship","Praise"}', '{En}', false, NULL),
('Mercy Chinwo',      'artist', 'Nigeria', 'NG', '{"Worship","Praise"}', '{En}', false, NULL),
('Moses Bliss',       'artist', 'Nigeria', 'NG', '{"Worship","Praise"}', '{En}', false, NULL),
('Frank Edwards',     'artist', 'Nigeria', 'NG', '{"Worship","Praise"}', '{En}', false, NULL),
('Eben',              'artist', 'Nigeria', 'NG', '{"Worship","Praise"}', '{En}', false, NULL),
('Steve Crown',       'artist', 'Nigeria', 'NG', '{"Worship","Praise"}', '{En}', false, NULL),
('Prospa Ochimana',   'artist', 'Nigeria', 'NG', '{"Worship","Praise"}', '{En}', false, NULL),
('Victoria Orenze',   'artist', 'Nigeria', 'NG', '{"Worship","Praise"}', '{En}', false, NULL),
('Minister GUC',      'artist', 'Nigeria', 'NG', '{"Worship","Praise"}', '{En}', false, NULL),
('Judikay',           'artist', 'Nigeria', 'NG', '{"Worship","Praise"}', '{En}', false, NULL),
('Peterson Okopi',    'artist', 'Nigeria', 'NG', '{"Worship","Praise"}', '{En}', false, NULL),
('Neon Adejo',        'artist', 'Nigeria', 'NG', '{"Worship","Praise"}', '{En}', false, NULL),
('Kaestrings',        'artist', 'Nigeria', 'NG', '{"Worship","Praise"}', '{En}', false, NULL),
('Emmanuel Iren',     'artist', 'Nigeria', 'NG', '{"Worship","Praise"}', '{En}', false, NULL),
('Lawrence Oyor',     'artist', 'Nigeria', 'NG', '{"Worship","Praise"}', '{En}', false, NULL),
('Theophilus Sunday', 'artist', 'Nigeria', 'NG', '{"Worship","Praise"}', '{En}', false, NULL),
('Abbey Ojomu',       'artist', 'Nigeria', 'NG', '{"Worship","Praise"}', '{En}', false, NULL),
('Sunmisola Agbebi',  'artist', 'Nigeria', 'NG', '{"Worship","Praise"}', '{En}', false, NULL),
('Preye Odede',       'artist', 'Nigeria', 'NG', '{"Worship","Praise"}', '{En}', false, NULL),
('Joe Praize',        'artist', 'Nigeria', 'NG', '{"Worship","Praise"}', '{En}', false, NULL),
('Tim Godfrey',       'artist', 'Nigeria', 'NG', '{"Worship","Praise"}', '{En}', false, NULL),
('Ada Ehi',           'artist', 'Nigeria', 'NG', '{"Worship","Praise"}', '{En}', false, NULL),
('Samsong',           'artist', 'Nigeria', 'NG', '{"Worship","Praise"}', '{En}', false, NULL),
('Chris Morgan',      'artist', 'Nigeria', 'NG', '{"Worship","Praise"}', '{En}', false, NULL),
('David G',           'artist', 'Nigeria', 'NG', '{"Worship","Praise"}', '{En}', false, NULL),
('Onos Ariyo',        'artist', 'Nigeria', 'NG', '{"Worship","Praise"}', '{En}', false, NULL),
('Yadah',             'artist', 'Nigeria', 'NG', '{"Worship","Praise"}', '{En}', false, NULL),
('Efe Nathan',        'artist', 'Nigeria', 'NG', '{"Worship","Praise"}', '{En}', false, NULL),
('Pat Uwaje King',    'artist', 'Nigeria', 'NG', '{"Worship","Praise"}', '{En}', false, NULL),
('Monique',           'artist', 'Nigeria', 'NG', '{"Worship","Praise"}', '{En}', false, NULL),
-- Yoruba / Gospel traditionnel
('Tope Alabi',        'artist', 'Nigeria', 'NG', '{"Traditional (Yoruba)"}', '{En,Yo}', false, NULL),
('Sola Allyson',      'artist', 'Nigeria', 'NG', '{"Traditional (Yoruba)"}', '{En,Yo}', false, NULL),
('Bola Are',          'artist', 'Nigeria', 'NG', '{"Traditional (Yoruba)"}', '{En,Yo}', false, NULL),
('Funmi Aragbaye',    'artist', 'Nigeria', 'NG', '{"Traditional (Yoruba)"}', '{En,Yo}', false, NULL),
('Adeyinka Alaseyori', 'artist', 'Nigeria', 'NG', '{"Traditional (Yoruba)"}', '{En,Yo}', false, NULL),
('Bukola Bekes',      'artist', 'Nigeria', 'NG', '{"Traditional (Yoruba)"}', '{En,Yo}', false, NULL),
('Dunni Olanrewaju',  'artist', 'Nigeria', 'NG', '{"Traditional (Yoruba)"}', '{En,Yo}', false, NULL),
('Yinka Ayefele',     'artist', 'Nigeria', 'NG', '{"Traditional (Yoruba)"}', '{En,Yo}', false, NULL),
-- Igbo Gospel
('Chioma Jesus',      'artist', 'Nigeria', 'NG', '{"Igbo Gospel"}', '{En,Ig}', false, NULL),
('Chinyere Udoma',    'artist', 'Nigeria', 'NG', '{"Igbo Gospel"}', '{En,Ig}', false, NULL),
-- Afro-Gospel / Urban
('Limoblaze',         'artist', 'Nigeria', 'NG', '{"Afro-Gospel","Urban"}', '{En}', false, NULL),
('Greatman Takit',    'artist', 'Nigeria', 'NG', '{"Afro-Gospel","Urban"}', '{En}', false, NULL),
('Prinx Emmanuel',    'artist', 'Nigeria', 'NG', '{"Afro-Gospel","Urban"}', '{En}', false, NULL),
('Gaise Baba',        'artist', 'Nigeria', 'NG', '{"Afro-Gospel","Urban"}', '{En}', false, NULL),
('Marizu',            'artist', 'Nigeria', 'NG', '{"Afro-Gospel","Urban"}', '{En}', false, NULL),
('Angeloh',           'artist', 'Nigeria', 'NG', '{"Afro-Gospel","Urban"}', '{En}', false, NULL),
('Festizie',          'artist', 'Nigeria', 'NG', '{"Afro-Gospel","Urban"}', '{En}', false, NULL),
('Anendlessocean',    'artist', 'Nigeria', 'NG', '{"Afro-Gospel","Urban"}', '{En}', false, NULL),
('K3ndrick',          'artist', 'Nigeria', 'NG', '{"Afro-Gospel","Urban"}', '{En}', false, NULL),
('Rehmahz',           'artist', 'Nigeria', 'NG', '{"Afro-Gospel","Urban"}', '{En}', false, NULL),
('Snatcha',           'artist', 'Nigeria', 'NG', '{"Afro-Gospel","Urban"}', '{En}', false, NULL),
('Bouqui',            'artist', 'Nigeria', 'NG', '{"Afro-Gospel","Urban"}', '{En}', false, NULL),
('Buchi',             'artist', 'Nigeria', 'NG', '{"Afro-Gospel","Urban"}', '{En}', false, NULL),
('Sammie Okposo',     'artist', 'Nigeria', 'NG', '{"Worship","Praise"}', '{En}', false, NULL),
('Panam Percy Paul',  'artist', 'Nigeria', 'NG', '{"Worship","Praise"}', '{En}', false, NULL),
('Annatoria',         'artist', 'Nigeria', 'NG', '{"Worship","Praise"}', '{En}', false, NULL),
('Victor Thompson',   'artist', 'Nigeria', 'NG', '{"Worship","Praise"}', '{En}', false, NULL),

-- ─────────────── 🇬🇭 GHANA ───────────────
('Joe Mettle',        'artist', 'Ghana', 'GH', '{"Worship","Contemporary"}', '{En,Tw}', false, NULL),
('Diana Hamilton',    'artist', 'Ghana', 'GH', '{"Worship","Contemporary"}', '{En,Tw}', false, NULL),
('Sonnie Badu',       'artist', 'Ghana', 'GH', '{"Worship"}', '{En,Tw}', false, NULL),
('MOGmusic',          'artist', 'Ghana', 'GH', '{"Worship"}', '{En,Tw}', false, NULL),
('Ebo Taylor',        'artist', 'Ghana', 'GH', '{"Traditional","Highlife"}', '{En,Tw}', false, NULL),
('Celestine Donkor',  'artist', 'Ghana', 'GH', '{"Worship","Contemporary"}', '{En,Tw}', false, NULL),
('Kofi Kari Kari',    'artist', 'Ghana', 'GH', '{"Worship"}', '{En,Tw}', false, NULL),
('Ohemaa Mercy',      'artist', 'Ghana', 'GH', '{"Worship","Praise"}', '{En,Tw}', false, NULL),
('Piesie Esther',     'artist', 'Ghana', 'GH', '{"Worship"}', '{En,Tw}', false, NULL),
('Nacee',             'artist', 'Ghana', 'GH', '{"Worship"}', '{En,Tw}', false, NULL),
('Joyce Blessing',    'artist', 'Ghana', 'GH', '{"Worship"}', '{En,Tw}', false, NULL),
('Obaapa Christy',    'artist', 'Ghana', 'GH', '{"Worship"}', '{En,Tw}', false, NULL),
('Diana Asamoah',     'artist', 'Ghana', 'GH', '{"Worship"}', '{En,Tw}', false, NULL),
('KODA',              'artist', 'Ghana', 'GH', '{"Worship"}', '{En,Tw}', false, NULL),
('Ceccy Twum',        'artist', 'Ghana', 'GH', '{"Worship"}', '{En,Tw}', false, NULL),
('Daughters of Glorious Jesus', 'group', 'Ghana', 'GH', '{"Ensemble"}', '{En,Tw}', false, NULL),
('Tagoe Sisters',     'group', 'Ghana', 'GH', '{"Ensemble"}', '{En,Tw}', false, NULL),
('Yaw Sarpong',       'artist', 'Ghana', 'GH', '{"Traditional"}', '{En,Tw}', false, NULL),
('Philipa Baafi',     'artist', 'Ghana', 'GH', '{"Worship"}', '{En,Tw}', false, NULL),

-- ─────────────── 🇨🇮 CÔTE D'IVOIRE ───────────────
('Morijah',            'artist', "Côte d'Ivoire", 'CI', '{"Worship","Afro-Gospel"}', '{Fr}', false, NULL),
('KS Bloom',           'artist', "Côte d'Ivoire", 'CI', '{"Afro-Gospel","Urban","Rap"}', '{Fr}', false, NULL),
('Roseline Layo',      'artist', "Côte d'Ivoire", 'CI', '{"Worship","Contemporary"}', '{Fr}', false, NULL),
('Constance',          'artist', "Côte d'Ivoire", 'CI', '{"Worship"}', '{Fr}', false, NULL),
('Lydie Koffi',        'artist', "Côte d'Ivoire", 'CI', '{"Worship","Afro-Gospel"}', '{Fr}', false, NULL),

-- ─────────────── 🇨🇩 RDC ───────────────
('Moïse Mbiye',        'artist', 'RD Congo', 'CD', '{"Worship","Contemporary"}', '{Fr,Li}', false, NULL),
('Mike Kalambay',      'artist', 'RD Congo', 'CD', '{"Worship"}', '{Fr,Li}', false, NULL),
('Dena Mwana',         'artist', 'RD Congo', 'CD', '{"Worship"}', '{Fr,Li}', false, NULL),
('Athom''s Mbuma',     'artist', 'RD Congo', 'CD', '{"Worship"}', '{Fr,Li}', false, NULL),
('Sandra Mbuyi',       'artist', 'RD Congo', 'CD', '{"Worship"}', '{Fr,Li}', false, NULL),
('Deborah Lukalu',     'artist', 'RD Congo', 'CD', '{"Worship"}', '{Fr,Li}', false, NULL),
('Eunice Manyanga',    'artist', 'RD Congo', 'CD', '{"Worship"}', '{Fr,Li}', false, NULL),
('Gospel Life',        'group', 'RD Congo', 'CD', '{"Ensemble","Worship"}', '{Fr,Li}', false, NULL),
('Jonathan Yoyo',      'artist', 'RD Congo', 'CD', '{"Worship"}', '{Fr,Li}', false, NULL),
('Unis Par Le Sang',   'group', 'RD Congo', 'CD', '{"Ensemble"}', '{Fr,Li}', false, NULL),

-- ─────────────── 🇿🇦 AFRIQUE DU SUD ───────────────
('Benjamin Dube',      'artist', 'Afrique du Sud', 'ZA', '{"Praise","Contemporary"}', '{En,Zu}', false, NULL),
('Ntokozo Mbambo',     'artist', 'Afrique du Sud', 'ZA', '{"Worship","Contemporary"}', '{En,Zu}', false, NULL),
('Sipho Makhabane',    'artist', 'Afrique du Sud', 'ZA', '{"Worship"}', '{En,Zu}', false, NULL),
('Dr Tumi',            'artist', 'Afrique du Sud', 'ZA', '{"Worship"}', '{En,Zu}', false, NULL),
('Bucy Radebe',        'artist', 'Afrique du Sud', 'ZA', '{"Worship"}', '{En,Zu}', false, NULL),
('Spirit of Praise',   'group', 'Afrique du Sud', 'ZA', '{"Ensemble","Worship"}', '{En,Zu}', false, NULL),
('Joyous Celebration', 'group', 'Afrique du Sud', 'ZA', '{"Ensemble","Praise"}', '{En,Zu}', false, NULL),
('Rebecca Malope',     'artist', 'Afrique du Sud', 'ZA', '{"Traditional","Praise"}', '{En,Zu}', false, NULL),
('Lebo Sekgobela',     'artist', 'Afrique du Sud', 'ZA', '{"Worship"}', '{En,Zu}', false, NULL),
('Xolly Mncwango',     'artist', 'Afrique du Sud', 'ZA', '{"Worship"}', '{En,Zu}', false, NULL),

-- ─────────────── 🇰🇪 KENYA / Afrique de l'Est ───────────────
('Daddy Owen',         'artist', 'Kenya', 'KE', '{"Afro-Gospel","Urban"}', '{En,Sw}', false, NULL),
('Ruth Kome',          'artist', 'Kenya', 'KE', '{"Worship"}', '{En,Sw}', false, NULL),
('Mtimkavu',           'artist', 'Kenya', 'KE', '{"Worship"}', '{En,Sw}', false, NULL),

-- ─────────────── 🇺🇸 ÉTATS-UNIS ───────────────
('Kirk Franklin',      'artist', 'États-Unis', 'US', '{"Contemporary","Gospel Choir"}', '{En}', false, NULL),
('CeCe Winans',        'artist', 'États-Unis', 'US', '{"Contemporary","Worship"}', '{En}', false, NULL),
('Tye Tribbett',       'artist', 'États-Unis', 'US', '{"Contemporary"}', '{En}', false, NULL),
('Donnie McClurkin',   'artist', 'États-Unis', 'US', '{"Traditional","Contemporary"}', '{En}', false, NULL),
('Marvin Sapp',        'artist', 'États-Unis', 'US', '{"Contemporary","Praise"}', '{En}', false, NULL),
('Yolanda Adams',      'artist', 'États-Unis', 'US', '{"Contemporary"}', '{En}', false, NULL),
('Fred Hammond',       'artist', 'États-Unis', 'US', '{"Contemporary"}', '{En}', false, NULL),
('Israel Houghton',    'artist', 'États-Unis', 'US', '{"Worship","Contemporary"}', '{En}', false, NULL),
('Travis Greene',      'artist', 'États-Unis', 'US', '{"Contemporary","Worship"}', '{En}', false, NULL),
('Jonathan McReynolds','artist', 'États-Unis', 'US', '{"Contemporary"}', '{En}', false, NULL),
('Todd Dulaney',       'artist', 'États-Unis', 'US', '{"Worship","Contemporary"}', '{En}', false, NULL),
('Maverick City Music','group', 'États-Unis', 'US', '{"Ensemble","Worship"}', '{En}', false, NULL),
('Elevation Worship',  'group', 'États-Unis', 'US', '{"Ensemble","Worship"}', '{En}', false, NULL),
('Bethel Music',       'group', 'États-Unis', 'US', '{"Ensemble","Worship"}', '{En}', false, NULL),
('Kari Jobe',          'artist', 'États-Unis', 'US', '{"Worship"}', '{En}', false, NULL),
('Brandon Lake',       'artist', 'États-Unis', 'US', '{"Worship"}', '{En}', false, NULL),
('Phil Wickham',       'artist', 'États-Unis', 'US', '{"Worship"}', '{En}', false, NULL),
('Chris Tomlin',       'artist', 'États-Unis', 'US', '{"Worship"}', '{En}', false, NULL),
('Hillsong UNITED',    'group', 'États-Unis', 'US', '{"Ensemble","Worship"}', '{En}', false, NULL),
('Hillsong Worship',   'group', 'États-Unis', 'US', '{"Ensemble","Worship"}', '{En}', false, NULL),
('Tasha Cobbs',        'artist', 'États-Unis', 'US', '{"Contemporary","Worship"}', '{En}', false, NULL),
('Hezekiah Walker',    'artist', 'États-Unis', 'US', '{"Traditional","Gospel Choir"}', '{En}', false, NULL),
('Kierra Sheard',      'artist', 'États-Unis', 'US', '{"Contemporary"}', '{En}', false, NULL),
('Shirley Caesar',     'artist', 'États-Unis', 'US', '{"Traditional","Gospel Choir"}', '{En}', false, NULL),
('Bishop Paul Morton', 'artist', 'États-Unis', 'US', '{"Traditional","Gospel Choir"}', '{En}', false, NULL),

-- ─────────────── 🇬🇧 ROYAUME-UNI ───────────────
('CalledOut Music',    'artist', 'Royaume-Uni', 'GB', '{"Afro-Gospel","Urban"}', '{En}', false, NULL),
('Noel Robinson',      'artist', 'Royaume-Uni', 'GB', '{"Contemporary","Worship"}', '{En}', false, NULL),
('Guvna B',            'artist', 'Royaume-Uni', 'GB', '{"Afro-Gospel","Urban","Rap"}', '{En}', false, NULL),
('Lurine Cato',        'artist', 'Royaume-Uni', 'GB', '{"Contemporary"}', '{En}', false, NULL),
('Muyiwa Olarewaju',   'artist', 'Royaume-Uni', 'GB', '{"Afro-Gospel","Worship"}', '{En}', false, NULL),

-- ─────────────── 🇨🇦 CANADA (francophone) ───────────────
('Maggie Blanchard',   'artist', 'Canada', 'CA', '{"Worship"}', '{Fr}', false, NULL),
('Impact',             'group', 'Canada', 'CA', '{"Ensemble","Worship"}', '{Fr}', false, NULL),
('Sébastien Corn',     'artist', 'Canada', 'CA', '{"Worship","Contemporary"}', '{Fr}', false, NULL),

-- ─────────────── 🇫🇷 FRANCE / Gospel francophone ───────────────
('Dan Luiten',         'artist', 'France', 'FR', '{"Worship","Contemporary"}', '{Fr}', false, NULL),
('Hillsong FR',        'group', 'France', 'FR', '{"Ensemble","Worship"}', '{Fr}', false, NULL),
('Collectif Cieux Ouverts', 'group', 'France', 'FR', '{"Ensemble","Worship"}', '{Fr}', false, NULL),
('Mirella',            'artist', 'France', 'FR', '{"Worship"}', '{Fr}', false, NULL),
('Marcel Boungou',     'artist', 'France', 'FR', '{"Worship"}', '{Fr}', false, NULL),
('Glorious',           'group', 'France', 'FR', '{"Ensemble","Worship"}', '{Fr}', false, NULL),
('Angela Lartigue',    'artist', 'France', 'FR', '{"Worship"}', '{Fr}', false, NULL),
('Fabrice Colson',     'artist', 'France', 'FR', '{"Worship","Contemporary"}', '{Fr}', false, NULL),
('Matt Marvane',       'artist', 'France', 'FR', '{"Worship","Afro-Gospel"}', '{Fr}', false, NULL),
('Miri B',             'artist', 'France', 'FR', '{"Worship"}', '{Fr}', false, NULL),
('Samuel Sesay',       'artist', 'France', 'FR', '{"Worship"}', '{Fr}', false, NULL),
('Enock Tady',         'artist', 'France', 'FR', '{"Worship"}', '{Fr}', false, NULL),
('Matthieu Semhoum',   'artist', 'France', 'FR', '{"Worship"}', '{Fr}', false, NULL),
('Lex',                'artist', 'France', 'FR', '{"Worship","Urban"}', '{Fr}', false, NULL)
on conflict ((lower(name))) do nothing;