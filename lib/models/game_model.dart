enum GameQuestionType { normal, bonus, cat }

class GameQuestionModel {
  final GameQuestionType type;
  final String question;
  final String answer;

  const GameQuestionModel({
    required this.type,
    required this.question,
    required this.answer,
  });
}

class GameTopicModel {
  final String name;
  // index 0→500, 1→1000, 2→1500, 3→2000, 4→2500
  final List<GameQuestionModel?> questions;

  const GameTopicModel({required this.name, required this.questions});
}

class GameRoundModel {
  final String name;
  final int timeSeconds;
  final List<GameTopicModel> topics;

  const GameRoundModel({
    required this.name,
    required this.timeSeconds,
    required this.topics,
  });
}

class GameModel {
  final List<GameRoundModel> rounds;

  const GameModel({required this.rounds});
}
