import '../game/puzzle.dart';

/// Textos de la interfaz en castellano y valenciano.
class Strings {
  const Strings({required this.catalan});

  final bool catalan;

  String get appName => 'Ronrón';
  String get tagline => catalan
      ? 'Un gat per fila, columna i regió'
      : 'Un gato por fila, columna y región';

  String get dailyTitle => catalan ? 'Puzle diari' : 'Puzle diario';
  String get dailyDone => catalan ? 'Completat hui' : 'Completado hoy';
  String get play => catalan ? 'Juga' : 'Jugar';
  String get playAgain => catalan ? 'Torna a jugar' : 'Volver a jugar';
  String get continueTitle =>
      catalan ? 'Continua la partida' : 'Continuar partida';
  String get savedGame => catalan ? 'Partida guardada' : 'Partida guardada';
  String get levelsTitle => catalan ? 'Nivells' : 'Niveles';
  String get level => catalan ? 'Nivell' : 'Nivel';
  String levelLabel(int number) => '$level $number';
  String get settings => catalan ? 'Ajustos' : 'Ajustes';
  String get close => catalan ? 'Tanca' : 'Cerrar';
  String get cancel => catalan ? 'Cancel·la' : 'Cancelar';
  String get restart => catalan ? 'Reinicia' : 'Reiniciar';
  String get restartTitle =>
      catalan ? 'Reiniciar el puzle?' : '¿Reiniciar el puzle?';
  String get restartBody => catalan
      ? 'S\'esborraran els gats i les X que has posat.'
      : 'Se borrarán los gatos y las X que has puesto.';
  String get undo => catalan ? 'Desfés' : 'Deshacer';
  String get hint => catalan ? 'Pista' : 'Pista';
  String get reset => catalan ? 'Reinicia' : 'Reiniciar';
  String get autoCross =>
      catalan ? 'Marca X automàticament' : 'Marcar X automáticamente';
  String get autoCrossShort => catalan ? 'X auto' : 'X auto';
  String get cats => catalan ? 'Gats' : 'Gatos';
  String get time => catalan ? 'Temps' : 'Tiempo';
  String get hints => catalan ? 'Pistes' : 'Pistas';
  String instructions() => catalan
      ? 'Toca una casella per a marcar X. Doble toc per a posar un gat. Arrossega per a marcar diverses X.'
      : 'Toca una casilla para marcar X. Doble toque para poner un gato. Arrastra para marcar varias X.';

  String get winTitle => catalan ? 'Puzle resolt!' : '¡Puzle resuelto!';
  String get winBody => catalan
      ? 'Has col·locat tots els gats.'
      : 'Has colocado todos los gatos.';
  String get next => catalan ? 'Següent' : 'Siguiente';
  String get home => catalan ? 'Inici' : 'Inicio';
  String get playLevel => catalan ? 'Juga un nivell' : 'Jugar un nivel';

  String get solvedStat => catalan ? 'Resolts' : 'Resueltos';
  String get streakStat => catalan ? 'Ratxa diària' : 'Racha diaria';
  String days(int count) => catalan
      ? '$count ${count == 1 ? 'dia' : 'dies'}'
      : '$count ${count == 1 ? 'día' : 'días'}';

  String get theme => catalan ? 'Tema' : 'Tema';
  String get themeSystem => catalan ? 'Sistema' : 'Sistema';
  String get themeLight => catalan ? 'Clar' : 'Claro';
  String get themeDark => catalan ? 'Fosc' : 'Oscuro';
  String get language => catalan ? 'Idioma' : 'Idioma';
  String get spanish => catalan ? 'Espanyol' : 'Español';
  String get valencian => 'Valencià';
  String get about => catalan ? 'Quant a' : 'Acerca de';
  String get aboutText => catalan
      ? 'Un puzle de lògica de gats, sense anuncis, sense connexió i amb codi lliure.'
      : 'Un puzle de lógica de gatos, sin anuncios, sin conexión y con código libre.';
  String get sourceCode => catalan ? 'Codi font' : 'Código fuente';
  String get madeWith => catalan ? 'Fet amb Flutter' : 'Hecho con Flutter';
  String versionLabel(String version) =>
      catalan ? 'Versió $version' : 'Versión $version';

  String difficulty(Difficulty value) => switch (value) {
    Difficulty.easy => catalan ? 'Fàcil' : 'Fácil',
    Difficulty.medium => catalan ? 'Mitjà' : 'Medio',
    Difficulty.hard => catalan ? 'Difícil' : 'Difícil',
    Difficulty.expert => catalan ? 'Expert' : 'Experto',
  };

  String sizeLabel(int size) => '$size×$size';

  String dateLong(DateTime date) {
    const weekdaysEs = [
      'lunes',
      'martes',
      'miércoles',
      'jueves',
      'viernes',
      'sábado',
      'domingo',
    ];
    const weekdaysCa = [
      'dilluns',
      'dimarts',
      'dimecres',
      'dijous',
      'divendres',
      'dissabte',
      'diumenge',
    ];
    const monthsEs = [
      'enero',
      'febrero',
      'marzo',
      'abril',
      'mayo',
      'junio',
      'julio',
      'agosto',
      'septiembre',
      'octubre',
      'noviembre',
      'diciembre',
    ];
    const monthsCa = [
      'gener',
      'febrer',
      'març',
      'abril',
      'maig',
      'juny',
      'juliol',
      'agost',
      'setembre',
      'octubre',
      'novembre',
      'desembre',
    ];
    final weekday = (catalan ? weekdaysCa : weekdaysEs)[date.weekday - 1];
    final month = (catalan ? monthsCa : monthsEs)[date.month - 1];
    if (!catalan) return '$weekday, ${date.day} de $month';
    final join = 'aeiou'.contains(month[0]) ? "d'" : 'de ';
    return '$weekday, ${date.day} $join$month';
  }

  String modeLabel(String mode, int levelIndex) {
    if (mode == 'daily') return dailyTitle;
    return levelLabel(levelIndex);
  }

  static String formatDuration(int totalSeconds) {
    final hours = totalSeconds ~/ 3600;
    final minutes = (totalSeconds % 3600) ~/ 60;
    final seconds = totalSeconds % 60;
    String two(int value) => value.toString().padLeft(2, '0');
    if (hours > 0) return '$hours:${two(minutes)}:${two(seconds)}';
    return '${two(minutes)}:${two(seconds)}';
  }
}
