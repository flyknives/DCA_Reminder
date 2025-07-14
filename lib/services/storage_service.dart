import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/investment_record.dart';

class StorageService {
  static const String _baseAmountKey = 'base_amount';
  static const String _investmentRecordsKey = 'investment_records';
  static const String _totalInvestedKey = 'total_invested';
  static const String _autoInvestEnabledKey = 'auto_invest_enabled';
  static const String _lastNotificationKey = 'last_notification';
  static const String _reminderEnabledKey = 'daily_reminder_enabled'; // 新增
  static const String _reminderTimesKey = 'reminder_times';

  static StorageService? _instance;
  static SharedPreferences? _prefs;

  StorageService._();

  static Future<StorageService> getInstance() async {
    _instance ??= StorageService._();
    _prefs ??= await SharedPreferences.getInstance();
    return _instance!;
  }

  /// 获取基准投资金额
  Future<double> getBaseAmount() async {
    return _prefs!.getDouble(_baseAmountKey) ?? 100.0;
  }

  /// 设置基准投资金额
  Future<void> setBaseAmount(double amount) async {
    await _prefs!.setDouble(_baseAmountKey, amount);
  }

  /// 获取投资记录列表
  Future<List<InvestmentRecord>> getInvestmentRecords() async {
    final String? recordsJson = _prefs!.getString(_investmentRecordsKey);
    if (recordsJson == null) return [];

    try {
      final List<dynamic> recordsList = json.decode(recordsJson);
      return recordsList
          .map((record) => InvestmentRecord.fromJson(record))
          .toList();
    } catch (e) {
      debugPrint('Error loading investment records: $e');
      return [];
    }
  }

  /// 添加投资记录
  Future<void> addInvestmentRecord(InvestmentRecord record) async {
    final records = await getInvestmentRecords();
    records.add(record);
    await _saveInvestmentRecords(records);

    // 更新总投资金额
    await _updateTotalInvested();
  }

  /// 删除投资记录
  Future<void> deleteInvestmentRecord(int index) async {
    final records = await getInvestmentRecords();
    if (index >= 0 && index < records.length) {
      records.removeAt(index);
      await _saveInvestmentRecords(records);
      await _updateTotalInvested();
    }
  }

  /// 清空所有投资记录
  Future<void> clearInvestmentRecords() async {
    await _prefs!.remove(_investmentRecordsKey);
    await _prefs!.remove(_totalInvestedKey);
  }

  /// 保存投资记录列表
  Future<void> _saveInvestmentRecords(List<InvestmentRecord> records) async {
    final recordsJson =
        json.encode(records.map((record) => record.toJson()).toList());
    await _prefs!.setString(_investmentRecordsKey, recordsJson);
  }

  /// 更新总投资金额
  Future<void> _updateTotalInvested() async {
    final records = await getInvestmentRecords();
    final totalInvested =
        records.fold<double>(0, (sum, record) => sum + record.amount);
    await _prefs!.setDouble(_totalInvestedKey, totalInvested);
  }

  /// 获取总投资金额
  Future<double> getTotalInvested() async {
    return _prefs!.getDouble(_totalInvestedKey) ?? 0.0;
  }

  /// 获取投资统计摘要
  Future<InvestmentSummary?> getInvestmentSummary(
      double currentBTCPrice) async {
    final records = await getInvestmentRecords();
    if (records.isEmpty) return null;

    final totalInvested =
        records.fold<double>(0, (sum, record) => sum + record.amount);
    final totalBTCAmount =
        records.fold<double>(0, (sum, record) => sum + record.btcAmount);
    final averagePrice = totalInvested / totalBTCAmount;
    final currentValue = totalBTCAmount * currentBTCPrice;
    final totalROI = (currentValue - totalInvested) / totalInvested * 100;

    // 排序以获取第一次和最后一次投资
    final sortedRecords = List<InvestmentRecord>.from(records)
      ..sort((a, b) => a.date.compareTo(b.date));

    return InvestmentSummary(
      totalInvested: totalInvested,
      totalBTCAmount: totalBTCAmount,
      averagePrice: averagePrice,
      totalRecords: records.length,
      currentValue: currentValue,
      totalROI: totalROI,
      firstInvestment: sortedRecords.first.date,
      lastInvestment: sortedRecords.last.date,
    );
  }

