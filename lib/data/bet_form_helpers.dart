import 'package:bet_tracker_app/data/bet_form_catalog.dart';
import 'package:bet_tracker_app/models/bet_model.dart';

class ParsedMatchName {
  final String homeTeam;
  final String awayTeam;

  const ParsedMatchName({
    required this.homeTeam,
    required this.awayTeam,
  });
}

class TeamSuggestionData {
  final List<String> recentTeams;
  final List<String> frequentTeams;

  const TeamSuggestionData({
    required this.recentTeams,
    required this.frequentTeams,
  });
}

class BetFormInitialData {
  final String sport;
  final String country;
  final String league;
  final String homeTeam;
  final String awayTeam;

  const BetFormInitialData({
    required this.sport,
    required this.country,
    required this.league,
    required this.homeTeam,
    required this.awayTeam,
  });
}

class BetFormSelectionData {
  final List<String> availableCountries;
  final List<String> availableLeagues;
  final List<String> availableTeams;
  final List<String> availableBetTypes;

  const BetFormSelectionData({
    required this.availableCountries,
    required this.availableLeagues,
    required this.availableTeams,
    required this.availableBetTypes,
  });
}
class BetFormHelpers {
  static ParsedMatchName parseMatchName(String matchName) {
    final parts = matchName.split(' - ');
    final homeTeam = parts.isNotEmpty ? parts.first.trim() : '';
    final awayTeam =
    parts.length > 1 ? parts.sublist(1).join(' - ').trim() : '';

    return ParsedMatchName(
      homeTeam: homeTeam,
      awayTeam: awayTeam,
    );
  }

  static TeamSuggestionData extractTeamSuggestionData(List<BetModel> bets) {
    final List<String> recentOrdered = [];
    final Map<String, int> frequencyMap = {};

    for (final bet in bets) {
      final teams = [
        bet.resolvedHomeTeam.trim(),
        bet.resolvedAwayTeam.trim(),
      ];

      for (final rawTeam in teams) {
        final team = rawTeam.trim();
        if (team.isEmpty) continue;

        frequencyMap[team] = (frequencyMap[team] ?? 0) + 1;

        if (!recentOrdered.contains(team)) {
          recentOrdered.add(team);
        }
      }
    }

    final frequentOrdered = frequencyMap.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return TeamSuggestionData(
      recentTeams: recentOrdered.take(10).toList(),
      frequentTeams:
      frequentOrdered.map((entry) => entry.key).take(10).toList(),
    );
  }
  static BetFormSelectionData buildSelectionData({
    required String sport,
    required String country,
    required String league,
  }) {
    final normalizedSport = sport.trim();
    final normalizedCountry = country.trim();
    final normalizedLeague = league.trim();

    return BetFormSelectionData(
      availableCountries: BetFormCatalog.getAvailableCountries(normalizedSport),
      availableLeagues: BetFormCatalog.getAvailableLeagues(
        normalizedSport,
        normalizedCountry,
      ),
      availableTeams: _getAvailableTeamsForSelection(
        sport: normalizedSport,
        country: normalizedCountry,
        league: normalizedLeague,
      ),
      availableBetTypes: BetFormCatalog.getAvailableBetTypes(normalizedSport),
    );
  }

  static List<String> _getAvailableTeamsForSelection({
    required String sport,
    required String country,
    required String league,
  }) {
    if (sport.isEmpty) {
      return [];
    }

    final sportData = BetFormCatalog.teamData[sport] ?? {};

    if (country.isNotEmpty && league.isNotEmpty) {
      return _uniqueSorted(
        BetFormCatalog.getAvailableTeams(sport, country, league),
      );
    }

    if (country.isNotEmpty) {
      final countryData = sportData[country] ?? {};
      return _uniqueSorted(
        countryData.values.expand((teams) => teams),
      );
    }

    return _uniqueSorted(
      sportData.values
          .expand((countryLeagues) => countryLeagues.values)
          .expand((teams) => teams),
    );
  }

  static List<String> _uniqueSorted(Iterable<String> values) {
    final list = values
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toSet()
        .toList()
      ..sort();

    return list;
  }


  static List<String> buildSmartTeamSuggestionsForSelection({
    required String query,
    required String sport,
    required String country,
    required String league,
    required List<String> recentTeams,
    required List<String> frequentTeams,
  }) {
    final selectionData = buildSelectionData(
      sport: sport,
      country: country,
      league: league,
    );

    return buildSmartTeamSuggestions(
      query: query,
      filteredTeams: selectionData.availableTeams,
      recentTeams: recentTeams,
      frequentTeams: frequentTeams,
    );
  }

  static List<String> buildSmartTeamSuggestions({
    required String query,
    required List<String> filteredTeams,
    required List<String> recentTeams,
    required List<String> frequentTeams,
  }) {
    final normalizedQuery = query.trim().toLowerCase();

    final combined = <String>[
      ...recentTeams.where((team) => filteredTeams.contains(team)),
      ...frequentTeams.where((team) => filteredTeams.contains(team)),
      ...filteredTeams,
    ];

    final uniqueOrdered = <String>[];
    for (final team in combined) {
      if (!uniqueOrdered.contains(team)) {
        uniqueOrdered.add(team);
      }
    }

    if (normalizedQuery.isEmpty) {
      return uniqueOrdered.take(12).toList();
    }

    final searchableTeams = uniqueOrdered.isNotEmpty
        ? uniqueOrdered
        : _uniqueSorted(
      BetFormCatalog.teamData.values
          .expand((countries) => countries.values)
          .expand((leagues) => leagues.values)
          .expand((teams) => teams),
    );

    final startsWithMatches = searchableTeams
        .where((team) => team.toLowerCase().startsWith(normalizedQuery))
        .toList();

    final containsMatches = searchableTeams
        .where(
          (team) =>
      !startsWithMatches.contains(team) &&
          team.toLowerCase().contains(normalizedQuery),
    )
        .toList();

    return [...startsWithMatches, ...containsMatches].take(12).toList();
  }

  static BetFormInitialData buildInitialDataFromBet(BetModel bet) {
    final homeTeam = bet.resolvedHomeTeam.trim();
    final awayTeam = bet.resolvedAwayTeam.trim();

    final detectedTeamPath =
        BetFormCatalog.findTeamPath(homeTeam) ??
            BetFormCatalog.findTeamPath(awayTeam);

    return BetFormInitialData(
      sport: bet.sport.trim().isNotEmpty
          ? bet.sport.trim()
          : (detectedTeamPath?['sport'] ?? ''),
      country: bet.country.trim().isNotEmpty
          ? bet.country.trim()
          : (detectedTeamPath?['country'] ?? ''),
      league: bet.league.trim().isNotEmpty
          ? bet.league.trim()
          : (detectedTeamPath?['league'] ?? ''),
      homeTeam: homeTeam,
      awayTeam: awayTeam,
    );
  }

  static String buildMatchName({
    required String homeTeam,
    required String awayTeam,
  }) {
    return '${homeTeam.trim()} - ${awayTeam.trim()}';
  }
}