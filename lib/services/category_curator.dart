/// Editorial curation engine for category pages.
///
/// A real music client does not surface whatever a free-text search returns:
/// it shows what its editors would pick. This file encodes that editorial
/// logic — for every "Browse All" category we keep a short list of
/// internationally relevant artists (seeds) whose current releases drive the
/// category sections, plus a junk filter that keeps mix-tapes, megamixes,
/// "1 hour" loops, white-noise videos and karaoke out of the song sections.
///
/// Everything is keyless and works on the public iTunes Search API and the
/// muzo backend. Recency is enforced at runtime (current + previous year),
/// so the same seeds stay fresh year after year without code changes.
library;

import 'package:muzo/models/muzo_item.dart';

/// Artists that anchor each category. Order roughly mirrors "who is playing
/// right now" on the international stage (mainstream + global). Categories
/// without a solid artist anchor (sleep, focus, news, comedy, gaming, ...)
/// intentionally have no seeds: their sections use the plain term instead,
/// because those genres are dominated by ambient/long-form content.
const Map<String, List<String>> _categorySeeds = {
  'pop': [
    'Dua Lipa',
    'Sabrina Carpenter',
    'The Weeknd',
    'Taylor Swift',
    'Billie Eilish',
    'Ariana Grande',
    'Tate McRae',
    'Chappell Roan',
    'Bruno Mars',
  ],
  'hip hop': [
    'Kendrick Lamar',
    'Travis Scott',
    'Drake',
    '21 Savage',
    'J. Cole',
    'Future',
    'Metro Boomin',
    'Lil Baby',
  ],
  'rap': [
    'Kendrick Lamar',
    'Travis Scott',
    'J. Cole',
    'Future',
    '21 Savage',
    'Metro Boomin',
  ],
  'rock': [
    'Imagine Dragons',
    'Foo Fighters',
    'Arctic Monkeys',
    'Muse',
    'The Killers',
    'Linkin Park',
    'Kings of Leon',
  ],
  'latin': [
    'Bad Bunny',
    'Karol G',
    'Rauw Alejandro',
    'Anitta',
    'Shakira',
    'Feid',
    'J Balvin',
    'Maluma',
  ],
  'country': [
    'Luke Combs',
    'Morgan Wallen',
    'Zach Bryan',
    'Kane Brown',
    'Lainey Wilson',
    'Chris Stapleton',
  ],
  'r&b': [
    'SZA',
    'Usher',
    'Brent Faiyaz',
    'Giveon',
    'Jhené Aiko',
    'Chris Brown',
  ],
  'k-pop': [
    'Stray Kids',
    'ATEEZ',
    'NewJeans',
    'SEVENTEEN',
    'TXT',
    'IVE',
    'BTS',
    'BLACKPINK',
  ],
  'indie': [
    'Tame Impala',
    'Glass Animals',
    'Florence + the Machine',
    'Hozier',
    'Phoebe Bridgers',
    'Bon Iver',
  ],
  'workout': [
    'The Weeknd',
    'Kendrick Lamar',
    'Dua Lipa',
    'Imagine Dragons',
    'Eminem',
    'Skrillex',
    'David Guetta',
  ],
  'top hits': [
    'Taylor Swift',
    'The Weeknd',
    'Sabrina Carpenter',
    'Bad Bunny',
    'Kendrick Lamar',
    'Billie Eilish',
    'Lady Gaga',
  ],
  'oldies': [
    'Queen',
    'The Beatles',
    'Michael Jackson',
    'ABBA',
    'Fleetwood Mac',
    'Stevie Wonder',
    'Elton John',
  ],
  'party': [
    'Dua Lipa',
    'Drake',
    'Bad Bunny',
    'J Balvin',
    'Calvin Harris',
    'David Guetta',
    'Rihanna',
  ],
  'chill': [
    'FKJ',
    'Tom Misch',
    'Tycho',
    'Men I Trust',
    'Cigarettes After Sex',
    'Norah Jones',
  ],
  'chill mood': [
    'SZA',
    'Frank Ocean',
    'Lana Del Rey',
    'Cigarettes After Sex',
    'Men I Trust',
    'The Weeknd',
  ],
  'chill mix': [
    'FKJ',
    'Tom Misch',
    'Men I Trust',
    'Tycho',
    'Cigarettes After Sex',
    'Nujabes',
  ],
  'metal': [
    'Metallica',
    'Iron Maiden',
    'Slipknot',
    'Bring Me the Horizon',
    'Lamb of God',
    'Gojira',
  ],
  'blues': [
    'Gary Clark Jr.',
    'Joe Bonamassa',
    'Buddy Guy',
    'Keb\' Mo\'',
    'Eric Gales',
  ],
  'folk acoustic': [
    'Hozier',
    'Bon Iver',
    'Noah Kahan',
    'Mumford & Sons',
    'Ed Sheeran',
    'Vance Joy',
  ],
  'gospel': [
    'Kirk Franklin',
    'Tasha Cobbs Leonard',
    'Maverick City Music',
    'Lecrae',
    'Travis Greene',
  ],
  'funk': [
    'Bruno Mars',
    'Anderson .Paak',
    'Vulfpeck',
    'Thundercat',
    'Jamiroquai',
    'Nile Rodgers',
  ],
  'house music': [
    'Calvin Harris',
    'Disclosure',
    'RÜFÜS DU SOL',
    'John Summit',
    'Duke Dumont',
    'Meduza',
  ],
  'electronic': [
    'Calvin Harris',
    'David Guetta',
    'Kygo',
    'Marshmello',
    'Illenium',
    'Zedd',
    'Martin Garrix',
  ],
  'soul': [
    'Anderson .Paak',
    'Leon Bridges',
    'John Legend',
    'Alicia Keys',
    'Cleo Sol',
    'Aloe Blacc',
  ],
  'afro hits': [
    'Burna Boy',
    'Wizkid',
    'Davido',
    'Rema',
    'Asake',
    'Ayra Starr',
    'Tems',
  ],
  'afrobeats': [
    'Burna Boy',
    'Wizkid',
    'Davido',
    'Rema',
    'Asake',
    'Ayra Starr',
    'Tems',
  ],
  'chanson francaise': [
    'Aya Nakamura',
    'Stromae',
    'Angèle',
    'Soprano',
    'Vianney',
    'Clara Luciani',
    'Louane',
  ],
  'rap francais': [
    'Ninho',
    'GIMS',
    'SCH',
    'Jul',
    'Damso',
    'PLK',
    'Niska',
    'Gazo',
  ],
  'reggae': [
    'Chronixx',
    'Koffee',
    'Protoje',
    'Damian Marley',
    'Sean Paul',
    'Shaggy',
  ],
  'jazz': [
    'Norah Jones',
    'Gregory Porter',
    'Snarky Puppy',
    'Kamasi Washington',
    'Jacob Collier',
  ],
  'classical': [
    'Ludovico Einaudi',
    'Max Richter',
    'Lang Lang',
    'Yo-Yo Ma',
    'Yann Tiersen',
  ],
  'caribbean': [
    'Sean Paul',
    'Shaggy',
    'Koffee',
    'Popcaan',
    'Shenseea',
    'Masicka',
  ],
  'desi hits': [
    'Diljit Dosanjh',
    'AP Dhillon',
    'Arijit Singh',
    'Badshah',
    'Neha Kakkar',
    'Armaan Malik',
    'Atif Aslam',
  ],
  'romantic love songs': [
    'Ed Sheeran',
    'Adele',
    'Bruno Mars',
    'John Legend',
    'Taylor Swift',
    'Céline Dion',
  ],
  'new artists': [
    'Ayra Starr',
    'Tate McRae',
    'Chappell Roan',
    'Benson Boone',
    'Teddy Swims',
    'Central Cee',
  ],
  'women in music': [
    'Billie Eilish',
    'Dua Lipa',
    'SZA',
    'Karol G',
    'Taylor Swift',
    'Ariana Grande',
    'Ayra Starr',
    'Doja Cat',
  ],
  'alternative': [
    'Arctic Monkeys',
    'Tame Impala',
    'Radiohead',
    'The 1975',
    'Glass Animals',
    'Foals',
  ],
  'new release': [
    'Sabrina Carpenter',
    'The Weeknd',
    'Bad Bunny',
    'Kendrick Lamar',
    'Taylor Swift',
    'Dua Lipa',
    'Billie Eilish',
  ],
  'benin hits': [
    'Fanicko',
    'Siano Bless',
    'Zeynab Habib',
    'Blaaz',
  ],
};