  /// 获取自动投资开关状态
  Future<bool> getAutoInvestEnabled() async {
    return _prefs!.getBool(_autoInvestEnabledKey) ?? false;
  }

  /// 设置自动投资开关状态
  Future<void> setAutoInvestEnabled(bool enabled) async {
    await _prefs!.setBool(_autoInvestEnabledKey, enabled);
  }

  /// 获取最后通知时间
  Future<DateTime?> getLastNotificationTime() async {
    final timestamp = _prefs!.getInt(_lastNotificationKey);
    return timestamp != null
        ? DateTime.fromMillisecondsSinceEpoch(timestamp)
        : null;
  }

  /// 设置最后通知时间
  Future<void> setLastNotificationTime(DateTime time) async {
    await _prefs!.setInt(_lastNotificationKey, time.millisecondsSinceEpoch);
  }

  /// 检查是否应该发送通知（避免重复通知）
  Future<bool> shouldSendNotification() async {
    final lastNotification = await getLastNotificationTime();
    if (lastNotification == null) return true;

    // 如果距离上次通知超过1小时，则可以发送
    final now = DateTime.now();
    final difference = now.difference(lastNotification);
    return difference.inHours >= 1;
  }

  /// 导出投资记录为JSON字符串
  Future<String> exportInvestmentRecords() async {
    final records = await getInvestmentRecords();
    final exportData = {
      'exportDate': DateTime.now().toIso8601String(),
      'totalRecords': records.length,
      'records': records.map((record) => record.toJson()).toList(),
    };
    return json.encode(exportData);
  }

  /// 从JSON字符串导入投资记录
  Future<bool> importInvestmentRecords(String jsonString) async {
    try {
      final Map<String, dynamic> importData = json.decode(jsonString);
      final List<dynamic> recordsList = importData['records'];
      final records = recordsList
          .map((record) => InvestmentRecord.fromJson(record))
          .toList();

      await _saveInvestmentRecords(records);
      await _updateTotalInvested();
      return true;
    } catch (e) {
      debugPrint('Error importing investment records: $e');
      return false;
    }
  }

  /// 获取每日提醒开关状态
  Future<bool> getDailyReminderEnabled() async {
    return _prefs!.getBool(_reminderEnabledKey) ?? false;
  }

  /// 设置每日提醒开关状态
  Future<void> setDailyReminderEnabled(bool enabled) async {
    await _prefs!.setBool(_reminderEnabledKey, enabled);
  }

  /// 获取提醒时间列表
  Future<List<Map<String, int>>> getReminderTimes() async {
    final String? timesJson = _prefs!.getString(_reminderTimesKey);
    if (timesJson == null) return [];
    try {
      final List<dynamic> decodedList = json.decode(timesJson);
      return decodedList.map((e) => Map<String, int>.from(e)).toList();
    } catch (e) {
      debugPrint('Error loading reminder times: $e');
      return [];
    }
  }

  /// 设置提醒时间列表
  Future<void> setReminderTimes(List<Map<String, int>> times) async {
    final String encodedTimes = json.encode(times);
    await _prefs!.setString(_reminderTimesKey, encodedTimes);
  }

  /// 获取完整的提醒时间设置
  Future<Map<String, dynamic>> getReminderSettings() async {
    return {
      'enabled': await getDailyReminderEnabled(),
      'times': await getReminderTimes(),
    };
  }

  /// 设置完整的提醒时间设置
  Future<void> setReminderSettings({
    required bool enabled,
    required List<Map<String, int>> times,
  }) async {
    await setDailyReminderEnabled(enabled);
    await setReminderTimes(times);
  }
}
