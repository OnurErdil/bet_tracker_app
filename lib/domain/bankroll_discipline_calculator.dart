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

  static double _readDouble(
      dynamic value, {
        double fallback = 0.0,
      }) {
    if (value is num) {
      return value.toDouble();
    }

    if (value is String) {
      return double.tryParse(value.trim().replaceAll(',', '.')) ?? fallback;
    }

    return fallback;
  }

  static bool _readBool(
      dynamic value, {
        required bool fallback,
      }) {
    if (value is bool) {
      return value;
    }

    if (value is String) {
      final normalized = value.trim().toLowerCase();

      if (normalized == 'true') return true;
      if (normalized == 'false') return false;
    }

    if (value is num) {
      return value != 0;
    }

    return fallback;
  }

  static String _readMaxStakeMode(dynamic value) {
    final normalized = (value ?? '').toString().trim();

    if (normalized == 'fixed' || normalized == 'percent') {
      return normalized;
    }

    return 'fixed';
  }

  static String _readDisciplineMode(dynamic value) {
    final normalized = (value ?? '').toString().trim();

    if (normalized == 'warning' ||
        normalized == 'block_bet' ||
        normalized == 'lock_day') {
      return normalized;
    }

    return 'warning';
  }

  static BankrollDisciplineSnapshot calculate({
    required List<BetModel> bets,
    required List<BankrollTransaction> transactions,
    required Map<String, dynamic> userData,
    DateTime? referenceDate,
  }) {
    final now = referenceDate ?? DateTime.now();

    final startingBankroll = _readDouble(userData['startingBankroll']);
    final maxStakeMode = _readMaxStakeMode(userData['maxStakeMode']);
    final maxStakeValue = _readDouble(userData['maxStakeValue']);
    final dailyLossLimit = _readDouble(userData['dailyLossLimit']);
    final targetBankroll = _readDouble(userData['targetBankroll']);
    final disciplineMode = _readDisciplineMode(userData['disciplineMode']);

    final highConfidenceEnabled = _readBool(
      userData['highConfidenceEnabled'],
      fallback: defaultHighConfidenceEnabled,
    );

    final confidence9Multiplier = _readDouble(
      userData['confidence9Multiplier'],
      fallback: defaultConfidence9Multiplier,
    );

    final confidence10Multiplier = _readDouble(
      userData['confidence10Multiplier'],
      fallback: defaultConfidence10Multiplier,
    );

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