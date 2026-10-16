import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

class NotificationService {
  NotificationService._();

  static final NotificationService instance = NotificationService._();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  bool _initialized = false;

  static const Map<String, int> _notificationIds = {
    'encouragement': 1000,
    'breathing': 2000,
    'checkin': 3000,
    'milestones': 4000,
  };

  Future<void> initialize() async {
    if (_initialized) return;

    tz_data.initializeTimeZones();

    final localTimezone = await FlutterTimezone.getLocalTimezone();
    tz.setLocalLocation(tz.getLocation(localTimezone.identifier));

    const initializationSettings = InitializationSettings(
      android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      iOS: DarwinInitializationSettings(),
    );

    await _plugin.initialize(settings: initializationSettings);

    _initialized = true;
  }

  Future<bool> requestPermission() async {
    await initialize();

    final androidPlugin = _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();

    if (androidPlugin == null) return true;

    final granted = await androidPlugin.requestNotificationsPermission();
    return granted ?? true;
  }

  Future<void> syncReminder({
    required String key,
    required bool enabled,
    required int hour,
    required int minute,
    required Set<int> days,
  }) async {
    await initialize();

    final baseId = _notificationIds[key];

    if (baseId == null) {
      throw ArgumentError('Unknown brié reminder: $key');
    }

    // Cancel existing weekly schedules before updating them.
    for (int day = 0; day < 7; day++) {
      await _plugin.cancel(id: baseId + day);
    }

    if (!enabled || days.isEmpty) return;

    const details = NotificationDetails(
      android: AndroidNotificationDetails(
        'brie_gentle_reminders',
        'Gentle reminders',
        channelDescription: 'Gentle, optional reminders from brié.',
        importance: Importance.high,
        priority: Priority.high,
        enableVibration: true,
      ),
      iOS: DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: false,
        presentSound: true,
      ),
    );

    final message = _messageFor(key);

    for (final dayIndex in days) {
      if (dayIndex < 0 || dayIndex > 6) continue;

      final scheduledDate = _nextOccurrence(
        weekday: dayIndex + 1,
        hour: hour,
        minute: minute,
      );

      await _plugin.zonedSchedule(
        id: baseId + dayIndex,
        title: 'A gentle moment from brié',
        body: message,
        scheduledDate: scheduledDate,
        notificationDetails: details,
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,
        payload: key,
      );
    }
  }

  tz.TZDateTime _nextOccurrence({
    required int weekday,
    required int hour,
    required int minute,
  }) {
    final now = tz.TZDateTime.now(tz.local);

    var scheduled = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      hour,
      minute,
    );

    while (scheduled.weekday != weekday || !scheduled.isAfter(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }

    return scheduled;
  }

  String _messageFor(String key) {
    switch (key) {
      case 'encouragement':
        const messages = [
          'You do not have to figure everything out today.',
          'Small steps still count. Be gentle with yourself.',
          'You deserve the same kindness you give to others.',
          'Take today one moment at a time.',
          'You are allowed to pause and begin again.',
        ];

        final dayNumber = DateTime.now()
            .difference(DateTime(DateTime.now().year, 1, 1))
            .inDays;

        return messages[dayNumber % messages.length];

      case 'breathing':
        return 'Take a breath. Give yourself a little room to rest.';

      case 'checkin':
        return 'Before the day ends, how are you really feeling?';

      case 'milestones':
        return 'Every small step you take for yourself matters.';

      default:
        return 'Take a moment for yourself. You matter.';
    }
  }

  Future<void> cancelReminder(String key) async {
    final baseId = _notificationIds[key];
    if (baseId == null) return;

    for (int day = 0; day < 7; day++) {
      await _plugin.cancel(id: baseId + day);
    }
  }

  Future<void> cancelAllReminders() async {
    await _plugin.cancelAll();
  }

  Future<void> dismissDisplayedNotifications() async {
    await initialize();

    final activeNotifications = await _plugin.getActiveNotifications();

    for (final notification in activeNotifications) {
      if (notification.id != null) {
        await _plugin.cancel(id: notification.id!);
      }
    }
  }
}
