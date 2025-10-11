import 'package:flutter/material.dart';

/// Portal Brand Colors
class PortalColors {
  // Primary Portal Blue
  static const Color portalBlue = Color(0xFF3E71F8);
  static const Color portalBlueDark = Color(0xFF2D5BD6);
  static const Color portalBlueLight = Color(0xFF5B8AFF);
  
  // Gray Palette
  static const Color portalGray = Color(0xFF6B7280);
  static const Color portalGrayLight = Color(0xFFF3F4F6);
  static const Color portalGrayDark = Color(0xFF374151);
  
  // Basic Colors
  static const Color portalWhite = Color(0xFFFFFFFF);
  static const Color portalBlack = Color(0xFF000000);
}

/// Portal Theme Configuration
class PortalTheme {
  static ThemeData get lightTheme {
    return ThemeData(
      primarySwatch: MaterialColor(
        PortalColors.portalBlue.value,
        <int, Color>{
          50: PortalColors.portalBlueLight.withOpacity(0.1),
          100: PortalColors.portalBlueLight.withOpacity(0.2),
          200: PortalColors.portalBlueLight.withOpacity(0.3),
          300: PortalColors.portalBlueLight.withOpacity(0.4),
          400: PortalColors.portalBlueLight.withOpacity(0.5),
          500: PortalColors.portalBlue,
          600: PortalColors.portalBlueDark.withOpacity(0.8),
          700: PortalColors.portalBlueDark.withOpacity(0.9),
          800: PortalColors.portalBlueDark,
          900: PortalColors.portalBlueDark,
        },
      ),
      primaryColor: PortalColors.portalBlue,
      scaffoldBackgroundColor: PortalColors.portalGrayLight,
      appBarTheme: const AppBarTheme(
        backgroundColor: PortalColors.portalBlue,
        foregroundColor: PortalColors.portalWhite,
        elevation: 0,
        centerTitle: true,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: PortalColors.portalBlue,
          foregroundColor: PortalColors.portalWhite,
          elevation: 2,
          shadowColor: PortalColors.portalBlue.withOpacity(0.3),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        ),
      ),
      textTheme: const TextTheme(
        headlineLarge: TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.bold,
          color: PortalColors.portalBlue,
        ),
        headlineMedium: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: PortalColors.portalBlue,
        ),
        bodyLarge: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          color: PortalColors.portalGrayDark,
        ),
        bodyMedium: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: PortalColors.portalGrayDark,
        ),
      ),
    );
  }
}
