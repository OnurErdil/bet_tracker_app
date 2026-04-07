class BetFormCatalog {
  static const List<String> sports = [
    'Futbol',
    'Basketbol',
    'Tenis',
    'Voleybol',
    'Diğer',
  ];

  static final Map<String, Map<String, Map<String, List<String>>>> teamData = {
    'Futbol': {
      'Türkiye': {
        'Süper Lig': [
          'Kocaelispor',
          'Beşiktaş',
          'Galatasaray',
          'Fenerbahçe',
          'Trabzonspor',
          'Başakşehir',
          'Göztepe',
        ],
        '1. Lig': [
          'Sakaryaspor',
          'Bursaspor',
        ],
      },
      'İspanya': {
        'La Liga': [
          'Real Madrid',
          'Barcelona',
          'Atletico Madrid',
        ],
      },
      'İngiltere': {
        'Premier League': [
          'Manchester City',
          'Manchester United',
          'Liverpool',
          'Arsenal',
          'Chelsea',
        ],
      },
      'Almanya': {
        'Bundesliga': [
          'Bayern Münih',
          'Borussia Dortmund',
        ],
      },
      'Fransa': {
        'Ligue 1': [
          'PSG',
        ],
      },
      'İtalya': {
        'Serie A': [
          'Inter',
          'Milan',
          'Juventus',
          'Napoli',
        ],
      },
    },
    'Basketbol': {
      'ABD': {
        'NBA': [
          'Los Angeles Lakers',
          'Boston Celtics',
          'Golden State Warriors',
          'Chicago Bulls',
        ],
      },
      'Türkiye': {
        'Basketbol Süper Ligi': [
          'Anadolu Efes',
          'Fenerbahçe Beko',
          'Galatasaray',
          'Beşiktaş',
        ],
      },
    },
    'Tenis': {
      'Genel': {
        'ATP': [
          'Novak Djokovic',
          'Carlos Alcaraz',
          'Jannik Sinner',
        ],
        'WTA': [
          'Iga Swiatek',
          'Aryna Sabalenka',
          'Coco Gauff',
        ],
      },
    },
    'Voleybol': {
      'Türkiye': {
        'Sultanlar Ligi': [
          'VakıfBank',
          'Eczacıbaşı',
          'Fenerbahçe Medicana',
        ],
        'Efeler Ligi': [
          'Halkbank',
          'Ziraat Bankkart',
        ],
      },
    },
    'Diğer': {},
  };

  static final Map<String, List<String>> betTypesBySport = {
    'Futbol': [
      'MS 1',
      'MS X',
      'MS 2',
      'ÇŞ 1X',
      'ÇŞ 12',
      'ÇŞ X2',
      'Üst 2.5',
      'Alt 2.5',
      'Karşılıklı Gol Var',
      'Karşılıklı Gol Yok',
    ],
    'Basketbol': [
      'Maç Sonucu 1',
      'Maç Sonucu 2',
      'Üst',
      'Alt',
      'Handikaplı Maç Sonucu',
    ],
    'Tenis': [
      'Maç Sonucu 1',
      'Maç Sonucu 2',
      'Set Skoru',
      'Toplam Oyun Üst',
      'Toplam Oyun Alt',
    ],
    'Voleybol': [
      'Maç Sonucu 1',
      'Maç Sonucu 2',
      'Set Sayısı Üst',
      'Set Sayısı Alt',
    ],
    'Diğer': [
      'Maç Sonucu',
      'Üst/Alt',
      'Handikap',
      'Diğer',
    ],
  };

  static List<String> getAvailableCountries(String sport) {
    return (teamData[sport] ?? {}).keys.toList();
  }

  static List<String> getAvailableLeagues(String sport, String country) {
    return (teamData[sport]?[country] ?? {}).keys.toList();
  }

  static List<String> getAvailableTeams(
      String sport,
      String country,
      String league,
      ) {
    if (sport.isEmpty || country.isEmpty || league.isEmpty) {
      return [];
    }

    return teamData[sport]?[country]?[league] ?? [];
  }

  static List<String> getAvailableBetTypes(String sport) {
    return betTypesBySport[sport] ?? [];
  }

  static Map<String, String>? findTeamPath(String teamName) {
    final normalizedTeam = teamName.trim();
    if (normalizedTeam.isEmpty) return null;

    for (final sportEntry in teamData.entries) {
      final sport = sportEntry.key;
      final countries = sportEntry.value;

      for (final countryEntry in countries.entries) {
        final country = countryEntry.key;
        final leagues = countryEntry.value;

        for (final leagueEntry in leagues.entries) {
          final league = leagueEntry.key;
          final teams = leagueEntry.value;

          if (teams.contains(normalizedTeam)) {
            return {
              'sport': sport,
              'country': country,
              'league': league,
            };
          }
        }
      }
    }

    return null;
  }
}