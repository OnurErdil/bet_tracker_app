import 'package:bet_tracker_app/domain/bankroll_discipline_calculator.dart';
import 'package:bet_tracker_app/models/bankroll_transaction_model.dart';
import 'package:bet_tracker_app/models/bet_model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  BetModel bet({
    required DateTime date,
    required String result,
    required double netProfit,
    double stake = 100,
  }) {
    return BetModel(
      userId: 'user-1',
      date: date,
      sport: 'Futbol',
      country: 'Türkiye',
      league: 'Süper Lig',
      homeTeam: 'Kocaelispor',
      awayTeam: 'Beşiktaş',
      matchName: 'Kocaelispor - Beşiktaş',
      betType: 'MS 1',
      odd: 2.0,
      stake: stake,
      result: result,
      netProfit: netProfit,
      note: '',
      createdAt: date,
    );
  }

  BankrollTransaction transaction({
    required double amount,
    required String type,
  }) {
    return BankrollTransaction(
      userId: 'user-1',
      amount: amount,
      type: type,
      note: '',
      createdAt: DateTime(2026, 4, 26),
    );
  }

  group('BankrollDisciplineCalculator.calculate', () {
    test('kasa, toplam kâr, kasa hareketi ve sabit max stake hesaplar', () {
      final referenceDate = DateTime(2026, 4, 26, 12);

      final snapshot = BankrollDisciplineCalculator.calculate(
        referenceDate: referenceDate,
        bets: [
          bet(
            date: referenceDate,
            result: 'kazandi',
            netProfit: 500,
          ),
          bet(
            date: referenceDate,
            result: 'kaybetti',
            netProfit: -200,
          ),
        ],
        transactions: [
          transaction(amount: 1000, type: 'deposit'),
          transaction(amount: 250, type: 'withdraw'),
        ],
        userData: {
          'startingBankroll': 10000,
          'maxStakeMode': 'fixed',
          'maxStakeValue': 400,
          'dailyLossLimit': 500,
          'targetBankroll': 15000,
          'disciplineMode': 'warning',
        },
      );

      expect(snapshot.totalProfit, 300.0);
      expect(snapshot.bankrollMovement, 750.0);
      expect(snapshot.currentBankroll, 11050.0);
      expect(snapshot.computedMaxStake, 400.0);
      expect(snapshot.todayLoss, 200.0);
      expect(snapshot.remainingDailyLoss, 300.0);
      expect(snapshot.isDailyLossExceeded, false);
      expect(snapshot.isLockedForToday, false);
    });

    test('yüzde modunda max stake güncel kasa üzerinden hesaplanır', () {
      final referenceDate = DateTime(2026, 4, 26, 12);

      final snapshot = BankrollDisciplineCalculator.calculate(
        referenceDate: referenceDate,
        bets: [
          bet(
            date: referenceDate,
            result: 'kazandi',
            netProfit: 500,
          ),
        ],
        transactions: [
          transaction(amount: 500, type: 'deposit'),
        ],
        userData: {
          'startingBankroll': 10000,
          'maxStakeMode': 'percent',
          'maxStakeValue': 4,
          'dailyLossLimit': 0,
          'targetBankroll': 0,
          'disciplineMode': 'warning',
        },
      );

      expect(snapshot.currentBankroll, 11000.0);
      expect(snapshot.computedMaxStake, 440.0);
    });

    test('lock_day modunda günlük limit aşılırsa gün kilitlenir', () {
      final referenceDate = DateTime(2026, 4, 26, 12);

      final snapshot = BankrollDisciplineCalculator.calculate(
        referenceDate: referenceDate,
        bets: [
          bet(
            date: referenceDate,
            result: 'kaybetti',
            netProfit: -250,
          ),
        ],
        transactions: const [],
        userData: {
          'startingBankroll': 10000,
          'maxStakeMode': 'fixed',
          'maxStakeValue': 400,
          'dailyLossLimit': 200,
          'targetBankroll': 0,
          'disciplineMode': 'lock_day',
        },
      );

      expect(snapshot.todayLoss, 250.0);
      expect(snapshot.remainingDailyLoss, 0.0);
      expect(snapshot.isDailyLossExceeded, true);
      expect(snapshot.isLockedForToday, true);
    });

    test('geçersiz ayar değerlerinde güvenli varsayılanları kullanır', () {
      final snapshot = BankrollDisciplineCalculator.calculate(
        referenceDate: DateTime(2026, 4, 26),
        bets: const [],
        transactions: const [],
        userData: {
          'startingBankroll': 'abc',
          'maxStakeMode': 'yanlis',
          'maxStakeValue': '100,5',
          'dailyLossLimit': '200,5',
          'disciplineMode': 'bilinmeyen',
          'highConfidenceEnabled': 'false',
        },
      );

      expect(snapshot.startingBankroll, 0.0);
      expect(snapshot.maxStakeMode, 'fixed');
      expect(snapshot.maxStakeValue, 100.5);
      expect(snapshot.dailyLossLimit, 200.5);
      expect(snapshot.disciplineMode, 'warning');
      expect(snapshot.highConfidenceEnabled, false);
    });
  });

  group('BankrollDisciplineCalculator confidence helpers', () {
    test('güven 9 ve 10 için izin verilen stake çarpanla artar', () {
      expect(
        BankrollDisciplineCalculator.calculateAllowedStakeForConfidence(
          baseMaxStake: 100,
          confidenceScore: 8,
          highConfidenceEnabled: true,
          confidence9Multiplier: 2,
          confidence10Multiplier: 3,
        ),
        100.0,
      );

      expect(
        BankrollDisciplineCalculator.calculateAllowedStakeForConfidence(
          baseMaxStake: 100,
          confidenceScore: 9,
          highConfidenceEnabled: true,
          confidence9Multiplier: 2,
          confidence10Multiplier: 3,
        ),
        200.0,
      );

      expect(
        BankrollDisciplineCalculator.calculateAllowedStakeForConfidence(
          baseMaxStake: 100,
          confidenceScore: 10,
          highConfidenceEnabled: true,
          confidence9Multiplier: 2,
          confidence10Multiplier: 3,
        ),
        300.0,
      );
    });

    test('yüksek güven kapalıysa stake artmaz', () {
      final result =
      BankrollDisciplineCalculator.calculateAllowedStakeForConfidence(
        baseMaxStake: 100,
        confidenceScore: 10,
        highConfidenceEnabled: false,
        confidence9Multiplier: 2,
        confidence10Multiplier: 3,
      );

      expect(result, 100.0);
    });

    test('çarpan 1 altına düşerse güvenli şekilde 1 kabul edilir', () {
      final result =
      BankrollDisciplineCalculator.calculateAllowedStakeForConfidence(
        baseMaxStake: 100,
        confidenceScore: 10,
        highConfidenceEnabled: true,
        confidence9Multiplier: 0.5,
        confidence10Multiplier: 0.2,
      );

      expect(result, 100.0);
    });
  });
}