import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

/// Maneja los recordatorios locales de las tareas.
class NotificationService {
  NotificationService._();
  static final instance = NotificationService._();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();
  bool _initialized = false;

  bool get supportsScheduledNotifications =>
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.android ||
          defaultTargetPlatform == TargetPlatform.iOS);

  /// Inicializa el plugin y la zona horaria. Se llama una vez en main().
  Future<void> init() async {
    if (_initialized) return;

    tzdata.initializeTimeZones();
    tz.setLocalLocation(tz.getLocation('America/Lima')); // Zona horaria de Perú

    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const ios = DarwinInitializationSettings();
    await _plugin.initialize(
      settings: const InitializationSettings(android: android, iOS: ios),
    );

    // Android 13+: solicita permiso para mostrar notificaciones.
    await _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.requestNotificationsPermission();
    await _plugin
        .resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin
        >()
        ?.requestPermissions(alert: true, badge: true, sound: true);

    _initialized = true;
  }

  /// Convierte el ID de texto de Firestore a un entero estable entre reinicios.
  int _toId(String taskId) {
    var hash = 0x811c9dc5;
    for (final codeUnit in taskId.codeUnits) {
      hash = ((hash ^ codeUnit) * 0x01000193) & 0xffffffff;
    }
    return hash & 0x7fffffff;
  }

  /// Programa un recordatorio para la fecha indicada.
  Future<void> schedule(String taskId, String title, DateTime when) async {
    if (!supportsScheduledNotifications) return;
    if (!_initialized) {
      throw StateError('El servicio de notificaciones no está inicializado.');
    }
    if (!when.isAfter(DateTime.now())) return;

    await _plugin.zonedSchedule(
      id: _toId(taskId),
      title: 'Recordatorio de tarea',
      body: title,
      scheduledDate: tz.TZDateTime.from(when, tz.local),
      notificationDetails: const NotificationDetails(
        android: AndroidNotificationDetails(
          'tareas_channel',
          'Recordatorios de tareas',
          channelDescription: 'Avisos programados para tus tareas.',
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(),
      ),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
    );
  }

  /// Cancela el recordatorio (al eliminar o completar la tarea).
  Future<void> cancel(String taskId) async {
    if (!supportsScheduledNotifications) return;
    await _plugin.cancel(id: _toId(taskId));
  }
}
