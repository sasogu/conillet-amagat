import '../game/puzzle.dart';

/// Textos de la interfaz en castellano y valenciano.
class Strings {
  const Strings({required this.catalan});

  final bool catalan;

  String get appName => 'Conillet amagat';
  String get tagline => catalan
      ? 'Un conill per fila, columna i regió'
      : 'Un conejo por fila, columna y región';

  String get dailyTitle => catalan ? 'Puzle diari' : 'Puzle diario';
  String get dailyDone => catalan ? 'Completat hui' : 'Completado hoy';
  String get play => catalan ? 'Juga' : 'Jugar';
  String get playAgain => catalan ? 'Torna a jugar' : 'Volver a jugar';
  String get continueTitle =>
      catalan ? 'Continua la partida' : 'Continuar partida';
  String get savedGame => catalan ? 'Partida guardada' : 'Partida guardada';
  String get campaignTitle => catalan ? 'La teva etapa' : 'Tu etapa';
  String stageLabel(int number) => catalan ? 'Etapa $number' : 'Etapa $number';
  String stageProgress(int completed, int total) => catalan
      ? '$completed de $total completades'
      : '$completed de $total completadas';
  String givenBunnies(int count) => catalan
      ? '$count ${count == 1 ? 'conill' : 'conills'} de pista'
      : '$count ${count == 1 ? 'conejo' : 'conejos'} de pista';
  String get allStagesDone =>
      catalan ? 'Totes les etapes completades' : 'Todas las etapas completadas';
  String get settings => catalan ? 'Ajustos' : 'Ajustes';
  String get close => catalan ? 'Tanca' : 'Cerrar';
  String get cancel => catalan ? 'Cancel·la' : 'Cancelar';
  String get restart => catalan ? 'Reinicia' : 'Reiniciar';
  String get restartTitle =>
      catalan ? 'Reiniciar el puzle?' : '¿Reiniciar el puzle?';
  String get restartBody => catalan
      ? 'S\'esborraran els conills i les X que has posat.'
      : 'Se borrarán los conejos y las X que has puesto.';
  String get undo => catalan ? 'Desfés' : 'Deshacer';
  String get hint => catalan ? 'Pista' : 'Pista';
  String get reset => catalan ? 'Reinicia' : 'Reiniciar';
  String get autoCross =>
      catalan ? 'Marca X automàticament' : 'Marcar X automáticamente';
  String get autoCrossShort => catalan ? 'X auto' : 'X auto';
  String get bunnies => catalan ? 'Conills' : 'Conejos';
  String get lives => catalan ? 'Vides' : 'Vidas';
  String wrongBunny(int remaining) => catalan
      ? 'Conill mal col·locat. Et ${remaining == 1 ? 'queda' : 'queden'} $remaining ${remaining == 1 ? 'vida' : 'vides'}.'
      : 'Conejo mal colocado. Te ${remaining == 1 ? 'queda' : 'quedan'} $remaining ${remaining == 1 ? 'vida' : 'vidas'}.';
  String get noLivesTitle => catalan ? 'Sense vides' : 'Sin vidas';
  String get noLivesBody => catalan
      ? 'Has esgotat les tres vides. Reinicia el puzle per a tornar-ho a provar.'
      : 'Has agotado las tres vidas. Reinicia el puzle para volver a intentarlo.';
  String get time => catalan ? 'Temps' : 'Tiempo';
  String get hints => catalan ? 'Pistes' : 'Pistas';
  String instructions() => catalan
      ? 'Toca una casella per a marcar X. Doble toc per a posar un conill; si no hi va, perds una vida. Arrossega per a marcar diverses X.'
      : 'Toca una casilla para marcar X. Doble toque para poner un conejo; si no va ahí, pierdes una vida. Arrastra para marcar varias X.';

  String get winTitle => catalan ? 'Puzle resolt!' : '¡Puzle resuelto!';
  String get winBody => catalan
      ? 'Has col·locat tots els conills.'
      : 'Has colocado todos los conejos.';
  String get next => catalan ? 'Següent' : 'Siguiente';
  String get home => catalan ? 'Inici' : 'Inicio';
  String get playStage => catalan ? 'Juga una etapa' : 'Jugar etapa';

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
      ? 'Un puzle de lògica de conills, sense anuncis, sense connexió i amb codi lliure.'
      : 'Un puzle de lógica de conejos, sin anuncios, sin conexión y con código libre.';
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

  static String formatDuration(int totalSeconds) {
    final hours = totalSeconds ~/ 3600;
    final minutes = (totalSeconds % 3600) ~/ 60;
    final seconds = totalSeconds % 60;
    String two(int value) => value.toString().padLeft(2, '0');
    if (hours > 0) return '$hours:${two(minutes)}:${two(seconds)}';
    return '${two(minutes)}:${two(seconds)}';
  }
}
