import 'dart:convert';
import 'dart:isolate';

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:android_alarm_manager_plus/android_alarm_manager_plus.dart';
import '../../../core/utils/app_logger.dart';

/// Service to handle alarm callbacks in background
/// When an alarm fires, this callback is executed even if the app is closed
class AlarmCallbackService {
  static const String _pendingAlarmsKey = 'pending_alarm_notifications';

  /// Store alarm data to SharedPreferences so callback can retrieve it
  static Future<void> storeAlarmData({
    required int alarmId,
    required String title,
    required String body,
    String? payload,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final pendingAlarms = prefs.getStringList(_pendingAlarmsKey) ?? [];

    final alarmData = jsonEncode({
      'id': alarmId,
      'title': title,
      'body': body,
      'payload': payload,
    });

    // Remove existing alarm with same ID if any
    pendingAlarms.removeWhere((data) {
      final decoded = jsonDecode(data);
      return decoded['id'] == alarmId;
    });

    pendingAlarms.add(alarmData);
    await prefs.setStringList(_pendingAlarmsKey, pendingAlarms);
  }

  /// Remove alarm data from SharedPreferences
  static Future<void> removeAlarmData(int alarmId) async {
    final prefs = await SharedPreferences.getInstance();
    final pendingAlarms = prefs.getStringList(_pendingAlarmsKey) ?? [];

    pendingAlarms.removeWhere((data) {
      final decoded = jsonDecode(data);
      return decoded['id'] == alarmId;
    });

    await prefs.setStringList(_pendingAlarmsKey, pendingAlarms);
  }

  /// Get alarm data by ID
  static Future<Map<String, dynamic>?> getAlarmData(int alarmId) async {
    final prefs = await SharedPreferences.getInstance();
    final pendingAlarms = prefs.getStringList(_pendingAlarmsKey) ?? [];

    for (final data in pendingAlarms) {
      final decoded = jsonDecode(data);
      if (decoded['id'] == alarmId) {
        return decoded;
      }
    }
    return null;
  }

  /// Initialize AlarmManager - call this in main()
  static Future<void> initialize() async {
    await AndroidAlarmManager.initialize();
    AppLogger.info('[AlarmCallback] AndroidAlarmManager initialized');
  }

  /// Schedule an alarm that will fire at the specified time
  static Future<bool> scheduleAlarm({
    required int id,
    required DateTime scheduledTime,
    required String title,
    required String body,
    String? payload,
  }) async {
    // Store the notification data
    await storeAlarmData(
      alarmId: id,
      title: title,
      body: body,
      payload: payload,
    );

    // Schedule the alarm
    final success = await AndroidAlarmManager.oneShotAt(
      scheduledTime,
      id,
      alarmCallback,
      exact: true,
      wakeup: true,
      alarmClock: true,
    );

    if (success) {
      AppLogger.info(
          '[AlarmCallback] ✅ Alarm $id scheduled for $scheduledTime');
    } else {
      AppLogger.warning('[AlarmCallback] ⚠️ Failed to schedule alarm $id');
    }

    return success;
  }

  /// Cancel a scheduled alarm
  static Future<void> cancelAlarm(int id) async {
    await AndroidAlarmManager.cancel(id);
    await removeAlarmData(id);
    AppLogger.info('[AlarmCallback] Alarm $id cancelled');
  }
}

/// Callback function that runs when alarm fires
/// MUST be a top-level function with @pragma annotation
@pragma('vm:entry-point')
Future<void> alarmCallback(int alarmId) async {
  print(
      '[AlarmCallback] 🔔 Alarm fired! ID: $alarmId, Isolate: ${Isolate.current.hashCode}');

  try {
    // Get the stored notification data
    final prefs = await SharedPreferences.getInstance();
    final pendingAlarms =
        prefs.getStringList('pending_alarm_notifications') ?? [];

    Map<String, dynamic>? alarmData;
    for (final data in pendingAlarms) {
      final decoded = jsonDecode(data);
      if (decoded['id'] == alarmId) {
        alarmData = decoded;
        break;
      }
    }

    if (alarmData == null) {
      print('[AlarmCallback] ⚠️ No data found for alarm $alarmId');
      return;
    }

    // Initialize flutter_local_notifications in this isolate
    final flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const InitializationSettings initializationSettings =
        InitializationSettings(
      android: initializationSettingsAndroid,
    );

    await flutterLocalNotificationsPlugin.initialize(initializationSettings);

    // Show the notification
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
      ),
    );

    await flutterLocalNotificationsPlugin.show(
      alarmId,
      alarmData['title'] as String,
      alarmData['body'] as String,
      platformChannelSpecifics,
      payload: alarmData['payload'] as String?,
    );

    print('[AlarmCallback] ✅ Notification shown: ${alarmData['title']}');

    // Remove the alarm data after showing notification
    pendingAlarms.removeWhere((data) {
      final decoded = jsonDecode(data);
      return decoded['id'] == alarmId;
    });
    await prefs.setStringList('pending_alarm_notifications', pendingAlarms);
  } catch (e, stackTrace) {
    print('[AlarmCallback] ❌ Error in alarm callback: $e');
    print(stackTrace);
  }
}
