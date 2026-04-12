import 'package:bet_tracker_app/models/bankroll_transaction_model.dart';
import 'package:bet_tracker_app/models/bet_model.dart';
import 'package:bet_tracker_app/domain/bankroll_discipline_calculator.dart';

class StatisticsOverview {
  final double startingBankroll;
  final String maxStakeMode;
  final double maxStakeValue;
  final double dailyLossLimit;
  final double targetBankroll;
  final String disciplineMode;

  final double bankrollMovement;
  final int totalBets;
  final int wonCount;
  final int lostCount;
  final int refundedCount;
  final int pendingCount;
  final int settledCount;

  final double totalStake;
  final double totalProfit;
  final double winRate;
  final double roi;
  final double currentBankroll;
  final double computedMaxStake;
  final double todayLoss;

  final Map<String, Map<String, dynamic>> sportStats;
  final Map<String, Map<String, dynamic>> betTypeStats;

  final String bestSport;
  final String worstSport;
  final String mostPlayedSport;
  final double pendingRate;
  final String bestDayLabel;
  final String worstDayLabel;
  final int winStreak;
  final int lossStreak;
  final String mostPlayedBetType;
  final String biggestWinLabel;
  final String biggestLossLabel;
  final List<Map<String, String>> last10Form;

  const StatisticsOverview({
    required this.startingBankroll,
    required this.maxStakeMode,
    required this.maxStakeValue,
    required this.dailyLossLimit,
    required this.targetBankroll,
    required this.disciplineMode,
    required this.bankrollMovement,
    required this.totalBets,
    required this.wonCount,
    required this.lostCount,
    required this.refundedCount,
    required this.pendingCount,
    required this.settledCount,
    required this.totalStake,
    required this.totalProfit,
    required this.winRate,
    required this.roi,
    required this.currentBankroll,
    required this.computedMaxStake,
    required this.todayLoss,
    required this.sportStats,
    required this.betTypeStats,
    required this.bestSport,
    required this.worstSport,
    required this.mostPlayedSport,
    required this.pendingRate,
    required this.bestDayLabel,
    required this.worstDayLabel,
    required this.winStreak,
    required this.lossStreak,
    required this.mostPlayedBetType,
    required this.biggestWinLabel,
    required this.biggestLossLabel,
    required this.last10Form,
  });
}

class StatisticsCalculator {
  static StatisticsOverview calculate({
    required List<BetModel> bets,
    required List<BankrollTransaction> transactions,
    required Map<String, dynamic> userData,
  }) {
    final now = DateTime.now();

    final snapshot = BankrollDisciplineCalculator.calculate(
      bets: bets,
      transactions: transactions,
      userData: userData,
      referenceDate: now,
    );

    final totalBets = bets.length;
    final wonCount = bets.where((e) => e.result == 'kazandi').length;
    final lostCount = bets.where((e) => e.result == 'kaybetti').length;
    final refundedCount = bets.where((e) => e.result == 'iade').length;
    final pendingCount = bets.where((e) => e.result == 'beklemede').length;

    final totalStake = bets.fold<double>(0, (sum, item) => sum + item.stake);
    final totalProfit = snapshot.totalProfit;

    final settledCount = bets
        .where(
          (e) =>
      e.result == 'kazandi' ||
          e.result == 'kaybetti' ||
          e.result == 'iade',
    )
        .length;

    final winRate = settledCount == 0 ? 0.0 : (wonCount / settledCount) * 100;
    final roi = totalStake == 0 ? 0.0 : (totalProfit / totalStake) * 100;

    final sportStats = _buildSportStats(bets);
    final analysis = _buildAdvancedAnalysis(
      bets: bets,
      sportStats: sportStats,
    );

    return StatisticsOverview(
      startingBankroll: snapshot.startingBankroll,
      maxStakeMode: snapshot.maxStakeMode,
      maxStakeValue: snapshot.maxStakeValue,
      dailyLossLimit: snapshot.dailyLossLimit,
      targetBankroll: snapshot.targetBankroll,
      disciplineMode: snapshot.disciplineMode,
      bankrollMovement: snapshot.bankrollMovement,
      totalBets: totalBets,
      wonCount: wonCount,
      lostCount: lostCount,
      refundedCount: refundedCount,
      pendingCount: pendingCount,
      settledCount: settledCount,
      totalStake: totalStake,
      totalProfit: totalProfit,
      winRate: winRate,
      roi: roi,
      currentBankroll: snapshot.currentBankroll,
      computedMaxStake: snapshot.computedMaxStake,
      todayLoss: snapshot.todayLoss,
      sportStats: sportStats,
      betTypeStats:
      analysis['betTypeStats'] as Map<String, Map<String, dynamic>>,
      bestSport: analysis['bestSport'] as String,
      worstSport: analysis['worstSport'] as String,
      mostPlayedSport: analysis['mostPlayedSport'] as String,
      pendingRate: analysis['pendingRate'] as double,
      bestDayLabel: analysis['bestDayLabel'] as String,
      worstDayLabel: analysis['worstDayLabel'] as String,
      winStreak: analysis['winStreak'] as int,
      lossStreak: analysis['lossStreak'] as int,
      mostPlayedBetType: analysis['mostPlayedBetType'] as String,
      biggestWinLabel: analysis['biggestWinLabel'] as String,
      biggestLossLabel: analysis['biggestLossLabel'] as String,
      last10Form: analysis['last10Form'] as List<Map<String, String>>,
    );
  }

