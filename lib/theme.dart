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
    required this.cross,
    required this.autoCross,
    required this.gap,
    required this.conflict,
  });

  final List<Color> regions;
  final Color cross;
  final Color autoCross;
  final Color gap;
  final Color conflict;

  static const BoardColors light = BoardColors(
    regions: [
      Color(0xFFF0AE9E), // coral
      Color(0xFFF5B766), // albaricoque
      Color(0xFFEDDA66), // dorado
      Color(0xFFBBDD92), // pistacho
      Color(0xFF8FDDC6), // menta
      Color(0xFF8CCBEC), // cielo
      Color(0xFF9CB3F0), // azul lavanda
      Color(0xFFC99FE9), // violeta
      Color(0xFFF1AECC), // rosa
      Color(0xFFC4E9E9), // turquesa
    ],
    cross: Color(0xFF6E6459),
    autoCross: Color(0xFF9C9184),
    gap: Color(0xFFFFFCF6),
    conflict: Color(0xFFD1495B),
  );

  static const BoardColors dark = BoardColors(
    regions: [
      Color(0xFFB0665B), // coral
      Color(0xFFC9763A), // albaricoque
      Color(0xFF90881F), // dorado
      Color(0xFF6C9054), // pistacho
      Color(0xFF3A8C77), // menta
      Color(0xFF4B8098), // cielo
      Color(0xFF6178B2), // azul lavanda
      Color(0xFF986CA6), // violeta
      Color(0xFFA86280), // rosa
      Color(0xFF49ABAB), // turquesa
    ],
    cross: Color(0xFFF1E9DB),
    autoCross: Color(0xFF4A453D),
    gap: Color(0xFF0A0D0C),
    conflict: Color(0xFFFF8492),
  );

  static BoardColors of(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark ? dark : light;

  Color regionColor(int region) => regions[region % regions.length];
}
