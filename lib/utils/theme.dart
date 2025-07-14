import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // 颜色定义
  static const Color primaryColor = Color(0xFF00FF88);
  static const Color secondaryColor = Color(0xFFFFD700);
  static const Color backgroundColor = Color(0xFF1A1A1A);
  static const Color surfaceColor = Color(0xFF2D2D2D);
  static const Color cardColor = Color(0xFF333333);
  static const Color textColor = Color(0xFFFFFFFF);
  static const Color textSecondaryColor = Color(0xFF888888);
  static const Color successColor = Color(0xFF00FF88);
  static const Color errorColor = Color(0xFFFF4444);
  static const Color warningColor = Color(0xFFFF9800);
  static const Color shadowColor = Color(0xFF000000);
  static const Color accentColor = Color(0xFF64FFDA);

  // 彩虹区域颜色
  static const Color blueZone = Color(0xFF2196F3);
  static const Color greenZone = Color(0xFF4CAF50);
  static const Color yellowZone = Color(0xFFFFEB3B);
  static const Color orangeZone = Color(0xFFFF9800);
  static const Color redZone = Color(0xFFFF5722);
  static const Color purpleZone = Color(0xFF9C27B0);

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: backgroundColor,

      // 颜色方案
      colorScheme: const ColorScheme.dark(
        primary: primaryColor,
        secondary: secondaryColor,
        surface: surfaceColor,
        error: errorColor,
      ),

      // 文本主题
      textTheme: GoogleFonts.robotoTextTheme(
        ThemeData.dark().textTheme.copyWith(
              headlineLarge: const TextStyle(
                color: textColor,
                fontSize: 32,
                fontWeight: FontWeight.bold,
              ),
              headlineMedium: const TextStyle(
                color: textColor,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
              headlineSmall: const TextStyle(
                color: textColor,
                fontSize: 20,
                fontWeight: FontWeight.w600,
              ),
              bodyLarge: const TextStyle(
                color: textColor,
                fontSize: 16,
              ),
              bodyMedium: const TextStyle(
                color: textColor,
                fontSize: 14,
              ),
              bodySmall: const TextStyle(
                color: textSecondaryColor,
                fontSize: 12,
              ),
            ),
      ),

      // 卡片主题
      cardTheme: CardThemeData(
        color: cardColor,
        elevation: 8,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),

      // 按钮主题
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor,
          foregroundColor: Colors.black,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),

      // 应用栏主题
      appBarTheme: const AppBarTheme(
        backgroundColor: backgroundColor,
        foregroundColor: textColor,
        elevation: 0,
        centerTitle: true,
      ),
    );
  }

  // 辅助方法：根据彩虹区域获取颜色
  static Color getRainbowZoneColor(String zone) {
    switch (zone) {
      case '🔵 深蓝区':
      case '🔵 蓝色区':
        return blueZone;
      case '🟢 绿色区':
        return greenZone;
      case '🟡 黄色区':
        return yellowZone;
      case '🟠 橙色区':
        return orangeZone;
      case '🔴 红色区':
      case '🔴 深红区':
        return redZone;
      case '🟣 狂热区':
        return purpleZone;
      default:
        return yellowZone;
    }
  }
}
