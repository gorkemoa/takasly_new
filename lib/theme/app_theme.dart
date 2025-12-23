import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // --- Renkler ---
  static const Color primary = Color(0xFF10B981); // Kurumsal Koyu Mavi
  static const Color accent = Color(0xFF10B981); // Vurgu Rengi (Mevcut Yeşil)
  static const Color background = Color(0xFFF7F8FA); // Çok Açık Gri Arka Plan
  static const Color surface = Colors.white; // Kart ve Yüzey Rengi
  static const Color textPrimary = Color(
    0xFF212121,
  ); // Ana Metin Rengi (Koyu Gri)
  static const Color textSecondary = Color(
    0xFF757575,
  ); // İkincil Metin Rengi (Orta Gri)
  static const Color error = Color(0xFFD32F2F); // Hata Rengi
  static const Color success = Color(0xFF388E3C); // Başarı Rengi

  // --- Kenarlık ve Gölgeler ---
  static final BorderRadius borderRadius = BorderRadius.circular(12.0);
  static final List<BoxShadow> cardShadow = [
    BoxShadow(
      color: Colors.black.withOpacity(0.05),
      blurRadius: 20,
      offset: const Offset(0, 4),
    ),
  ];

  // --- Tipografi (Google Fonts - Poppins) ---
  static TextStyle _poppinsStyle({
    required double fontSize,
    required FontWeight fontWeight,
    required Color color,
    double? letterSpacing,
    double? height,
  }) {
    return GoogleFonts.poppins(
      fontSize: fontSize,
      fontWeight: fontWeight,
      color: color,
      letterSpacing: letterSpacing,
      height: height,
    );
  }

  // Public metod: Diğer dosyalardan Poppins kullanımı için
  static TextStyle safePoppins({
    required double fontSize,
    required FontWeight fontWeight,
    required Color color,
    double? letterSpacing,
    double? height,
  }) {
    return _poppinsStyle(
      fontSize: fontSize,
      fontWeight: fontWeight,
      color: color,
      letterSpacing: letterSpacing,
      height: height,
    );
  }

  // Lazy loading için TextTheme getter
  static TextTheme get _textTheme {
    return TextTheme(
      displayLarge: _poppinsStyle(
        fontSize: 32,
        fontWeight: FontWeight.w600,
        color: textPrimary,
        letterSpacing: -0.5,
      ),
      displayMedium: _poppinsStyle(
        fontSize: 28,
        fontWeight: FontWeight.w600,
        color: textPrimary,
        letterSpacing: -0.5,
      ),
      headlineMedium: _poppinsStyle(
        fontSize: 24,
        fontWeight: FontWeight.w500,
        color: textPrimary,
      ),
      headlineSmall: _poppinsStyle(
        fontSize: 20,
        fontWeight: FontWeight.w500,
        color: textPrimary,
      ),
      titleLarge: _poppinsStyle(
        fontSize: 18,
        fontWeight: FontWeight.w500,
        color: textPrimary,
      ),
      titleMedium: _poppinsStyle(
        fontSize: 16,
        fontWeight: FontWeight.w400,
        color: textPrimary,
      ),
      bodyLarge: _poppinsStyle(
        fontSize: 16,
        fontWeight: FontWeight.w400,
        color: textSecondary,
      ),
      bodyMedium: _poppinsStyle(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        color: textSecondary,
      ),
      labelLarge: _poppinsStyle(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        color: Colors.white,
      ), // Buton metni
    );
  }

  // --- Genel Tema ---
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      primaryColor: primary,
      scaffoldBackgroundColor: background,
      cardColor: surface,
      // Kalın metin kontrolü için font weight ayarları
      // Google Fonts kullanılıyorsa Inter, değilse sistem fontu kullanılır
      // Text scaling ve bold text kontrolü
      textTheme: _textTheme.apply(
        bodyColor: textPrimary,
        displayColor: textPrimary,
      ),
      colorScheme: const ColorScheme.light(
        primary: primary,
        secondary: accent,
        surface: surface,
        background: background,
        error: error,
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onSurface: textPrimary,
        onBackground: textPrimary,
        onError: Colors.white,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: background,
        elevation: 0,
        scrolledUnderElevation: 0,
        iconTheme: const IconThemeData(color: textPrimary),
        titleTextStyle: _textTheme.titleLarge,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: borderRadius),
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
          textStyle: _textTheme.labelLarge,
          elevation: 2,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(
          vertical: 16,
          horizontal: 16,
        ),
        border: OutlineInputBorder(
          borderRadius: borderRadius,
          borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: borderRadius,
          borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: borderRadius,
          borderSide: const BorderSide(color: primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: borderRadius,
          borderSide: const BorderSide(color: error, width: 1),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: borderRadius,
          borderSide: const BorderSide(color: error, width: 2),
        ),
        hintStyle: _textTheme.bodyLarge?.copyWith(
          color: textSecondary.withOpacity(0.7),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: textPrimary,
          side: const BorderSide(color: Color(0xFFE0E0E0)),
          shape: RoundedRectangleBorder(borderRadius: borderRadius),
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
          textStyle: _textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      cardTheme: CardThemeData(
        clipBehavior: Clip.antiAlias,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: borderRadius),
        color: surface,
        margin: EdgeInsets.zero,
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: surface,
        selectedItemColor: primary,
        unselectedItemColor: textSecondary,
        type: BottomNavigationBarType.fixed,
        elevation: 8,
      ),
    );
  }
}
