import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

import '../../shared/models/user_model.dart';

/// Handles the local daily review reminder.
///
/// Call [initialize] once at app startup (before [runApp]).
/// Call [scheduleReviewReminder] whenever the user's profile or notification
/// preferences change — it cancels existing notifications and schedules a
/// daily reminder at the start of the user's notification window.
class NotificationService {
  NotificationService._();
  static final instance = NotificationService._();

  final _plugin = FlutterLocalNotificationsPlugin();

  static const _channelId = 'linguaboost_review';
  static const _channelName = 'Daily Review';
  static const _channelDesc = 'Daily phrase review reminders';
  static const _reminderId = 1;

  bool _initialized = false;

  // ── Lifecycle ──────────────────────────────────────────────────────────────

  Future<void> initialize() async {
    if (_initialized) return;
    _initialized = true;

    tz.initializeTimeZones();

    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const ios = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );
    await _plugin.initialize(
      settings: const InitializationSettings(android: android, iOS: ios),
    );

    await _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(const AndroidNotificationChannel(
          _channelId,
          _channelName,
          description: _channelDesc,
          importance: Importance.defaultImportance,
        ));
  }

  /// Requests notification permission (iOS prompt; Android 13+ runtime
  /// permission).
  Future<bool> requestPermission() async {
    final ios = _plugin
        .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin>();
    if (ios != null) {
      return await ios.requestPermissions(
            alert: true,
            badge: true,
            sound: true,
          ) ??
          false;
    }
    final android = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    if (android != null) {
      return await android.requestNotificationsPermission() ?? false;
    }
    return true;
  }

  // ── Scheduling ─────────────────────────────────────────────────────────────

  /// Cancels pending notifications and schedules one repeating daily reminder
  /// at the start of the user's notification window.
  ///
  /// Does nothing if [user.notificationsEnabled] is false.
  Future<void> scheduleReviewReminder(UserModel user) async {
    await _plugin.cancelAll();
    if (!user.notificationsEnabled) return;

    final now = DateTime.now();
    var slot = _parseHHMM(user.notificationStartTime, now);
    if (!slot.isAfter(now)) slot = slot.add(const Duration(days: 1));

    try {
      await _plugin.zonedSchedule(
        id: _reminderId,
        title: 'Time to review',
        body: 'You have phrases waiting for review. Keep your streak going!',
        scheduledDate: tz.TZDateTime.from(slot, tz.local),
        notificationDetails: const NotificationDetails(
          android: AndroidNotificationDetails(
            _channelId,
            _channelName,
            channelDescription: _channelDesc,
            importance: Importance.defaultImportance,
            priority: Priority.defaultPriority,
            icon: '@mipmap/ic_launcher',
          ),
          iOS: DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: false,
            presentSound: true,
          ),
        ),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        matchDateTimeComponents: DateTimeComponents.time, // repeat daily
      );
      debugPrint('NotificationService: daily review reminder at '
          '${user.notificationStartTime}');
    } catch (e) {
      debugPrint('NotificationService: failed to schedule reminder — $e');
    }
  }

  /// Cancels all pending local notifications.
  Future<void> cancelAll() => _plugin.cancelAll();

  DateTime _parseHHMM(String hhmm, DateTime base) {
    final parts = hhmm.split(':');
    return DateTime(
      base.year,
      base.month,
      base.day,
      int.tryParse(parts[0]) ?? 8,
      parts.length > 1 ? (int.tryParse(parts[1]) ?? 0) : 0,
    );
  }
}
