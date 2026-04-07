import 'package:bet_tracker_app/services/bankroll_service.dart';
import 'package:bet_tracker_app/services/bet_service.dart';
import 'package:bet_tracker_app/services/user_service.dart';

class ResetService {
  static Future<String?> resetAllUserData() async {
    final betsResult = await BetService.deleteAllUserBets();
    if (betsResult != null) return betsResult;

    final bankrollResult = await BankrollService.deleteAllTransactions();
    if (bankrollResult != null) return bankrollResult;

    final startingBankrollResult = await UserService.resetStartingBankroll();
    if (startingBankrollResult != null) return startingBankrollResult;

    return null;
  }
}