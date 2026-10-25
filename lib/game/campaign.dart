import '../data/puzzle_repository.dart';
import 'puzzle.dart';

/// Etapa de la campaña: una secuencia lineal de puzles de 6×6 a 9×9.
class CampaignStage {
  const CampaignStage({
    required this.number,
    required this.size,
    required this.level,
    required this.totalStages,
    required this.givenBunnies,
    required this.endless,
  });

  final int number;
  final int size;
  final int level;
  final int totalStages;
  final int givenBunnies;
  final bool endless;

  int get completed => number - 1;
  double get progress =>
      totalStages == 0 ? 0 : (completed / totalStages).clamp(0.0, 1.0);
}

int campaignTotalStages(PuzzleRepository repository) {
  var total = 0;
  for (final size in supportedSizes) {
    total += repository.puzzlesFor(size).length;
  }
  return total;
}

CampaignStage campaignStageFor(PuzzleRepository repository, int number) {
  final total = campaignTotalStages(repository);
  final stage = number < 1 ? 1 : number;
  var offset = 0;
  for (final size in supportedSizes) {
    final count = repository.puzzlesFor(size).length;
    if (stage <= offset + count) {
      return CampaignStage(
        number: stage,
        size: size,
        level: stage - offset,
        totalStages: total,
        givenBunnies: _givenBunnies(stage),
        endless: false,
      );
    }
    offset += count;
  }

  final size = supportedSizes.last;
  final count = repository.puzzlesFor(size).length;
  return CampaignStage(
    number: stage,
    size: size,
    level: (stage - offset - 1) % count + 1,
    totalStages: total,
    givenBunnies: 0,
    endless: true,
  );
}

int _givenBunnies(int stage) {
  if (stage <= 3) return 2;
  if (stage <= 6) return 1;
  return 0;
}

Iterable<int> givenCellsFor(Puzzle puzzle, int count) =>
    puzzle.solution.take(count.clamp(0, puzzle.size));
