import 'dart:async';
import 'package:bet_tracker_app/data/bet_form_helpers.dart';
import 'package:bet_tracker_app/models/bet_model.dart';
import 'package:bet_tracker_app/pages/bets/edit_bet_page.dart';
import 'package:bet_tracker_app/pages/home/widgets/home_common_widgets.dart';
import 'package:bet_tracker_app/services/bet_service.dart';
import 'package:bet_tracker_app/theme/app_design_tokens.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
class BetHistoryPage extends StatefulWidget {
  const BetHistoryPage({super.key});

  @override
  State<BetHistoryPage> createState() => _BetHistoryPageState();
}
class _BetHistorySummary {
  final int recordCount;
  final double totalProfit;
  final double totalStake;
  final double averageOdd;
  final int wonCount;
  final int lostCount;
  final int pendingCount;
  final int highConfidenceCount;
  final double highConfidenceProfit;
  final double averageConfidence;

  const _BetHistorySummary({
    required this.recordCount,
    required this.totalProfit,
    required this.totalStake,
    required this.averageOdd,
    required this.wonCount,
    required this.lostCount,
    required this.pendingCount,
    required this.highConfidenceCount,
    required this.highConfidenceProfit,
    required this.averageConfidence,
  });
}

class _BetHistoryViewData {
  final List<String> countryOptions;
  final List<String> leagueOptions;
  final List<BetModel> filteredBets;
  final _BetHistorySummary summary;

  const _BetHistoryViewData({
    required this.countryOptions,
    required this.leagueOptions,
    required this.filteredBets,
    required this.summary,
  });
}

class _BetHistoryPageState extends State<BetHistoryPage> {
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _minOddController = TextEditingController();
  final TextEditingController _maxOddController = TextEditingController();
  final TextEditingController _minStakeController = TextEditingController();
  final TextEditingController _maxStakeController = TextEditingController();

  Timer? _searchDebounce;
  String _searchQuery = '';
  String _selectedSport = 'Tümü';
  String _selectedCountry = 'Tümü';
  String _selectedLeague = 'Tümü';
  String _selectedResult = 'Tümü';
  String _selectedConfidence = 'Tümü';
  String _selectedQuickFilter = 'Yok';
  String _sortOption = 'Tarih (Yeni → Eski)';

  DateTime? _startDate;
  DateTime? _endDate;

  bool _showAdvancedFilters = true;

  final List<String> _sportOptions = [
    'Tümü',
    'Futbol',
    'Basketbol',
    'Tenis',
    'Voleybol',
    'Diğer',
  ];

  final List<String> _resultOptions = [
    'Tümü',
    'beklemede',
    'kazandi',
    'kaybetti',
    'iade',
  ];

  final List<String> _confidenceOptions = [
    'Tümü',
    '1',
    '2',
    '3',
    '4',
    '5',
    '6',
    '7',
    '8',
    '9',
    '10',
    '9-10',
  ];
  List<String> _countryOptions(List<BetModel> bets) {
    final countries = bets
        .where((bet) => _selectedSport == 'Tümü' || bet.sport == _selectedSport)
        .map((bet) => bet.country.trim())
        .where((country) => country.isNotEmpty)
        .toSet()
        .toList()
      ..sort();

    return ['Tümü', ...countries];
  }

  List<String> _leagueOptions(List<BetModel> bets) {
    final leagues = bets
        .where((bet) {
      final matchesSport =
          _selectedSport == 'Tümü' || bet.sport == _selectedSport;
      final matchesCountry =
          _selectedCountry == 'Tümü' || bet.country == _selectedCountry;

      return matchesSport && matchesCountry;
    })
        .map((bet) => bet.league.trim())
        .where((league) => league.isNotEmpty)
        .toSet()
        .toList()
      ..sort();

    return ['Tümü', ...leagues];
  }
  _BetHistorySummary _buildSummary(List<BetModel> filteredBets) {
    final totalProfit =
    filteredBets.fold<double>(0, (sum, item) => sum + item.netProfit);

    final totalStake =
    filteredBets.fold<double>(0, (sum, item) => sum + item.stake);

    final averageOdd = filteredBets.isEmpty
        ? 0.0
        : filteredBets.fold<double>(0, (sum, item) => sum + item.odd) /
        filteredBets.length;

    final wonCount =
        filteredBets.where((bet) => bet.result == 'kazandi').length;
    final lostCount =
        filteredBets.where((bet) => bet.result == 'kaybetti').length;
    final pendingCount =
        filteredBets.where((bet) => bet.result == 'beklemede').length;

    final highConfidenceBets =
    filteredBets.where((bet) => bet.confidenceScore >= 9).toList();

    final highConfidenceCount = highConfidenceBets.length;

    final highConfidenceProfit = highConfidenceBets.fold<double>(
      0,
          (sum, item) => sum + item.netProfit,
    );

    final averageConfidence = filteredBets.isEmpty
        ? 0.0
        : filteredBets.fold<double>(
      0,
          (sum, item) => sum + item.confidenceScore.toDouble(),
    ) /
        filteredBets.length;

    return _BetHistorySummary(
      recordCount: filteredBets.length,
      totalProfit: totalProfit,
      totalStake: totalStake,
      averageOdd: averageOdd,
      wonCount: wonCount,
      lostCount: lostCount,
      pendingCount: pendingCount,
      highConfidenceCount: highConfidenceCount,
      highConfidenceProfit: highConfidenceProfit,
      averageConfidence: averageConfidence,
    );
  }

