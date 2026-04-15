import 'package:bet_tracker_app/models/bankroll_transaction_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class BankrollService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  static CollectionReference<Map<String, dynamic>> _ref(String userId) {
    return _firestore.collection('users').doc(userId).collection('bankroll');
  }

  static Future<String?> addTransaction(BankrollTransaction tx) async {
    try {
      await _ref(tx.userId).add(tx.toMap());
      return null;
    } catch (e) {
      return 'İşlem eklenemedi: $e';
    }
  }

  static Stream<List<BankrollTransaction>> getTransactions() {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return const Stream.empty();
    }

    return _ref(user.uid)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => BankrollTransaction.fromMap(doc.data(), doc.id))
          .toList();
    });
  }

  static Future<String?> updateTransaction(BankrollTransaction tx) async {
    try {
      if (tx.id == null) {
        return 'Güncellenecek işlem bulunamadı.';
      }

      await _ref(tx.userId).doc(tx.id).update(tx.toMap());
      return null;
    } catch (e) {
      return 'İşlem güncellenemedi: $e';
    }
  }

  static Future<String?> deleteTransaction({
    required String userId,
    required String transactionId,
  }) async {
    try {
      await _ref(userId).doc(transactionId).delete();
      return null;
    } catch (e) {
      return 'İşlem silinemedi: $e';
    }
  }

  static Future<String?> deleteAllTransactions() async {
    try {
      final user = FirebaseAuth.instance.currentUser;

      if (user == null) {
        return 'Kullanıcı bulunamadı.';
      }

      final snapshot = await _ref(user.uid).get();
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
      return 'Kasa hareketleri silinirken hata oluştu: $e';
    }
  }
}