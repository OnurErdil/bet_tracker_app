import 'package:bet_tracker_app/services/service_helpers.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class UserService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  static String? get currentUserId => ServiceHelpers.currentUserId;

  static DocumentReference<Map<String, dynamic>> _userDoc(String userId) {
    return _firestore.collection('users').doc(userId);
  }

  static Map<String, dynamic> _withUserMeta({
    required String? email,
    required Map<String, dynamic> data,
  }) {
    return {
      'email': email,
      ...data,
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  static Future<String?> _setCurrentUserData({
    required Map<String, dynamic> data,
    required String errorPrefix,
  }) async {
    try {
      final user = ServiceHelpers.currentUser;

      if (user == null) {
        return ServiceHelpers.userNotFoundMessage;
      }

      await _userDoc(user.uid).set(
        _withUserMeta(
          email: user.email,
          data: data,
        ),
        SetOptions(merge: true),
      );

      return null;
    } catch (e) {
      return '$errorPrefix: $e';
    }
  }

  static Map<String, dynamic> _defaultDisciplineData() {
    return {
      'startingBankroll': 0.0,
      'maxStakeMode': 'fixed',
      'maxStakeValue': 0.0,
      'dailyLossLimit': 0.0,
      'targetBankroll': 0.0,
      'disciplineMode': 'warning',
      'highConfidenceEnabled': true,
      'confidence9Multiplier': 2.0,
      'confidence10Multiplier': 3.0,
    };
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
      final user = ServiceHelpers.currentUser;
      if (user == null) return null;

      final doc = await _userDoc(user.uid).get();
      return doc.data();
    } catch (_) {
      return null;
    }
  }

  static Future<String?> updateStartingBankroll(double amount) {
    return _setCurrentUserData(
      data: {
        'startingBankroll': amount,
      },
      errorPrefix: 'Başlangıç kasası kaydedilirken hata oluştu',
    );
  }

  static Future<String?> updateDisciplineSettings({
    required String maxStakeMode,
    required double maxStakeValue,
    required double dailyLossLimit,
    required double targetBankroll,
    required String disciplineMode,
    required bool highConfidenceEnabled,
    required double confidence9Multiplier,
    required double confidence10Multiplier,
  }) {
    return _setCurrentUserData(
      data: {
        'maxStakeMode': maxStakeMode,
        'maxStakeValue': maxStakeValue,
        'dailyLossLimit': dailyLossLimit,
        'targetBankroll': targetBankroll,
        'disciplineMode': disciplineMode,
        'highConfidenceEnabled': highConfidenceEnabled,
        'confidence9Multiplier': confidence9Multiplier,
        'confidence10Multiplier': confidence10Multiplier,
      },
      errorPrefix: 'Disiplin ayarları kaydedilirken hata oluştu',
    );
  }

  static Future<String?> resetStartingBankroll() {
    return _setCurrentUserData(
      data: _defaultDisciplineData(),
      errorPrefix: 'Başlangıç kasası sıfırlanırken hata oluştu',
    );
  }
}