  _BetHistoryViewData _buildViewData(List<BetModel> bets) {
    final countryOptions = _countryOptions(bets);
    final leagueOptions = _leagueOptions(bets);
    final filteredBets = _filterBets(bets);

    return _BetHistoryViewData(
      countryOptions: countryOptions,
      leagueOptions: leagueOptions,
      filteredBets: filteredBets,
      summary: _buildSummary(filteredBets),
    );
  }

  final List<String> _sortOptions = [
    'Tarih (Yeni → Eski)',
    'Tarih (Eski → Yeni)',
    'Oran (Yüksek → Düşük)',
    'Oran (Düşük → Yüksek)',
    'Tutar (Yüksek → Düşük)',
    'Tutar (Düşük → Yüksek)',
    'Net (Yüksek → Düşük)',
    'Net (Düşük → Yüksek)',
  ];

  @override
  void dispose() {
    _searchController.dispose();
    _minOddController.dispose();
    _maxOddController.dispose();
    _minStakeController.dispose();
    _maxStakeController.dispose();
    _searchDebounce?.cancel();
    super.dispose();
  }
  void _onSearchChanged(String value) {
    _searchDebounce?.cancel();

    _searchDebounce = Timer(const Duration(milliseconds: 250), () {
      if (!mounted) return;

      setState(() {
        _searchQuery = value.trim().toLowerCase();
      });
    });
  }
  List<BetModel> _filterBets(List<BetModel> bets) {
    final query = _searchQuery;

    final minOdd =
    double.tryParse(_minOddController.text.trim().replaceAll(',', '.'));
    final maxOdd =
    double.tryParse(_maxOddController.text.trim().replaceAll(',', '.'));
    final minStake =
    double.tryParse(_minStakeController.text.trim().replaceAll(',', '.'));
    final maxStake =
    double.tryParse(_maxStakeController.text.trim().replaceAll(',', '.'));

    final filtered = bets.where((bet) {
      final displayMatchName = _displayMatchName(bet).toLowerCase();
      final homeTeam = bet.resolvedHomeTeam.toLowerCase();
      final awayTeam = bet.resolvedAwayTeam.toLowerCase();

      final matchesSearch =
          query.isEmpty ||
              displayMatchName.contains(query) ||
              homeTeam.contains(query) ||
              awayTeam.contains(query) ||
              bet.betType.toLowerCase().contains(query) ||
              bet.sport.toLowerCase().contains(query) ||
              bet.country.toLowerCase().contains(query) ||
              bet.league.toLowerCase().contains(query) ||
              bet.note.toLowerCase().contains(query);

      final matchesSport =
          _selectedSport == 'Tümü' || bet.sport == _selectedSport;

      final matchesCountry =
          _selectedCountry == 'Tümü' || bet.country == _selectedCountry;

      final matchesLeague =
          _selectedLeague == 'Tümü' || bet.league == _selectedLeague;

      final matchesResult =
          _selectedResult == 'Tümü' || bet.result == _selectedResult;

      final matchesConfidence = _selectedConfidence == 'Tümü'
          ? true
          : _selectedConfidence == '9-10'
          ? bet.confidenceScore >= 9
          : bet.confidenceScore.toString() == _selectedConfidence;

      final betDateOnly = DateTime(bet.date.year, bet.date.month, bet.date.day);

      final matchesStartDate =
          _startDate == null ||
              !betDateOnly.isBefore(
                DateTime(_startDate!.year, _startDate!.month, _startDate!.day),
              );

      final matchesEndDate =
          _endDate == null ||
              !betDateOnly.isAfter(
                DateTime(_endDate!.year, _endDate!.month, _endDate!.day),
              );

      final matchesOdd =
          (minOdd == null || bet.odd >= minOdd) &&
              (maxOdd == null || bet.odd <= maxOdd);

      final matchesStake =
          (minStake == null || bet.stake >= minStake) &&
              (maxStake == null || bet.stake <= maxStake);

      return matchesSearch &&
          matchesSport &&
          matchesCountry &&
          matchesLeague &&
          matchesResult &&
          matchesConfidence &&
          matchesStartDate &&
          matchesEndDate &&
          matchesOdd &&
          matchesStake;
    }).toList();

    int compareNewestFirst(BetModel a, BetModel b) {
      final dateCompare = b.date.compareTo(a.date);
      if (dateCompare != 0) return dateCompare;
      return b.createdAt.compareTo(a.createdAt);
    }

    int compareOldestFirst(BetModel a, BetModel b) {
      final dateCompare = a.date.compareTo(b.date);
      if (dateCompare != 0) return dateCompare;
      return a.createdAt.compareTo(b.createdAt);
    }

    filtered.sort((a, b) {
      switch (_sortOption) {
        case 'Tarih (Eski → Yeni)':
          return compareOldestFirst(a, b);
        case 'Oran (Yüksek → Düşük)':
          final oddCompare = b.odd.compareTo(a.odd);
          return oddCompare != 0 ? oddCompare : compareNewestFirst(a, b);
        case 'Oran (Düşük → Yüksek)':
          final oddCompare = a.odd.compareTo(b.odd);
          return oddCompare != 0 ? oddCompare : compareNewestFirst(a, b);
        case 'Tutar (Yüksek → Düşük)':
          final stakeCompare = b.stake.compareTo(a.stake);
          return stakeCompare != 0 ? stakeCompare : compareNewestFirst(a, b);
        case 'Tutar (Düşük → Yüksek)':
          final stakeCompare = a.stake.compareTo(b.stake);
          return stakeCompare != 0 ? stakeCompare : compareNewestFirst(a, b);
        case 'Net (Yüksek → Düşük)':
          final netCompare = b.netProfit.compareTo(a.netProfit);
          return netCompare != 0 ? netCompare : compareNewestFirst(a, b);
        case 'Net (Düşük → Yüksek)':
          final netCompare = a.netProfit.compareTo(b.netProfit);
          return netCompare != 0 ? netCompare : compareNewestFirst(a, b);
        case 'Tarih (Yeni → Eski)':
        default:
          return compareNewestFirst(a, b);
      }
    });

    return filtered;
  }

