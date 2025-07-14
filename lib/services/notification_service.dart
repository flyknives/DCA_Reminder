import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'dart:io' show Platform;
import 'storage_service.dart';
import 'api_service.dart';
import 'rainbow_dca_service.dart';
import '../utils/helpers.dart';

enum NotificationType {
  daily,
  priceAlert,
  investment,
  system,
}

class NotificationService {
  static final NotificationService _instance =
      NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();

  bool _isInitialized = false;
  late StorageService _storage;

  /// Check if the service is initialized.
  bool get isInitialized => _isInitialized;

  /// Initialize the notification service.
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      _storage = await StorageService.getInstance();

      const androidSettings =
          AndroidInitializationSettings('@mipmap/ic_launcher');
      const iosSettings = DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
      );
      const windowsSettings = WindowsInitializationSettings(
        appName: 'BTC DCA 提醒',
        appUserModelId: 'com.btcdca.reminder',
        guid: 'a58a4b52-1d5c-4c8e-9f7a-2b3c4d5e6f7a',
      );

      const initializationSettings = InitializationSettings(
        android: androidSettings,
        iOS: iosSettings,
        windows: windowsSettings,
      );

      final result = await _notifications.initialize(
        initializationSettings,
        onDidReceiveNotificationResponse: _onNotificationResponse,
      );

      _isInitialized = result ?? false;
      debugPrint(
          '🔔 Notification service initialized: $_isInitialized');

      if (_isInitialized) {
        await requestPermissions();
      }
    } catch (e) {
      debugPrint('❌ Notification service initialization failed: $e');
      _isInitialized = false;
    }
  }

  /// Handle notification tap events.
  void _onNotificationResponse(NotificationResponse response) {
    debugPrint('📱 Notification tapped: ${response.payload}');
    // Handle payload-based navigation or actions here.
  }

  /// Request necessary permissions for notifications.
  Future<bool> requestPermissions() async {
    try {
      if (Platform.isAndroid) {
        final androidImplementation =
            _notifications.resolvePlatformSpecificImplementation<
                AndroidFlutterLocalNotificationsPlugin>();
        return await androidImplementation?.requestNotificationsPermission() ??
            false;
      } else if (Platform.isIOS) {
        final iosImplementation =
            _notifications.resolvePlatformSpecificImplementation<
                IOSFlutterLocalNotificationsPlugin>();
        return await iosImplementation?.requestPermissions(
              alert: true,
              badge: true,
              sound: true,
            ) ??
            false;
      }
      return true; // Default to true for other platforms like Windows
    } catch (e) {
      debugPrint('❌ Request notification permissions failed: $e');
      return false;
    }
  }

  /// Send a test notification to verify functionality.
  Future<void> sendTestNotification() async {
    if (!_isInitialized) {
      debugPrint('❌ Notification service not initialized');
      return;
    }
    await _showNotification(
      id: 0,
      title: '🌈 BTC DCA 提醒测试',
      body: '通知功能正常工作！',
      type: NotificationType.system,
      payload: 'test_notification',
    );
  }

  /// Send a smart reminder based on the Rainbow DCA model.
  Future<void> sendSmartReminder() async {
    if (!_isInitialized) return;

    try {
      final shouldSend = await _storage.shouldSendNotification();
      if (!shouldSend) {
        debugPrint('⏰ Notification cooldown active, skipping smart reminder.');
        return;
      }

      final apiService = APIService();
      final btcData = await apiService.getBTCPrice();
      final rainbowResult = await RainbowDCAService.calculateRainbowDCAAsync(
        currentPrice: btcData.price,
        historicalData: [], // Passing empty list, consider fetching real data if needed
      );

      String title;
      String body;

      if (rainbowResult.multiplier >= 2.0) {
        title = '🟢 绝佳买入机会！';
        body = '当前处于${rainbowResult.zone}，建议增加投资！';
      } else if (rainbowResult.multiplier <= 0.5) {
        title = '🔴 谨慎投资区域';
        body = '当前处于${rainbowResult.zone}，建议减少投资。';
      } else {
        title = '🟡 正常DCA区域';
        body = '当前处于${rainbowResult.zone}，按计划定投。';
      }

      body += '\n当前价格: ${AppHelpers.formatPrice(btcData.price)}';
      body += '\n建议金额: ${AppHelpers.formatPrice(rainbowResult.suggestedAmount)}';

      await _showNotification(
        id: _getBaseIdForType(NotificationType.daily) + 1,
        title: title,
        body: body,
        type: NotificationType.daily,
        payload: 'smart_reminder|${rainbowResult.zone}',
      );
      
      await _storage.setLastNotificationTime(DateTime.now());
      debugPrint('✅ Smart reminder sent');
    } catch (e) {
      debugPrint('❌ Send smart reminder failed: $e');
    }
  }

  /// Send a price alert notification.
  Future<void> sendPriceAlert({
    required double targetPrice,
    required double currentPrice,
    required bool isAbove,
  }) async {
    if (!_isInitialized) return;

    final direction = isAbove ? '突破' : '跌破';
    final emoji = isAbove ? '🚀' : '📉';

    await _showNotification(
      id: _getBaseIdForType(NotificationType.priceAlert),
      title: '$emoji BTC价格警报',
      body: 'BTC已$direction目标价格！\n'
          '当前价格: ${AppHelpers.formatPrice(currentPrice)}\n'
          '目标价格: ${AppHelpers.formatPrice(targetPrice)}',
      type: NotificationType.priceAlert,
      payload: 'price_alert|$currentPrice|$targetPrice',
    );
  }

  /// Send a confirmation notification after an investment is recorded.
  Future<void> sendInvestmentConfirmation({
    required double amount,
    required double btcPrice,
    required double btcAmount,
  }) async {
    if (!_isInitialized) return;

    await _showNotification(
      id: _getBaseIdForType(NotificationType.investment),
      title: '✅ 投资记录已保存',
      body: '投资金额: ${AppHelpers.formatPrice(amount)}\n'
          'BTC价格: ${AppHelpers.formatPrice(btcPrice)}\n'
          '购买数量: ${AppHelpers.formatBTC(btcAmount)}',
      type: NotificationType.investment,
      payload: 'investment|$amount|$btcAmount',
    );
  }

  /// Generic method to display a notification.
  Future<void> _showNotification({
    required int id,
    required String title,
    required String body,
    required NotificationType type,
    String? payload,
  }) async {
    const androidDetails = AndroidNotificationDetails(
      'btc_dca_enhanced',
      'BTC DCA 增强提醒',
      channelDescription: 'BTC定投智能提醒通知',
      importance: Importance.high,
      priority: Priority.high,
      showWhen: true,
      enableVibration: true,
      playSound: true,
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
      badgeNumber: 1,
    );

    const windowsDetails = WindowsNotificationDetails();

    const notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
      windows: windowsDetails,
    );

    await _notifications.show(
      id,
      title,
      body,
      notificationDetails,
      payload: payload,
    );
  }

  /// Cancel all scheduled and displayed notifications.
  Future<void> cancelAllNotifications() async {
    if (!_isInitialized) return;
    await _notifications.cancelAll();
    debugPrint('🗑️ All notifications cancelled');
  }

  /// Cancel notifications of a specific type.
  Future<void> cancelNotificationType(NotificationType type) async {
    if (!_isInitialized) return;
    int baseId = _getBaseIdForType(type);
    // Cancel a range of IDs for the given type
    for (int i = 0; i < 10; i++) {
      await _notifications.cancel(baseId + i);
    }
    debugPrint('🗑️ Cancelled notifications for type: $type');
  }

  /// Get the base ID for a notification type to avoid collisions.
  int _getBaseIdForType(NotificationType type) {
    switch (type) {
      case NotificationType.daily:
        return 1000;
      case NotificationType.priceAlert:
        return 2000;
      case NotificationType.investment:
        return 3000;
      case NotificationType.system:
        return 0;
    }
  }

  /// Check current notification permission status.
  Future<bool> checkPermissions() async {
    if (!_isInitialized) return false;

    try {
      if (Platform.isAndroid) {
        final androidImplementation =
            _notifications.resolvePlatformSpecificImplementation<
                AndroidFlutterLocalNotificationsPlugin>();
        return await androidImplementation?.areNotificationsEnabled() ?? false;
      } else if (Platform.isIOS) {
        // iOS doesn't have a direct method to check, but requesting permissions
        // again will return the current status without re-prompting the user.
        final dynamic settings = await _notifications
            .resolvePlatformSpecificImplementation<
                IOSFlutterLocalNotificationsPlugin>()
            ?.checkPermissions();
        if (settings == null) return false;
        // Use string comparison to avoid compile-time dependency on Darwin-specific types.
        // DarwinAuthorizationStatus.authorized.toString() results in 'DarwinAuthorizationStatus.authorized'
        return settings.authorizationStatus.toString() == 'DarwinAuthorizationStatus.authorized';
      }
      return true; // Assume true for Windows
    } catch (e) {
      debugPrint('❌ Check notification permissions failed: $e');
      return false;
    }
  }

  /// Get the count of pending notifications.
  Future<int> getPendingNotificationCount() async {
    if (!_isInitialized) return 0;
    try {
      final pendingRequests =
          await _notifications.pendingNotificationRequests();
      return pendingRequests.length;
    } catch (e) {
      debugPrint('❌ Get pending notification count failed: $e');
      return 0;
    }
  }
}