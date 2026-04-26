import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';

class AuthService {
  static final FirebaseAuth _auth = FirebaseAuth.instance;
  static FirebaseAuth get auth => _auth;

  static Stream<User?> get authStateChanges => _auth.authStateChanges();

  static Future<String?> _runAuthAction({
    required Future<dynamic> Function() action,
    required String Function(Object error) fallbackMessage,
  }) async {
    try {
      await action();
      return null;
    } on FirebaseAuthException catch (e) {
      return _firebaseErrorMessage(e);
    } catch (e) {
      return fallbackMessage(e);
    }
  }

  static Future<String?> register({
    required String email,
    required String password,
  }) {
    return _runAuthAction(
      action: () {
        return _auth.createUserWithEmailAndPassword(
          email: email.trim(),
          password: password.trim(),
        );
      },
      fallbackMessage: (_) {
        return 'Kayıt sırasında beklenmeyen bir hata oluştu.';
      },
    );
  }

  static Future<String?> login({
    required String email,
    required String password,
  }) {
    return _runAuthAction(
      action: () {
        return _auth.signInWithEmailAndPassword(
          email: email.trim(),
          password: password.trim(),
        );
      },
      fallbackMessage: (_) {
        return 'Giriş sırasında beklenmeyen bir hata oluştu.';
      },
    );
  }

  static Future<String?> resetPassword(String email) {
    return _runAuthAction(
      action: () {
        return _auth.sendPasswordResetEmail(email: email.trim());
      },
      fallbackMessage: (_) {
        return 'Şifre sıfırlama sırasında hata oluştu.';
      },
    );
  }

  static Future<String?> signInWithGoogle() async {
    try {
      if (kIsWeb) {
        final GoogleAuthProvider googleProvider = GoogleAuthProvider();
        await _auth.signInWithPopup(googleProvider);
        return null;
      } else {
        final GoogleSignIn googleSignIn = GoogleSignIn();

        await googleSignIn.signOut();

        final GoogleSignInAccount? googleUser = await googleSignIn.signIn();

        if (googleUser == null) {
          return 'Google ile giriş iptal edildi.';
        }

        final GoogleSignInAuthentication googleAuth =
        await googleUser.authentication;

        final credential = GoogleAuthProvider.credential(
          accessToken: googleAuth.accessToken,
          idToken: googleAuth.idToken,
        );

        await _auth.signInWithCredential(credential);
        return null;
      }
    } on FirebaseAuthException catch (e) {
      return _firebaseErrorMessage(e);
    } catch (e) {
      return 'Google ile giriş sırasında hata oluştu: $e';
    }
  }

  static Future<void> logout() async {
    if (!kIsWeb) {
      await GoogleSignIn().signOut();
    }
    await _auth.signOut();
  }

  static String _firebaseErrorMessage(FirebaseAuthException e) {
    switch (e.code) {
      case 'email-already-in-use':
        return 'Bu e-posta adresi zaten kullanımda.';
      case 'invalid-email':
        return 'Geçerli bir e-posta adresi gir.';
      case 'weak-password':
        return 'Şifre çok zayıf. Daha güçlü bir şifre kullan.';
      case 'user-not-found':
        return 'Bu e-posta ile kayıtlı kullanıcı bulunamadı.';
      case 'wrong-password':
      case 'invalid-credential':
        return 'E-posta veya şifre hatalı.';
      case 'user-disabled':
        return 'Bu kullanıcı hesabı devre dışı bırakılmış.';
      case 'too-many-requests':
        return 'Çok fazla deneme yapıldı. Biraz sonra tekrar dene.';
      case 'network-request-failed':
        return 'İnternet bağlantını kontrol et.';
      case 'popup-closed-by-user':
        return 'Google giriş penceresi kapatıldı.';
      default:
        return e.message ?? 'Bir kimlik doğrulama hatası oluştu.';
    }
  }
}