/// Dedicated editorial anchor artists for specific sub-categories.
/// Ensures that sub-categories like "Salsa", "French Pop", "Drill FR", "K-Pop Girl Groups",
/// "1980s", etc. surface exact genre-compliant artists instead of fallback parent seeds.
const Map<String, List<String>> _subCategorySeeds = {
  // ─── LATIN ───
  'salsa': [
    'Marc Anthony',
    'Celia Cruz',
    'Willie Colón',
    'Hector Lavoe',
    'Frankie Ruiz',
    'Grupo Niche',
  ],
  'bachata': [
    'Romeo Santos',
    'Aventura',
    'Prince Royce',
    'Juan Luis Guerra',
    'Monchy & Alexandra',
  ],
  'reggaeton': [
    'Bad Bunny',
    'Karol G',
    'Rauw Alejandro',
    'Feid',
    'Daddy Yankee',
    'J Balvin',
  ],
  'latin pop': [
    'Shakira',
    'Rosalía',
    'Enrique Iglesias',
    'Ricky Martin',
    'Sebastián Yatra',
    'Camilo',
  ],
  'latin trap': [
    'Bad Bunny',
    'Anuel AA',
    'Myke Towers',
    'Eladio Carrión',
    'Arcángel',
  ],
  'regional mexican': [
    'Peso Pluma',
    'Fuerza Regida',
    'Natanael Cano',
    'Grupo Frontera',
    'Christian Nodal',
  ],
  'corridos': [
    'Peso Pluma',
    'Fuerza Regida',
    'Natanael Cano',
    'Junior H',
    'Eslabón Armado',
  ],
  'cumbia': [
    'Los Ángeles Azules',
    'Grupo Climax',
    'Carlos Vives',
    'Chicha Libre',
  ],
  'merengue': [
    'Juan Luis Guerra',
    'Elvis Crespo',
    'Olga Tañón',
    'Eddy Herrera',
  ],
  'brazilian': [
    'Anitta',
    'Ludmilla',
    'Alok',
    'Marília Mendonça',
    'Luísa Sonza',
  ],

  // ─── POP ───
  'french pop': [
    'Stromae',
    'Angèle',
    'Aya Nakamura',
    'Vianney',
    'Clara Luciani',
    'Louane',
    'Amir',
  ],
  'k-pop pop': [
    'NewJeans',
    'Stray Kids',
    'IVE',
    'TWICE',
    'LE SSERAFIM',
    'BTS',
    'BLACKPINK',
  ],
  'dance pop': [
    'Dua Lipa',
    'David Guetta',
    'Calvin Harris',
    'Bebe Rexha',
    'Ava Max',
    'Katy Perry',
  ],
  'teen pop': [
    'Olivia Rodrigo',
    'Sabrina Carpenter',
    'Tate McRae',
    'Billie Eilish',
    'Conan Gray',
  ],
  'electropop': [
    'Charli xcx',
    'Troye Sivan',
    'Dua Lipa',
    'Chappell Roan',
    'Lorde',
  ],
  'pop classics': [
    'Michael Jackson',
    'Madonna',
    'Prince',
    'Whitney Houston',
    'George Michael',
    'Cyndi Lauper',
  ],
  'us pop': [
    'Taylor Swift',
    'The Weeknd',
    'Sabrina Carpenter',
    'Ariana Grande',
    'Billie Eilish',
  ],
  'uk pop': [
    'Ed Sheeran',
    'Dua Lipa',
    'Harry Styles',
    'Adele',
    'Sam Smith',
    'Charli xcx',
  ],

  // ─── RAP FRANÇAIS & CHANSONS ───
  'rap fr': [
    'Ninho',
    'SCH',
    'Jul',
    'Damso',
    'PLK',
    'Niska',
    'Gazo',
    'GIMS',
    'SDM',
  ],
  'new rap fr': [
    'Werenoi',
    'SDM',
    'Gazo',
    'Tiakola',
    'Favé',
    'Kerchak',
  ],
  'drill fr': [
    'Gazo',
    'Freeze Corleone',
    'Ziak',
    'Koba LaD',
    'Central Cee',
    '13 Block',
  ],
  'trap fr': [
    'Ninho',
    'SCH',
    'Kaaris',
    'Niska',
    'Werenoi',
    'Koba LaD',
  ],
  'rap conscient': [
    'Damso',
    'Kery James',
    'Youssoupha',
    'Dinos',
    'Orelsan',
    'Lino',
  ],
  'rap 90s': [
    'IAM',
    'Suprême NTM',
    'MC Solaar',
    'Fonky Family',
    'Doc Gynéco',
    'Passi',
  ],
  'rap 2000s': [
    'Booba',
    'Rohff',
    'Sniper',
    'Sefyu',
    'Sinik',
    'Diam\'s',
    'Mafia K\'1 Fry',
  ],
  'rap 2010s': [
    'Ninho',
    'PNL',
    'Nekfeu',
    'Sextion d\'Assaut',
    'Lacrim',
    'Gradur',
  ],
  'rap 2020s': [
    'Ninho',
    'Gazo',
    'SDM',
    'Werenoi',
    'Tiakola',
    'PLK',
  ],
  'chansons françaises': [
    'Stromae',
    'Angèle',
    'Aya Nakamura',
    'Vianney',
    'Clara Luciani',
    'Louane',
    'Soprano',
  ],
  "chanson d'amour": [
    'Slimane',
    'Vianney',
    'Clara Luciani',
    'Louane',
    'Dadju',
    'Tayc',
  ],
  'chanson française classique': [
    'Edith Piaf',
    'Charles Aznavour',
    'Jacques Brel',
    'Georges Brassens',
    'Serge Gainsbourg',
    'Francis Cabrel',
  ],
  'variété française': [
    'Jean-Jacques Goldman',
    'Francis Cabrel',
    'Michel Sardou',
    'Johnny Hallyday',
    'Florent Pagny',
  ],

  // ─── HIP-HOP & RAP GLOBAL ───
  'trap': [
    'Travis Scott',
    'Metro Boomin',
    'Future',
    '21 Savage',
    'Lil Baby',
    'Gunna',
  ],
  'drill': [
    'Central Cee',
    'Pop Smoke',
    'Chief Keef',
    'Headie One',
    'Fivio Foreign',
  ],
  'boom bap': [
    'Joey Badass',
    'Nas',
    'J. Cole',
    'Logic',
    'Griselda',
    'Freddie Gibbs',
  ],
  'conscious hip-hop': [
    'Kendrick Lamar',
    'J. Cole',
    'Lupe Fiasco',
    'Common',
    'Talib Kweli',
  ],
  'alternative hip-hop': [
    'Tyler, The Creator',
    'BROCKHAMPTON',
    'JPEGMAFIA',
    'Danny Brown',
    'Vince Staples',
  ],
  'southern hip-hop': [
    'Outkast',
    'Future',
    'Lil Wayne',
    'T.I.',
    'Young Thug',
    '21 Savage',
  ],
  'east coast': [
    'Nas',
    'Jay-Z',
    'The Notorious B.I.G.',
    'Wu-Tang Clan',
    'J. Cole',
  ],
  'west coast': [
    'Kendrick Lamar',
    'Snoop Dogg',
    'Dr. Dre',
    'YG',
    'Roddy Ricch',
  ],

  // ─── ROCK ───
  'classic rock': [
    'Queen',
    'The Beatles',
    'Led Zeppelin',
    'Pink Floyd',
    'AC/DC',
    'The Rolling Stones',
  ],
  'alternative rock': [
    'Arctic Monkeys',
    'Radiohead',
    'Foo Fighters',
    'Muse',
    'The Killers',
    'Red Hot Chili Peppers',
  ],
  'indie rock': [
    'Arctic Monkeys',
    'The Strokes',
    'The 1975',
    'Phoenix',
    'Franz Ferdinand',
  ],
  'hard rock': [
    'AC/DC',
    'Guns N\' Roses',
    'Metallica',
    'Aerosmith',
    'Deep Purple',
  ],
  'punk rock': [
    'Green Day',
    'Blink-182',
    'The Offspring',
    'Sum 41',
    'Paramore',
  ],
  'pop rock': [
    'Imagine Dragons',
    'Maroon 5',
    'OneRepublic',
    'Coldplay',
    '5 Seconds of Summer',
  ],
  'progressive rock': [
    'Pink Floyd',
    'Rush',
    'Yes',
    'Tool',
    'Porcupine Tree',
  ],
  'psychedelic rock': [
    'Tame Impala',
    'Pink Floyd',
    'King Gizzard & The Lizard Wizard',
    'The Doors',
  ],
  'grunge': [
    'Nirvana',
    'Pearl Jam',
    'Soundgarden',
    'Alice in Chains',
    'Foo Fighters',
  ],

  // ─── DECADES ───
  '2020s': [
    'The Weeknd',
    'Dua Lipa',
    'Olivia Rodrigo',
    'Billie Eilish',
    'Sabrina Carpenter',
    'SZA',
  ],
  '2010s': [
    'Bruno Mars',
    'Katy Perry',
    'Drake',
    'Rihanna',
    'Justin Bieber',
    'Avicii',
    'Taylor Swift',
  ],
  '2000s': [
    'Beyoncé',
    'Eminem',
    '50 Cent',
    'Britney Spears',
    'Coldplay',
    'Usher',
    'Rihanna',
  ],
  '1990s': [
    'Nirvana',
    'Tupac',
    'The Notorious B.I.G.',
    'TLC',
    'Backstreet Boys',
    'Spice Girls',
    'Oasis',
  ],
  '1980s': [
    'Michael Jackson',
    'Prince',
    'Madonna',
    'Queen',
    'Whitney Houston',
    'A-ha',
    'Wham!',
  ],
  '1970s': [
    'ABBA',
    'Bee Gees',
    'Fleetwood Mac',
    'Elton John',
    'Stevie Wonder',
    'Eagles',
  ],
  '1960s': [
    'The Beatles',
    'The Rolling Stones',
    'Beach Boys',
    'Aretha Franklin',
    'Elvis Presley',
  ],
  '1950s': [
    'Elvis Presley',
    'Chuck Berry',
    'Little Richard',
    'Buddy Holly',
    'Johnny Cash',
  ],
  'classics': [
    'The Beatles',
    'Michael Jackson',
    'Queen',
    'ABBA',
    'Elvis Presley',
    'Bob Marley',
  ],

  // ─── K-POP ───
  'k-pop hits': [
    'Stray Kids',
    'NewJeans',
    'IVE',
    'ATEEZ',
    'SEVENTEEN',
    'TWICE',
    'BTS',
    'BLACKPINK',
  ],
  'new k-pop': [
    'NewJeans',
    'IVE',
    'RIIZE',
    'ZEROBASEONE',
    'BABYMONSTER',
    'ILLIT',
  ],
  'k-pop girl groups': [
    'NewJeans',
    'IVE',
    'BLACKPINK',
    'TWICE',
    'LE SSERAFIM',
    'aespa',
    'ITZY',
  ],
  'k-pop boy groups': [
    'Stray Kids',
    'BTS',
    'ATEEZ',
    'SEVENTEEN',
    'TXT',
    'ENHYPEN',
    'NCT 127',
  ],
  'soloists': [
    'IU',
    'Taeyeon',
    'Jungkook',
    'Jimin',
    'JISOO',
    'LISA',
    'BAEKHYUN',
  ],
  'k-r&b': [
    'DEAN',
    'Crush',
    'DPR LIVE',
    'BIBI',
    'Jay Park',
    'ZICO',
    'Heize',
  ],
  'korean ost': [
    'IU',
    'Gaho',
    '10cm',
    'Davichi',
    'Ailee',
    'V',
    'CHEN',
  ],

  // ─── AFROBEATS & AFRO HITS ───
  'afrobeats hits': [
    'Burna Boy',
    'Wizkid',
    'Davido',
    'Rema',
    'Asake',
    'Ayra Starr',
    'Tems',
  ],
  'new afrobeats': [
    'Asake',
    'Ayra Starr',
    'Rema',
    'Seyi Vibez',
    'Omah Lay',
    'Shallipopi',
  ],
  'amapiano': [
    'Kabza De Small',
    'DJ Maphorisa',
    'Focalistic',
    'Tyler ICU',
    'Uncle Waffles',
    'DBN Gogo',
  ],
  'nigerian afrobeats': [
    'Burna Boy',
    'Wizkid',
    'Davido',
    'Rema',
    'Asake',
    'Ayra Starr',
    'Fireboy DML',
  ],
  'ghanaian afrobeats': [
    'Shatta Wale',
    'Sarkodie',
    'Stonebwoy',
    'King Promise',
    'Black Sherif',
  ],
  'ivorian afrobeats': [
    'Didi B',
    'KS Bloom',
    'Serge Beynaud',
    'Josey',
    'Fior 2 Bior',
  ],
  'afro house': [
    'Black Coffee',
    'Master KG',
    'Prince Kaybee',
    'Sun-El Musician',
    'DJ Zinhle',
  ],

  // ─── HIT BENIN ───
  'top benin': [
    'Fanicko',
    'Blaaz',
    'Vano Baby',
    'Amir El Presidente',
    'Bobo Wê',
    'Siano Bless',
  ],
  'new benin': [
    'Vano Baby',
    'Bobo Wê',
    'Blaaz',
    'Tessia',
    'Sessimè',
  ],
  'benin rap': [
    'Blaaz',
    'Vano Baby',
    'Amir El Presidente',
    'Fils du Vent',
    'TBD',
  ],
  'benin afrobeats': [
    'Fanicko',
    'Tessia',
    'Sessimè',
    'Nikanor',
    'Zeynab Habib',
  ],
  'benin gospel': [
    'First King',
    'Kalamoulaï',
    'Session Bénin Gospel',
    'Dena Mwana',
  ],
  'cotonou hits': [
    'Fanicko',
    'Blaaz',
    'Vano Baby',
    'Siano Bless',
    'Nikanor',
  ],

  // ─── MOOD & WORKOUT ───
  'sad': [
    'Adele',
    'Billie Eilish',
    'Lewis Capaldi',
    'Olivia Rodrigo',
    'Phoebe Bridgers',
  ],
  'happy': [
    'Bruno Mars',
    'Pharrell Williams',
    'Mark Ronson',
    'Katy Perry',
    'Lizzo',
  ],
  'energetic': [
    'Eminem',
    'Imagine Dragons',
    'Kanye West',
    'Skrillex',
    'David Guetta',
  ],
  'romantic': [
    'Ed Sheeran',
    'John Legend',
    'Adele',
    'Taylor Swift',
    'Bruno Mars',
  ],
  'gym': [
    'Eminem',
    'Kanye West',
    'David Guetta',
    'Skrillex',
    'Kendrick Lamar',
  ],
  'running': [
    'The Weeknd',
    'Dua Lipa',
    'Calvin Harris',
    'David Guetta',
    'Tiësto',
  ],
  'boxing': [
    'Eminem',
    '50 Cent',
    'Pop Smoke',
    'Roy Jones Jr.',
    'Neffex',
  ],

  // ─── REGGAE, JAZZ, CLASSICAL, ELECTRONIC, METAL, BLUES, GOSPEL ───
  'roots reggae': [
    'Bob Marley',
    'Burning Spear',
    'Peter Tosh',
    'Chronixx',
    'Steel Pulse',
  ],
  'dancehall': [
    'Sean Paul',
    'Shaggy',
    'Popcaan',
    'Vybz Kartel',
    'Shenseea',
  ],
  'smooth jazz': [
    'Kenny G',
    'Grover Washington Jr.',
    'Boney James',
    'Dave Koz',
  ],
  'piano': [
    'Ludovico Einaudi',
    'Yiruma',
    'Chopin',
    'Lang Lang',
    'Max Richter',
  ],
  'symphony': [
    'Beethoven',
    'Mozart',
    'Tchaikovsky',
    'London Symphony Orchestra',
  ],
  'edm': [
    'Calvin Harris',
    'David Guetta',
    'Martin Garrix',
    'Tiësto',
    'Avicii',
  ],
  'techno': [
    'Charlotte de Witte',
    'Amelie Lens',
    'Carl Cox',
    'Adam Beyer',
  ],
  'heavy metal': [
    'Metallica',
    'Megadeth',
    'Slayer',
    'Anthrax',
    'Iron Maiden',
  ],
  'metalcore': [
    'Bring Me the Horizon',
    'Architects',
    'Parkway Drive',
    'Killswitch Engage',
  ],
  'blues rock': [
    'Stevie Ray Vaughan',
    'Gary Clark Jr.',
    'Joe Bonamassa',
    'The Black Keys',
  ],
  'indie folk': [
    'Hozier',
    'Bon Iver',
    'Noah Kahan',
    'Mumford & Sons',
  ],
  'african gospel': [
    'Sinach',
    'Nathaniel Bassey',
    'Mercy Chinwo',
    'Benjamin Dube',
    'Dena Mwana',
  ],
};

