import 'package:bet_tracker_app/data/bet_form_catalog.dart';
import 'package:bet_tracker_app/data/bet_form_helpers.dart';
import 'package:bet_tracker_app/domain/bet_calculator.dart';
import 'package:bet_tracker_app/domain/bankroll_discipline_calculator.dart';
import 'package:bet_tracker_app/models/bankroll_transaction_model.dart';
import 'package:bet_tracker_app/models/bet_model.dart';
import 'package:bet_tracker_app/pages/bets/widgets/bet_form_status_widgets.dart';
import 'package:bet_tracker_app/pages/home/widgets/home_common_widgets.dart';
import 'package:bet_tracker_app/services/bankroll_service.dart';
import 'package:bet_tracker_app/services/bet_service.dart';
import 'package:bet_tracker_app/services/user_service.dart';
import 'package:bet_tracker_app/theme/app_design_tokens.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class AddBetPage extends StatefulWidget {
  const AddBetPage({super.key});

  @override
  State<AddBetPage> createState() => _AddBetPageState();
}

class _AddBetPageState extends State<AddBetPage> {
  final _formKey = GlobalKey<FormState>();

  final _sportController = TextEditingController();
  final _countryController = TextEditingController();
  final _leagueController = TextEditingController();
  final _homeTeamController = TextEditingController();
  final _awayTeamController = TextEditingController();
  final _betTypeController = TextEditingController();
  final _oddController = TextEditingController();
  final _stakeController = TextEditingController();
  final _noteController = TextEditingController();

  List<String> _recentTeams = [];
  List<String> _frequentTeams = [];


  DateTime _selectedDate = DateTime.now();
  String _selectedResult = 'beklemede';
  bool _isLoading = false;

  String _maxStakeMode = 'fixed';
  double _maxStakeValue = 0;
  double _dailyLossLimit = 0;
  double _targetBankroll = 0;
  double _currentDynamicMaxStake = 0;

