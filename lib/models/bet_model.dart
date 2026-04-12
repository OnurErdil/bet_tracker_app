import 'package:cloud_firestore/cloud_firestore.dart';

class BetModel {
  final String? id;
  final String userId;
  final DateTime date;
  final String sport;
  final String country;
  final String league;
  final String homeTeam;
  final String awayTeam;
  final String matchName;
  final String betType;
  final double odd;
  final double stake;
  final String result; // kazandi, kaybetti, iade, beklemede
  final double netProfit;
  final String note;
  final DateTime createdAt;
  final int confidenceScore;

  BetModel({
    this.id,
    required this.userId,
    required this.date,
    required this.sport,
    required this.country,
    required this.league,
    this.homeTeam = '',
    this.awayTeam = '',
    required this.matchName,
    required this.betType,
    required this.odd,
    required this.stake,
    required this.result,
    required this.netProfit,
    required this.note,
    required this.createdAt,
    this.confidenceScore = 5,
  });

  static Map<String, String> _parseMatchName(String matchName) {
    final parts = matchName.split(' - ');

    final parsedHome = parts.isNotEmpty ? parts.first.trim() : '';
    final parsedAway =
    parts.length > 1 ? parts.sublist(1).join(' - ').trim() : '';

    return {
      'homeTeam': parsedHome,
      'awayTeam': parsedAway,
    };
  }

  String get resolvedHomeTeam {
    if (homeTeam.trim().isNotEmpty) return homeTeam.trim();
    return _parseMatchName(matchName)['homeTeam'] ?? '';
  }

  String get resolvedAwayTeam {
    if (awayTeam.trim().isNotEmpty) return awayTeam.trim();
    return _parseMatchName(matchName)['awayTeam'] ?? '';
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'date': Timestamp.fromDate(date),
      'sport': sport,
      'country': country,
      'league': league,
      'homeTeam': resolvedHomeTeam,
      'awayTeam': resolvedAwayTeam,
      'matchName': matchName,
      'betType': betType,
      'odd': odd,
      'stake': stake,
      'result': result,
      'netProfit': netProfit,
      'note': note,
      'createdAt': Timestamp.fromDate(createdAt),
      'confidenceScore': confidenceScore,
    };
  }

  factory BetModel.fromMap(Map<String, dynamic> map, String documentId) {
    final rawMatchName = (map['matchName'] ?? '').toString();
    final parsed = _parseMatchName(rawMatchName);

    return BetModel(
      id: documentId,
      userId: map['userId'] ?? '',
      date: (map['date'] as Timestamp).toDate(),
      sport: map['sport'] ?? '',
      country: map['country'] ?? '',
      league: map['league'] ?? '',
      homeTeam: (map['homeTeam'] ?? parsed['homeTeam'] ?? '').toString(),
      awayTeam: (map['awayTeam'] ?? parsed['awayTeam'] ?? '').toString(),
      matchName: rawMatchName,
      betType: map['betType'] ?? '',
      odd: (map['odd'] ?? 0).toDouble(),
      stake: (map['stake'] ?? 0).toDouble(),
      result: map['result'] ?? 'beklemede',
      netProfit: (map['netProfit'] ?? 0).toDouble(),
      note: map['note'] ?? '',
      createdAt: (map['createdAt'] as Timestamp).toDate(),
      confidenceScore: ((map['confidenceScore'] ?? 5) as num).toInt(),
    );
  }
}