/// Queries whose sections are allowed to show ambient / long-form content
/// (sleep, meditation, focus, lo-fi, rain, news, comedy, gaming...). The junk
/// filter is skipped for them because a "Rain Sounds" track is exactly what
/// those sections are about.
const Set<String> _ambientQueries = {
  'sleep',
  'deep sleep',
  'relaxation',
  'meditation',
  'mindfulness',
  'focus',
  'deep focus',
  'study',
  'lofi beats',
  'lo-fi',
  'chillhop',
  'ambient',
  'white noise',
  'rain',
  'ocean',
  'nature sounds',
  'brown noise',
  'asmr',
  'news',
  'politics',
  'comedy',
  'shadow',
  'shadowing',
  'gaming music',
  'gaming',
  'live',
  'live events',
  'concerts',
  'festivals',
  'bande originale',
  'bandes-originales',
  'soundtrack',
  'comédies musicales',
};

/// Junk-title patterns: mixes, mashups, full-album uploads, timed loops,
/// frequency videos, ambient noise, karaoke and other non-song content that
/// would otherwise flood the song sections of a genre category.
final RegExp _junkTitleRe = RegExp(
  r'(^|[^a-z0-9])'
  r'(non[- ]?stop|megamix|mega ?mix|mashup|mixtape|full album|album mix|'
  r'album edition|dj mix|best of|greatest hits|official audio|lyric video|'
  r'karaoke|halftime|bootleg|tribute|soundtrack|lullaby)'
  r'([^a-z0-9]|$)'
  r'|(\d+\s*(hour|hr|hrs|hours|min|mins|minute|minutes)\s*)'
  r'|(\b(1h|2h|3h|4h|5h|6h|10h|12h|24h)\b)'
  r'|(\b(528|432|639|852|963)\s*hz\b)'
  r'|(\b(white noise|brown noise|rain sounds?|sleep sounds?|nature sounds?|'
  r'sound machine|background music|relaxing music|studying music)\b)',
  caseSensitive: false,
);

