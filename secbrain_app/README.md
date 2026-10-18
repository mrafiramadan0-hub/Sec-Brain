# SecBrain Flutter

SecBrain adalah personal workspace Flutter dengan task, agenda, notes, finance, savings, investment lokal, dan memory log. Data inti saat ini disimpan offline melalui `shared_preferences`.

## Menjalankan aplikasi

```powershell
cd secbrain_app
flutter pub get
flutter run
```

Validasi lokal:

```powershell
flutter analyze
flutter test
flutter build web
```

Firebase CLI setup (run once):

```powershell
flutter pub add firebase_core firebase_auth cloud_firestore firebase_storage
dart pub global activate flutterfire_cli
$env:Path += ";$env:LOCALAPPDATA\Pub\Cache\bin"
flutterfire configure
```

## Menambahkan Push Notification

Gunakan Firebase Cloud Messaging untuk push dan `flutter_local_notifications` untuk reminder lokal ketika aplikasi sedang offline.

```powershell
flutter pub add firebase_core firebase_messaging flutter_local_notifications timezone
dart pub global activate flutterfire_cli
flutterfire configure
```

Urutan implementasi:

1. Inisialisasi Firebase di `main.dart` sebelum `runApp`.
2. Buat `NotificationService` yang meminta permission Android 13 dan iOS.
3. Saat task disimpan, jadwalkan tiga reminder: H-1, satu jam sebelum, dan waktu deadline.
4. Simpan `notificationIds` pada model `Task` agar reminder lama bisa dibatalkan saat task diedit atau dihapus.
5. Tambahkan Firebase Messaging handler untuk notifikasi yang dikirim server.

Reminder lokal tidak memerlukan server. Push lintas perangkat memerlukan Firebase Cloud Functions atau backend sendiri.

## Login dan Cloud Sync

```powershell
flutter pub add firebase_core firebase_auth cloud_firestore firebase_storage
flutterfire configure
```

Gunakan struktur Firestore berikut:

```text
users/{uid}/tasks/{taskId}
users/{uid}/notes/{noteId}
users/{uid}/transactions/{transactionId}
users/{uid}/memories/{memoryId}
users/{uid}/bills/{billId}
users/{uid}/investments/{investmentId}
```

Ganti `BrainStore.save()` dengan repository yang menulis ke Firestore, tetapi pertahankan cache `shared_preferences` untuk mode offline. Gunakan `uid` sebagai partition key dan jangan menyimpan API key di kode Flutter.

## Cover Otomatis dan Pencarian Karya

Tambahkan client HTTP dan fallback upload manual:

```powershell
flutter pub add http image_picker
```

Gunakan endpoint berikut melalui service terpisah, bukan langsung di widget:

- Film: TMDB API, simpan `poster_path` sebagai `coverUrl`.
- Anime: Jikan API sebagai wrapper publik MyAnimeList.
- Buku: Google Books Volumes API.

API key TMDB harus diberikan melalui `--dart-define=TMDB_API_KEY=...` atau backend proxy. `image_picker` dipakai untuk fallback upload manual, kemudian file disimpan ke Firebase Storage jika cloud sync sudah aktif.

## Harga Investasi Realtime

Buat `InvestmentPriceService` dengan `http` atau WebSocket ke provider pasar yang memiliki izin penggunaan data. Simpan `lastPrice`, `lastUpdated`, dan `snapshotStatus` pada model. Jangan menganggap harga seeded di aplikasi sebagai harga realtime. Token provider harus disimpan di backend atau secret manager.

## Urutan Pengerjaan

1. Firebase Auth dan Firestore untuk identitas serta sinkronisasi.
2. Local notification dan permission native.
3. TMDB/Jikan/Google Books dan upload cover.
4. Provider harga investasi dan refresh policy.
5. Test permission, offline sync, duplicate notification, dan API failure.

Konfigurasi eksternal tidak boleh di-commit ke repository. Gunakan file lokal untuk tooling development dan secret manager untuk production.
