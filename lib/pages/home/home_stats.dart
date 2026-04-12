import 'package:bet_tracker_app/models/bankroll_transaction_model.dart';
import 'package:bet_tracker_app/models/bet_model.dart';
import 'package:bet_tracker_app/domain/bankroll_discipline_calculator.dart';

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
    final now = DateTime.now();

    final snapshot = BankrollDisciplineCalculator.calculate(
      bets: bets,
      transactions: transactions,
      userData: userData,
      referenceDate: now,
    );

    final totalBets = bets.length;
    final totalProfit = snapshot.totalProfit;

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

    final todayBets = bets.where((bet) {
      return bet.date.year == now.year &&
          bet.date.month == now.month &&
          bet.date.day == now.day;
    }).toList();

    final todayProfit =
    todayBets.fold<double>(0, (sum, item) => sum + item.netProfit);

    final sevenDaysAgo = DateTime(
      now.year,
      now.month,
      now.day,
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

    return HomeStats(
      bets: bets,
      pendingBets: pendingBets,
      last10Bets: last10Bets,
      totalBets: totalBets,
      totalProfit: totalProfit,
      winRate: winRate,
      todayProfit: todayProfit,
      todayLoss: snapshot.todayLoss,
      last7DaysProfit: last7DaysProfit,
      currentBankroll: snapshot.currentBankroll,
      maxPlayableAmount: snapshot.computedMaxStake,
      dailyLossLimit: snapshot.dailyLossLimit,
      remainingDailyLoss: snapshot.remainingDailyLoss,
      isDailyLossExceeded: snapshot.isDailyLossExceeded,
      disciplineMode: snapshot.disciplineMode,
      mostPlayedBetType: mostPlayedBetType,
      mostPlayedBetTypeCount: mostPlayedBetTypeCount,
      biggestWin: biggestWin,
      biggestLoss: biggestLoss,
    );
  }
}