/// Sanitized seed artists for a category query. Matching is case- and
/// diacritic-insensitive and prefers the closest known key.
List<String> seedsFor(String query) {
  final key = query.trim().toLowerCase();
  if (key.isEmpty) return const [];
  final direct = _categorySeeds[key];
  if (direct != null) return direct;
  // Allow "Deep Focus", "Lo-Fi Beats", ... to fall back on a parent genre
  // only when that makes musical sense; otherwise stay empty (term path).
  if (key.contains('focus') || key.contains('sleep') || key.contains('study')) {
    return const [];
  }
  if (key.contains('beat')) return _categorySeeds['chill'] ?? const [];
  if (key.contains('mix')) return _categorySeeds['pop'] ?? const [];
  return const [];
}

/// Dedicated seed resolution for a specific sub-category within a parent category.
/// First checks the precise sub-category seeds; if absent, falls back to deterministic
/// rotation of the parent category seeds.
List<String> seedsForSubCategory(String category, String sub) {
  final subKey = sub.trim().toLowerCase();
  final catKey = category.trim().toLowerCase();
  if (subKey.isEmpty) return seedsFor(category);

  // 1. Direct sub-category seed match
  final directSub = _subCategorySeeds[subKey];
  if (directSub != null && directSub.isNotEmpty) {
    return directSub;
  }

  // 2. Partial key match in sub-category seeds (e.g. "new rap fr" -> "rap fr")
  for (final entry in _subCategorySeeds.entries) {
    if (subKey.contains(entry.key) || entry.key.contains(subKey)) {
      return entry.value;
    }
  }

  // 3. Fallback to category seed rotation if parent has seeds
  if (hasSeeds(catKey)) {
    return seedsForSection(catKey, subKey);
  }

  return const [];
}

