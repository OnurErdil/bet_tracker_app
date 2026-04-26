import 'package:bet_tracker_app/models/bet_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  BetModel createBet({
    int confidenceScore = 5,
    String homeTeam = '',
    String awayTeam = '',
    String matchName = 'Kocaelispor - Beşiktaş',
  }) {
    return BetModel(
      userId: 'user-1',
      date: DateTime(2026, 4, 26),
      sport: 'Futbol',
      country: 'Türkiye',
      league: 'Süper Lig',
      homeTeam: homeTeam,
      awayTeam: awayTeam,
      matchName: matchName,
      betType: 'MS 1',
      odd: 2.0,
      stake: 100,
      result: 'beklemede',
      netProfit: 0,
      note: '',
      createdAt: DateTime(2026, 4, 26, 12),
      confidenceScore: confidenceScore,
    );
  }

  group('BetModel confidenceScore', () {
    test('constructor confidenceScore değerini 1 ile 10 arasına sıkıştırır', () {
      expect(createBet(confidenceScore: -5).confidenceScore, 1);
      expect(createBet(confidenceScore: 0).confidenceScore, 1);
      expect(createBet(confidenceScore: 5).confidenceScore, 5);
      expect(createBet(confidenceScore: 15).confidenceScore, 10);
    });

    test('fromMap confidenceScore string/numeric değerleri güvenli okur', () {
      final low = BetModel.fromMap(
        {
          'confidenceScore': '-3',
          'matchName': 'A - B',
        },
        'bet-1',
      );

      final high = BetModel.fromMap(
        {
          'confidenceScore': 99,
          'matchName': 'A - B',
        },
        'bet-2',
      );

      final fallback = BetModel.fromMap(
        {
          'confidenceScore': 'abc',
          'matchName': 'A - B',
        },
        'bet-3',
      );

      expect(low.confidenceScore, 1);
      expect(high.confidenceScore, 10);
      expect(fallback.confidenceScore, 5);
    });
  });

  group('BetModel fromMap/toMap', () {
    test('fromMap string sayıları, tarihleri ve geçersiz sonucu güvenli okur', () {
      final date = DateTime(2026, 4, 26, 15, 30);
      final createdAt = DateTime(2026, 4, 26, 16, 45);

      final bet = BetModel.fromMap(
        {
          'userId': 'user-1',
          'date': Timestamp.fromDate(date),
          'sport': 'Futbol',
          'country': 'Türkiye',
          'league': 'Süper Lig',
          'matchName': 'Kocaelispor - Beşiktaş',
          'betType': 'MS 1',
          'odd': '2,25',
          'stake': '150,5',
          'result': 'bilinmeyen',
          'netProfit': '75,25',
          'note': 'test notu',
          'createdAt': createdAt.toIso8601String(),
          'confidenceScore': '9',
        },
        'bet-1',
      );

      expect(bet.id, 'bet-1');
      expect(bet.userId, 'user-1');
      expect(bet.date, date);
      expect(bet.createdAt, createdAt);
      expect(bet.odd, 2.25);
      expect(bet.stake, 150.5);
      expect(bet.netProfit, 75.25);
      expect(bet.result, 'beklemede');
      expect(bet.resolvedHomeTeam, 'Kocaelispor');
      expect(bet.resolvedAwayTeam, 'Beşiktaş');
      expect(bet.confidenceScore, 9);
    });

    test('toMap resolvedHomeTeam/resolvedAwayTeam ve confidenceScore yazar', () {
      final date = DateTime(2026, 4, 26);
      final createdAt = DateTime(2026, 4, 26, 12);

      final bet = BetModel(
        userId: 'user-1',
        date: date,
        sport: 'Futbol',
        country: 'Türkiye',
        league: 'Süper Lig',
        matchName: 'Kocaelispor - Beşiktaş',
        betType: 'MS 1',
        odd: 2.0,
        stake: 100,
        result: 'kazandi',
        netProfit: 100,
        note: 'not',
        createdAt: createdAt,
        confidenceScore: 15,
      );

      final map = bet.toMap();

      expect(map['userId'], 'user-1');
      expect(map['homeTeam'], 'Kocaelispor');
      expect(map['awayTeam'], 'Beşiktaş');
      expect(map['confidenceScore'], 10);
      expect((map['date'] as Timestamp).toDate(), date);
      expect((map['createdAt'] as Timestamp).toDate(), createdAt);
    });

    test('resolved takım alanları doluysa matchName yerine onları kullanır', () {
      final bet = createBet(
        homeTeam: 'Galatasaray',
        awayTeam: 'Fenerbahçe',
        matchName: 'Kocaelispor - Beşiktaş',
      );

      expect(bet.resolvedHomeTeam, 'Galatasaray');
      expect(bet.resolvedAwayTeam, 'Fenerbahçe');
    });
  });
}