import 'dart:math';
import 'package:flutter/foundation.dart';
import '../models/btc_data.dart';
import 'storage_service.dart';

class RainbowDCAService {
  // 彩虹DCA配置
  static const double defaultBaseAmount = 100.0;

  // 彩虹倍数配置
  static final Map<double, double> rainbowMultipliers = {
    0.45: 3.0, // 深蓝区
    0.60: 2.0, // 蓝色区
    0.75: 1.5, // 绿色区
    1.0: 1.0, // 黄色区
    1.3: 0.75, // 橙色区
    1.6: 0.5, // 红色区
    1.9: 0.25, // 深红区
  };

  static const double defaultTopMultiplier = 0.1; // 狂热区

  /// 计算彩虹DCA建议（异步版本，使用存储的基准金额）
  static Future<RainbowDCAResult> calculateRainbowDCAAsync({
    required double currentPrice,
    required List<HistoricalData> historicalData,
  }) async {
    final storage = await StorageService.getInstance();
    final baseAmount = await storage.getBaseAmount();

    return calculateRainbowDCA(
      currentPrice: currentPrice,
      historicalData: historicalData,
      baseAmount: baseAmount,
    );
  }

  /// 计算彩虹DCA建议
  static RainbowDCAResult calculateRainbowDCA({
    required double currentPrice,
    required List<HistoricalData> historicalData,
    double? baseAmount,
  }) {
    try {
      if (historicalData.length < 100) {
        // 数据不足，返回默认值
        return _createDefaultResult(currentPrice, baseAmount);
      }

      // 计算对数回归
      final regressionPrice = _calculateLogRegression(historicalData);

      // 计算价格比率
      final priceRatio = currentPrice / regressionPrice;

      // 确定倍数
      final multiplier = _determineMultiplier(priceRatio);

      // 计算建议金额
      final suggestedAmount = (baseAmount ?? defaultBaseAmount) * multiplier;

      // 获取区域信息
      final zoneInfo = _getZoneInfo(multiplier);

      return RainbowDCAResult(
        currentPrice: currentPrice,
        regressionPrice: regressionPrice,
        priceRatio: priceRatio,
        multiplier: multiplier,
        suggestedAmount: suggestedAmount,
        zone: zoneInfo['zone']!,
        marketStatus: zoneInfo['status']!,
        calculatedAt: DateTime.now(),
      );
    } catch (e) {
      debugPrint('Error calculating Rainbow DCA: $e');
      return _createDefaultResult(currentPrice);
    }
  }

  /// 计算对数回归价格
  static double _calculateLogRegression(List<HistoricalData> data) {
    final prices = data.map((d) => d.close).toList();
    final n = prices.length;

    // 创建时间索引
    final timeIndices = List.generate(n, (index) => index.toDouble());

    // 计算对数价格
    final logPrices = prices.map((price) => log(price)).toList();

    // 计算线性回归系数
    final sumX = timeIndices.reduce((a, b) => a + b);
    final sumY = logPrices.reduce((a, b) => a + b);
    final sumXY = List.generate(n, (i) => timeIndices[i] * logPrices[i])
        .reduce((a, b) => a + b);
    final sumXX = timeIndices.map((x) => x * x).reduce((a, b) => a + b);

    // 线性回归公式
    final slope = (n * sumXY - sumX * sumY) / (n * sumXX - sumX * sumX);
    final intercept = (sumY - slope * sumX) / n;

    // 计算当前时间点的回归价格
    final currentTimeIndex = n - 1;
    final predictedLogPrice = slope * currentTimeIndex + intercept;

    return exp(predictedLogPrice);
  }

  /// 根据价格比率确定倍数
  static double _determineMultiplier(double priceRatio) {
    for (final entry in rainbowMultipliers.entries) {
      if (priceRatio < entry.key) {
        return entry.value;
      }
    }
    return defaultTopMultiplier;
  }

  /// 获取彩虹区域信息
  static Map<String, String> _getZoneInfo(double multiplier) {
    if (multiplier >= 2.5) {
      return {
        'zone': '🔵 深蓝区',
        'status': '极度恐慌，大幅买入',
      };
    } else if (multiplier >= 1.8) {
      return {
        'zone': '🔵 蓝色区',
        'status': '严重低估，增加买入',
      };
    } else if (multiplier >= 1.3) {
      return {
        'zone': '🟢 绿色区',
        'status': '略微低估，适度增加',
      };
    } else if (multiplier >= 0.9) {
      return {
        'zone': '🟡 黄色区',
        'status': '公允价值，正常买入',
      };
    } else if (multiplier >= 0.6) {
      return {
        'zone': '🟠 橙色区',
        'status': '略微高估，减少买入',
      };
    } else if (multiplier >= 0.3) {
      return {
        'zone': '🔴 红色区',
        'status': '明显高估，大幅减少',
      };
    } else if (multiplier >= 0.15) {
      return {
        'zone': '🔴 深红区',
        'status': '严重高估，最小买入',
      };
    } else {
      return {
        'zone': '🟣 狂热区',
        'status': '泡沫期，极少买入',
      };
    }
  }

  /// 创建默认结果
  static RainbowDCAResult _createDefaultResult(double currentPrice,
      [double? baseAmount]) {
    return RainbowDCAResult(
      currentPrice: currentPrice,
      regressionPrice: currentPrice,
      priceRatio: 1.0,
      multiplier: 1.0,
      suggestedAmount: baseAmount ?? defaultBaseAmount,
      zone: '🟡 黄色区',
      marketStatus: '数据不足，使用默认值',
      calculatedAt: DateTime.now(),
    );
  }

  /// 批量计算历史彩虹DCA数据（用于图表显示）
  static List<RainbowDCAResult> calculateHistoricalRainbow({
    required List<HistoricalData> historicalData,
    int lookbackDays = 30,
  }) {
    final results = <RainbowDCAResult>[];

    if (historicalData.length < 100) {
      return results;
    }

    for (int i = 100; i < historicalData.length; i++) {
      final currentPrice = historicalData[i].close;
      final dataSubset = historicalData.sublist(0, i + 1);

      try {
        final result = calculateRainbowDCA(
          currentPrice: currentPrice,
          historicalData: dataSubset,
        );
        results.add(result);
      } catch (e) {
        debugPrint('Error calculating historical rainbow at index $i: $e');
      }
    }

    // 返回最近指定天数的数据
    if (results.length > lookbackDays) {
      return results.sublist(results.length - lookbackDays);
    }

    return results;
  }

  /// 计算投资效率指标
  static Map<String, double> calculateInvestmentMetrics({
    required List<RainbowDCAResult> historicalResults,
    required double totalInvested,
  }) {
    if (historicalResults.isEmpty) {
      return {
        'averageMultiplier': 1.0,
        'totalSuggested': totalInvested,
        'efficiency': 1.0,
      };
    }

    final totalSuggested =
        historicalResults.map((r) => r.suggestedAmount).reduce((a, b) => a + b);

    final averageMultiplier =
        historicalResults.map((r) => r.multiplier).reduce((a, b) => a + b) /
            historicalResults.length;

    final efficiency = totalInvested / totalSuggested;

    return {
      'averageMultiplier': averageMultiplier,
      'totalSuggested': totalSuggested,
      'efficiency': efficiency,
    };
  }
}
