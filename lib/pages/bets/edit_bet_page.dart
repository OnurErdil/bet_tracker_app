import 'package:bet_tracker_app/data/bet_form_catalog.dart';
import 'package:bet_tracker_app/data/bet_form_helpers.dart';
import 'package:bet_tracker_app/domain/bankroll_discipline_calculator.dart';
import 'package:bet_tracker_app/models/bet_model.dart';
import 'package:bet_tracker_app/pages/bets/widgets/bet_form_status_widgets.dart';
import 'package:bet_tracker_app/pages/home/widgets/home_common_widgets.dart';
import 'package:bet_tracker_app/services/bankroll_service.dart';
import 'package:bet_tracker_app/services/bet_service.dart';
import 'package:bet_tracker_app/services/user_service.dart';
import 'package:bet_tracker_app/theme/app_design_tokens.dart';
import 'package:flutter/material.dart';

class EditBetPage extends StatefulWidget {
  final BetModel bet;

  const EditBetPage({
    super.key,
    required this.bet,
  });

  @override
  State<EditBetPage> createState() => _EditBetPageState();
}

class _EditBetPageState extends State<EditBetPage> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _sportController;
  late final TextEditingController _countryController;
  late final TextEditingController _leagueController;
  late final TextEditingController _homeTeamController;
  late final TextEditingController _awayTeamController;
  late final TextEditingController _betTypeController;
  late final TextEditingController _oddController;
  late final TextEditingController _stakeController;
  late final TextEditingController _noteController;





  List<String> _recentTeams = [];
  List<String> _frequentTeams = [];



  late DateTime _selectedDate;
  late String _selectedResult;

  bool _isLoading = false;
  bool _isDeleting = false;

  String _maxStakeMode = 'fixed';
  double _maxStakeValue = 0;
  double _dailyLossLimit = 0;
  double _targetBankroll = 0;
  double _currentDynamicMaxStake = 0;

  String _disciplineMode = 'warning'; // warning | block_bet | lock_day
  bool _isLockedForToday = false;
  double _todayLoss = 0;
  late int _confidenceScore;
  bool _highConfidenceEnabled = true;
  double _confidence9Multiplier =
      BankrollDisciplineCalculator.defaultConfidence9Multiplier;
  double _confidence10Multiplier =
      BankrollDisciplineCalculator.defaultConfidence10Multiplier;

  @override
  void initState() {
    super.initState();

    final initialData = BetFormHelpers.buildInitialDataFromBet(widget.bet);

    _sportController = TextEditingController(text: initialData.sport);
    _countryController = TextEditingController(text: initialData.country);
    _leagueController = TextEditingController(text: initialData.league);
    _homeTeamController = TextEditingController(text: initialData.homeTeam);
    _awayTeamController = TextEditingController(text: initialData.awayTeam);

    _betTypeController = TextEditingController(text: widget.bet.betType);
    _oddController = TextEditingController(text: widget.bet.odd.toString());
    _stakeController = TextEditingController(text: widget.bet.stake.toString());
    _noteController = TextEditingController(text: widget.bet.note);

    _selectedDate = widget.bet.date;
    _selectedResult = widget.bet.result;
    _confidenceScore = widget.bet.confidenceScore;

    _loadDisciplineSettings();
    _loadTeamSuggestions();
    _oddController.addListener(_refreshPreview);
    _stakeController.addListener(_refreshPreview);
  }

  @override
  void dispose() {
    _oddController.removeListener(_refreshPreview);
    _stakeController.removeListener(_refreshPreview);

    _sportController.dispose();
    _countryController.dispose();
    _leagueController.dispose();
    _homeTeamController.dispose();
    _awayTeamController.dispose();
    _betTypeController.dispose();
    _oddController.dispose();
    _stakeController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _loadTeamSuggestions() async {
    final bets = await BetService.getUserBets().first;
    final suggestionData = BetFormHelpers.extractTeamSuggestionData(bets);

    if (!mounted) return;

    setState(() {
      _recentTeams = suggestionData.recentTeams;
      _frequentTeams = suggestionData.frequentTeams;
    });
  }
  BetFormSelectionData get _selectionData {
    return BetFormHelpers.buildSelectionData(
      sport: _sportController.text.trim(),
      country: _countryController.text.trim(),
      league: _leagueController.text.trim(),
    );
  }

  List<String> get _availableCountries => _selectionData.availableCountries;

  List<String> get _availableLeagues => _selectionData.availableLeagues;

  List<String> get _availableBetTypes => _selectionData.availableBetTypes;

  List<String> _getSmartTeamSuggestions(String query) {
    return BetFormHelpers.buildSmartTeamSuggestionsForSelection(
      query: query,
      sport: _sportController.text.trim(),
      country: _countryController.text.trim(),
      league: _leagueController.text.trim(),
      recentTeams: _recentTeams,
      frequentTeams: _frequentTeams,
    );
  }

  Future<void> _loadDisciplineSettings() async {
    final userData = await UserService.getUserProfileOnce();
    if (!mounted || userData == null) return;

    final bets = await BetService.getUserBets().first;
    final transactions = await BankrollService.getTransactions().first;

    final snapshot = BankrollDisciplineCalculator.calculate(
      bets: bets,
      transactions: transactions,
      userData: userData,
      referenceDate: DateTime.now(),
    );

    setState(() {
      _maxStakeMode = snapshot.maxStakeMode;
      _maxStakeValue = snapshot.maxStakeValue;
      _dailyLossLimit = snapshot.dailyLossLimit;
      _targetBankroll = snapshot.targetBankroll;
      _currentDynamicMaxStake = snapshot.computedMaxStake;
      _disciplineMode = snapshot.disciplineMode;
      _isLockedForToday = snapshot.isLockedForToday;
      _todayLoss = snapshot.todayLoss;
      _highConfidenceEnabled = snapshot.highConfidenceEnabled;
      _confidence9Multiplier = snapshot.confidence9Multiplier;
      _confidence10Multiplier = snapshot.confidence10Multiplier;
    });
  }

  void _refreshPreview() {
    if (mounted) {
      setState(() {});
    }
  }

  double get _effectiveMaxStake {
    return BankrollDisciplineCalculator.calculateAllowedStakeForConfidence(
      baseMaxStake: _currentDynamicMaxStake,
      confidenceScore: _confidenceScore,
      highConfidenceEnabled: _highConfidenceEnabled,
      confidence9Multiplier: _confidence9Multiplier,
      confidence10Multiplier: _confidence10Multiplier,
    );
  }

  BetFormPreviewData get _previewData {
    return BetFormHelpers.buildPreviewData(
      oddText: _oddController.text,
      stakeText: _stakeController.text,
      result: _selectedResult,
      effectiveMaxStake: _effectiveMaxStake,
    );
  }

  bool get _isHighConfidenceSelected {
    return BankrollDisciplineCalculator.isHighConfidence(
      _confidenceScore,
      highConfidenceEnabled: _highConfidenceEnabled,
    );
  }

  double get _previewNetProfit => _previewData.netProfit;

  double get _previewPayout => _previewData.payout;

  String get _previewResultLabel => _previewData.resultLabel;

  StatusTone get _previewNetTone {
    if (_previewNetProfit > 0) return StatusTone.success;
    if (_previewNetProfit < 0) return StatusTone.danger;
    return StatusTone.warning;
  }

  bool get _isPreviewLimitExceeded => _previewData.isLimitExceeded;

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );

    if (picked != null) {
      setState(() {
        _selectedDate = DateTime(
          picked.year,
          picked.month,
          picked.day,
          _selectedDate.hour,
          _selectedDate.minute,
        );
      });
    }
  }

  String _maxStakeInfoText() {
    return BetFormHelpers.buildMaxStakeInfoText(
      currentDynamicMaxStake: _currentDynamicMaxStake,
      maxStakeMode: _maxStakeMode,
      maxStakeValue: _maxStakeValue,
      confidenceScore: _confidenceScore,
      highConfidenceEnabled: _highConfidenceEnabled,
      confidence9Multiplier: _confidence9Multiplier,
      confidence10Multiplier: _confidence10Multiplier,
      effectiveMaxStake: _effectiveMaxStake,
      isHighConfidenceSelected: _isHighConfidenceSelected,
    );
  }

  String _disciplineModeLabel() {
    return BetFormHelpers.buildDisciplineModeLabel(_disciplineMode);
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

  ButtonStyle _dangerDialogButtonStyle() {
    return solidToneButtonStyle(
      tone: StatusTone.danger,
    );
  }

  ButtonStyle _submitButtonStyle(StatusTone tone) {
    return solidToneButtonStyle(
      tone: tone,
      minimumSize: const Size(double.infinity, 52),
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.md,
      ),
    );
  }

  ButtonStyle _primarySubmitButtonStyle() {
    return _submitButtonStyle(StatusTone.primary);
  }

  ButtonStyle _dangerSubmitButtonStyle() {
    return _submitButtonStyle(StatusTone.danger);
  }


  Future<bool> _handleDailyLossLimitBeforeUpdate({
    required double stake,
  }) async {
    if (_dailyLossLimit <= 0) {
      return true;
    }

    final isTodayBet = BetFormHelpers.isSameDay(
      _selectedDate,
      DateTime.now(),
    );
    if (!isTodayBet) {
      return true;
    }

    final todayLoss = await BetService.getDailyLossForDate(DateTime.now());

    if (!mounted) return false;

    double adjustedTodayLoss = todayLoss;

    if (BetFormHelpers.isSameDay(widget.bet.date, DateTime.now()) &&
        widget.bet.result == 'kaybetti' &&
        widget.bet.netProfit < 0) {
      adjustedTodayLoss -= widget.bet.netProfit.abs();
      if (adjustedTodayLoss < 0) adjustedTodayLoss = 0;
    }

    setState(() {
      _todayLoss = adjustedTodayLoss;
    });

    final alreadyExceeded = adjustedTodayLoss >= _dailyLossLimit;

    if (alreadyExceeded) {
      if (_disciplineMode == 'block_bet') {
        _showMessage(
          BetFormHelpers.buildDailyLossAlreadyExceededMessage(
            disciplineMode: _disciplineMode,
            blockMessage: 'Bu bahis güncellenemez.',
          ),
        );
        return false;
      }

      if (_disciplineMode == 'lock_day') {
        setState(() {
          _isLockedForToday = true;
        });
        _showMessage(
          BetFormHelpers.buildDailyLossAlreadyExceededMessage(
            disciplineMode: _disciplineMode,
            blockMessage: 'Bu bahis güncellenemez.',
          ),
        );
        return false;
      }

      _showMessage(
        BetFormHelpers.buildDailyLossAlreadyExceededMessage(
          disciplineMode: _disciplineMode,
          blockMessage: 'Bu bahis güncellenemez.',
        ),
      );
      return true;
    }

    if (_selectedResult == 'kaybetti') {
      final projectedLoss = adjustedTodayLoss + stake;

      if (projectedLoss > _dailyLossLimit) {
        final message = BetFormHelpers.buildProjectedDailyLossLimitMessage(
          disciplineMode: _disciplineMode,
          actionLabel: 'Bu güncelleme',
          dailyLossLimit: _dailyLossLimit,
        );

        if (_disciplineMode == 'block_bet') {
          _showMessage(message);
          return false;
        }

        if (_disciplineMode == 'lock_day') {
          setState(() {
            _isLockedForToday = true;
          });
          _showMessage(message);
          return false;
        }

        _showMessage(message);
      }
    }

    return true;
  }

  Future<bool> _handleMaxStakeLimitBeforeUpdate({
    required double stake,
  }) async {
    final effectiveLimit = _effectiveMaxStake;

    if (effectiveLimit <= 0 || stake <= effectiveLimit) {
      return true;
    }

    final limitText = BetFormHelpers.buildMaxStakeLimitText(
      isHighConfidenceSelected: _isHighConfidenceSelected,
      confidenceScore: _confidenceScore,
      maxStakeMode: _maxStakeMode,
      maxStakeValue: _maxStakeValue,
      effectiveMaxStake: effectiveLimit,
    );

    if (_disciplineMode == 'block_bet') {
      _showMessage('Bu bahis tutarı maksimum bahis limitini aşıyor. $limitText');
      return false;
    }

    if (_disciplineMode == 'lock_day') {
      setState(() {
        _isLockedForToday = true;
      });
      _showMessage('Maksimum bahis limiti aşıldı. Bugün bahis kapandı.');
      return false;
    }

    _showMessage('Uyarı: Bu bahis tutarı maksimum bahis limitini aşıyor. $limitText');
    return true;
  }

  Future<void> _updateBet() async {
    FocusScope.of(context).unfocus();

    if (!_formKey.currentState!.validate()) return;

    if (_disciplineMode == 'lock_day' && _isLockedForToday) {
      _showMessage('Bugün bahis kapalı. Günlük disiplin kilidi aktif.');
      return;
    }

    final previewData = _previewData;
    final odd = previewData.odd;
    final stake = previewData.stake;

    if (odd == null || stake == null) {
      _showMessage('Oran ve tutar sayısal olmalı.');
      return;
    }

    final dailyLossAllowed = await _handleDailyLossLimitBeforeUpdate(
      stake: stake,
    );
    if (!dailyLossAllowed) return;

    final maxStakeAllowed = await _handleMaxStakeLimitBeforeUpdate(
      stake: stake,
    );
    if (!maxStakeAllowed) return;

    final homeTeam = _homeTeamController.text.trim();
    final awayTeam = _awayTeamController.text.trim();
    final matchName = BetFormHelpers.buildMatchName(
      homeTeam: homeTeam,
      awayTeam: awayTeam,
    );

    setState(() => _isLoading = true);

    final updatedBet = BetModel(
      id: widget.bet.id,
      userId: widget.bet.userId,
      date: _selectedDate,
      sport: _sportController.text.trim(),
      country: _countryController.text.trim(),
      league: _leagueController.text.trim(),
      homeTeam: homeTeam,
      awayTeam: awayTeam,
      matchName: matchName,
      betType: _betTypeController.text.trim(),
      odd: odd,
      stake: stake,
      result: _selectedResult,
      netProfit: previewData.netProfit,
      note: _noteController.text.trim(),
      createdAt: widget.bet.createdAt,
      confidenceScore: _confidenceScore,
    );

    final result = await BetService.updateBet(updatedBet);

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (result != null) {
      _showMessage(result);
      return;
    }

    await _loadTeamSuggestions();

    if (!mounted) return;

    _showMessage(
      'Bahis güncellendi.',
      clearPrevious: true,
    );
    Navigator.pop(context);
  }
  String _currentMatchNameForDialog() {
    final homeTeam = _homeTeamController.text.trim();
    final awayTeam = _awayTeamController.text.trim();

    if (homeTeam.isNotEmpty && awayTeam.isNotEmpty) {
      return '$homeTeam - $awayTeam';
    }

    return widget.bet.matchName;
  }
  Future<void> _confirmDelete() async {
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
          title: const AppDialogHeader(
            icon: Icons.delete_outline,
            title: 'Bahsi Sil',
            subtitle: 'Bu kayıt düzenleme ekranından kaldırılacak.',
            tone: StatusTone.danger,
          ),
          content: Text(
            '"${_currentMatchNameForDialog()}" kaydı silinecek. Silme sonrası kısa süre içinde geri alabilirsin.',
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
              child: const ButtonIconLabel(
                icon: Icons.delete_outline,
                label: 'Sil',
              ),
            ),
          ],
        );
      },
    );

    if (confirmed == true) {
      await _deleteBet();
    }
  }
  Future<void> _deleteBet() async {
    if (widget.bet.id == null) {
      _showMessage('Silinecek bahis bulunamadı.');
      return;
    }

    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    final deletedBet = widget.bet;

    setState(() => _isDeleting = true);

    final result = await BetService.deleteBet(
      userId: deletedBet.userId,
      betId: deletedBet.id!,
    );

    if (!mounted) return;
    setState(() => _isDeleting = false);

    if (result != null) {
      _showMessage(result);
      return;
    }

    final deletedMatchName = _currentMatchNameForDialog();

    messenger.clearSnackBars();
    navigator.pop();

    Future<void> restoreDeletedBet() async {
      final restoreResult = await BetService.addBet(
        BetModel(
          userId: deletedBet.userId,
          date: deletedBet.date,
          sport: deletedBet.sport,
          country: deletedBet.country,
          league: deletedBet.league,
          homeTeam: deletedBet.resolvedHomeTeam,
          awayTeam: deletedBet.resolvedAwayTeam,
          matchName: deletedBet.matchName,
          betType: deletedBet.betType,
          odd: deletedBet.odd,
          stake: deletedBet.stake,
          result: deletedBet.result,
          netProfit: deletedBet.netProfit,
          note: deletedBet.note,
          createdAt: deletedBet.createdAt,
          confidenceScore: deletedBet.confidenceScore,
        ),
      );

      messenger.clearSnackBars();

      if (restoreResult != null) {
        if (!mounted) return;

        showAppSnackBar(
          context,
          restoreResult,
          clearPrevious: true,
          tone: StatusTone.danger,
        );
        return;
      }

      if (!mounted) return;

      showAppSnackBar(
        context,
        'Bahis geri yüklendi.',
        clearPrevious: true,
        tone: StatusTone.success,
      );
    }

    messenger.showSnackBar(
      SnackBar(
        duration: const Duration(seconds: 5),
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppColors.surfaceAlt,
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              '$deletedMatchName silindi.',
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: restoreDeletedBet,
                icon: const Icon(Icons.restore, size: 18),
                label: const Text('Geri Al'),
                style: TextButton.styleFrom(
                  foregroundColor: statusToneColor(StatusTone.warning),
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md,
                    vertical: AppSpacing.sm,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.of(context).size.width > 700;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Bahsi Düzenle'),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: isWide ? 700 : double.infinity,
            ),
            child: Card(
              color: AppColors.surface,
              elevation: 0,
              shape: AppStyles.cardShape(),
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.xl),
                child: Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      if (_isLockedForToday)
                        const BetLockedWarningCard(),
                      if (_currentDynamicMaxStake > 0 ||
                          _dailyLossLimit > 0 ||
                          _targetBankroll > 0)
                        BetDisciplineInfoCard(
                          maxStakeInfoText: _currentDynamicMaxStake > 0 ? _maxStakeInfoText() : '',
                          confidenceScore: _confidenceScore,
                          isHighConfidenceSelected: _isHighConfidenceSelected,
                          effectiveMaxStake: _effectiveMaxStake,
                          dailyLossLimit: _dailyLossLimit,
                          targetBankroll: _targetBankroll,
                          todayLoss: _todayLoss,
                          disciplineModeLabel: _disciplineModeLabel(),
                        ),
                      BetLivePreviewCard(
                        previewResultLabel: _previewResultLabel,
                        netProfit: _previewNetProfit,
                        netTone: _previewNetTone,
                        payout: _previewPayout,
                        effectiveMaxStake: _effectiveMaxStake,
                        isPreviewLimitExceeded: _isPreviewLimitExceeded,
                        payoutLabel: 'Toplam Geri Ödeme',
                      ),
                      DropdownButtonFormField<String>(
                        value: _sportController.text.isEmpty ||
                            !BetFormCatalog.sports.contains(_sportController.text)
                            ? null
                            : _sportController.text,
                        decoration: const InputDecoration(
                          labelText: 'Spor Dalı',
                          prefixIcon: Icon(Icons.sports_soccer),
                        ),
                        items: BetFormCatalog.sports
                            .map(
                              (sport) => DropdownMenuItem(
                            value: sport,
                            child: Text(sport),
                          ),
                        )
                            .toList(),
                        onChanged: (value) {
                          setState(() {
                            _sportController.text = value ?? '';
                            _countryController.clear();
                            _leagueController.clear();
                            _homeTeamController.clear();
                            _awayTeamController.clear();
                            _betTypeController.clear();
                          });
                        },
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Spor dalı seç';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 14),
                      if (isWide)
                        Row(
                          children: [
                            Expanded(
                              child: DropdownButtonFormField<String>(
                                value: _countryController.text.isEmpty
                                    ? null
                                    : _countryController.text,
                                decoration: const InputDecoration(
                                  labelText: 'Ülke',
                                  prefixIcon: Icon(Icons.public),
                                ),
                                items: _availableCountries
                                    .map(
                                      (country) => DropdownMenuItem(
                                    value: country,
                                    child: Text(
                                      country,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                )
                                    .toList(),
                                onChanged: (value) {
                                  setState(() {
                                    _countryController.text = value ?? '';
                                    _leagueController.clear();
                                    _homeTeamController.clear();
                                    _awayTeamController.clear();
                                  });
                                },
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Ülke seç';
                                  }
                                  return null;
                                },
                              ),
                            ),
                            const SizedBox(width: AppSpacing.md),
                            Expanded(
                              child: DropdownButtonFormField<String>(
                                value: _leagueController.text.isEmpty
                                    ? null
                                    : _leagueController.text,
                                decoration: const InputDecoration(
                                  labelText: 'Lig',
                                  prefixIcon: Icon(Icons.emoji_events_outlined),
                                ),
                                items: _availableLeagues
                                    .map(
                                      (league) => DropdownMenuItem(
                                    value: league,
                                    child: Text(
                                      league,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                )
                                    .toList(),
                                onChanged: (value) {
                                  setState(() {
                                    _leagueController.text = value ?? '';
                                    _homeTeamController.clear();
                                    _awayTeamController.clear();
                                  });
                                },
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Lig seç';
                                  }
                                  return null;
                                },
                              ),
                            ),
                          ],
                        )
                      else
                        Column(
                          children: [
                            DropdownButtonFormField<String>(
                              value: _countryController.text.isEmpty
                                  ? null
                                  : _countryController.text,
                              decoration: const InputDecoration(
                                labelText: 'Ülke',
                                prefixIcon: Icon(Icons.public),
                              ),
                              items: _availableCountries
                                  .map(
                                    (country) => DropdownMenuItem(
                                  value: country,
                                  child: Text(
                                    country,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              )
                                  .toList(),
                              onChanged: (value) {
                                setState(() {
                                  _countryController.text = value ?? '';
                                  _leagueController.clear();
                                  _homeTeamController.clear();
                                  _awayTeamController.clear();
                                });
                              },
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Ülke seç';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: AppSpacing.md),
                            DropdownButtonFormField<String>(
                              value: _leagueController.text.isEmpty
                                  ? null
                                  : _leagueController.text,
                              decoration: const InputDecoration(
                                labelText: 'Lig',
                                prefixIcon: Icon(Icons.emoji_events_outlined),
                              ),
                              items: _availableLeagues
                                  .map(
                                    (league) => DropdownMenuItem(
                                  value: league,
                                  child: Text(
                                    league,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              )
                                  .toList(),
                              onChanged: (value) {
                                setState(() {
                                  _leagueController.text = value ?? '';
                                  _homeTeamController.clear();
                                  _awayTeamController.clear();
                                });
                              },
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Lig seç';
                                }
                                return null;
                              },
                            ),
                          ],
                        ),
                      const SizedBox(height: 14),
                      Row(
                        children: [
                          Expanded(
                            child: _buildTeamAutocompleteField(
                              fieldKey: ValueKey(
                                'home_${_sportController.text}_${_countryController.text}_${_leagueController.text}',
                              ),
                              controller: _homeTeamController,
                              label: 'Ev Sahibi',
                              hint: 'Örn: Galatasaray',
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildTeamAutocompleteField(
                              fieldKey: ValueKey(
                                'away_${_sportController.text}_${_countryController.text}_${_leagueController.text}',
                              ),
                              controller: _awayTeamController,
                              label: 'Deplasman',
                              hint: 'Örn: Fenerbahçe',
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      DropdownButtonFormField<String>(
                        value: _betTypeController.text.isEmpty
                            ? null
                            : _betTypeController.text,
                        decoration: const InputDecoration(
                          labelText: 'Bahis Türü',
                          prefixIcon: Icon(Icons.tips_and_updates_outlined),
                        ),
                        items: _availableBetTypes
                            .map(
                              (betType) => DropdownMenuItem(
                            value: betType,
                            child: Text(betType),
                          ),
                        )
                            .toList(),
                        onChanged: (value) {
                          setState(() {
                            _betTypeController.text = value ?? '';
                          });
                        },
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Bahis türü seç';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 14),
                      BetConfidenceScoreCard(
                        confidenceScore: _confidenceScore,
                        isHighConfidenceSelected: _isHighConfidenceSelected,
                        effectiveMaxStake: _effectiveMaxStake,
                        onChanged: (value) {
                          setState(() {
                            _confidenceScore = value.round();
                          });
                        },
                      ),
                      Row(
                        children: [
                          Expanded(
                            child: _buildTextField(
                              controller: _oddController,
                              label: 'Oran',
                              hint: 'Örn: 1.85',
                              keyboardType:
                              const TextInputType.numberWithOptions(
                                decimal: true,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildTextField(
                              controller: _stakeController,
                              label: 'Tutar',
                              hint: _effectiveMaxStake > 0
                                  ? 'Max ${_effectiveMaxStake.toStringAsFixed(0)}'
                                  : 'Örn: 100',
                              keyboardType:
                              const TextInputType.numberWithOptions(
                                decimal: true,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      DropdownButtonFormField<String>(
                        value: _selectedResult,
                        decoration: const InputDecoration(
                          labelText: 'Sonuç',
                          prefixIcon: Icon(Icons.flag_outlined),
                        ),
                        items: const [
                          DropdownMenuItem(
                            value: 'beklemede',
                            child: Text('Beklemede'),
                          ),
                          DropdownMenuItem(
                            value: 'kazandi',
                            child: Text('Kazandı'),
                          ),
                          DropdownMenuItem(
                            value: 'kaybetti',
                            child: Text('Kaybetti'),
                          ),
                          DropdownMenuItem(
                            value: 'iade',
                            child: Text('İade'),
                          ),
                        ],
                        onChanged: (value) {
                          setState(() {
                            _selectedResult = value ?? 'beklemede';
                          });
                        },
                      ),
                      const SizedBox(height: 14),
                      InkWell(
                        onTap: _pickDate,
                        borderRadius: BorderRadius.circular(14),
                        child: InputDecorator(
                          decoration: const InputDecoration(
                            labelText: 'Tarih',
                            prefixIcon: Icon(Icons.calendar_today_outlined),
                          ),
                          child: Text(
                            BetFormHelpers.formatShortDate(_selectedDate),
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),
                      TextFormField(
                        controller: _noteController,
                        maxLines: 4,
                        decoration: const InputDecoration(
                          labelText: 'Not',
                          hintText: 'İstersen kısa not ekle',
                          alignLabelWithHint: true,
                          prefixIcon: Padding(
                            padding: EdgeInsets.only(bottom: 60),
                            child: Icon(Icons.note_alt_outlined),
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton(
                        onPressed:
                        (_isLoading || _isDeleting || _isLockedForToday)
                            ? null
                            : _updateBet,
                        style: _primarySubmitButtonStyle(),
                        child: _isLoading
                            ? const ButtonLoadingIndicator()
                            : const ButtonIconLabel(
                          icon: Icons.edit_outlined,
                          label: 'Güncelle',
                        ),
                      ),
                      const SizedBox(height: 12),
                      ElevatedButton(
                        onPressed:
                        (_isLoading || _isDeleting) ? null : _confirmDelete,
                        style: _dangerSubmitButtonStyle(),
                        child: _isDeleting
                            ? const ButtonLoadingIndicator()
                            : const ButtonIconLabel(
                          icon: Icons.delete_outline,
                          label: 'Sil',
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTeamAutocompleteField({
    required Key fieldKey,
    required TextEditingController controller,
    required String label,
    required String hint,
  }) {
    return Autocomplete<String>(
      key: fieldKey,
      initialValue: TextEditingValue(text: controller.text),
      optionsBuilder: (textEditingValue) {
        return _getSmartTeamSuggestions(textEditingValue.text);
      },
      onSelected: (selection) {
        controller.text = selection;

        final teamPath = BetFormCatalog.findTeamPath(selection);
        if (teamPath != null) {
          setState(() {
            _sportController.text = teamPath['sport'] ?? _sportController.text;
            _countryController.text =
                teamPath['country'] ?? _countryController.text;
            _leagueController.text =
                teamPath['league'] ?? _leagueController.text;
          });
        }
      },
      fieldViewBuilder: (
          context,
          textEditingController,
          focusNode,
          onFieldSubmitted,
          ) {
        if (textEditingController.text != controller.text) {
          textEditingController.value = TextEditingValue(
            text: controller.text,
            selection: TextSelection.collapsed(
              offset: controller.text.length,
            ),
          );
        }

        return TextFormField(
          controller: textEditingController,
          focusNode: focusNode,
          onChanged: (value) {
            controller.value = TextEditingValue(
              text: value,
              selection: TextSelection.collapsed(offset: value.length),
            );
          },
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Bu alan zorunlu';
            }
            return null;
          },
          decoration: InputDecoration(
            labelText: label,
            hintText: hint,
          ),
        );
      },
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    TextInputType? keyboardType,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          return 'Bu alan zorunlu';
        }
        return null;
      },
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
      ),
    );
  }
}