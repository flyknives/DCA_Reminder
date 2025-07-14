import 'package:flutter/material.dart';
import '../utils/theme.dart';

class ErrorWidget extends StatelessWidget {
  final String title;
  final String? message;
  final String? actionText;
  final VoidCallback? onRetry;
  final IconData? icon;
  final bool showDetails;
  final String? details;

  const ErrorWidget({
    super.key,
    required this.title,
    this.message,
    this.actionText,
    this.onRetry,
    this.icon,
    this.showDetails = false,
    this.details,
  });

  factory ErrorWidget.network({
    VoidCallback? onRetry,
    String? details,
  }) {
    return ErrorWidget(
      title: '网络连接失败',
      message: '请检查您的网络连接并重试',
      actionText: '重试',
      onRetry: onRetry,
      icon: Icons.wifi_off,
      showDetails: details != null,
      details: details,
    );
  }

  factory ErrorWidget.server({
    VoidCallback? onRetry,
    String? details,
  }) {
    return ErrorWidget(
      title: '服务暂时不可用',
      message: '服务器正在维护中，请稍后重试',
      actionText: '重试',
      onRetry: onRetry,
      icon: Icons.error_outline,
      showDetails: details != null,
      details: details,
    );
  }

  factory ErrorWidget.dataFormat({
    VoidCallback? onRetry,
    String? details,
  }) {
    return ErrorWidget(
      title: '数据解析失败',
      message: '数据格式异常，请重新加载',
      actionText: '重新加载',
      onRetry: onRetry,
      icon: Icons.broken_image,
      showDetails: details != null,
      details: details,
    );
  }

  factory ErrorWidget.generic({
    required String title,
    String? message,
    VoidCallback? onRetry,
    String? details,
  }) {
    return ErrorWidget(
      title: title,
      message: message ?? '发生了未知错误',
      actionText: '重试',
      onRetry: onRetry,
      icon: Icons.error,
      showDetails: details != null,
      details: details,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        margin: const EdgeInsets.all(24),
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: AppTheme.cardColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: AppTheme.errorColor.withAlpha(77),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: AppTheme.shadowColor.withAlpha(26),
              spreadRadius: 2,
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 错误图标
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppTheme.errorColor.withAlpha(26),
              ),
              child: Icon(
                icon ?? Icons.error_outline,
                size: 40,
                color: AppTheme.errorColor,
              ),
            ),
            const SizedBox(height: 24),

            // 错误标题
            Text(
              title,
              style: const TextStyle(
                color: AppTheme.textColor,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),

            // 错误消息
            if (message != null)
              Text(
                message!,
                style: TextStyle(
                  color: AppTheme.textSecondaryColor,
                  fontSize: 14,
                  height: 1.4,
                ),
                textAlign: TextAlign.center,
              ),

            // 详细信息（可展开）
            if (showDetails && details != null) ...[
              const SizedBox(height: 16),
              _ErrorDetailsSection(details: details!),
            ],

            // 操作按钮
            const SizedBox(height: 32),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (onRetry != null)
                  ElevatedButton.icon(
                    onPressed: onRetry,
                    icon: const Icon(Icons.refresh),
                    label: Text(actionText ?? '重试'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryColor,
                      foregroundColor: AppTheme.backgroundColor,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                    ),
                  ),
                if (showDetails && details != null) ...[
                  const SizedBox(width: 16),
                  OutlinedButton(
                    onPressed: () => _showErrorDetails(context),
                    child: const Text('查看详情'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppTheme.textSecondaryColor,
                      side: BorderSide(color: AppTheme.textSecondaryColor),
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showErrorDetails(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('错误详情'),
        content: SingleChildScrollView(
          child: Text(
            details!,
            style: const TextStyle(fontFamily: 'monospace'),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('关闭'),
          ),
        ],
      ),
    );
  }
}

class _ErrorDetailsSection extends StatefulWidget {
  final String details;

  const _ErrorDetailsSection({required this.details});

  @override
  State<_ErrorDetailsSection> createState() => _ErrorDetailsSectionState();
}

class _ErrorDetailsSectionState extends State<_ErrorDetailsSection> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        GestureDetector(
          onTap: () => setState(() => _isExpanded = !_isExpanded),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                '技术详情',
                style: TextStyle(
                  color: AppTheme.textSecondaryColor,
                  fontSize: 12,
                  decoration: TextDecoration.underline,
                ),
              ),
              const SizedBox(width: 4),
              Icon(
                _isExpanded ? Icons.expand_less : Icons.expand_more,
                size: 16,
                color: AppTheme.textSecondaryColor,
              ),
            ],
          ),
        ),
        if (_isExpanded) ...[
          const SizedBox(height: 8),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
            color: AppTheme.surfaceColor.withAlpha(_animation.value.toInt()),
            borderRadius: widget.borderRadius ?? BorderRadius.circular(8),
          ),
            child: Text(
              widget.details,
              style: TextStyle(
                color: AppTheme.textSecondaryColor,
                fontSize: 11,
                fontFamily: 'monospace',
              ),
            ),
          ),
        ],
      ],
    );
  }
}

/// 简化的错误提示组件
class SimpleErrorWidget extends StatelessWidget {
  final String message;
  final VoidCallback? onRetry;

  const SimpleErrorWidget({
    super.key,
    required this.message,
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: 48,
            color: AppTheme.errorColor,
          ),
          const SizedBox(height: 16),
          Text(
            message,
            style: TextStyle(
              color: AppTheme.textSecondaryColor,
              fontSize: 14,
            ),
            textAlign: TextAlign.center,
          ),
          if (onRetry != null) ...[
            const SizedBox(height: 16),
            TextButton(
              onPressed: onRetry,
              child: const Text('重试'),
            ),
          ],
        ],
      ),
    );
  }
}