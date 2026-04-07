import 'package:bet_tracker_app/models/bankroll_transaction_model.dart';
import 'package:bet_tracker_app/models/bet_model.dart';
import 'package:bet_tracker_app/services/bankroll_service.dart';
import 'package:bet_tracker_app/services/bet_service.dart';
import 'package:bet_tracker_app/services/reset_service.dart';
import 'package:bet_tracker_app/services/user_service.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

class StatisticsPage extends StatelessWidget {
  const StatisticsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('İstatistikler'),
      ),
      body: StreamBuilder<List<BetModel>>(
        stream: BetService.getUserBets(),
        builder: (context, betSnapshot) {
          if (betSnapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (betSnapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  'İstatistikler yüklenirken hata oluştu:\n${betSnapshot.error}',
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }

          final bets = betSnapshot.data ?? [];

          return StreamBuilder<Map<String, dynamic>?>(
            stream: UserService.getUserProfile(),
            builder: (context, userSnapshot) {
              if (userSnapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              final userData = userSnapshot.data ?? {};
              final startingBankroll =
              (userData['startingBankroll'] ?? 0).toDouble();
              final maxStakeMode =
              (userData['maxStakeMode'] ?? 'fixed').toString();
              final maxStakeValue =
              (userData['maxStakeValue'] ?? 0).toDouble();
              final dailyLossLimit =
              (userData['dailyLossLimit'] ?? 0).toDouble();
              final targetBankroll =
              (userData['targetBankroll'] ?? 0).toDouble();
              final disciplineMode =
              (userData['disciplineMode'] ?? 'warning').toString();

              return StreamBuilder<List<BankrollTransaction>>(
                stream: BankrollService.getTransactions(),
                builder: (context, txSnapshot) {
                  if (txSnapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
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

                  final transactions = txSnapshot.data ?? [];

                  double bankrollMovement = 0;
                  for (final tx in transactions) {
                    if (tx.type == 'deposit') {
                      bankrollMovement += tx.amount;
                    } else if (tx.type == 'withdraw') {
                      bankrollMovement -= tx.amount;
                    }
                  }

                  final totalBets = bets.length;
                  final wonCount =
                      bets.where((e) => e.result == 'kazandi').length;
                  final lostCount =
                      bets.where((e) => e.result == 'kaybetti').length;
                  final refundedCount =
                      bets.where((e) => e.result == 'iade').length;
                  final pendingCount =
                      bets.where((e) => e.result == 'beklemede').length;

                  final totalStake =
                  bets.fold<double>(0, (sum, item) => sum + item.stake);

                  final totalProfit =
                  bets.fold<double>(0, (sum, item) => sum + item.netProfit);

                  final settledCount = bets
                      .where((e) =>
                  e.result == 'kazandi' ||
                      e.result == 'kaybetti' ||
                      e.result == 'iade')
                      .length;

                  final winRate =
                  settledCount == 0 ? 0 : (wonCount / settledCount) * 100;

                  final roi =
                  totalStake == 0 ? 0 : (totalProfit / totalStake) * 100;

                  final currentBankroll =
                      startingBankroll + totalProfit + bankrollMovement;

                  double computedMaxStake = 0;
                  if (maxStakeMode == 'percent') {
                    computedMaxStake = currentBankroll * (maxStakeValue / 100);
                  } else {
                    computedMaxStake = maxStakeValue;
                  }

                  final today = DateTime.now();
                  double todayLoss = 0;

                  for (final bet in bets) {
                    final sameDay = bet.date.year == today.year &&
                        bet.date.month == today.month &&
                        bet.date.day == today.day;

                    if (sameDay &&
                        bet.result == 'kaybetti' &&
                        bet.netProfit < 0) {
                      todayLoss += bet.netProfit.abs();
                    }
                  }

                  final sportStats = _buildSportStats(bets);
                  final analysis = _buildAdvancedAnalysis(
                    bets: bets,
                    sportStats: sportStats,
                  );

                  final bestSport = analysis['bestSport'] as String;
                  final worstSport = analysis['worstSport'] as String;
                  final mostPlayedSport = analysis['mostPlayedSport'] as String;
                  final pendingRate = analysis['pendingRate'] as double;
                  final bestDayLabel = analysis['bestDayLabel'] as String;
                  final worstDayLabel = analysis['worstDayLabel'] as String;
                  final winStreak = analysis['winStreak'] as int;
                  final lossStreak = analysis['lossStreak'] as int;
                  final mostPlayedBetType =
                  analysis['mostPlayedBetType'] as String;
                  final biggestWinLabel = analysis['biggestWinLabel'] as String;
                  final biggestLossLabel = analysis['biggestLossLabel'] as String;
                  final last10Form =
                  analysis['last10Form'] as List<Map<String, String>>;
                  final betTypeStats =
                  analysis['betTypeStats'] as Map<String, Map<String, dynamic>>;

                  final isWide = MediaQuery.of(context).size.width > 900;

                  return Center(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(24),
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 1100),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            if (dailyLossLimit > 0 && todayLoss >= dailyLossLimit)
                              const _WarningCard(
                                text:
                                'Bugünkü kayıp limiti aşıldı. Bugün frene basma zamanı.',
                              ),
                            if (targetBankroll > 0 &&
                                currentBankroll >= targetBankroll)
                              const _WarningCard(
                                text:
                                'Hedef kasaya ulaştın. Hedef tamam, havaya zıplamak serbest.',
                              ),
                            Card(
                              color: const Color(0xFF161A23),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(20),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.stretch,
                                  children: [
                                    const Text(
                                      'Kasa Özeti',
                                      style: TextStyle(
                                        fontSize: 22,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 16),
                                    if (isWide)
                                      Row(
                                        children: [
                                          Expanded(
                                            child: _StatBox(
                                              title: 'Başlangıç Kasası',
                                              value:
                                              '${startingBankroll.toStringAsFixed(2)} ₺',
                                              icon: Icons.savings_outlined,
                                            ),
                                          ),
                                          const SizedBox(width: 12),
                                          Expanded(
                                            child: _StatBox(
                                              title: 'Net Kâr / Zarar',
                                              value:
                                              '${totalProfit.toStringAsFixed(2)} ₺',
                                              valueColor: totalProfit >= 0
                                                  ? const Color(0xFF22C55E)
                                                  : const Color(0xFFEF4444),
                                              icon: Icons.account_balance_wallet,
                                            ),
                                          ),
                                          const SizedBox(width: 12),
                                          Expanded(
                                            child: _StatBox(
                                              title: 'Kasa Hareketleri',
                                              value:
                                              '${bankrollMovement.toStringAsFixed(2)} ₺',
                                              valueColor: bankrollMovement >= 0
                                                  ? const Color(0xFF22C55E)
                                                  : const Color(0xFFEF4444),
                                              icon: Icons.swap_horiz,
                                            ),
                                          ),
                                          const SizedBox(width: 12),
                                          Expanded(
                                            child: _StatBox(
                                              title: 'Mevcut Kasa',
                                              value:
                                              '${currentBankroll.toStringAsFixed(2)} ₺',
                                              valueColor:
                                              currentBankroll >=
                                                  startingBankroll
                                                  ? const Color(0xFF22C55E)
                                                  : const Color(0xFFEF4444),
                                              icon: Icons.paid_outlined,
                                            ),
                                          ),
                                        ],
                                      )
                                    else
                                      Column(
                                        children: [
                                          _StatBox(
                                            title: 'Başlangıç Kasası',
                                            value:
                                            '${startingBankroll.toStringAsFixed(2)} ₺',
                                            icon: Icons.savings_outlined,
                                          ),
                                          const SizedBox(height: 12),
                                          _StatBox(
                                            title: 'Net Kâr / Zarar',
                                            value:
                                            '${totalProfit.toStringAsFixed(2)} ₺',
                                            valueColor: totalProfit >= 0
                                                ? const Color(0xFF22C55E)
                                                : const Color(0xFFEF4444),
                                            icon: Icons.account_balance_wallet,
                                          ),
                                          const SizedBox(height: 12),
                                          _StatBox(
                                            title: 'Kasa Hareketleri',
                                            value:
                                            '${bankrollMovement.toStringAsFixed(2)} ₺',
                                            valueColor: bankrollMovement >= 0
                                                ? const Color(0xFF22C55E)
                                                : const Color(0xFFEF4444),
                                            icon: Icons.swap_horiz,
                                          ),
                                          const SizedBox(height: 12),
                                          _StatBox(
                                            title: 'Mevcut Kasa',
                                            value:
                                            '${currentBankroll.toStringAsFixed(2)} ₺',
                                            valueColor:
                                            currentBankroll >=
                                                startingBankroll
                                                ? const Color(0xFF22C55E)
                                                : const Color(0xFFEF4444),
                                            icon: Icons.paid_outlined,
                                          ),
                                        ],
                                      ),
                                    const SizedBox(height: 16),
                                    ElevatedButton.icon(
                                      onPressed: () {
                                        _showBankrollDialog(
                                          context,
                                          startingBankroll,
                                        );
                                      },
                                      icon: const Icon(Icons.edit),
                                      label: const Text(
                                        'Başlangıç Kasasını Ayarla',
                                      ),
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
                                padding: const EdgeInsets.all(20),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.stretch,
                                  children: [
                                    const Text(
                                      'Disiplin Ayarları',
                                      style: TextStyle(
                                        fontSize: 22,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 16),
                                    if (isWide)
                                      Row(
                                        children: [
                                          Expanded(
                                            child: _StatBox(
                                              title: 'Maksimum Bahis',
                                              value: maxStakeMode == 'percent'
                                                  ? '%${maxStakeValue.toStringAsFixed(1)} • ${computedMaxStake.toStringAsFixed(2)} ₺'
                                                  : '${computedMaxStake.toStringAsFixed(2)} ₺',
                                              icon: Icons.money_off_csred_outlined,
                                            ),
                                          ),
                                          const SizedBox(width: 12),
                                          Expanded(
                                            child: _StatBox(
                                              title: 'Günlük Kayıp Limiti',
                                              value:
                                              '${dailyLossLimit.toStringAsFixed(2)} ₺',
                                              icon:
                                              Icons.warning_amber_rounded,
                                            ),
                                          ),
                                          const SizedBox(width: 12),
                                          Expanded(
                                            child: _StatBox(
                                              title: 'Hedef Kasa',
                                              value:
                                              '${targetBankroll.toStringAsFixed(2)} ₺',
                                              icon: Icons.flag_outlined,
                                            ),
                                          ),
                                          const SizedBox(width: 12),
                                          Expanded(
                                            child: _StatBox(
                                              title: 'Disiplin Modu',
                                              value:
                                              _disciplineModeText(disciplineMode),
                                              icon: Icons.shield_outlined,
                                            ),
                                          ),
                                        ],
                                      )
                                    else
                                      Column(
                                        children: [
                                          _StatBox(
                                            title: 'Maksimum Bahis',
                                            value: maxStakeMode == 'percent'
                                                ? '%${maxStakeValue.toStringAsFixed(1)} • ${computedMaxStake.toStringAsFixed(2)} ₺'
                                                : '${computedMaxStake.toStringAsFixed(2)} ₺',
                                            icon: Icons.money_off_csred_outlined,
                                          ),
                                          const SizedBox(height: 12),
                                          _StatBox(
                                            title: 'Günlük Kayıp Limiti',
                                            value:
                                            '${dailyLossLimit.toStringAsFixed(2)} ₺',
                                            icon:
                                            Icons.warning_amber_rounded,
                                          ),
                                          const SizedBox(height: 12),
                                          _StatBox(
                                            title: 'Hedef Kasa',
                                            value:
                                            '${targetBankroll.toStringAsFixed(2)} ₺',
                                            icon: Icons.flag_outlined,
                                          ),
                                          const SizedBox(height: 12),
                                          _StatBox(
                                            title: 'Disiplin Modu',
                                            value:
                                            _disciplineModeText(disciplineMode),
                                            icon: Icons.shield_outlined,
                                          ),
                                        ],
                                      ),
                                    const SizedBox(height: 16),
                                    ElevatedButton.icon(
                                      onPressed: () {
                                        _showDisciplineDialog(
                                          context,
                                          maxStakeMode: maxStakeMode,
                                          maxStakeValue: maxStakeValue,
                                          dailyLossLimit: dailyLossLimit,
                                          targetBankroll: targetBankroll,
                                          disciplineMode: disciplineMode,
                                        );
                                      },
                                      icon: const Icon(Icons.tune),
                                      label: const Text(
                                          'Disiplin Ayarlarını Düzenle'),
                                    ),
                                    const SizedBox(height: 12),
                                    ElevatedButton.icon(
                                      onPressed: () {
                                        _showResetDialog(context);
                                      },
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor:
                                        const Color(0xFFDC2626),
                                      ),
                                      icon: const Icon(Icons.delete_forever),
                                      label:
                                      const Text('Tüm Verileri Sıfırla'),
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
                                padding: const EdgeInsets.all(20),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Kâr / Zarar Grafiği',
                                      style: TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 16),
                                    ProfitChart(bets: bets),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(height: 20),
                            const Text(
                              'Akıllı Analiz',
                              style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 12),
                            GridView.count(
                              crossAxisCount: isWide ? 2 : 1,
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              mainAxisSpacing: 16,
                              crossAxisSpacing: 16,
                              childAspectRatio: 3.2,
                              children: [
                                _StatBox(
                                  title: 'En Kârlı Spor',
                                  value: bestSport,
                                  icon: Icons.emoji_events_outlined,
                                  valueColor: const Color(0xFF22C55E),
                                ),
                                _StatBox(
                                  title: 'En Zararlı Spor',
                                  value: worstSport,
                                  icon: Icons.sentiment_dissatisfied_outlined,
                                  valueColor: const Color(0xFFEF4444),
                                ),
                                _StatBox(
                                  title: 'En Çok Oynanan Spor',
                                  value: mostPlayedSport,
                                  icon: Icons.sports_score_outlined,
                                ),
                                _StatBox(
                                  title: 'Beklemede Oranı',
                                  value:
                                  '%${pendingRate.toStringAsFixed(1)}',
                                  icon: Icons.pending_actions_outlined,
                                  valueColor: pendingRate > 0
                                      ? const Color(0xFFF59E0B)
                                      : null,
                                ),
                              ],
                            ),
                            const SizedBox(height: 20),
                            const Text(
                              'Seri ve Gün Analizi',
                              style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 12),
                            GridView.count(
                              crossAxisCount: isWide ? 2 : 1,
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              mainAxisSpacing: 16,
                              crossAxisSpacing: 16,
                              childAspectRatio: 3.2,
                              children: [
                                _StatBox(
                                  title: 'En İyi Gün',
                                  value: bestDayLabel,
                                  icon: Icons.wb_sunny_outlined,
                                  valueColor: const Color(0xFF22C55E),
                                ),
                                _StatBox(
                                  title: 'En Kötü Gün',
                                  value: worstDayLabel,
                                  icon: Icons.thunderstorm_outlined,
                                  valueColor: const Color(0xFFEF4444),
                                ),
                                _StatBox(
                                  title: 'En Uzun Kazanma Serisi',
                                  value: '$winStreak',
                                  icon: Icons.trending_up,
                                  valueColor: const Color(0xFF22C55E),
                                ),
                                _StatBox(
                                  title: 'En Uzun Kaybetme Serisi',
                                  value: '$lossStreak',
                                  icon: Icons.trending_down,
                                  valueColor: const Color(0xFFEF4444),
                                ),
                              ],
                            ),
                            const SizedBox(height: 20),
                            const Text(
                              'Performans Özeti',
                              style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 12),
                            GridView.count(
                              crossAxisCount: isWide ? 2 : 1,
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              mainAxisSpacing: 16,
                              crossAxisSpacing: 16,
                              childAspectRatio: 3.2,
                              children: [
                                _StatBox(
                                  title: 'En Büyük Tek Kazanç',
                                  value: biggestWinLabel,
                                  icon: Icons.arrow_upward,
                                  valueColor: const Color(0xFF22C55E),
                                ),
                                _StatBox(
                                  title: 'En Büyük Tek Kayıp',
                                  value: biggestLossLabel,
                                  icon: Icons.arrow_downward,
                                  valueColor: const Color(0xFFEF4444),
                                ),
                                _StatBox(
                                  title: 'En Çok Oynanan Bahis Türü',
                                  value: mostPlayedBetType,
                                  icon: Icons.local_fire_department_outlined,
                                ),
                                _Last10FormStat(formItems: last10Form),
                              ],
                            ),
                            const SizedBox(height: 20),
                            GridView.count(
                              crossAxisCount: isWide ? 3 : 1,
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              mainAxisSpacing: 16,
                              crossAxisSpacing: 16,
                              childAspectRatio: 2.8,
                              children: [
                                _StatBox(
                                  title: 'Toplam Bahis',
                                  value: '$totalBets',
                                  icon: Icons.receipt_long,
                                ),
                                _StatBox(
                                  title: 'Toplam Oynanan',
                                  value: '${totalStake.toStringAsFixed(2)} ₺',
                                  icon: Icons.payments_outlined,
                                ),
                                _StatBox(
                                  title: 'Kazanma Oranı',
                                  value: '%${winRate.toStringAsFixed(1)}',
                                  icon: Icons.bar_chart,
                                ),
                                _StatBox(
                                  title: 'Kazanan',
                                  value: '$wonCount',
                                  valueColor: const Color(0xFF22C55E),
                                  icon: Icons.check_circle_outline,
                                ),
                                _StatBox(
                                  title: 'Kaybeden',
                                  value: '$lostCount',
                                  valueColor: const Color(0xFFEF4444),
                                  icon: Icons.cancel_outlined,
                                ),
                                _StatBox(
                                  title: 'Beklemede',
                                  value: '$pendingCount',
                                  valueColor: const Color(0xFF94A3B8),
                                  icon: Icons.hourglass_bottom,
                                ),
                                _StatBox(
                                  title: 'İade',
                                  value: '$refundedCount',
                                  valueColor: const Color(0xFFF59E0B),
                                  icon: Icons.reply_all_outlined,
                                ),
                                _StatBox(
                                  title: 'ROI',
                                  value: '%${roi.toStringAsFixed(1)}',
                                  valueColor: roi >= 0
                                      ? const Color(0xFF22C55E)
                                      : const Color(0xFFEF4444),
                                  icon: Icons.trending_up,
                                ),
                                _StatBox(
                                  title: 'Bugünkü Kayıp',
                                  value: '${todayLoss.toStringAsFixed(2)} ₺',
                                  valueColor: todayLoss > 0
                                      ? const Color(0xFFEF4444)
                                      : null,
                                  icon: Icons.today,
                                ),
                              ],
                            ),
                            const SizedBox(height: 24),
                            const Text(
                              'Bahis Türüne Göre Özet',
                              style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 12),
                            if (betTypeStats.isEmpty)
                              Card(
                                color: const Color(0xFF161A23),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(18),
                                ),
                                child: const Padding(
                                  padding: EdgeInsets.all(20),
                                  child: Text(
                                    'Henüz bahis türü bazlı istatistik gösterecek veri yok.',
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                              )
                            else
                              ...betTypeStats.entries.map((entry) {
                                final betType = entry.key;
                                final data = entry.value;
                                final typeProfit =
                                    (data['profit'] as double?) ?? 0;
                                final typeCount =
                                    (data['count'] as int?) ?? 0;
                                final typeWon = (data['won'] as int?) ?? 0;
                                final typeWinRate = typeCount == 0
                                    ? 0
                                    : (typeWon / typeCount) * 100;

                                return Card(
                                  color: const Color(0xFF161A23),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(18),
                                  ),
                                  margin: const EdgeInsets.only(bottom: 12),
                                  child: ListTile(
                                    contentPadding:
                                    const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 8,
                                    ),
                                    title: Text(
                                      betType,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    subtitle: Padding(
                                      padding:
                                      const EdgeInsets.only(top: 6),
                                      child: Text(
                                        'Bahis: $typeCount | Kazanma Oranı: %${typeWinRate.toStringAsFixed(1)}',
                                      ),
                                    ),
                                    trailing: Text(
                                      '${typeProfit.toStringAsFixed(2)} ₺',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: typeProfit >= 0
                                            ? const Color(0xFF22C55E)
                                            : const Color(0xFFEF4444),
                                      ),
                                    ),
                                  ),
                                );
                              }),
                            const SizedBox(height: 24),
                            const Text(
                              'Spor Dalına Göre Özet',
                              style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 12),
                            if (sportStats.isEmpty)
                              Card(
                                color: const Color(0xFF161A23),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(18),
                                ),
                                child: const Padding(
                                  padding: EdgeInsets.all(20),
                                  child: Text(
                                    'Henüz spor bazlı istatistik gösterecek veri yok.',
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                              )
                            else
                              ...sportStats.entries.map((entry) {
                                final sport = entry.key;
                                final data = entry.value;
                                final sportProfit =
                                    (data['profit'] as double?) ?? 0;
                                final sportCount =
                                    (data['count'] as int?) ?? 0;
                                final sportWon = (data['won'] as int?) ?? 0;
                                final sportWinRate = sportCount == 0
                                    ? 0
                                    : (sportWon / sportCount) * 100;

                                return Card(
                                  color: const Color(0xFF161A23),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(18),
                                  ),
                                  margin: const EdgeInsets.only(bottom: 12),
                                  child: ListTile(
                                    contentPadding:
                                    const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 8,
                                    ),
                                    title: Text(
                                      sport,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    subtitle: Padding(
                                      padding:
                                      const EdgeInsets.only(top: 6),
                                      child: Text(
                                        'Bahis: $sportCount | Kazanma Oranı: %${sportWinRate.toStringAsFixed(1)}',
                                      ),
                                    ),
                                    trailing: Text(
                                      '${sportProfit.toStringAsFixed(2)} ₺',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: sportProfit >= 0
                                            ? const Color(0xFF22C55E)
                                            : const Color(0xFFEF4444),
                                      ),
                                    ),
                                  ),
                                );
                              }),
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

      result[bet.sport]!['count'] = (result[bet.sport]!['count'] as int) + 1;

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
    final pendingRate =
    bets.isEmpty ? 0.0 : (pendingCount / bets.length) * 100;

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

      if (biggestWin == null || bet.netProfit > biggestWin.netProfit) {
        biggestWin = bet;
      }for (final bet in bets) {
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
      'biggestWinLabel':
      biggestWin == null ? '-' : '${biggestWin.netProfit.toStringAsFixed(2)} ₺',
      'biggestLossLabel':
      biggestLoss == null ? '-' : '${biggestLoss.netProfit.toStringAsFixed(2)} ₺',
      'last10Form': last10Form,
      'betTypeStats': betTypeStats,
      'betTypeStats': betTypeStats,
    };
  }

  static void _showBankrollDialog(
      BuildContext context,
      double currentBankrollValue,
      ) {
    final controller = TextEditingController(
      text: currentBankrollValue == 0 ? '' : currentBankrollValue.toString(),
    );

    showDialog(
      context: context,
      builder: (dialogContext) {
        bool isSaving = false;

        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              backgroundColor: const Color(0xFF161A23),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              title: const Text('Başlangıç Kasası'),
              content: TextField(
                controller: controller,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: const InputDecoration(
                  labelText: 'Tutar',
                  hintText: 'Örn: 5000',
                  prefixIcon: Icon(Icons.savings_outlined),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: isSaving
                      ? null
                      : () {
                    Navigator.pop(dialogContext);
                  },
                  child: const Text('İptal'),
                ),
                ElevatedButton(
                  onPressed: isSaving
                      ? null
                      : () async {
                    final amount = double.tryParse(
                      controller.text.replaceAll(',', '.'),
                    );

                    if (amount == null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Geçerli bir sayı gir.'),
                        ),
                      );
                      return;
                    }

                    setState(() => isSaving = true);

                    final result =
                    await UserService.updateStartingBankroll(amount);

                    if (!context.mounted) return;

                    setState(() => isSaving = false);

                    if (result != null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(result)),
                      );
                      return;
                    }

                    Navigator.pop(dialogContext);

                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                          'Başlangıç kasası başarıyla kaydedildi.',
                        ),
                      ),
                    );
                  },
                  child: isSaving
                      ? const SizedBox(
                    height: 18,
                    width: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                      : const Text('Kaydet'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  static void _showDisciplineDialog(
      BuildContext context, {
        required String maxStakeMode,
        required double maxStakeValue,
        required double dailyLossLimit,
        required double targetBankroll,
        required String disciplineMode,
      }) {
    final maxStakeController = TextEditingController(
      text: maxStakeValue == 0 ? '' : maxStakeValue.toString(),
    );
    final dailyLossController = TextEditingController(
      text: dailyLossLimit == 0 ? '' : dailyLossLimit.toString(),
    );
    final targetBankrollController = TextEditingController(
      text: targetBankroll == 0 ? '' : targetBankroll.toString(),
    );

    String selectedMode = maxStakeMode;
    String selectedDisciplineMode = disciplineMode;

    showDialog(
      context: context,
      builder: (dialogContext) {
        bool isSaving = false;

        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              backgroundColor: const Color(0xFF161A23),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              title: const Text('Disiplin Ayarları'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    DropdownButtonFormField<String>(
                      value: selectedMode,
                      decoration: const InputDecoration(
                        labelText: 'Maksimum Bahis Modu',
                        prefixIcon: Icon(Icons.tune),
                      ),
                      items: const [
                        DropdownMenuItem(
                          value: 'fixed',
                          child: Text('Sabit Tutar'),
                        ),
                        DropdownMenuItem(
                          value: 'percent',
                          child: Text('Kasa Yüzdesi (%)'),
                        ),
                      ],
                      onChanged: (value) {
                        setState(() {
                          selectedMode = value ?? 'fixed';
                        });
                      },
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: maxStakeController,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      decoration: InputDecoration(
                        labelText: selectedMode == 'percent'
                            ? 'Maksimum Bahis Yüzdesi'
                            : 'Maksimum Bahis',
                        hintText: selectedMode == 'percent'
                            ? 'Örn: 4 veya 5'
                            : 'Örn: 250',
                        prefixIcon:
                        const Icon(Icons.money_off_csred_outlined),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: dailyLossController,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      decoration: const InputDecoration(
                        labelText: 'Günlük Kayıp Limiti',
                        hintText: 'Örn: 500',
                        prefixIcon: Icon(Icons.warning_amber_rounded),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: targetBankrollController,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      decoration: const InputDecoration(
                        labelText: 'Hedef Kasa',
                        hintText: 'Örn: 10000',
                        prefixIcon: Icon(Icons.flag_outlined),
                      ),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      value: selectedDisciplineMode,
                      decoration: const InputDecoration(
                        labelText: 'Disiplin Modu',
                        prefixIcon: Icon(Icons.shield_outlined),
                      ),
                      items: const [
                        DropdownMenuItem(
                          value: 'warning',
                          child: Text('Sadece Uyarı'),
                        ),
                        DropdownMenuItem(
                          value: 'block_bet',
                          child: Text('Bahsi Engelle'),
                        ),
                        DropdownMenuItem(
                          value: 'lock_day',
                          child: Text('Günü Kilitle'),
                        ),
                      ],
                      onChanged: (value) {
                        setState(() {
                          selectedDisciplineMode = value ?? 'warning';
                        });
                      },
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: isSaving
                      ? null
                      : () {
                    Navigator.pop(dialogContext);
                  },
                  child: const Text('İptal'),
                ),
                ElevatedButton(
                  onPressed: isSaving
                      ? null
                      : () async {
                    final maxStakeValueParsed = double.tryParse(
                      maxStakeController.text
                          .trim()
                          .replaceAll(',', '.'),
                    ) ??
                        0;

                    final dailyLossValue = double.tryParse(
                      dailyLossController.text
                          .trim()
                          .replaceAll(',', '.'),
                    ) ??
                        0;

                    final targetBankrollValue = double.tryParse(
                      targetBankrollController.text
                          .trim()
                          .replaceAll(',', '.'),
                    ) ??
                        0;

                    setState(() => isSaving = true);

                    final result =
                    await UserService.updateDisciplineSettings(
                      maxStakeMode: selectedMode,
                      maxStakeValue: maxStakeValueParsed,
                      dailyLossLimit: dailyLossValue,
                      targetBankroll: targetBankrollValue,
                      disciplineMode: selectedDisciplineMode,
                    );

                    if (!context.mounted) return;

                    setState(() => isSaving = false);

                    if (result != null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(result)),
                      );
                      return;
                    }

                    Navigator.pop(dialogContext);

                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Disiplin ayarları kaydedildi.'),
                      ),
                    );
                  },
                  child: isSaving
                      ? const SizedBox(
                    height: 18,
                    width: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                      : const Text('Kaydet'),
                ),
              ],
            );
          },
        );
      },
    );
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

  static void _showResetDialog(BuildContext context) {
    bool isResetting = false;

    showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              backgroundColor: const Color(0xFF161A23),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              title: const Text('Tüm Verileri Sıfırla'),
              content: const Text(
                'Bu işlem tüm bahisleri, kasa hareketlerini ve başlangıç kasasını sıfırlar. Bu işlem geri alınamaz.',
              ),
              actions: [
                TextButton(
                  onPressed: isResetting
                      ? null
                      : () {
                    Navigator.pop(dialogContext);
                  },
                  child: const Text('Vazgeç'),
                ),
                ElevatedButton(
                  onPressed: isResetting
                      ? null
                      : () async {
                    setState(() => isResetting = true);

                    final result =
                    await ResetService.resetAllUserData();

                    if (!context.mounted) return;

                    setState(() => isResetting = false);

                    if (result != null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(result)),
                      );
                      return;
                    }

                    Navigator.pop(dialogContext);

                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content:
                        Text('Tüm veriler başarıyla sıfırlandı.'),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFDC2626),
                  ),
                  child: isResetting
                      ? const SizedBox(
                    height: 18,
                    width: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                      : const Text('Sıfırla'),
                ),
              ],
            );
          },
        );
      },
    );
  }
}

