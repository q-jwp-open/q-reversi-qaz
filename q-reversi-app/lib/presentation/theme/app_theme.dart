import 'package:flutter/material.dart';
import '../../core/constants/game_constants.dart';
import '../../domain/entities/gate_type.dart';

/// アプリテーマ（量子・宇宙イメージ）
class AppTheme {
  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      primaryColor: const Color(GameConstants.primaryPurple),
      scaffoldBackgroundColor: const Color(GameConstants.bgDark1),
      colorScheme: const ColorScheme.dark(
        primary: Color(GameConstants.primaryPurple),
        secondary: Color(GameConstants.cyan),
        tertiary: Color(GameConstants.neonBlue),
        error: Color(GameConstants.pink),
        surface: Color(GameConstants.bgDark2),
        onPrimary: Color(GameConstants.white),
        onSecondary: Color(GameConstants.white),
        onSurface: Color(GameConstants.white),
        onError: Color(GameConstants.white),
      ),
      textTheme: const TextTheme(
        displayLarge: TextStyle(
          color: Color(GameConstants.white),
          fontSize: 32,
          fontWeight: FontWeight.bold,
        ),
        displayMedium: TextStyle(
          color: Color(GameConstants.white),
          fontSize: 24,
          fontWeight: FontWeight.bold,
        ),
        bodyLarge: TextStyle(
          color: Color(GameConstants.white),
          fontSize: 16,
        ),
        bodyMedium: TextStyle(
          color: Color(GameConstants.white),
          fontSize: 14,
        ),
      ),
      cardTheme: CardThemeData(
        color: const Color(GameConstants.bgDark2).withOpacity(0.8),
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(
            color: const Color(GameConstants.purple).withOpacity(0.3),
            width: 1,
          ),
        ),
      ),
      buttonTheme: ButtonThemeData(
        buttonColor: const Color(GameConstants.primaryPurple),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          foregroundColor: const Color(GameConstants.white),
          backgroundColor: const Color(GameConstants.primaryPurple),
          textStyle: const TextStyle(
            color: Color(GameConstants.white),
            fontSize: 18,
          ),
        ),
      ),
    );
  }
  
  /// ゲートボタンのスタイル
  static ButtonStyle getGateButtonStyle(GateType gate, bool isEnabled, bool isSelected, [bool isReadOnly = false]) {
    // すべてのゲートボタンを紫色にする
    const Color purpleColor = Color(GameConstants.primaryPurple);
    
    // 選択されていないときは半透明にする
    final Color backgroundColor = isSelected
        ? purpleColor
        : purpleColor.withOpacity(0.5);
    
    return ButtonStyle(
      backgroundColor: WidgetStateProperty.all(
        isEnabled ? backgroundColor : const Color(GameConstants.darkGray),
      ),
      foregroundColor: WidgetStateProperty.all(Colors.white),
      shape: WidgetStateProperty.all(
        RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }
}

