import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// ثيم آي ستور: كحلي داكن زجاجي مع تدرجات بنفسجي/سماوي (نفس هوية الموقع)
class AppTheme {
  static const Color bg = Color(0xFF0C0A1D);
  static const Color surface = Color(0xFF17142E);
  static const Color card = Color(0x14FFFFFF);
  static const Color border = Color(0x1FFFFFFF);
  static const Color accent = Color(0xFF8B5CF6);
  static const Color accent2 = Color(0xFF22D3EE);
  static const Color text = Colors.white;
  static const Color textDim = Color(0xB3FFFFFF);
  static const Color textFaint = Color(0x80FFFFFF);

  static const LinearGradient primaryGradient = LinearGradient(
    colors: [Color(0xFF22D3EE), Color(0xFF8B5CF6)],
    begin: Alignment.centerRight,
    end: Alignment.centerLeft,
  );

  static ThemeData dark() {
    final base = ThemeData.dark(useMaterial3: true);
    final textTheme = GoogleFonts.cairoTextTheme(base.textTheme).apply(bodyColor: text, displayColor: text);
    return base.copyWith(
      scaffoldBackgroundColor: bg,
      colorScheme: const ColorScheme.dark(
        primary: accent,
        secondary: accent2,
        surface: surface,
        error: Color(0xFFF87171),
      ),
      textTheme: textTheme,
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0x0FFFFFFF),
        hintStyle: const TextStyle(color: Color(0x66FFFFFF)),
        labelStyle: const TextStyle(color: textDim, fontWeight: FontWeight.w700, fontSize: 14),
        contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(18), borderSide: const BorderSide(color: border)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(18), borderSide: const BorderSide(color: border)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(18), borderSide: const BorderSide(color: accent, width: 1.5)),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: const Color(0xFF221E45),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        contentTextStyle: const TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.w700),
      ),
    );
  }
}

String fmtPrice(num v, [String currency = 'د.ل']) {
  final s = v == v.roundToDouble() ? v.toStringAsFixed(0) : v.toStringAsFixed(2);
  // فاصلة الآلاف
  final parts = s.split('.');
  final intPart = parts[0].replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (m) => ',');
  return '${parts.length > 1 ? '$intPart.${parts[1]}' : intPart} $currency';
}