class ProfitChart extends StatelessWidget {
  final List<BetModel> bets;

  const ProfitChart({super.key, required this.bets});

  @override
  Widget build(BuildContext context) {
    if (bets.isEmpty) {
      return const SizedBox(
        height: 220,
        child: Center(
          child: Text('Grafik için yeterli veri yok.'),
        ),
      );
    }

    final sorted = [...bets];
    sorted.sort((a, b) => a.date.compareTo(b.date));

    double cumulative = 0;
    final spots = <FlSpot>[];
    for (int i = 0; i < sorted.length; i++) {
      cumulative += sorted[i].netProfit;
      spots.add(FlSpot(i.toDouble(), cumulative));
    }

    final minY = spots.map((e) => e.y).reduce((a, b) => a < b ? a : b);
    final maxY = spots.map((e) => e.y).reduce((a, b) => a > b ? a : b);

    return SizedBox(
      height: 240,
      child: LineChart(
        LineChartData(
          minY: minY == maxY ? minY - 1 : minY,
          maxY: minY == maxY ? maxY + 1 : maxY,
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            horizontalInterval: ((maxY - minY).abs() / 4).clamp(1, double.infinity),
          ),
          titlesData: FlTitlesData(
            topTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            rightTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 52,
                getTitlesWidget: (value, meta) {
                  return Text(
                    value.toStringAsFixed(0),
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 11,
                    ),
                  );
                },
              ),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                interval: spots.length <= 1 ? 1 : (spots.length / 4).ceilToDouble(),
                getTitlesWidget: (value, meta) {
                  final index = value.toInt();
                  if (index < 0 || index >= sorted.length) {
                    return const SizedBox.shrink();
                  }
                  final date = sorted[index].date;
                  return Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      '${date.day}/${date.month}',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 10,
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
          borderData: FlBorderData(
            show: true,
            border: Border.all(color: const Color(0xFF2A3140)),
          ),
          lineBarsData: [
            LineChartBarData(
              spots: spots,
              isCurved: true,
              color: const Color(0xFF16A34A),
              barWidth: 3,
              dotData: const FlDotData(show: false),
              belowBarData: BarAreaData(
                show: true,
                color: const Color(0xFF16A34A).withOpacity(0.15),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _WarningCard extends StatelessWidget {
  final String text;

  const _WarningCard({
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFDC2626).withOpacity(0.12),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: const Color(0xFFDC2626).withOpacity(0.35),
        ),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: Color(0xFFFCA5A5),
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

class _StatBox extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color? valueColor;

  const _StatBox({
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
              child: Icon(
                icon,
                color: const Color(0xFF16A34A),
                size: 22,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
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

class _Last10FormStat extends StatelessWidget {
  final List<Map<String, String>> formItems;

  const _Last10FormStat({
    required this.formItems,
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
                        : formItems.map((item) {
                      Color color;
                      switch (item['color']) {
                        case 'green':
                          color = const Color(0xFF22C55E);
                          break;
                        case 'red':
                          color = const Color(0xFFEF4444);
                          break;
                        case 'orange':
                          color = const Color(0xFFF59E0B);
                          break;
                        default:
                          color = const Color(0xFF94A3B8);
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
                          item['label'] ?? '-',
                          style: TextStyle(
                            color: color,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      );
                    }).toList(),
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