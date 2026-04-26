import 'package:bet_tracker_app/data/bet_form_helpers.dart';
import 'package:bet_tracker_app/models/bet_model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  BetModel bet({
    required String matchName,
    String homeTeam = '',
    String awayTeam = '',
    int confidenceScore = 5,
  }) {
    return BetModel(
      userId: 'user-1',
      date: DateTime(2026, 4, 26),
      sport: 'Futbol',
      country: 'Türkiye',
      league: 'Süper Lig',
      homeTeam: homeTeam,
      awayTeam: awayTeam,
      matchName: matchName,
      betType: 'MS 1',
      odd: 2.0,
      stake: 100,
      result: 'beklemede',
      netProfit: 0,
      note: '',
      createdAt: DateTime(2026, 4, 26),
      confidenceScore: confidenceScore,
    );
  }

  group('BetFormHelpers parse/format', () {
    test('parseDecimalText virgüllü ve noktalı sayıları okur', () {
      expect(BetFormHelpers.parseDecimalText('2,45'), 2.45);
      expect(BetFormHelpers.parseDecimalText('2.45'), 2.45);
      expect(BetFormHelpers.parseDecimalText('abc'), null);
    });

    test('parseMatchName ev sahibi ve deplasmanı ayırır', () {
      final parsed = BetFormHelpers.parseMatchName('A Takımı - B Takımı - Ek');

      expect(parsed.homeTeam, 'A Takımı');
      expect(parsed.awayTeam, 'B Takımı - Ek');
    });

    test('formatShortDate tarihi kısa formata çevirir', () {
      final result = BetFormHelpers.formatShortDate(DateTime(2026, 4, 6));

      expect(result, '06.04.2026');
    });

    test('buildMatchName takımları trimleyerek maç adı üretir', () {
      final result = BetFormHelpers.buildMatchName(
        homeTeam: '  Kocaelispor ',
        awayTeam: ' Beşiktaş  ',
      );

      expect(result, 'Kocaelispor - Beşiktaş');
    });
  });

  group('BetFormHelpers preview', () {
    test('buildPreviewData kazanç, payout ve limit aşımı üretir', () {
      final preview = BetFormHelpers.buildPreviewData(
        oddText: '2,50',
        stakeText: '100',
        result: 'kazandi',
        effectiveMaxStake: 80,
      );

      expect(preview.odd, 2.5);
      expect(preview.stake, 100.0);
      expect(preview.netProfit, 150.0);
      expect(preview.payout, 250.0);
      expect(preview.isLimitExceeded, true);
      expect(preview.resultLabel, 'Kazanç Senaryosu');
    });

    test('buildPreviewData geçersiz sayı varsa sıfır değer üretir', () {
      final preview = BetFormHelpers.buildPreviewData(
        oddText: 'abc',
        stakeText: '100',
        result: 'kazandi',
        effectiveMaxStake: 200,
      );

      expect(preview.odd, null);
      expect(preview.stake, 100.0);
      expect(preview.netProfit, 0.0);
      expect(preview.payout, 0.0);
      expect(preview.isLimitExceeded, false);
    });
  });

  group('BetFormHelpers selection/team helpers', () {
    test('buildSelectionData spor, ülke, lig seçimine göre listeleri üretir', () {
      final data = BetFormHelpers.buildSelectionData(
        sport: 'Futbol',
        country: 'Türkiye',
        league: 'Süper Lig',
      );

      expect(data.availableCountries, contains('Türkiye'));
      expect(data.availableLeagues, contains('Süper Lig'));
      expect(data.availableTeams, contains('Kocaelispor'));
      expect(data.availableBetTypes, contains('MS 1'));
    });

    test('buildSmartTeamSuggestions son ve sık kullanılan takımları öne alır', () {
      final suggestions = BetFormHelpers.buildSmartTeamSuggestions(
        query: '',
        filteredTeams: ['Kocaelispor', 'Beşiktaş', 'Galatasaray'],
        recentTeams: ['Galatasaray'],
        frequentTeams: ['Kocaelispor'],
      );

      expect(suggestions.take(3).toList(), [
        'Galatasaray',
        'Kocaelispor',
        'Beşiktaş',
      ]);
    });

    test('extractTeamSuggestionData son ve sık takım listesi çıkarır', () {
      final data = BetFormHelpers.extractTeamSuggestionData([
        bet(matchName: 'Kocaelispor - Beşiktaş'),
        bet(matchName: 'Kocaelispor - Galatasaray'),
        bet(matchName: 'Fenerbahçe - Kocaelispor'),
      ]);

      expect(data.recentTeams, contains('Kocaelispor'));
      expect(data.frequentTeams.first, 'Kocaelispor');
    });
  });

  group('BetFormHelpers discipline messages', () {
    test('buildMaxStakeLimitText yüksek güven mesajı üretir', () {
      final result = BetFormHelpers.buildMaxStakeLimitText(
        isHighConfidenceSelected: true,
        confidenceScore: 9,
        maxStakeMode: 'fixed',
        maxStakeValue: 100,
        effectiveMaxStake: 200,
      );

      expect(result, 'Güven puanı 9 için izin verilen limit: 200.00 ₺');
    });

    test('buildDailyLossAlreadyExceededMessage modlara göre mesaj üretir', () {
      expect(
        BetFormHelpers.buildDailyLossAlreadyExceededMessage(
          disciplineMode: 'block_bet',
          blockMessage: 'Yeni bahis eklenemez.',
        ),
        'Günlük kayıp limiti zaten aşıldı. Yeni bahis eklenemez.',
      );

      expect(
        BetFormHelpers.buildDailyLossAlreadyExceededMessage(
          disciplineMode: 'lock_day',
          blockMessage: 'Yeni bahis eklenemez.',
        ),
        'Günlük kayıp limiti aşıldı. Bugün bahis kapandı.',
      );
    });

    test('buildProjectedDailyLossLimitMessage warning mesajı üretir', () {
      final result = BetFormHelpers.buildProjectedDailyLossLimitMessage(
        disciplineMode: 'warning',
        actionLabel: 'Bu kayıt',
        dailyLossLimit: 500,
      );

      expect(
        result,
        'Uyarı: Bu kayıt günlük kayıp limitini aşıyor. Limit: 500.00 ₺',
      );
    });
  });
}