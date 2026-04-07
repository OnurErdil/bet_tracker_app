import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class UserService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  static String? get currentUserId => FirebaseAuth.instance.currentUser?.uid;

  static DocumentReference<Map<String, dynamic>> _userDoc(String userId) {
    return _firestore.collection('users').doc(userId);
  }

  static Stream<Map<String, dynamic>?> getUserProfile() {
    final userId = currentUserId;

    if (userId == null) {
      return const Stream.empty();
    }

    return _userDoc(userId).snapshots().map((doc) => doc.data());
  }

  static Future<Map<String, dynamic>?> getUserProfileOnce() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return null;

      final doc = await _userDoc(user.uid).get();
      return doc.data();
    } catch (_) {
      return null;
    }
  }

  static Future<String?> updateStartingBankroll(double amount) async {
    try {
      final user = FirebaseAuth.instance.currentUser;

      if (user == null) {
        return 'Kullanıcı bulunamadı.';
      }

      await _userDoc(user.uid).set({
        'email': user.email,
        'startingBankroll': amount,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      return null;
    } catch (e) {
      return 'Başlangıç kasası kaydedilirken hata oluştu: $e';
    }
  }

  static Future<String?> updateDisciplineSettings({
    required String maxStakeMode, // fixed | percent
    required double maxStakeValue,
    required double dailyLossLimit,
    required double targetBankroll,
    required String disciplineMode, // warning | block_bet | lock_day
  }) async {
    try {
      final user = FirebaseAuth.instance.currentUser;

      if (user == null) {
        return 'Kullanıcı bulunamadı.';
      }

      await _userDoc(user.uid).set({
        'email': user.email,
        'maxStakeMode': maxStakeMode,
        'maxStakeValue': maxStakeValue,
        'dailyLossLimit': dailyLossLimit,
        'targetBankroll': targetBankroll,
        'disciplineMode': disciplineMode,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      return null;
    } catch (e) {
      return 'Disiplin ayarları kaydedilirken hata oluştu: $e';
    }
  }

  static Future<String?> resetStartingBankroll() async {
    try {
      final user = FirebaseAuth.instance.currentUser;

      if (user == null) {
        return 'Kullanıcı bulunamadı.';
      }

      await _userDoc(user.uid).set({
        'startingBankroll': 0.0,
        'maxStakeMode': 'fixed',
        'maxStakeValue': 0.0,
        'dailyLossLimit': 0.0,
        'targetBankroll': 0.0,
        'disciplineMode': 'warning',
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      return null;
    } catch (e) {
      return 'Başlangıç kasası sıfırlanırken hata oluştu: $e';
    }
  }
}