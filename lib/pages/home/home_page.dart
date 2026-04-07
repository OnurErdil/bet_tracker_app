import 'package:bet_tracker_app/models/bankroll_transaction_model.dart';
import 'package:bet_tracker_app/models/bet_model.dart';
import 'package:bet_tracker_app/pages/bankroll/bankroll_page.dart';
import 'package:bet_tracker_app/pages/bets/add_bet_page.dart';
import 'package:bet_tracker_app/pages/bets/bet_history_page.dart';
import 'package:bet_tracker_app/pages/bets/edit_bet_page.dart';
import 'package:bet_tracker_app/pages/home/home_stats.dart';
import 'package:bet_tracker_app/pages/home/widgets/home_common_widgets.dart';
import 'package:bet_tracker_app/pages/home/widgets/home_sections.dart';
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
        content: Text('Bahis sonucu güncellendi: ${resultLabel(newResult)}'),
      ),
    );
  }

  void _openPage(BuildContext context, Widget page) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => page),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Ana Sayfa'),
        actions: [
          IconButton(
            icon: const Icon(Icons.account_balance_wallet),
            onPressed: () => _openPage(context, const BankrollPage()),
            tooltip: 'Kasa Hareketleri',
          ),
          IconButton(
            onPressed: () => _openPage(context, const StatisticsPage()),
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
        onPressed: () => _openPage(context, const AddBetPage()),
        icon: const Icon(Icons.add),
        label: const Text('Bahis Ekle'),
      ),
      body: HomeDataLoader(
        userEmail: user?.email ?? 'Kullanıcı bilgisi bulunamadı',
        onQuickSettle: (bet, result) => _quickSettleBet(context, bet, result),
      ),
    );
  }
}

class HomeDataLoader extends StatelessWidget {
  final String userEmail;
  final Future<void> Function(BetModel bet, String newResult) onQuickSettle;

  const HomeDataLoader({
    super.key,
    required this.userEmail,
    required this.onQuickSettle,
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<BetModel>>(
      stream: BetService.getUserBets(),
      builder: (context, betSnapshot) {
        if (betSnapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (betSnapshot.hasError) {
          return ErrorStateCard(
            message: 'Bahis verileri yüklenirken hata oluştu:\n${betSnapshot.error}',
          );
        }

        return StreamBuilder<List<BankrollTransaction>>(
          stream: BankrollService.getTransactions(),
          builder: (context, txSnapshot) {
            if (txSnapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (txSnapshot.hasError) {
              return ErrorStateCard(
                message:
                'Kasa hareketleri yüklenirken hata oluştu:\n${txSnapshot.error}',
              );
            }

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

                final stats = HomeStats.fromData(
                  bets: betSnapshot.data ?? [],
                  transactions: txSnapshot.data ?? [],
                  userData: userSnapshot.data ?? {},
                );

                return HomeContent(
                  userEmail: userEmail,
                  stats: stats,
                  onQuickSettle: onQuickSettle,
                );
              },
            );
          },
        );
      },
    );
  }
}

class HomeContent extends StatelessWidget {
  final String userEmail;
  final HomeStats stats;
  final Future<void> Function(BetModel bet, String newResult) onQuickSettle;

  const HomeContent({
    super.key,
    required this.userEmail,
    required this.stats,
    required this.onQuickSettle,
  });