  static Map<String, Map<String, dynamic>> _buildSportStats(
      List<BetModel> bets,
      ) {
    final Map<String, Map<String, dynamic>> result = {};

    for (final bet in bets) {
      result.putIfAbsent(bet.sport, () {
        return {
          'count': 0,
          'won': 0,
          'profit': 0.0,
        };
      });

      result[bet.sport]!['count'] =
          (result[bet.sport]!['count'] as int) + 1;

      if (bet.result == 'kazandi') {
        result[bet.sport]!['won'] = (result[bet.sport]!['won'] as int) + 1;
      }

      result[bet.sport]!['profit'] =
          (result[bet.sport]!['profit'] as double) + bet.netProfit;
    }

    return result;
  }

  static Map<String, dynamic> _buildAdvancedAnalysis({
    required List<BetModel> bets,
    required Map<String, Map<String, dynamic>> sportStats,
  }) {
    if (bets.isEmpty || sportStats.isEmpty) {
      return {
        'bestSport': '-',
        'worstSport': '-',
        'mostPlayedSport': '-',
        'pendingRate': 0.0,
        'bestDayLabel': '-',
        'worstDayLabel': '-',
        'winStreak': 0,
        'lossStreak': 0,
        'mostPlayedBetType': '-',
        'biggestWinLabel': '-',
        'biggestLossLabel': '-',
        'last10Form': <Map<String, String>>[],
        'betTypeStats': <String, Map<String, dynamic>>{},
      };
    }

    String bestSport = '-';
    String worstSport = '-';
    String mostPlayedSport = '-';

    double bestProfit = double.negativeInfinity;
    double worstProfit = double.infinity;
    int mostPlayedCount = -1;

    sportStats.forEach((sport, data) {
      final profit = (data['profit'] as double?) ?? 0;
      final count = (data['count'] as int?) ?? 0;

      if (profit > bestProfit) {
        bestProfit = profit;
        bestSport = sport;
      }

      if (profit < worstProfit) {
        worstProfit = profit;
        worstSport = sport;
      }

      if (count > mostPlayedCount) {
        mostPlayedCount = count;
        mostPlayedSport = sport;
      }
    });

    final pendingCount = bets.where((e) => e.result == 'beklemede').length;
    final pendingRate = bets.isEmpty ? 0.0 : (pendingCount / bets.length) * 100;

    final dailyMap = <String, double>{};
    for (final bet in bets) {
      final key =
          '${bet.date.year}-${bet.date.month.toString().padLeft(2, '0')}-${bet.date.day.toString().padLeft(2, '0')}';
      dailyMap[key] = (dailyMap[key] ?? 0) + bet.netProfit;
    }

    String bestDayLabel = '-';
    String worstDayLabel = '-';
    double bestDayProfit = double.negativeInfinity;
    double worstDayProfit = double.infinity;

    dailyMap.forEach((day, profit) {
      if (profit > bestDayProfit) {
        bestDayProfit = profit;
        bestDayLabel = '$day (${profit.toStringAsFixed(2)} ₺)';
      }
      if (profit < worstDayProfit) {
        worstDayProfit = profit;
        worstDayLabel = '$day (${profit.toStringAsFixed(2)} ₺)';
      }
    });

    final settledBets = [...bets]..sort((a, b) => a.date.compareTo(b.date));
    int currentWinStreak = 0;
    int currentLossStreak = 0;
    int maxWinStreak = 0;
    int maxLossStreak = 0;

    for (final bet in settledBets) {
      if (bet.result == 'kazandi') {
        currentWinStreak++;
        currentLossStreak = 0;
      } else if (bet.result == 'kaybetti') {
        currentLossStreak++;
        currentWinStreak = 0;
      } else {
        currentWinStreak = 0;
        currentLossStreak = 0;
      }

      if (currentWinStreak > maxWinStreak) {
        maxWinStreak = currentWinStreak;
      }
      if (currentLossStreak > maxLossStreak) {
        maxLossStreak = currentLossStreak;
      }
    }

    final betTypeCounts = <String, int>{};
    final betTypeStats = <String, Map<String, dynamic>>{};
    BetModel? biggestWin;
    BetModel? biggestLoss;

    for (final bet in bets) {
      betTypeCounts[bet.betType] = (betTypeCounts[bet.betType] ?? 0) + 1;

      betTypeStats.putIfAbsent(bet.betType, () {
        return {
          'count': 0,
          'won': 0,
          'profit': 0.0,
        };
      });

      betTypeStats[bet.betType]!['count'] =
          (betTypeStats[bet.betType]!['count'] as int) + 1;

      betTypeStats[bet.betType]!['profit'] =
          (betTypeStats[bet.betType]!['profit'] as double) + bet.netProfit;

      if (bet.result == 'kazandi') {
        betTypeStats[bet.betType]!['won'] =
            (betTypeStats[bet.betType]!['won'] as int) + 1;
      }

      if (biggestWin == null || bet.netProfit > biggestWin.netProfit) {
        biggestWin = bet;
      }

      if (biggestLoss == null || bet.netProfit < biggestLoss.netProfit) {
        biggestLoss = bet;
      }
    }

    String mostPlayedBetType = '-';
    int maxBetTypeCount = 0;

    betTypeCounts.forEach((key, value) {
      if (value > maxBetTypeCount) {
        maxBetTypeCount = value;
        mostPlayedBetType = '$key ($value)';
      }
    });

    final last10Sorted = [...bets]..sort((a, b) => b.date.compareTo(a.date));
    final last10Form = last10Sorted.take(10).map((bet) {
      switch (bet.result) {
        case 'kazandi':
          return {'label': 'W', 'color': 'green'};
        case 'kaybetti':
          return {'label': 'L', 'color': 'red'};
        case 'iade':
          return {'label': 'I', 'color': 'orange'};
        default:
          return {'label': 'B', 'color': 'gray'};
      }
    }).toList();

    return {
      'bestSport': bestSport,
      'worstSport': worstSport,
      'mostPlayedSport': mostPlayedSport,
      'pendingRate': pendingRate,
      'bestDayLabel': bestDayLabel,
      'worstDayLabel': worstDayLabel,
      'winStreak': maxWinStreak,
      'lossStreak': maxLossStreak,
      'mostPlayedBetType': mostPlayedBetType,
      'biggestWinLabel': biggestWin == null
          ? '-'
          : '${biggestWin.netProfit.toStringAsFixed(2)} ₺',
      'biggestLossLabel': biggestLoss == null
          ? '-'
          : '${biggestLoss.netProfit.toStringAsFixed(2)} ₺',
      'last10Form': last10Form,
      'betTypeStats': betTypeStats,
    };
  }
}