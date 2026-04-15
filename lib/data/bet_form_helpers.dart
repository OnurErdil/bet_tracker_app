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
    return BetFormSelectionData(
      availableCountries: BetFormCatalog.getAvailableCountries(sport.trim()),
      availableLeagues: BetFormCatalog.getAvailableLeagues(
        sport.trim(),
        country.trim(),
      ),
      availableTeams: BetFormCatalog.getAvailableTeams(
        sport.trim(),
        country.trim(),
        league.trim(),
      ),
      availableBetTypes: BetFormCatalog.getAvailableBetTypes(sport.trim()),
    );
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

    final fallbackTeams = BetFormCatalog.teamData.values
        .expand((countries) => countries.values)
        .expand((leagues) => leagues.values)
        .expand((teams) => teams)
        .toSet()
        .toList();

    final sourceTeams = filteredTeams.isNotEmpty ? filteredTeams : fallbackTeams;

    final combined = <String>[
      ...recentTeams.where((team) => sourceTeams.contains(team)),
      ...frequentTeams.where((team) => sourceTeams.contains(team)),
      ...sourceTeams,
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

    final startsWithMatches = uniqueOrdered
        .where((team) => team.toLowerCase().startsWith(normalizedQuery))
        .toList();

    final containsMatches = uniqueOrdered
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