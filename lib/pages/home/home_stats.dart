import 'package:bet_tracker_app/models/bankroll_transaction_model.dart';
import 'package:bet_tracker_app/models/bet_model.dart';

class HomeStats {
  final List<BetModel> bets;
  final List<BetModel> pendingBets;
  final List<BetModel> last10Bets;

  final int totalBets;
  final double totalProfit;
  final double winRate;
  final double todayProfit;
  final double todayLoss;
  final double last7DaysProfit;
  final double currentBankroll;
  final double maxPlayableAmount;
  final double dailyLossLimit;
  final double remainingDailyLoss;

  final bool isDailyLossExceeded;
  final String disciplineMode;
  final String mostPlayedBetType;
  final int mostPlayedBetTypeCount;

  final BetModel? biggestWin;
  final BetModel? biggestLoss;

  const HomeStats({
    required this.bets,
    required this.pendingBets,
    required this.last10Bets,
    required this.totalBets,
    required this.totalProfit,
    required this.winRate,
    required this.todayProfit,
    required this.todayLoss,
    required this.last7DaysProfit,
    required this.currentBankroll,
    required this.maxPlayableAmount,
    required this.dailyLossLimit,
    required this.remainingDailyLoss,
    required this.isDailyLossExceeded,
    required this.disciplineMode,
    required this.mostPlayedBetType,
    required this.mostPlayedBetTypeCount,
    required this.biggestWin,
    required this.biggestLoss,
  });

  factory HomeStats.fromData({
    required List<BetModel> bets,
    required List<BankrollTransaction> transactions,
    required Map<String, dynamic> userData,
  }) {
    final totalBets = bets.length;
    final totalProfit =
    bets.fold<double>(0, (sum, item) => sum + item.netProfit);

    final wonCount = bets.where((e) => e.result == 'kazandi').length;
    final settledCount = bets
        .where(
          (e) =>
      e.result == 'kazandi' ||
          e.result == 'kaybetti' ||
          e.result == 'iade',
    )
        .length;

    final winRate = settledCount == 0 ? 0.0 : ((wonCount / settledCount) * 100);

    final pendingBets = bets.where((e) => e.result == 'beklemede').toList();

    final today = DateTime.now();
    final todayBets = bets.where((bet) {
      return bet.date.year == today.year &&
          bet.date.month == today.month &&
          bet.date.day == today.day;
    }).toList();

    final todayProfit =
    todayBets.fold<double>(0, (sum, item) => sum + item.netProfit);

    double todayLoss = 0;
    for (final bet in todayBets) {
      if (bet.result == 'kaybetti' && bet.netProfit < 0) {
        todayLoss += bet.netProfit.abs();
      }
    }

    final sevenDaysAgo = DateTime(
      today.year,
      today.month,
      today.day,
    ).subtract(const Duration(days: 6));

    final last7DaysBets = bets.where((bet) {
      final normalized = DateTime(bet.date.year, bet.date.month, bet.date.day);
      return !normalized.isBefore(sevenDaysAgo);
    }).toList();

    final last7DaysProfit =
    last7DaysBets.fold<double>(0, (sum, item) => sum + item.netProfit);

    final sortedByDate = [...bets]..sort((a, b) => b.date.compareTo(a.date));
    final last10Bets = sortedByDate.take(10).toList();

    BetModel? biggestWin;
    BetModel? biggestLoss;
    final Map<String, int> betTypeCounts = {};

    for (final bet in bets) {
      if (biggestWin == null || bet.netProfit > biggestWin.netProfit) {
        biggestWin = bet;
      }
      if (biggestLoss == null || bet.netProfit < biggestLoss.netProfit) {
        biggestLoss = bet;
      }
      betTypeCounts[bet.betType] = (betTypeCounts[bet.betType] ?? 0) + 1;
    }

    String mostPlayedBetType = '-';
    int mostPlayedBetTypeCount = 0;

    betTypeCounts.forEach((key, value) {
      if (value > mostPlayedBetTypeCount) {
        mostPlayedBetTypeCount = value;
        mostPlayedBetType = key;
      }
    });

    final startingBankroll = (userData['startingBankroll'] ?? 0).toDouble();
    final maxStakeMode = (userData['maxStakeMode'] ?? 'fixed').toString();
    final maxStakeValue = (userData['maxStakeValue'] ?? 0).toDouble();
    final dailyLossLimit = (userData['dailyLossLimit'] ?? 0).toDouble();
    final disciplineMode = (userData['disciplineMode'] ?? 'warning').toString();

    final transactionNet = transactions.fold<double>(0, (sum, tx) {
      if (tx.type == 'deposit') return sum + tx.amount;
      if (tx.type == 'withdraw') return sum - tx.amount;
      return sum;
    });

    final currentBankroll = startingBankroll + transactionNet + totalProfit;

    final maxPlayableAmount = maxStakeMode == 'percent'
        ? currentBankroll * (maxStakeValue / 100)
        : maxStakeValue;

    final remainingDailyLoss =
    dailyLossLimit > 0 ? (dailyLossLimit - todayLoss) : 0;

    final isDailyLossExceeded =
        dailyLossLimit > 0 && todayLoss >= dailyLossLimit;

    return HomeStats(
      bets: bets,
      pendingBets: pendingBets,
      last10Bets: last10Bets,
      totalBets: totalBets,
      totalProfit: totalProfit,
      winRate: winRate,
      todayProfit: todayProfit,
      todayLoss: todayLoss,
      last7DaysProfit: last7DaysProfit,
      currentBankroll: currentBankroll,
      maxPlayableAmount: maxPlayableAmount,
      dailyLossLimit: dailyLossLimit,
      remainingDailyLoss: remainingDailyLoss,
      isDailyLossExceeded: isDailyLossExceeded,
      disciplineMode: disciplineMode,
      mostPlayedBetType: mostPlayedBetType,
      mostPlayedBetTypeCount: mostPlayedBetTypeCount,
      biggestWin: biggestWin,
      biggestLoss: biggestLoss,
    );
  }
}