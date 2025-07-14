import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/btc_provider.dart';
import '../widgets/price_card.dart';
import '../widgets/rainbow_dca_card.dart';

import '../widgets/loading_widget.dart';
import '../widgets/error_widget.dart' as custom_error_widget;
import '../widgets/reminder_time_picker.dart';
import '../utils/theme.dart';
import 'settings_screen.dart';
import 'kline_chart_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _setupAnimations();
  }

  void _setupAnimations() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    ));

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.2),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    ));

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildAppBar(),
      body: RefreshIndicator(
        onRefresh: () async {
          final provider = context.read<BTCProvider>();
          await provider.refreshData();
        },
        child: Consumer<BTCProvider>(
          builder: (context, provider, child) {
            if (provider.isLoading && !provider.hasData) {
              return const LoadingWidget(
                message: '正在获取BTC数据...',
              );
            }

            if (provider.hasError && !provider.hasData) {
              return custom_error_widget.ErrorWidget.network(
                onRetry: () => provider.refreshData(),
                details: provider.errorMessage,
              );
            }

            return _buildContent(provider);
          },
        ),
      ),
    );
  }

  AppBar _buildAppBar() {
    return AppBar(
      title: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            '🌈 BTC DCA',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 20,
            ),
          ),
          const SizedBox(width: 8),
          Consumer<BTCProvider>(
            builder: (context, provider, child) {
              if (provider.isLoading) {
                return const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      AppTheme.primaryColor,
                    ),
                  ),
                );
              }
              return const SizedBox.shrink();
            },
          ),
        ],
      ),
      actions: [
        Consumer<BTCProvider>(
          builder: (context, provider, child) {
            return IconButton(
              icon: provider.isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : const Icon(Icons.refresh),
              onPressed: provider.isLoading ? null : provider.refreshData,
              tooltip: provider.isLoading ? '更新中...' : '刷新数据',
            );
          },
        ),
        IconButton(
          icon: const Icon(Icons.settings),
          onPressed: () => _navigateToSettings(),
        ),
        IconButton(
          icon: const Icon(Icons.show_chart),
          onPressed: () => _navigateToKlineChart(),
          tooltip: '查看K线图',
        ),
        Consumer<BTCProvider>(
          builder: (context, provider, child) {
            return IconButton(
              icon: Icon(
                provider.hasError ? Icons.warning : Icons.info_outline,
                color: provider.hasError
                    ? AppTheme.errorColor
                    : AppTheme.textSecondaryColor,
              ),
              onPressed: () => _showInfoDialog(provider),
            );
          },
        ),
      ],
    );
  }

  Widget _buildContent(BTCProvider provider) {
    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return FadeTransition(
          opacity: _fadeAnimation,
          child: SlideTransition(
            position: _slideAnimation,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // 时间和更新状态
                  _buildStatusBar(provider),
                  const SizedBox(height: 16),

                  // 价格卡片
                  PriceCard(
                    btcData: provider.btcData,
                    isLoading: provider.isLoading,
                  ),
                  const SizedBox(height: 16),

                  // 彩虹DCA卡片
                  RainbowDCACard(
                    rainbowResult: provider.rainbowResult,
                    isLoading: provider.isLoading,
                  ),
                  const SizedBox(height: 24),

                  // 提醒时间设置
                  ReminderTimePicker(
                    onTimeChanged: () {
                      provider.updateNotificationSchedule();
                    },
                  ),
                  const SizedBox(height: 24),

                  // 下次提醒时间
                  _buildNextReminderInfo(),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildStatusBar(BTCProvider provider) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              const Icon(
                Icons.access_time,
                size: 16,
                color: AppTheme.textSecondaryColor,
              ),
              const SizedBox(width: 8),
              Text(
                '更新: ${provider.getDataFreshnessStatus()}',
                style: const TextStyle(
                  color: AppTheme.textSecondaryColor,
                  fontSize: 12,
                ),
              ),
            ],
          ),
          Row(
            children: [
              Icon(
                provider.hasError
                    ? Icons.error_outline
                    : Icons.check_circle_outline,
                size: 16,
                color: provider.hasError
                    ? AppTheme.errorColor
                    : AppTheme.successColor,
              ),
              const SizedBox(width: 4),
              Text(
                provider.hasError ? '连接失败' : '数据正常',
                style: TextStyle(
                  color: provider.hasError
                      ? AppTheme.errorColor
                      : AppTheme.successColor,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildNextReminderInfo() {
    return Consumer<BTCProvider>(
      builder: (context, provider, child) {
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppTheme.surfaceColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: AppTheme.primaryColor.withAlpha(77),
              width: 1,
            ),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withAlpha(26),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.notifications_active,
                  color: AppTheme.primaryColor,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '下次提醒时间',
                      style: TextStyle(
                        color: AppTheme.textSecondaryColor,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 2),
                    FutureBuilder<String>(
                      future: provider.getNextNotificationTimeString(),
                      builder: (context, snapshot) {
                        return Text(
                          snapshot.data ?? '获取中...',
                          style: const TextStyle(
                            color: AppTheme.textColor,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
              
            ],
          ),
        );
      },
    );
  }

  void _showInfoDialog(BTCProvider provider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.surfaceColor,
        title: const Text(
          '应用信息',
          style: TextStyle(color: AppTheme.textColor),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildInfoRow('版本', '1.0.0'),
            _buildInfoRow('数据源', 'Binance API'),
            _buildInfoRow('更新频率', '每5分钟'),
            _buildInfoRow('提醒时间', '每日 10:00'),
            _buildInfoRow('最后更新', provider.getDataFreshnessStatus()),
            if (provider.hasError) ...[
              const SizedBox(height: 8),
              Text(
                '错误信息：${provider.errorMessage}',
                style: const TextStyle(
                  color: AppTheme.errorColor,
                  fontSize: 12,
                ),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text(
              '确定',
              style: TextStyle(color: AppTheme.primaryColor),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: AppTheme.textSecondaryColor,
              fontSize: 14,
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              color: AppTheme.textColor,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  void _navigateToSettings() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const SettingsScreen(),
      ),
    );
  }

  void _navigateToKlineChart() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const KlineChartScreen(),
      ),
    );
  }
}
