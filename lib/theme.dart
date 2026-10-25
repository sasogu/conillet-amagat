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
    required this.cat,
    required this.catEye,
    required this.cross,
    required this.autoCross,
    required this.border,
    required this.grid,
    required this.conflict,
  });

  final List<Color> regions;
  final Color cat;
  final Color catEye;
  final Color cross;
  final Color autoCross;
  final Color border;
  final Color grid;
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
    cat: Color(0xFF2F2A26),
    catEye: Color(0xFFFFF8EA),
    cross: Color(0xFF8A7F72),
    autoCross: Color(0xFFB4A99C),
    border: Color(0xFFFFFCF6),
    grid: Color(0x14000000),
    conflict: Color(0xFFD1495B),
  );

  static const BoardColors dark = BoardColors(
    regions: [
      Color(0xFF6E4B45),
      Color(0xFF6B5B34),
      Color(0xFF41573D),
      Color(0xFF355660),
      Color(0xFF4B4569),
      Color(0xFF6A4353),
      Color(0xFF574C40),
      Color(0xFF36554F),
      Color(0xFF5C4B3A),
      Color(0xFF404B60),
    ],
    cat: Color(0xFFF5E9D0),
    catEye: Color(0xFF2A2622),
    cross: Color(0xFFBDB4A6),
    autoCross: Color(0xFF7C766C),
    border: Color(0xFF101413),
    grid: Color(0x14FFFFFF),
    conflict: Color(0xFFFF7B8A),
  );

  static BoardColors of(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark ? dark : light;

  Color regionColor(int region) => regions[region % regions.length];
}
