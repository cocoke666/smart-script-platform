import 'package:flutter/material.dart';

/// 平台配色与主题。
///
/// 登录页沿用平台既有设计令牌（深湖蓝主色 #254E90、暖灰辅助色），
/// 与 H5 原型保持同一套视觉语言，不引入截图中的第三方品牌配色。
class AppTheme {
  const AppTheme._();

  /// 主色：深湖蓝。
  static const Color primary = Color(0xFF254E90);

  /// 主色按下态。
  static const Color primaryDark = Color(0xFF1D3E73);

  /// 主色浅底。
  static const Color primaryTint = Color(0xFFEAF1FA);

  /// 标题文字。
  static const Color text1 = Color(0xFF1F2329);

  /// 正文文字。
  static const Color text2 = Color(0xFF4E5969);

  /// 辅助小字 / placeholder。
  static const Color text3 = Color(0xFF86909C);

  /// 分割线。
  static const Color divider = Color(0xFFE5E6EB);

  /// 浅灰填充。
  static const Color fill = Color(0xFFF2F3F5);

  /// 错误态。
  static const Color error = Color(0xFFB54A44);

  /// 微信入口占位色。
  static const Color wechatGreen = Color(0xFF07C160);

  /// QQ 入口占位色。
  static const Color qqBlue = Color(0xFF12B7F5);

  static ThemeData light() {
    final base = ThemeData(
      useMaterial3: false,
      brightness: Brightness.light,
      primaryColor: primary,
      scaffoldBackgroundColor: Colors.white,
      colorScheme: const ColorScheme.light(
        primary: primary,
        secondary: primary,
        error: error,
        surface: Colors.white,
      ),
    );
    return base.copyWith(
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.white,
        foregroundColor: text1,
        elevation: 0,
        centerTitle: false,
      ),
      textSelectionTheme: const TextSelectionThemeData(cursorColor: primary),
      snackBarTheme: const SnackBarThemeData(
        backgroundColor: Color(0xE01F2329),
        contentTextStyle: TextStyle(color: Colors.white, fontSize: 13),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}
