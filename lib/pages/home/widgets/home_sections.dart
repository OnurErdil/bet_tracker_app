import 'package:bet_tracker_app/models/bet_model.dart';
import 'package:bet_tracker_app/pages/home/home_stats.dart';
import 'package:bet_tracker_app/pages/home/widgets/home_common_widgets.dart';
import 'package:bet_tracker_app/theme/app_design_tokens.dart';
import 'package:flutter/material.dart';

class DisciplineSection extends StatelessWidget {
  final HomeStats stats;
  final bool isWide;

  const DisciplineSection({
    super.key,
    required this.stats,
    required this.isWide,
  });

  @override
  Widget build(BuildContext context) {
    return SectionCardShell(
      title: 'Disiplin Durumu',
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          GridView.count(
            crossAxisCount: isWide ? 2 : 1,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: isWide ? 3.0 : 3.2,
            children: [
              DashboardCard(
                title: 'Disiplin Modu',
                value: disciplineModeText(stats.disciplineMode),
                icon: Icons.shield_outlined,
              ),
              DashboardCard(
                title: 'Günlük Kayıp Limiti',
                value: stats.dailyLossLimit > 0
                    ? '${stats.dailyLossLimit.toStringAsFixed(2)} ₺'
                    : 'Kapalı',
                icon: Icons.warning_amber_rounded,
              ),
              DashboardCard(
                title: 'Bugünkü Kayıp',
                value: '${stats.todayLoss.toStringAsFixed(2)} ₺',
                valueColor:
                stats.todayLoss > 0 ? homeDangerColor() : null,
                icon: Icons.trending_down,
              ),
              DashboardCard(
                title: 'Kalan Limit',
                value: stats.dailyLossLimit > 0
                    ? '${stats.remainingDailyLoss > 0 ? stats.remainingDailyLoss.toStringAsFixed(2) : '0.00'} ₺'
                    : 'Sınırsız',
                valueColor: stats.isDailyLossExceeded
                    ? homeDangerColor()
                    : homeSuccessColor(),
                icon: Icons.speed,
              ),
            ],
          ),
          if (stats.isDailyLossExceeded) ...[
            const SizedBox(height: 14),
            WarningCard(
              message: stats.disciplineMode == 'lock_day'
                  ? 'Günlük kayıp limiti aşıldı. Gün kilitlenmiş durumda.'
                  : stats.disciplineMode == 'block_bet'
                  ? 'Günlük kayıp limiti aşıldı. Yeni bahisler engellenir.'
                  : 'Günlük kayıp limiti aşıldı. Şu an sadece uyarı modundasın.',
            ),
          ],
        ],
      ),
    );
  }
}
class MiniAnalysisSection extends StatelessWidget {
  final HomeStats stats;
  final bool isWide;

  const MiniAnalysisSection({
    super.key,
    required this.stats,
    required this.isWide,
  });

  @override
  Widget build(BuildContext context) {
    return SectionCardShell(
      title: 'Mini Analiz',
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: GridView.count(
        crossAxisCount: isWide ? 2 : 1,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: isWide ? 3.0 : 3.2,
        children: [
          DashboardCard(
            title: 'En Büyük Kazanç',
            value: stats.biggestWin == null
                ? '-'
                : '${stats.biggestWin!.netProfit.toStringAsFixed(2)} ₺',
            valueColor: stats.biggestWin != null &&
                stats.biggestWin!.netProfit > 0
                ? homeSuccessColor()
                : null,
            icon: Icons.arrow_upward,
          ),
          DashboardCard(
            title: 'En Büyük Kayıp',
            value: stats.biggestLoss == null
                ? '-'
                : '${stats.biggestLoss!.netProfit.toStringAsFixed(2)} ₺',
            valueColor: stats.biggestLoss != null &&
                stats.biggestLoss!.netProfit < 0
                ? homeDangerColor()
                : null,
            icon: Icons.arrow_downward,
          ),
          DashboardCard(
            title: 'En Çok Oynanan Bahis Türü',
            value: stats.mostPlayedBetTypeCount == 0
                ? '-'
                : '${stats.mostPlayedBetType} (${stats.mostPlayedBetTypeCount})',
            icon: Icons.local_fire_department_outlined,
          ),
          Last10FormCard(bets: stats.last10Bets),
        ],
      ),
    );
  }
}

class QuickActionsSection extends StatelessWidget {
  final VoidCallback onAddBet;
  final VoidCallback onBetHistory;
  final VoidCallback onStats;
  final VoidCallback onBankroll;

  const QuickActionsSection({
    super.key,
    required this.onAddBet,
    required this.onBetHistory,
    required this.onStats,
    required this.onBankroll,
  });

