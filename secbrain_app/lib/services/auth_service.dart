import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';

class AuthService {
  static final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: ['email', 'profile'],
  );

  static FirebaseAuth? get _auth {
    try {
      if (Firebase.apps.isNotEmpty) {
        return FirebaseAuth.instance;
      }
    } catch (e) {
      debugPrint('Firebase Auth not available: $e');
    }
    return null;
  }

  static User? get currentUser => _auth?.currentUser;
  static bool get isLoggedIn => _auth?.currentUser != null;

  static Stream<User?> get authStateChanges {
    final auth = _auth;
    if (auth != null) {
      return auth.authStateChanges();
    }
    return Stream.value(null);
  }

  /// Login dengan Akun Google disertai batas waktu (timeout) 15 detik
  static Future<UserCredential?> signInWithGoogle() async {
    final auth = _auth;
    if (auth == null) {
      throw Exception('Firebase Auth belum dikonfigurasi.');
    }

    try {
      // 1. Pemanggilan Google Sign-In dengan timeout 15 detik
      final GoogleSignInAccount? googleUser = await _googleSignIn
          .signIn()
          .timeout(
            const Duration(seconds: 15),
            onTimeout: () => throw TimeoutException(
              'Waktu koneksi Google Sign-In habis (15 detik). Periksa koneksi internet atau konfigurasi SHA-1 Firebase.',
            ),
          );

      if (googleUser == null) {
        // Pengguna membatalkan dialog pemilihan akun Google
        return null;
      }

      // 2. Mengambil token autentikasi Google dengan timeout 15 detik
      final GoogleSignInAuthentication googleAuth = await googleUser
          .authentication
          .timeout(
            const Duration(seconds: 15),
            onTimeout: () => throw TimeoutException(
              'Gagal mengambil token autentikasi Google (timeout 15 detik).',
            ),
          );

      final OAuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // 3. Otentikasi ke Firebase dengan timeout 15 detik
      final userCredential = await auth
          .signInWithCredential(credential)
          .timeout(
            const Duration(seconds: 15),
            onTimeout: () => throw TimeoutException(
              'Gagal login, periksa koneksi atau konfigurasi SHA-1 Firebase.',
            ),
          );

      return userCredential;
    } on TimeoutException {
      rethrow;
    } catch (e) {
      debugPrint('Google Sign-In Error: $e');
      throw Exception(
        'Gagal login, periksa koneksi atau konfigurasi SHA-1 Firebase ($e)',
      );
    }
  }

  /// Pendaftaran akun dengan Email & Password dengan timeout 15 detik
  static Future<UserCredential?> signUpWithEmail({
    required String email,
    required String password,
    required String displayName,
  }) async {
    final auth = _auth;
    if (auth == null) {
      throw Exception('Firebase Auth belum dikonfigurasi.');
    }
    final credential = await auth
        .createUserWithEmailAndPassword(email: email, password: password)
        .timeout(
          const Duration(seconds: 15),
          onTimeout: () => throw TimeoutException(
            'Pendaftaran akun gagal (waktu habis 15 detik). Periksa koneksi internet.',
          ),
        );
    if (credential.user != null) {
      await credential.user!.updateDisplayName(displayName);
    }
    return credential;
  }

  /// Masuk dengan Email & Password dengan timeout 15 detik
  static Future<UserCredential?> signInWithEmail({
    required String email,
    required String password,
  }) async {
    final auth = _auth;
    if (auth == null) {
      throw Exception('Firebase Auth belum dikonfigurasi.');
    }
    return await auth
        .signInWithEmailAndPassword(email: email, password: password)
        .timeout(
          const Duration(seconds: 15),
          onTimeout: () => throw TimeoutException(
            'Gagal login, periksa koneksi atau konfigurasi Firebase (timeout 15 detik).',
          ),
        );
  }

  /// Keluar dari sesi (Google Sign-Out & Firebase Auth)
  static Future<void> signOut() async {
    final auth = _auth;
    try {
      if (await _googleSignIn.isSignedIn()) {
        await _googleSignIn.signOut();
      }
    } catch (e) {
      debugPrint('Google Sign-Out Error: $e');
    }
    if (auth != null) {
      await auth.signOut();
    }
  }
}
