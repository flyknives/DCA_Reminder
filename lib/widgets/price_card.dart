import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/btc_data.dart';
import '../utils/theme.dart';

class PriceCard extends StatelessWidget {
  final BTCData? btcData;
  final bool isLoading;

  const PriceCard({
    super.key,
    this.btcData,
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
            _buildPriceSection(),
            const SizedBox(height: 12),
            _buildChangeSection(),
            const SizedBox(height: 16),
            _buildTimestamp(),
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
            color: AppTheme.secondaryColor.withAlpha(26),
            shape: BoxShape.circle,
          ),
          child: Icon(
            Icons.currency_bitcoin,
            color: AppTheme.secondaryColor,
            size: 24,
          ),
        ),
        const SizedBox(width: 12),
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '💰 当前价格',
                style: TextStyle(
                  color: AppTheme.textSecondaryColor,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                'Bitcoin (BTC)',
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

  Widget _buildPriceSection() {
    if (btcData == null) {
      return _buildPlaceholderPrice();
    }

    final formatter = NumberFormat.currency(
      symbol: '\$',
      decimalDigits: 2,
    );

    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(
          child: Text(
            formatter.format(btcData!.price),
            style: const TextStyle(
              color: AppTheme.secondaryColor,
              fontSize: 32,
              fontWeight: FontWeight.bold,
              height: 1.1,
            ),
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: AppTheme.surfaceColor,
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Text(
            'USDT',
            style: TextStyle(
              color: AppTheme.textSecondaryColor,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildChangeSection() {
    if (btcData == null) {
      return _buildPlaceholderChange();
    }

    final isPositive = btcData!.priceChangePercent24h >= 0;
    final changeColor = isPositive ? AppTheme.successColor : AppTheme.errorColor;
    final changeIcon = isPositive ? Icons.trending_up : Icons.trending_down;
    final changePrefix = isPositive ? '+' : '';

    final absoluteChange = NumberFormat.currency(
      symbol: '\$',
      decimalDigits: 2,
    ).format(btcData!.priceChange24h.abs());

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: changeColor.withAlpha(26),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: changeColor.withAlpha(77),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Icon(
            changeIcon,
            color: changeColor,
            size: 20,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '24小时变化',
                  style: TextStyle(
                    color: AppTheme.textSecondaryColor,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Text(
                      '$changePrefix${btcData!.priceChangePercent24h.toStringAsFixed(2)}%',
                      style: TextStyle(
                        color: changeColor,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '($changePrefix$absoluteChange)',
                      style: TextStyle(
                        color: changeColor,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: changeColor.withAlpha(51),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              isPositive ? '涨' : '跌',
              style: TextStyle(
                color: changeColor,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimestamp() {
    if (btcData == null) return const SizedBox.shrink();

    final formatter = DateFormat('yyyy-MM-dd HH:mm:ss');
    
    return Row(
      children: [
        Icon(
          Icons.update,
          size: 14,
          color: AppTheme.textSecondaryColor,
        ),
        const SizedBox(width: 4),
        Text(
          '数据时间: ${formatter.format(btcData!.timestamp)}',
          style: TextStyle(
            color: AppTheme.textSecondaryColor,
            fontSize: 11,
          ),
        ),
      ],
    );
  }

  Widget _buildPlaceholderPrice() {
    return Container(
      height: 40,
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor.withOpacity(0.5),
        borderRadius: BorderRadius.circular(8),
      ),
      child: const Center(
        child: Text(
          '加载中...',
          style: TextStyle(
            color: AppTheme.textSecondaryColor,
            fontSize: 16,
          ),
        ),
      ),
    );
  }

  Widget _buildPlaceholderChange() {
    return Container(
      height: 60,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor.withOpacity(0.5),
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Center(
        child: Text(
          '计算变化中...',
          style: TextStyle(
            color: AppTheme.textSecondaryColor,
            fontSize: 14,
          ),
        ),
      ),
    );
  }
} 