  @override
  Widget build(BuildContext context) {
    return SectionCardShell(
      title: 'Hızlı İşlemler',
      subtitle: 'En sık kullandığın ekranlara buradan hızlıca geç.',
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Wrap(
        spacing: 12,
        runSpacing: 12,
        children: [
          QuickActionButton(
            label: 'Bahis Ekle',
            icon: Icons.add_circle_outline,
            onTap: onAddBet,
          ),
          QuickActionButton(
            label: 'Bahis Geçmişi',
            icon: Icons.history,
            onTap: onBetHistory,
          ),
          QuickActionButton(
            label: 'İstatistikler',
            icon: Icons.bar_chart,
            onTap: onStats,
          ),
          QuickActionButton(
            label: 'Kasa Hareketleri',
            icon: Icons.account_balance_wallet,
            onTap: onBankroll,
          ),
        ],
      ),
    );
  }
}

class PendingBetCard extends StatelessWidget {
  final BetModel bet;
  final Future<void> Function(BetModel bet, String newResult) onQuickSettle;
  final VoidCallback onDetail;

  const PendingBetCard({
    super.key,
    required this.bet,
    required this.onQuickSettle,
    required this.onDetail,
  });

  @override
  Widget build(BuildContext context) {
    return BetCardShell(
      title: bet.matchName,
      confidenceScore: bet.confidenceScore,
      titleFontSize: 17,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              BetInfoChip(
                icon: Icons.sports_soccer,
                text: bet.sport,
                tone: StatusTone.info,
              ),
              BetInfoChip(
                icon: Icons.local_activity_outlined,
                text: bet.betType,
                tone: StatusTone.muted,
              ),
              BetInfoChip(
                icon: Icons.percent,
                text: 'Oran ${bet.odd.toStringAsFixed(2)}',
                tone: StatusTone.info,
              ),
              BetInfoChip(
                icon: Icons.payments_outlined,
                text: 'Tutar ${bet.stake.toStringAsFixed(2)} ₺',
                tone: StatusTone.warning,
              ),
            ],
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              StatusActionButton(
                onPressed: () => onQuickSettle(bet, 'kazandi'),
                tone: StatusTone.success,
                icon: Icons.check_circle_outline,
                label: 'Kazandı',
              ),
              StatusActionButton(
                onPressed: () => onQuickSettle(bet, 'kaybetti'),
                tone: StatusTone.danger,
                icon: Icons.cancel_outlined,
                label: 'Kaybetti',
              ),
              StatusActionButton(
                onPressed: () => onQuickSettle(bet, 'iade'),
                tone: StatusTone.warning,
                icon: Icons.reply_all_outlined,
                label: 'İade',
              ),
              SecondaryActionButton(
                onPressed: onDetail,
                icon: Icons.open_in_new_outlined,
                label: 'Detay',
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class RecentBetCard extends StatelessWidget {
  final BetModel bet;
  final VoidCallback onTap;

  const RecentBetCard({
    super.key,
    required this.bet,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final resultTone = bet.result == 'kazandi'
        ? StatusTone.success
        : bet.result == 'kaybetti'
        ? StatusTone.danger
        : bet.result == 'iade'
        ? StatusTone.warning
        : StatusTone.muted;

    final netTone =
    bet.netProfit >= 0 ? StatusTone.success : StatusTone.danger;

    return BetCardShell(
      title: bet.matchName,
      confidenceScore: bet.confidenceScore,
      onTap: onTap,
      titleFontSize: 16,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              BetInfoChip(
                icon: Icons.sports_soccer,
                text: bet.sport,
                tone: StatusTone.info,
              ),
              BetInfoChip(
                icon: Icons.local_activity_outlined,
                text: bet.betType,
                tone: StatusTone.muted,
              ),
              BetInfoChip(
                icon: Icons.percent,
                text: 'Oran ${bet.odd.toStringAsFixed(2)}',
                tone: StatusTone.info,
              ),
              BetInfoChip(
                icon: Icons.payments_outlined,
                text: 'Tutar ${bet.stake.toStringAsFixed(2)} ₺',
                tone: StatusTone.warning,
              ),
              BetInfoChip(
                icon: Icons.flag_outlined,
                text: resultLabel(bet.result),
                tone: resultTone,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Align(
            alignment: Alignment.centerRight,
            child: BetInfoChip(
              icon: bet.netProfit >= 0
                  ? Icons.trending_up
                  : Icons.trending_down,
              text: '${bet.netProfit.toStringAsFixed(2)} ₺',
              tone: netTone,
            ),
          ),
        ],
      ),
    );
  }
}