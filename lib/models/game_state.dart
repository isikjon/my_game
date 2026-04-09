/// Central game state model — single source of truth for all clients.
library;

// ─── Enums ───────────────────────────────────────────────────────────────────

enum GamePhase { lobby, board, question, result, gameOver }

enum PlayerRole { host, player }

// ─── Sub-models ──────────────────────────────────────────────────────────────

class TeamState {
  final int id;
  final String name;
  final int score;

  const TeamState({required this.id, required this.name, required this.score});

  TeamState copyWith({int? id, String? name, int? score}) => TeamState(
        id: id ?? this.id,
        name: name ?? this.name,
        score: score ?? this.score,
      );

  factory TeamState.fromJson(Map<String, dynamic> j) => TeamState(
        id: (j['id'] as num).toInt(),
        name: j['name'] as String,
        score: (j['score'] as num?)?.toInt() ?? 0,
      );
}

class ActiveQuestion {
  final int questionId;
  final String questionText;
  final int score;
  final String type;
  final int roundIdx;
  final int topicIdx;
  final int scoreIdx;

  const ActiveQuestion({
    required this.questionId,
    required this.questionText,
    required this.score,
    required this.type,
    required this.roundIdx,
    required this.topicIdx,
    required this.scoreIdx,
  });
}

// ─── Round / Topic metadata (for board rendering) ────────────────────────────

class LiveTopicState {
  final String name;
  final List<int?> questionIds; // map to scoreOrder [500, 1000, 1500, 2000, 2500]

  const LiveTopicState({required this.name, required this.questionIds});
}

class LiveRoundState {
  final String name;
  final int timeSeconds;
  final List<LiveTopicState> topics;

  const LiveRoundState({
    required this.name,
    required this.timeSeconds,
    required this.topics,
  });
}

// ─── Root GameState ───────────────────────────────────────────────────────────

class GameState {
  final GamePhase phase;
  final String gameCode;
  final PlayerRole role;
  final List<TeamState> teams;
  final List<LiveRoundState> rounds;
  final int currentRound;
  final ActiveQuestion? activeQuestion;
  final int timerSeconds;
  final String? revealedAnswer;
  final Set<int> usedQuestionIds;
  final int? awardedTeamId;
  final int? awardedScore;
  final bool catRevealed;

  const GameState({
    required this.phase,
    required this.gameCode,
    required this.role,
    required this.teams,
    required this.rounds,
    required this.currentRound,
    this.activeQuestion,
    required this.timerSeconds,
    this.revealedAnswer,
    required this.usedQuestionIds,
    this.awardedTeamId,
    this.awardedScore,
    this.catRevealed = false,
  });

  /// Initial lobby state before the game starts.
  factory GameState.lobby({
    required String gameCode,
    required PlayerRole role,
    required List<TeamState> teams,
    required List<LiveRoundState> rounds,
  }) =>
      GameState(
        phase: GamePhase.lobby,
        gameCode: gameCode,
        role: role,
        teams: teams,
        rounds: rounds,
        currentRound: 0,
        timerSeconds: 0,
        usedQuestionIds: const {},
      );

  GameState copyWith({
    GamePhase? phase,
    String? gameCode,
    PlayerRole? role,
    List<TeamState>? teams,
    List<LiveRoundState>? rounds,
    int? currentRound,
    Object? activeQuestion = _sentinel,
    int? timerSeconds,
    Object? revealedAnswer = _sentinel,
    Set<int>? usedQuestionIds,
    Object? awardedTeamId = _sentinel,
    Object? awardedScore = _sentinel,
    bool? catRevealed,
  }) =>
      GameState(
        phase: phase ?? this.phase,
        gameCode: gameCode ?? this.gameCode,
        role: role ?? this.role,
        teams: teams ?? this.teams,
        rounds: rounds ?? this.rounds,
        currentRound: currentRound ?? this.currentRound,
        activeQuestion: activeQuestion == _sentinel
            ? this.activeQuestion
            : activeQuestion as ActiveQuestion?,
        timerSeconds: timerSeconds ?? this.timerSeconds,
        revealedAnswer: revealedAnswer == _sentinel
            ? this.revealedAnswer
            : revealedAnswer as String?,
        usedQuestionIds: usedQuestionIds ?? this.usedQuestionIds,
        awardedTeamId: awardedTeamId == _sentinel
            ? this.awardedTeamId
            : awardedTeamId as int?,
        awardedScore: awardedScore == _sentinel
            ? this.awardedScore
            : awardedScore as int?,
        catRevealed: catRevealed ?? this.catRevealed,
      );

  bool get isHost => role == PlayerRole.host;

  /// Scores map — convenience helper for display.
  Map<String, int> get scoreMap =>
      {for (final t in teams) t.name: t.score};
}

// Sentinel for nullable copyWith fields.
const Object _sentinel = Object();

// ─── Server JSON helpers ──────────────────────────────────────────────────────

List<LiveRoundState> parseRoundsFromServerJson(List<dynamic> rawRounds) {
  const scoreOrder = [500, 1000, 1500, 2000, 2500];
  return rawRounds.map((r) {
    final rawTopics = (r['topics'] as List?) ?? [];
    final topics = rawTopics.map((t) {
      final rawQuestions = (t['questions'] as List?) ?? [];
      final qids = List<int?>.filled(5, null);
      for (final q in rawQuestions) {
        final score = (q['score'] as num).toInt();
        final idx = scoreOrder.indexOf(score);
        if (idx >= 0) qids[idx] = (q['id'] as num).toInt();
      }
      return LiveTopicState(
        name: t['name'] as String,
        questionIds: qids,
      );
    }).toList();
    return LiveRoundState(
      name: r['name'] as String,
      timeSeconds: (r['time_seconds'] as num?)?.toInt() ?? 60,
      topics: topics,
    );
  }).toList();
}

List<TeamState> parseTeamsFromServerJson(List<dynamic> rawTeams) {
  return rawTeams.map((t) => TeamState.fromJson(t as Map<String, dynamic>)).toList();
}
