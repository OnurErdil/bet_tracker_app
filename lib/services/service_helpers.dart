import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ServiceHelpers {
  static const String userNotFoundMessage = 'Kullanıcı bulunamadı.';
  static const int deleteBatchSize = 400;

  static User? get currentUser => FirebaseAuth.instance.currentUser;

  static String? get currentUserId => currentUser?.uid;

  static String? validateCurrentUserAccess(String userId) {
    final activeUserId = currentUserId;

    if (activeUserId == null) {
      return userNotFoundMessage;
    }

    if (activeUserId != userId) {
      return 'Bu işlem için yetkin yok.';
    }

    return null;
  }

  static String? validateDocumentId({
    required String? id,
    required String missingMessage,
  }) {
    if (id == null || id.trim().isEmpty) {
      return missingMessage;
    }

    return null;
  }

  static Future<void> deleteDocsInBatches({
    required FirebaseFirestore firestore,
    required List<QueryDocumentSnapshot<Map<String, dynamic>>> docs,
    int batchSize = deleteBatchSize,
  }) async {
    if (docs.isEmpty) return;

    for (int i = 0; i < docs.length; i += batchSize) {
      final batch = firestore.batch();
      final end = (i + batchSize > docs.length) ? docs.length : i + batchSize;

      for (final doc in docs.sublist(i, end)) {
        batch.delete(doc.reference);
      }

      await batch.commit();
    }
  }
}