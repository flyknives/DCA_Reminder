import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:window_manager/window_manager.dart';
import 'dart:io' show Platform;

import 'services/notification_service.dart';
import 'services/api_service.dart';
import 'services/system_tray_service.dart';
import 'providers/btc_provider.dart';
import 'providers/kline_chart_provider.dart';
import 'screens/home_screen.dart';
import 'utils/theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 确保窗口管理器已初始化
  await windowManager.ensureInitialized();

  // 在应用启动时就设置好，防止窗口关闭时应用退出
  if (Platform.isWindows) {
    await windowManager.setPreventClose(true);
  }

  // 设置窗口选项，并使用 waitUntilReadyToShow 来管理应用的生命周期
  WindowOptions windowOptions = const WindowOptions(
    size: Size(1200, 800),
    minimumSize: Size(800, 600),
    center: true,
    backgroundColor: Colors.transparent,
    skipTaskbar: false,
    titleBarStyle: TitleBarStyle.normal,
  );

  windowManager.waitUntilReadyToShow(windowOptions, () async {
    await windowManager.show();
    await windowManager.focus();
  });

  // 初始化服务
  try {
    final notificationService = NotificationService();
    await notificationService.initialize();
    debugPrint("通知服务初始化成功");
  } catch (e) {
    debugPrint("通知服务初始化失败: $e");
  }

  if (Platform.isWindows) {
    try {
      final systemTrayService = SystemTrayService();
      await systemTrayService.initialize();
      debugPrint("系统托盘初始化成功");
    } catch (e) {
      debugPrint("系统托盘初始化失败: $e");
    }
  }

  runApp(const BTCDCAApp());
}

class BTCDCAApp extends StatefulWidget {
  const BTCDCAApp({super.key});

  @override
  State<BTCDCAApp> createState() => _BTCDCAAppState();
}

class _BTCDCAAppState extends State<BTCDCAApp> with WindowListener {
  late SystemTrayService _systemTrayService;

  @override
  void initState() {
    super.initState();
    _systemTrayService = SystemTrayService();
    if (Platform.isWindows) {
      windowManager.addListener(this);
    }
    // 在这里获取 BTCProvider 的实例并设置给 SystemTrayService
    // 确保在 build 方法之前，provider 已经可用
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final btcProvider = Provider.of<BTCProvider>(context, listen: false);
      _systemTrayService.setBtcProvider(btcProvider);
    });
  }

  @override
  void dispose() {
    if (Platform.isWindows) {
      windowManager.removeListener(this);
    }
    super.dispose();
  }

  @override
  void onWindowClose() {
    // 因为已经在 main() 中设置了 setPreventClose(true)，
    // 所以这里只需要隐藏窗口即可。
    _systemTrayService.hideToTray();
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => BTCProvider(APIService())),
        ChangeNotifierProvider(create: (context) => KlineChartProvider(APIService())),
      ],
      child: MaterialApp(
        title: 'BTC DCA 提醒',
        theme: AppTheme.darkTheme,
        home: const HomeScreen(),
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}
