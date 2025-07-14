import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../models/btc_data.dart';

class APIService {
  static const String _baseUrl = 'https://api.binance.com/api/v3';
  late final Dio _dio;

  APIService() {
    _dio = Dio(BaseOptions(
      baseUrl: _baseUrl,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
      headers: {
        'Content-Type': 'application/json',
      },
    ));
    
    // 添加日志拦截器（仅在调试模式下）
    if (kDebugMode) {
      _dio.interceptors.add(LogInterceptor(
        requestBody: true,
        responseBody: true,
        logPrint: (object) => debugPrint(object.toString()),
      ));
    }
  }

  /// 获取BTC当前价格数据
  Future<BTCData> getBTCPrice() async {
    try {
      final response = await _dio.get('/ticker/24hr', queryParameters: {
        'symbol': 'BTCUSDT',
      });
      
      if (response.statusCode == 200) {
        return BTCData.fromJson(response.data);
      } else {
        throw Exception('Failed to fetch BTC price: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Error fetching BTC price: $e');
      rethrow;
    }
  }

  /// 获取历史K线数据
  Future<List<HistoricalData>> getHistoricalData({
    String symbol = 'BTCUSDT',
    String interval = '1d',
    int limit = 200,
  }) async {
    try {
      final response = await _dio.get('/klines', queryParameters: {
        'symbol': symbol,
        'interval': interval,
        'limit': limit,
      });
      
      if (response.statusCode == 200) {
        final List<dynamic> klines = response.data;
        return klines.map((kline) => HistoricalData.fromKlineData(kline)).toList();
      } else {
        throw Exception('Failed to fetch historical data: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Error fetching historical data: $e');
      rethrow;
    }
  }

  /// 获取多个时间周期的数据
  Future<Map<String, List<HistoricalData>>> getMultiTimeframeData({
    String symbol = 'BTCUSDT',
    List<String> intervals = const ['1h', '4h', '1d'],
    int limit = 100,
  }) async {
    try {
      final Map<String, List<HistoricalData>> result = {};
      
      for (String interval in intervals) {
        final data = await getHistoricalData(
          symbol: symbol,
          interval: interval,
          limit: limit,
        );
        result[interval] = data;
      }
      
      return result;
    } catch (e) {
      debugPrint('Error fetching multi-timeframe data: $e');
      rethrow;
    }
  }

  /// 检查API连接状态
  Future<bool> checkConnection() async {
    try {
      final response = await _dio.get('/ping');
      return response.statusCode == 200;
    } catch (e) {
      debugPrint('API connection check failed: $e');
      return false;
    }
  }

  /// 获取服务器时间
  Future<DateTime> getServerTime() async {
    try {
      final response = await _dio.get('/time');
      if (response.statusCode == 200) {
        final serverTime = response.data['serverTime'];
        return DateTime.fromMillisecondsSinceEpoch(serverTime);
      } else {
        throw Exception('Failed to get server time');
      }
    } catch (e) {
      debugPrint('Error getting server time: $e');
      return DateTime.now(); // 降级到本地时间
    }
  }

  /// 获取交易对信息
  Future<Map<String, dynamic>?> getSymbolInfo(String symbol) async {
    try {
      final response = await _dio.get('/exchangeInfo');
      if (response.statusCode == 200) {
        final symbols = response.data['symbols'] as List;
        for (var symbolInfo in symbols) {
          if (symbolInfo['symbol'] == symbol) {
            return symbolInfo;
          }
        }
      }
      return null;
    } catch (e) {
      debugPrint('Error getting symbol info: $e');
      return null;
    }
  }

  /// 获取指定日期的BTC价格
  Future<double> getBTCPriceByDate(DateTime date) async {
    try {
      // Binance API 的 /klines 接口可以获取历史K线数据
      // 我们获取指定日期的1天K线数据，取其收盘价作为当天的价格
      final response = await _dio.get('/klines', queryParameters: {
        'symbol': 'BTCUSDT',
        'interval': '1d',
        'startTime': date.millisecondsSinceEpoch,
        'limit': 1,
      });

      if (response.statusCode == 200 && response.data.isNotEmpty) {
        // klines 数组的第一个元素是指定日期的K线数据
        // kline[4] 是收盘价
        return double.parse(response.data[0][4]);
      } else {
        throw Exception('Failed to fetch BTC price for date: ${date.toIso8601String()}');
      }
    } catch (e) {
      debugPrint('Error fetching BTC price by date: $e');
      rethrow;
    }
  }

  /// 释放资源
  void dispose() {
    _dio.close();
  }
} 