  String _disciplineMode = 'warning'; // warning | block_bet | lock_day
  bool _isLockedForToday = false;
  double _todayLoss = 0;
  int _confidenceScore = 5;
  bool _highConfidenceEnabled = true;
  double _confidence9Multiplier =
      BankrollDisciplineCalculator.defaultConfidence9Multiplier;
  double _confidence10Multiplier =
      BankrollDisciplineCalculator.defaultConfidence10Multiplier;
  @override
  void initState() {
    super.initState();
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

  void _refreshPreview() {
    if (mounted) {
      setState(() {});
    }
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

  double? get _previewOdd {
    return double.tryParse(_oddController.text.trim().replaceAll(',', '.'));
  }

  double? get _previewStake {
    return double.tryParse(_stakeController.text.trim().replaceAll(',', '.'));
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

  bool get _isHighConfidenceSelected {
    return BankrollDisciplineCalculator.isHighConfidence(
      _confidenceScore,
      highConfidenceEnabled: _highConfidenceEnabled,
    );
  }
  double get _previewNetProfit {
    final odd = _previewOdd;
    final stake = _previewStake;

    if (odd == null || stake == null) return 0;

    return BetCalculator.calculateNetProfit(
      odd: odd,
      stake: stake,
      result: _selectedResult,
    );
  }

  double get _previewPayout {
    final odd = _previewOdd;
    final stake = _previewStake;

    if (odd == null || stake == null) return 0;

    return BetCalculator.calculatePayout(
      odd: odd,
      stake: stake,
      result: _selectedResult,
    );
  }

  bool get _isPreviewLimitExceeded {
    final stake = _previewStake;
    if (stake == null) return false;
    if (_effectiveMaxStake <= 0) return false;
    return stake > _effectiveMaxStake;
  }

  String get _previewResultLabel {
    return BetFormHelpers.buildPreviewResultLabel(_selectedResult);
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

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  Future<bool> _handleDailyLossLimitBeforeSave({
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

    setState(() {
      _todayLoss = todayLoss;
    });

    final alreadyExceeded = todayLoss >= _dailyLossLimit;

    if (alreadyExceeded) {
      if (_disciplineMode == 'block_bet') {
        _showMessage(
          'Günlük kayıp limiti zaten aşıldı. Yeni bahis eklenemez.',
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
      final projectedLoss = todayLoss + stake;

      if (projectedLoss > _dailyLossLimit) {
        if (_disciplineMode == 'block_bet') {
          _showMessage(
            'Bu kayıt günlük kayıp limitini aşıyor. Limit: ${_dailyLossLimit.toStringAsFixed(2)} ₺',
          );
          return false;
        }

        if (_disciplineMode == 'lock_day') {
          setState(() {
            _isLockedForToday = true;
          });
          _showMessage(
            'Bu kayıt günlük kayıp limitini aşıyor. Bugün bahis kapandı.',
          );
          return false;
        }

        _showMessage(
          'Uyarı: Bu kayıt günlük kayıp limitini aşıyor. Limit: ${_dailyLossLimit.toStringAsFixed(2)} ₺',
        );
      }
    }

    return true;
  }

  Future<bool> _handleMaxStakeLimitBeforeSave({
    required double stake,
  }) async {
    final effectiveLimit = _effectiveMaxStake;

    if (effectiveLimit <= 0 || stake <= effectiveLimit) {
      return true;
    }

    final limitText = _isHighConfidenceSelected
        ? 'Güven puanı $_confidenceScore için izin verilen limit: ${effectiveLimit.toStringAsFixed(2)} ₺'
        : _maxStakeMode == 'percent'
        ? '%${_maxStakeValue.toStringAsFixed(1)} moduna göre limit: ${effectiveLimit.toStringAsFixed(2)} ₺'
        : 'Limit: ${effectiveLimit.toStringAsFixed(2)} ₺';

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

  Future<void> _saveBet() async {
    FocusScope.of(context).unfocus();

    if (!_formKey.currentState!.validate()) return;

    if (_disciplineMode == 'lock_day' && _isLockedForToday) {
      _showMessage('Bugün bahis kapalı. Günlük disiplin kilidi aktif.');
      return;
    }

    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      _showMessage('Kullanıcı oturumu bulunamadı.');
      return;
    }

    final odd = double.tryParse(_oddController.text.replaceAll(',', '.'));
    final stake = double.tryParse(_stakeController.text.replaceAll(',', '.'));

    if (odd == null || stake == null) {
      _showMessage('Oran ve tutar sayısal olmalı.');
      return;
    }

    final dailyLossAllowed = await _handleDailyLossLimitBeforeSave(
      stake: stake,
    );
    if (!dailyLossAllowed) return;

    final maxStakeAllowed = await _handleMaxStakeLimitBeforeSave(
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

    final bet = BetModel(
      userId: user.uid,
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
      netProfit: BetCalculator.calculateNetProfit(
        odd: odd,
        stake: stake,
        result: _selectedResult,
      ),
      note: _noteController.text.trim(),
      createdAt: DateTime.now(),
      confidenceScore: _confidenceScore,
    );

    final result = await BetService.addBet(bet);

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (result != null) {
      _showMessage(result);
      return;
    }

    await _loadTeamSuggestions();

    _showMessage('Bahis başarıyla kaydedildi.');
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.of(context).size.width > 700;
    final previewNetProfit = _previewNetProfit;
    final previewPayout = _previewPayout;
    final previewNetColor = previewNetProfit > 0
        ? homeSuccessColor()
        : previewNetProfit < 0
        ? homeDangerColor()
        : homeWarningColor();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Yeni Bahis Ekle'),
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
                          maxStakeInfoText:
                          _currentDynamicMaxStake > 0
                              ? _maxStakeInfoText()
                              : '',
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
                        netProfit: previewNetProfit,
                        netColor: previewNetColor,
                        payout: previewPayout,
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
                            _betTypeController.text = '';
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
                        onPressed: (_isLoading || _isLockedForToday)
                            ? null
                            : _saveBet,
                        child: _isLoading
                            ? const SizedBox(
                          height: 22,
                          width: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                            : const Text('Bahsi Kaydet'),
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
        return _getSmartTeamSuggestions(textEditingValue.text).toList();
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