import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

class NotificationService {
  static final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  static const String alarmChannelId = 'secbrain_alarms';
  static const String alarmChannelName = 'SecBrain Alarm & Pengingat';
  static const String alarmChannelDesc =
      'Alarm berdering dan bergetar untuk tenggat waktu tugas, agenda, jadwal kuliah, dan tagihan';

  static bool _initialized = false;

  /// Inisialisasi service notifikasi & channel alarm Android dengan prioritas maksimal
  static Future<void> init() async {
    if (_initialized) return;

    try {
      tz.initializeTimeZones();
      // Konfigurasi timezone default Asia/Jakarta (WIB) atau fallback ke local
      try {
        tz.setLocalLocation(tz.getLocation('Asia/Jakarta'));
      } catch (_) {
        // Gunakan local timezone default jika zona spesifik tidak tersedia
      }

      const AndroidInitializationSettings initializationSettingsAndroid =
          AndroidInitializationSettings('@mipmap/ic_launcher');

      const DarwinInitializationSettings initializationSettingsIOS =
          DarwinInitializationSettings(
            requestAlertPermission: true,
            requestBadgePermission: true,
            requestSoundPermission: true,
            defaultPresentAlert: true,
            defaultPresentBadge: true,
            defaultPresentSound: true,
          );

      const WindowsInitializationSettings initializationSettingsWindows =
          WindowsInitializationSettings(
            appName: 'SecBrain',
            appUserModelId: 'com.secbrain.app',
            guid: '2f3d1f10-c5b5-43d4-85f2-0f0003d5d1d0',
          );

      const InitializationSettings initializationSettings =
          InitializationSettings(
            android: initializationSettingsAndroid,
            iOS: initializationSettingsIOS,
            windows: initializationSettingsWindows,
          );

      await _notificationsPlugin.initialize(
        settings: initializationSettings,
        onDidReceiveNotificationResponse: (details) {
          debugPrint('Notification clicked: ${details.payload}');
        },
      );

      // Konfigurasi Channel Alarm Android (Max Importance, Sound, Vibration, Lights, FullScreen)
      final androidImplementation = _notificationsPlugin
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >();

      if (androidImplementation != null) {
        // Request izin notifikasi Android 13+
        await androidImplementation.requestNotificationsPermission();

        // Request izin exact alarms Android 12+
        await androidImplementation.requestExactAlarmsPermission();

        // Buat Android Notification Channel berprioritas tinggi
        final AndroidNotificationChannel channel = AndroidNotificationChannel(
          alarmChannelId,
          alarmChannelName,
          description: alarmChannelDesc,
          importance: Importance.max,
          playSound: true,
          enableVibration: true,
          enableLights: true,
          showBadge: true,
          vibrationPattern: Int64List.fromList([0, 500, 200, 500, 200, 500]),
        );

        await androidImplementation.createNotificationChannel(channel);
      }

      _initialized = true;
      debugPrint('NotificationService: Berhasil diinisialisasi dengan Alarm Channel.');
    } catch (e, stackTrace) {
      debugPrint('NotificationService init error: $e');
      debugPrintStack(stackTrace: stackTrace);
    }
  }

