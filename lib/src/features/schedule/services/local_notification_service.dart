import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:flutter/foundation.dart'; // for kIsWeb
import '../../../core/utils/app_logger.dart';
import 'alarm_callback_service.dart';

class LocalNotificationService {
  static final LocalNotificationService _instance =
      LocalNotificationService._internal();
  factory LocalNotificationService() => _instance;
  LocalNotificationService._internal();

  final FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  bool _initialized = false;

  String? _localTimezone;

  Future<void> initialize() async {
    if (_initialized) return;

    try {
      // 1. Initialize Timezones
      tz.initializeTimeZones();
      try {
        // FlutterTimezone.getLocalTimezone() returns a TimezoneInfo object
        // Its toString() format is: "TimezoneInfo(America/La_Paz, (locale: es_BO, name: hora de Bolivia))"
        // We need to extract just the timezone name (e.g., "America/La_Paz")
        final timezoneInfo = await FlutterTimezone.getLocalTimezone();
        final String rawTimezone = '$timezoneInfo';

        // Parse the timezone name from the string
        String timezoneName;
        if (rawTimezone.startsWith('TimezoneInfo(')) {
          // Extract: "TimezoneInfo(America/La_Paz, ...)" -> "America/La_Paz"
          final startIndex = 'TimezoneInfo('.length;
          final endIndex = rawTimezone.indexOf(',', startIndex);
          if (endIndex > startIndex) {
            timezoneName = rawTimezone.substring(startIndex, endIndex).trim();
          } else {
            timezoneName = rawTimezone
                .substring(startIndex, rawTimezone.length - 1)
                .trim();
          }
        } else {
          // If it's already a plain string like "America/La_Paz", use it directly
          timezoneName = rawTimezone;
        }

        AppLogger.info('[LocalNotification] Raw timezone info: $rawTimezone');
        AppLogger.info(
            '[LocalNotification] Parsed timezone name: $timezoneName');

        _localTimezone = timezoneName;
        tz.setLocalLocation(tz.getLocation(timezoneName));
        AppLogger.info('[LocalNotification] ✅ Timezone set to: $timezoneName');
        AppLogger.info(
            '[LocalNotification] Current local time: ${tz.TZDateTime.now(tz.local)}');
      } catch (e, stackTrace) {
        // Fallback to UTC if timezone fails
        AppLogger.warning(
            '[LocalNotification] ⚠️ Could not set local timezone, using UTC: $e');
        AppLogger.error(
            '[LocalNotification] Timezone error details', e, stackTrace);
        tz.setLocalLocation(tz.UTC);
        _localTimezone = 'UTC';
      }

      // 2. Android Initialization Settings
      const AndroidInitializationSettings initializationSettingsAndroid =
          AndroidInitializationSettings('@mipmap/ic_launcher');

      // 3. iOS/MacOS Initialization Settings (Darwin)
      const DarwinInitializationSettings initializationSettingsDarwin =
          DarwinInitializationSettings(
        requestAlertPermission: false,
        requestBadgePermission: false,
        requestSoundPermission: false,
      );

      // 4. Linux Initialization Settings
      const LinuxInitializationSettings initializationSettingsLinux =
          LinuxInitializationSettings(defaultActionName: 'Open notification');

      // 5. Shared Initialization Settings
      final InitializationSettings initializationSettings =
          InitializationSettings(
        android: initializationSettingsAndroid,
        iOS: initializationSettingsDarwin,
        macOS: initializationSettingsDarwin,
        linux: initializationSettingsLinux,
      );

      // 6. Initialize Plugin
      await _flutterLocalNotificationsPlugin.initialize(
        initializationSettings,
        onDidReceiveNotificationResponse: (NotificationResponse response) {
          AppLogger.info('Notification tapped: ${response.payload}');
          // Handle navigation if needed
        },
      );

      _initialized = true;
      AppLogger.info(
          '[LocalNotification] ✅ LocalNotificationService initialized');

      // Request permissions immediately after initialization
      final permissionGranted = await requestPermissions();
      AppLogger.info(
          '[LocalNotification] Permissions granted: $permissionGranted');
    } catch (e) {
      AppLogger.error('Error initializing LocalNotificationService', e);
    }
  }

