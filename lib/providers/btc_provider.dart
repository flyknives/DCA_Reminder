import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/api_service.dart';
import '../services/rainbow_dca_service.dart';
import '../services/notification_service.dart';
import '../services/notification_scheduler.dart';
import '../services/system_tray_service.dart';
import '../services/storage_service.dart'; // 导入 StorageService
import '../models/btc_data.dart';

enum LoadingState { initial, loading, loaded, error }

class BTCProvider extends ChangeNotifier {
  final APIService _apiService;
  final NotificationService _notificationService = NotificationService();
  final NotificationScheduler _notificationScheduler = NotificationScheduler();
  final SystemTrayService _systemTrayService = SystemTrayService();
  late StorageService _storageService; // 添加 StorageService 实例

  // 数据状态
  BTCData? _btcData;
  List<HistoricalData> _historicalData = [];
  RainbowDCAResult? _rainbowResult;

  // UI状态
  LoadingState _loadingState = LoadingState.initial;
  String? _errorMessage;
  DateTime? _lastUpdated;

  // 性能优化：缓存和防抖动
  Timer? _refreshTimer;
  Timer? _debounceTimer;
  static const Duration _cacheValidDuration = Duration(minutes: 5);
  static const Duration _debounceDelay = Duration(milliseconds: 500);
  static const Duration _autoRefreshInterval = Duration(minutes: 10);
  static const int _maxRetries = 3;
  int _retryCount = 0;

  BTCProvider(this._apiService) {
    _initialize();
  }

  // Getters
  BTCData? get btcData => _btcData;
  List<HistoricalData> get historicalData => _historicalData;
  RainbowDCAResult? get rainbowResult => _rainbowResult;
  LoadingState get loadingState => _loadingState;
  bool get isLoading => _loadingState == LoadingState.loading;
  bool get hasError => _loadingState == LoadingState.error;
  bool get hasData => _btcData != null && _rainbowResult != null;
  String? get errorMessage => _errorMessage;
  DateTime? get lastUpdated => _lastUpdated;

  /// 数据是否过期
  bool get isDataStale {
    if (_lastUpdated == null) return true;
    return DateTime.now().difference(_lastUpdated!).inMinutes >= 5;
  }

  /// 初始化
  Future<void> _initialize() async {
    try {
      _storageService = await StorageService.getInstance(); // 初始化 StorageService
      await _notificationService.initialize();
      await _notificationScheduler.initialize();
      await _loadCachedData();

      // 如果没有设置提醒时间，则设置一个默认时间
      final reminderSettings = await _storageService.getReminderSettings();
      if ((reminderSettings['times'] as List).isEmpty) {
        await _storageService.setReminderSettings(
          enabled: true,
          times: [{'hour': 9, 'minute': 0}], // 默认早上9点
        );
        await _notificationScheduler.updateSchedule(); // 更新调度
      }

      // 如果没有缓存数据或数据过期，则刷新
      if (_btcData == null || isDataStale) {
        await refreshData();
      }

      _startAutoRefresh();
    } catch (e) {
      debugPrint('Provider initialization error: $e');
      _setErrorState('初始化失败: $e');
    }
  }

  /// 启动自动刷新
  void _startAutoRefresh() {
    _refreshTimer?.cancel();
    _refreshTimer = Timer.periodic(_autoRefreshInterval, (_) {
      if (!isLoading) {
        refreshData();
      }
    });
  }

  /// 刷新数据（带防抖动）
  Future<void> refreshData() async {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(_debounceDelay, _performRefresh);
  }

  /// 执行实际的数据刷新
  Future<void> _performRefresh() async {
    if (isLoading) return;

    _setLoadingState(LoadingState.loading);
    _retryCount = 0;

    await _refreshDataWithRetry();
  }

  /// 带重试机制的数据刷新
  Future<void> _refreshDataWithRetry() async {
    try {
      // 并行获取数据以提高性能
      final results = await Future.wait([
        _apiService.getBTCPrice(),
        _apiService.getHistoricalData(),
      ]);

      _btcData = results[0] as BTCData;
      _historicalData = results[1] as List<HistoricalData>;

      // 计算彩虹DCA
      _rainbowResult = await RainbowDCAService.calculateRainbowDCAAsync(
        currentPrice: _btcData!.price,
        historicalData: _historicalData,
      );

      _lastUpdated = DateTime.now();
      _setLoadingState(LoadingState.loaded);
      _retryCount = 0;

      // 异步缓存数据，不阻塞UI
      _cacheDataAsync();

      debugPrint('✅ Data refreshed successfully');
    } catch (e) {
      debugPrint('❌ Data refresh error: $e');
      await _handleRefreshError(e);
    }
  }

  /// 处理刷新错误
  Future<void> _handleRefreshError(dynamic error) async {
    _retryCount++;

    if (_retryCount <= _maxRetries) {
      debugPrint('🔄 Retrying... ($_retryCount/$_maxRetries)');

      // 指数退避重试
      final delay = Duration(seconds: 2 * _retryCount);
      await Future.delayed(delay);

      return _refreshDataWithRetry();
    } else {
      _setErrorState('网络连接失败，请检查网络设置');
    }
  }

  /// 设置加载状态
  void _setLoadingState(LoadingState state) {
    if (_loadingState != state) {
      _loadingState = state;
      if (state != LoadingState.error) {
        _errorMessage = null;
      }
      notifyListeners();
    }
  }

