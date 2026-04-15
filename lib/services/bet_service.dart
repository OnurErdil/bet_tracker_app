import 'package:bet_tracker_app/domain/bet_calculator.dart';
import 'package:bet_tracker_app/models/bet_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class BetService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  static CollectionReference<Map<String, dynamic>> _betsRef(String userId) {
    return _firestore.collection('users').doc(userId).collection('bets');
  }

  static Future<String?> addBet(BetModel bet) async {
    try {
      await _betsRef(bet.userId).add(bet.toMap());
      return null;
    } catch (e) {
      return 'Bahis kaydedilirken hata oluştu: $e';
    }
  }

  static Stream<List<BetModel>> getUserBets() {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return const Stream.empty();
    }

    return _betsRef(user.uid)
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
      if (bet.id == null) {
        return 'Güncellenecek bahis bulunamadı.';
      }

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
      await _betsRef(userId).doc(betId).delete();
      return null;
    } catch (e) {
      return 'Bahis silinirken hata oluştu: $e';
    }
  }

  static Future<String?> deleteAllUserBets() async {
    try {
      final user = FirebaseAuth.instance.currentUser;

      if (user == null) {
        return 'Kullanıcı bulunamadı.';
      }

      final snapshot = await _betsRef(user.uid).get();
      final docs = snapshot.docs;

      if (docs.isEmpty) {
        return null;
      }

      const deleteBatchSize = 400;

      for (int i = 0; i < docs.length; i += deleteBatchSize) {
        final batch = _firestore.batch();
        final end = (i + deleteBatchSize > docs.length)
            ? docs.length
            : i + deleteBatchSize;

        for (final doc in docs.sublist(i, end)) {
          batch.delete(doc.reference);
        }

        await batch.commit();
      }

      return null;
    } catch (e) {
      return 'Tüm bahisler silinirken hata oluştu: $e';
    }
  }
  static Future<double> getDailyLossForDate(DateTime date) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return 0;

    final startOfDay = DateTime(date.year, date.month, date.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));

    final snapshot = await _betsRef(user.uid)
        .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
        .where('date', isLessThan: Timestamp.fromDate(endOfDay))
        .get();

    double totalLoss = 0;

    for (final doc in snapshot.docs) {
      final data = doc.data();
      final result = data['result'] ?? '';
      final netProfit = (data['netProfit'] ?? 0).toDouble();

      if (result == 'kaybetti' && netProfit < 0) {
        totalLoss += netProfit.abs();
      }
    }

    return totalLoss;
  }

  static Future<String?> settleBetQuick({
    required BetModel bet,
    required String newResult,
  }) async {
    try {
      if (bet.id == null) {
        return 'Güncellenecek bahis bulunamadı.';
      }

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