import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/btc_data.dart';
import '../utils/theme.dart';

class RainbowDCACard extends StatelessWidget {
  final RainbowDCAResult? rainbowResult;
  final bool isLoading;

  const RainbowDCACard({
    super.key,
    this.rainbowResult,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppTheme.cardColor,
              AppTheme.cardColor.withAlpha(204),
            ],
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            const SizedBox(height: 16),
            _buildSuggestedAmount(),
            const SizedBox(height: 16),
            _buildRainbowZone(),
            const SizedBox(height: 16),
            _buildDetails(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppTheme.primaryColor.withAlpha(26),
            shape: BoxShape.circle,
          ),
          child: Icon(
            Icons.auto_graph,
            color: AppTheme.primaryColor,
            size: 24,
          ),
        ),
        const SizedBox(width: 12),
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '🌈 彩虹DCA建议',
                style: TextStyle(
                  color: AppTheme.textSecondaryColor,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                '智能定投建议',
                style: TextStyle(
                  color: AppTheme.textColor,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
        if (isLoading)
          const SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryColor),
            ),
          ),
      ],
    );
  }

  Widget _buildSuggestedAmount() {
    if (rainbowResult == null) {
      return _buildPlaceholderAmount();
    }

    final formatter = NumberFormat.currency(
      symbol: '\$',
      decimalDigits: 2,
    );

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.primaryColor.withAlpha(26),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppTheme.primaryColor.withAlpha(77),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '建议买入金额',
                  style: TextStyle(
                    color: AppTheme.textSecondaryColor,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  formatter.format(rainbowResult!.suggestedAmount),
                  style: const TextStyle(
                    color: AppTheme.primaryColor,
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: AppTheme.primaryColor,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              children: [
                const Text(
                  '倍数',
                  style: TextStyle(
                    color: Colors.black,
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  '${rainbowResult!.multiplier.toStringAsFixed(2)}x',
                  style: const TextStyle(
                    color: Colors.black,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRainbowZone() {
    if (rainbowResult == null) {
      return _buildPlaceholderZone();
    }

    final zoneColor = AppTheme.getRainbowZoneColor(rainbowResult!.zone);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: zoneColor.withAlpha(26),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: zoneColor.withAlpha(77),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: zoneColor,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '当前区域',
                style: TextStyle(
                  color: AppTheme.textSecondaryColor,
                  fontSize: 14,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            rainbowResult!.zone,
            style: TextStyle(
              color: zoneColor,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            rainbowResult!.marketStatus,
            style: const TextStyle(
              color: AppTheme.textColor,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetails() {
    if (rainbowResult == null) {
      return const SizedBox.shrink();
    }

    return Column(
      children: [
        _buildDetailRow(
          '当前价格',
          '\$${rainbowResult!.currentPrice.toStringAsFixed(2)}',
          Icons.attach_money,
        ),
        const SizedBox(height: 8),
        _buildDetailRow(
          '回归价格',
          '\$${rainbowResult!.regressionPrice.toStringAsFixed(2)}',
          Icons.trending_up,
        ),
        const SizedBox(height: 8),
        _buildDetailRow(
          '价格比率',
          rainbowResult!.priceRatio.toStringAsFixed(3),
          Icons.compare,
        ),
        const SizedBox(height: 12),
        _buildCalculationTime(),
      ],
    );
  }

  Widget _buildDetailRow(String label, String value, IconData icon) {
    return Row(
      children: [
        Icon(
          icon,
          size: 16,
          color: AppTheme.textSecondaryColor,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              color: AppTheme.textSecondaryColor,
              fontSize: 13,
            ),
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            color: AppTheme.textColor,
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildCalculationTime() {
    if (rainbowResult == null) return const SizedBox.shrink();

    final formatter = DateFormat('HH:mm:ss');
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor.withAlpha(128),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.calculate,
            size: 12,
            color: AppTheme.textSecondaryColor,
          ),
          const SizedBox(width: 4),
          Text(
            '计算时间: ${formatter.format(rainbowResult!.calculatedAt)}',
            style: TextStyle(
              color: AppTheme.textSecondaryColor,
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlaceholderAmount() {
    return Container(
      height: 80,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor.withOpacity(0.5),
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Center(
        child: Text(
          '计算建议金额中...',
          style: TextStyle(
            color: AppTheme.textSecondaryColor,
            fontSize: 16,
          ),
        ),
      ),
    );
  }

  Widget _buildPlaceholderZone() {
    return Container(
      height: 100,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor.withAlpha(128),
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Center(
        child: Text(
          '分析彩虹区域中...',
          style: TextStyle(
            color: AppTheme.textSecondaryColor,
            fontSize: 16,
          ),
        ),
      ),
    );
  }
} 