  void _openPage(BuildContext context, Widget page) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => page),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.of(context).size.width > 900;

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1100),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              WelcomeHeader(email: userEmail),
              const SizedBox(height: 20),

              GridView.count(
                crossAxisCount: isWide ? 2 : 1,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: 16,
                crossAxisSpacing: 16,
                childAspectRatio: isWide ? 3.0 : 3.2,
                children: [
                  DashboardCard(
                    title: 'Güncel Kasa',
                    value: '${stats.currentBankroll.toStringAsFixed(2)} ₺',
                    valueColor: stats.currentBankroll >= 0
                        ? const Color(0xFF22C55E)
                        : const Color(0xFFEF4444),
                    icon: Icons.account_balance_wallet,
                  ),
                  DashboardCard(
                    title: 'Maksimum Oynanabilir Tutar',
                    value: '${stats.maxPlayableAmount.toStringAsFixed(2)} ₺',
                    valueColor: const Color(0xFFF59E0B),
                    icon: Icons.sports_score,
                  ),
                ],
              ),

              const SizedBox(height: 20),
              DisciplineSection(stats: stats, isWide: isWide),

              const SizedBox(height: 20),
              GridView.count(
                crossAxisCount: isWide ? 4 : 1,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: 16,
                crossAxisSpacing: 16,
                childAspectRatio: isWide ? 2.45 : 3.2,
                children: [
                  DashboardCard(
                    title: 'Toplam Bahis',
                    value: '${stats.totalBets}',
                    icon: Icons.receipt_long,
                  ),
                  DashboardCard(
                    title: 'Toplam Kâr / Zarar',
                    value: '${stats.totalProfit.toStringAsFixed(2)} ₺',
                    valueColor: stats.totalProfit >= 0
                        ? const Color(0xFF22C55E)
                        : const Color(0xFFEF4444),
                    icon: Icons.account_balance_wallet_outlined,
                  ),
                  DashboardCard(
                    title: 'Kazanma Oranı',
                    value: '%${stats.winRate.toStringAsFixed(1)}',
                    icon: Icons.bar_chart,
                  ),
                  DashboardCard(
                    title: 'Bekleyen Bahis',
                    value: '${stats.pendingBets.length}',
                    valueColor: stats.pendingBets.isNotEmpty
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
                  DashboardCard(
                    title: 'Bugünkü Sonuç',
                    value: '${stats.todayProfit.toStringAsFixed(2)} ₺',
                    valueColor: stats.todayProfit >= 0
                        ? const Color(0xFF22C55E)
                        : const Color(0xFFEF4444),
                    icon: Icons.today,
                  ),
                  DashboardCard(
                    title: 'Son 7 Gün',
                    value: '${stats.last7DaysProfit.toStringAsFixed(2)} ₺',
                    valueColor: stats.last7DaysProfit >= 0
                        ? const Color(0xFF22C55E)
                        : const Color(0xFFEF4444),
                    icon: Icons.date_range,
                  ),
                ],
              ),

              const SizedBox(height: 20),
              MiniAnalysisSection(stats: stats, isWide: isWide),

              const SizedBox(height: 20),
              QuickActionsSection(
                onAddBet: () => _openPage(context, const AddBetPage()),
                onBetHistory: () => _openPage(context, const BetHistoryPage()),
                onStats: () => _openPage(context, const StatisticsPage()),
                onBankroll: () => _openPage(context, const BankrollPage()),
              ),

              const SizedBox(height: 24),
              SectionHeader(
                title: 'Bekleyen Bahisler',
                trailing: Text(
                  '${stats.pendingBets.length} adet',
                  style: const TextStyle(color: Colors.white70),
                ),
              ),
              const SizedBox(height: 12),
              if (stats.pendingBets.isEmpty)
                const InfoCard(
                  text: 'Beklemede bahis yok. Masa temiz.',
                )
              else
                ...stats.pendingBets.take(5).map(
                      (bet) => PendingBetCard(
                    bet: bet,
                    onQuickSettle: onQuickSettle,
                    onDetail: () => _openPage(
                      context,
                      EditBetPage(bet: bet),
                    ),
                  ),
                ),

              const SizedBox(height: 24),
              SectionHeader(
                title: 'Son Bahisler',
                trailing: TextButton(
                  onPressed: () => _openPage(context, const BetHistoryPage()),
                  child: const Text('Tümünü Gör'),
                ),
              ),
              const SizedBox(height: 12),
              if (stats.bets.isEmpty)
                const InfoCard(
                  text:
                  'Henüz kayıtlı bahis yok. Sağ alttaki butondan ilk bahsini ekleyebilirsin.',
                )
              else
                ...stats.bets.take(5).map(
                      (bet) => RecentBetCard(
                    bet: bet,
                    onTap: () => _openPage(context, EditBetPage(bet: bet)),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}