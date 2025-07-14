import 'dart:async';
import 'dart:io' show Platform;
import 'package:flutter/material.dart';
import 'package:tray_manager/tray_manager.dart';
import 'package:window_manager/window_manager.dart';
import '../providers/btc_provider.dart'; // 导入 BTCProvider

class SystemTrayService extends TrayListener {
  static final SystemTrayService _instance = SystemTrayService._internal();
  factory SystemTrayService() => _instance;
  SystemTrayService._internal();

  bool _isInitialized = false;
  BTCProvider? _btcProvider; // 注入 BTCProvider 实例

  void setBtcProvider(BTCProvider provider) {
    _btcProvider = provider;
  }

  /// 初始化系统托盘
  Future<void> initialize() async {
    if (!Platform.isWindows || _isInitialized) return;

    try {
      trayManager.addListener(this);

      await trayManager.setIcon('windows/runner/resources/app_icon.ico');
      await trayManager.setTitle('BTC DCA 提醒');
      await trayManager.setToolTip('BTC DCA 买入提醒应用\n点击查看详情');

      await _updateTrayMenu();

      _isInitialized = true;
      debugPrint('SystemTrayService initialized successfully');
    } catch (e) {
      debugPrint('Error initializing SystemTrayService: $e');
    }
  }

  /// 更新托盘菜单
  Future<void> _updateTrayMenu() async {
    final menu = Menu(
      items: [
        MenuItem(
          key: 'show_window',
          label: '显示主窗口',
        ),
        MenuItem.separator(),
        
        MenuItem(
          key: 'exit',
          label: '退出应用',
        ),
      ],
    );

    await trayManager.setContextMenu(menu);
  }

  /// 显示主窗口
  Future<void> showMainWindow() async {
    if (!Platform.isWindows) return;
    await windowManager.show();
    await windowManager.focus();
  }

  /// 隐藏到系统托盘
  Future<void> hideToTray() async {
    if (!Platform.isWindows) return;
    await windowManager.hide();
  }

  /// 停止系统托盘服务
  Future<void> dispose() async {
    if (!Platform.isWindows || !_isInitialized) return;
    try {
      trayManager.removeListener(this);
      await trayManager.destroy();
      _isInitialized = false;
      debugPrint('SystemTrayService disposed');
    } catch (e) {
      debugPrint('Error disposing SystemTrayService: $e');
    }
  }

  // TrayListener 回调方法
  @override
  void onTrayIconMouseDown() {
    showMainWindow();
  }

  @override
  void onTrayIconRightMouseDown() async {
    await _updateTrayMenu(); // 每次右键都更新菜单
    await trayManager.popUpContextMenu();
  }

  @override
  void onTrayMenuItemClick(MenuItem menuItem) {
    switch (menuItem.key) {
      case 'show_window':
        showMainWindow();
        break;
      
      case 'exit':
        _exitApplication();
        break;
    }
  }

  

  

  void _exitApplication() {
    windowManager.destroy();
  }

  bool get isInitialized => _isInitialized;
}