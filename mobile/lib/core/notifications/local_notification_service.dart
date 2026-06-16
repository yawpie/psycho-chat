import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import 'package:psycho_chat/domain/entities/chat_message.dart' as chat;

class LocalNotificationService {
  LocalNotificationService({FlutterLocalNotificationsPlugin? plugin})
    : _plugin = plugin ?? FlutterLocalNotificationsPlugin();

  static const _channelId = 'chat_messages';
  static const _channelName = 'Chat messages';
  static const _channelDescription =
      'Notifications for newly received chat messages.';

  final FlutterLocalNotificationsPlugin _plugin;
  bool _isInitialized = false;

  bool get _isSupportedPlatform =>
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.android ||
          defaultTargetPlatform == TargetPlatform.iOS);

  Future<void> initialize() async {
    if (_isInitialized || !_isSupportedPlatform) return;

    const settings = InitializationSettings(
      android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      iOS: DarwinInitializationSettings(
        requestAlertPermission: false,
        requestBadgePermission: false,
        requestSoundPermission: false,
      ),
    );

    await _plugin.initialize(settings: settings);
    _isInitialized = true;
  }

  Future<void> requestPermissions() async {
    if (!_isSupportedPlatform) return;
    await initialize();

    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        await _plugin
            .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin
            >()
            ?.requestNotificationsPermission();
        return;
      case TargetPlatform.iOS:
        await _plugin
            .resolvePlatformSpecificImplementation<
              IOSFlutterLocalNotificationsPlugin
            >()
            ?.requestPermissions(alert: true, badge: true, sound: true);
        return;
      default:
        return;
    }
  }

  Future<void> showNewMessage(chat.Message message) async {
    if (!_isSupportedPlatform) return;
    await initialize();

    const details = NotificationDetails(
      android: AndroidNotificationDetails(
        _channelId,
        _channelName,
        channelDescription: _channelDescription,
        importance: Importance.high,
        priority: Priority.high,
        category: AndroidNotificationCategory.message,
      ),
      iOS: DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      ),
    );

    await _plugin.show(
      id: message.id.hashCode,
      title: message.sender,
      body: message.message,
      notificationDetails: details,
      payload: message.conversationId.toString(),
    );
  }
}
