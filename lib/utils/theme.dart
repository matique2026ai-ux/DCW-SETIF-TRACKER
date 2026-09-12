import 'package:flutter/material.dart';

class AppTheme {
  static const Color PrimaryColor = Color(0xFF881337);
  static const Color PrimaryLightColor = Color(0xFF9F1239);
  static const Color AccentColor = Color(0xFFD4AF37);
  static const Color AccentLightColor = Color(0xFFFDE68A);
  static const Color SidebarColor = Color(0xFF4C0519);
  static const Color BackgroundColor = Color(0xFFFAF5F5);
  static const Color CardColor = Color(0xFFFFFFFF);
  static const Color TextPrimary = Color(0xFF1F2937);
  static const Color TextSecondary = Color(0xFF6B7280);
  static const Color BorderColor = Color(0xFFE5E7EB);
  static const Color BorderFocusColor = Color(0xFF9F1239);
  static const Color SuccessColor = Color(0xFF10B981);
  static const Color WarningColor = Color(0xFFF59E0B);
  static const Color DangerColor = Color(0xFFEF4444);

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      fontFamily: 'Tajawal',
      scaffoldBackgroundColor: BackgroundColor,
      primaryColor: PrimaryColor,
      colorScheme: ColorScheme.light(
        primary: PrimaryColor,
        secondary: AccentColor,
        surface: CardColor,
        background: BackgroundColor,
        error: DangerColor,
        onPrimary: Colors.white,
        onSurface: TextPrimary,
        onBackground: TextPrimary,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: PrimaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          color: Colors.white,
          fontSize: 18,
          fontWeight: FontWeight.bold,
          fontFamily: 'Tajawal',
        ),
        iconTheme: IconThemeData(color: Colors.white),
      ),
      cardTheme: CardThemeData(
        color: CardColor,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: BorderSide(color: BorderColor, width: 1),
        ),
        shadowColor: Colors.black.withOpacity(0.06),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: PrimaryColor,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          textStyle: TextStyle(
            fontFamily: 'Tajawal',
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: PrimaryColor,
          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          textStyle: TextStyle(
            fontFamily: 'Tajawal',
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: PrimaryColor,
          side: BorderSide(color: PrimaryColor, width: 1.5),
          padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          textStyle: TextStyle(
            fontFamily: 'Tajawal',
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: CardColor,
        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: BorderColor),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: BorderColor),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: PrimaryColor, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: DangerColor),
        ),
        hintStyle: TextStyle(
          fontFamily: 'Tajawal',
          color: TextSecondary,
          fontSize: 14,
        ),
        labelStyle: TextStyle(
          fontFamily: 'Tajawal',
          color: TextPrimary,
          fontSize: 14,
        ),
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: CardColor,
        selectedItemColor: PrimaryColor,
        unselectedItemColor: TextSecondary,
        selectedLabelStyle: TextStyle(
          fontFamily: 'Tajawal',
          fontWeight: FontWeight.bold,
          fontSize: 12,
        ),
        unselectedLabelStyle: TextStyle(fontFamily: 'Tajawal', fontSize: 12),
        type: BottomNavigationBarType.fixed,
        elevation: 8,
      ),
      dataTableTheme: DataTableThemeData(
        decoration: BoxDecoration(
          color: CardColor,
          borderRadius: BorderRadius.circular(14),
        ),
        headingRowColor: WidgetStatePropertyAll(PrimaryColor),
        headingTextStyle: TextStyle(
          fontFamily: 'Tajawal',
          fontWeight: FontWeight.bold,
          color: Colors.white,
          fontSize: 13,
        ),
        dataTextStyle: TextStyle(
          fontFamily: 'Tajawal',
          color: TextPrimary,
          fontSize: 13,
        ),
        columnSpacing: 16,
        horizontalMargin: 16,
      ),
      dividerTheme: DividerThemeData(color: BorderColor, thickness: 1),
      dialogTheme: DialogThemeData(
        backgroundColor: CardColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        titleTextStyle: TextStyle(
          fontFamily: 'Tajawal',
          fontWeight: FontWeight.bold,
          fontSize: 18,
          color: TextPrimary,
        ),
        contentTextStyle: TextStyle(
          fontFamily: 'Tajawal',
          fontSize: 14,
          color: TextPrimary,
        ),
      ),
    );
  }

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      fontFamily: 'Tajawal',
      scaffoldBackgroundColor: Color(0xFF1F2937),
      primaryColor: AccentColor,
      colorScheme: ColorScheme.dark(
        primary: AccentColor,
        secondary: PrimaryColor,
        surface: Color(0xFF374151),
        background: Color(0xFF111827),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: SidebarColor,
        foregroundColor: AccentColor,
        elevation: 0,
      ),
      cardTheme: CardThemeData(
        color: Color(0xFF374151),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Color(0xFF374151),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
      ),
    );
  }
}
