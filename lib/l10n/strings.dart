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
  String get howToPlay => catalan ? 'Com jugar' : 'Cómo jugar';
  String get appearance => catalan ? 'Aspectes' : 'Aspectos';
  String get skinSelected => catalan ? 'En ús' : 'En uso';
  String get skinChoose => catalan ? 'Triar' : 'Elegir';
  String get skinUnlock => catalan ? 'Desbloqueja' : 'Desbloquear';
  String skinName(String id) => switch (id) {
    'gray' => catalan ? 'Gris' : 'Gris',
    'brown' => catalan ? 'Marró' : 'Marrón',
    'night' => catalan ? 'Nocturn' : 'Nocturno',
    'carrot' => catalan ? 'Pastanaga' : 'Zanahoria',
    _ => catalan ? 'Blanc' : 'Blanco',
  };
  String notEnoughCarrots(int cost) => catalan
      ? 'Et falten pastanagues: aquest aspecte costa $cost.'
      : 'Te faltan zanahorias: este aspecto cuesta $cost.';
  String get understood => catalan ? 'Entesos' : 'Entendido';
  String get tutorialTapTitle =>
      catalan ? 'Un toc marca una X' : 'Un toque marca una X';
  String get tutorialTapBody => catalan
      ? 'Descarta la casella; un altre toc la torna a deixar lliure.'
      : 'Descarta la casilla; otro toque la vuelve a dejar libre.';
  String get tutorialBunnyTitle =>
      catalan ? 'Doble toc amaga un conill' : 'Doble toque esconde un conejo';
  String get tutorialBunnyBody => catalan
      ? 'Si el conill no va en eixa casella, perds una vida. Arrossega per a marcar diverses X.'
      : 'Si el conejo no va en esa casilla, pierdes una vida. Arrastra para marcar varias X.';
  String get tutorialLivesTitle =>
      catalan ? 'Tres vides per puzle' : 'Tres vidas por puzle';
  String get tutorialLivesBody => catalan
      ? 'Un conill mal col·locat gasta una vida. Els conills amb contorn són pistes fixes i no es poden traure.'
      : 'Un conejo mal colocado gasta una vida. Los conejos con contorno son pistas fijas y no se pueden quitar.';
  String get tutorialFastTitle =>
      catalan ? 'Avança més ràpid' : 'Avanza más rápido';
  String get tutorialFastBody => catalan
      ? 'Resoldre sense perdre vides i dins del temps et fa saltar 2 o 3 etapes.'
      : 'Resolver sin perder vidas y dentro del tiempo te hace saltar 2 o 3 etapas.';
  String get tutorialCarrotsTitle =>
      catalan ? 'Pastanagues' : 'Zanahorias';
  String get tutorialCarrotsBody => catalan
      ? 'Cada vida que et sobra es converteix en una pastanaga. Usa-les per a reviure si et quedes sense vides.'
      : 'Cada vida que te sobra se convierte en una zanahoria. Úsalas para revivir si te quedas sin vidas.';
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
  String get points => catalan ? 'Punts' : 'Puntos';
  String get carrots => catalan ? 'Pastanagues' : 'Zanahorias';
  String carrotsFed(int count) => catalan
      ? '$count ${count == 1 ? 'pastanaga' : 'pastanagues'} per al conill'
      : '$count ${count == 1 ? 'zanahoria' : 'zanahorias'} para el conejo';
  String scoreBreakdown(int base, int timeBonus, int livesBonus) => catalan
      ? 'Base ${formatNumber(base)} · Temps ${formatNumber(timeBonus)} · Vides ${formatNumber(livesBonus)}'
      : 'Base ${formatNumber(base)} · Tiempo ${formatNumber(timeBonus)} · Vidas ${formatNumber(livesBonus)}';
  String wrongBunny(int remaining) => catalan
      ? 'Conill mal col·locat. Et ${remaining == 1 ? 'queda' : 'queden'} $remaining ${remaining == 1 ? 'vida' : 'vides'}.'
      : 'Conejo mal colocado. Te ${remaining == 1 ? 'queda' : 'quedan'} $remaining ${remaining == 1 ? 'vida' : 'vidas'}.';
  String fastAdvance(int count) => catalan
      ? 'Salt ràpid: $count etapes'
      : 'Salto rápido: $count etapas';
  String get noLivesTitle => catalan ? 'Sense vides' : 'Sin vidas';
  String get noLivesBody =>
      catalan ? 'Has esgotat les tres vides.' : 'Has agotado las tres vidas.';
  String get revive => catalan ? 'Reviu' : 'Revivir';
  String reviveWithCarrots(int cost) => catalan
      ? 'Reviu · $cost pastanagues'
      : 'Revivir · $cost zanahorias';
  String carrotsOwned(int count) => catalan
      ? 'Tens $count ${count == 1 ? 'pastanaga' : 'pastanagues'}'
      : 'Tienes $count ${count == 1 ? 'zanahoria' : 'zanahorias'}';
  String reviveNeeds(int cost) => catalan
      ? 'Necessites $cost pastanagues per a reviure.'
      : 'Necesitas $cost zanahorias para revivir.';
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

  static String formatNumber(int value) {
    final digits = value.abs().toString();
    final buffer = StringBuffer();
    for (var index = 0; index < digits.length; index++) {
      if (index > 0 && (digits.length - index) % 3 == 0) buffer.write('.');
      buffer.write(digits[index]);
    }
    return value < 0 ? '-$buffer' : buffer.toString();
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