  void _clearFilters() {
    _searchDebounce?.cancel();

    setState(() {
      _searchController.clear();
      _searchQuery = '';
      _minOddController.clear();
      _maxOddController.clear();
      _minStakeController.clear();
      _maxStakeController.clear();
      _selectedSport = 'Tümü';
      _selectedCountry = 'Tümü';
      _selectedLeague = 'Tümü';
      _selectedResult = 'Tümü';
      _selectedConfidence = 'Tümü';
      _selectedQuickFilter = 'Yok';
      _sortOption = 'Tarih (Yeni → Eski)';
      _startDate = null;
      _endDate = null;
    });
  }

  StatusTone _quickFilterTone(String filter) {
    switch (filter) {
      case 'Sadece Kaybedenler':
        return StatusTone.danger;
      case 'Sadece Bekleyenler':
        return StatusTone.muted;
      case 'Yüksek Güven':
        return StatusTone.highConfidence;
      case 'Bugün':
      case 'Son 7 Gün':
      case 'Bu Ay':
      default:
        return StatusTone.info;
    }
  }

  void _applyQuickFilter(String filter) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    setState(() {
      if (_selectedQuickFilter == filter) {
        _selectedQuickFilter = 'Yok';

        if (filter == 'Bugün' ||
            filter == 'Son 7 Gün' ||
            filter == 'Bu Ay') {
          _startDate = null;
          _endDate = null;
        }

        if (filter == 'Sadece Kaybedenler' ||
            filter == 'Sadece Bekleyenler') {
          _selectedResult = 'Tümü';
        }

        if (filter == 'Yüksek Güven') {
          _selectedConfidence = 'Tümü';
        }
        return;
      }

      _selectedQuickFilter = filter;

      switch (filter) {
        case 'Bugün':
          _startDate = today;
          _endDate = today;
          break;
        case 'Son 7 Gün':
          _startDate = today.subtract(const Duration(days: 6));
          _endDate = today;
          break;
        case 'Bu Ay':
          _startDate = DateTime(now.year, now.month, 1);
          _endDate = DateTime(now.year, now.month + 1, 0);
          break;
        case 'Sadece Kaybedenler':
          _selectedResult = 'kaybetti';
          break;
        case 'Sadece Bekleyenler':
          _selectedResult = 'beklemede';
          break;
        case 'Yüksek Güven':
          _selectedConfidence = '9-10';
          break;
        case 'Yok':
        default:
          break;
      }
    });
  }

  void _clearQuickFilterSelection() {
    _selectedQuickFilter = 'Yok';
  }

  void _rebuildFilters() {
    setState(() {});
  }

  StatusTone _resultTone(String value) {
    switch (value) {
      case 'kazandi':
        return StatusTone.success;
      case 'kaybetti':
        return StatusTone.danger;
      case 'iade':
        return StatusTone.warning;
      default:
        return StatusTone.muted;
    }
  }

  ButtonStyle _dangerDialogButtonStyle() {
    return ElevatedButton.styleFrom(
      backgroundColor: AppColors.danger,
      foregroundColor: Colors.white,
      minimumSize: const Size(0, 46),
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
    );
  }

  void _showMessage(
      String message, {
        bool clearPrevious = false,
      }) {
    showAppSnackBar(
      context,
      message,
      clearPrevious: clearPrevious,
    );
  }

  void _showDeleteSuccessMessage(BetModel bet) {
    final messenger = ScaffoldMessenger.of(context);

    messenger.clearSnackBars();
    messenger.showSnackBar(
      SnackBar(
        content: Text('${_displayMatchName(bet)} silindi.'),
        action: SnackBarAction(
          label: 'Geri Al',
          onPressed: () async {
            final restoreResult = await BetService.addBet(
              BetModel(
                userId: bet.userId,
                date: bet.date,
                sport: bet.sport,
                country: bet.country,
                league: bet.league,
                homeTeam: bet.resolvedHomeTeam,
                awayTeam: bet.resolvedAwayTeam,
                matchName: bet.matchName,
                betType: bet.betType,
                odd: bet.odd,
                stake: bet.stake,
                result: bet.result,
                netProfit: bet.netProfit,
                note: bet.note,
                createdAt: bet.createdAt,
                confidenceScore: bet.confidenceScore,
              ),
            );

            if (!mounted) return;

            if (restoreResult != null) {
              _showMessage(restoreResult);
              return;
            }

            _showMessage('Bahis geri yüklendi.');
          },
        ),
      ),
    );
  }

  String _displayMatchName(BetModel bet) {
    final home = bet.resolvedHomeTeam.trim();
    final away = bet.resolvedAwayTeam.trim();

    if (home.isNotEmpty && away.isNotEmpty) {
      return '$home - $away';
    }

    return bet.matchName;
  }
  IconData _sportIcon(String sport) {
    switch (sport) {
      case 'Futbol':
        return Icons.sports_soccer;
      case 'Basketbol':
        return Icons.sports_basketball;
      case 'Tenis':
        return Icons.sports_tennis;
      case 'Voleybol':
        return Icons.sports_volleyball;
      default:
        return Icons.emoji_events_outlined;
    }
  }

  Future<void> _pickStartDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _startDate ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );

    if (picked != null) {
      setState(() {
        _clearQuickFilterSelection();
        _startDate = picked;
      });
    }
  }

  Future<void> _pickEndDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _endDate ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );

    if (picked != null) {
      setState(() {
        _clearQuickFilterSelection();
        _endDate = picked;
      });
    }
  }

  Future<bool> _handleDelete(BetModel bet) async {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null || bet.id == null) {
      _showMessage('Silinecek bahis bulunamadı.');
      return false;
    }

    final result = await BetService.deleteBet(
      userId: user.uid,
      betId: bet.id!,
    );

    if (!mounted) return false;

    if (result != null) {
      _showMessage(result);
      return false;
    }

    _showDeleteSuccessMessage(bet);

    return true;
  }

  Future<bool> _confirmDelete(BetModel bet) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
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
          title: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: statusToneFill(StatusTone.danger),
                  borderRadius: BorderRadius.circular(AppRadius.md),
                  border: Border.all(
                    color: statusToneBorder(StatusTone.danger),
                  ),
                ),
                child: Icon(
                  Icons.delete_outline,
                  color: statusToneColor(StatusTone.danger),
                  size: 20,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Bahsi Sil',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Bu kayıt geçmişten kaldırılacak.',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          content: Text(
            '"${_displayMatchName(bet)}" kaydı silinecek. Silme sonrası kısa süre içinde geri alabilirsin.',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext, false);
              },
              child: const Text('Vazgeç'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(dialogContext, true);
              },
              style: _dangerDialogButtonStyle(),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.delete_outline, size: 18),
                  SizedBox(width: 6),
                  Text('Sil'),
                ],
              ),
            ),
          ],
        );
      },
    );

    if (confirmed != true) return false;

    return _handleDelete(bet);
  }

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.of(context).size.width > 800;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Bahis Geçmişi'),
      ),
      body: StreamBuilder<List<BetModel>>(
        stream: BetService.getUserBets(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          if (snapshot.hasError) {
            return ErrorStateCard(
              message: 'Bahisler yüklenirken hata oluştu:\n${snapshot.error}',
            );
          }

          final bets = snapshot.data ?? [];
          final viewData = _buildViewData(bets);

          final countryOptions = viewData.countryOptions;
          final leagueOptions = viewData.leagueOptions;
          final filteredBets = viewData.filteredBets;
          final summary = viewData.summary;

          return Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1000),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Card(
                      color: AppColors.surface,
                      elevation: 0,
                      shape: AppStyles.cardShape(),
                      child: Padding(
                        padding: const EdgeInsets.all(AppSpacing.lg),
                        child: GridView.count(
                          crossAxisCount: isWide ? 5 : 2,
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          mainAxisSpacing: 14,
                          crossAxisSpacing: 14,
                          childAspectRatio: isWide ? 2.4 : 2.8,
                          children: [
                            _TopStat(
                              title: 'Kayıt',
                              value: '${summary.recordCount}',
                            ),
                            _TopStat(
                              title: 'Net',
                              value: '${summary.totalProfit.toStringAsFixed(2)} ₺',
                              tone: summary.totalProfit >= 0
                                  ? StatusTone.success
                                  : StatusTone.danger,
                            ),
                            _TopStat(
                              title: 'Toplam Tutar',
                              value: '${summary.totalStake.toStringAsFixed(2)} ₺',
                            ),
                            _TopStat(
                              title: 'Ort. Oran',
                              value: summary.averageOdd.toStringAsFixed(2),
                            ),
                            _TopStat(
                              title: 'Kazanan',
                              value: '${summary.wonCount}',
                              tone: StatusTone.success,
                            ),
                            _TopStat(
                              title: 'Kaybeden',
                              value: '${summary.lostCount}',
                              tone: StatusTone.danger,
                            ),
                            _TopStat(
                              title: 'Bekleyen',
                              value: '${summary.pendingCount}',
                              tone: StatusTone.muted,
                            ),
                            _TopStat(
                              title: 'Yüksek Güven',
                              value: '${summary.highConfidenceCount}',
                              tone: summary.highConfidenceCount > 0
                                  ? StatusTone.warning
                                  : null,
                            ),
                            _TopStat(
                              title: 'Yüksek Güven Net',
                              value: '${summary.highConfidenceProfit.toStringAsFixed(2)} ₺',
                              tone: summary.highConfidenceProfit >= 0
                                  ? StatusTone.success
                                  : StatusTone.danger,
                            ),
                            _TopStat(
                              title: 'Ort. Güven',
                              value: summary.averageConfidence.toStringAsFixed(1),
                              tone: summary.averageConfidence >= 9
                                  ? StatusTone.warning
                                  : summary.averageConfidence >= 7
                                  ? StatusTone.success
                                  : null,
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Card(
                      color: AppColors.surface,
                      elevation: 0,
                      shape: AppStyles.cardShape(),
                      child: Padding(
                        padding: const EdgeInsets.all(AppSpacing.xl),
                        child: Column(
                          children: [
                            TextField(
                              controller: _searchController,
                              onChanged: _onSearchChanged,
                              decoration: const InputDecoration(
                                labelText: 'Ara',
                                hintText: 'Maç, spor, ülke, lig, bahis türü veya not',
                                prefixIcon: Icon(Icons.search),
                              ),
                            ),
                            const SizedBox(height: 14),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: [
                                _QuickFilterChip(
                                  label: 'Bugün',
                                  tone: _quickFilterTone('Bugün'),
                                  isSelected: _selectedQuickFilter == 'Bugün',
                                  onTap: () => _applyQuickFilter('Bugün'),
                                ),
                                _QuickFilterChip(
                                  label: 'Son 7 Gün',
                                  tone: _quickFilterTone('Son 7 Gün'),
                                  isSelected: _selectedQuickFilter == 'Son 7 Gün',
                                  onTap: () => _applyQuickFilter('Son 7 Gün'),
                                ),
                                _QuickFilterChip(
                                  label: 'Bu Ay',
                                  tone: _quickFilterTone('Bu Ay'),
                                  isSelected: _selectedQuickFilter == 'Bu Ay',
                                  onTap: () => _applyQuickFilter('Bu Ay'),
                                ),
                                _QuickFilterChip(
                                  label: 'Sadece Kaybedenler',
                                  tone: _quickFilterTone('Sadece Kaybedenler'),
                                  isSelected:
                                  _selectedQuickFilter == 'Sadece Kaybedenler',
                                  onTap: () =>
                                      _applyQuickFilter('Sadece Kaybedenler'),
                                ),
                                _QuickFilterChip(
                                  label: 'Sadece Bekleyenler',
                                  tone: _quickFilterTone('Sadece Bekleyenler'),
                                  isSelected:
                                  _selectedQuickFilter == 'Sadece Bekleyenler',
                                  onTap: () =>
                                      _applyQuickFilter('Sadece Bekleyenler'),
                                ),
                                _QuickFilterChip(
                                  label: 'Yüksek Güven',
                                  tone: _quickFilterTone('Yüksek Güven'),
                                  isSelected:
                                  _selectedQuickFilter == 'Yüksek Güven',
                                  onTap: () => _applyQuickFilter('Yüksek Güven'),
                                ),
                              ],
                            ),
                            const SizedBox(height: 14),
                            Align(
                              alignment: Alignment.centerLeft,
                              child: TextButton.icon(
                                onPressed: () {
                                  setState(() {
                                    _showAdvancedFilters =
                                    !_showAdvancedFilters;
                                  });
                                },
                                icon: Icon(
                                  _showAdvancedFilters
                                      ? Icons.expand_less
                                      : Icons.expand_more,
                                ),
                                label: Text(
                                  _showAdvancedFilters
                                      ? 'Gelişmiş Filtreleri Gizle'
                                      : 'Gelişmiş Filtreleri Göster',
                                ),
                              ),
                            ),
                            if (_showAdvancedFilters) ...[
                              const SizedBox(height: 10),
                              if (isWide)
                                Column(
                                  children: [
                                    Row(
                                      children: [
                                        Expanded(child: _buildSportDropdown()),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: _buildCountryDropdown(countryOptions),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 12),
                                    Row(
                                      children: [
                                        Expanded(
                                          child: _buildLeagueDropdown(leagueOptions),
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(child: _buildResultDropdown()),
                                      ],
                                    ),
                                    const SizedBox(height: 12),
                                    Row(
                                      children: [
                                        Expanded(child: _buildConfidenceDropdown()),
                                        const SizedBox(width: 12),
                                        const Expanded(child: SizedBox()),
                                      ],
                                    ),
                                  ],
                                )
                              else
                                Column(
                                  children: [
                                    _buildSportDropdown(),
                                    const SizedBox(height: 12),
                                    _buildCountryDropdown(countryOptions),
                                    const SizedBox(height: 12),
                                    _buildLeagueDropdown(leagueOptions),
                                    const SizedBox(height: 12),
                                    _buildResultDropdown(),
                                    const SizedBox(height: 12),
                                    _buildConfidenceDropdown(),

                                  ],
                                ),
                              const SizedBox(height: 14),
                              DropdownButtonFormField<String>(
                                value: _sortOption,
                                decoration: const InputDecoration(
                                  labelText: 'Sıralama',
                                  prefixIcon: Icon(Icons.sort),
                                ),
                                items: _sortOptions
                                    .map(
                                      (option) => DropdownMenuItem(
                                    value: option,
                                    child: Text(option),
                                  ),
                                )
                                    .toList(),
                                onChanged: (value) {
                                  setState(() {
                                    _sortOption =
                                        value ?? 'Tarih (Yeni → Eski)';
                                  });
                                },
                              ),
                              const SizedBox(height: 14),
                              if (isWide)
                                Row(
                                  children: [
                                    Expanded(
                                      child: OutlinedButton.icon(
                                        onPressed: _pickStartDate,
                                        icon: const Icon(Icons.date_range),
                                        label: Text(
                                          _startDate == null
                                              ? 'Başlangıç Tarihi'
                                              : BetFormHelpers.formatShortDate(_startDate!),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: OutlinedButton.icon(
                                        onPressed: _pickEndDate,
                                        icon: const Icon(Icons.event),
                                        label: Text(
                                          _endDate == null
                                              ? 'Bitiş Tarihi'
                                              : BetFormHelpers.formatShortDate(_endDate!),
                                        ),
                                      ),
                                    ),
                                  ],
                                )
                              else
                                Column(
                                  children: [
                                    OutlinedButton.icon(
                                      onPressed: _pickStartDate,
                                      icon: const Icon(Icons.date_range),
                                      label: Text(
                                        _startDate == null
                                            ? 'Başlangıç Tarihi'
                                            : BetFormHelpers.formatShortDate(_startDate!),
                                      ),
                                    ),
                                    const SizedBox(height: 12),
                                    OutlinedButton.icon(
                                      onPressed: _pickEndDate,
                                      icon: const Icon(Icons.event),
                                      label: Text(
                                        _endDate == null
                                            ? 'Bitiş Tarihi'
                                            : BetFormHelpers.formatShortDate(_endDate!),
                                      ),
                                    ),
                                  ],
                                ),
                              const SizedBox(height: 14),
                              if (isWide)
                                Row(
                                  children: [
                                    Expanded(
                                      child: _buildFilterNumberField(
                                        controller: _minOddController,
                                        label: 'Min Oran',
                                        icon: Icons.trending_up,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: _buildFilterNumberField(
                                        controller: _maxOddController,
                                        label: 'Max Oran',
                                        icon: Icons.trending_down,
                                      ),
                                    ),
                                  ],
                                )
                              else
                                Column(
                                  children: [
                                    _buildFilterNumberField(
                                      controller: _minOddController,
                                      label: 'Min Oran',
                                      icon: Icons.trending_up,
                                    ),
                                    const SizedBox(height: 12),
                                    _buildFilterNumberField(
                                      controller: _maxOddController,
                                      label: 'Max Oran',
                                      icon: Icons.trending_down,
                                    ),
                                  ],
                                ),
                              const SizedBox(height: 14),
                              if (isWide)
                                Row(
                                  children: [
                                    Expanded(
                                      child: _buildFilterNumberField(
                                        controller: _minStakeController,
                                        label: 'Min Tutar',
                                        icon: Icons.payments_outlined,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: _buildFilterNumberField(
                                        controller: _maxStakeController,
                                        label: 'Max Tutar',
                                        icon: Icons.account_balance_wallet_outlined,
                                      ),
                                    ),
                                  ],
                                )
                              else
                                Column(
                                  children: [
                                    _buildFilterNumberField(
                                      controller: _minStakeController,
                                      label: 'Min Tutar',
                                      icon: Icons.payments_outlined,
                                    ),
                                    const SizedBox(height: 12),
                                    _buildFilterNumberField(
                                      controller: _maxStakeController,
                                      label: 'Max Tutar',
                                      icon: Icons.account_balance_wallet_outlined,
                                    ),
                                  ],
                                ),
                            ],
                            const SizedBox(height: 14),
                            Align(
                              alignment: Alignment.centerRight,
                              child: TextButton.icon(
                                onPressed: _clearFilters,
                                icon: const Icon(Icons.clear_all),
                                label: const Text('Filtreleri Temizle'),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    SectionHeader(
                      title: 'Kayıtlar',
                      trailing: BetInfoChip(
                        icon: Icons.inventory_2_outlined,
                        text: '${summary.recordCount} kayıt',
                        tone: StatusTone.info,
                      ),
                    ),
                    const SizedBox(height: 12),
                    if (filteredBets.isEmpty)
                      const InfoCard(
                        text:
                        'Filtreye uygun bahis bulunamadı.\nArama kelimesini daraltmış veya filtreleri fazla sıkmış olabilirsin.',
                      )
                    else
                      ...filteredBets.map(
                            (bet) => Dismissible(
                          key: ValueKey(
                            '${bet.id ?? bet.createdAt.millisecondsSinceEpoch}_${bet.matchName}',
                          ),
                          direction: DismissDirection.endToStart,
                          confirmDismiss: (_) => _confirmDelete(bet),
                              background: Container(
                                margin: const EdgeInsets.only(bottom: 12),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: AppSpacing.lg,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.danger,
                                  borderRadius: BorderRadius.circular(AppRadius.lg),
                                ),
                                alignment: Alignment.centerRight,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 10,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.10),
                                    borderRadius: BorderRadius.circular(
                                      AppRadius.pill,
                                    ),
                                    border: Border.all(
                                      color: Colors.white.withValues(alpha: 0.16),
                                    ),
                                  ),
                                  child: const Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        Icons.delete_outline,
                                        color: Colors.white,
                                        size: 18,
                                      ),
                                      SizedBox(width: 6),
                                      Text(
                                        'Sil',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              child: _BetCard(
                                bet: bet,
                                resultLabel: resultLabel(bet.result),
                                resultTone: _resultTone(bet.result),
                                formattedDate: BetFormHelpers.formatShortDate(bet.date),
                                sportIcon: _sportIcon(bet.sport),
                              ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildFilterNumberField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
  }) {
    return TextField(
      controller: controller,
      keyboardType: const TextInputType.numberWithOptions(
        decimal: true,
      ),
      onChanged: (_) => _rebuildFilters(),
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
      ),
    );
  }

  Widget _buildSportDropdown() {
    return DropdownButtonFormField<String>(
      value: _selectedSport,
      decoration: const InputDecoration(
        labelText: 'Spor Dalı',
        prefixIcon: Icon(Icons.sports_soccer),
      ),
      items: _sportOptions
          .map(
            (sport) => DropdownMenuItem(
          value: sport,
          child: Text(sport),
        ),
      )
          .toList(),
      onChanged: (value) {
        setState(() {
          _clearQuickFilterSelection();
          _selectedSport = value ?? 'Tümü';
          _selectedCountry = 'Tümü';
          _selectedLeague = 'Tümü';
        });
      },
    );
  }

  Widget _buildCountryDropdown(List<String> countryOptions) {
    return DropdownButtonFormField<String>(
      value: countryOptions.contains(_selectedCountry) ? _selectedCountry : 'Tümü',
      decoration: const InputDecoration(
        labelText: 'Ülke',
        prefixIcon: Icon(Icons.public),
      ),
      items: countryOptions
          .map(
            (country) => DropdownMenuItem(
          value: country,
          child: Text(country),
        ),
      )
          .toList(),
      onChanged: (value) {
        setState(() {
          _clearQuickFilterSelection();
          _selectedCountry = value ?? 'Tümü';
          _selectedLeague = 'Tümü';
        });
      },
    );
  }

  Widget _buildLeagueDropdown(List<String> leagueOptions) {
    return DropdownButtonFormField<String>(
      value: leagueOptions.contains(_selectedLeague) ? _selectedLeague : 'Tümü',
      decoration: const InputDecoration(
        labelText: 'Lig',
        prefixIcon: Icon(Icons.emoji_events_outlined),
      ),
      items: leagueOptions
          .map(
            (league) => DropdownMenuItem(
          value: league,
          child: Text(league),
        ),
      )
          .toList(),
      onChanged: (value) {
        setState(() {
          _clearQuickFilterSelection();
          _selectedLeague = value ?? 'Tümü';
        });
      },
    );
  }

  Widget _buildResultDropdown() {
    return DropdownButtonFormField<String>(
      value: _selectedResult,
      decoration: const InputDecoration(
        labelText: 'Sonuç',
        prefixIcon: Icon(Icons.flag_outlined),
      ),
      items: _resultOptions
          .map(
            (result) => DropdownMenuItem(
          value: result,
          child: Text(resultLabel(result == 'Tümü' ? 'Tümü' : result)),
        ),
      )
          .toList(),
      onChanged: (value) {
        setState(() {
          _clearQuickFilterSelection();
          _selectedResult = value ?? 'Tümü';
        });
      },
    );
  }
  Widget _buildConfidenceDropdown() {
    return DropdownButtonFormField<String>(
      value: _selectedConfidence,
      decoration: const InputDecoration(
        labelText: 'Güven',
        prefixIcon: Icon(Icons.verified_outlined),
      ),
      items: _confidenceOptions
          .map(
            (confidence) => DropdownMenuItem(
          value: confidence,
          child: Text(
            confidence == 'Tümü'
                ? 'Tümü'
                : confidence == '9-10'
                ? '9-10 (Yüksek Güven)'
                : 'Güven $confidence',
          ),
        ),
      )
          .toList(),
      onChanged: (value) {
        setState(() {
          _clearQuickFilterSelection();
          _selectedConfidence = value ?? 'Tümü';
        });
      },
    );
  }
}

class _BetCard extends StatelessWidget {
  final BetModel bet;
  final String resultLabel;
  final StatusTone resultTone;
  final String formattedDate;
  final IconData sportIcon;

  const _BetCard({
    required this.bet,
    required this.resultLabel,
    required this.resultTone,
    required this.formattedDate,
    required this.sportIcon,
  });

  @override
  Widget build(BuildContext context) {
    final matchTitle =
    bet.resolvedHomeTeam.isNotEmpty && bet.resolvedAwayTeam.isNotEmpty
        ? '${bet.resolvedHomeTeam} - ${bet.resolvedAwayTeam}'
        : bet.matchName;

    final locationText = [bet.country.trim(), bet.league.trim()]
        .where((item) => item.isNotEmpty)
        .join(' • ');

    final hasNote = bet.note.trim().isNotEmpty;

    final Color netColor;
    final IconData resultIcon;

    switch (bet.result) {
    case 'kazandi':
    netColor = homeSuccessColor();
    resultIcon = Icons.check_circle_outline;
    break;
    case 'kaybetti':
    netColor = homeDangerColor();
    resultIcon = Icons.cancel_outlined;
    break;
    case 'iade':
    netColor = homeWarningColor();
    resultIcon = Icons.reply_all_outlined;
    break;
    default:
    netColor = AppColors.textSecondary;
    resultIcon = Icons.hourglass_bottom_outlined;
    break;
    }

    return Card(
      color: AppColors.surface,
      elevation: 0,
      shape: AppStyles.cardShape(radius: AppRadius.lg),
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.lg),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => EditBetPage(bet: bet),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: statusToneFill(StatusTone.primary),
                      borderRadius: BorderRadius.circular(AppRadius.md),
                      border: Border.all(
                        color: statusToneBorder(StatusTone.primary),
                      ),
                    ),
                    child: Icon(
                      sportIcon,
                      size: 18,
                      color: statusToneColor(StatusTone.primary),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          matchTitle,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            height: 1.25,
                          ),
                        ),
                        if (locationText.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(
                            locationText,
                            style: const TextStyle(
                              color: AppColors.primary,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  ConfidenceBadge(score: bet.confidenceScore),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  BetInfoChip(
                    icon: Icons.calendar_today_outlined,
                    text: formattedDate,
                    tone: StatusTone.muted,
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
              if (hasNote) ...[
                const SizedBox(height: AppSpacing.md),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(AppSpacing.md),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceAlt,
                    borderRadius: BorderRadius.circular(AppRadius.md),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Not',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        bet.note.trim(),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          height: 1.35,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: AppSpacing.md),
              _BetOutcomeBar(
                resultLabel: resultLabel,
                resultTone: resultTone,
                resultIcon: resultIcon,
                netProfit: bet.netProfit,
                netColor: netColor,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BetOutcomeBar extends StatelessWidget {
  final String resultLabel;
  final StatusTone resultTone;
  final IconData resultIcon;
  final double netProfit;
  final Color netColor;

  const _BetOutcomeBar({
    required this.resultLabel,
    required this.resultTone,
    required this.resultIcon,
    required this.netProfit,
    required this.netColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.md,
      ),
      decoration: BoxDecoration(
        color: AppColors.surfaceAlt,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          BetInfoChip(
            icon: resultIcon,
            text: resultLabel,
            tone: resultTone,
          ),
          const Spacer(),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              const Text(
                'Net Etki',
                style: TextStyle(
                  fontSize: 11,
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                '${netProfit.toStringAsFixed(2)} ₺',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: netColor,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _TopStat extends StatelessWidget {
  final String title;
  final String value;
  final StatusTone? tone;

  const _TopStat({
    required this.title,
    required this.value,
    this.tone,
  });

  @override
  Widget build(BuildContext context) {
    return StatValueCard(
      title: title,
      value: value,
      valueColor: tone == null ? null : statusToneColor(tone!),
      centered: true,
      compact: true,
    );
  }
}

class _QuickFilterChip extends StatelessWidget {
  final String label;
  final StatusTone tone;
  final bool isSelected;
  final VoidCallback onTap;

  const _QuickFilterChip({
    required this.label,
    required this.tone,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final activeColor = statusToneColor(tone);

    return ChoiceChip(
      label: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: isSelected ? activeColor : AppColors.textPrimary,
        ),
      ),
      selected: isSelected,
      onSelected: (_) => onTap(),
      showCheckmark: false,
      backgroundColor: AppColors.surfaceAlt,
      selectedColor: statusToneFill(tone),
      side: BorderSide(
        color: isSelected ? statusToneBorder(tone) : AppColors.border,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
      labelPadding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
      ),
      padding: const EdgeInsets.symmetric(
        horizontal: 2,
        vertical: 2,
      ),
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      visualDensity: const VisualDensity(
        horizontal: -1,
        vertical: -2,
      ),
    );
  }
}