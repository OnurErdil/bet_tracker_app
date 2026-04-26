import 'package:bet_tracker_app/models/bankroll_transaction_model.dart';
import 'package:bet_tracker_app/services/service_helpers.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class BankrollService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  static CollectionReference<Map<String, dynamic>> _ref(String userId) {
    return _firestore.collection('users').doc(userId).collection('bankroll');
  }

  static Future<String?> addTransaction(BankrollTransaction tx) async {
    try {
      final accessError = ServiceHelpers.validateCurrentUserAccess(tx.userId);
      if (accessError != null) return accessError;

      await _ref(tx.userId).add(tx.toMap());
      return null;
    } catch (e) {
      return 'İşlem eklenemedi: $e';
    }
  }

  static Stream<List<BankrollTransaction>> getTransactions() {
    final userId = ServiceHelpers.currentUserId;

    if (userId == null) {
      return const Stream.empty();
    }

    return _ref(userId)
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
      final idError = ServiceHelpers.validateDocumentId(
        id: tx.id,
        missingMessage: 'Güncellenecek işlem bulunamadı.',
      );
      if (idError != null) return idError;

      final accessError = ServiceHelpers.validateCurrentUserAccess(tx.userId);
      if (accessError != null) return accessError;

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
      final idError = ServiceHelpers.validateDocumentId(
        id: transactionId,
        missingMessage: 'Silinecek işlem bulunamadı.',
      );
      if (idError != null) return idError;

      final accessError = ServiceHelpers.validateCurrentUserAccess(userId);
      if (accessError != null) return accessError;

      await _ref(userId).doc(transactionId).delete();
      return null;
    } catch (e) {
      return 'İşlem silinemedi: $e';
    }
  }

  static Future<String?> deleteAllTransactions() async {
    try {
      final userId = ServiceHelpers.currentUserId;

      if (userId == null) {
        return ServiceHelpers.userNotFoundMessage;
      }

      final snapshot = await _ref(userId).get();

      await ServiceHelpers.deleteDocsInBatches(
        firestore: _firestore,
        docs: snapshot.docs,
      );

      return null;
    } catch (e) {
      return 'Kasa hareketleri silinirken hata oluştu: $e';
    }
  }
}