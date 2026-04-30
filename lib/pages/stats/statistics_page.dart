import 'package:bet_tracker_app/domain/statistics_calculator.dart';
import 'package:bet_tracker_app/models/bankroll_transaction_model.dart';
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
            return ErrorStateCard(
              message:
              'İstatistikler yüklenemedi:\n${betSnapshot.error}',
            );
          }

          final bets = betSnapshot.data ?? [];

          return StreamBuilder<Map<String, dynamic>?>(
            stream: UserService.getUserProfile(),
            builder: (context, userSnapshot) {
              if (userSnapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (userSnapshot.hasError) {
                return ErrorStateCard(
                  message:
                  'Kullanıcı verileri yüklenirken hata oluştu:\n${userSnapshot.error}',
                );
              }

              final userData = userSnapshot.data ?? {};

              return StreamBuilder<List<BankrollTransaction>>(
                stream: BankrollService.getTransactions(),
                builder: (context, txSnapshot) {
                  if (txSnapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (txSnapshot.hasError) {
                    return ErrorStateCard(
                      message:
                      'Kasa hareketleri yüklenemedi:\n${txSnapshot.error}',
                    );
                  }

                  final transactions = txSnapshot.data ?? [];

                  final overview = StatisticsCalculator.calculate(
                    bets: bets,
                    transactions: transactions,
                    userData: userData,
                  );

                  final isWide = MediaQuery.of(context).size.width > 900;

                  return Center(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(AppSpacing.xl),
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 1100),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            if (overview.dailyLossLimit > 0 &&
                                overview.todayLoss >= overview.dailyLossLimit)
                              const Padding(
                                padding: EdgeInsets.only(bottom: AppSpacing.lg),
                                child: WarningCard(
                                  message:
                                  'Bugünkü kayıp limiti aşıldı. Bugün frene basma zamanı.',
                                ),
                              ),
                            if (overview.targetBankroll > 0 &&
                                overview.currentBankroll >=
                                    overview.targetBankroll)
                              const Padding(
                                padding: EdgeInsets.only(bottom: AppSpacing.lg),
                                child: WarningCard(
                                  message:
                                  'Hedef kasaya ulaştın. Hedef tamam, havaya zıplamak serbest.',
                                ),
                              ),
                            const SizedBox(height: AppSpacing.xl),
                            SectionCardShell(
                              title: 'Genel Durum',
                              padding: const EdgeInsets.all(AppSpacing.lg),
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
                                    tone: overview.roi >= 0
                                        ? StatusTone.success
                                        : StatusTone.danger,
                                    icon: Icons.trending_up,
                                  ),
                                  _StatBox(
                                    title: 'Beklemede',
                                    value: '${overview.pendingCount}',
                                    tone: StatusTone.muted,
                                    icon: Icons.hourglass_bottom,
                                  ),
                                  _StatBox(
                                    title: 'Bugünkü Kayıp',
                                    value: '${overview.todayLoss.toStringAsFixed(2)} ₺',
                                    tone: overview.todayLoss > 0
                                        ? StatusTone.danger
                                        : null,
                                    icon: Icons.today,
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: AppSpacing.xl),
                            SectionCardShell(
                              title: 'Kasa Özeti',
                              padding: const EdgeInsets.all(AppSpacing.lg),
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
                                        const SizedBox(width: AppSpacing.md),
                                        Expanded(
                                          child: _StatBox(
                                            title: 'Net Kâr / Zarar',
                                            value: '${overview.totalProfit.toStringAsFixed(2)} ₺',
                                            tone: overview.totalProfit >= 0
                                                ? StatusTone.success
                                                : StatusTone.danger,
                                            icon: Icons.account_balance_wallet,
                                          ),
                                        ),
                                        const SizedBox(width: AppSpacing.md),
                                        Expanded(
                                          child: _StatBox(
                                            title: 'Kasa Hareketleri',
                                            value: '${overview.bankrollMovement.toStringAsFixed(2)} ₺',
                                            tone: overview.bankrollMovement >= 0
                                                ? StatusTone.success
                                                : StatusTone.danger,
                                            icon: Icons.swap_horiz,
                                          ),
                                        ),
                                        const SizedBox(width: AppSpacing.md),
                                        Expanded(
                                          child: _StatBox(
                                            title: 'Mevcut Kasa',
                                            value: '${overview.currentBankroll.toStringAsFixed(2)} ₺',
                                            tone: overview.currentBankroll >= overview.startingBankroll
                                                ? StatusTone.success
                                                : StatusTone.danger,
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
                                        const SizedBox(height: AppSpacing.md),
                                        _StatBox(
                                          title: 'Net Kâr / Zarar',
                                          value: '${overview.totalProfit.toStringAsFixed(2)} ₺',
                                          tone: overview.totalProfit >= 0
                                              ? StatusTone.success
                                              : StatusTone.danger,
                                          icon: Icons.account_balance_wallet,
                                        ),
                                        const SizedBox(height: AppSpacing.md),
                                        _StatBox(
                                          title: 'Kasa Hareketleri',
                                          value: '${overview.bankrollMovement.toStringAsFixed(2)} ₺',
                                          tone: overview.bankrollMovement >= 0
                                              ? StatusTone.success
                                              : StatusTone.danger,
                                          icon: Icons.swap_horiz,
                                        ),
                                        const SizedBox(height: AppSpacing.md),
                                        _StatBox(
                                          title: 'Mevcut Kasa',
                                          value: '${overview.currentBankroll.toStringAsFixed(2)} ₺',
                                          tone: overview.currentBankroll >= overview.startingBankroll
                                              ? StatusTone.success
                                              : StatusTone.danger,
                                          icon: Icons.paid_outlined,
                                        ),
                                      ],
                                    ),
                                  const SizedBox(height: AppSpacing.lg),
                                  ElevatedButton.icon(
                                    onPressed: () {
                                      _showBankrollDialog(
                                        context,
                                        overview.startingBankroll,
                                      );
                                    },
                                    style: _primaryActionButtonStyle(),
                                    icon: const Icon(Icons.edit_outlined, size: 18),
                                    label: const Text('Başlangıç Kasasını Ayarla'),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: AppSpacing.xl),
                            SectionCardShell(
                              title: 'Disiplin Ayarları',
                              padding: const EdgeInsets.all(AppSpacing.lg),
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
                                        const SizedBox(width: AppSpacing.md),
                                        Expanded(
                                          child: _StatBox(
                                            title: 'Günlük Kayıp Limiti',
                                            value: '${overview.dailyLossLimit.toStringAsFixed(2)} ₺',
                                            icon: Icons.warning_amber_rounded,
                                          ),
                                        ),
                                        const SizedBox(width: AppSpacing.md),
                                        Expanded(
                                          child: _StatBox(
                                            title: 'Hedef Kasa',
                                            value: '${overview.targetBankroll.toStringAsFixed(2)} ₺',
                                            icon: Icons.flag_outlined,
                                          ),
                                        ),
                                        const SizedBox(width: AppSpacing.md),
                                        Expanded(
                                          child: _StatBox(
                                            title: 'Disiplin Modu',
                                            value: disciplineModeText(
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
                                        const SizedBox(height: AppSpacing.md),
                                        _StatBox(
                                          title: 'Günlük Kayıp Limiti',
                                          value: '${overview.dailyLossLimit.toStringAsFixed(2)} ₺',
                                          icon: Icons.warning_amber_rounded,
                                        ),
                                        const SizedBox(height: AppSpacing.md),
                                        _StatBox(
                                          title: 'Hedef Kasa',
                                          value: '${overview.targetBankroll.toStringAsFixed(2)} ₺',
                                          icon: Icons.flag_outlined,
                                        ),
                                        const SizedBox(height: AppSpacing.md),
                                        _StatBox(
                                          title: 'Disiplin Modu',
                                          value: disciplineModeText(
                                            overview.disciplineMode,
                                          ),
                                          icon: Icons.shield_outlined,
                                        ),
                                      ],
                                    ),
                                  const SizedBox(height: AppSpacing.lg),
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
                                    style: _primaryActionButtonStyle(),
                                    icon: const Icon(Icons.tune, size: 18),
                                    label: const Text('Disiplin Ayarlarını Düzenle'),
                                  ),
                                  const SizedBox(height: 12),
                                  ElevatedButton.icon(
                                    onPressed: () {
                                      _showResetDialog(context);
                                    },
                                    style: _dangerActionButtonStyle(),
                                    icon: const Icon(
                                      Icons.delete_forever_outlined,
                                      size: 18,
                                    ),
                                    label: const Text('Tüm Verileri Sıfırla'),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: AppSpacing.xl),
                            SectionCardShell(
                              title: 'Akıllı Analiz',
                              padding: const EdgeInsets.all(AppSpacing.lg),
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
                                    tone: StatusTone.success,
                                  ),
                                  _StatBox(
                                    title: 'En Zararlı Spor',
                                    value: overview.worstSport,
                                    icon: Icons.sentiment_dissatisfied_outlined,
                                    tone: StatusTone.danger,
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
                                    tone: overview.pendingRate > 0
                                        ? StatusTone.warning
                                        : null,
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: AppSpacing.xl),
                            SectionCardShell(
                              title: 'Seri ve Gün Analizi',
                              padding: const EdgeInsets.all(AppSpacing.lg),
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
                                    tone: StatusTone.success,
                                  ),
                                  _StatBox(
                                    title: 'En Kötü Gün',
                                    value: overview.worstDayLabel,
                                    icon: Icons.thunderstorm_outlined,
                                    tone: StatusTone.danger,
                                  ),
                                  _StatBox(
                                    title: 'En Uzun Kazanma Serisi',
                                    value: '${overview.winStreak}',
                                    icon: Icons.trending_up,
                                    tone: StatusTone.success,
                                  ),
                                  _StatBox(
                                    title: 'En Uzun Kaybetme Serisi',
                                    value: '${overview.lossStreak}',
                                    icon: Icons.trending_down,
                                    tone: StatusTone.danger,
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: AppSpacing.xl),
                            SectionCardShell(
                              title: 'Güven Analizi',
                              padding: const EdgeInsets.all(AppSpacing.lg),
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
                                    tone: overview.highConfidenceBetCount > 0
                                        ? StatusTone.warning
                                        : null,
                                  ),
                                  _StatBox(
                                    title: 'Güven 9-10 Kazanma Oranı',
                                    value: '%${overview.highConfidenceWinRate.toStringAsFixed(1)}',
                                    icon: Icons.track_changes,
                                    tone: overview.highConfidenceWinRate >= 50
                                        ? StatusTone.success
                                        : StatusTone.danger,
                                  ),
                                  _StatBox(
                                    title: 'Güven 9-10 Kâr / Zarar',
                                    value: '${overview.highConfidenceProfit.toStringAsFixed(2)} ₺',
                                    icon: Icons.paid_outlined,
                                    tone: overview.highConfidenceProfit >= 0
                                        ? StatusTone.success
                                        : StatusTone.danger,
                                  ),
                                  _StatBox(
                                    title: 'En Kârlı Güven Seviyesi',
                                    value: overview.bestConfidenceLabel,
                                    icon: Icons.emoji_events_outlined,
                                    tone: StatusTone.warning,
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: AppSpacing.xl),
                            SectionCardShell(
                              title: 'Güven Puanına Göre Özet',
                              padding: const EdgeInsets.all(AppSpacing.lg),
                              child: overview.confidenceStats.isEmpty
                                  ? const _SectionEmptyState(
                                text:
                                'Henüz güven puanı bazlı istatistik gösterecek veri yok.',
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
                                      tone: profit >= 0
                                          ? StatusTone.success
                                          : StatusTone.danger,
                                    );
                                  }).toList();
                                })(),
                              ),
                            ),
                            const SizedBox(height: AppSpacing.xl),
                            SectionCardShell(
                              title: 'Bahis Türüne Göre Özet',
                              padding: const EdgeInsets.all(AppSpacing.lg),
                              child: overview.betTypeStats.isEmpty
                                  ? const _SectionEmptyState(
                                text:
                                'Henüz bahis türü bazlı istatistik gösterecek veri yok.',
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
                                    tone: typeProfit >= 0
                                        ? StatusTone.success
                                        : StatusTone.danger,
                                  );
                                }).toList(),
                              ),
                            ),
                            const SizedBox(height: AppSpacing.xl),
                            SectionCardShell(
                              title: 'Spor Dalına Göre Özet',
                              padding: const EdgeInsets.all(AppSpacing.lg),
                              child: overview.sportStats.isEmpty
                                  ? const _SectionEmptyState(
                                text:
                                'Henüz spor bazlı istatistik gösterecek veri yok.',
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
                                    tone: sportProfit >= 0
                                        ? StatusTone.success
                                        : StatusTone.danger,
                                  );
                                }).toList(),
                              ),
                            ),
                            const SizedBox(height: AppSpacing.xl),
                            SectionCardShell(
                              title: 'Performans Özeti',
                              padding: const EdgeInsets.all(AppSpacing.lg),
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
                                    tone: StatusTone.success,
                                  ),
                                  _StatBox(
                                    title: 'En Büyük Tek Kayıp',
                                    value: overview.biggestLossLabel,
                                    icon: Icons.arrow_downward,
                                    tone: StatusTone.danger,
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
                            const SizedBox(height: AppSpacing.xl),
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

  static void _showMessage(
      BuildContext context,
      String message, {
        bool clearPrevious = false,
      }) {
    showAppSnackBar(
      context,
      message,
      clearPrevious: clearPrevious,
    );
  }

  static double? _parseDoubleInput(TextEditingController controller) {
    return double.tryParse(
      controller.text.replaceAll(',', '.'),
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
              title: const AppDialogHeader(
                icon: Icons.savings_outlined,
                title: 'Başlangıç Kasası',
                subtitle: 'Kasa başlangıç tutarını güncelle.',
              ),
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
                    final amount = _parseDoubleInput(controller);

                    if (amount == null) {
                      _showMessage(context, 'Geçerli bir sayı gir.');
                      return;
                    }

                    setState(() => isSaving = true);

                    final result =
                    await UserService.updateStartingBankroll(amount);

                    if (!context.mounted) return;

                    setState(() => isSaving = false);

                    if (result != null) {
                      _showMessage(context, result);
                      return;
                    }

                    Navigator.pop(dialogContext);

                    _showMessage(
                      context,
                      'Başlangıç kasası başarıyla kaydedildi.',
                    );
                  },
                  style: _primaryActionButtonStyle(),
                  child: isSaving
                      ? const ButtonLoadingIndicator(size: 18)
                      : const ButtonIconLabel(
                    icon: Icons.save_outlined,
                    label: 'Kaydet',
                  ),
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
            final isCompact = MediaQuery.of(context).size.width < 430;

            return AlertDialog(
                backgroundColor: AppColors.surface,
                shape: AppStyles.cardShape(radius: AppRadius.xl),
                insetPadding: EdgeInsets.symmetric(
                  horizontal: isCompact ? AppSpacing.md : 40,
                  vertical: AppSpacing.lg,
                ),
                titlePadding: EdgeInsets.fromLTRB(
                  isCompact ? AppSpacing.lg : AppSpacing.xl,
                  isCompact ? AppSpacing.lg : AppSpacing.xl,
                  isCompact ? AppSpacing.lg : AppSpacing.xl,
                  AppSpacing.sm,
                ),
                contentPadding: EdgeInsets.fromLTRB(
                  isCompact ? AppSpacing.lg : AppSpacing.xl,
                  0,
                  isCompact ? AppSpacing.lg : AppSpacing.xl,
                  isCompact ? AppSpacing.md : AppSpacing.lg,
                ),
                actionsPadding: EdgeInsets.fromLTRB(
                  isCompact ? AppSpacing.md : AppSpacing.lg,
                  0,
                  isCompact ? AppSpacing.md : AppSpacing.lg,
                  isCompact ? AppSpacing.md : AppSpacing.lg,
                ),
                title: const AppDialogHeader(
                  icon: Icons.tune,
                  title: 'Disiplin Ayarları',
                  subtitle: 'Maksimum bahis, günlük limit ve güven ayarlarını güncelle.',
                ),
                content: SingleChildScrollView(
                  clipBehavior: Clip.none,
                  child: Padding(
                    padding: const EdgeInsets.only(top: AppSpacing.sm),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                    DropdownButtonFormField<String>(
                      initialValue: selectedMode,
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
                      initialValue: selectedDisciplineMode,
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
                      activeThumbColor: AppColors.primary,
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
                        0.0;

                    final dailyLossValue = double.tryParse(
                      dailyLossController.text.trim().replaceAll(',', '.'),
                    ) ??
                        0.0;

                    final targetBankrollValue = double.tryParse(
                      targetBankrollController.text.trim().replaceAll(',', '.'),
                    ) ??
                        0.0;

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
                      _showMessage(
                        context,
                        'Güven 9 çarpanı en az 1.0 olmalı.',
                      );
                      return;
                    }

                    if (selectedHighConfidenceEnabled &&
                        confidence10Value < confidence9Value) {
                      _showMessage(
                        context,
                        'Güven 10 çarpanı, Güven 9 çarpanından küçük olamaz.',
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
                      _showMessage(context, result);
                      return;
                    }

                    Navigator.pop(dialogContext);

                    _showMessage(context, 'Disiplin ayarları kaydedildi.');
                  },
                  style: _primaryActionButtonStyle(),
                  child: isSaving
                      ? const ButtonLoadingIndicator(size: 18)
                      : const ButtonIconLabel(
                    icon: Icons.save_outlined,
                    label: 'Kaydet',
                  ),
                ),
              ],
            );
          },
        );
      },
    );
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
              title: const AppDialogHeader(
                icon: Icons.delete_forever_outlined,
                title: 'Tüm Verileri Sıfırla',
                subtitle: 'Bu işlem tüm bahis, kasa ve disiplin verilerini temizler.',
                tone: StatusTone.danger,
              ),
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
                      _showMessage(context, result);
                      return;
                    }

                    Navigator.pop(dialogContext);

                    _showMessage(
                      context,
                      'Tüm veriler başarıyla sıfırlandı.',
                    );
                  },
                  style: _dangerActionButtonStyle(),
                  child: isResetting
                      ? const ButtonLoadingIndicator(size: 18)
                      : const ButtonIconLabel(
                    icon: Icons.delete_forever_outlined,
                    label: 'Sıfırla',
                  ),
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
                      color: AppColors.textSecondary,
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
                        color: AppColors.textSecondary,
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
            border: Border.all(color: AppColors.border),
          ),
          lineBarsData: [
            LineChartBarData(
              spots: spots,
              isCurved: true,
              color: AppColors.primary,
              barWidth: 3,
              dotData: const FlDotData(show: false),
              belowBarData: BarAreaData(
                show: true,
                color: AppColors.primary.withValues(alpha: 0.15),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatBox extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final StatusTone? tone;

  const _StatBox({
    required this.title,
    required this.value,
    required this.icon,
    this.tone,
  });

  @override
  Widget build(BuildContext context) {
    return StatValueCard(
      title: title,
      value: value,
      icon: icon,
      valueColor: tone == null ? null : statusToneColor(tone!),
      iconTone: tone,
      compact: true,
    );
  }
}

ButtonStyle _actionButtonStyle(StatusTone tone) {
  return solidToneButtonStyle(
    tone: tone,
  );
}

ButtonStyle _primaryActionButtonStyle() {
  return _actionButtonStyle(StatusTone.primary);
}

ButtonStyle _dangerActionButtonStyle() {
  return _actionButtonStyle(StatusTone.danger);
}

class _SectionEmptyState extends StatelessWidget {
  final String text;

  const _SectionEmptyState({
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: const TextStyle(
          color: AppColors.textSecondary,
          height: 1.4,
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

  List<FormSequenceEntry> _buildItems() {
    return formItems.map((item) {
      final StatusTone tone;

      switch (item['color']) {
        case 'green':
          tone = StatusTone.success;
          break;
        case 'red':
          tone = StatusTone.danger;
          break;
        case 'orange':
          tone = StatusTone.warning;
          break;
        default:
          tone = StatusTone.muted;
      }

      return FormSequenceEntry(
        label: item['label'] ?? '-',
        tone: tone,
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