/// Generates a refined, contextually rich search term for a sub-category when no seeds exist.
String queryForSubCategory(String category, String sub) {
  final subClean = sub.trim();
  final catClean = category.trim();
  final subKey = subClean.toLowerCase();
  final catKey = catClean.toLowerCase();

  if (subKey.startsWith('all ')) return catClean;
  if (subKey.contains(catKey) || catKey.contains(subKey)) return subClean;
  return '$subClean $catClean';
}

/// True when this query is a pure-term category (no artist seeds).
bool hasSeeds(String query) => seedsFor(query).isNotEmpty;

/// True when the query or sub-category belongs to an ambient / non-song genre.
bool isAmbientQuery(String query) {
  final key = query.trim().toLowerCase();
  return _ambientQueries.any(key.contains);
}

/// True when either the category or sub-category is ambient.
bool isAmbientSubCategory(String category, String sub) {
  return isAmbientQuery(category) || isAmbientQuery(sub);
}

/// True when a title looks like a mix/loop/non-song and should stay out of a
/// song section. [isAmbient] disables the check for ambient categories.
bool isJunkSong(String title, {bool isAmbient = false}) {
  if (isAmbient) return false;
  if (title.isEmpty) return true;
  return _junkTitleRe.hasMatch(title);
}

/// A MuzoItem is "actually playable" if the player can stream it without
/// relying on a dead source. An item with an `it_`/`sp` video id (iTunes/
/// Spotify placeholder) has no streamable YouTube id, so without a direct
/// audioUrl it would resolve to a dead slot and the tap would produce no
/// sound. Real YouTube (ytify) ids pass, and user_tracks with audioUrl pass.
bool isActuallyPlayable(MuzoItem song) {
  if (song.audioUrl != null && song.audioUrl!.isNotEmpty) return true;
  final vid = song.videoId;
  if (vid == null || vid.isEmpty) return false;
  return !_nonYtVideoRe.hasMatch(vid);
}

final _nonYtVideoRe = RegExp(r'^(it_|sp_|sp:|yr_|al_|user_track_)');

/// A deterministic rotation of the category's seed artists for one sub
/// section, so every sub-category on the page shows a *different* but still
/// genre-correct set of artists instead of repeating the same list.
List<String> seedsForSection(String category, String sub, {int count = 3}) {
  final seeds = seedsFor(category);
  if (seeds.length <= count) return List.of(seeds);
  var hash = 0;
  for (final code in sub.toLowerCase().codeUnits) {
    hash = (hash * 31 + code) & 0x7fffffff;
  }
  final start = hash % seeds.length;
  return [
    for (var i = 0; i < count; i++) seeds[(start + i) % seeds.length],
  ];
}

