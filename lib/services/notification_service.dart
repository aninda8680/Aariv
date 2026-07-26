import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

  Future<void> init() async {
    tz.initializeTimeZones();

    const AndroidInitializationSettings initializationSettingsAndroid = AndroidInitializationSettings('@mipmap/ic_launcher');
    
    final DarwinInitializationSettings initializationSettingsDarwin = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );
    
    final InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsDarwin,
    );

    // v22+ signature
    await flutterLocalNotificationsPlugin.initialize(settings: initializationSettings);
  }

  Future<void> requestPermissions() async {
    final androidPlugin = flutterLocalNotificationsPlugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
    await androidPlugin?.requestNotificationsPermission();

    final iosPlugin = flutterLocalNotificationsPlugin.resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>();
    await iosPlugin?.requestPermissions(
      alert: true,
      badge: true,
      sound: true,
    );
  }

  Future<void> scheduleTimerCompletionNotification(int id, String title, String body, DateTime scheduledDate) async {
    await flutterLocalNotificationsPlugin.zonedSchedule(
      id: id,
      title: title,
      body: body,
      scheduledDate: tz.TZDateTime.from(scheduledDate, tz.local),
      notificationDetails: const NotificationDetails(
        android: AndroidNotificationDetails(
          'timer_channel',
          'Timer Notifications',
          channelDescription: 'Notifications for completed focus sessions',
          importance: Importance.max,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(
          interruptionLevel: InterruptionLevel.timeSensitive,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
    );
  }

  Future<void> cancelNotification(int id) async {
    // Some versions use positional id, let's see. If cancel fails, we will adjust
    try {
      await flutterLocalNotificationsPlugin.cancel(id: id);
    } catch (e) {
      // ignore
    }
  }
}
