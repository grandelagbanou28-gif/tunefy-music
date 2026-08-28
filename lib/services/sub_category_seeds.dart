// Per-sub-category editorial seeds, keyed by `category > sub`.
// A real music client does not surface whatever a free-text search returns:
// it shows what its editors would pick. Each sub-section that needs a
// distinct editorial identity points at a curated list of internationally
// relevant artists for that exact sound.
//
// Everything not listed here falls back to the parent category seeds in
// category_curator.dart, which is already a solid default.
library;

const Map<String, List<String>> _subCategorySeeds = {

  // ─── Pop ───
  'Pop > Pop Hits': [
    'Dua Lipa',
    'The Weeknd',
    'Sabrina Carpenter',
    'Tate McRae',
    'Chappell Roan',
  ],
  'Pop > New Pop': [
    'Tate McRae',
    'Chappell Roan',
    'Benson Boone',
    'Teddy Swims',
    'Sabrina Carpenter',
  ],
  'Pop > Pop Classics': [
    'Michael Jackson',
    'Madonna',
    'Prince',
    'Whitney Houston',
    'George Michael',
    'Cyndi Lauper',
  ],
  'Pop > Dance Pop': [
    'David Guetta',
    'Calvin Harris',
    'Dua Lipa',
    'Beyoncé',
    'Doja Cat',
    'Charli XCX',
  ],
  'Pop > Teen Pop': [
    'Olivia Rodrigo',
    'Tate McRae',
    'Billie Eilish',
    'Sabrina Carpenter',
    'Conan Gray',
  ],
  'Pop > Electropop': [
    'Robyn',
    'CHVRCHES',
    'Purity Ring',
    'Grimes',
    'Caroline Polachek',
    'Charli XCX',
  ],
  'Pop > Indie Pop': [
    'Laufey',
    'Clairo',
    'Men I Trust',
    'Alvvays',
    'Beabadoobee',
    'Boygenius',
  ],
  'Pop > K-Pop Pop': [
    'BLACKPINK',
    'NewJeans',
    'IVE',
    'aespa',
    'TWICE',
    'LE SSERAFIM',
  ],
  'Pop > Afro Pop': [
    'Burna Boy',
    'Wizkid',
    'Tems',
    'Ayra Starr',
    'Rema',
    'Omah Lay',
  ],
  'Pop > French Pop': [
    'Aya Nakamura',
    'Louane',
    'Jain',
    'Angèle',
    'Zaz',
    'Vianney',
  ],
  'Pop > US Pop': [
    'Taylor Swift',
    'Ariana Grande',
    'Billie Eilish',
    'Lady Gaga',
    'Katy Perry',
    'Olivia Rodrigo',
  ],
  'Pop > UK Pop': [
    'Dua Lipa',
    'Adele',
    'Ed Sheeran',
    'Harry Styles',
    'Charli XCX',
    'Sam Smith',
  ],



  // ─── Hip-Hop ───
  'Hip-Hop > Hip-Hop Hits': [
    'Kendrick Lamar',
    'Drake',
    'Travis Scott',
    'Future',
    '21 Savage',
    'Travis Scott',
  ],
  'Hip-Hop > New Hip-Hop': [
    'Travis Scott',
    'Don Toliver',
    'Lil Baby',
    'Gunna',
    'Central Cee',
  ],
  'Hip-Hop > Trap': [
    'Future',
    'Young Thug',
    'Gunna',
    'Lil Baby',
    'Tra Scott',
  ],
  'Hip-Hop > Drill': [
    'Central Cee',
    'Pop Smoke',
    'Fivio Foreign',
    'Digga D',
    'Headie One',
  ],
  'Hip-Hop > Boom Bap': [
    'J. Cole',
    'Nas',
    'Joey Badass',
    'Black Thought',
    'Rapsody',
  ],
  'Hip-Hop > Conscious Hip-Hop': [
    'Kendrick Lamar',
    'J. Cole',
    'Rapsody',
    'Little Simz',
    'Lupe Fiasco',
  ],
  'Hip-Hop > Alternative Hip-Hop': [
    'Tyler, The Creator',
    'Childish Gambino',
    'Brockhampton',
    'Dominic Fike',
    'Denzel Curry',
  ],
  'Hip-Hop > Southern Hip-Hop': [
    'Megan Thee Stallion',
    'Lil Baby',
    'Gucci Mane',
    'T.I.',
    '2 Chainz',
  ],
  'Hip-Hop > French Hip-Hop': [
    'Ninho',
    'Gazo',
    'SCH',
    'Jul',
    'Damso',
  ],
  'Hip-Hop > African Hip-Hop': [
    'Kwesi Arthur',
    'Nasty C',
    'Khaligraph Jones',
    'Sarkodie',
    'M.anifest',
  ],



  // ─── R&B ───
  'R&B > Contemporary R&B': [
    'SZA',
    'Summer Walker',
    'H.E.R.',
    'Kehlani',
    'Ella Mai',
  ],
  'R&B > New R&B': [
    'SZA',
    'Victoria Monét',
    'Coco Jones',
    'Ari Lennox',
    'Kelela',
  ],
  'R&B > R&B Hits': [
    'SZA',
    'Chris Brown',
    'Usher',
    'Beyoncé',
    'The Weeknd',
  ],
  'R&B > Alternative R&B': [
    'Frank Ocean',
    'Kelela',
    'FKA twigs',
    'Blood Orange',
    'Solange',
  ],
  'R&B > Neo Soul': [
    'Erykah Badu',
    'Dwele',
    'India.Arie',
    'Laura Mvula',
    'Cleo Sol',
  ],
  'R&B > 90s R&B': [
    'Aaliyah',
    'Brandy',
    'Mary J. Blige',
    'TLC',
    'D\'Angelo',
  ],
  'R&B > 2000s R&B': [
    'Rihanna',
    'Beyoncé',
    'Usher',
    'Keyshia Cole',
    'Omarion',
  ],
  'R&B > Slow Jams': [
    'SZA',
    'Daniel Caesar',
    'H.E.R.',
    'John Legend',
    'Erykah Badu',
  ],



  // ─── Rock ───
  'Rock > Rock Hits': [
    'Imagine Dragons',
    'Foo Fighters',
    'The Killers',
    'Muse',
    'Queens of the Stone Age',
  ],
  'Rock > Classic Rock': [
    'Queen',
    'Led Zeppelin',
    'The Rolling Stones',
    'Pink Floyd',
    'AC/DC',
  ],
  'Rock > Alternative Rock': [
    'Arctic Monkeys',
    'The 1975',
    'Radiohead',
    'Paramore',
    'Vampire Weekend',
  ],
  'Rock > Indie Rock': [
    'Arctic Monkeys',
    'The Strokes',
    'Phoenix',
    'Two Door Cinema Club',
    'Foals',
  ],
  'Rock > Hard Rock': [
    'AC/DC',
    'Guns N\' Roses',
    'Metallica',
    'Van Halen',
    'Aerosmith',
  ],
  'Rock > Punk Rock': [
    'Green Day',
    'The Offspring',
    'Bad Religion',
    'Rancid',
    'Sum 41',
  ],
  'Rock > Pop Rock': [
    'The 1975',
    'Panic! At The Disco',
    'Paramore',
    'Walk the Moon',
    'OneRepublic',
  ],
  'Rock > Grunge': [
    'Nirvana',
    'Pearl Jam',
    'Soundgarden',
    'Alice in Chains',
    'Stone Temple Pilots',
  ],
  'Rock > Progressive Rock': [
    'Muse',
    'Porcupine Tree',
    'Rush',
    'Tool',
    'Dream Theater',
  ],



  // ─── Electronic ───
  'Electronic > EDM': [
    'David Guetta',
    'Calvin Harris',
    'Martin Garrix',
    'Tiësto',
    'Marshmello',
  ],
  'Electronic > House': [
    'Disclosure',
    'Peggy Gou',
    'John Summit',
    'Dom Dolla',
    'MEDUZA',
  ],
  'Electronic > Techno': [
    'Charlotte de Witte',
    'Amelie Lens',
    'Nina Kraviz',
    'Adam Beyer',
    'Jeff Mills',
  ],
  'Electronic > Trance': [
    'Armin van Buuren',
    'Above & Beyond',
    'Ferry Corsten',
    'Aly & Fila',
    'Paul van Dyk',
  ],
  'Electronic > Dubstep': [
    'Skrillex',
    'Excision',
    'Virtual Riot',
    'Sub Focus',
    'Zeds Dead',
  ],
  'Electronic > Drum & Bass': [
    'Sub Focus',
    'Chase & Status',
    'Pendulum',
    'Wilkinson',
    'Netsky',
  ],
  'Electronic > Future Bass': [
    'Flume',
    'San Holo',
    'Illenium',
    'ODESZA',
    'Louis the Child',
  ],
  'Electronic > Ambient': [
    'Brian Eno',
    'Jon Hopkins',
    'Nils Frahm',
    'Hiroshi Yoshimura',
    'Ryuichi Sakamoto',
  ],
  'Electronic > Experimental': [
    'Aphex Twin',
    'Arca',
    'Oneohtrix Point Never',
    'Sophie',
    'A.G. Cook',
  ],



  // ─── Afrobeats ───
  'Afrobeats > Afrobeats Hits': [
    'Burna Boy',
    'Wizkid',
    'Davido',
    'Rema',
    'Ayra Starr',
  ],
  'Afrobeats > New Afrobeats': [
    'Rema',
    'Ayra Starr',
    'Asake',
    'Seyi Vibez',
    'Kizz Daniel',
  ],
  'Afrobeats > Nigerian Afrobeats': [
    'Burna Boy',
    'Wizkid',
    'Davido',
    'Asake',
    'Olamide',
  ],
  'Afrobeats > Ghanaian Afrobeats': [
    'Black Sherif',
    'Sarkodie',
    'King Promise',
    'KiDi',
    'Amerado',
  ],
  'Afrobeats > Beninese Afrobeats': [
    'Fanicko',
    'Siano Bless',
    'Zeynab Habib',
    'Blaaz',
  ],
  'Afrobeats > Ivorian Afrobeats': [
    'Didi B',
    'Suspect 95',
    'Débordo Leekunfa',
    'DJ Arafat',
    'Serge Beynaud',
  ],
  'Afrobeats > Afro-Pop': [
    'Tems',
    'Ayra Starr',
    'Rema',
    'Ruger',
    'Libianca',
  ],
  'Afrobeats > Afro-R&B': [
    'Tems',
    'Ayra Starr',
    'Blaq Jerzee',
    'Ruger',
    'CKay',
  ],
  'Afrobeats > Afro-Fusion': [
    'Burna Boy',
    'Rema',
    'Wizkid',
    'Asake',
    'Ckay',
  ],
  'Afrobeats > Afrobeats Party': [
    'Burna Boy',
    'Davido',
    'Asake',
    'Ruger',
    'Kizz Daniel',
  ],



  // ─── Afro Hits ───
  'Afro Hits > Amapiano': [
    'Kabza De Small',
    'Focalistic',
    'DBN Gogo',
    'Young Stunna',
    'Tyler ICU',
  ],
  'Afro Hits > Afro House': [
    'Black Coffee',
    'Keinemusik',
    'Peggy Gou',
    'Deefrozo',
    'Claudio Wade',
  ],
  'Afro Hits > Afro Dancehall': [
    'Burna Boy',
    'Shenseea',
    'Kranium',
    'Projexx',
    'Ding Dong',
  ],
  'Afro Hits > African Drill': [
    'Kwesi Arthur',
    'Headie One',
    'Central Cee',
    'Rondodasosa',
    'Artie 5ive',
  ],
  'Afro Hits > African Gospel': [
    'Sinach',
    'Mercy Chinwo',
    'Ada Ehi',
    'Frank Edwards',
    'Moses Bliss',
  ],
  'Afro Hits > East Africa': [
    'Sauti Sol',
    'Diamond Platnumz',
    'Rayvanny',
    'Ali Kiba',
    'Zuchu',
  ],
  'Afro Hits > West Africa': [
    'Burna Boy',
    'Wizkid',
    'Davido',
    'Sarkodie',
    'Black Sherif',
  ],
  'Afro Hits > Southern Africa': [
    'Focalistic',
    'Sho Madjozi',
    'Sjava',
    'Tyla',
    'De Mthuda',
  ],



  // ─── Latin ───
  'Latin > Reggaeton': [
    'Bad Bunny',
    'J Balvin',
    'Karol G',
    'Rauw Alejandro',
    'Feid',
  ],
  'Latin > Latin Pop': [
    'Shakira',
    'Maluma',
    'Sebastián Yatra',
    'Camilo',
    'Kali Uchis',
  ],
  'Latin > Salsa': [
    'Marc Anthony',
    'Gilberto Santa Rosa',
    'Victor Manuelle',
    'La India',
    'Celia Cruz',
  ],
  'Latin > Bachata': [
    'Romeo Santos',
    'Aventura',
    'Prince Royce',
    'Juan Luis Guerra',
    'Frank Reyes',
  ],
  'Latin > Latin Trap': [
    'Bad Bunny',
    'Anuel AA',
    'Ozuna',
    'Myke Towers',
    'Eladio Carrion',
  ],
  'Latin > Regional Mexican': [
    'Natanael Cano',
    'Grupo Firme',
    'Peso Pluma',
    'Eslabon Armado',
    'Junior H',
  ],
  'Latin > Corridos': [
    'Natanael Cano',
    'Peso Pluma',
    'Fuerza Regida',
    'Tito Double P',
    'Junior H',
  ],
  'Latin > Brazilian': [
    'Anitta',
    'Ludmilla',
    'Luísa Sonza',
    'Matuê',
    'Jorge & Mateus',
  ],



  // ─── K-Pop ───
  'K-Pop > K-Pop Hits': [
    'BTS',
    'BLACKPINK',
    'NewJeans',
    'aespa',
    'Stray Kids',
  ],
  'K-Pop > New K-Pop': [
    'NewJeans',
    'IVE',
    'LE SSERAFIM',
    'aespa',
    'ZEROBASEONE',
  ],
  'K-Pop > K-Pop Girl Groups': [
    'BLACKPINK',
    'NewJeans',
    'IVE',
    'LE SSERAFIM',
    'aespa',
  ],
  'K-Pop > K-Pop Boy Groups': [
    'BTS',
    'Stray Kids',
    'SEVENTEEN',
    'NCT',
    'ENHYPEN',
  ],
  'K-Pop > Soloists': [
    'IU',
    'Taemin',
    'Sunmi',
    'Chungha',
    'Jessi',
  ],
  'K-Pop > K-R&B': [
    'DEAN',
    'Crush',
    'Zion.T',
    'Heize',
    'IU',
  ],
  'K-Pop > K-Hip-Hop': [
    'Epik High',
    'Jessi',
    'Jay Park',
    'pH-1',
    'BIG Naughty',
  ],
  'K-Pop > K-Rock': [
    'DAY6',
    'Nell',
    'Jannabi',
    'The Rose',
    'Hyukoh',
  ],
  'K-Pop > K-Indie': [
    'HYUKOH',
    'Se So Neon',
    'meaningful stone',
    'The Black Skirts',
    'Soran',
  ],



  // ─── Jazz ───
  'Jazz > Jazz Classics': [
    'Miles Davis',
    'John Coltrane',
    'Thelonious Monk',
    'Duke Ellington',
    'Charlie Parker',
  ],
  'Jazz > Smooth Jazz': [
    'George Benson',
    'Boney James',
    'Dave Koz',
    'Norman Brown',
    'Peter White',
  ],
  'Jazz > Contemporary Jazz': [
    'Kamasi Washington',
    'Robert Glasper',
    'Snarky Puppy',
    'Esperanza Spalding',
    'Christian Scott',
  ],
  'Jazz > Bebop': [
    'Charlie Parker',
    'Dizzy Gillespie',
    'Bud Powell',
    'Art Blakey',
    'Max Roach',
  ],
  'Jazz > Jazz Fusion': [
    'Miles Davis',
    'Weather Report',
    'Herbie Hancock',
    'Snarky Puppy',
    'Kamasi Washington',
  ],
  'Jazz > Latin Jazz': [
    'Buena Vista Social Club',
    'Arturo Sandoval',
    'Tito Puente',
    'Chucho Valdés',
    'Bebo Valdés',
  ],
  'Jazz > Vocal Jazz': [
    'Ella Fitzgerald',
    'Louis Armstrong',
    'Billie Holiday',
    'Chet Baker',
    'Norah Jones',
  ],
  'Jazz > Piano Jazz': [
    'Bill Evans',
    'Oscar Peterson',
    'Thelonious Monk',
    'Hiromi Uehara',
    'Robert Glasper',
  ],
  'Jazz > African Jazz': [
    'Manu Dibango',
    'Hugh Masekela',
    'Miriam Makeba',
    'Mulatu Astatke',
    'Fela Kuti',
  ],



  // ─── Metal ───
  'Metal > Heavy Metal': [
    'Metallica',
    'Iron Maiden',
    'Judas Priest',
    'Black Sabbath',
    'Ozzy Osbourne',
  ],
  'Metal > Metalcore': [
    'Bring Me the Horizon',
    'Architects',
    'A Day to Remember',
    'Parkway Drive',
    'August Burns Red',
  ],
  'Metal > Death Metal': [
    'Cannibal Corpse',
    'Morbid Angel',
    'Death',
    'Nile',
    'Entombed',
  ],
  'Metal > Black Metal': [
    'Mayhem',
    'Darkthrone',
    'Emperor',
    'Burzum',
    'Immortal',
  ],
  'Metal > Thrash Metal': [
    'Metallica',
    'Slayer',
    'Megadeth',
    'Anthrax',
    'Testament',
  ],
  'Metal > Nu Metal': [
    'Linkin Park',
    'Slipknot',
    'Korn',
    'Deftones',
    'System of a Down',
  ],
  'Metal > Alternative Metal': [
    'Tool',
    'Rage Against the Machine',
    'Audioslave',
    'Alice in Chains',
    'System of a Down',
  ],
  'Metal > Progressive Metal': [
    'Tool',
    'Dream Theater',
    'Opeth',
    'Mastodon',
    'Gojira',
  ],
  'Metal > Doom Metal': [
    'Candlemass',
    'Electric Wizard',
    'Sleep',
    'Bell Witch',
    'YOB',
  ],
  'Metal > Industrial Metal': [
    'Rammstein',
    'Ministry',
    'Nine Inch Nails',
    'KMFDM',
    'Marilyn Manson',
  ],



  // ─── Soul ───
  'Soul > Classic Soul': [
    'Aretha Franklin',
    'Marvin Gaye',
    'Stevie Wonder',
    'Otis Redding',
    'Sam Cooke',
  ],
  'Soul > Contemporary Soul': [
    'Leon Bridges',
    'Michael Kiwanuka',
    'YEBBA',
    'Cleo Sol',
    'Laura Mvula',
  ],
  'Soul > Soul R&B': [
    'SZA',
    'Daniel Caesar',
    'H.E.R.',
    'Ella Mai',
    'Miguel',
  ],
  'Soul > Motown': [
    'Stevie Wonder',
    'The Temptations',
    'Marvin Gaye',
    'Diana Ross',
    'Smokey Robinson',
  ],
  'Soul > Funk Soul': [
    'Anderson .Paak',
    'Bruno Mars',
    'Jamiroquai',
    'Vulfpeck',
    'Cory Henry',
  ],
  'Soul > Gospel Soul': [
    'CeCe Winans',
    'Mary Mary',
    'Fred Hammond',
    'Israel Houghton',
    'Tasha Cobbs Leonard',
  ],
  'Soul > Alternative Soul': [
    'Jordan Rakei',
    'Little Dragon',
    'Rhye',
    'Sampha',
    'Kindness',
  ],



  // ─── Blues ───
  'Blues > Blues Classics': [
    'B.B. King',
    'Muddy Waters',
    'Howlin\' Wolf',
    'John Lee Hooker',
    'Etta James',
  ],
  'Blues > Chicago Blues': [
    'Muddy Waters',
    'Buddy Guy',
    'Willie Dixon',
    'Koko Taylor',
    'Magic Sam',
  ],
  'Blues > Delta Blues': [
    'Robert Johnson',
    'Son House',
    'Charley Patton',
    'Mississippi John Hurt',
    'Lead Belly',
  ],
  'Blues > Electric Blues': [
    'Stevie Ray Vaughan',
    'Buddy Guy',
    'Joe Bonamassa',
    'Gary Clark Jr.',
    'Kenny Wayne Shepherd',
  ],
  'Blues > Blues Rock': [
    'Gary Clark Jr.',
    'The Black Keys',
    'Rival Sons',
    'Marcus King',
    'Larkin Poe',
  ],
  'Blues > Contemporary Blues': [
    'Gary Clark Jr.',
    'Christone Kingfish Ingram',
    'Shemekia Copeland',
    'Keb\' Mo\'',
    'Jontavious Willis',
  ],



  // ─── Country ───
  'Country > Country Hits': [
    'Luke Combs',
    'Morgan Wallen',
    'Zach Bryan',
    'Kane Brown',
    'Lainey Wilson',
  ],
  'Country > New Country': [
    'Zach Bryan',
    'Lainey Wilson',
    'Morgan Wallen',
    'Bailey Zimmerman',
    'Jelly Roll',
  ],
  'Country > Country Pop': [
    'Shania Twain',
    'Kelsea Ballerini',
    'Maren Morris',
    'Kane Brown',
    'Sam Hunt',
  ],
  'Country > Country Rock': [
    'Zac Brown Band',
    'Eric Church',
    'Kings of Leon',
    'The Cadillac Three',
    'Midland',
  ],
  'Country > Americana': [
    'Zach Bryan',
    'Tyler Childers',
    'Jason Isbell',
    'Colter Wall',
    'Sturgill Simpson',
  ],
  'Country > Bluegrass': [
    'Billy Strings',
    'Molly Tuttle',
    'Sierra Hull',
    'Greensky Bluegrass',
    'Yonder Mountain String Band',
  ],
  'Country > Outlaw Country': [
    'Willie Nelson',
    'Merle Haggard',
    'Johnny Cash',
    'Kris Kristofferson',
    'Chris Stapleton',
  ],



  // ─── Reggae ───
  'Reggae > Roots Reggae': [
    'Bob Marley',
    'Burning Spear',
    'Steel Pulse',
    'Israel Vibration',
    'Culture',
  ],
  'Reggae > Dancehall': [
    'Popcaan',
    'Vybz Kartel',
    'Sean Paul',
    'Spice',
    'Shenseea',
  ],
  'Reggae > Reggae Fusion': [
    'Drake',
    'Koffee',
    'Protoje',
    'Lila Iké',
    'Skillibeng',
  ],
  'Reggae > Dub': [
    'King Tubby',
    'Lee Scratch Perry',
    'Mad Professor',
    'Scientist',
    'UB40',
  ],



  // ─── Gospel ───
  'Gospel > Gospel Hits': [
    'Kirk Franklin',
    'Tasha Cobbs Leonard',
    'Maverick City Music',
    'Travis Greene',
    'CeCe Winans',
    'Fred Hammond',
    'Marvin Sapp',
    'Yolanda Adams',
  ],
  'Gospel > Contemporary Gospel': [
    'Tasha Cobbs Leonard',
    'Maverick City Music',
    'Travis Greene',
    'Jonathan McReynolds',
    'Tamela Mann',
    'Smokie Norful',
    'Hezekiah Walker',
    'Donald Lawrence',
  ],
  'Gospel > Nigerian Gospel': [
    'Mercy Chinwo',
    'Sinach',
    'Frank Edwards',
    'Ada Ehi',
    'Moses Bliss',
    'Dunsin Oyekan',
    'Tope Alabi',
    'Nathaniel Bassey',
  ],
  'Gospel > Benin Gospel': [
    'Siano Bless',
    'Anna Tèko',
    'Zeynab Habib',
    'Sam Bhlu',
    'Yvan pour Yésué',
    'Sir Abilé',
    'Désiré Kindomihou',
    'Miriam Ayizansi',
  ],
  'Gospel > Gospel Worship': [
    'Hillsong Worship',
    'Elevation Worship',
    'Maverick City Music',
    'Bethel Music',
    'Travis Greene',
    'Kari Jobe',
    'Hillsong United',
    'Sinach',
  ],



  // ─── Folk & Acoustic ───
  'Folk & Acoustic > Folk': [
    'Bob Dylan',
    'Simon & Garfunkel',
    'Joni Mitchell',
    'Nick Drake',
    'Leonard Cohen',
  ],
  'Folk & Acoustic > Indie Folk': [
    'Bon Iver',
    'Fleet Foxes',
    'Iron & Wine',
    'The Tallest Man on Earth',
    'Big Thief',
  ],
  'Folk & Acoustic > Singer-Songwriter': [
    'Ed Sheeran',
    'James Taylor',
    'Joni Mitchell',
    'Tracy Chapman',
    'Father John Misty',
  ],
  'Folk & Acoustic > Celtic': [
    'The Chieftains',
    'Enya',
    'Loreena McKennitt',
    'The Corrs',
    'Runrig',
  ],
  'Folk & Acoustic > Acoustic Covers': [
    'Boyce Avenue',
    'Megan Lee',
    'Tessa Violet',
    'Landon Austin',
    'Daniela Andrade',
  ],



  // ─── Classical ───
  'Classical > Classical Hits': [
    'Ludovico Einaudi',
    'Max Richter',
    'Chopin',
    'Mozart',
    'Beethoven',
  ],
  'Classical > Piano': [
    'Lang Lang',
    'Ludovico Einaudi',
    'Max Richter',
    'Chopin',
    'Claude Debussy',
  ],
  'Classical > Orchestra': [
    'Berlin Philharmonic',
    'London Symphony Orchestra',
    'Vienna Philharmonic',
    'Chicago Symphony',
    'New York Philharmonic',
  ],
  'Classical > Film Scores': [
    'Hans Zimmer',
    'John Williams',
    'Ennio Morricone',
    'Howard Shore',
    'Ramin Djawadi',
  ],
  'Classical > Baroque': [
    'Bach',
    'Vivaldi',
    'Handel',
    'Pachelbel',
    'Corelli',
  ],



  // ─── House ───
  'House > Deep House': [
    'Disclosure',
    'Peggy Gou',
    'RÜFÜS DU SOL',
    'Ben Böhmer',
    'Ross from Friends',
  ],
  'House > Tech House': [
    'John Summit',
    'Dom Dolla',
    'James Hype',
    'Fisher',
    'Chris Lake',
  ],
  'House > Progressive House': [
    'Deadmau5',
    'Eric Prydz',
    'Calvin Harris',
    'Swedish House Mafia',
    'Audien',
  ],
  'House > Tropical House': [
    'Kygo',
    'Lost Frequencies',
    'Klingande',
    'Sam Feldt',
    'Thomas Jack',
  ],
  'House > Melodic House': [
    'Ben Böhmer',
    'Nils Frahm',
    'RÜFÜS DU SOL',
    'Tinlicker',
    'Adriatique',
  ],



  // ─── Lo-Fi Beats ───
  'Lo-Fi Beats > Lo-Fi Hip-Hop': [
    'Nujabes',
    'J Dilla',
    'Tomppabeats',
    'Kupla',
    'Idealism',
  ],
  'Lo-Fi Beats > Lo-Fi Chill': [
    'Tomppabeats',
    'Kupla',
    'Idealism',
    'Philanthrope',
    'Sleepy Fish',
  ],
  'Lo-Fi Beats > Lo-Fi Study': [
    'Jinsang',
    'Kupla',
    'Tomppabeats',
    'Idealism',
    'Pandrezz',
  ],
  'Lo-Fi Beats > Lo-Fi Jazz': [
    'Nujabes',
    'J Dilla',
    'Aso',
    'Philanthrope',
    'Saib',
  ],
  'Lo-Fi Beats > Chillhop': [
    'Nujabes',
    'J Dilla',
    'Tomppabeats',
    'Philanthrope',
    'Saib',
  ],



  // ─── Focus ───
  'Focus > Deep Focus': [
    'Nils Frahm',
    'Brian Eno',
    'Marconi Union',
    'Max Richter',
    'Johann Johannsson',
  ],
  'Focus > Study': [
    'Nils Frahm',
    'Max Richter',
    'Brian Eno',
    'Marconi Union',
    'Johann Johannsson',
  ],
  'Focus > Classical Focus': [
    'Bach',
    'Mozart',
    'Chopin',
    'Debussy',
    'Satie',
  ],
  'Focus > Lo-Fi Focus': [
    'Tomppabeats',
    'Kupla',
    'Idealism',
    'Jinsang',
    'Philanthrope',
  ],
  'Focus > White Noise': [
    'Nature Sounds',
    'Rain Sounds',
    'Ocean Sounds',
    'Atmosphere',
  ],



  // ─── Meditation ───
  'Meditation > Guided Meditation': [
    'Tibetan Bowls',
    'Deva Premal',
    'Snatam Kaur',
    'Chakra',
    'Reiki',
  ],
  'Meditation > Nature Sounds': [
    'Rain Sounds',
    'Ocean Sounds',
    'Forest Sounds',
    'Thunder Sounds',
    'Wind Sounds',
  ],
  'Meditation > Spiritual': [
    'Snatam Kaur',
    'Krishna Das',
    'Deva Premal',
    'Mata Amritanandamayi',
    'Jai Uttal',
  ],



  // ─── Sleep ───
  'Sleep > Sleep Music': [
    'Max Richter',
    'Marconi Union',
    'Brian Eno',
    'Lavinia Meijer',
    'Chad Lawson',
  ],
  'Sleep > Deep Sleep': [
    'Marconi Union',
    'Max Richter',
    'Chad Lawson',
    'Sleepyfish',
    'Lavinia Meijer',
  ],
  'Sleep > ASMR': [
    'WhispersRed',
    'Gibi ASMR',
    'Gentle Whispering',
    'Latte ASMR',
    'ASMR Darling',
  ],



  // ─── Chill ───
  'Chill > Chill Hits': [
    'FKJ',
    'Tom Misch',
    'Tycho',
    'Men I Trust',
    'Cigarettes After Sex',
  ],
  'Chill > Chillout': [
    'Zero 7',
    'Air',
    'Thievery Corporation',
    'Groove Armada',
    'Zero 7',
  ],
  'Chill > Lounge': [
    'St Germain',
    'Parov Stelar',
    'Club des Belugas',
    'Waldeck',
   'Norbert Schmitt',
  ],
  'Chill > Chill Electronic': [
    'Tycho',
    'Bonobo',
    'Four Tet',
    'Caribou',
    'Floating Points',
  ],
  'Chill > Acoustic Chill': [
    'Iron & Wine',
    'Ben Howard',
    'Vance Joy',
    'Tom Walker',
    'Daughter',
  ],
  'Chill > Sunset': [
    'RÜFÜS DU SOL',
    'Tycho',
    'Ben Böhmer',
    'Maribou State',
   'CRUISR',
  ],
  'Chill > Late Night': [
    'Frank Ocean',
    'Sade',
    'The Weeknd',
    'Daniel Caesar',
    'Blood Orange',
  ],



  // ─── Indie ───
  'Indie > Indie Electronic': [
    'Jamie xx',
    'Four Tet',
    'Caribou',
    'Floating Points',
    'Jon Hopkins',
  ],
  'Indie > Dream Pop': [
    'Beach House',
    'Cigarettes After Sex',
    'The Marías',
    'Alvvays',
    'Men I Trust',
  ],
  'Indie > Shoegaze': [
    'My Bloody Valentine',
    'Slowdive',
    'Ride',
    'DIIV',
    'Nothing',
  ],
  'Indie > Bedroom Pop': [
    'Clairo',
    'Boy Pablo',
    'Beabadoobee',
    'Still Woozy',
    'Cuco',
  ],
  'Indie > Alternative': [
    'Radiohead',
    'The 1975',
    'Arctic Monkeys',
    'Bon Iver',
    'Phoebe Bridgers',
  ],



  // ─── Party ───
  'Party > Party Hits': [
    'Dua Lipa',
    'Bad Bunny',
    'David Guetta',
    'Calvin Harris',
    'Doja Cat',
  ],
  'Party > Club': [
    'Calvin Harris',
    'David Guetta',
    'Tiësto',
    'Swedish House Mafia',
    'Martin Garrix',
  ],
  'Party > Dance': [
    'Calvin Harris',
    'David Guetta',
    'Martin Garrix',
    'Swedish House Mafia',
    'Tiësto',
  ],
  'Party > House Party': [
    'Disclosure',
    'Peggy Gou',
    'John Summit',
    'MEDUZA',
    'Dom Dolla',
  ],
  'Party > Throwbacks': [
    'ABBA',
    'Bee Gees',
    'Earth, Wind & Fire',
    'Whitney Houston',
    'Daft Punk',
  ],
  'Party > Night Out': [
    'Calvin Harris',
    'David Guetta',
    'DJ Snake',
    'Major Lazer',
    'Disclosure',
  ],



  // ─── Workout ───
  'Workout > Gym': [
    'Eminem',
    'Kendrick Lamar',
    'The Weeknd',
    'Imagine Dragons',
    'Skrillex',
    'David Guetta',
    'Linkin Park',
    'Metallica',
  ],
  'Workout > Running': [
    'The Weeknd',
    'Calvin Harris',
    'Avicii',
    'David Guetta',
    'Swedish House Mafia',
  ],
  'Workout > HIIT': [
    'AC/DC',
    'Eminem',
    'Metallica',
    'Skrillex',
    'The Prodigy',
  ],
  'Workout > Cardio': [
    'Calvin Harris',
    'David Guetta',
    'Martin Garrix',
    'Tiësto',
    'Alesso',
  ],
  'Workout > Pre-Workout': [
    'Eminem',
    'Skrillex',
    'The Prodigy',
    'AC/DC',
    'Hans Zimmer',
  ],
  'Workout > High Energy': [
    'The Prodigy',
    'Skrillex',
    'Hans Zimmer',
    'Eminem',
    'AC/DC',
  ],
  'Workout > Motivation': [
    'Eminem',
    'Kanye West',
    'Hans Zimmer',
    'Imagine Dragons',
    'Two Steps from Hell',
    'Survivor',
    'Fort Minor',
    'Papa Roach',
  ],



  // ─── Hit Benin ───
  'Hit Benin > Top Benin': [
    'Vano Baby',
    'Axel Merryl',
    'Fanicko',
  ],
  'Hit Benin > New Benin': [
    'T-GANG',
    'GHIX',
    'Fat B',
  ],
  'Hit Benin > Benin Rap': [
    'Nikanor',
    'Crisba',
    'Blaaz',
  ],
  'Hit Benin > Benin Afrobeats': [
    'MZNK',
    'Dibi Dobo',
    'Conex et Don',
  ],
  'Hit Benin > Benin Pop': [
    'Siano Bless',
    'Nel Oliver',
    'Anna Téko',
  ],
  'Hit Benin > Benin R&B': [
    'Shirazee',
    'Zeynab Habib',
    'TYAF',
  ],
  'Hit Benin > Benin Gospel': [
    'Alphonse Gandonou',
    'Paul Kouton',
    'DJELYKABA BINTOU',
  ],
  'Hit Benin > Benin Traditional': [
    'Anice Pépé',
    'Gnonnas Pédro',
    'Orchestre Poly-Rythmo',
  ],
  'Hit Benin > Benin Classics': [
    'Stanislas Tohon',
    'Gangbé Brass Band',
    'Jackinosa Aziza',
  ],
  'Hit Benin > Cotonou Hits': [
    'OPA Officiel',
    'HABY',
    'X-TIME',
  ],
  'Hit Benin > Porto-Novo': [
    'Raïmi Sagbohan',
    'Bobo Wê',
    'Le Renoi',
  ],
  'Hit Benin > Abomey-Calavi': [
    'Familyzik',
    'GG Lapino',
    'BWIZ',
  ],
  'Hit Benin > Viral Benin': [
    '2XCOCO WAYA',
    'Sêminvo Xlixè',
    'Slicejay',
  ],
  'Hit Benin > Artists from Benin': [
    'Jesse Roar',
    'Murielle Ayodélé',
    'Patrick Ruffino',
  ],


  // ─── Rap Français ───
  'Rap Français > Rap FR': [
    'Ninho',
    'GIMS',
    'SCH',
    'Jul',
    'Gazo',
  ],
  'Rap Français > New Rap FR': [
    'Gazo',
    'Ninho',
    'SCH',
    'Zola',
    'Freeze Corleone',
  ],
  'Rap Français > Drill FR': [
    'Gazo',
    'Freeze Corleone',
    'Zola',
    'Diddi Trix',
    'Kalash l\'Africain',
  ],
  'Rap Français > Trap FR': [
    'Gazo',
    'Ninho',
    'Jul',
    'SCH',
    'MHD',
  ],
  'Rap Français > Rap Alternatif': [
    'Josman',
    'Dinx',
    'Wallen',
    'Soprano',
    'Lomepal',
  ],
  'Rap Français > Rap Underground': [
    'Dschew',
    'Josman',
    'Serber',
    'Wallen',
    'Dinx',
  ],
  'Rap Français > Rap Conscient': [
    'MC Solaar',
    'Oxmo Puccino',
    'Soprano',
    'Akhenaton',
    'Kery James',
  ],



  // ─── Chansons Françaises ───
  'Chansons Françaises > Chanson Pop': [
    'Aya Nakamura',
    'Louane',
    'Vianney',
    'Pomme',
    'Jain',
  ],
  'Chansons Françaises > Chanson Française Classique': [
    'Édith Piaf',
    'Jacques Brel',
    'Charles Aznavour',
    'Georges Brassens',
    'Barbara',
  ],
  'Chansons Françaises > Nouvelle Chanson': [
    'Pomme',
    'Juliette',
    'Vianney',
    'Louane',
    'Clara Luciani',
  ],
  'Chansons Françaises > Variété Française': [
    'Kendji Girac',
    'Vianney',
    'Julien Doré',
    'Mika',
    'Patrick Bruel',
  ],
  'Chanson d\'Amour': [
    'Édith Piaf',
    'Jacques Brel',
    'Françoise Hardy',
    'Charles Aznavour',
    'Barbara',
  ],
  'Chansons Françaises > Chanson Africaine': [
    'Aya Nakamura',
    'Youssou N\'Dour',
    'Salif Keita',
    'Ismaël Lô',
    'Blick Bassy',
  ],



  // ─── Desi / Bollywood ───
  'Desi / Bollywood > Bollywood': [
    'Arijit Singh',
    'Shreya Ghoshal',
    'Sonu Nigam',
    'Lata Mangeshkar',
    'Kishore Kumar',
  ],
  'Desi / Bollywood > Indian Pop': [
    'Diljit Dosanjh',
    'AP Dhillon',
    'Guru Randhawa',
    'Honey Singh',
    'Badshah',
  ],
  'Desi / Bollywood > Hindi': [
    'Arijit Singh',
    'Sonu Nigam',
    'Jubin Nautiyal',
    'Darshan Raval',
    'Atif Aslam',
  ],
  'Desi / Bollywood > Punjabi': [
    'Diljit Dosanjh',
    'AP Dhillon',
    'Sidhu Moose Wala',
    'Karan Aujla',
    'Shubh',
  ],
  'Desi / Bollywood > Tamil': [
    'Anirudh Ravichander',
    'A.R. Rahman',
    'Sid Sriram',
    'Dhanush',
    'Yuvan Shankar Raja',
  ],
  'Desi / Bollywood > Bhangra': [
    'Diljit Dosanjh',
    'Gurdas Maan',
    'Malkit Singh',
    'Jazzy B',
    'Miss Pooja',
  ],
  'Desi / Bollywood > Desi Hip-Hop': [
    'Divine',
    'KRSNA',
    'Seedhe Maut',
    'Prabh Deep',
    'Raftaar',
  ],



  // ─── Caribbean ───
  'Caribbean > Soca': [
    'Machel Montano',
    'Kes',
    'Patrice Roberts',
    'Bunji Garlin',
    'Farmer Nappy',
  ],
  'Caribbean > Zouk': [
    'Kassav\'',
    'Jocelyn B?',
    'Kaysha',
    'Thierry Vaton',
    'Medhy Custos',
  ],
  'Caribbean > Kompa': [
    'Djakout #1',
    'Tabou Combo',
    'Micky Benoit',
    'Alan Cavé',
    'Zenglen',
  ],
  'Caribbean > Jamaican Music': [
    'Bob Marley',
    'Popcaan',
    'Vybz Kartel',
    'Sean Paul',
    'Burning Spear',
  ],



  // ─── EQUAL / Women ───
  'EQUAL / Women > Women in Hip-Hop': [
    'Cardi B',
    'Megan Thee Stallion',
    'Doja Cat',
    'Nicki Minaj',
    'Missy Elliott',
  ],
  'EQUAL / Women > Women in Afrobeats': [
    'Tems',
    'Ayra Starr',
    'Tiwa Savage',
    'Yemi Alade',
    'Simi',
  ],
  'EQUAL / Women > Women in Pop': [
    'Taylor Swift',
    'Dua Lipa',
    'Billie Eilish',
    'Lady Gaga',
    'Ariana Grande',
  ],
  'EQUAL / Women > Women in R&B': [
    'SZA',
    'H.E.R.',
    'Summer Walker',
    'Jorja Smith',
    'Kehlani',
  ],
  'EQUAL / Women > Rising Women': [
    'Tyla',
    'Ayra Starr',
    'Chappell Roan',
    'Megan Thee Stallion',
    'Victoria Monét',
  ],



  // ─── Romance / Love ───
  'Romance / Love > Love Songs': [
    'Ed Sheeran',
    'Adele',
    'John Legend',
    'Bruno Mars',
    'Sade',
  ],
  'Romance / Love > Romantic Pop': [
    'Ed Sheeran',
    'Adele',
    'Bruno Mars',
    'John Legend',
    'SZA',
  ],
  'Romance / Love > Afro Love': [
    'Tems',
    'Ayra Starr',
    'CKay',
    'Ruger',
    'Libianca',
  ],
  'Romance / Love > French Love': [
    'Aya Nakamura',
    'Louane',
    'Vianney',
    'Grand Corps Malade',
    'Pomme',
  ],
  'Romance / Love > Wedding': [
    'Ed Sheeran',
    'John Legend',
    'Christina Perri',
    'Etta James',
    'Stevie Wonder',
  ],
  'Romance / Love > Heartbreak': [
    'Adele',
    'Sam Smith',
    'Lewis Capaldi',
    'SZA',
    'Frank Ocean',
  ],



  // ─── Fresh Finds ───
  'Fresh Finds > Fresh Finds Global': [
    'Tyla',
    'Ayra Starr',
    'Chappell Roan',
    'Teddy Swims',
    'Benson Boone',
  ],
  'Fresh Finds > Fresh Finds Africa': [
    'Tyla',
    'Ayra Starr',
    'Tems',
    'Rema',
    'Asake',
  ],
  'Fresh Finds > Fresh Finds Hip-Hop': [
    'Central Cee',
    'Fivio Foreign',
    'Tyla',
    'Maliibu Miitch',
    'GloRilla',
  ],
  'Fresh Finds > Fresh Finds Pop': [
    'Tate McRae',
    'Chappell Roan',
    'Benson Boone',
    'Teddy Swims',
    'Sabrina Carpenter',
  ],
  'Fresh Finds > Fresh Finds R&B': [
    'Victoria Monét',
    'Coco Jones',
    'Ari Lennox',
    'Kelela',
    'SZA',
  ],
  'Fresh Finds > Fresh Finds Electronic': [
    'Fred again..',
    'Jamie xx',
    'The Blessed Madonna',
    ' salute',
    'Barry Can\'t Swim',
  ],
  'Fresh Finds > Emerging Artists': [
    'Tyla',
    'Ayra Starr',
    'Chappell Roan',
    'Teddy Swims',
    'Benson Boone',
  ],



  // ─── Funk ───
  'Funk > Classic Funk': [
    'James Brown',
    'Parliament',
    'Sly & the Family Stone',
    'Funkadelic',
    'Earth, Wind & Fire',
  ],
  'Funk > P-Funk': [
    'Parliament',
    'Funkadelic',
    'George Clinton',
    'Bootsy Collins',
    'Bernie Worrell',
  ],
  'Funk > Disco Funk': [
    'Daft Punk',
    'Chic',
    'Bee Gees',
    'Earth, Wind & Fire',
    'KC & the Sunshine Band',
  ],
  'Funk > Modern Funk': [
    'Vulfpeck',
    'Cory Henry',
    'Khruangbin',
    'Hiatus Kaiyote',
    'Mild High Club',
  ],
  'Funk > Brazilian Funk': [
    'MC Kevin o Chris',
    'MC Hariel',
    'MC Ryan SP',
    'Anitta',
    'Ludmilla',
  ],
  'Funk > Afro Funk': [
    'Fela Kuti',
    'Burna Boy',
    'Seun Kuti',
    'Made Kuti',
    'The Good People',
  ],



  // ─── Comedy ───
  'Comedy > Stand-Up': [
    'Kevin Hart',
    'Dave Chappelle',
    'Trevor Noah',
    'Ali Wong',
    'Sebastian Maniscalco',
  ],
  'Comedy > African Comedy': [
    'Trevor Noah',
    'Anne Kansiime',
    'Basketmouth',
    'Caramel',
    'Mamane',
  ],
  'Comedy > French Comedy': [
    'Jamel Debbouze',
    'Gad Elmaleh',
    'Kev Adams',
    'Florent Peyre',
    'Tarek',
  ],
  'Comedy > American Comedy': [
    'Kevin Hart',
    'Dave Chappelle',
    'Ali Wong',
    'Sebastian Maniscalco',
    'John Mulaney',
  ],
  'Comedy > Dark Comedy': [
    'Bo Burnham',
    'Anthony Jeselnik',
    'Ricky Gervais',
    'Jimmy Carr',
    'Dave Chappelle',
  ],



  // ─── Gaming ───
  'Gaming > Battle': [
    'Hans Zimmer',
    'Two Steps from Hell',
    'E.S. Posthumus',
    'Future Heroes',
    'Globus',
  ],
  'Gaming > RPG': [
    'Nobuo Uematsu',
    'Yoko Shimomura',
    'Austin Wintory',
    'Hans Zimmer',
    'Lena Raine',
  ],
  'Gaming > FPS': [
    'Hans Zimmer',
    'Two Steps from Hell',
    'C418',
    'Andrew Hulshult',
    'Mick Gordon',
  ],
  'Gaming > Retro Gaming': [
    'C418',
    'Disasterpeace',
    'Keiichi Okabe',
    'Yoko Shimomura',
    'Austin Wintory',
  ],
  'Gaming > Game Soundtracks': [
    'Hans Zimmer',
    'Nobuo Uematsu',
    'Lena Raine',
    'C418',
    'Two Steps from Hell',
  ],



  // ─── Decades ───
  'Decades > 2020s': [
    'The Weeknd',
    'Dua Lipa',
    'Bad Bunny',
    'Olivia Rodrigo',
    'Taylor Swift',
  ],
  'Decades > 2010s': [
    'Drake',
    'Ed Sheeran',
    'Adele',
    'Bruno Mars',
    'Rihanna',
  ],
  'Decades > 2000s': [
    'Beyoncé',
    'Usher',
    'Eminem',
    'Linkin Park',
    'Rihanna',
  ],
  'Decades > 1990s': [
    'Nirvana',
    'Tupac',
    'Mariah Carey',
    'Backstreet Boys',
    'Radiohead',
  ],
  'Decades > 1980s': [
    'Michael Jackson',
    'Prince',
    'Madonna',
    'Whitney Houston',
    'Queen',
  ],
  'Decades > 1970s': [
    'Fleetwood Mac',
    'Bee Gees',
    'Led Zeppelin',
    'Pink Floyd',
    'Queen',
  ],
  'Decades > 1960s': [
    'The Beatles',
    'The Rolling Stones',
    'Aretha Franklin',
    'The Beach Boys',
    'Marvin Gaye',
  ],



  // ─── Made For You ───
  'Made For You > Discover Weekly': [
    'Tame Impala',
    'Khruangbin',
    'Mild High Club',
    'Men I Trust',
    'Crumb',
  ],
  'Made For You > Daily Mix': [
    'Dua Lipa',
    'The Weeknd',
    'SZA',
    'Kendrick Lamar',
    'Taylor Swift',
  ],
  'Made For You > Mood Mix': [
    'Frank Ocean',
    'SZA',
    'Daniel Caesar',
    'Blood Orange',
    'Solange',
  ],
  'Made For You > Time Capsule': [
    'The Cranberries',
    'Avril Lavigne',
    'No Doubt',
    'Destiny\'s Child',
    'Savage Garden',
  ],

  'Made For You > Recently Played': [
    'The Weeknd',
    'Dua Lipa',
    'Bad Bunny',
    'Taylor Swift',
    'SZA',
  ],

  // ─── Music (structural sub-categories) ───
  // Every sub gets its own curated hitmaker lineup so each section always
  // resolves to real playable songs, with zero artist overlap between subs.
  'Music > All Music': [
    'The Weeknd',
    'Dua Lipa',
    'Kendrick Lamar',
    'Billie Eilish',
    'Bad Bunny',
    'SZA',
  ],
  'Music > New Music': [
    'Sabrina Carpenter',
    'Chappell Roan',
    'Tate McRae',
    'Teddy Swims',
    'Benson Boone',
    'Gracie Abrams',
  ],
  'Music > Trending': [
    'Drake',
    'Travis Scott',
    'Karol G',
    'Anitta',
    'Rema',
    'Gunna',
  ],
  'Music > Popular': [
    'Bruno Mars',
    'Rihanna',
    'Ed Sheeran',
    'Adele',
    'Coldplay',
    'Maroon 5',
  ],
  'Music > Top Songs': [
    'Post Malone',
    'Doja Cat',
    'Harry Styles',
    'Miley Cyrus',
    'Justin Timberlake',
    'Katy Perry',
  ],
  'Music > Top Albums': [
    'Taylor Swift',
    'Olivia Rodrigo',
    'Lana Del Rey',
    'Eminem',
    'Imagine Dragons',
    'Linkin Park',
  ],
  'Music > Top Artists': [
    'Beyoncé',
    'Justin Bieber',
    'Nicki Minaj',
    'Lil Wayne',
    'David Guetta',
    'Shakira',
  ],
  'Music > Singles': [
    'Calvin Harris',
    'Marshmello',
    'Bebe Rexha',
    'Jason Derulo',
    'Jonas Brothers',
    'OneRepublic',
  ],
  'Music > Albums': [
    'Arctic Monkeys',
    'The Killers',
    'Foo Fighters',
    'Muse',
    'Kings of Leon',
    'Red Hot Chili Peppers',
  ],
  'Music > Playlists': [
    'Frank Ocean',
    'Daniel Caesar',
    'Kali Uchis',
    'Steve Lacy',
    'Tyler, The Creator',
    'Brent Faiyaz',
  ],
  'Music > Compilations': [
    'Queen',
    'ABBA',
    'Michael Jackson',
    'Fleetwood Mac',
    'Nirvana',
    'Guns N\' Roses',
  ],
  'Music > Music Videos': [
    'Chris Brown',
    'Usher',
    'Ne-Yo',
    'J Balvin',
    'Maluma',
    'Ozuna',
  ],

  // ─── Romance (fix: legacy keys were stored under "Romance / Love > …") ───
  'Romance > Love Songs': [
    'Ed Sheeran',
    'John Legend',
    'Sam Smith',
    'Adele',
  ],
  'Romance > Romantic Pop': [
    'James Arthur',
    'Ellie Goulding',
    'Lewis Capaldi',
    'Anne-Marie',
  ],
  'Romance > R&B Love': [
    'Usher',
    'Alicia Keys',
    'Mario',
    'Ashanti',
  ],
  'Romance > Afro Love': [
    'Diamond Platnumz',
    'Otile Brown',
    'Joeboy',
    'Simi',
  ],
  'Romance > French Love': [
    'Slimane',
    'Vianney',
    'Amel Bent',
    'Claudio Capeo',
  ],
  'Romance > Slow Jams': [
    'Boyz II Men',
    'K-Ci & JoJo',
    'Dru Hill',
    'Jodeci',
  ],
  'Romance > Valentine\'s Day': [
    'Whitney Houston',
    'Lionel Richie',
    'Richard Marx',
    'Sade',
  ],
  'Romance > Heartbreak': [
    'Julia Michaels',
    'JP Saxe',
    'Noah Cyrus',
    'Sasha Alex Sloan',
  ],
  'Romance > First Love': [
    'Shawn Mendes',
    'Camila Cabello',
    'LANY',
    'Jeremy Zucker',
  ],
  'Romance > Wedding': [
    'Al Green',
    'Etta James',
    'Earth, Wind & Fire',
    'Christina Perri',
  ],
  'Romance > Couple': [
    'Jason Mraz',
    'Colbie Caillat',
    'Train',
    'Andy Grammer',
  ],
  'Romance > Love Classics': [
    'Elvis Presley',
    'Nat King Cole',
    'The Righteous Brothers',
    'Bee Gees',
  ],

  // ─── EQUAL (fix: legacy keys were under "EQUAL / Women > …") ───
  'EQUAL > EQUAL Global': [
    'Ariana Grande',
    'Dua Lipa',
    'Sia',
    'Katy Perry',
  ],
  'EQUAL > EQUAL Africa': [
    'Tiwa Savage',
    'Yemi Alade',
    'Angelique Kidjo',
    'Tems',
  ],
  'EQUAL > EQUAL France': [
    'Aya Nakamura',
    'Indila',
    'Angele',
    'Zaz',
  ],
  'EQUAL > EQUAL USA': [
    'Lizzo',
    'H.E.R.',
    'Megan Thee Stallion',
    'Demi Lovato',
  ],
  'EQUAL > Women in Hip-Hop': [
    'Nicki Minaj',
    'Cardi B',
    'Ice Spice',
    'Latto',
  ],
  'EQUAL > Women in Afrobeats': [
    'Ayra Starr',
    'Gyakie',
    'Niniola',
    'Teni',
  ],
  'EQUAL > Women in Pop': [
    'Selena Gomez',
    'Rita Ora',
    'Zara Larsson',
    'Bebe Rexha',
  ],
  'EQUAL > Women in R&B': [
    'Summer Walker',
    'Jhene Aiko',
    'Kehlani',
    'Tinashe',
  ],
  'EQUAL > Rising Women': [
    'PinkPantheress',
    'Renee Rapp',
    'Madison Beer',
    'Fletcher',
  ],
  'EQUAL > Women Songwriters': [
    'Taylor Swift',
    'Julia Michaels',
    'Jessie Reyez',
    'Maren Morris',
  ],
  'EQUAL > Women Producers': [
    'Grimes',
    'Peggy Gou',
    'Rezz',
    'Alison Wonderland',
  ],

  // ─── Desi (fix: legacy keys were under "Desi / Bollywood > …") ───
  'Desi > Bollywood': [
    'Arijit Singh',
    'Shreya Ghoshal',
    'Atif Aslam',
    'Neha Kakkar',
  ],
  'Desi > Indian Pop': [
    'Badshah',
    'Guru Randhawa',
    'Divine',
    'Nucleya',
  ],
  'Desi > Hindi': [
    'Sonu Nigam',
    'Udit Narayan',
    'Alka Yagnik',
    'Kumar Sanu',
  ],
  'Desi > Punjabi': [
    'Diljit Dosanjh',
    'AP Dhillon',
    'Karan Aujla',
    'Sidhu Moose Wala',
  ],
  'Desi > Tamil': [
    'Anirudh Ravichander',
    'Sid Sriram',
    'Dhanush',
    'Harris Jayaraj',
  ],
  'Desi > Telugu': [
    'Armaan Malik',
    'Kaala Bhairava',
    'Anurag Kulkarni',
    'Sunidhi Chauhan',
  ],
  'Desi > Bengali': [
    'Anupam Roy',
    'Monali Thakur',
    'Nachiketa Chakraborty',
    'Rupam Islam',
  ],
  'Desi > Marathi': [
    'Ajay-Atul',
    'Shankar Mahadevan',
    'Avadhoot Gupte',
    'Vaishali Samant',
  ],
  'Desi > Indian Classical': [
    'Zakir Hussain',
    'Ravi Shankar',
    'Hariprasad Chaurasia',
    'Shivkumar Sharma',
  ],
  'Desi > Bhangra': [
    'Yo Yo Honey Singh',
    'Jazzy B',
    'Garry Sandhu',
    'Amrit Maan',
  ],
  'Desi > Desi Hip-Hop': [
    'Raftaar',
    'MC Stan',
    'Seedhe Maut',
    'Prabh Deep',
  ],
  'Desi > Bollywood Classics': [
    'Lata Mangeshkar',
    'Kishore Kumar',
    'Mohammed Rafi',
    'Mukesh',
  ],

  // ─── Chansons (fix: legacy keys were under "Chansons Françaises > …") ───
  'Chansons > Chansons Françaises': [
    'Edith Piaf',
    'Jacques Brel',
    'Charles Aznavour',
    'Serge Gainsbourg',
  ],
  'Chansons > Chanson Pop': [
    'Stromae',
    'Christophe Mae',
    'M. Pokora',
    'Grand Corps Malade',
  ],
  'Chansons > Chanson d\'Amour': [
    'Slimane',
    'Vianney',
    'Louane',
    'Amir',
  ],
  'Chansons > Chanson Française Classique': [
    'Georges Brassens',
    'Barbara',
    'Juliette Greco',
    'Yves Montand',
  ],
  'Chansons > Nouvelle Chanson': [
    'Benjamin Biolay',
    'Vincent Delerm',
    'Jeanne Cherhal',
    'Camille',
  ],
  'Chansons > Variété Française': [
    'Michel Sardou',
    'Johnny Hallyday',
    'France Gall',
    'Dalida',
  ],
  'Chansons > Chanson Acoustique': [
    'Francis Cabrel',
    'Maxime Le Forestier',
    'Gerald De Palmas',
    'Keren Ann',
  ],
  'Chansons > Chanson Triste': [
    'Leo Ferre',
    'Julien Dore',
    'Renan Luce',
    'Nolwenn Leroy',
  ],
  'Chansons > Chanson Romantique': [
    'Patrick Bruel',
    'Garou',
    'Natasha St-Pier',
    'Helene Segara',
  ],
  'Chansons > Chanson Africaine': [
    'Magic System',
    "Youssou N'Dour",
    'Ismael Lo',
    'Tiken Jah Fakoly',
  ],
  'Chansons > Chanson Québécoise': [
    'Celine Dion',
    'Roch Voisine',
    'Ginette Reno',
    'Les Cowboys Fringants',
  ],

  // ─── New Releases ───
  'New Releases > New Songs': [
    'Sabrina Carpenter',
    'Benson Boone',
    'Teddy Swims',
    'Chappell Roan',
  ],
  'New Releases > New Albums': [
    'Taylor Swift',
    'Billie Eilish',
    'Dua Lipa',
    'Olivia Rodrigo',
  ],
  'New Releases > New EPs': [
    'Tyla',
    'Conan Gray',
    'Gracie Abrams',
    'Renee Rapp',
  ],
  'New Releases > New Singles': [
    'Zara Larsson',
    'Kygo',
    'Jonas Blue',
    'Rita Ora',
  ],
  'New Releases > New Artists': [
    'Noah Kahan',
    'Jelly Roll',
    'Bailey Zimmerman',
    'Peso Pluma',
  ],
  'New Releases > New Music Videos': [
    'Rosalia',
    'Karol G',
    'J Balvin',
    'Anitta',
  ],
  'New Releases > This Week': [
    'Future',
    '21 Savage',
    'Don Toliver',
    'Playboi Carti',
  ],
  'New Releases > Today': [
    'Jack Harlow',
    'Lil Baby',
    'Central Cee',
    'GloRilla',
  ],
  'New Releases > Upcoming Releases': [
    'Hozier',
    'Florence + The Machine',
    'Twenty One Pilots',
    'Imagine Dragons',
  ],
  'New Releases > New Releases by Genre': [
    'Maroon 5',
    'OneRepublic',
    'Red Hot Chili Peppers',
    'Green Day',
  ],
  'New Releases > New Releases by Country': [
    'Burna Boy',
    'BTS',
    'Shakira',
    'Angele',
  ],

  // ─── Charts ───
  'Charts > Global Top 50': [
    'The Weeknd',
    'Taylor Swift',
    'Drake',
    'Billie Eilish',
  ],
  'Charts > Viral 50': [
    'Tyla',
    'Shaboozey',
    'Chappell Roan',
    'Hozier',
  ],
  'Charts > Top Songs': [
    'SZA',
    'Doja Cat',
    'Harry Styles',
    'Dua Lipa',
  ],
  'Charts > Top Albums': [
    'Morgan Wallen',
    'Zach Bryan',
    'Olivia Rodrigo',
    'Travis Scott',
  ],
  'Charts > Top Artists': [
    'Bad Bunny',
    'Eminem',
    'Rihanna',
    'Bruno Mars',
  ],
  'Charts > Trending': [
    'Lil Durk',
    'NBA YoungBoy',
    'Kodak Black',
    'Ken Carson',
  ],
  'Charts > Fastest Rising': [
    'Benson Boone',
    'Teddy Swims',
    'Noah Kahan',
    'Jelly Roll',
  ],
  'Charts > Global': [
    'Ed Sheeran',
    'Justin Bieber',
    'Ariana Grande',
    'Coldplay',
  ],
  'Charts > Benin': [
    'Angelique Kidjo',
    'Zeynab',
    'Nel Oliver',
  ],
  'Charts > Africa': [
    'Fally Ipupa',
    'Davido',
    'Wizkid',
    'Diamond Platnumz',
  ],
  'Charts > France': [
    'Ninho',
    'Gazo',
    'Jul',
    'SCH',
  ],
  'Charts > USA': [
    'Post Malone',
    'Kanye West',
    'Tyler, The Creator',
    'Childish Gambino',
  ],
  'Charts > UK': [
    'Central Cee',
    'Dave',
    'Stormzy',
    'Calvin Harris',
  ],
  'Charts > Nigeria': [
    'Asake',
    'Fireboy DML',
    'Ruger',
    'Victony',
  ],
  'Charts > Ghana': [
    'Sarkodie',
    'Stonebwoy',
    'King Promise',
    'Camidoh',
  ],

  // ─── Live Events ───
  'Live Events > Concerts': [
    'Coldplay',
    'Bruce Springsteen',
    'The Rolling Stones',
    'Pink',
  ],
  'Live Events > Festivals': [
    'Kendrick Lamar',
    'Tyler, The Creator',
    'Lana Del Rey',
    'Tame Impala',
  ],
  'Live Events > Tours': [
    'Shania Twain',
    'Eagles',
    'Def Leppard',
    'Journey',
  ],
  'Live Events > DJ Events': [
    'David Guetta',
    'Martin Garrix',
    'Tiësto',
    'Armin van Buuren',
  ],
  'Live Events > Hip-Hop Events': [
    '50 Cent',
    'Snoop Dogg',
    'Wiz Khalifa',
    'Nas',
  ],
  'Live Events > Afrobeats Events': [
    'Wizkid',
    'Flavour',
    'Kizz Daniel',
    'Omah Lay',
  ],
  'Live Events > Gospel Events': [
    'Kirk Franklin',
    'Tasha Cobbs Leonard',
    'Sinach',
    'Maverick City Music',
  ],
  'Live Events > Rock Events': [
    'Metallica',
    'Guns N\' Roses',
    'AC/DC',
    'Iron Maiden',
  ],
  'Live Events > Jazz Events': [
    'Norah Jones',
    'Gregory Porter',
    'Kamasi Washington',
    'Robert Glasper',
  ],
  'Live Events > Comedy Shows': [
    'Kevin Hart',
    'Dave Chappelle',
    'Trevor Noah',
    'Gad Elmaleh',
  ],
  'Live Events > Cultural Events': [
    'Salif Keita',
    'Oumou Sangare',
    'Toumani Diabate',
    'Baaba Maal',
  ],
  'Live Events > University Events': [
    'Khalid',
    'Lauv',
    'Chelsea Cutler',
    'Quinn XCII',
  ],
  'Live Events > Events Near You': [
    'Kings of Leon',
    'The Killers',
    'Bastille',
    'Fitz and The Tantrums',
  ],
  'Live Events > Upcoming Events': [
    'Billie Eilish',
    'Janet Jackson',
    'Missy Elliott',
    'Pitbull',
  ],

  // ─── News & Politics ───
  'News & Politics > World News': [
    'U2',
    'Bob Dylan',
    'The Clash',
    'Rage Against the Machine',
  ],
  'News & Politics > Africa': [
    'Fela Kuti',
    'Lucky Dube',
    'Miriam Makeba',
    'Fally Ipupa',
  ],
  'News & Politics > Benin': [
    'Angelique Kidjo',
    'Gnonnas Pedro',
    'Orchestre Poly-Rythmo',
    'Zeynab',
  ],
  'News & Politics > France': [
    'Noir Desir',
    'Renaud',
    'IAM',
    'NTM',
  ],
  'News & Politics > USA': [
    'Neil Young',
    'Public Enemy',
    'N.W.A.',
    'Tracy Chapman',
  ],
  'News & Politics > Politics': [
    'Dead Kennedys',
    'System of a Down',
    'Green Day',
    'Manu Chao',
  ],
  'News & Politics > Economy': [
    'Dire Straits',
    'Pink Floyd',
    'Queen',
    'Genesis',
  ],
  'News & Politics > Technology': [
    'Daft Punk',
    'Kraftwerk',
    'Imogen Heap',
    'Jean-Michel Jarre',
  ],
  'News & Politics > Business': [
    'Survivor',
    'Bon Jovi',
    'Tina Turner',
    'Gloria Gaynor',
  ],
  'News & Politics > Society': [
    'Nina Simone',
    'Sam Cooke',
    'Bill Withers',
    'Curtis Mayfield',
  ],
  'News & Politics > Investigations': [
    'Portishead',
    'Massive Attack',
    'Morcheeba',
  ],
  'News & Politics > Interviews': [
    'Jack Johnson',
    'Ray LaMontagne',
    'Iron & Wine',
    'Jose Gonzalez',
  ],
  'News & Politics > Daily News': [
    'Pharrell Williams',
    'Katrina and the Waves',
    'UB40',
    'The Police',
  ],

  // ─── Gaming (complément) ───
  'Gaming > Gaming Music': [
    'TheFatRat',
    'Alan Walker',
    'Lindsey Stirling',
    'Pegboard Nerds',
  ],
  'Gaming > Racing': [
    'The Prodigy',
    'Pendulum',
    'Justice',
    'M83',
  ],
  'Gaming > Strategy': [
    'Two Steps From Hell',
    'Audiomachine',
    'Thomas Bergersen',
    'Hans Zimmer',
  ],
  'Gaming > Nintendo': [
    'Koji Kondo',
    'Nobuo Uematsu',
    'Yasunori Mitsuda',
    'Grant Kirkhope',
  ],
  'Gaming > PlayStation': [
    'Gustavo Santaolalla',
    'Bear McCreary',
    'Junkie XL',
    'Lorne Balfe',
  ],
  'Gaming > Xbox': [
    'Martin O\'Donnell',
    'Michael Salvatori',
    'Neil Davidge',
    'Sarah Schachner',
  ],
  'Gaming > Boss Battles': [
    'DragonForce',
    'Sabaton',
    'Powerwolf',
    'Alestorm',
  ],
  'Gaming > Focus Gaming': [
    "Snail's House",
    'Tycho',
    'Bonobo',
    'Emancipator',
  ],
  'Gaming > Lo-Fi Gaming': [
    'Chillhop Music',
    'Idealism',
    'Jinsang',
    'Kupla',
  ],

  // ─── Mood ───
  'Mood > Happy': [
    'Pharrell Williams',
    'Justin Timberlake',
    'Jason Mraz',
    'Walk Off the Earth',
  ],
  'Mood > Sad': [
    'Billie Eilish',
    'Birdy',
    'A Great Big World',
    'Passenger',
  ],
  'Mood > Chill': [
    'Bon Iver',
    'Cigarettes After Sex',
    'Honne',
    'Tom Misch',
  ],
  'Mood > Energetic': [
    'Panic! At The Disco',
    'Fall Out Boy',
    'Imagine Dragons',
    'Twenty One Pilots',
  ],
  'Mood > Romantic': [
    'Charlie Puth',
    'James Bay',
    'Kacey Musgraves',
    'Alec Benjamin',
  ],
  'Mood > Motivational': [
    'Eminem',
    'Fort Minor',
    'Macklemore',
    'will.i.am',
  ],
  'Mood > Confident': [
    'Lizzo',
    'Meghan Trainor',
    'Kesha',
    'Pink',
  ],
  'Mood > Peaceful': [
    'Enya',
    'Norah Jones',
    'Yiruma',
    'Kina Grannis',
  ],
  'Mood > Angry': [
    'Three Days Grace',
    'Breaking Benjamin',
    'Slipknot',
    'Hollywood Undead',
  ],
  'Mood > Nostalgic': [
    'Backstreet Boys',
    'NSYNC',
    'Westlife',
    'a-ha',
  ],
  'Mood > Melancholic': [
    'Radiohead',
    'The National',
    'Phoebe Bridgers',
    'Sufjan Stevens',
  ],
  'Mood > Feel Good': [
    'Earth, Wind & Fire',
    'Chic',
    'Kool & The Gang',
    'Sister Sledge',
  ],
  'Mood > Emotional': [
    'Adele',
    'Ruth B.',
    'Vance Joy',
    'Seafret',
  ],
  'Mood > Dark': [
    'The Weeknd',
    'Halsey',
    'Melanie Martinez',
    'Chase Atlantic',
  ],
  'Mood > Hopeful': [
    'Rachel Platten',
    'Andra Day',
    'Sia',
    'Coldplay',
  ],

  // ─── Sleep (complément) ───
  'Sleep > Relaxation': [
    'Marconi Union',
    'Liquid Mind',
    'Deuter',
    'Kevin Kern',
  ],
  'Sleep > Nature Sounds': [
    'Dan Gibson',
    'Steven Halpern',
    'David Arkenstone',
    'Tim Janis',
  ],
  'Sleep > Rain': [
    'Helios',
    'Hammock',
    'Eluvium',
    'Goldmund',
  ],
  'Sleep > Ocean': [
    'Olafur Arnalds',
    'Nils Frahm',
    'Peter Broderick',
    'Dustin O\'Halloran',
  ],
  'Sleep > Brown Noise': [
    'Steve Roach',
    'Robert Rich',
    'Stars of the Lid',
    'A Winged Victory for the Sullen',
  ],
  'Sleep > Meditation': [
    'Deuter',
    'Anugama',
    'Maneesh De Moor',
    'Chinmaya Dunster',
  ],
  'Sleep > Sleep Stories': [
    'Max Richter',
    'Ludovico Einaudi',
    'Brian Eno',
    'Helen Jane Long',
  ],
  'Sleep > Baby Sleep': [
    'Rockabye Baby!',
    'Vitamin String Quartet',
    'Jewel',
    'Lisa Loeb',
  ],

  // ─── Focus (complément) ───
  'Focus > Coding': [
    'Tycho',
    'Boards of Canada',
    'Aphex Twin',
    'Jon Hopkins',
  ],
  'Focus > Reading': [
    'Erik Satie',
    'Helen Jane Long',
    'Peter Kater',
    'Ludovico Einaudi',
  ],
  'Focus > Work': [
    'Hans Zimmer',
    'Johann Johannsson',
    'Max Richter',
    'Alexandre Desplat',
  ],
  'Focus > Productivity': [
    'Steve Reich',
    'Philip Glass',
    'Terry Riley',
    'Michael Nyman',
  ],
  'Focus > Instrumental': [
    'Explosions in the Sky',
    'Sigur Ros',
    'Mogwai',
    'This Will Destroy You',
  ],
  'Focus > Ambient': [
    'Brian Eno',
    'Stars of the Lid',
    'Tim Hecker',
    'Biosphere',
  ],

  // ─── Workout (complément) ───
  'Workout > Strength Training': [
    'Metallica',
    'Five Finger Death Punch',
    'Avenged Sevenfold',
    'Slipknot',
  ],
  'Workout > Cycling': [
    'Fatboy Slim',
    'The Chemical Brothers',
    'The Crystal Method',
    'Basement Jaxx',
    'Avicii',
    'Zedd',
    'Swedish House Mafia',
  ],
  'Workout > Yoga': [
    'Krishna Das',
    'Deva Premal',
    'Snatam Kaur',
    'Wah!',
    'Liquid Mind',
  ],
  'Workout > Recovery': [
    'Moby',
    'Zero 7',
    'Air',
    'Thievery Corporation',
  ],

  // ─── Party (complément) ───
  'Party > Afrobeats Party': [
    'Burna Boy',
    'Davido',
    'Wizkid',
    'Asake',
  ],
  'Party > Hip-Hop Party': [
    'Busta Rhymes',
    'Missy Elliott',
    'DMX',
    'Ludacris',
  ],
  'Party > French Party': [
    'DJ Snake',
    'Kungs',
    'Ofenbach',
    'Tchami',
  ],
  'Party > Latin Party': [
    'Ozuna',
    'Nicky Jam',
    'Farruko',
    'Sech',
  ],
  'Party > Amapiano Party': [
    'Kabza De Small',
    'DJ Maphorisa',
    'Focalistic',
    'Daliwonga',
  ],
  'Party > Pre-Game': [
    'Flo Rida',
    'Taio Cruz',
    'LMFAO',
    'Far East Movement',
  ],

  // ─── Couverture exhaustive : chaque sous de l'UI a désormais ses seeds ───
  // ─── Afro Hits (complément) ───
  'Afro Hits > Afrobeats': [
    'CKay',
    'Joeboy',
    'Ruger',
    'Victony',
  ],
  'Afro Hits > Afro Pop': [
    'Yemi Alade',
    'Tiwa Savage',
    'Kizz Daniel',
    'Adekunle Gold',
  ],
  'Afro Hits > Afro R&B': [
    'Nonso Amadi',
    'Johnny Drille',
    'Chike',
    'Ric Hassani',
  ],
  'Afro Hits > Afro Hip-Hop': [
    'Nasty C',
    'M.I Abaga',
    'Ladipoe',
    'Vector',
  ],
  'Afro Hits > Afro Fusion': [
    'Mr Eazi',
    'Maleek Berry',
    'Wande Coal',
    'Wurld',
  ],
  'Afro Hits > Central Africa': [
    "Innoss'B",
    'Gaz Mawete',
    'Naza',
    'KeBlack',
  ],
  // ─── Afrobeats (complément) ───
  'Afrobeats > Afro-Love': [
    'Oxlade',
    'Libianca',
    'Simi',
    'Fireboy DML',
  ],
  'Afrobeats > Afrobeats Classics': [
    '2Face Idibia',
    'P-Square',
    'D\'banj',
    'Banky W',
  ],
  // ─── Alternative / Global ───
  'Alternative / Global > Alternative Pop': [
    'Lorde',
    'Lana Del Rey',
    'Mitski',
    'Halsey',
  ],
  'Alternative / Global > Alternative Rock': [
    'Placebo',
    'Weezer',
    'Smashing Pumpkins',
    'Pixies',
  ],
  'Alternative / Global > Alternative R&B': [
    'Banks',
    '6LACK',
    'Syd',
    'Ravyn Lenae',
  ],
  'Alternative / Global > Alternative Hip-Hop': [
    'Kid Cudi',
    'Mac Miller',
    'Gorillaz',
    'Lupe Fiasco',
  ],
  'Alternative / Global > Experimental': [
    'Björk',
    'Flying Lotus',
    'James Blake',
    'Arca',
  ],
  'Alternative / Global > Dream Pop': [
    'Cocteau Twins',
    'Mazzy Star',
    'Julee Cruise',
    'Beach House',
  ],
  'Alternative / Global > Shoegaze': [
    'My Bloody Valentine',
    'Slowdive',
    'DIIV',
    'Lush',
  ],
  'Alternative / Global > Art Pop': [
    'Kate Bush',
    'St. Vincent',
    'Tori Amos',
    'Regina Spektor',
  ],
  'Alternative / Global > Post-Punk': [
    'Joy Division',
    'Interpol',
    'IDLES',
    'Fontaines D.C.',
  ],
  'Alternative / Global > Indie Alternative': [
    'MGMT',
    'Foster The People',
    'alt-J',
    'Glass Animals',
  ],
  'Alternative / Global > Global Alternative': [
    'Milky Chance',
    'Twenty One Pilots',
    'Bastille',
    'The Neighbourhood',
  ],
  'Alternative / Global > Emerging Alternative': [
    'Wet Leg',
    'Holly Humberstone',
    'Snail Mail',
    'Soccer Mommy',
  ],
  // ─── Blues (complément) ───
  'Blues > Acoustic Blues': [
    'Taj Mahal',
    'Eric Bibb',
    'Chris Smither',
    'Rory Block',
  ],
  'Blues > Blues Guitar': [
    'Walter Trout',
    'Robben Ford',
    'Sonny Landreth',
    'Joe Louis Walker',
  ],
  'Blues > Blues Vocals': [
    'Beth Hart',
    'Susan Tedeschi',
    'Ruthie Foster',
    'Janiva Magness',
  ],
  'Blues > Soul Blues': [
    'Bobby Rush',
    'Johnny Rawls',
    'Curtis Salgado',
    'Sugaray Rayford',
  ],
  // ─── Caribbean (complément) ───
  'Caribbean > Calypso': [
    'Harry Belafonte',
    'Mighty Sparrow',
    'Lord Kitchener',
    'Calypso Rose',
  ],
  'Caribbean > Caribbean Classics': [
    'Jimmy Cliff',
    'Desmond Dekker',
    'Peter Tosh',
    'Gregory Isaacs',
  ],
  'Caribbean > Caribbean Pop': [
    'Rihanna',
    'Omi',
    'Conkarah',
    'Shaggy',
  ],
  'Caribbean > Dancehall': [
    'Skillibeng',
    'Masicka',
    'Aidonia',
    'Konshens',
  ],
  'Caribbean > Guadeloupe': [
    'Admiral T',
    'Tiwony',
    'Saïk',
    'Fyo',
  ],
  'Caribbean > Haitian Music': [
    'Wyclef Jean',
    'T-Micky',
    'Kreyol La',
    'Boukman Eksperyans',
  ],
  'Caribbean > Martinique': [
    'Malavoi',
    'Dédé Saint-Prix',
    'Edith Lefel',
    'Ralph Thamar',
  ],
  'Caribbean > Reggae': [
    'Chronixx',
    'Kabaka Pyramid',
    'Jesse Royal',
    'Romain Virgo',
  ],
  'Caribbean > Reggaeton': [
    'Daddy Yankee',
    'Don Omar',
    'Ivy Queen',
    'Tego Calderón',
  ],
  // ─── Charts (complément) ───
  'Charts > Côte d\'Ivoire': [
    'Didi B',
    'Tam Sir',
    'Roseline Layo',
    'DJ Arafat',
  ],
  // ─── Chill (complément) ───
  'Chill > Chill Pop': [
    'LANY',
    'Lauv',
    'Jeremy Zucker',
    'Chelsea Cutler',
  ],
  'Chill > Chill R&B': [
    'Giveon',
    'Snoh Aalegra',
    'Jorja Smith',
    'Mahalia',
  ],
  'Chill > Chill Rap': [
    'Drake',
    'Big Sean',
    'Wale',
    'Amine',
  ],
  'Chill > Weekend Chill': [
    'Jack Johnson',
    'Colbie Caillat',
    'Jason Mraz',
    'Norah Jones',
  ],
  // ─── Classical (complément) ───
  'Classical > Chamber Music': [
    'Yo-Yo Ma',
    'Itzhak Perlman',
    'Martha Argerich',
    'Alban Berg Quartet',
  ],
  'Classical > Classical for Focus': [
    'Erik Satie',
    'Franz Schubert',
    'Edvard Grieg',
    'Robert Schumann',
  ],
  'Classical > Classical for Sleep': [
    'Ólafur Arnalds',
    "Dustin O'Halloran",
    'Helen Jane Long',
    'Chad Lawson',
  ],
  'Classical > Contemporary Classical': [
    'Philip Glass',
    'Arvo Pärt',
    'Michael Nyman',
    'John Adams',
  ],
  'Classical > Modern Classical': [
    'Jóhann Jóhannsson',
    'Clint Mansell',
    'Craig Armstrong',
    'Abel Korzeniowski',
  ],
  'Classical > Opera': [
    'Andrea Bocelli',
    'Luciano Pavarotti',
    'Maria Callas',
    'Plácido Domingo',
  ],
  'Classical > Romantic Era': [
    'Pyotr Ilyich Tchaikovsky',
    'Sergei Rachmaninoff',
    'Johannes Brahms',
    'Franz Liszt',
  ],
  'Classical > Symphony': [
    'Antonín Dvořák',
    'Jean Sibelius',
    'Gustav Mahler',
    'Dmitri Shostakovich',
  ],
  // ─── Comedy (complément) ───
  'Comedy > Comedy Podcasts': [
    'Joe Rogan',
    'Bill Burr',
    'Tim Dillon',
    'Theo Von',
  ],
  'Comedy > Funny Stories': [
    'Gabriel Iglesias',
    'Nate Bargatze',
    'Jim Gaffigan',
    'Brian Regan',
  ],
  'Comedy > Interviews': [
    "Conan O'Brien",
    'Marc Maron',
    'Graham Norton',
    'Jimmy Fallon',
  ],
  'Comedy > Satire': [
    'John Oliver',
    'Jon Stewart',
    'Stephen Colbert',
    'Saturday Night Live',
  ],
  'Comedy > Sketches': [
    'Key & Peele',
    'Monty Python',
    'The Lonely Island',
    'Mr Bean',
  ],
  // ─── Country (complément) ───
  'Country > Classic Country': [
    'Hank Williams',
    'Patsy Cline',
    'George Jones',
    'Dolly Parton',
  ],
  'Country > Contemporary Country': [
    'Cody Johnson',
    'Parker McCollum',
    'Megan Moroney',
    'Warren Zeiders',
  ],
  'Country > Country Classics': [
    'Alan Jackson',
    'George Strait',
    'Garth Brooks',
    'Reba McEntire',
  ],
  'Country > Country Love': [
    'Keith Urban',
    'Tim McGraw',
    'Faith Hill',
    'Lady A',
  ],
  // ─── Decades (complément) ───
  'Decades > 1940s': [
    'Billie Holiday',
    'Nat King Cole',
    'Bing Crosby',
    'Glenn Miller',
  ],
  'Decades > 1950s': [
    'Elvis Presley',
    'Chuck Berry',
    'Buddy Holly',
    'Little Richard',
  ],
  'Decades > Classics': [
    'Bob Marley',
    'ABBA',
    'Elton John',
    'Phil Collins',
  ],
  // ─── Electronic (complément) ───
  'Electronic > Electro': [
    'Justice',
    'Digitalism',
    'Gesaffelstein',
    'Kavinsky',
  ],
  'Electronic > Progressive': [
    'Eric Prydz',
    'Yotto',
    'Anyma',
    'CamelPhat',
  ],
  'Electronic > Melodic Electronic': [
    'RÜFÜS DU SOL',
    'Lane 8',
    'Stephan Bodzin',
    'Mind Against',
  ],
  'Electronic > Dance': [
    'Major Lazer',
    'DJ Snake',
    'Diplo',
    'Zedd',
  ],
  // ─── Folk & Acoustic (complément) ───
  'Folk & Acoustic > Acoustic': [
    'José González',
    'Ray LaMontagne',
    'Ben Harper',
    'Eddie Vedder',
  ],
  'Folk & Acoustic > African Folk': [
    'Ali Farka Touré',
    'Toumani Diabaté',
    'Oumou Sangaré',
    'Habib Koité',
  ],
  'Folk & Acoustic > Americana': [
    'The Lumineers',
    'Mumford & Sons',
    'Wilco',
    'The Head and the Heart',
  ],
  'Folk & Acoustic > Campfire': [
    'Vance Joy',
    'George Ezra',
    'Passenger',
    'Judah & the Lion',
  ],
  'Folk & Acoustic > Country Folk': [
    'John Prine',
    'Gillian Welch',
    'Emmylou Harris',
    'Townes Van Zandt',
  ],
  'Folk & Acoustic > French Folk': [
    'Francis Cabrel',
    'Yves Duteil',
    'Dick Annegarn',
    'Graeme Allwright',
  ],
  'Folk & Acoustic > Traditional Folk': [
    'Woody Guthrie',
    'Pete Seeger',
    'Joan Baez',
    'Lead Belly',
  ],
  // ─── Fresh Finds (complément) ───
  'Fresh Finds > Fresh Finds Afrobeats': [
    'Shallipopi',
    'Odumodublvck',
    'Bloody Civilian',
    'Qing Madi',
  ],
  'Fresh Finds > Fresh Finds Benin': [
    'Sessimè',
    'Slicejay',
    'Kpros',
    'Tessia',
  ],
  'Fresh Finds > Fresh Finds France': [
    'Zaho de Sagazan',
    'Luidji',
    'Yseult',
    'SDM',
  ],
  'Fresh Finds > Fresh Finds USA': [
    'Gracie Abrams',
    'Olivia Dean',
    'Myles Smith',
    'Alex Warren',
  ],
  'Fresh Finds > New Voices': [
    'Samara Joy',
    'Lauren Spencer-Smith',
    'Stephen Sanchez',
    'David Kushner',
  ],
  // ─── Funk (complément) ───
  'Funk > Funk Classics': [
    'Kool & The Gang',
    'Ohio Players',
    'The Isley Brothers',
    'Commodores',
  ],
  'Funk > Funk Party': [
    'Bruno Mars',
    'Mark Ronson',
    'Prince',
    'Rick James',
  ],
  'Funk > Funk Rock': [
    'Red Hot Chili Peppers',
    'Lenny Kravitz',
    'Primus',
    'Faith No More',
  ],
  'Funk > Funk Soul': [
    'Stevie Wonder',
    'Tower of Power',
    'Average White Band',
    'Cameo',
  ],
  // ─── Gospel (complément) ───
  'Gospel > African Gospel': [
    'Benjamin Dube',
    'Dena Mwana',
    'Chioma Jesus',
    'Tim Godfrey',
    'Joyous Celebration',
    'Uche Agu',
    'Solly Mahlangu',
  ],
  'Gospel > Choir': [
    'Brooklyn Tabernacle Choir',
    'London Community Gospel Choir',
    'Gaither Vocal Band',
    'Soweto Gospel Choir',
    'Kurt Carr',
    'Mississippi Mass Choir',
    'Troy Sneed',
  ],
  'Gospel > Christian Music': [
    'Casting Crowns',
    'MercyMe',
    'Chris Tomlin',
    'Lauren Daigle',
    'TobyMac',
    'Zach Williams',
    'for KING & COUNTRY',
  ],
  'Gospel > Gospel Classics': [
    'Andraé Crouch',
    'The Clark Sisters',
    'Shirley Caesar',
    'Edwin Hawkins',
    'Mahalia Jackson',
    'James Cleveland',
  ],
  'Gospel > Gospel R&B': [
    'Mary Mary',
    'Kierra Sheard',
    'Deitrick Haddon',
    'Michelle Williams',
    'Erica Campbell',
    'Mali Music',
    'Ted Winn',
  ],
  'Gospel > Gospel Rap': [
    'Lecrae',
    'NF',
    'Andy Mineo',
    'Trip Lee',
    'KB',
    'Hulvey',
    'Social Club Misfits',
  ],
  'Gospel > Praise': [
    'Don Moen',
    'Darlene Zschech',
    'Planetshakers',
    'Gateway Worship',
    'Ron Kenoly',
    'Israel Houghton',
    'Fred Hammond',
  ],
  // ─── Hip-Hop (complément) ───
  'Hip-Hop > East Coast': [
    'The Notorious B.I.G.',
    'Jay-Z',
    'Wu-Tang Clan',
    'Mobb Deep',
  ],
  'Hip-Hop > Underground': [
    'MF DOOM',
    'Atmosphere',
    'Aesop Rock',
    'Immortal Technique',
  ],
  'Hip-Hop > West Coast': [
    '2Pac',
    'Snoop Dogg',
    'Dr. Dre',
    'N.W.A.',
  ],
  // ─── House (complément) ───
  'House > Afro House': [
    'Black Coffee',
    'Shimza',
    'Culoe De Song',
    'Da Capo',
  ],
  'House > Amapiano': [
    'Uncle Waffles',
    'Musa Keys',
    'Sir Trill',
    'Young Stunna',
  ],
  'House > Classic House': [
    'Frankie Knuckles',
    'Marshall Jefferson',
    'Larry Heard',
    'Kerri Chandler',
  ],
  'House > Future House': [
    'Oliver Heldens',
    'Don Diablo',
    'Brooks',
    'Mesto',
  ],
  'House > House Party': [
    'Robin Schulz',
    'Felix Jaehn',
    'Alle Farben',
    'YouNotUs',
  ],
  'House > Piano House': [
    'Joel Corry',
    'MK',
    'Sonny Fodera',
    'Low Steppa',
  ],
  'House > Soulful House': [
    'Mousse T.',
    'Dennis Ferrer',
    'Kings of Tomorrow',
    'Jasper Street Co.',
  ],
  // ─── Indie (complément) ───
  'Indie > Indie Pop': [
    'The Postal Service',
    'Belle and Sebastian',
    'Camera Obscura',
    'Tennis',
  ],
  'Indie > Indie Rock': [
    'The Strokes',
    'Pavement',
    'Modest Mouse',
    'Yeah Yeah Yeahs',
  ],
  'Indie > Indie Folk': [
    'Noah Kahan',
    'Gregory Alan Isakov',
    'Andrew Bird',
    'First Aid Kit',
  ],
  'Indie > Indie Classics': [
    'The Smiths',
    'Sonic Youth',
    'The Cure',
    'New Order',
  ],
  'Indie > Lo-Fi Indie': [
    'Mac DeMarco',
    'Alex G',
    'Beach Fossils',
    'Real Estate',
  ],
  // ─── Jazz (complément) ───
  'Jazz > Jazz Instrumental': [
    'Pat Metheny',
    'Al Di Meola',
    'Stanley Clarke',
    'Jean-Luc Ponty',
  ],
  'Jazz > Soul Jazz': [
    'Horace Silver',
    'Cannonball Adderley',
    'Jimmy Smith',
    'Lou Donaldson',
  ],
  'Jazz > Swing': [
    'Benny Goodman',
    'Count Basie',
    'Django Reinhardt',
    'Artie Shaw',
  ],
  // ─── K-Pop (complément) ───
  'K-Pop > K-Pop Classics': [
    'Girls\' Generation',
    'Super Junior',
    'SHINee',
    '2NE1',
  ],
  'K-Pop > Korean OST': [
    'Gaho',
    'Davichi',
    'CHEN',
    'Paul Kim',
  ],
  // ─── Latin (complément) ───
  'Latin > Cumbia': [
    'Los Ángeles Azules',
    'Carlos Vives',
    'Grupo Niche',
    'La Sonora Dinamita',
  ],
  'Latin > Latin Classics': [
    'Juan Gabriel',
    'Luis Miguel',
    'José José',
    'Rocío Dúrcal',
  ],
  'Latin > Latin Hip-Hop': [
    'Residente',
    'Canserbero',
    'Arcángel',
    'Ñengo Flow',
  ],
  'Latin > Merengue': [
    'Elvis Crespo',
    'Olga Tañón',
    'Toño Rosario',
    'Milly Quezada',
  ],
  // ─── Lo-Fi Beats (complément) ───
  'Lo-Fi Beats > Instrumental Lo-Fi': [
    'Oatmello',
    'Frook',
    'Dryhope',
    'Cushy',
  ],
  'Lo-Fi Beats > Lo-Fi Anime': [
    "Snail's House",
    'Yunomi',
    'Moe Shop',
    'Macross 82-99',
  ],
  'Lo-Fi Beats > Lo-Fi Focus': [
    'eevee',
    'Flamingosis',
    'Brock Berrigan',
    'The Deli',
  ],
  'Lo-Fi Beats > Lo-Fi Gaming': [
    'Dj Cutman',
    'GameChops',
    'Hyper Potions',
    'Noteblock',
  ],
  'Lo-Fi Beats > Lo-Fi Rain': [
    'Tenno',
    'Kanisan',
    'Lukrembo',
    'Purrple Cat',
  ],
  'Lo-Fi Beats > Lo-Fi Sleep': [
    'Lofi Girl',
    'Blue Wednesday',
    'Monma',
    'WYS',
  ],
  // ─── Made For You (complément) ───
  'Made For You > Artist Mix': [
    'Post Malone',
    'Justin Bieber',
    'Doja Cat',
    'Jack Harlow',
    'Latto',
  ],
  'Made For You > Release Radar': [
    'Fred again..',
    'PinkPantheress',
    'Dominic Fike',
    'Omar Apollo',
  ],
  'Made For You > Genre Mix': [
    'Metallica',
    'Avicii',
    'Bob Marley',
    'Frank Sinatra',
  ],
  'Made For You > Your Top Songs': [
    'Morgan Wallen',
    'Shaboozey',
    'Hozier',
    'Teddy Swims',
  ],
  'Made For You > Your Favorites': [
    'Coldplay',
    'Queen',
    "Guns N' Roses",
    'Eminem',
  ],
  'Made For You > Because You Like...': [
    'Arctic Monkeys',
    'The Neighbourhood',
    'Chase Atlantic',
    'Lana Del Rey',
  ],
  'Made For You > Based on Your Listening': [
    'Brent Faiyaz',
    'Baby Keem',
    'Smino',
    'Vince Staples',
  ],
  // ─── Meditation (complément) ───
  'Meditation > Mindfulness': [
    'Kitaro',
    'Nadama',
    'Prem Joshua',
    'Sacred Earth',
  ],
  'Meditation > Breathing': [
    'Deuter',
    'Anugama',
    'Shastro',
    'Kamal',
  ],
  'Meditation > Morning Meditation': [
    'Bernward Koch',
    'David Lanz',
    'Michael Hoppé',
    'Tim Wheater',
  ],
  'Meditation > Evening Meditation': [
    'Gandalf',
    'Llewellyn',
    'Medwyn Goodall',
    'Aeoliah',
  ],
  'Meditation > Relaxation': [
    'Liquid Mind',
    'Kevin Kern',
    'David Darling',
    'Hilary Stagg',
  ],
  'Meditation > Sleep Meditation': [
    'Anael',
    '2002',
    'Nicholas Gunn',
    'Parijat',
  ],
  'Meditation > Stress Relief': [
    'Terry Oldfield',
    'Karunesh',
    'Chinmaya Dunster',
    'Manish Vyas',
  ],
  'Meditation > Anxiety Relief': [
    'Steven Halpern',
    'David Arkenstone',
    'Paul Avgerinos',
    'Ryan Farish',
  ],
  'Meditation > Yoga': [
    'Wah!',
    'MC Yogi',
    'DJ Drez',
    'East Forest',
  ],
  // ─── Metal (complément) ───
  'Metal > Symphonic Metal': [
    'Nightwish',
    'Epica',
    'Within Temptation',
    'Therion',
  ],
  'Metal > Metal Classics': [
    'Motörhead',
    'Dio',
    'Whitesnake',
    'Twisted Sister',
  ],
  // ─── R&B (complément) ───
  'R&B > R&B Chill': [
    'Miguel',
    'Jeremih',
    'PartyNextDoor',
    'Ty Dolla \$ign',
  ],
  'R&B > R&B Love': [
    'Monica',
    'Joe',
    '112',
    'Jagged Edge',
  ],
  'R&B > Urban R&B': [
    'Trey Songz',
    'T-Pain',
    'Akon',
    'Bobby V',
  ],
  // ─── Rap ───
  'Rap > Rap Hits': [
    'Eminem',
    'Drake',
    'Kendrick Lamar',
    'Nicki Minaj',
    '50 Cent',
  ],
  'Rap > New Rap': [
    'Sexyy Red',
    'Cash Cobain',
    'Ice Spice',
    'Babytron',
  ],
  'Rap > Trap': [
    'Gucci Mane',
    'Waka Flocka Flame',
    'Young Jeezy',
    'Migos',
  ],
  'Rap > Drill': [
    'Lil Durk',
    'Chief Keef',
    'G Herbo',
    'Pooh Shiesty',
  ],
  'Rap > Boom Bap': [
    'Griselda',
    'Westside Gunn',
    'Freddie Gibbs',
    'Roc Marciano',
  ],
  'Rap > Underground': [
    'JPEGMAFIA',
    'Danny Brown',
    'Earl Sweatshirt',
    'MIKE',
  ],
  'Rap > Conscious Rap': [
    'Common',
    'Mos Def',
    'Talib Kweli',
    'Black Star',
  ],
  'Rap > Alternative Rap': [
    'Outkast',
    'B.o.B',
    'Asher Roth',
    'Machine Gun Kelly',
  ],
  'Rap > Hardcore Rap': [
    'DMX',
    'Onyx',
    'M.O.P.',
    'Bone Thugs-N-Harmony',
  ],
  'Rap > Rap Love': [
    'Ja Rule',
    'Nelly',
    'Fabolous',
    'Lloyd Banks',
  ],
  'Rap > Freestyle': [
    'Jadakiss',
    'Method Man',
    'Redman',
    'Ludacris',
  ],
  'Rap > International Rap': [
    'Aitch',
    'Dizzee Rascal',
    'Wiley',
    'Kano',
  ],
  // ─── Rap Français (complément) ───
  'Rap Français > Rap 90s': [
    'IAM',
    'Suprême NTM',
    'Fonky Family',
    '113',
  ],
  'Rap Français > Rap 2000s': [
    'Booba',
    'Rohff',
    'Sinik',
    'La Fouine',
  ],
  'Rap Français > Rap 2010s': [
    'PNL',
    'Nekfeu',
    'Lacrim',
    'Kaaris',
  ],
  'Rap Français > Rap 2020s': [
    'Werenoi',
    'Tiakola',
    'Dinos',
    'Leto',
  ],
  'Rap Français > Rap Game': [
    'Jul',
    'Alonzo',
    'Naps',
    'Soso Maness',
  ],
  'Rap Français > Rap Hardcore': [
    'Ideal J',
    'Assassin',
    'Ministère A.M.E.R.',
    'Lunatic',
  ],
  'Rap Français > Rap Love': [
    'Youssoupha',
    'Disiz',
    'Grand Corps Malade',
    'Hugo TSR',
  ],
  'Rap Français > Freestyle': [
    'Sofiane',
    'Kalash Criminel',
    'Koba LaD',
    'Bekar',
  ],
  // ─── Reggae (complément) ───
  'Reggae > African Reggae': [
    'Alpha Blondy',
    'Tiken Jah Fakoly',
    'Majek Fashek',
    'Ismaël Isaac',
  ],
  'Reggae > New Reggae': [
    'Sevana',
    'Christopher Martin',
    'Tarrus Riley',
    'Buju Banton',
  ],
  'Reggae > Reggae Classics': [
    'Peter Tosh',
    'Jimmy Cliff',
    'Desmond Dekker',
    'Toots and the Maytals',
  ],
  'Reggae > Reggae Love': [
    'Beres Hammond',
    'Freddie McGregor',
    'Glen Washington',
    'Sanchez',
  ],
  'Reggae > Reggae Party': [
    'Inner Circle',
    'Shabba Ranks',
    'Mr. Vegas',
    'Elephant Man',
  ],
  'Reggae > Rocksteady': [
    'The Paragons',
    'Alton Ellis',
    'Ken Boothe',
    'Phyllis Dillon',
  ],
  'Reggae > Ska': [
    'The Specials',
    'Madness',
    'The Beat',
    'Bad Manners',
  ],
  // ─── Rock (complément) ───
  'Rock > Garage Rock': [
    'The White Stripes',
    'The Hives',
    'Jet',
    'Wolfmother',
  ],
  'Rock > Post-Rock': [
    'Sigur Rós',
    'God Is an Astronaut',
    'Caspian',
    'Russian Circles',
  ],
  'Rock > Psychedelic Rock': [
    'Jimi Hendrix',
    'The Doors',
    'Jefferson Airplane',
    'Cream',
  ],
  // ─── Shadowings (apprentissage linguistique par chansons) ───
  'Shadowings > English Shadowing': [
    'Ed Sheeran',
    'Amy Winehouse',
    'Sam Smith',
    'Adele',
  ],
  'Shadowings > French Shadowing': [
    'Stromae',
    'Indila',
    'Christophe Maé',
    'Tal',
  ],
  'Shadowings > Beginner': [
    'Birdy',
    'Katie Melua',
    'Kina Grannis',
    'Gabrielle Aplin',
  ],
  'Shadowings > Intermediate': [
    'OneRepublic',
    'James Arthur',
    'Charlie Puth',
    'James Bay',
  ],
  'Shadowings > Advanced': [
    'Eminem',
    'Kendrick Lamar',
    'Busta Rhymes',
    'Tech N9ne',
  ],
  'Shadowings > Pronunciation': [
    'Annie Lennox',
    'Seal',
    'Sade',
    'Carpenters',
  ],
  'Shadowings > Conversation': [
    'Tracy Chapman',
    'Leonard Cohen',
    'Van Morrison',
    'Cat Stevens',
  ],
  'Shadowings > Daily English': [
    'Maroon 5',
    'Coldplay',
    'Taylor Swift',
    'Billie Eilish',
  ],
  'Shadowings > Business English': [
    'Michael Bublé',
    'Jamie Cullum',
    'George Ezra',
    'Paloma Faith',
  ],
  'Shadowings > Travel English': [
    'Zach Bryan',
    'Of Monsters and Men',
    'The Lumineers',
    'Tom Petty',
  ],
  'Shadowings > American English': [
    'Bruce Springsteen',
    'Creedence Clearwater Revival',
    'Johnny Cash',
    'Simon & Garfunkel',
  ],
  'Shadowings > British English': [
    'Oasis',
    'Blur',
    'The Beatles',
    'David Bowie',
  ],
  // ─── Sleep (complément) ───
  'Sleep > White Noise': [
    'Bibio',
    'The Orb',
    'Global Communication',
    'Tycho',
  ],
  // ─── Soul (complément) ───
  'Soul > Neo Soul': [
    'D\'Angelo',
    'Jill Scott',
    'Musiq Soulchild',
    'Maxwell',
  ],
  'Soul > Soul Classics': [
    'The Drifters',
    'Ben E. King',
    'Wilson Pickett',
    'Percy Sledge',
  ],
  'Soul > Soul Love': [
    'Barry White',
    'Anita Baker',
    'Luther Vandross',
    'Teddy Pendergrass',
  ],
  // ─── Workout (complément) ───
  'Workout > Boxing': [
    'Roy Jones Jr.',
    'Survivor',
    'Zombie Nation',
    '2Pac',
  ],

  // ─── Amapiano ───
  'Amapiano > Amapiano Hits': [
    'Kabza De Small',
    'DJ Maphorisa',
    'Focalistic',
    'Uncle Waffles',
    'Major League DJz',
  ],
  'Amapiano > Private School Piano': [
    'Kabza De Small',
    'Soa Mattrix',
    'DJ Jaivane',
    'Mellow & Sleazy',
    'Aymos',
  ],
  'Amapiano > Log Drums': [
    'Uncle Waffles',
    'Focalistic',
    'DBN Gogo',
    'Pabi Cooper',
    'Young Stunna',
  ],
  'Amapiano > Yanos Classics': [
    'DJ Maphorisa',
    'Kabza De Small',
    'Busiswa',
    'Moonchild Sanelly',
    'Distruction Boyz',
  ],
  'Amapiano > SA House': [
    'Black Coffee',
    'Shimza',
    'DJ Kentalky',
    'Themba Mbokazi',
    'Sun-EL Musician',
  ],
  'Amapiano > Amapiano Mix': [
    'Major League DJz',
    'DJ Jaivane',
    'Soa Mattrix',
    'MFR Souls',
    'Semi Tee',
  ],
  'Amapiano > Afro Piano': [
    'Burna Boy',
    'Wizkid',
    'Asake',
    'Ruger',
    'Fireboy DML',
  ],
  'Amapiano > Piano & Amapiano': [
    'TitoM & Yuppe',
    'Nkosazana Daughter',
    'Zaba',
    'SjavasDaDeejay',
    'Da Muziqal Chef',
  ],

  // ─── Bande Originale ───
  'Bande Originale > Bandes-Originales': [
    'Hans Zimmer',
    'John Williams',
    'Ennio Morricone',
    'Ludwig Göransson',
    'Alexandre Desplat',
  ],
  'Bande Originale > Disney': [
    'Alan Menken',
    'Lin-Manuel Miranda',
    'Zendaya',
    'Idina Menzel',
    'Bruno Mars',
  ],
  'Bande Originale > Séries TV': [
    'Ramin Djawadi',
    'Max Richter',
    'Bear McCreary',
    'Nicholas Britell',
    'Mac Quayle',
  ],
  'Bande Originale > Anime': [
    'Yoko Kanno',
    'Hiroyuki Sawano',
    'Joe Hisaishi',
    'LiSA',
    'Eve',
  ],
  'Bande Originale > Comédies Musicales': [
    'Lin-Manuel Miranda',
    'Andrew Lloyd Webber',
    'Claude-Michel Schönberg',
    'Stephen Schwartz',
    'Jonathan Larson',
  ],
  'Bande Originale > Hans Zimmer': [
    'Hans Zimmer',
    'Benjamin Wallfisch',
    'Steve Jablonsky',
    'James Newton Howard',
    'Lorne Balfe',
  ],
  'Bande Originale > John Williams': [
    'John Williams',
    'London Symphony Orchestra',
    'Boston Pops Orchestra',
    'Anne-Sophie Mutter',
    'Itzhak Perlman',
  ],
  'Bande Originale > Classiques du Cinéma': [
    'Ennio Morricone',
    'Nino Rota',
    'Bernard Herrmann',
    'Maurice Jarre',
    'Michel Legrand',
  ],

  // ─── Dancehall ───
  'Dancehall > Dancehall Hits': [
    'Vybz Kartel',
    'Popcaan',
    'Skillibeng',
    'Shenseea',
    'Konshens',
  ],
  'Dancehall > Reggae Fusion': [
    'Sean Paul',
    'Major Lazer',
    'Gyptian',
    'Omi',
    'Shaggy',
  ],
  'Dancehall > Old School Dancehall': [
    'Beenie Man',
    'Buju Banton',
    'Capleton',
    'Bounty Killer',
    'Elephant Man',
  ],
  'Dancehall > Bashment': [
    'Charly Black',
    'Konshens',
    'Demarco',
    'Aidonia',
    'I-Octane',
  ],
  'Dancehall > Afro Dancehall': [
    'Stonebwoy',
    'Shatta Wale',
    'Patoranking',
    'Timaya',
    'Mr Eazi',
  ],
  'Dancehall > Dancehall Français': [
    'Admiral T',
    'Kaaris',
    'Kalash',
    'Hurtigruten',
    'Saïk',
  ],
  'Dancehall > Moombahton': [
    'Dillon Francis',
    'Major Lazer',
    'DJ Snake',
    'Diplo',
    'Tropkillaz',
  ],
  'Dancehall > Reggaeton Dancehall': [
    'Daddy Yankee',
    'Don Omar',
    'Zion & Lennox',
    'Plan B',
    'Ivy Queen',
  ],

  // ─── Musique Arabe ───
  'Musique Arabe > Hits Arabe': [
    'Amr Diab',
    'Sherine',
    'Saad Lamjarred',
    'Nancy Ajram',
    'Tamer Hosny',
  ],
  'Musique Arabe > Égypte': [
    'Amr Diab',
    'Sherine',
    'Tamer Hosny',
    'Mohamed Ramadan',
    'Angham',
  ],
  'Musique Arabe > Maroc': [
    'Saad Lamjarred',
    'Douzi',
    'Hatim Ammor',
    'ElGrandeToto',
    'Zouhair Bahaoui',
  ],
  'Musique Arabe > Algérie': [
    'Cheb Khaled',
    'Cheb Mami',
    'Rachid Taha',
    'Sofiane Saidi',
    'Bilal Sghir',
  ],
  'Musique Arabe > Tunisie': [
    'Saber Rebai',
    'Latifa',
    'Lotfi Bouchnak',
    'Balti',
    'Ahmed Chaouch',
  ],
  'Musique Arabe > Liban': [
    'Fairuz',
    'Nancy Ajram',
    'Elissa',
    'Wael Kfoury',
    'Assala',
  ],
  'Musique Arabe > Raï': [
    'Cheb Khaled',
    'Cheb Mami',
    'Cheb Hasni',
    'Reda Taliani',
    'Cheikha Rimitti',
  ],
  'Musique Arabe > Khaliji': [
    'Hussain Al Jassmi',
    'Abdul Majeed Abdullah',
    'Rashed Al Majed',
    'Balqees',
    'Aseel Hameem',
  ],

  // ─── Rumba Congolaise ───
  'Rumba Congolaise > Rumba Hits': [
    'Fally Ipupa',
    'Ferre Gola',
    'Innoss\'B',
    'Koffi Olomidé',
    'Héritier Watanabe',
  ],
  'Rumba Congolaise > Rumba Classique': [
    'Papa Wemba',
    'Madilu System',
    'Tabu Ley Rochereau',
    'Franco Luambo',
    'Pepe Kalle',
  ],
  'Rumba Congolaise > Ndombolo': [
    'Awilo Longomba',
    'Werrason',
    'JB Mpiana',
    'Koffi Olomidé',
    'Zaiko Langa Langa',
  ],
  'Rumba Congolaise > Congo Kinshasa': [
    'Fally Ipupa',
    'Ferre Gola',
    'Werrason',
    'Fabregas Le Métis Noir',
    'Dena Mwana',
  ],
  'Rumba Congolaise > Congo Brazzaville': [
    'Youssoupha',
    'Passi',
    'Caloé',
    'Naza',
    'KeBlack',
  ],
  'Rumba Congolaise > Rumba Moderne': [
    'Innoss\'B',
    'Fally Ipupa',
    'Gaz Mawete',
    'Dadju',
    'KeBlack',
  ],
  'Rumba Congolaise > Guitaristes Légendaires': [
    'Franco Luambo',
    'Diblo Dibala',
    'Rigo Star',
    'Nyboma',
    'Simaro Lutumba',
  ],
  'Rumba Congolaise > Soukous': [
    'Awilo Longomba',
    'Kanda Bongo Man',
    'Papa Wemba',
    'Kassav',
    'Loketo',
  ],

  // ─── Drill ───
  'Drill > UK Drill': [
    'Central Cee',
    'Headie One',
    'Digga D',
    'Pop Smoke',
    'OFB',
  ],
  'Drill > Drill Français': [
    'Gazo',
    'Tiakola',
    'Freeze Corleone',
    'Koba LaD',
    'Zed',
  ],
  'Drill > Brooklyn Drill': [
    'Pop Smoke',
    'Fivio Foreign',
    'Sheff G',
    'Sleepy Hallow',
    '22Gz',
  ],
  'Drill > Afro Drill': [
    'Rema',
    'Blxckie',
    'Magixx',
    'Alpha P',
    'Prettyboy D-O',
  ],
  'Drill > Drill Beats': [
    'Ghosty',
    'MKThePlug',
    'Gotts',
    'Chris Rich',
    '8DS',
  ],
  'Drill > New York Drill': [
    'Ice Spice',
    'Lola Brooke',
    'Kay Flock',
    'B-Lovee',
    'Cash Cobain',
  ],
  'Drill > Drill Australien': [
    'ONEFOUR',
    'Hooligan Hefs',
    'Spanian',
    'Lisi',
    'P1llboy',
  ],
  'Drill > Irish Drill': [
    'A92',
    'Offica',
    'Popman',
    'S4E',
    'Double G',
  ],
};

/// Sub-category seeds keyed by `category > sub`. Returns the curated artist
/// list for a sub-section, or `null` when the parent category seeds should
/// be used instead. Matching is case- and punctuation-insensitive.
List<String>? subCategorySeeds(String category, String sub) {
  final key = "$category > $sub".trim();
  if (_subCategorySeeds.containsKey(key)) return _subCategorySeeds[key];
  final lowerKey = key.toLowerCase();
  for (final entry in _subCategorySeeds.entries) {
    if (entry.key.toLowerCase() == lowerKey) return entry.value;
  }
  return null;
}
