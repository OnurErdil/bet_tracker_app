import 'package:bet_tracker_app/data/bet_form_catalog.dart';
import 'package:bet_tracker_app/data/bet_form_helpers.dart';
import 'package:bet_tracker_app/models/bankroll_transaction_model.dart';
import 'package:bet_tracker_app/models/bet_model.dart';
import 'package:bet_tracker_app/services/bankroll_service.dart';
import 'package:bet_tracker_app/services/bet_service.dart';
import 'package:bet_tracker_app/services/user_service.dart';
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
  List<String> _getSmartTeamSuggestions(String query) {
    return BetFormHelpers.buildSmartTeamSuggestions(
      query: query,
      filteredTeams: _getFilteredTeams(),
      recentTeams: _recentTeams,
      frequentTeams: _frequentTeams,
    );
  }

  List<String> get _availableCountries {
    return BetFormCatalog.getAvailableCountries(_sportController.text);
  }

  List<String> get _availableLeagues {
    return BetFormCatalog.getAvailableLeagues(
      _sportController.text,
      _countryController.text,
    );
  }

  List<String> _getFilteredTeams() {
    return BetFormCatalog.getAvailableTeams(
      _sportController.text,
      _countryController.text,
      _leagueController.text,
    );
  }

  List<String> get _availableBetTypes {
    return BetFormCatalog.getAvailableBetTypes(_sportController.text);
  }

  Future<void> _loadDisciplineSettings() async {
    final userData = await UserService.getUserProfileOnce();
    if (!mounted || userData == null) return;

    final startingBankroll = (userData['startingBankroll'] ?? 0).toDouble();
    final maxStakeMode = (userData['maxStakeMode'] ?? 'fixed').toString();
    final maxStakeValue = (userData['maxStakeValue'] ?? 0).toDouble();
    final dailyLossLimit = (userData['dailyLossLimit'] ?? 0).toDouble();
    final targetBankroll = (userData['targetBankroll'] ?? 0).toDouble();
    final disciplineMode = (userData['disciplineMode'] ?? 'warning').toString();

    final bets = await BetService.getUserBets().first;
    final transactions = await BankrollService.getTransactions().first;

    final totalProfit = bets.fold<double>(0, (sum, item) => sum + item.netProfit);

    double bankrollMovement = 0;
    for (final tx in transactions) {
      if (tx.type == 'deposit') {
        bankrollMovement += tx.amount;
      } else if (tx.type == 'withdraw') {
        bankrollMovement -= tx.amount;
      }
    }

    final currentBankroll = startingBankroll + totalProfit + bankrollMovement;

    double currentDynamicMaxStake = 0;
    if (maxStakeMode == 'percent' && maxStakeValue > 0) {
      currentDynamicMaxStake = currentBankroll * (maxStakeValue / 100);
    } else {
      currentDynamicMaxStake = maxStakeValue;
    }

    final todayLoss = await BetService.getDailyLossForDate(DateTime.now());

    bool isLockedForToday = false;
    if (disciplineMode == 'lock_day' &&
        dailyLossLimit > 0 &&
        todayLoss >= dailyLossLimit) {
      isLockedForToday = true;
    }

    setState(() {
      _maxStakeMode = maxStakeMode;
      _maxStakeValue = maxStakeValue;
      _dailyLossLimit = dailyLossLimit;
      _targetBankroll = targetBankroll;
      _currentDynamicMaxStake = currentDynamicMaxStake;
      _disciplineMode = disciplineMode;
      _isLockedForToday = isLockedForToday;
      _todayLoss = todayLoss;
    });
  }

  double _calculateNetProfit({
    required double odd,
    required double stake,
    required String result,
  }) {
    switch (result) {
      case 'kazandi':
        return (odd * stake) - stake;
      case 'kaybetti':
        return -stake;
      case 'iade':
        return 0;
      case 'beklemede':
      default:
        return 0;
    }
  }

  void _refreshPreview() {
    if (mounted) {
      setState(() {});
    }
  }

  double? get _previewOdd =>
      double.tryParse(_oddController.text.replaceAll(',', '.'));

  double? get _previewStake =>
      double.tryParse(_stakeController.text.replaceAll(',', '.'));

  double get _previewNetProfit {
    final odd = _previewOdd;
    final stake = _previewStake;

    if (odd == null || stake == null) return 0;

    return _calculateNetProfit(
      odd: odd,
      stake: stake,
      result: _selectedResult,
    );
  }

  double get _previewPayout {
    final odd = _previewOdd;
    final stake = _previewStake;

    if (odd == null || stake == null) return 0;

    if (_selectedResult == 'kazandi') return odd * stake;
    if (_selectedResult == 'iade') return stake;

    return 0;
  }

  bool get _isPreviewLimitExceeded {
    final stake = _previewStake;
    if (stake == null) return false;
    if (_currentDynamicMaxStake <= 0) return false;
    return stake > _currentDynamicMaxStake;
  }

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

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  String _formatDate(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    final year = date.year.toString();
    return '$day.$month.$year';
  }

  String _maxStakeInfoText() {
    if (_currentDynamicMaxStake <= 0) return '';

    if (_maxStakeMode == 'percent') {
      return '• Maksimum bahis: %${_maxStakeValue.toStringAsFixed(1)} ≈ ${_currentDynamicMaxStake.toStringAsFixed(2)} ₺';
    }

    return '• Maksimum bahis: ${_currentDynamicMaxStake.toStringAsFixed(2)} ₺';
  }

  String _disciplineModeLabel() {
    switch (_disciplineMode) {
      case 'block_bet':
        return '• Disiplin modu: Limit aşılırsa bahis engellenir';
      case 'lock_day':
        return '• Disiplin modu: Limit aşılırsa gün kilitlenir';
      case 'warning':
      default:
        return '• Disiplin modu: Sadece uyarı';
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  Future<bool> _handleDailyLossLimitBeforeUpdate({
    required double stake,
  }) async {
    if (_dailyLossLimit <= 0) {
      return true;
    }

    final isTodayBet = _isSameDay(_selectedDate, DateTime.now());
    if (!isTodayBet) {
      return true;
    }

    final todayLoss = await BetService.getDailyLossForDate(DateTime.now());

    if (!mounted) return false;

    double adjustedTodayLoss = todayLoss;

    if (_isSameDay(widget.bet.date, DateTime.now()) &&
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
          'Günlük kayıp limiti zaten aşıldı. Bu bahis güncellenemez.',
        );
        return false;
      }

      if (_disciplineMode == 'lock_day') {
        setState(() {
          _isLockedForToday = true;
        });
        _showMessage(
          'Günlük kayıp limiti aşıldı. Bugün bahis kapandı.',
        );
        return false;
      }

      _showMessage(
        'Uyarı: Günlük kayıp limiti zaten aşılmış durumda.',
      );
      return true;
    }

    if (_selectedResult == 'kaybetti') {
      final projectedLoss = adjustedTodayLoss + stake;

      if (projectedLoss > _dailyLossLimit) {
        if (_disciplineMode == 'block_bet') {
          _showMessage(
            'Bu güncelleme günlük kayıp limitini aşıyor. Limit: ${_dailyLossLimit.toStringAsFixed(2)} ₺',
          );
          return false;
        }

        if (_disciplineMode == 'lock_day') {
          setState(() {
            _isLockedForToday = true;
          });
          _showMessage(
            'Bu güncelleme günlük kayıp limitini aşıyor. Bugün bahis kapandı.',
          );
          return false;
        }

        _showMessage(
          'Uyarı: Bu güncelleme günlük kayıp limitini aşıyor. Limit: ${_dailyLossLimit.toStringAsFixed(2)} ₺',
        );
      }
    }

    return true;
  }

  Future<bool> _handleMaxStakeLimitBeforeUpdate({
    required double stake,
  }) async {
    if (_currentDynamicMaxStake <= 0 || stake <= _currentDynamicMaxStake) {
      return true;
    }

    final limitText = _maxStakeMode == 'percent'
        ? '%${_maxStakeValue.toStringAsFixed(1)} moduna göre limit: ${_currentDynamicMaxStake.toStringAsFixed(2)} ₺'
        : 'Limit: ${_currentDynamicMaxStake.toStringAsFixed(2)} ₺';

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

    final odd = double.tryParse(_oddController.text.replaceAll(',', '.'));
    final stake = double.tryParse(_stakeController.text.replaceAll(',', '.'));

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
      matchName: matchName,
      betType: _betTypeController.text.trim(),
      odd: odd,
      stake: stake,
      result: _selectedResult,
      netProfit: _calculateNetProfit(
        odd: odd,
        stake: stake,
        result: _selectedResult,
      ),
      note: _noteController.text.trim(),
      createdAt: widget.bet.createdAt,
    );

    final result = await BetService.updateBet(updatedBet);

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (result != null) {
      _showMessage(result);
      return;
    }

    await _loadTeamSuggestions();

    _showMessage('Bahis güncellendi.');
    Navigator.pop(context);
  }

  Future<void> _deleteBet() async {
    if (widget.bet.id == null) {
      _showMessage('Silinecek bahis bulunamadı.');
      return;
    }

    setState(() => _isDeleting = true);

    final result = await BetService.deleteBet(
      userId: widget.bet.userId,
      betId: widget.bet.id!,
    );

    if (!mounted) return;
    setState(() => _isDeleting = false);

    if (result != null) {
      _showMessage(result);
      return;
    }

    _showMessage('Bahis silindi.');
    Navigator.pop(context);
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
              color: const Color(0xFF161A23),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      if (_isLockedForToday)
                        Container(
                          width: double.infinity,
                          margin: const EdgeInsets.only(bottom: 16),
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: const Color(0xFFDC2626).withOpacity(0.12),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: const Color(0xFFDC2626).withOpacity(0.35),
                            ),
                          ),
                          child: const Text(
                            'Bugün bahis kilitli. Disiplin modu aktif.',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Color(0xFFFCA5A5),
                            ),
                          ),
                        ),
                      if (_currentDynamicMaxStake > 0 ||
                          _dailyLossLimit > 0 ||
                          _targetBankroll > 0)
                        Container(
                          width: double.infinity,
                          margin: const EdgeInsets.only(bottom: 16),
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: _isPreviewLimitExceeded
                                ? const Color(0xFFDC2626).withOpacity(0.12)
                                : const Color(0xFF1F2937),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: _isPreviewLimitExceeded
                                  ? const Color(0xFFDC2626).withOpacity(0.35)
                                  : const Color(0xFF374151),
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Canlı Hesap',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 10),
                              Text(
                                '• Net Etki: ${_previewNetProfit.toStringAsFixed(2)} ₺',
                                style: TextStyle(
                                  color: _previewNetProfit > 0
                                      ? const Color(0xFF22C55E)
                                      : _previewNetProfit < 0
                                      ? const Color(0xFFEF4444)
                                      : const Color(0xFFF59E0B),
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                '• Toplam Ödeme: ${_previewPayout.toStringAsFixed(2)} ₺',
                              ),
                              if (_currentDynamicMaxStake > 0)
                                Text(
                                  '• Max: ${_currentDynamicMaxStake.toStringAsFixed(2)} ₺',
                                ),
                              if (_isPreviewLimitExceeded)
                                const Text(
                                  '• Limit aşıldı',
                                  style: TextStyle(
                                    color: Color(0xFFFCA5A5),
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                            ],
                          ),
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
                                  child: Text(country),
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
                          const SizedBox(width: 12),
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
                                  child: Text(league),
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
                      ),
                      const SizedBox(height: 14),
                      Row(
                        children: [
                          Expanded(
                            child: _buildTeamAutocompleteField(
                              controller: _homeTeamController,
                              label: 'Ev Sahibi',
                              hint: 'Örn: Galatasaray',
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildTeamAutocompleteField(
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
                              hint: _currentDynamicMaxStake > 0
                                  ? 'Max ${_currentDynamicMaxStake.toStringAsFixed(0)}'
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
                          child: Text(_formatDate(_selectedDate)),
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
                        child: _isLoading
                            ? const SizedBox(
                          height: 22,
                          width: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                            : const Text('Güncelle'),
                      ),
                      const SizedBox(height: 12),
                      ElevatedButton(
                        onPressed:
                        (_isLoading || _isDeleting) ? null : _deleteBet,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFDC2626),
                        ),
                        child: _isDeleting
                            ? const SizedBox(
                          height: 22,
                          width: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                            : const Text('Sil'),
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
    required TextEditingController controller,
    required String label,
    required String hint,
  }) {
    return Autocomplete<String>(
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