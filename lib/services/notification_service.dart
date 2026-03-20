import 'package:flutter_local_notifications/flutter_local_notifications.dart';

/// Sends local push notifications for tool-call approval requests.
class NotificationService {
  static final _plugin = FlutterLocalNotificationsPlugin();
  static const _channelId = 'nomadterm_approve';
  static const _channelName = 'Tool Call Approvals';

  static Future<void> init() async {
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    const settings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );
    await _plugin.initialize(settings);
  }

  /// Show a notification asking the user to approve a tool call.
  static Future<void> showApproveNotification({
    required int id,
    required String command,
    required String risk,
  }) async {
    const androidDetails = AndroidNotificationDetails(
      _channelId,
      _channelName,
      importance: Importance.max,
      priority: Priority.high,
    );
    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );
    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _plugin.show(
      id,
      'Tool Call Approval Required',
      '$command (risk: $risk)',
      details,
    );
  }
}
