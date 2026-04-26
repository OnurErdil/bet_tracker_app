import 'package:bet_tracker_app/domain/bet_calculator.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('BetCalculator.calculateNetProfit', () {
    test('kazanan bahis için net kârı hesaplar', () {
      final result = BetCalculator.calculateNetProfit(
        odd: 2.0,
        stake: 100,
        result: 'kazandi',
      );

      expect(result, 100.0);
    });

    test('kazanan bahis için ondalıklı oranla net kârı hesaplar', () {
      final result = BetCalculator.calculateNetProfit(
        odd: 1.85,
        stake: 200,
        result: 'kazandi',
      );

      expect(result, closeTo(170.0, 0.001));
    });

    test('kaybeden bahis için stake kadar zarar yazar', () {
      final result = BetCalculator.calculateNetProfit(
        odd: 2.0,
        stake: 100,
        result: 'kaybetti',
      );

      expect(result, -100.0);
    });

    test('iade bahis için net etki sıfırdır', () {
      final result = BetCalculator.calculateNetProfit(
        odd: 2.0,
        stake: 100,
        result: 'iade',
      );

      expect(result, 0.0);
    });

    test('beklemede bahis için net etki sıfırdır', () {
      final result = BetCalculator.calculateNetProfit(
        odd: 2.0,
        stake: 100,
        result: 'beklemede',
      );

      expect(result, 0.0);
    });

    test('bilinmeyen sonuç için net etki sıfırdır', () {
      final result = BetCalculator.calculateNetProfit(
        odd: 2.0,
        stake: 100,
        result: 'iptal',
      );

      expect(result, 0.0);
    });
  });

  group('BetCalculator.calculatePayout', () {
    test('kazanan bahis için toplam geri ödeme oran x stake olur', () {
      final result = BetCalculator.calculatePayout(
        odd: 2.5,
        stake: 100,
        result: 'kazandi',
      );

      expect(result, 250.0);
    });

    test('iade bahis için sadece stake geri döner', () {
      final result = BetCalculator.calculatePayout(
        odd: 2.5,
        stake: 100,
        result: 'iade',
      );

      expect(result, 100.0);
    });

    test('kaybeden bahis için geri ödeme sıfırdır', () {
      final result = BetCalculator.calculatePayout(
        odd: 2.5,
        stake: 100,
        result: 'kaybetti',
      );

      expect(result, 0.0);
    });

    test('beklemede bahis için geri ödeme sıfırdır', () {
      final result = BetCalculator.calculatePayout(
        odd: 2.5,
        stake: 100,
        result: 'beklemede',
      );

      expect(result, 0.0);
    });

    test('bilinmeyen sonuç için geri ödeme sıfırdır', () {
      final result = BetCalculator.calculatePayout(
        odd: 2.5,
        stake: 100,
        result: 'iptal',
      );

      expect(result, 0.0);
    });
  });
}