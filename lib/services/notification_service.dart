import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class NotificationService {
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;

  // Initialize FCM and configure settings
  Future<void> init() async {
    await _messaging.requestPermission(); // Request permissions for iOS
    await _messaging.subscribeToTopic('daily_reminders');
    // TODO: Set up local notifications or handle incoming messages for daily practice reminders
  }
}

// Provider for NotificationService (initialized once)
final notificationServiceProvider = Provider<NotificationService>((ref) {
  final service = NotificationService();
  service.init(); // Initialize on creation
  return service;
});
