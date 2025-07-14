import 'dart:math' as math;
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

/// 通用工具类
class AppHelpers {
  AppHelpers._();

  /// 格式化价格
  static String formatPrice(double price, {int decimals = 2}) {
    if (price.isNaN || price.isInfinite) return '\$0.00';

    final formatter = NumberFormat.currency(
      symbol: '\$',
      decimalDigits: decimals,
    );
    return formatter.format(price);
  }

  /// 格式化百分比
  static String formatPercentage(double percentage, {int decimals = 2}) {
    if (percentage.isNaN || percentage.isInfinite) return '0.00%';

    final sign = percentage >= 0 ? '+' : '';
    return '$sign${percentage.toStringAsFixed(decimals)}%';
  }

  /// 格式化BTC数量
  static String formatBTC(double amount, {int decimals = 8}) {
    if (amount.isNaN || amount.isInfinite) return '0.00000000 BTC';

    return '${amount.toStringAsFixed(decimals)} BTC';
  }

  /// 格式化大数字（K, M, B）
  static String formatLargeNumber(double number) {
    if (number.isNaN || number.isInfinite) return '0';

    if (number >= 1e9) {
      return '${(number / 1e9).toStringAsFixed(1)}B';
    } else if (number >= 1e6) {
      return '${(number / 1e6).toStringAsFixed(1)}M';
    } else if (number >= 1e3) {
      return '${(number / 1e3).toStringAsFixed(1)}K';
    } else {
      return number.toStringAsFixed(0);
    }
  }

  /// 格式化日期时间
  static String formatDateTime(DateTime dateTime,
      {String pattern = 'yyyy-MM-dd HH:mm'}) {
    final formatter = DateFormat(pattern);
    return formatter.format(dateTime);
  }

  /// 格式化相对时间
  static String formatRelativeTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays > 0) {
      return '${difference.inDays}天前';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}小时前';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}分钟前';
    } else {
      return '刚刚';
    }
  }

  /// 验证价格输入
  static bool isValidPrice(String input) {
    if (input.isEmpty) return false;
    final price = double.tryParse(input);
    return price != null && price > 0 && price < double.maxFinite;
  }

  /// 验证金额输入
  static bool isValidAmount(String input) {
    if (input.isEmpty) return false;
    final amount = double.tryParse(input);
    return amount != null && amount > 0 && amount <= 1000000; // 最大100万
  }

  /// 获取颜色根据价格变化
  static String getPriceChangeEmoji(double change) {
    if (change > 0) return '🟢';
    if (change < 0) return '🔴';
    return '⚪';
  }

  /// 获取趋势箭头
  static String getTrendArrow(double change) {
    if (change > 0) return '↗️';
    if (change < 0) return '↘️';
    return '➡️';
  }

  /// 计算投资回报率
  static double calculateROI(double initialValue, double currentValue) {
    if (initialValue <= 0) return 0.0;
    return ((currentValue - initialValue) / initialValue) * 100;
  }

  /// 生成随机ID
  static String generateId() {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final random = math.Random().nextInt(9999);
    return '${timestamp}_$random';
  }

  /// 防抖动器
  static void debounce(void Function() action, Duration delay) {
    _DebounceHelper.instance.debounce(action, delay);
  }

  /// 震动反馈
  static void vibrate() {
    HapticFeedback.lightImpact();
  }

  /// 强震动反馈
  static void vibrateStrong() {
    HapticFeedback.heavyImpact();
  }

  /// 安全地执行异步操作
  static Future<T?> safeAsync<T>(Future<T> Function() operation) async {
    try {
      return await operation();
    } catch (e) {
      return null;
    }
  }

  /// 检查是否为有效的JSON
  static bool isValidJson(String jsonString) {
    try {
      return jsonString.isNotEmpty;
    } catch (e) {
      return false;
    }
  }

  /// 限制数字范围
  static double clamp(double value, double min, double max) {
    return math.max(min, math.min(max, value));
  }

  /// 格式化文件大小
  static String formatFileSize(int bytes) {
    if (bytes <= 0) return '0 B';
    const units = ['B', 'KB', 'MB', 'GB'];
    int unitIndex = 0;
    double size = bytes.toDouble();

    while (size >= 1024 && unitIndex < units.length - 1) {
      size /= 1024;
      unitIndex++;
    }

    return '${size.toStringAsFixed(1)} ${units[unitIndex]}';
  }

  /// 计算两点之间的距离
  static double calculateDistance(double x1, double y1, double x2, double y2) {
    return math.sqrt(math.pow(x2 - x1, 2) + math.pow(y2 - y1, 2));
  }

  /// 获取彩虹区域颜色
  static String getRainbowZoneEmoji(String zone) {
    if (zone.contains('深蓝') || zone.contains('蓝色')) return '🔵';
    if (zone.contains('绿色')) return '🟢';
    if (zone.contains('黄色')) return '🟡';
    if (zone.contains('橙色')) return '🟠';
    if (zone.contains('红色')) return '🔴';
    if (zone.contains('狂热') || zone.contains('紫色')) return '🟣';
    return '🟡';
  }

  /// 检查网络连接错误
  static bool isNetworkError(dynamic error) {
    final errorString = error.toString().toLowerCase();
    return errorString.contains('socket') ||
        errorString.contains('network') ||
        errorString.contains('timeout') ||
        errorString.contains('connection');
  }

  /// 检查服务器错误
  static bool isServerError(dynamic error) {
    final errorString = error.toString().toLowerCase();
    return errorString.contains('500') ||
        errorString.contains('502') ||
        errorString.contains('503') ||
        errorString.contains('server');
  }

  /// 格式化错误消息
  static String formatErrorMessage(dynamic error) {
    if (isNetworkError(error)) {
      return '网络连接失败，请检查网络设置';
    } else if (isServerError(error)) {
      return '服务器暂时不可用，请稍后重试';
    } else if (error.toString().contains('format')) {
      return '数据格式错误，请重新加载';
    } else {
      return '发生未知错误：${error.toString()}';
    }
  }
}

