import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

import '../models/class_schedule.dart';

/// Service Notifikasi Push Lokal & Alarm Terjadwal untuk Android
class NotificationService {
  NotificationService._();
  static final NotificationService instance = NotificationService._();

  final FlutterLocalNotificationsPlugin _notifications = FlutterLocalNotificationsPlugin();
  bool _isInitialized = false;

  /// Inisialisasi plugin notifikasi dan setup timezone
  Future<void> init() async {
    if (_isInitialized) return;

    try {
      tz.initializeTimeZones();
      try {
        tz.setLocalLocation(tz.getLocation('Asia/Jakarta'));
      } catch (_) {
        tz.setLocalLocation(tz.local);
      }

      const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
      const iosSettings = DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
      );

      const initSettings = InitializationSettings(
        android: androidSettings,
        iOS: iosSettings,
      );

      await _notifications.initialize(
        settings: initSettings,
        onDidReceiveNotificationResponse: (response) {
          debugPrint('Notification clicked with payload: ${response.payload}');
        },
      );

      await requestPermissions();
      _isInitialized = true;
    } catch (e) {
      debugPrint('NotificationService init error: $e');
    }
  }

  /// Meminta izin notifikasi (Android 13+ & iOS)
  Future<bool> requestPermissions() async {
    if (kIsWeb) return false;

    try {
      final androidPlatform = _notifications.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
      if (androidPlatform != null) {
        final granted = await androidPlatform.requestNotificationsPermission();
        return granted ?? true;
      }
    } catch (e) {
      debugPrint('Permission request error: $e');
    }
    return true;
  }

  /// Menampilkan notifikasi instan langsung
  Future<void> showInstantNotification({
    required int id,
    required String title,
    required String body,
    String? payload,
  }) async {
    if (!_isInitialized) await init();

    const androidDetails = AndroidNotificationDetails(
      'fib_general_channel',
      'Pengumuman & Agenda FIB',
      channelDescription: 'Notifikasi umum agenda dan kegiatan kampus FIB UNDIP',
      importance: Importance.high,
      priority: Priority.high,
      showWhen: true,
      icon: '@mipmap/ic_launcher',
    );

    const details = NotificationDetails(android: androidDetails);
    await _notifications.show(
      id: id,
      title: title,
      body: body,
      notificationDetails: details,
      payload: payload,
    );
  }

  /// Menjadwalkan pengingat jadwal kuliah (2 Jam Sebelum Kelas Dimulai)
  Future<void> scheduleWeeklyClassReminder({
    required int id,
    required String subject,
    required String room,
    required String time,
    required int dayOfWeek, // 1 = Senin ... 6 = Sabtu
  }) async {
    if (!_isInitialized) await init();

    try {
      // Parse waktu mulai kuliah (format: "HH:mm")
      final parts = time.split(':');
      if (parts.length < 2) return;
      int hour = int.tryParse(parts[0]) ?? 8;
      int minute = int.tryParse(parts[1]) ?? 0;

      // Hitung 2 jam sebelumnya
      hour = hour - 2;
      if (hour < 0) hour = hour + 24;

      final now = tz.TZDateTime.now(tz.local);
      tz.TZDateTime scheduledDate = tz.TZDateTime(
        tz.local,
        now.year,
        now.month,
        now.day,
        hour,
        minute,
      );

      // Sesuaikan hari dalam minggu (1 = Monday, 7 = Sunday)
      while (scheduledDate.weekday != dayOfWeek || scheduledDate.isBefore(now)) {
        scheduledDate = scheduledDate.add(const Duration(days: 1));
      }

      const androidDetails = AndroidNotificationDetails(
        'fib_class_schedule_channel',
        'Pengingat Kuliah FIB UNDIP',
        channelDescription: 'Pengingat otomatis 2 jam sebelum perkuliahan dimulai',
        importance: Importance.max,
        priority: Priority.high,
        icon: '@mipmap/ic_launcher',
        enableVibration: true,
      );

      const details = NotificationDetails(android: androidDetails);

      await _notifications.zonedSchedule(
        id: id,
        title: '⏰ 2 Jam Lagi: Kuliah $subject',
        body: 'Pukul $time di $room. Persiapkan buku dan materi kuliah Anda!',
        scheduledDate: scheduledDate,
        notificationDetails: details,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,
        payload: 'class_schedule_$id',
      );
    } catch (e) {
      debugPrint('Error scheduling class reminder: $e');
    }
  }

  /// Sinkronisasi seluruh jadwal perkuliahan aktif ke sistem Alarm Notifikasi Android
  Future<void> syncClassSchedules(List<ClassSchedule> schedules) async {
    if (kIsWeb) return;
    if (!_isInitialized) await init();

    try {
      for (final s in schedules) {
        if (s.reminderMinutes > 0 && s.startTime.isNotEmpty) {
          await scheduleWeeklyClassReminder(
            id: 1000 + s.id,
            subject: s.subject,
            room: s.room ?? 'Gedung FIB UNDIP',
            time: s.startTime,
            dayOfWeek: s.dayOfWeek,
          );
        }
      }
    } catch (e) {
      debugPrint('Error syncing class schedules to notifications: $e');
    }
  }

  /// Menjadwalkan pengingat harian SRS Review Flashcard (misal setiap jam 19:30)
  Future<void> scheduleDailySrsReminder({
    int hour = 19,
    int minute = 30,
    int dueCount = 0,
  }) async {
    if (kIsWeb) return;
    if (!_isInitialized) await init();

    try {
      final now = tz.TZDateTime.now(tz.local);
      tz.TZDateTime scheduledDate = tz.TZDateTime(
        tz.local,
        now.year,
        now.month,
        now.day,
        hour,
        minute,
      );

      if (scheduledDate.isBefore(now)) {
        scheduledDate = scheduledDate.add(const Duration(days: 1));
      }

      const androidDetails = AndroidNotificationDetails(
        'fib_srs_reminder_channel',
        'Pengingat Harian Review SRS',
        channelDescription: 'Pengingat review harian flashcard kanji & kosakata',
        importance: Importance.defaultImportance,
        priority: Priority.defaultPriority,
        icon: '@mipmap/ic_launcher',
      );

      const details = NotificationDetails(android: androidDetails);

      final title = dueCount > 0
          ? '🌸 $dueCount Kartu Kanji Menanti Review!'
          : '🌸 Waktunya Review Kanji & Kosakata Hari Ini';

      const body = 'Jaga streak belajar Anda dengan me-review flashcard SM-2 malam ini.';

      await _notifications.zonedSchedule(
        id: 9999, // ID tetap untuk pengingat harian
        title: title,
        body: body,
        scheduledDate: scheduledDate,
        notificationDetails: details,
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        matchDateTimeComponents: DateTimeComponents.time,
        payload: 'srs_review',
      );
    } catch (e) {
      debugPrint('Error scheduling daily SRS reminder: $e');
    }
  }

  /// Membatalkan notifikasi berdasarkan ID
  Future<void> cancel(int id) async {
    try {
      await _notifications.cancel(id: id);
    } catch (_) {}
  }

  /// Membatalkan semua notifikasi
  Future<void> cancelAll() async {
    try {
      await _notifications.cancelAll();
    } catch (_) {}
  }
}