  /// 设置错误状态
  void _setErrorState(String message) {
    _loadingState = LoadingState.error;
    _errorMessage = message;
    notifyListeners();
  }

  /// 异步缓存数据
  void _cacheDataAsync() {
    // 在后台线程中缓存数据，不阻塞UI
    compute(_cacheDataBackground, {
      'btcData': _btcData?.toJson(),
      'historicalData': _historicalData.map((data) => data.toJson()).toList(),
      'rainbowResult': _rainbowResult?.toJson(),
      'lastUpdated': _lastUpdated?.millisecondsSinceEpoch,
    });
  }

  /// 后台缓存数据
  static Future<void> _cacheDataBackground(Map<String, dynamic> data) async {
    try {
      final prefs = await SharedPreferences.getInstance();

      await Future.wait([
        if (data['btcData'] != null)
          prefs.setString('cached_btc_data', json.encode(data['btcData'])),
        if (data['historicalData'] != null)
          prefs.setString(
              'cached_historical_data', json.encode(data['historicalData'])),
        if (data['rainbowResult'] != null)
          prefs.setString(
              'cached_rainbow_result', json.encode(data['rainbowResult'])),
        if (data['lastUpdated'] != null)
          prefs.setInt('cache_timestamp', data['lastUpdated']),
      ]);
    } catch (e) {
      debugPrint('Background cache error: $e');
    }
  }

  /// 加载缓存数据
  Future<void> _loadCachedData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cacheTimestamp = prefs.getInt('cache_timestamp');

      if (cacheTimestamp != null) {
        final cacheTime = DateTime.fromMillisecondsSinceEpoch(cacheTimestamp);
        final age = DateTime.now().difference(cacheTime);

        // 只加载有效的缓存数据
        if (age < _cacheValidDuration) {
          final btcDataJson = prefs.getString('cached_btc_data');
          final historicalDataJson = prefs.getString('cached_historical_data');
          final rainbowResultJson = prefs.getString('cached_rainbow_result');

          if (btcDataJson != null && rainbowResultJson != null) {
            _btcData = BTCData.fromJson(json.decode(btcDataJson));
            _rainbowResult =
                RainbowDCAResult.fromJson(json.decode(rainbowResultJson));

            if (historicalDataJson != null) {
              final List<dynamic> historicalList =
                  json.decode(historicalDataJson);
              _historicalData = historicalList
                  .map((data) => HistoricalData.fromJson(data))
                  .toList();
            }

            _lastUpdated = cacheTime;
            _setLoadingState(LoadingState.loaded);

            debugPrint('✅ Loaded cached data (age: ${age.inMinutes}min)');
          }
        } else {
          debugPrint('🗑️ Cache expired (age: ${age.inMinutes}min)');
          _clearCache();
        }
      }
    } catch (e) {
      debugPrint('❌ Error loading cached data: $e');
      _clearCache();
    }
  }

  /// 清理缓存
  Future<void> _clearCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await Future.wait([
        prefs.remove('cached_btc_data'),
        prefs.remove('cached_historical_data'),
        prefs.remove('cached_rainbow_result'),
        prefs.remove('cache_timestamp'),
      ]);
    } catch (e) {
      debugPrint('Error clearing cache: $e');
    }
  }

  /// 发送价格提醒
  Future<void> sendPriceReminder() async {
    try {
      final notifications = NotificationService();
      await notifications.sendSmartReminder();

      // 记录最后提醒时间
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(
          'last_reminder_time', DateTime.now().millisecondsSinceEpoch);
    } catch (e) {
      debugPrint('Error sending price reminder: $e');
      throw Exception('发送价格提醒失败: $e');
    }
  }

  

  /// 强制刷新（忽略缓存）
  Future<void> forceRefresh() async {
    await _clearCache();
    await _performRefresh();
  }

  /// 获取数据新鲜度状态
  String getDataFreshnessStatus() {
    if (_lastUpdated == null) return '暂无数据';

    final age = DateTime.now().difference(_lastUpdated!);
    if (age.inMinutes < 1) return '刚刚更新';
    if (age.inMinutes < 60) return '${age.inMinutes}分钟前';
    if (age.inHours < 24) return '${age.inHours}小时前';
    return '${age.inDays}天前';
  }

  /// 更新通知调度
  Future<void> updateNotificationSchedule() async {
    try {
      await _notificationScheduler.updateSchedule();
      notifyListeners();
    } catch (e) {
      debugPrint('Error updating notification schedule: $e');
    }
  }

  /// 获取下次通知时间
  Future<String> getNextNotificationTimeString() async {
    try {
      return await _notificationScheduler.getNextNotificationTimeString();
    } catch (e) {
      debugPrint('Error getting next notification time: $e');
      return '获取失败';
    }
  }

  /// 获取提醒开关状态
  Future<bool> getIsReminderEnabled() async {
    final settings = await _storageService.getReminderSettings();
    return settings['enabled'] as bool;
  }

  /// 切换提醒状态
  Future<void> toggleReminderEnabled() async {
    final settings = await _storageService.getReminderSettings();
    final currentStatus = settings['enabled'] as bool;
    await _storageService.setReminderSettings(
      enabled: !currentStatus,
      times: settings['times'] as List<Map<String, int>>,
    );
    await _notificationScheduler.updateSchedule(); // 状态改变后更新调度
    notifyListeners();
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    _debounceTimer?.cancel();
    _notificationScheduler.stop();
    _systemTrayService.dispose();
    super.dispose();
  }
}