/// 防抖动助手类
class _DebounceHelper {
  static final _DebounceHelper instance = _DebounceHelper._();
  _DebounceHelper._();

  DateTime? _lastActionTime;

  void debounce(void Function() action, Duration delay) {
    final now = DateTime.now();

    if (_lastActionTime == null || now.difference(_lastActionTime!) >= delay) {
      _lastActionTime = now;
      action();
    }
  }
}

/// 颜色工具类
class ColorHelpers {
  ColorHelpers._();

  /// 根据百分比获取颜色（绿色到红色渐变）
  static String getPercentageColor(double percentage) {
    if (percentage > 10) return '🟢';
    if (percentage > 5) return '🟡';
    if (percentage > 0) return '🟠';
    if (percentage > -5) return '🔴';
    return '🟣';
  }

  /// 获取风险等级颜色
  static String getRiskLevelColor(double riskLevel) {
    if (riskLevel < 0.3) return '🟢'; // 低风险
    if (riskLevel < 0.6) return '🟡'; // 中等风险
    if (riskLevel < 0.8) return '🟠'; // 高风险
    return '🔴'; // 极高风险
  }
}

/// 验证器工具类
class Validators {
  Validators._();

  /// 验证邮箱
  static bool isValidEmail(String email) {
    return RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(email);
  }

  /// 验证手机号
  static bool isValidPhone(String phone) {
    return RegExp(r'^1[3-9]\d{9}$').hasMatch(phone);
  }

  /// 验证密码强度
  static bool isStrongPassword(String password) {
    return password.length >= 8 &&
        RegExp(r'[A-Z]').hasMatch(password) &&
        RegExp(r'[a-z]').hasMatch(password) &&
        RegExp(r'[0-9]').hasMatch(password);
  }

  /// 验证URL
  static bool isValidUrl(String url) {
    return Uri.tryParse(url)?.hasAbsolutePath ?? false;
  }
}