  /// Detail notifikasi alarm dengan getar dan suara keras
  static NotificationDetails get _alarmNotificationDetails {
    final vibrationPattern = Int64List.fromList([0, 600, 250, 600, 250, 600]);
    return NotificationDetails(
      android: AndroidNotificationDetails(
        alarmChannelId,
        alarmChannelName,
        channelDescription: alarmChannelDesc,
        importance: Importance.max,
        priority: Priority.max,
        playSound: true,
        enableVibration: true,
        vibrationPattern: vibrationPattern,
        fullScreenIntent: true,
        category: AndroidNotificationCategory.alarm,
        audioAttributesUsage: AudioAttributesUsage.alarm,
        visibility: NotificationVisibility.public,
        styleInformation: const BigTextStyleInformation(''),
      ),
      iOS: const DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
        interruptionLevel: InterruptionLevel.timeSensitive,
      ),
    );
  }

  /// Menjadwalkan alarm notifikasi tepat waktu (Exact Alarm)
  static Future<void> scheduleNotification({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledDate,
  }) async {
    final now = DateTime.now();
    if (scheduledDate.isBefore(now)) return;

    try {
      try {
        tz.initializeTimeZones();
      } catch (_) {}
      tz.Location location;
      try {
        location = tz.local;
      } catch (_) {
        try {
          location = tz.getLocation('Asia/Jakarta');
        } catch (_) {
          location = tz.UTC;
        }
      }
      final tzScheduled = tz.TZDateTime.from(scheduledDate, location);

      await _notificationsPlugin.zonedSchedule(
        id: id,
        title: title,
        body: body,
        scheduledDate: tzScheduled,
        notificationDetails: _alarmNotificationDetails,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      );

      debugPrint(
        'NotificationService: Alarm berhasil dijadwalkan [ID: $id] pada $scheduledDate ("$title")',
      );
    } catch (e) {
      debugPrint('NotificationService schedule error ($id): $e');
    }
  }

  /// Mengirimkan notifikasi / alarm instan langsung (untuk pengujian atau peringatan segera)
  static Future<void> showInstantNotification({
    int id = 9999,
    String title = '⏰ SecBrain Alarm Aktif',
    String body = 'Sistem notifikasi dan alarm pengingat berhasil diaktifkan dengan suara dan getar!',
  }) async {
    try {
      await _notificationsPlugin.show(
        id: id,
        title: title,
        body: body,
        notificationDetails: _alarmNotificationDetails,
      );
      debugPrint('NotificationService: Notifikasi instan terkirim.');
    } catch (e) {
      debugPrint('NotificationService showInstantNotification error: $e');
    }
  }

  /// Menjadwalkan 3 level pengingat untuk tugas/agenda: H-1 Hari, 1 Jam Sebelum, dan Waktu Deadline
  static Future<List<int>> scheduleTaskReminders({
    required String taskId,
    required String taskTitle,
    required DateTime deadline,
  }) async {
    List<int> notificationIds = [];
    final baseId = taskId.hashCode.abs();

    final now = DateTime.now();

    // 1. Pengingat H-1 Hari (24 Jam Sebelum)
    final hMinus1 = deadline.subtract(const Duration(days: 1));
    if (hMinus1.isAfter(now)) {
      final idH1 = baseId % 1000000 + 1;
      await scheduleNotification(
        id: idH1,
        title: '📌 H-1 Deadline: $taskTitle',
        body: 'Tugas ini besok harus selesai. Jangan lupa disiapkan!',
        scheduledDate: hMinus1,
      );
      notificationIds.add(idH1);
    }

    // 2. Pengingat 1 Jam Sebelum (H-1 Jam)
    final hMinus1Hour = deadline.subtract(const Duration(hours: 1));
    if (hMinus1Hour.isAfter(now)) {
      final id1H = baseId % 1000000 + 2;
      await scheduleNotification(
        id: id1H,
        title: '⏰ 1 Jam Lagi: $taskTitle',
        body: 'Tenggat waktu tersisa 1 jam lagi! Segera selesaikan tugas Anda.',
        scheduledDate: hMinus1Hour,
      );
      notificationIds.add(id1H);
    }

    // 3. Alarm Tepat Saat Waktu Deadline Tiba
    if (deadline.isAfter(now)) {
      final idDeadline = baseId % 1000000 + 3;
      await scheduleNotification(
        id: idDeadline,
        title: '🚨 Deadline Sekarang: $taskTitle',
        body: 'Waktu pengumpulan/deadline telah tiba!',
        scheduledDate: deadline,
      );
      notificationIds.add(idDeadline);
    }

    return notificationIds;
  }

  /// Menjadwalkan pengingat jadwal kuliah mingguan (H-15 menit sebelum kelas)
  static Future<void> scheduleClassReminder({
    required String courseName,
    required String day,
    required String startTime,
    required String room,
    required String lecturer,
  }) async {
    final dayOfWeekMap = {
      'Senin': DateTime.monday,
      'Selasa': DateTime.tuesday,
      'Rabu': DateTime.wednesday,
      'Kamis': DateTime.thursday,
      'Jumat': DateTime.friday,
      'Sabtu': DateTime.saturday,
      'Minggu': DateTime.sunday,
    };

    final targetWeekday = dayOfWeekMap[day] ?? DateTime.monday;
    final now = DateTime.now();

    final parts = startTime.split(':');
    final hour = parts.isNotEmpty ? int.tryParse(parts[0]) ?? 8 : 8;
    final minute = parts.length > 1 ? int.tryParse(parts[1]) ?? 0 : 0;

    int daysUntil = (targetWeekday - now.weekday) % 7;
    var targetDate = DateTime(
      now.year,
      now.month,
      now.day + daysUntil,
      hour,
      minute,
    ).subtract(const Duration(minutes: 15));

    if (targetDate.isBefore(now)) {
      targetDate = targetDate.add(const Duration(days: 7));
    }

    final id = ('class_${courseName}_$day').hashCode.abs() % 1000000;
    await scheduleNotification(
      id: id,
      title: '🎓 Kelas 15 Menit Lagi: $courseName',
      body: 'Ruang: $room | Dosen: $lecturer. Siapkan materi kuliah Anda.',
      scheduledDate: targetDate,
    );
  }

  /// Menjadwalkan pengingat tagihan bulanan
  static Future<void> scheduleBillReminder({
    required String billTitle,
    required double amount,
    required int dueDay,
  }) async {
    final now = DateTime.now();
    var targetDate = DateTime(now.year, now.month, dueDay.clamp(1, 28), 9, 0);
    if (targetDate.isBefore(now)) {
      targetDate = DateTime(now.year, now.month + 1, dueDay.clamp(1, 28), 9, 0);
    }

    final id = ('bill_$billTitle').hashCode.abs() % 1000000;
    await scheduleNotification(
      id: id,
      title: '💳 Jatuh Tempo Tagihan: $billTitle',
      body: 'Segera lakukan pembayaran bulanan sebesar Rp ${amount.round()}.',
      scheduledDate: targetDate,
    );
  }

  /// Membatalkan alarm / notifikasi
  static Future<void> cancelNotifications(List<int> notificationIds) async {
    for (int id in notificationIds) {
      await _notificationsPlugin.cancel(id: id);
    }
  }

  /// Membatalkan seluruh notifikasi
  static Future<void> cancelAll() async {
    await _notificationsPlugin.cancelAll();
  }
}
