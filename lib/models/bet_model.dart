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
    int confidenceScore = 5,
  }) : confidenceScore = _normalizeConfidenceScore(confidenceScore);

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

  static int _normalizeConfidenceScore(int value) {
    if (value < 1) return 1;
    if (value > 10) return 10;
    return value;
  }

  static int _readConfidenceScore(dynamic rawValue) {
    if (rawValue is num) {
      return _normalizeConfidenceScore(rawValue.toInt());
    }

    if (rawValue is String) {
      final parsed = int.tryParse(rawValue.trim());
      if (parsed != null) {
        return _normalizeConfidenceScore(parsed);
      }
    }

    return 5;
  }

  static double _readDouble(dynamic value) {
    if (value is num) {
      return value.toDouble();
    }

    if (value is String) {
      return double.tryParse(value.trim().replaceAll(',', '.')) ?? 0.0;
    }

    return 0.0;
  }

  static DateTime _readDateTime(dynamic value) {
    if (value is Timestamp) {
      return value.toDate();
    }

    if (value is DateTime) {
      return value;
    }

    if (value is int) {
      return DateTime.fromMillisecondsSinceEpoch(value);
    }

    if (value is String) {
      return DateTime.tryParse(value.trim()) ?? DateTime.now();
    }

    return DateTime.now();
  }

  static String _readResult(dynamic value) {
    final normalized = (value ?? '').toString().trim();

    if (normalized == 'kazandi' ||
        normalized == 'kaybetti' ||
        normalized == 'iade' ||
        normalized == 'beklemede') {
      return normalized;
    }

    return 'beklemede';
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
      'confidenceScore': _normalizeConfidenceScore(confidenceScore),
    };
  }

  factory BetModel.fromMap(Map<String, dynamic> map, String documentId) {
    final rawMatchName = (map['matchName'] ?? '').toString();
    final parsed = _parseMatchName(rawMatchName);

    return BetModel(
      id: documentId,
      userId: (map['userId'] ?? '').toString(),
      date: _readDateTime(map['date']),
      sport: (map['sport'] ?? '').toString(),
      country: (map['country'] ?? '').toString(),
      league: (map['league'] ?? '').toString(),
      homeTeam: (map['homeTeam'] ?? parsed['homeTeam'] ?? '').toString(),
      awayTeam: (map['awayTeam'] ?? parsed['awayTeam'] ?? '').toString(),
      matchName: rawMatchName,
      betType: (map['betType'] ?? '').toString(),
      odd: _readDouble(map['odd']),
      stake: _readDouble(map['stake']),
      result: _readResult(map['result']),
      netProfit: _readDouble(map['netProfit']),
      note: (map['note'] ?? '').toString(),
      createdAt: _readDateTime(map['createdAt']),
      confidenceScore: _readConfidenceScore(map['confidenceScore']),
    );
  }
}