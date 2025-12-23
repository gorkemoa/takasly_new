import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:logger/web.dart';

class AppTheme {
  // Google Fonts kullanım durumu
  // Normal cihazlarda Google Fonts kullanılacak, emülatörde devre dışı
  static bool _googleFontsAvailable = true;
  static bool _isInitialized = false;
  static bool get googleFontsAvailable => _googleFontsAvailable;

  // Google Fonts'u önceden yükle
  // Normal cihazlarda Google Fonts kullanılacak
  // Emülatörde veya hata durumunda otomatik fallback yapılacak
  static Future<void> preloadFonts() async {
    if (_isInitialized) return;
    _isInitialized = true;

    try {
      // Google Fonts'u test et
      // Normal cihazda çalışırsa kullanılacak, hata verirse otomatik fallback yapılacak
      final testStyle = GoogleFonts.inter(fontSize: 14);
      if (testStyle.fontFamily != null && testStyle.fontFamily!.isNotEmpty) {
        _googleFontsAvailable = true;
        Logger.info(
          'Google Fonts başarıyla yüklendi - normal cihazda kullanılacak',
          tag: 'AppTheme',
        );
      } else {
        _googleFontsAvailable = false;
        Logger.info(
          'Google Fonts yüklenemedi - sistem fontları kullanılacak',
          tag: 'AppTheme',
        );
      }
    } catch (e) {
      // Hata durumunda (emülatörde olabilir) güvenli tarafta kal - fallback kullan
      _googleFontsAvailable = false;
      Logger.info(
        'Google Fonts preload hatası (emülatör olabilir), fallback font kullanılacak',
        tag: 'AppTheme',
      );
    }
  }

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

  // --- Tipografi (Google Fonts - Inter) - Kalın metin kontrolü ile ---
  // Font yükleme hatası durumunda fallback için yardımcı metod
  static TextStyle _safeInterTextStyle({
    required double fontSize,
    required FontWeight fontWeight,
    required Color color,
    double? letterSpacing,
    double? height,
  }) {
    // Google Fonts yüklenemediyse veya devre dışıysa direkt fallback kullan
    if (!_googleFontsAvailable) {
      return TextStyle(
        fontSize: fontSize,
        fontWeight: fontWeight,
        color: color,
        letterSpacing: letterSpacing,
        height: height,
        // fontFamily belirtilmezse sistem fontu kullanılır (Inter'e benzer)
      );
    }

    try {
      // Normal cihazda Google Fonts kullan
      final textStyle = GoogleFonts.inter(
        fontSize: fontSize,
        fontWeight: fontWeight,
        color: color,
        letterSpacing: letterSpacing,
        height: height,
      );

      return textStyle;
    } catch (e) {
      // Hata durumunda Google Fonts'u devre dışı bırak ve fallback kullan
      _googleFontsAvailable = false;
      Logger.error(
        'Google Fonts yükleme hatası, fallback font kullanılıyor: $e',
        tag: 'AppTheme',
        error: e,
      );
      // Fallback olarak sistem fontunu kullan
      return TextStyle(
        fontSize: fontSize,
        fontWeight: fontWeight,
        color: color,
        letterSpacing: letterSpacing,
        height: height,
      );
    }
  }

  // Public metod: Diğer dosyalardan güvenli Google Fonts kullanımı için
  static TextStyle safeInter({
    required double fontSize,
    required FontWeight fontWeight,
    required Color color,
    double? letterSpacing,
    double? height,
  }) {
    return _safeInterTextStyle(
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
      displayLarge: _safeInterTextStyle(
        fontSize: 32,
        fontWeight: FontWeight.w600, // w700'den w600'a düşürüldü
        color: textPrimary,
        letterSpacing: -0.5,
      ),
      displayMedium: _safeInterTextStyle(
        fontSize: 28,
        fontWeight: FontWeight.w600, // w700'den w600'a düşürüldü
        color: textPrimary,
        letterSpacing: -0.5,
      ),
      headlineMedium: _safeInterTextStyle(
        fontSize: 24,
        fontWeight: FontWeight.w500, // w600'dan w500'a düşürüldü
        color: textPrimary,
      ),
      headlineSmall: _safeInterTextStyle(
        fontSize: 20,
        fontWeight: FontWeight.w500, // w600'dan w500'a düşürüldü
        color: textPrimary,
      ),
      titleLarge: _safeInterTextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w500, // w600'dan w500'a düşürüldü
        color: textPrimary,
      ),
      titleMedium: _safeInterTextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w400, // w500'dan w400'a düşürüldü
        color: textPrimary,
      ),
      bodyLarge: _safeInterTextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w400,
        color: textSecondary,
      ),
      bodyMedium: _safeInterTextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        color: textSecondary,
      ),
      labelLarge: _safeInterTextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w500, // w600'dan w500'a düşürüldü
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
