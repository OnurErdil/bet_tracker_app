import 'package:bet_tracker_app/domain/bet_calculator.dart';
import 'package:bet_tracker_app/models/bet_model.dart';
import 'package:bet_tracker_app/services/service_helpers.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class BetService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  static CollectionReference<Map<String, dynamic>> _betsRef(String userId) {
    return _firestore.collection('users').doc(userId).collection('bets');
  }

  static Future<String?> addBet(BetModel bet) async {
    try {
      final accessError = ServiceHelpers.validateCurrentUserAccess(bet.userId);
      if (accessError != null) return accessError;

      await _betsRef(bet.userId).add(bet.toMap());
      return null;
    } catch (e) {
      return 'Bahis kaydedilirken hata oluştu: $e';
    }
  }

  static Stream<List<BetModel>> getUserBets() {
    final userId = ServiceHelpers.currentUserId;

    if (userId == null) {
      return const Stream.empty();
    }

    return _betsRef(userId)
        .orderBy('date', descending: true)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return BetModel.fromMap(doc.data(), doc.id);
      }).toList();
    });
  }

  static Future<String?> updateBet(BetModel bet) async {
    try {
      final idError = ServiceHelpers.validateDocumentId(
        id: bet.id,
        missingMessage: 'Güncellenecek bahis bulunamadı.',
      );
      if (idError != null) return idError;

      final accessError = ServiceHelpers.validateCurrentUserAccess(bet.userId);
      if (accessError != null) return accessError;

      await _betsRef(bet.userId).doc(bet.id).update(bet.toMap());
      return null;
    } catch (e) {
      return 'Bahis güncellenirken hata oluştu: $e';
    }
  }

  static Future<String?> deleteBet({
    required String userId,
    required String betId,
  }) async {
    try {
      final idError = ServiceHelpers.validateDocumentId(
        id: betId,
        missingMessage: 'Silinecek bahis bulunamadı.',
      );
      if (idError != null) return idError;

      final accessError = ServiceHelpers.validateCurrentUserAccess(userId);
      if (accessError != null) return accessError;

      await _betsRef(userId).doc(betId).delete();
      return null;
    } catch (e) {
      return 'Bahis silinirken hata oluştu: $e';
    }
  }

  static Future<String?> deleteAllUserBets() async {
    try {
      final userId = ServiceHelpers.currentUserId;

      if (userId == null) {
        return ServiceHelpers.userNotFoundMessage;
      }

      final snapshot = await _betsRef(userId).get();

      await ServiceHelpers.deleteDocsInBatches(
        firestore: _firestore,
        docs: snapshot.docs,
      );

      return null;
    } catch (e) {
      return 'Tüm bahisler silinirken hata oluştu: $e';
    }
  }

  static Future<double> getDailyLossForDate(DateTime date) async {
    final userId = ServiceHelpers.currentUserId;
    if (userId == null) return 0;

    final startOfDay = DateTime(date.year, date.month, date.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));

    final snapshot = await _betsRef(userId)
        .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
        .where('date', isLessThan: Timestamp.fromDate(endOfDay))
        .get();

    double totalLoss = 0;

    for (final doc in snapshot.docs) {
      final bet = BetModel.fromMap(doc.data(), doc.id);

      if (bet.result == 'kaybetti' && bet.netProfit < 0) {
        totalLoss += bet.netProfit.abs();
      }
    }

    return totalLoss;
  }

  static Future<String?> settleBetQuick({
    required BetModel bet,
    required String newResult,
  }) async {
    try {
      final idError = ServiceHelpers.validateDocumentId(
        id: bet.id,
        missingMessage: 'Güncellenecek bahis bulunamadı.',
      );
      if (idError != null) return idError;

      final accessError = ServiceHelpers.validateCurrentUserAccess(bet.userId);
      if (accessError != null) return accessError;

      final updatedNetProfit = BetCalculator.calculateNetProfit(
        odd: bet.odd,
        stake: bet.stake,
        result: newResult,
      );

      await _betsRef(bet.userId).doc(bet.id).update({
        'result': newResult,
        'netProfit': updatedNetProfit,
      });

      return null;
    } catch (e) {
      return 'Bahis sonucu güncellenemedi: $e';
    }
  }
}