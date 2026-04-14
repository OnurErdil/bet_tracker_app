import 'dart:math' as math;

import 'package:bet_tracker_app/models/bankroll_transaction_model.dart';
import 'package:bet_tracker_app/models/bet_model.dart';

class BankrollDisciplineSnapshot {
  final double startingBankroll;
  final String maxStakeMode;
  final double maxStakeValue;
  final double dailyLossLimit;
  final double targetBankroll;
  final String disciplineMode;

  final double totalProfit;
  final double bankrollMovement;
  final double currentBankroll;
  final double computedMaxStake;

  final double todayLoss;
  final double remainingDailyLoss;
  final bool isDailyLossExceeded;
  final bool isLockedForToday;

  final bool highConfidenceEnabled;
  final double confidence9Multiplier;
  final double confidence10Multiplier;

  const BankrollDisciplineSnapshot({
    required this.startingBankroll,
    required this.maxStakeMode,
    required this.maxStakeValue,
    required this.dailyLossLimit,
    required this.targetBankroll,
    required this.disciplineMode,
    required this.totalProfit,
    required this.bankrollMovement,
    required this.currentBankroll,
    required this.computedMaxStake,
    required this.todayLoss,
    required this.remainingDailyLoss,
    required this.isDailyLossExceeded,
    required this.isLockedForToday,
    required this.highConfidenceEnabled,
    required this.confidence9Multiplier,
    required this.confidence10Multiplier,
  });
}

class BankrollDisciplineCalculator {
  static const bool defaultHighConfidenceEnabled = true;
  static const int highConfidenceThreshold = 9;
  static const double defaultConfidence9Multiplier = 2.0;
  static const double defaultConfidence10Multiplier = 3.0;

  static BankrollDisciplineSnapshot calculate({
    required List<BetModel> bets,
    required List<BankrollTransaction> transactions,
    required Map<String, dynamic> userData,
    DateTime? referenceDate,
  }) {
    final now = referenceDate ?? DateTime.now();

    final startingBankroll = (userData['startingBankroll'] ?? 0).toDouble();
    final maxStakeMode = (userData['maxStakeMode'] ?? 'fixed').toString();
    final maxStakeValue = (userData['maxStakeValue'] ?? 0).toDouble();
    final dailyLossLimit = (userData['dailyLossLimit'] ?? 0).toDouble();
    final targetBankroll = (userData['targetBankroll'] ?? 0).toDouble();
    final disciplineMode = (userData['disciplineMode'] ?? 'warning').toString();

    final highConfidenceEnabled =
    (userData['highConfidenceEnabled'] ?? defaultHighConfidenceEnabled)
    as bool;

    final confidence9Multiplier =
    (userData['confidence9Multiplier'] ?? defaultConfidence9Multiplier)
        .toDouble();

    final confidence10Multiplier =
    (userData['confidence10Multiplier'] ?? defaultConfidence10Multiplier)
        .toDouble();

    final totalProfit =
    bets.fold<double>(0, (sum, item) => sum + item.netProfit);

    final bankrollMovement = transactions.fold<double>(0, (sum, tx) {
      if (tx.type == 'deposit') return sum + tx.amount;
      if (tx.type == 'withdraw') return sum - tx.amount;
      return sum;
    });

    final currentBankroll = startingBankroll + totalProfit + bankrollMovement;

    final computedMaxStake =
    maxStakeMode == 'percent' && maxStakeValue > 0
        ? currentBankroll * (maxStakeValue / 100)
        : maxStakeValue;

    double todayLoss = 0;

    for (final bet in bets) {
      if (_isSameDay(bet.date, now) &&
          bet.result == 'kaybetti' &&
          bet.netProfit < 0) {
        todayLoss += bet.netProfit.abs();
      }
    }

    final isDailyLossExceeded =
        dailyLossLimit > 0 && todayLoss >= dailyLossLimit;

    final remainingDailyLoss =
    dailyLossLimit > 0 ? math.max(0.0, dailyLossLimit - todayLoss) : 0.0;

    final isLockedForToday =
        disciplineMode == 'lock_day' && isDailyLossExceeded;

    return BankrollDisciplineSnapshot(
      startingBankroll: startingBankroll,
      maxStakeMode: maxStakeMode,
      maxStakeValue: maxStakeValue,
      dailyLossLimit: dailyLossLimit,
      targetBankroll: targetBankroll,
      disciplineMode: disciplineMode,
      totalProfit: totalProfit,
      bankrollMovement: bankrollMovement,
      currentBankroll: currentBankroll,
      computedMaxStake: computedMaxStake,
      todayLoss: todayLoss,
      remainingDailyLoss: remainingDailyLoss,
      isDailyLossExceeded: isDailyLossExceeded,
      isLockedForToday: isLockedForToday,
      highConfidenceEnabled: highConfidenceEnabled,
      confidence9Multiplier: confidence9Multiplier,
      confidence10Multiplier: confidence10Multiplier,
    );
  }

  static double calculateAllowedStakeForConfidence({
    required double baseMaxStake,
    required int confidenceScore,
    required bool highConfidenceEnabled,
    required double confidence9Multiplier,
    required double confidence10Multiplier,
  }) {
    if (baseMaxStake <= 0) return 0;
    if (!highConfidenceEnabled) return baseMaxStake;

    final safe9Multiplier = math.max(1.0, confidence9Multiplier);
    final safe10Multiplier = math.max(1.0, confidence10Multiplier);

    if (confidenceScore >= 10) {
      return baseMaxStake * safe10Multiplier;
    }

    if (confidenceScore >= 9) {
      return baseMaxStake * safe9Multiplier;
    }

    return baseMaxStake;
  }

  static bool isHighConfidence(
      int confidenceScore, {
        bool highConfidenceEnabled = true,
      }) {
    return highConfidenceEnabled && confidenceScore >= highConfidenceThreshold;
  }

  static double confidenceMultiplier(
      int confidenceScore, {
        required bool highConfidenceEnabled,
        required double confidence9Multiplier,
        required double confidence10Multiplier,
      }) {
    if (!highConfidenceEnabled) return 1.0;
    if (confidenceScore >= 10) return math.max(1.0, confidence10Multiplier);
    if (confidenceScore >= 9) return math.max(1.0, confidence9Multiplier);
    return 1.0;
  }

  static bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }
}