import 'package:bet_tracker_app/domain/statistics_calculator.dart';
import 'package:bet_tracker_app/models/bet_model.dart';
import 'package:bet_tracker_app/pages/home/widgets/home_common_widgets.dart';
import 'package:bet_tracker_app/services/bankroll_service.dart';
import 'package:bet_tracker_app/services/bet_service.dart';
import 'package:bet_tracker_app/services/reset_service.dart';
import 'package:bet_tracker_app/services/user_service.dart';
import 'package:bet_tracker_app/theme/app_design_tokens.dart';
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
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 560),
                child: Card(
                  color: AppColors.surface,
                  elevation: 0,
                  shape: AppStyles.cardShape(radius: AppRadius.lg),
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.xl),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 56,
                          height: 56,
                          decoration: BoxDecoration(
                            color: AppColors.danger.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(AppRadius.lg),
                            border: Border.all(
                              color: AppColors.danger.withOpacity(0.30),
                            ),
                          ),
                          child: const Icon(
                            Icons.error_outline,
                            color: AppColors.danger,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.md),
                        const Text(
                          'İstatistikler yüklenemedi',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        Text(
                          '${betSnapshot.error}',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: AppColors.textSecondary,
                            height: 1.4,
                          ),
                        ),
                      ],
                    ),
                  ),
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

              return StreamBuilder<List<dynamic>>(
                stream: BankrollService.getTransactions(),
                builder: (context, txSnapshot) {
                  if (txSnapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (txSnapshot.hasError) {
                    return Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 560),
                        child: Card(
                          color: AppColors.surface,
                          elevation: 0,
                          shape: AppStyles.cardShape(radius: AppRadius.lg),
                          child: Padding(
                            padding: const EdgeInsets.all(AppSpacing.xl),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  width: 56,
                                  height: 56,
                                  decoration: BoxDecoration(
                                    color: AppColors.danger.withOpacity(0.12),
                                    borderRadius: BorderRadius.circular(AppRadius.lg),
                                    border: Border.all(
                                      color: AppColors.danger.withOpacity(0.30),
                                    ),
                                  ),
                                  child: const Icon(
                                    Icons.error_outline,
                                    color: AppColors.danger,
                                  ),
                                ),
                                const SizedBox(height: AppSpacing.md),
                                const Text(
                                  'Kasa hareketleri yüklenemedi',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: AppSpacing.xs),
                                Text(
                                  '${txSnapshot.error}',
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                    color: AppColors.textSecondary,
                                    height: 1.4,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  }

                  final transactions = txSnapshot.data ?? [];

                  final overview = StatisticsCalculator.calculate(
                    bets: bets,
                    transactions: transactions.cast(),
                    userData: userData,
                  );

                  final isWide = MediaQuery.of(context).size.width > 900;

                  return Center(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(24),
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 1100),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            if (overview.dailyLossLimit > 0 &&
                                overview.todayLoss >= overview.dailyLossLimit)
                              const _WarningCard(
                                text:
                                'Bugünkü kayıp limiti aşıldı. Bugün frene basma zamanı.',
                              ),
                            if (overview.targetBankroll > 0 &&
                                overview.currentBankroll >=
                                    overview.targetBankroll)
                              const _WarningCard(
                                text:
                                'Hedef kasaya ulaştın. Hedef tamam, havaya zıplamak serbest.',
                              ),
                            const SizedBox(height: 20),
                            SectionCardShell(
                              title: 'Genel Durum',
                              padding: const EdgeInsets.all(20),
                              child: GridView.count(
                                crossAxisCount: isWide ? 3 : 1,
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                mainAxisSpacing: 16,
                                crossAxisSpacing: 16,
                                childAspectRatio: 2.8,
                                children: [
                                  _StatBox(
                                    title: 'Toplam Bahis',
                                    value: '${overview.totalBets}',
                                    icon: Icons.receipt_long,
                                  ),
                                  _StatBox(
                                    title: 'Toplam Oynanan',
                                    value: '${overview.totalStake.toStringAsFixed(2)} ₺',
                                    icon: Icons.payments_outlined,
                                  ),
                                  _StatBox(
                                    title: 'Kazanma Oranı',
                                    value: '%${overview.winRate.toStringAsFixed(1)}',
                                    icon: Icons.bar_chart,
                                  ),
                                  _StatBox(
                                    title: 'ROI',
                                    value: '%${overview.roi.toStringAsFixed(1)}',
                                    valueColor: overview.roi >= 0
                                        ? const Color(0xFF22C55E)
                                        : const Color(0xFFEF4444),
                                    icon: Icons.trending_up,
                                  ),
                                  _StatBox(
                                    title: 'Beklemede',
                                    value: '${overview.pendingCount}',
                                    valueColor: const Color(0xFF94A3B8),
                                    icon: Icons.hourglass_bottom,
                                  ),
                                  _StatBox(
                                    title: 'Bugünkü Kayıp',
                                    value: '${overview.todayLoss.toStringAsFixed(2)} ₺',
                                    valueColor: overview.todayLoss > 0
                                        ? const Color(0xFFEF4444)
                                        : null,
                                    icon: Icons.today,
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 20),
                            SectionCardShell(
                              title: 'Kasa Özeti',
                              padding: const EdgeInsets.all(20),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  if (isWide)
                                    Row(
                                      children: [
                                        Expanded(
                                          child: _StatBox(
                                            title: 'Başlangıç Kasası',
                                            value: '${overview.startingBankroll.toStringAsFixed(2)} ₺',
                                            icon: Icons.savings_outlined,
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: _StatBox(
                                            title: 'Net Kâr / Zarar',
                                            value: '${overview.totalProfit.toStringAsFixed(2)} ₺',
                                            valueColor: overview.totalProfit >= 0
                                                ? const Color(0xFF22C55E)
                                                : const Color(0xFFEF4444),
                                            icon: Icons.account_balance_wallet,
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: _StatBox(
                                            title: 'Kasa Hareketleri',
                                            value: '${overview.bankrollMovement.toStringAsFixed(2)} ₺',
                                            valueColor: overview.bankrollMovement >= 0
                                                ? const Color(0xFF22C55E)
                                                : const Color(0xFFEF4444),
                                            icon: Icons.swap_horiz,
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: _StatBox(
                                            title: 'Mevcut Kasa',
                                            value: '${overview.currentBankroll.toStringAsFixed(2)} ₺',
                                            valueColor: overview.currentBankroll >= overview.startingBankroll
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
                                          value: '${overview.startingBankroll.toStringAsFixed(2)} ₺',
                                          icon: Icons.savings_outlined,
                                        ),
                                        const SizedBox(height: 12),
                                        _StatBox(
                                          title: 'Net Kâr / Zarar',
                                          value: '${overview.totalProfit.toStringAsFixed(2)} ₺',
                                          valueColor: overview.totalProfit >= 0
                                              ? const Color(0xFF22C55E)
                                              : const Color(0xFFEF4444),
                                          icon: Icons.account_balance_wallet,
                                        ),
                                        const SizedBox(height: 12),
                                        _StatBox(
                                          title: 'Kasa Hareketleri',
                                          value: '${overview.bankrollMovement.toStringAsFixed(2)} ₺',
                                          valueColor: overview.bankrollMovement >= 0
                                              ? const Color(0xFF22C55E)
                                              : const Color(0xFFEF4444),
                                          icon: Icons.swap_horiz,
                                        ),
                                        const SizedBox(height: 12),
                                        _StatBox(
                                          title: 'Mevcut Kasa',
                                          value: '${overview.currentBankroll.toStringAsFixed(2)} ₺',
                                          valueColor: overview.currentBankroll >= overview.startingBankroll
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
                                        overview.startingBankroll,
                                      );
                                    },
                                    icon: const Icon(Icons.edit),
                                    label: const Text('Başlangıç Kasasını Ayarla'),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 20),
                            SectionCardShell(
                              title: 'Disiplin Ayarları',
                              padding: const EdgeInsets.all(20),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  if (isWide)
                                    Row(
                                      children: [
                                        Expanded(
                                          child: _StatBox(
                                            title: 'Maksimum Bahis',
                                            value: overview.maxStakeMode == 'percent'
                                                ? '%${overview.maxStakeValue.toStringAsFixed(1)} • ${overview.computedMaxStake.toStringAsFixed(2)} ₺'
                                                : '${overview.computedMaxStake.toStringAsFixed(2)} ₺',
                                            icon: Icons.money_off_csred_outlined,
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: _StatBox(
                                            title: 'Günlük Kayıp Limiti',
                                            value: '${overview.dailyLossLimit.toStringAsFixed(2)} ₺',
                                            icon: Icons.warning_amber_rounded,
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: _StatBox(
                                            title: 'Hedef Kasa',
                                            value: '${overview.targetBankroll.toStringAsFixed(2)} ₺',
                                            icon: Icons.flag_outlined,
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: _StatBox(
                                            title: 'Disiplin Modu',
                                            value: _disciplineModeText(
                                              overview.disciplineMode,
                                            ),
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
                                          value: overview.maxStakeMode == 'percent'
                                              ? '%${overview.maxStakeValue.toStringAsFixed(1)} • ${overview.computedMaxStake.toStringAsFixed(2)} ₺'
                                              : '${overview.computedMaxStake.toStringAsFixed(2)} ₺',
                                          icon: Icons.money_off_csred_outlined,
                                        ),
                                        const SizedBox(height: 12),
                                        _StatBox(
                                          title: 'Günlük Kayıp Limiti',
                                          value: '${overview.dailyLossLimit.toStringAsFixed(2)} ₺',
                                          icon: Icons.warning_amber_rounded,
                                        ),
                                        const SizedBox(height: 12),
                                        _StatBox(
                                          title: 'Hedef Kasa',
                                          value: '${overview.targetBankroll.toStringAsFixed(2)} ₺',
                                          icon: Icons.flag_outlined,
                                        ),
                                        const SizedBox(height: 12),
                                        _StatBox(
                                          title: 'Disiplin Modu',
                                          value: _disciplineModeText(
                                            overview.disciplineMode,
                                          ),
                                          icon: Icons.shield_outlined,
                                        ),
                                      ],
                                    ),
                                  const SizedBox(height: 16),
                                  ElevatedButton.icon(
                                    onPressed: () {
                                      _showDisciplineDialog(
                                        context,
                                        maxStakeMode: overview.maxStakeMode,
                                        maxStakeValue: overview.maxStakeValue,
                                        dailyLossLimit: overview.dailyLossLimit,
                                        targetBankroll: overview.targetBankroll,
                                        disciplineMode: overview.disciplineMode,
                                        highConfidenceEnabled: overview.highConfidenceEnabled,
                                        confidence9Multiplier: overview.confidence9Multiplier,
                                        confidence10Multiplier: overview.confidence10Multiplier,
                                      );
                                    },
                                    icon: const Icon(Icons.tune),
                                    label: const Text('Disiplin Ayarlarını Düzenle'),
                                  ),
                                  const SizedBox(height: 12),
                                  ElevatedButton.icon(
                                    onPressed: () {
                                      _showResetDialog(context);
                                    },
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFFDC2626),
                                    ),
                                    icon: const Icon(Icons.delete_forever),
                                    label: const Text('Tüm Verileri Sıfırla'),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 20),
                            SectionCardShell(
                              title: 'Akıllı Analiz',
                              padding: const EdgeInsets.all(20),
                              child: GridView.count(
                                crossAxisCount: isWide ? 2 : 1,
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                mainAxisSpacing: 16,
                                crossAxisSpacing: 16,
                                childAspectRatio: 3.2,
                                children: [
                                  _StatBox(
                                    title: 'En Kârlı Spor',
                                    value: overview.bestSport,
                                    icon: Icons.emoji_events_outlined,
                                    valueColor: const Color(0xFF22C55E),
                                  ),
                                  _StatBox(
                                    title: 'En Zararlı Spor',
                                    value: overview.worstSport,
                                    icon: Icons.sentiment_dissatisfied_outlined,
                                    valueColor: const Color(0xFFEF4444),
                                  ),
                                  _StatBox(
                                    title: 'En Çok Oynanan Spor',
                                    value: overview.mostPlayedSport,
                                    icon: Icons.sports_score_outlined,
                                  ),
                                  _StatBox(
                                    title: 'Beklemede Oranı',
                                    value: '%${overview.pendingRate.toStringAsFixed(1)}',
                                    icon: Icons.pending_actions_outlined,
                                    valueColor: overview.pendingRate > 0
                                        ? const Color(0xFFF59E0B)
                                        : null,
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 20),
                            SectionCardShell(
                              title: 'Seri ve Gün Analizi',
                              padding: const EdgeInsets.all(20),
                              child: GridView.count(
                                crossAxisCount: isWide ? 2 : 1,
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                mainAxisSpacing: 16,
                                crossAxisSpacing: 16,
                                childAspectRatio: 3.2,
                                children: [
                                  _StatBox(
                                    title: 'En İyi Gün',
                                    value: overview.bestDayLabel,
                                    icon: Icons.wb_sunny_outlined,
                                    valueColor: const Color(0xFF22C55E),
                                  ),
                                  _StatBox(
                                    title: 'En Kötü Gün',
                                    value: overview.worstDayLabel,
                                    icon: Icons.thunderstorm_outlined,
                                    valueColor: const Color(0xFFEF4444),
                                  ),
                                  _StatBox(
                                    title: 'En Uzun Kazanma Serisi',
                                    value: '${overview.winStreak}',
                                    icon: Icons.trending_up,
                                    valueColor: const Color(0xFF22C55E),
                                  ),
                                  _StatBox(
                                    title: 'En Uzun Kaybetme Serisi',
                                    value: '${overview.lossStreak}',
                                    icon: Icons.trending_down,
                                    valueColor: const Color(0xFFEF4444),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 20),
                            SectionCardShell(
                              title: 'Güven Analizi',
                              padding: const EdgeInsets.all(20),
                              child: GridView.count(
                                crossAxisCount: isWide ? 2 : 1,
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                mainAxisSpacing: 16,
                                crossAxisSpacing: 16,
                                childAspectRatio: 3.2,
                                children: [
                                  _StatBox(
                                    title: 'Yüksek Güven Bahis Sayısı',
                                    value: '${overview.highConfidenceBetCount}',
                                    icon: Icons.verified_outlined,
                                    valueColor: overview.highConfidenceBetCount > 0
                                        ? const Color(0xFFF59E0B)
                                        : null,
                                  ),
                                  _StatBox(
                                    title: 'Güven 9-10 Kazanma Oranı',
                                    value: '%${overview.highConfidenceWinRate.toStringAsFixed(1)}',
                                    icon: Icons.track_changes,
                                    valueColor: overview.highConfidenceWinRate >= 50
                                        ? const Color(0xFF22C55E)
                                        : const Color(0xFFEF4444),
                                  ),
                                  _StatBox(
                                    title: 'Güven 9-10 Kâr / Zarar',
                                    value: '${overview.highConfidenceProfit.toStringAsFixed(2)} ₺',
                                    icon: Icons.paid_outlined,
                                    valueColor: overview.highConfidenceProfit >= 0
                                        ? const Color(0xFF22C55E)
                                        : const Color(0xFFEF4444),
                                  ),
                                  _StatBox(
                                    title: 'En Kârlı Güven Seviyesi',
                                    value: overview.bestConfidenceLabel,
                                    icon: Icons.emoji_events_outlined,
                                    valueColor: const Color(0xFFF59E0B),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 24),
                            SectionCardShell(
                              title: 'Güven Puanına Göre Özet',
                              padding: const EdgeInsets.all(20),
                              child: overview.confidenceStats.isEmpty
                                  ? const Padding(
                                padding: EdgeInsets.all(AppSpacing.md),
                                child: Text(
                                  'Henüz güven puanı bazlı istatistik gösterecek veri yok.',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: AppColors.textSecondary,
                                    height: 1.4,
                                  ),
                                ),
                              )
                                  : Column(
                                children: (() {
                                  final entries = overview.confidenceStats.entries.toList()
                                    ..sort((a, b) => int.parse(b.key).compareTo(int.parse(a.key)));

                                  return entries.map((entry) {
                                    final score = entry.key;
                                    final data = entry.value;

                                    final count = (data['count'] as int?) ?? 0;
                                    final settled = (data['settled'] as int?) ?? 0;
                                    final won = (data['won'] as int?) ?? 0;
                                    final profit = (data['profit'] as double?) ?? 0.0;
                                    final winRate = settled == 0 ? 0.0 : (won / settled) * 100;

                                    return SummaryInsightCard(
                                      title: 'Güven $score',
                                      subtitle:
                                      'Bahis: $count | Settled: $settled | Win Rate: %${winRate.toStringAsFixed(1)}',
                                      value: '${profit.toStringAsFixed(2)} ₺',
                                      valueColor: profit >= 0
                                          ? const Color(0xFF22C55E)
                                          : const Color(0xFFEF4444),
                                    );
                                  }).toList();
                                })(),
                              ),
                            ),
                            const SizedBox(height: 24),
                            SectionCardShell(
                              title: 'Bahis Türüne Göre Özet',
                              padding: const EdgeInsets.all(20),
                              child: overview.betTypeStats.isEmpty
                                  ? const Padding(
                                padding: EdgeInsets.all(AppSpacing.md),
                                child: Text(
                                  'Henüz bahis türü bazlı istatistik gösterecek veri yok.',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: AppColors.textSecondary,
                                    height: 1.4,
                                  ),
                                ),
                              )
                                  : Column(
                                children: overview.betTypeStats.entries.map((entry) {
                                  final betType = entry.key;
                                  final data = entry.value;
                                  final typeProfit =
                                      (data['profit'] as double?) ?? 0;
                                  final typeCount =
                                      (data['count'] as int?) ?? 0;
                                  final typeWon =
                                      (data['won'] as int?) ?? 0;
                                  final typeWinRate = typeCount == 0
                                      ? 0
                                      : (typeWon / typeCount) * 100;

                                  return SummaryInsightCard(
                                    title: betType,
                                    subtitle:
                                    'Bahis: $typeCount | Kazanma Oranı: %${typeWinRate.toStringAsFixed(1)}',
                                    value: '${typeProfit.toStringAsFixed(2)} ₺',
                                    valueColor: typeProfit >= 0
                                        ? const Color(0xFF22C55E)
                                        : const Color(0xFFEF4444),
                                  );
                                }).toList(),
                              ),
                            ),
                            const SizedBox(height: 24),const SizedBox(height: 24),
                            SectionCardShell(
                              title: 'Spor Dalına Göre Özet',
                              padding: const EdgeInsets.all(20),
                              child: overview.sportStats.isEmpty
                                  ? const Padding(
                                padding: EdgeInsets.all(AppSpacing.md),
                                child: Text(
                                  'Henüz spor bazlı istatistik gösterecek veri yok.',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: AppColors.textSecondary,
                                    height: 1.4,
                                  ),
                                ),
                              )
                                  : Column(
                                children: overview.sportStats.entries.map((entry) {
                                  final sport = entry.key;
                                  final data = entry.value;
                                  final sportProfit = (data['profit'] as double?) ?? 0;
                                  final sportCount = (data['count'] as int?) ?? 0;
                                  final sportWon = (data['won'] as int?) ?? 0;
                                  final sportWinRate = sportCount == 0
                                      ? 0
                                      : (sportWon / sportCount) * 100;

                                  return SummaryInsightCard(
                                    title: sport,
                                    subtitle:
                                    'Bahis: $sportCount | Kazanma Oranı: %${sportWinRate.toStringAsFixed(1)}',
                                    value: '${sportProfit.toStringAsFixed(2)} ₺',
                                    valueColor: sportProfit >= 0
                                        ? const Color(0xFF22C55E)
                                        : const Color(0xFFEF4444),
                                  );
                                }).toList(),
                              ),
                            ),
                            const SizedBox(height: 24),
                            SectionCardShell(
                              title: 'Performans Özeti',
                              padding: const EdgeInsets.all(20),
                              child: GridView.count(
                                crossAxisCount: isWide ? 2 : 1,
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                mainAxisSpacing: 16,
                                crossAxisSpacing: 16,
                                childAspectRatio: 3.2,
                                children: [
                                  _StatBox(
                                    title: 'En Büyük Tek Kazanç',
                                    value: overview.biggestWinLabel,
                                    icon: Icons.arrow_upward,
                                    valueColor: const Color(0xFF22C55E),
                                  ),
                                  _StatBox(
                                    title: 'En Büyük Tek Kayıp',
                                    value: overview.biggestLossLabel,
                                    icon: Icons.arrow_downward,
                                    valueColor: const Color(0xFFEF4444),
                                  ),
                                  _StatBox(
                                    title: 'En Çok Oynanan Bahis Türü',
                                    value: overview.mostPlayedBetType,
                                    icon: Icons.local_fire_department_outlined,
                                  ),
                                  _Last10FormStat(
                                    formItems: overview.last10Form,
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 20),
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
              backgroundColor: AppColors.surface,
              shape: AppStyles.cardShape(radius: AppRadius.xl),
              titlePadding: const EdgeInsets.fromLTRB(
                AppSpacing.xl,
                AppSpacing.xl,
                AppSpacing.xl,
                AppSpacing.md,
              ),
              contentPadding: const EdgeInsets.fromLTRB(
                AppSpacing.xl,
                0,
                AppSpacing.xl,
                AppSpacing.lg,
              ),
              actionsPadding: const EdgeInsets.fromLTRB(
                AppSpacing.lg,
                0,
                AppSpacing.lg,
                AppSpacing.lg,
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
        required bool highConfidenceEnabled,
        required double confidence9Multiplier,
        required double confidence10Multiplier,
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
    final confidence9Controller = TextEditingController(
      text: confidence9Multiplier.toString(),
    );
    final confidence10Controller = TextEditingController(
      text: confidence10Multiplier.toString(),
    );

    String selectedMode = maxStakeMode;
    String selectedDisciplineMode = disciplineMode;
    bool selectedHighConfidenceEnabled = highConfidenceEnabled;

    showDialog(
      context: context,
      builder: (dialogContext) {
        bool isSaving = false;

        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              backgroundColor: AppColors.surface,
              shape: AppStyles.cardShape(radius: AppRadius.xl),
              titlePadding: const EdgeInsets.fromLTRB(
                AppSpacing.xl,
                AppSpacing.xl,
                AppSpacing.xl,
                AppSpacing.md,
              ),
              contentPadding: const EdgeInsets.fromLTRB(
                AppSpacing.xl,
                0,
                AppSpacing.xl,
                AppSpacing.lg,
              ),
              actionsPadding: const EdgeInsets.fromLTRB(
                AppSpacing.lg,
                0,
                AppSpacing.lg,
                AppSpacing.lg,
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
                        prefixIcon: const Icon(Icons.money_off_csred_outlined),
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
                    const SizedBox(height: 12),
                    SwitchListTile(
                      value: selectedHighConfidenceEnabled,
                      activeColor: const Color(0xFF16A34A),
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Yüksek Güven Limit Aşımı'),
                      subtitle: const Text(
                        'Açıksa güven 9 ve 10 için max bahis çarpanı uygulanır.',
                      ),
                      onChanged: (value) {
                        setState(() {
                          selectedHighConfidenceEnabled = value;
                        });
                      },
                    ),
                    if (selectedHighConfidenceEnabled) ...[
                      const SizedBox(height: 12),
                      TextField(
                        controller: confidence9Controller,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        decoration: const InputDecoration(
                          labelText: 'Güven 9 Çarpanı',
                          hintText: 'Örn: 2.0',
                          prefixIcon: Icon(Icons.filter_9_plus),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: confidence10Controller,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        decoration: const InputDecoration(
                          labelText: 'Güven 10 Çarpanı',
                          hintText: 'Örn: 3.0',
                          prefixIcon: Icon(Icons.verified_outlined),
                        ),
                      ),
                    ],
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
                      maxStakeController.text.trim().replaceAll(',', '.'),
                    ) ??
                        0;

                    final dailyLossValue = double.tryParse(
                      dailyLossController.text.trim().replaceAll(',', '.'),
                    ) ??
                        0;

                    final targetBankrollValue = double.tryParse(
                      targetBankrollController.text.trim().replaceAll(',', '.'),
                    ) ??
                        0;

                    final confidence9Value = double.tryParse(
                      confidence9Controller.text.trim().replaceAll(',', '.'),
                    ) ??
                        2.0;

                    final confidence10Value = double.tryParse(
                      confidence10Controller.text.trim().replaceAll(',', '.'),
                    ) ??
                        3.0;

                    if (selectedHighConfidenceEnabled &&
                        confidence9Value < 1) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Güven 9 çarpanı en az 1.0 olmalı.'),
                        ),
                      );
                      return;
                    }

                    if (selectedHighConfidenceEnabled &&
                        confidence10Value < confidence9Value) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'Güven 10 çarpanı, Güven 9 çarpanından küçük olamaz.',
                          ),
                        ),
                      );
                      return;
                    }

                    setState(() => isSaving = true);

                    final result =
                    await UserService.updateDisciplineSettings(
                      maxStakeMode: selectedMode,
                      maxStakeValue: maxStakeValueParsed,
                      dailyLossLimit: dailyLossValue,
                      targetBankroll: targetBankrollValue,
                      disciplineMode: selectedDisciplineMode,
                      highConfidenceEnabled: selectedHighConfidenceEnabled,
                      confidence9Multiplier: confidence9Value,
                      confidence10Multiplier: confidence10Value,
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
              backgroundColor: AppColors.surface,
              shape: AppStyles.cardShape(radius: AppRadius.xl),
              titlePadding: const EdgeInsets.fromLTRB(
                AppSpacing.xl,
                AppSpacing.xl,
                AppSpacing.xl,
                AppSpacing.md,
              ),
              contentPadding: const EdgeInsets.fromLTRB(
                AppSpacing.xl,
                0,
                AppSpacing.xl,
                AppSpacing.lg,
              ),
              actionsPadding: const EdgeInsets.fromLTRB(
                AppSpacing.lg,
                0,
                AppSpacing.lg,
                AppSpacing.lg,
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
            horizontalInterval:
            ((maxY - minY).abs() / 4).clamp(1, double.infinity),
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
                interval: spots.length <= 1
                    ? 1
                    : (spots.length / 4).ceilToDouble(),
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
    return StatValueCard(
      title: title,
      value: value,
      icon: icon,
      valueColor: valueColor,
      compact: true,
    );
  }
}

class _Last10FormStat extends StatelessWidget {
  final List<Map<String, String>> formItems;

  const _Last10FormStat({
    required this.formItems,
  });

  List<FormSequenceEntry> _buildItems() {
    return formItems.map((item) {
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

      return FormSequenceEntry(
        label: item['label'] ?? '-',
        color: color,
      );
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return FormSequenceCard(
      items: _buildItems(),
    );
  }
}