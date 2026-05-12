class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  Future<void> init() async {
    // Notifications will be added when Firebase is connected
  }

  Future<void> showNotification({
    required int id,
    required String title,
    required String body,
  }) async {
    // Will be implemented with Firebase Cloud Messaging
    print('NOTIFICATION: $title - $body');
  }

  Future<void> cancelAll() async {}
}