  Future<bool> requestPermissions() async {
    if (kIsWeb) {
      AppLogger.info(
          '[LocalNotification] Web platform - no permissions needed');
      return false;
    }

    try {
      bool? notificationPermission = false;
      bool? exactAlarmPermission = false;

      final androidImplementation = _flutterLocalNotificationsPlugin
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();

      if (androidImplementation != null) {
        // Request notification permission (Android 13+)
        try {
          notificationPermission =
              await androidImplementation.requestNotificationsPermission();
          AppLogger.info(
              '[LocalNotification] 🔔 Notification permission: $notificationPermission');
        } catch (e) {
          AppLogger.warning(
              '[LocalNotification] ⚠️ Error requesting notification permission: $e');
        }

        // Request exact alarm permission (Android 12+)
        try {
          exactAlarmPermission =
              await androidImplementation.requestExactAlarmsPermission();
          AppLogger.info(
              '[LocalNotification] ⏰ Exact alarm permission: $exactAlarmPermission');
        } catch (e) {
          AppLogger.warning(
              '[LocalNotification] ⚠️ Error requesting exact alarm permission: $e');
        }

        // Check if notifications are enabled
        try {
          final areNotificationsEnabled =
              await androidImplementation.areNotificationsEnabled();
          AppLogger.info(
              '[LocalNotification] 📲 Notifications enabled in system: $areNotificationsEnabled');
          if (areNotificationsEnabled == false) {
            AppLogger.warning(
                '[LocalNotification] ❌ NOTIFICATIONS ARE DISABLED IN SYSTEM SETTINGS!');
          }
        } catch (e) {
          AppLogger.warning(
              '[LocalNotification] ⚠️ Could not check notification status: $e');
        }
      }

      final iosImplementation = _flutterLocalNotificationsPlugin
          .resolvePlatformSpecificImplementation<
              IOSFlutterLocalNotificationsPlugin>();

      if (iosImplementation != null) {
        notificationPermission = await iosImplementation.requestPermissions(
          alert: true,
          badge: true,
          sound: true,
        );
        AppLogger.info(
            '[LocalNotification] iOS permission: $notificationPermission');
      }

      final macosImplementation = _flutterLocalNotificationsPlugin
          .resolvePlatformSpecificImplementation<
              MacOSFlutterLocalNotificationsPlugin>();

      if (macosImplementation != null) {
        notificationPermission = await macosImplementation.requestPermissions(
          alert: true,
          badge: true,
          sound: true,
        );
        AppLogger.info(
            '[LocalNotification] macOS permission: $notificationPermission');
      }

      final result = notificationPermission ?? false;
      AppLogger.info('[LocalNotification] Final permission result: $result');
      return result;
    } catch (e, stackTrace) {
      AppLogger.error(
          '[LocalNotification] ❌ Error requesting permissions', e, stackTrace);
      return false;
    }
  }

  Future<void> scheduleNotification({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledDate,
    String? payload,
  }) async {
    if (!_initialized) {
      AppLogger.warning(
          '[LocalNotification] ⚠️ Service not initialized, initializing now...');
      await initialize();
    }

    try {
      // Convert to TZDateTime
      final tz.TZDateTime scheduledTZ =
          tz.TZDateTime.from(scheduledDate, tz.local);
      final tz.TZDateTime nowTZ = tz.TZDateTime.now(tz.local);

      // Debug logging
      AppLogger.info('[LocalNotification] 📅 Scheduling notification:');
      AppLogger.info('[LocalNotification]   ID: $id');
      AppLogger.info('[LocalNotification]   Title: $title');
      AppLogger.info('[LocalNotification]   Input DateTime: $scheduledDate');
      AppLogger.info('[LocalNotification]   Scheduled TZ: $scheduledTZ');
      AppLogger.info('[LocalNotification]   Current TZ: $nowTZ');
      AppLogger.info('[LocalNotification]   Timezone: $_localTimezone');
      AppLogger.info(
          '[LocalNotification]   Time until notification: ${scheduledTZ.difference(nowTZ).inMinutes} minutes');

      // For intervals less than 5 minutes, use Future.delayed as fallback
      // since zonedSchedule doesn't seem to work reliably on this device
      final delaySeconds = scheduledTZ.difference(nowTZ).inSeconds;
      if (delaySeconds > 0 && delaySeconds < 300) {
        // 5 minutes = 300 seconds
        AppLogger.info(
            '[LocalNotification] ⏱️ Using delayed show for interval: $delaySeconds sec');
        Future.delayed(Duration(seconds: delaySeconds), () async {
          await showNotification(
              id: id, title: title, body: body, payload: payload);
        });
        AppLogger.info(
            '[LocalNotification] ✅ Notification $id will show in $delaySeconds seconds');
        return;
      }

      // Check if time is in the past
      if (delaySeconds <= 0) {
        AppLogger.warning(
            '[LocalNotification] ⚠️ Scheduled time is in the past! Skipping.');
        return;
      }

      // For Android, use AlarmCallbackService which works even when app is closed
      if (!kIsWeb) {
        AppLogger.info(
            '[LocalNotification] 📅 Using AndroidAlarmManager for long interval: ${scheduledTZ.difference(nowTZ).inMinutes} min');

        final success = await AlarmCallbackService.scheduleAlarm(
          id: id,
          scheduledTime: scheduledDate,
          title: title,
          body: body,
          payload: payload,
        );

        if (success) {
          AppLogger.info(
              '[LocalNotification] ✅ Notification $id scheduled via AlarmManager for $scheduledTZ');
        } else {
          AppLogger.warning(
              '[LocalNotification] ⚠️ Failed to schedule via AlarmManager, falling back to zonedSchedule');
          // Fallback to zonedSchedule
          await _scheduleWithZonedSchedule(
              id, title, body, scheduledTZ, payload);
        }
        return;
      }

      // For web/other platforms, use zonedSchedule
      await _scheduleWithZonedSchedule(id, title, body, scheduledTZ, payload);
    } catch (e, stackTrace) {
      AppLogger.error(
          '[LocalNotification] ❌ Error scheduling notification', e, stackTrace);
    }
  }

