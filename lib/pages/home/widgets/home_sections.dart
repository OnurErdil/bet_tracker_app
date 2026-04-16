import 'package:bet_tracker_app/models/bet_model.dart';
import 'package:bet_tracker_app/pages/home/home_stats.dart';
import 'package:bet_tracker_app/pages/home/widgets/home_common_widgets.dart';
import 'package:flutter/material.dart';

Color _confidenceBadgeColor(int score) {
  if (score >= 10) return const Color(0xFFEA580C);
  if (score >= 9) return const Color(0xFFF59E0B);
  if (score >= 7) return const Color(0xFF16A34A);
  if (score >= 5) return const Color(0xFF0EA5E9);
  return const Color(0xFF64748B);
}

Widget _confidenceBadge(int score) {
  final color = _confidenceBadgeColor(score);

  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
    decoration: BoxDecoration(
      color: color.withOpacity(0.14),
      borderRadius: BorderRadius.circular(999),
      border: Border.all(color: color.withOpacity(0.45)),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          Icons.verified_outlined,
          size: 14,
          color: color,
        ),
        const SizedBox(width: 4),
        Text(
          'G $score',
          style: TextStyle(
            color: color,
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    ),
  );
}
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
    return Card(
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
                  stats.todayLoss > 0 ? const Color(0xFFEF4444) : null,
                  icon: Icons.trending_down,
                ),
                DashboardCard(
                  title: 'Kalan Limit',
                  value: stats.dailyLossLimit > 0
                      ? '${stats.remainingDailyLoss > 0 ? stats.remainingDailyLoss.toStringAsFixed(2) : '0.00'} ₺'
                      : 'Sınırsız',
                  valueColor: stats.isDailyLossExceeded
                      ? const Color(0xFFEF4444)
                      : const Color(0xFF22C55E),
                  icon: Icons.speed,
                ),
              ],
            ),
            if (stats.isDailyLossExceeded) ...[
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFFDC2626).withOpacity(0.12),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: const Color(0xFFDC2626).withOpacity(0.35),
                  ),
                ),
                child: Text(
                  stats.disciplineMode == 'lock_day'
                      ? 'Günlük kayıp limiti aşıldı. Gün kilitlenmiş durumda.'
                      : stats.disciplineMode == 'block_bet'
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
    return Card(
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
                      ? const Color(0xFF22C55E)
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
                      ? const Color(0xFFEF4444)
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
          ],
        ),
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
    return Card(
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
            const SizedBox(height: 6),
            const Text(
              'En sık kullandığın ekranlara buradan hızlıca geç.',
              style: TextStyle(
                color: Colors.white70,
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 14),
            Wrap(
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
          ],
        ),
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
    return Card(
      color: const Color(0xFF161A23),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
      ),
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    bet.matchName,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                _confidenceBadge(bet.confidenceScore),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              '${bet.sport} • ${bet.betType}\nOran: ${bet.odd.toStringAsFixed(2)} | Tutar: ${bet.stake.toStringAsFixed(2)} ₺',
              style: const TextStyle(color: Colors.white70),
            ),
            const SizedBox(height: 14),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                ElevatedButton(
                  onPressed: () => onQuickSettle(bet, 'kazandi'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF22C55E),
                  ),
                  child: const Text('Kazandı'),
                ),
                ElevatedButton(
                  onPressed: () => onQuickSettle(bet, 'kaybetti'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFEF4444),
                  ),
                  child: const Text('Kaybetti'),
                ),
                ElevatedButton(
                  onPressed: () => onQuickSettle(bet, 'iade'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFF59E0B),
                  ),
                  child: const Text('İade'),
                ),
                OutlinedButton(
                  onPressed: onDetail,
                  child: const Text('Detay'),
                ),
              ],
            ),
          ],
        ),
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
    return Card(
      color: const Color(0xFF161A23),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
      ),
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        onTap: onTap,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 8,
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(
                bet.matchName,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(width: 8),
            _confidenceBadge(bet.confidenceScore),
          ],
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 6),
          child: Text(
            '${bet.sport} • ${bet.betType}\nOran: ${bet.odd.toStringAsFixed(2)} | Tutar: ${bet.stake.toStringAsFixed(2)} ₺ | Sonuç: ${resultLabel(bet.result)}',
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
    );
  }
}