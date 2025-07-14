import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'storage_service.dart';
import 'notification_service.dart';

class NotificationScheduler {
  static final NotificationScheduler _instance =
      NotificationScheduler._internal();
  factory NotificationScheduler() => _instance;
  NotificationScheduler._internal();

  List<Timer> _timers = []; // 存储所有定时器
  late StorageService _storage;
  late NotificationService _notificationService;
  bool _isInitialized = false;

  /// 初始化调度器
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      _storage = await StorageService.getInstance();
      _notificationService = NotificationService();
      await _notificationService.initialize();

      _isInitialized = true;
      await _scheduleAllNotifications();

      debugPrint('NotificationScheduler initialized successfully');
    } catch (e) {
      debugPrint('Error initializing NotificationScheduler: $e');
    }
  }

  /// 调度所有通知
  Future<void> _scheduleAllNotifications() async {
    if (!_isInitialized) return;

    try {
      _cancelAllTimers(); // 取消所有现有定时器

      final reminderSettings = await _storage.getReminderSettings();
      final isEnabled = reminderSettings['enabled'] as bool;
      final times = reminderSettings['times'] as List<Map<String, int>>;

      if (!isEnabled || times.isEmpty) {
        debugPrint('Reminders are disabled or no times set');
        return;
      }

      for (var time in times) {
        final hour = time['hour']!;
        final minute = time['minute']!;

        final nextNotificationTime = _calculateNextNotificationTime(hour, minute);
        final now = DateTime.now();
        final delay = nextNotificationTime.difference(now);

        if (delay.isNegative) {
          debugPrint('Time $hour:$minute is in the past, scheduling for tomorrow');
          // 如果时间已过，则安排到明天，并立即发送一次（如果今天还没发过）
          _scheduleSingleNotification(hour, minute, nextNotificationTime.add(const Duration(days: 1)));
          // 检查今天是否已经发送过，如果没有，则立即发送
          final lastNotification = await _storage.getLastNotificationTime();
          if (lastNotification == null || !lastNotification.isAtSameMomentAs(DateTime(now.year, now.month, now.day))) {
             await _sendDailyNotification();
          }
        } else {
          debugPrint('Time $hour:$minute scheduled for: $nextNotificationTime');
          _scheduleSingleNotification(hour, minute, nextNotificationTime);
        }
      }
    } catch (e) {
      debugPrint('Error scheduling all notifications: $e');
    }
  }

  /// 调度单个通知
  Future<void> _scheduleSingleNotification(int hour, int minute, DateTime scheduledTime) {
    _timers.add(Timer(scheduledTime.difference(DateTime.now()), () async {
      await _sendDailyNotification();
      // 递归调度下一次通知（对于这个时间点）
      await _scheduleSingleNotification(hour, minute, scheduledTime.add(const Duration(days: 1)));
    }));

    // 设置每分钟检查定时器（防止系统时间变更导致的问题）
    _timers.add(Timer.periodic(const Duration(minutes: 1), (timer) async {
      await _checkAndSendNotification(hour, minute);
    }));
    return Future.value();
  }

  /// 计算下次通知时间
  DateTime _calculateNextNotificationTime(int hour, int minute) {
    final now = DateTime.now();
    var nextNotification = DateTime(now.year, now.month, now.day, hour, minute);

    if (nextNotification.isBefore(now)) {
      nextNotification = nextNotification.add(const Duration(days: 1));
    }
    return nextNotification;
  }

  /// 检查是否应该发送通知
  Future<void> _checkAndSendNotification(int hour, int minute) async {
    if (!_isInitialized) return;

    try {
      final reminderSettings = await _storage.getReminderSettings();
      final isEnabled = reminderSettings['enabled'] as bool;

      if (!isEnabled) return;

      final now = DateTime.now();

      // 检查是否到了通知时间（允许1分钟的误差）
      if (now.hour == hour && now.minute == minute) {
        final lastNotification = await _storage.getLastNotificationTime();
        if (lastNotification != null) {
          final lastNotificationDate = DateTime(
            lastNotification.year,
            lastNotification.month,
            lastNotification.day,
          );
          final today = DateTime(now.year, now.month, now.day);

          if (lastNotificationDate.isAtSameMomentAs(today)) {
            debugPrint('Notification for $hour:$minute already sent today');
            return;
          }
        }

        await _sendDailyNotification();
      }
    } catch (e) {
      debugPrint('Error checking notification time for $hour:$minute: $e');
    }
  }

  /// 发送每日通知
  Future<void> _sendDailyNotification() async {
    try {
      await _notificationService.sendSmartReminder();
      await _storage.setLastNotificationTime(DateTime.now());
      debugPrint('Daily notification sent successfully');
    } catch (e) {
      debugPrint('Error sending daily notification: $e');
    }
  }

  /// 更新通知调度（当用户修改设置时调用）
  Future<void> updateSchedule() async {
    if (!_isInitialized) {
      await initialize();
      return;
    }

    debugPrint('Updating notification schedule');
    await _scheduleAllNotifications();
  }

  /// 立即发送通知
  Future<void> sendImmediateNotification() async {
    if (!_isInitialized) {
      await initialize();
    }

    try {
      debugPrint('Attempting to send immediate notification...');
      await _sendDailyNotification();
      debugPrint('Immediate notification send attempt completed.');
    } catch (e) {
      debugPrint('Error sending immediate notification: $e');
      throw Exception('发送立即通知失败: $e');
    }
  }

  /// 取消所有定时器
  void _cancelAllTimers() {
    for (var timer in _timers) {
      timer.cancel();
    }
    _timers.clear();
  }

  /// 获取下次通知时间
  Future<DateTime?> getNextNotificationTime() async {
    if (!_isInitialized) return null;

    try {
      final reminderSettings = await _storage.getReminderSettings();
      final isEnabled = reminderSettings['enabled'] as bool;
      final times = reminderSettings['times'] as List<Map<String, int>>;

      if (!isEnabled || times.isEmpty) return null;

      DateTime? closestTime;
      final now = DateTime.now();

      for (var time in times) {
        final hour = time['hour']!;
        final minute = time['minute']!;
        var nextNotification = DateTime(now.year, now.month, now.day, hour, minute);

        if (nextNotification.isBefore(now)) {
          nextNotification = nextNotification.add(const Duration(days: 1));
        }

        if (closestTime == null || nextNotification.isBefore(closestTime)) {
          closestTime = nextNotification;
        }
      }
      return closestTime;
    } catch (e) {
      debugPrint('Error getting next notification time: $e');
      return null;
    }
  }

  /// 获取格式化的下次通知时间字符串
  Future<String> getNextNotificationTimeString() async {
    final nextTime = await getNextNotificationTime();
    if (nextTime == null) {
      return '通知已关闭';
    }

    final now = DateTime.now();
    final difference = nextTime.difference(now);

    if (difference.inDays > 0) {
      return '明天 ${nextTime.hour.toString().padLeft(2, '0')}:${nextTime.minute.toString().padLeft(2, '0')}';
    } else if (difference.inHours > 0) {
      return '今天 ${nextTime.hour.toString().padLeft(2, '0')}:${nextTime.minute.toString().padLeft(2, '0')}';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} 分钟后';
    } else {
      return '即将通知';
    }
  }

  /// 停止调度器
  void stop() {
    _cancelAllTimers();
    _isInitialized = false;
    debugPrint('NotificationScheduler stopped');
  }

  /// 检查调度器是否正在运行
  bool get isRunning => _isInitialized && _timers.isNotEmpty;
}