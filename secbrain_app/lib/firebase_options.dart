// File: lib/firebase_options.dart
// Dikonfigurasi untuk proyek Firebase: secbrain-c134d
// Web App ID: 1:21752903075:web:c67c5071adca519f749616

import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show TargetPlatform, defaultTargetPlatform, kIsWeb;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web;
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      case TargetPlatform.macOS:
        return macos;
      case TargetPlatform.windows:
        return windows;
      case TargetPlatform.linux:
        return linux;
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  // WEB — Konfigurasi utama dari Firebase Console
  // ─────────────────────────────────────────────────────────────────────────
  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyAKk0UohA0u6nGbHitX1SxbpMtIYVP8NaU',
    appId: '1:21752903075:web:c67c5071adca519f749616',
    messagingSenderId: '21752903075',
    projectId: 'secbrain-c134d',
    authDomain: 'secbrain-c134d.firebaseapp.com',
    storageBucket: 'secbrain-c134d.firebasestorage.app',
    measurementId: 'G-E57CG6CS2G',
  );

  // ─────────────────────────────────────────────────────────────────────────
  // WINDOWS — Desktop Flutter menggunakan Web SDK Firebase
  // ─────────────────────────────────────────────────────────────────────────
  static const FirebaseOptions windows = FirebaseOptions(
    apiKey: 'AIzaSyAKk0UohA0u6nGbHitX1SxbpMtIYVP8NaU',
    appId: '1:21752903075:web:c67c5071adca519f749616',
    messagingSenderId: '21752903075',
    projectId: 'secbrain-c134d',
    authDomain: 'secbrain-c134d.firebaseapp.com',
    storageBucket: 'secbrain-c134d.firebasestorage.app',
    measurementId: 'G-E57CG6CS2G',
  );

  // ─────────────────────────────────────────────────────────────────────────
  // LINUX — Desktop Flutter menggunakan Web SDK Firebase
  // ─────────────────────────────────────────────────────────────────────────
  static const FirebaseOptions linux = FirebaseOptions(
    apiKey: 'AIzaSyAKk0UohA0u6nGbHitX1SxbpMtIYVP8NaU',
    appId: '1:21752903075:web:c67c5071adca519f749616',
    messagingSenderId: '21752903075',
    projectId: 'secbrain-c134d',
    authDomain: 'secbrain-c134d.firebaseapp.com',
    storageBucket: 'secbrain-c134d.firebasestorage.app',
    measurementId: 'G-E57CG6CS2G',
  );

  // ─────────────────────────────────────────────────────────────────────────
  // ANDROID — Perlu mendaftarkan Android App terpisah di Firebase Console
  // Buka: Firebase Console → Project Settings → Add App → Android
  // Package name: com.example.secbrain_app
  // Lalu download google-services.json → taruh di android/app/
  // ─────────────────────────────────────────────────────────────────────────
  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyAanZUsy_OuedJGya4Fvt988stOU3h7gzs',
    appId: '1:21752903075:android:a83e37d8f594e4e3749616',
    messagingSenderId: '21752903075',
    projectId: 'secbrain-c134d',
    storageBucket: 'secbrain-c134d.firebasestorage.app',
  );

  // ─────────────────────────────────────────────────────────────────────────
  // iOS — Perlu mendaftarkan iOS App terpisah di Firebase Console
  // Buka: Firebase Console → Project Settings → Add App → iOS
  // Bundle ID: com.example.secbrainApp
  // Lalu download GoogleService-Info.plist → taruh di ios/Runner/
  // ─────────────────────────────────────────────────────────────────────────
  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyAKk0UohA0u6nGbHitX1SxbpMtIYVP8NaU',
    appId: '1:21752903075:ios:REPLACE_AFTER_REGISTER_IOS_APP',
    messagingSenderId: '21752903075',
    projectId: 'secbrain-c134d',
    storageBucket: 'secbrain-c134d.firebasestorage.app',
    iosBundleId: 'com.example.secbrainApp',
  );

  // ─────────────────────────────────────────────────────────────────────────
  // macOS — Menggunakan konfigurasi iOS
  // ─────────────────────────────────────────────────────────────────────────
  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'AIzaSyAKk0UohA0u6nGbHitX1SxbpMtIYVP8NaU',
    appId: '1:21752903075:ios:REPLACE_AFTER_REGISTER_IOS_APP',
    messagingSenderId: '21752903075',
    projectId: 'secbrain-c134d',
    storageBucket: 'secbrain-c134d.firebasestorage.app',
    iosBundleId: 'com.example.secbrainApp',
  );
}
