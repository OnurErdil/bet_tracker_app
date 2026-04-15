import 'package:bet_tracker_app/services/bankroll_service.dart';
import 'package:bet_tracker_app/services/bet_service.dart';
import 'package:bet_tracker_app/services/user_service.dart';

class ResetService {
  static Future<String?> resetAllUserData() async {
    try {
      final betsResult = await _runStep(
        stepLabel: 'Bahisler',
        action: BetService.deleteAllUserBets,
      );
      if (betsResult != null) return betsResult;

      final bankrollResult = await _runStep(
        stepLabel: 'Kasa hareketleri',
        action: BankrollService.deleteAllTransactions,
      );
      if (bankrollResult != null) return bankrollResult;

      final userSettingsResult = await _runStep(
        stepLabel: 'Başlangıç kasası ve disiplin ayarları',
        action: UserService.resetStartingBankroll,
      );
      if (userSettingsResult != null) return userSettingsResult;

      return null;
    } catch (e) {
      return 'Tüm veriler sıfırlanırken beklenmeyen bir hata oluştu: $e';
    }
  }

  static Future<String?> _runStep({
    required String stepLabel,
    required Future<String?> Function() action,
  }) async {
    try {
      final result = await action();

      if (result != null) {
        return '$stepLabel adımında hata oluştu: $result';
      }

      return null;
    } catch (e) {
      return '$stepLabel adımında beklenmeyen bir hata oluştu: $e';
    }
  }
}