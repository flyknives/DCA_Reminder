import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart' as fl;
import '../providers/kline_chart_provider.dart';
import '../models/btc_data.dart';
import '../models/investment_record.dart';
import '../utils/helpers.dart';
import '../utils/theme.dart';

class KlineChartScreen extends StatefulWidget {
  const KlineChartScreen({super.key});

  @override
  State<KlineChartScreen> createState() => _KlineChartScreenState();
}

class _KlineChartScreenState extends State<KlineChartScreen> {
  double minY = 0;
  double maxY = 0;
  List<fl.FlSpot> averageCostSpots = [];
  @override
  void initState() {
    super.initState();
    // Fetch initial data when the screen loads
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<KlineChartProvider>(context, listen: false).fetchKlineData();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('BTC K线图'),
        backgroundColor: AppTheme.primaryColor,
      ),
      body: Consumer<KlineChartProvider>(
        builder: (context, provider, child) {
          if (provider.loadingState == KlineLoadingState.loading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (provider.loadingState == KlineLoadingState.error) {
            return Center(child: Text('错误: ${provider.errorMessage}'));
          }
          if (provider.klineData.isEmpty) {
            return const Center(child: Text('没有K线数据'));
          }
          return Column(
            children: [
              _buildIntervalSelector(provider),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: _buildCandlestickChart(provider.klineData),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildIntervalSelector(KlineChartProvider provider) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildIntervalButton(provider, '15m', '15分钟'),
          _buildIntervalButton(provider, '1h', '1小时'),
          _buildIntervalButton(provider, '4h', '4小时'),
          _buildIntervalButton(provider, '1d', '1天'),
          _buildIntervalButton(provider, '1w', '1周'),
          _buildIntervalButton(provider, '1M', '1月'),
        ],
      ),
    );
  }

  Widget _buildIntervalButton(KlineChartProvider provider, String interval, String label) {
    final isSelected = provider.selectedInterval == interval;
    return ElevatedButton(
      onPressed: () => provider.changeInterval(interval),
      style: ElevatedButton.styleFrom(
        backgroundColor: isSelected ? AppTheme.primaryColor : AppTheme.surfaceColor,
        foregroundColor: isSelected ? Colors.black : AppTheme.textColor,
      ),
      child: Text(label),
    );
  }

  Widget _buildCandlestickChart(List<HistoricalData> data) {
    final KlineChartProvider provider = context.read<KlineChartProvider>();
    final List<InvestmentRecord> investmentRecords = provider.investmentRecords;
    final double averageCost = provider.averageCost;

    final List<fl.FlSpot> spots = data.asMap().entries.map((entry) {
      final historicalData = entry.value;
      return fl.FlSpot(historicalData.timestamp.millisecondsSinceEpoch.toDouble(), historicalData.close);
    }).toList();

    // Calculate minX and maxX based on actual timestamps
    final double minX = data.first.timestamp.millisecondsSinceEpoch.toDouble();
    final double maxX = data.last.timestamp.millisecondsSinceEpoch.toDouble();

    // Calculate minY and maxY with some padding
    minY = data.map((d) => d.low).reduce((a, b) => a < b ? a : b) * 0.95;
    maxY = data.map((d) => d.high).reduce((a, b) => a > b ? a : b) * 1.05;

    // Create spots for average cost line
    if (averageCost > 0) {
      averageCostSpots = [
        fl.FlSpot(minX, averageCost),
        fl.FlSpot(maxX, averageCost),
      ];
    }

    // Create spots for buy points
    final List<fl.FlSpot> buySpots = investmentRecords.map<fl.FlSpot>((record) {
      // Find the closest historical data point for the investment date
      HistoricalData? closestData;
      double minDiff = double.infinity;
      for (var hd in data) {
        final diff = (hd.timestamp.millisecondsSinceEpoch - record.date.millisecondsSinceEpoch).abs();
        if (diff < minDiff) {
          minDiff = diff.toDouble();
          closestData = hd;
        }
      }
      if (closestData != null) {
        return fl.FlSpot(closestData.timestamp.millisecondsSinceEpoch.toDouble(), closestData.close);
      }
      return fl.FlSpot(0, 0); // Fallback, should not happen if data is available
    }).toList();

    // Determine if the average cost label should be visible
    final bool isAverageCostVisible = averageCost > 0 && averageCost >= minY && averageCost <= maxY;

    return Column(
      children: [
        Expanded(
          child: fl.LineChart(
            fl.LineChartData(
              clipData: const fl.FlClipData.none(), // Allow tooltips to render outside chart bounds
              lineTouchData: fl.LineTouchData(
                touchTooltipData: fl.LineTouchTooltipData(
                  getTooltipItems: (List<fl.LineBarSpot> touchedSpots) {
                    return touchedSpots.map((fl.LineBarSpot touchedSpot) {
                      final textStyle = TextStyle(
                        color: touchedSpot.bar.color,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      );
                      // For buy points (yellow dots)
                      if (touchedSpot.barIndex == 1) {
                        return fl.LineTooltipItem(
                          AppHelpers.formatPrice(touchedSpot.y),
                          textStyle,
                        );
                      }
                      // For average cost line (blue line), hide tooltip
                      if (touchedSpot.barIndex == 2) {
                        return null; // Hide tooltip for average cost line
                      }
                      // For main price line, show date and price
                      final dateTime = DateTime.fromMillisecondsSinceEpoch(touchedSpot.x.toInt());
                      return fl.LineTooltipItem(
                        '${dateTime.month}/${dateTime.day} ${dateTime.hour}:00\n${AppHelpers.formatPrice(touchedSpot.y)}',
                        textStyle,
                      );
                    }).toList();
                  },
                ),
              ),
              gridData: const fl.FlGridData(show: false),
              titlesData: fl.FlTitlesData(
                bottomTitles: fl.AxisTitles(
                  sideTitles: fl.SideTitles(
                    showTitles: true,
                    getTitlesWidget: (value, meta) {
                      final dateTime = DateTime.fromMillisecondsSinceEpoch(value.toInt());
                      final interval = provider.selectedInterval;
                      String text;
                      if (interval == '1d' || interval == '1w' || interval == '1M') {
                        text = '${dateTime.year}\n${dateTime.month}/${dateTime.day}';
                      } else {
                        text = '${dateTime.month}/${dateTime.day}\n${dateTime.hour}:00';
                      }
                      return const Text(
                        text,
                        style: TextStyle(color: AppTheme.textColor, fontSize: 10),
                      );
                    },
                    interval: (maxX - minX) / 5, // Show about 5 labels
                    reservedSize: 30,
                  ),
                ),
                leftTitles: fl.AxisTitles(
                  sideTitles: fl.SideTitles(
                    showTitles: true,
                    getTitlesWidget: (value, meta) {
                      return Text(
                        value.toStringAsFixed(0),
                        style: const TextStyle(color: AppTheme.textColor, fontSize: 10),
                      );
                    },
                    reservedSize: 40,
                  ),
                ),
                topTitles: const fl.AxisTitles(sideTitles: fl.SideTitles(showTitles: false)),
                rightTitles: const fl.AxisTitles(sideTitles: fl.SideTitles(showTitles: false)),
              ),
              borderData: fl.FlBorderData(
                show: true,
                border: Border.all(color: const Color(0xff37434d), width: 1),
              ),
              minX: minX,
              maxX: maxX,
              minY: minY,
              maxY: maxY,
              lineBarsData: [
                fl.LineChartBarData(
                  spots: spots,
                  isCurved: true,
                  color: AppTheme.primaryColor,
                  barWidth: 2,
                  isStrokeCapRound: true,
                  dotData: const fl.FlDotData(show: false),
                  belowBarData: fl.BarAreaData(show: false),
                ),
                // Buy points
                fl.LineChartBarData(
                  spots: buySpots,
                  isCurved: false,
                  color: Colors.yellow,
                  barWidth: 0, // No line
                  isStrokeCapRound: true,
                  dotData: fl.FlDotData(
                    show: true,
                    getDotPainter: (spot, percent, bar, index) => fl.FlDotCirclePainter(
                      radius: 4,
                      color: Colors.yellow,
                      strokeWidth: 1,
                      strokeColor: Colors.black,
                    ),
                  ),
                  belowBarData: fl.BarAreaData(show: false),
                ),
                // Average cost line
                if (isAverageCostVisible) // Only show if average cost is in the visible range
                  fl.LineChartBarData(
                    spots: averageCostSpots,
                    isCurved: false,
                    color: Colors.blueAccent,
                    barWidth: 2,
                    isStrokeCapRound: true,
                    dotData: const fl.FlDotData(show: false),
                    belowBarData: fl.BarAreaData(show: false),
                  ),
              ],
            ),
          ),
        ),
        if (isAverageCostVisible) // Only show if average cost is in the visible range
          Padding(
            padding: const EdgeInsets.only(top: 8.0),
            child: Text(
              '平均持仓成本: ${AppHelpers.formatPrice(averageCost)}',
              style: const TextStyle(
                color: AppTheme.textSecondaryColor,
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
      ],
    );
  }
}
