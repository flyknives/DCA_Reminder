import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/theme.dart';

class ReminderTimePicker extends StatefulWidget {
  final VoidCallback? onTimeChanged;

  const ReminderTimePicker({
    super.key,
    this.onTimeChanged,
  });

  @override
  State<ReminderTimePicker> createState() => _ReminderTimePickerState();
}

class _ReminderTimePickerState extends State<ReminderTimePicker> {
  bool _reminderEnabled = true;
  TimeOfDay _selectedTime = const TimeOfDay(hour: 9, minute: 0);
  late SharedPreferences _prefs;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    try {
      _prefs = await SharedPreferences.getInstance();

      setState(() {
        _reminderEnabled = _prefs.getBool('daily_reminder_enabled') ?? true;

        // 加载保存的时间，默认为上午9点
        final savedHour = _prefs.getInt('reminder_hour') ?? 9;
        final savedMinute = _prefs.getInt('reminder_minute') ?? 0;
        _selectedTime = TimeOfDay(hour: savedHour, minute: savedMinute);

        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error loading reminder settings: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _saveSettings() async {
    try {
      await _prefs.setBool('daily_reminder_enabled', _reminderEnabled);
      await _prefs.setInt('reminder_hour', _selectedTime.hour);
      await _prefs.setInt('reminder_minute', _selectedTime.minute);

      // 触发回调通知父组件
      if (widget.onTimeChanged != null) {
        widget.onTimeChanged!();
      }

      // 显示保存成功提示
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_reminderEnabled
                ? '提醒时间已设置为 ${_selectedTime.format(context)}'
                : '每日提醒已关闭'),
            backgroundColor: AppTheme.primaryColor,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      debugPrint('Error saving reminder settings: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('保存设置失败'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _selectTime() async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.fromSeed(
              seedColor: AppTheme.primaryColor,
              brightness: Brightness.dark,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null && picked != _selectedTime) {
      setState(() {
        _selectedTime = picked;
      });
      await _saveSettings();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(
          color: AppTheme.primaryColor,
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppTheme.primaryColor.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.access_time,
                color: AppTheme.primaryColor,
                size: 24,
              ),
              const SizedBox(width: 12),
              const Text(
                '每日提醒设置',
                style: TextStyle(
                  color: AppTheme.textColor,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // 开关控制
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                '启用每日提醒',
                style: TextStyle(
                  color: AppTheme.textColor,
                  fontSize: 16,
                ),
              ),
              Switch(
                value: _reminderEnabled,
                onChanged: (value) async {
                  setState(() {
                    _reminderEnabled = value;
                  });
                  await _saveSettings();
                },
                activeColor: AppTheme.primaryColor,
                activeTrackColor: AppTheme.primaryColor.withAlpha(77),
                inactiveThumbColor: Colors.grey,
                inactiveTrackColor: Colors.grey.withAlpha(77),
              ),
            ],
          ),

          if (_reminderEnabled) ...[
            const SizedBox(height: 20),

            // 时间选择
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.backgroundColor.withAlpha(128),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppTheme.primaryColor.withAlpha(51),
                ),
              ),
              child: Column(
                children: [
                  const Text(
                    '提醒时间',
                    style: TextStyle(
                      color: AppTheme.textSecondaryColor,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 8),
                  GestureDetector(
                    onTap: _selectTime,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryColor,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.schedule,
                            color: Colors.black,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            _selectedTime.format(context),
                            style: const TextStyle(
                              color: Colors.black,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // 提醒信息
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withAlpha(26),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    color: AppTheme.primaryColor,
                    size: 16,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '每日 ${_selectedTime.format(context)} 将发送BTC价格和投资建议提醒',
                      style: TextStyle(
                        color: AppTheme.textSecondaryColor,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