  /// Fallback scheduling using zonedSchedule
  Future<void> _scheduleWithZonedSchedule(
    int id,
    String title,
    String body,
    tz.TZDateTime scheduledTZ,
    String? payload,
  ) async {
    const NotificationDetails platformChannelSpecifics = NotificationDetails(
      android: AndroidNotificationDetails(
        'atesur_notifications',
        'ATESUR Notifications',
        channelDescription: 'Notificaciones de programación y recordatorios',
        importance: Importance.max,
        priority: Priority.high,
        icon: '@mipmap/ic_launcher',
        playSound: true,
        enableVibration: true,
        visibility: NotificationVisibility.public,
        channelShowBadge: true,
      ),
      iOS: DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      ),
      macOS: DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      ),
    );

    await _flutterLocalNotificationsPlugin.zonedSchedule(
      id,
      title,
      body,
      scheduledTZ,
      platformChannelSpecifics,
      payload: payload,
      androidScheduleMode: AndroidScheduleMode.alarmClock,
    );

    AppLogger.info(
        '[LocalNotification] ✅ Notification $id scheduled via zonedSchedule for $scheduledTZ');
  }

  Future<void> showNotification({
    required int id,
    required String title,
    required String body,
    String? payload,
  }) async {
    if (!_initialized) {
      AppLogger.warning(
          '[LocalNotification] ⚠️ Service not initialized, initializing now...');
      await initialize();
    }

    try {
      AppLogger.info(
          '[LocalNotification] 🔔 Showing notification immediately:');
      AppLogger.info('[LocalNotification]   ID: $id, Title: $title');

      const NotificationDetails platformChannelSpecifics = NotificationDetails(
        android: AndroidNotificationDetails(
          'atesur_notifications', // Must match strings.xml ID
          'ATESUR Notifications',
          channelDescription: 'Notificaciones de programación y recordatorios',
          importance: Importance.max,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher', // Use launcher icon for compatibility
          playSound: true,
          enableVibration: true,
          visibility: NotificationVisibility.public,
          channelShowBadge: true,
        ),
        iOS: DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
        macOS: DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      );

      await _flutterLocalNotificationsPlugin.show(
        id,
        title,
        body,
        platformChannelSpecifics,
        payload: payload,
      );

      AppLogger.info(
          '[LocalNotification] ✅ Notification $id shown immediately');
    } catch (e, stackTrace) {
      AppLogger.error(
          '[LocalNotification] ❌ Error showing notification', e, stackTrace);
    }
  }

  Future<void> cancelNotification(int id) async {
    // Cancel both the alarm and any pending local notification
    if (!kIsWeb) {
      await AlarmCallbackService.cancelAlarm(id);
    }
    await _flutterLocalNotificationsPlugin.cancel(id);
    AppLogger.info('[LocalNotification] Notification $id canceled');
  }

  Future<void> cancelAllNotifications() async {
    await _flutterLocalNotificationsPlugin.cancelAll();
    AppLogger.info('[LocalNotification] All notifications canceled');
  }

  /// Test method: Shows a notification immediately
  Future<void> testNotificationNow() async {
    AppLogger.info('[LocalNotification] 🧪 Testing immediate notification...');
    await showNotification(
      id: 99999,
      title: '🧪 Test Notification',
      body: 'This is a test notification shown at ${DateTime.now()}',
    );
  }

  /// Test method: Schedules a notification for 10 seconds in the future
  Future<void> testScheduledNotification() async {
    AppLogger.info(
        '[LocalNotification] 🧪 Testing scheduled notification (10 seconds)...');
    final testTime = DateTime.now().add(const Duration(seconds: 10));
    await scheduleNotification(
      id: 99998,
      title: '🧪 Scheduled Test',
      body: 'This notification was scheduled for $testTime',
      scheduledDate: testTime,
    );
  }

  /// Get pending notifications count for debugging
  Future<List<PendingNotificationRequest>> getPendingNotifications() async {
    final pending =
        await _flutterLocalNotificationsPlugin.pendingNotificationRequests();
    AppLogger.info(
        '[LocalNotification] 📋 Pending notifications: ${pending.length}');
    for (final notification in pending) {
      AppLogger.info(
          '[LocalNotification]   - ID: ${notification.id}, Title: ${notification.title}');
    }
    return pending;
  }
}
