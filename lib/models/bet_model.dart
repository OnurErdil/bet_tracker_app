import 'package:cloud_firestore/cloud_firestore.dart';

class BetModel {
  final String? id;
  final String userId;
  final DateTime date;
  final String sport;
  final String country;
  final String league;
  final String matchName;
  final String betType;
  final double odd;
  final double stake;
  final String result; // kazandi, kaybetti, iade, beklemede
  final double netProfit;
  final String note;
  final DateTime createdAt;

  BetModel({
    this.id,
    required this.userId,
    required this.date,
    required this.sport,
    required this.country,
    required this.league,
    required this.matchName,
    required this.betType,
    required this.odd,
    required this.stake,
    required this.result,
    required this.netProfit,
    required this.note,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'date': Timestamp.fromDate(date),
      'sport': sport,
      'country': country,
      'league': league,
      'matchName': matchName,
      'betType': betType,
      'odd': odd,
      'stake': stake,
      'result': result,
      'netProfit': netProfit,
      'note': note,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  factory BetModel.fromMap(Map<String, dynamic> map, String documentId) {
    return BetModel(
      id: documentId,
      userId: map['userId'] ?? '',
      date: (map['date'] as Timestamp).toDate(),
      sport: map['sport'] ?? '',
      country: map['country'] ?? '',
      league: map['league'] ?? '',
      matchName: map['matchName'] ?? '',
      betType: map['betType'] ?? '',
      odd: (map['odd'] ?? 0).toDouble(),
      stake: (map['stake'] ?? 0).toDouble(),
      result: map['result'] ?? 'beklemede',
      netProfit: (map['netProfit'] ?? 0).toDouble(),
      note: map['note'] ?? '',
      createdAt: (map['createdAt'] as Timestamp).toDate(),
    );
  }
}