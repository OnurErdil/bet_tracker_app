import 'package:bet_tracker_app/models/bankroll_transaction_model.dart';
import 'package:bet_tracker_app/models/bet_model.dart';
import 'package:bet_tracker_app/pages/bankroll/bankroll_page.dart';
import 'package:bet_tracker_app/pages/bets/add_bet_page.dart';
import 'package:bet_tracker_app/pages/bets/bet_history_page.dart';
import 'package:bet_tracker_app/pages/bets/edit_bet_page.dart';
import 'package:bet_tracker_app/pages/stats/statistics_page.dart';
import 'package:bet_tracker_app/services/auth_service.dart';
import 'package:bet_tracker_app/services/bankroll_service.dart';
import 'package:bet_tracker_app/services/bet_service.dart';
import 'package:bet_tracker_app/services/user_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  Future<void> _quickSettleBet(
      BuildContext context,
      BetModel bet,
      String newResult,
      ) async {
    final result = await BetService.settleBetQuick(
      bet: bet,
      newResult: newResult,
    );

    if (!context.mounted) return;

    if (result != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result)),
      );
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Bahis sonucu güncellendi: ${_resultLabel(newResult)}'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final User? user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Ana Sayfa'),
        actions: [
          IconButton(
            icon: const Icon(Icons.account_balance_wallet),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const BankrollPage()),
              );
            },
            tooltip: 'Kasa Hareketleri',
          ),
          IconButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const StatisticsPage(),
                ),
              );
            },
            icon: const Icon(Icons.bar_chart),
            tooltip: 'İstatistikler',
          ),
          IconButton(
            onPressed: () async {
              await AuthService.logout();
            },
            icon: const Icon(Icons.logout),
            tooltip: 'Çıkış Yap',
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: const Color(0xFF16A34A),
        foregroundColor: Colors.white,
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => const AddBetPage(),
            ),
          );
        },
        icon: const Icon(Icons.add),
        label: const Text('Bahis Ekle'),
      ),
      body: StreamBuilder<List<BetModel>>(
        stream: BetService.getUserBets(),
        builder: (context, betSnapshot) {
          if (betSnapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          if (betSnapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  'Bahis verileri yüklenirken hata oluştu:\n${betSnapshot.error}',
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }

          return StreamBuilder<List<BankrollTransaction>>(
            stream: BankrollService.getTransactions(),
            builder: (context, txSnapshot) {
              if (txSnapshot.connectionState == ConnectionState.waiting) {
                return const Center(
                  child: CircularProgressIndicator(),
                );
              }

              if (txSnapshot.hasError) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text(
                      'Kasa hareketleri yüklenirken hata oluştu:\n${txSnapshot.error}',
                      textAlign: TextAlign.center,
                    ),
                  ),
                );
              }

              return StreamBuilder<Map<String, dynamic>?>(
                stream: UserService.getUserProfile(),
                builder: (context, userSnapshot) {
                  if (userSnapshot.connectionState == ConnectionState.waiting) {
                    return const Center(
                      child: CircularProgressIndicator(),
                    );
                  }

                  if (userSnapshot.hasError) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Text(
                          'Kullanıcı verileri yüklenirken hata oluştu:\n${userSnapshot.error}',
                          textAlign: TextAlign.center,
                        ),
                      ),
                    );
                  }

                  final bets = betSnapshot.data ?? [];
                  final transactions = txSnapshot.data ?? [];
                  final userData = userSnapshot.data ?? {};

                  final totalBets = bets.length;
                  final totalProfit =
                  bets.fold<double>(0, (sum, item) => sum + item.netProfit);
                  final wonCount =
                      bets.where((e) => e.result == 'kazandi').length;
                  final settledCount = bets
                      .where((e) =>
                  e.result == 'kazandi' ||
                      e.result == 'kaybetti' ||
                      e.result == 'iade')
                      .length;
                  final winRate =
                  settledCount == 0 ? 0 : ((wonCount / settledCount) * 100);

                  final pendingBets =
                  bets.where((e) => e.result == 'beklemede').toList();

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
                    final normalized =
                    DateTime(bet.date.year, bet.date.month, bet.date.day);
                    return !normalized.isBefore(sevenDaysAgo);
                  }).toList();

                  final last7DaysProfit = last7DaysBets.fold<double>(
                    0,
                        (sum, item) => sum + item.netProfit,
                  );

                  final sortedByDate = [...bets]
                    ..sort((a, b) => b.date.compareTo(a.date));
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

                  final screenWidth = MediaQuery.of(context).size.width;
                  final isWide = screenWidth > 900;

                  final startingBankroll =
                  (userData['startingBankroll'] ?? 0).toDouble();
                  final maxStakeMode =
                  (userData['maxStakeMode'] ?? 'fixed').toString();
                  final maxStakeValue =
                  (userData['maxStakeValue'] ?? 0).toDouble();
                  final dailyLossLimit =
                  (userData['dailyLossLimit'] ?? 0).toDouble();
                  final disciplineMode =
                  (userData['disciplineMode'] ?? 'warning').toString();

                  final transactionNet = transactions.fold<double>(0, (sum, tx) {
                    if (tx.type == 'deposit') {
                      return sum + tx.amount;
                    }
                    if (tx.type == 'withdraw') {
                      return sum - tx.amount;
                    }
                    return sum;
                  });

                  final currentBankroll =
                      startingBankroll + transactionNet + totalProfit;

                  double maxPlayableAmount;
                  if (maxStakeMode == 'percent') {
                    maxPlayableAmount = currentBankroll * (maxStakeValue / 100);
                  } else {
                    maxPlayableAmount = maxStakeValue;
                  }

                  final remainingDailyLoss =
                  dailyLossLimit > 0 ? (dailyLossLimit - todayLoss) : 0;
                  final isDailyLossExceeded =
                      dailyLossLimit > 0 && todayLoss >= dailyLossLimit;

                  return Center(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(24),
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 1100),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            _WelcomeHeader(
                              email: user?.email ?? 'Kullanıcı bilgisi bulunamadı',
                            ),
                            const SizedBox(height: 20),
                            GridView.count(
                              crossAxisCount: isWide ? 2 : 1,
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              mainAxisSpacing: 16,
                              crossAxisSpacing: 16,
                              childAspectRatio: isWide ? 3.0 : 3.2,
                              children: [
                                _DashboardCard(
                                  title: 'Güncel Kasa',
                                  value:
                                  '${currentBankroll.toStringAsFixed(2)} ₺',
                                  valueColor: currentBankroll >= 0
                                      ? const Color(0xFF22C55E)
                                      : const Color(0xFFEF4444),
                                  icon: Icons.account_balance_wallet,
                                ),
                                _DashboardCard(
                                  title: 'Maksimum Oynanabilir Tutar',
                                  value:
                                  '${maxPlayableAmount.toStringAsFixed(2)} ₺',
                                  valueColor: const Color(0xFFF59E0B),
                                  icon: Icons.sports_score,
                                ),
                              ],
                            ),
                            const SizedBox(height: 20),
                            Card(
                              color: const Color(0xFF161A23),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(18),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.stretch,
                                  children: [
                                    const Text(
                                      'Disiplin Durumu',
                                      style: TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 14),
                                    GridView.count(
                                      crossAxisCount: isWide ? 2 : 1,
                                      shrinkWrap: true,
                                      physics:
                                      const NeverScrollableScrollPhysics(),
                                      mainAxisSpacing: 12,
                                      crossAxisSpacing: 12,
                                      childAspectRatio: isWide ? 3.0 : 3.2,
                                      children: [
                                        _DashboardCard(
                                          title: 'Disiplin Modu',
                                          value:
                                          _disciplineModeText(disciplineMode),
                                          icon: Icons.shield_outlined,
                                        ),
                                        _DashboardCard(
                                          title: 'Günlük Kayıp Limiti',
                                          value: dailyLossLimit > 0
                                              ? '${dailyLossLimit.toStringAsFixed(2)} ₺'
                                              : 'Kapalı',
                                          icon: Icons.warning_amber_rounded,
                                        ),
                                        _DashboardCard(
                                          title: 'Bugünkü Kayıp',
                                          value:
                                          '${todayLoss.toStringAsFixed(2)} ₺',
                                          valueColor: todayLoss > 0
                                              ? const Color(0xFFEF4444)
                                              : null,
                                          icon: Icons.trending_down,
                                        ),
                                        _DashboardCard(
                                          title: 'Kalan Limit',
                                          value: dailyLossLimit > 0
                                              ? '${remainingDailyLoss > 0 ? remainingDailyLoss.toStringAsFixed(2) : '0.00'} ₺'
                                              : 'Sınırsız',
                                          valueColor: isDailyLossExceeded
                                              ? const Color(0xFFEF4444)
                                              : const Color(0xFF22C55E),
                                          icon: Icons.speed,
                                        ),
                                      ],
                                    ),
                                    if (isDailyLossExceeded) ...[
                                      const SizedBox(height: 14),
                                      Container(
                                        padding: const EdgeInsets.all(14),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFDC2626)
                                              .withOpacity(0.12),
                                          borderRadius:
                                          BorderRadius.circular(14),
                                          border: Border.all(
                                            color: const Color(0xFFDC2626)
                                                .withOpacity(0.35),
                                          ),
                                        ),
                                        child: Text(
                                          disciplineMode == 'lock_day'
                                              ? 'Günlük kayıp limiti aşıldı. Gün kilitlenmiş durumda.'
                                              : disciplineMode == 'block_bet'
                                              ? 'Günlük kayıp limiti aşıldı. Yeni bahisler engellenir.'
                                              : 'Günlük kayıp limiti aşıldı. Şu an sadece uyarı modundasın.',
                                          style: const TextStyle(
                                            color: Color(0xFFFCA5A5),
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(height: 20),
                            GridView.count(
                              crossAxisCount: isWide ? 4 : 1,
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              mainAxisSpacing: 16,
                              crossAxisSpacing: 16,
                              childAspectRatio: isWide ? 2.45 : 3.2,
                              children: [
                                _DashboardCard(
                                  title: 'Toplam Bahis',
                                  value: '$totalBets',
                                  icon: Icons.receipt_long,
                                ),
                                _DashboardCard(
                                  title: 'Toplam Kâr / Zarar',
                                  value: '${totalProfit.toStringAsFixed(2)} ₺',
                                  valueColor: totalProfit >= 0
                                      ? const Color(0xFF22C55E)
                                      : const Color(0xFFEF4444),
                                  icon: Icons.account_balance_wallet_outlined,
                                ),
                                _DashboardCard(
                                  title: 'Kazanma Oranı',
                                  value: '%${winRate.toStringAsFixed(1)}',
                                  icon: Icons.bar_chart,
                                ),
                                _DashboardCard(
                                  title: 'Bekleyen Bahis',
                                  value: '${pendingBets.length}',
                                  valueColor: pendingBets.isNotEmpty
                                      ? const Color(0xFFF59E0B)
                                      : null,
                                  icon: Icons.hourglass_bottom,
                                ),
                              ],
                            ),
                            const SizedBox(height: 20),
                            GridView.count(
                              crossAxisCount: isWide ? 2 : 1,
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              mainAxisSpacing: 16,
                              crossAxisSpacing: 16,
                              childAspectRatio: isWide ? 3.0 : 3.2,
                              children: [
                                _DashboardCard(
                                  title: 'Bugünkü Sonuç',
                                  value: '${todayProfit.toStringAsFixed(2)} ₺',
                                  valueColor: todayProfit >= 0
                                      ? const Color(0xFF22C55E)
                                      : const Color(0xFFEF4444),
                                  icon: Icons.today,
                                ),
                                _DashboardCard(
                                  title: 'Son 7 Gün',
                                  value:
                                  '${last7DaysProfit.toStringAsFixed(2)} ₺',
                                  valueColor: last7DaysProfit >= 0
                                      ? const Color(0xFF22C55E)
                                      : const Color(0xFFEF4444),
                                  icon: Icons.date_range,
                                ),
                              ],
                            ),
                            const SizedBox(height: 20),
                            Card(
                              color: const Color(0xFF161A23),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(18),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.stretch,
                                  children: [
                                    const Text(
                                      'Mini Analiz',
                                      style: TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 14),
                                    GridView.count(
                                      crossAxisCount: isWide ? 2 : 1,
                                      shrinkWrap: true,
                                      physics:
                                      const NeverScrollableScrollPhysics(),
                                      mainAxisSpacing: 12,
                                      crossAxisSpacing: 12,
                                      childAspectRatio: isWide ? 3.0 : 3.2,
                                      children: [
                                        _DashboardCard(
                                          title: 'En Büyük Kazanç',
                                          value: biggestWin == null
                                              ? '-'
                                              : '${biggestWin.netProfit.toStringAsFixed(2)} ₺',
                                          valueColor: biggestWin != null &&
                                              biggestWin.netProfit > 0
                                              ? const Color(0xFF22C55E)
                                              : null,
                                          icon: Icons.arrow_upward,
                                        ),
                                        _DashboardCard(
                                          title: 'En Büyük Kayıp',
                                          value: biggestLoss == null
                                              ? '-'
                                              : '${biggestLoss.netProfit.toStringAsFixed(2)} ₺',
                                          valueColor: biggestLoss != null &&
                                              biggestLoss.netProfit < 0
                                              ? const Color(0xFFEF4444)
                                              : null,
                                          icon: Icons.arrow_downward,
                                        ),
                                        _DashboardCard(
                                          title: 'En Çok Oynanan Bahis Türü',
                                          value: mostPlayedBetTypeCount == 0
                                              ? '-'
                                              : '$mostPlayedBetType ($mostPlayedBetTypeCount)',
                                          icon: Icons.local_fire_department_outlined,
                                        ),
                                        _Last10FormCard(bets: last10Bets),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(height: 20),
                            Card(
                              color: const Color(0xFF161A23),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(18),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.stretch,
                                  children: [
                                    const Text(
                                      'Hızlı İşlemler',
                                      style: TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 14),
                                    Wrap(
                                      spacing: 12,
                                      runSpacing: 12,
                                      children: [
                                        _QuickActionButton(
                                          label: 'Bahis Ekle',
                                          icon: Icons.add_circle_outline,
                                          onTap: () {
                                            Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                builder: (_) => const AddBetPage(),
                                              ),
                                            );
                                          },
                                        ),
                                        _QuickActionButton(
                                          label: 'Bahis Geçmişi',
                                          icon: Icons.history,
                                          onTap: () {
                                            Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                builder: (_) =>
                                                const BetHistoryPage(),
                                              ),
                                            );
                                          },
                                        ),
                                        _QuickActionButton(
                                          label: 'İstatistikler',
                                          icon: Icons.bar_chart,
                                          onTap: () {
                                            Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                builder: (_) =>
                                                const StatisticsPage(),
                                              ),
                                            );
                                          },
                                        ),
                                        _QuickActionButton(
                                          label: 'Kasa Hareketleri',
                                          icon: Icons.account_balance_wallet,
                                          onTap: () {
                                            Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                builder: (_) =>
                                                const BankrollPage(),
                                              ),
                                            );
                                          },
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(height: 24),
                            Row(
                              children: [
                                const Text(
                                  'Bekleyen Bahisler',
                                  style: TextStyle(
                                    fontSize: 22,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const Spacer(),
                                Text(
                                  '${pendingBets.length} adet',
                                  style:
                                  const TextStyle(color: Colors.white70),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            if (pendingBets.isEmpty)
                              Card(
                                color: const Color(0xFF161A23),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(18),
                                ),
                                child: const Padding(
                                  padding: EdgeInsets.all(20),
                                  child: Text(
                                    'Beklemede bahis yok. Masa temiz.',
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                              )
                            else
                              ...pendingBets.take(5).map(
                                    (bet) => Card(
                                  color: const Color(0xFF161A23),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(18),
                                  ),
                                  margin:
                                  const EdgeInsets.only(bottom: 12),
                                  child: Padding(
                                    padding: const EdgeInsets.all(16),
                                    child: Column(
                                      crossAxisAlignment:
                                      CrossAxisAlignment.stretch,
                                      children: [
                                        Text(
                                          bet.matchName,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 16,
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                        Text(
                                          '${bet.sport} • ${bet.betType}\nOran: ${bet.odd.toStringAsFixed(2)} | Tutar: ${bet.stake.toStringAsFixed(2)} ₺',
                                          style: const TextStyle(
                                            color: Colors.white70,
                                          ),
                                        ),
                                        const SizedBox(height: 14),
                                        Wrap(
                                          spacing: 8,
                                          runSpacing: 8,
                                          children: [
                                            ElevatedButton(
                                              onPressed: () {
                                                _quickSettleBet(
                                                  context,
                                                  bet,
                                                  'kazandi',
                                                );
                                              },
                                              style:
                                              ElevatedButton.styleFrom(
                                                backgroundColor:
                                                const Color(0xFF22C55E),
                                              ),
                                              child: const Text('Kazandı'),
                                            ),
                                            ElevatedButton(
                                              onPressed: () {
                                                _quickSettleBet(
                                                  context,
                                                  bet,
                                                  'kaybetti',
                                                );
                                              },
                                              style:
                                              ElevatedButton.styleFrom(
                                                backgroundColor:
                                                const Color(0xFFEF4444),
                                              ),
                                              child: const Text('Kaybetti'),
                                            ),
                                            ElevatedButton(
                                              onPressed: () {
                                                _quickSettleBet(
                                                  context,
                                                  bet,
                                                  'iade',
                                                );
                                              },
                                              style:
                                              ElevatedButton.styleFrom(
                                                backgroundColor:
                                                const Color(0xFFF59E0B),
                                              ),
                                              child: const Text('İade'),
                                            ),
                                            OutlinedButton(
                                              onPressed: () {
                                                Navigator.push(
                                                  context,
                                                  MaterialPageRoute(
                                                    builder: (_) =>
                                                        EditBetPage(
                                                          bet: bet,
                                                        ),
                                                  ),
                                                );
                                              },
                                              child: const Text('Detay'),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            const SizedBox(height: 24),
                            Row(
                              children: [
                                const Text(
                                  'Son Bahisler',
                                  style: TextStyle(
                                    fontSize: 22,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const Spacer(),
                                TextButton(
                                  onPressed: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) =>
                                        const BetHistoryPage(),
                                      ),
                                    );
                                  },
                                  child: const Text('Tümünü Gör'),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            if (bets.isEmpty)
                              Card(
                                color: const Color(0xFF161A23),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(18),
                                ),
                                child: const Padding(
                                  padding: EdgeInsets.all(20),
                                  child: Text(
                                    'Henüz kayıtlı bahis yok. Sağ alttaki butondan ilk bahsini ekleyebilirsin.',
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                              )
                            else
                              ...bets.take(5).map(
                                    (bet) => Card(
                                  color: const Color(0xFF161A23),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(18),
                                  ),
                                  margin:
                                  const EdgeInsets.only(bottom: 12),
                                  child: ListTile(
                                    onTap: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) =>
                                              EditBetPage(bet: bet),
                                        ),
                                      );
                                    },
                                    contentPadding:
                                    const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 8,
                                    ),
                                    title: Text(
                                      bet.matchName,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    subtitle: Padding(
                                      padding:
                                      const EdgeInsets.only(top: 6),
                                      child: Text(
                                        '${bet.sport} • ${bet.betType}\nOran: ${bet.odd.toStringAsFixed(2)} | Tutar: ${bet.stake.toStringAsFixed(2)} ₺ | Sonuç: ${_resultLabel(bet.result)}',
                                      ),
                                    ),
                                    trailing: Text(
                                      '${bet.netProfit.toStringAsFixed(2)} ₺',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: bet.netProfit >= 0
                                            ? const Color(0xFF22C55E)
                                            : const Color(0xFFEF4444),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }

  static String _resultLabel(String value) {
    switch (value) {
      case 'kazandi':
        return 'Kazandı';
      case 'kaybetti':
        return 'Kaybetti';
      case 'iade':
        return 'İade';
      case 'Tümü':
        return 'Tümü';
      default:
        return 'Beklemede';
    }
  }

  static String _disciplineModeText(String mode) {
    switch (mode) {
      case 'block_bet':
        return 'Bahsi Engelle';
      case 'lock_day':
        return 'Günü Kilitle';
      case 'warning':
      default:
        return 'Sadece Uyarı';
    }
  }
}

class _WelcomeHeader extends StatelessWidget {
  final String email;

  const _WelcomeHeader({
    required this.email,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      color: const Color(0xFF161A23),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const Icon(
              Icons.verified_user,
              size: 56,
              color: Color(0xFF16A34A),
            ),
            const SizedBox(height: 16),
            const Text(
              'Hoş geldin',
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              email,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 15,
              ),
            ),
            const SizedBox(height: 18),
            const Text(
              'Bugünkü tabloya bak, bekleyen bahisleri kapat, sonra keyfine bak.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 15),
            ),
          ],
        ),
      ),
    );
  }
}

class _DashboardCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color? valueColor;

  const _DashboardCard({
    required this.title,
    required this.value,
    required this.icon,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      color: const Color(0xFF161A23),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        child: Row(
          children: [
            CircleAvatar(
              radius: 20,
              backgroundColor: const Color(0xFF16A34A).withOpacity(0.15),
              child: Icon(icon, color: const Color(0xFF16A34A), size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    value,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: valueColor,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Last10FormCard extends StatelessWidget {
  final List<BetModel> bets;

  const _Last10FormCard({
    required this.bets,
  });

  @override
  Widget build(BuildContext context) {
    final formItems = bets.map((bet) {
      Color color;
      String label;

      switch (bet.result) {
        case 'kazandi':
          color = const Color(0xFF22C55E);
          label = 'W';
          break;
        case 'kaybetti':
          color = const Color(0xFFEF4444);
          label = 'L';
          break;
        case 'iade':
          color = const Color(0xFFF59E0B);
          label = 'I';
          break;
        default:
          color = const Color(0xFF94A3B8);
          label = 'B';
      }

      return Container(
        width: 28,
        height: 28,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: color.withOpacity(0.18),
          borderRadius: BorderRadius.circular(999),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: color,
            fontWeight: FontWeight.bold,
          ),
        ),
      );
    }).toList();

    return Card(
      color: const Color(0xFF161A23),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        child: Row(
          children: [
            CircleAvatar(
              radius: 20,
              backgroundColor: const Color(0xFF16A34A).withOpacity(0.15),
              child: const Icon(
                Icons.insights_outlined,
                color: Color(0xFF16A34A),
                size: 22,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Son 10 Form',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: formItems.isEmpty
                        ? [const Text('-', style: TextStyle(fontWeight: FontWeight.bold))]
                        : formItems,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _QuickActionButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;

  const _QuickActionButton({
    required this.label,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: onTap,
      style: OutlinedButton.styleFrom(
        minimumSize: const Size(180, 48),
        side: const BorderSide(color: Color(0xFF2A3140)),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
      ),
      icon: Icon(icon),
      label: Text(label),
    );
  }
}