import 'package:flutter/material.dart';

class AppTheme {
  static const Color seed = Color(0xFF2F7A6B);

  static ThemeData light() {
    final scheme =
        ColorScheme.fromSeed(
          seedColor: seed,
          brightness: Brightness.light,
        ).copyWith(
          surface: const Color(0xFFFFFCF6),
          surfaceContainerLow: const Color(0xFFF8F1E6),
          surfaceContainer: const Color(0xFFF3EADC),
        );
    return _base(scheme, const Color(0xFFFBF7F0));
  }

  static ThemeData dark() {
    final scheme =
        ColorScheme.fromSeed(
          seedColor: seed,
          brightness: Brightness.dark,
        ).copyWith(
          surface: const Color(0xFF141817),
          surfaceContainerLow: const Color(0xFF1C2321),
          surfaceContainer: const Color(0xFF232B28),
        );
    return _base(scheme, const Color(0xFF101413));
  }

  static ThemeData _base(ColorScheme scheme, Color background) {
    return ThemeData(
      useMaterial3: true,
      fontFamily: 'Roboto',
      colorScheme: scheme,
      scaffoldBackgroundColor: background,
      appBarTheme: AppBarTheme(
        backgroundColor: background,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        margin: EdgeInsets.zero,
        color: scheme.surfaceContainerLow,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: scheme.surfaceContainerLow,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: scheme.surfaceContainerLow,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size(0, 48),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          textStyle: const TextStyle(fontWeight: FontWeight.w600),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
    );
  }
}

class BoardColors {
  const BoardColors({
    required this.regions,
    required this.bunny,
    required this.bunnyEye,
    required this.cross,
    required this.autoCross,
    required this.gap,
    required this.conflict,
  });

  final List<Color> regions;
  final Color bunny;
  final Color bunnyEye;
  final Color cross;
  final Color autoCross;
  final Color gap;
  final Color conflict;

  static const BoardColors light = BoardColors(
    regions: [
      Color(0xFFF3C6B8),
      Color(0xFFF4E1AD),
      Color(0xFFCDE3C0),
      Color(0xFFBFDCE8),
      Color(0xFFD3CEEB),
      Color(0xFFF2C9DC),
      Color(0xFFE2D6C3),
      Color(0xFFC4E4DC),
      Color(0xFFEAD6BE),
      Color(0xFFD9E2F0),
    ],
    bunny: Color(0xFF2F2A26),
    bunnyEye: Color(0xFFFFF8EA),
    cross: Color(0xFF8A7F72),
    autoCross: Color(0xFFB4A99C),
    gap: Color(0xFFFFFCF6),
    conflict: Color(0xFFD1495B),
  );

  static const BoardColors dark = BoardColors(
    regions: [
      Color(0xFFA9655A), // coral
      Color(0xFFA98A48), // ámbar
      Color(0xFF6F8E5E), // salvia
      Color(0xFF4B8779), // verde azulado
      Color(0xFF4E7F98), // azul cian
      Color(0xFF6F78A6), // índigo
      Color(0xFF896CA1), // violeta
      Color(0xFFA4617D), // rosa
      Color(0xFF5C6E8B), // pizarra
      Color(0xFF8B7960), // arena
    ],
    bunny: Color(0xFFF7EBD2),
    bunnyEye: Color(0xFF221E1A),
    cross: Color(0xFFE6DCCB),
    autoCross: Color(0xFF4A453D),
    gap: Color(0xFF0A0D0C),
    conflict: Color(0xFFFF8492),
  );

  static BoardColors of(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark ? dark : light;

  Color regionColor(int region) => regions[region % regions.length];
}
