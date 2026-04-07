import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/game_state.dart';
import 'socket_service.dart';

/// Maps every server Socket.IO event to a GameState transition.
/// UI rebuilds automatically via Riverpod whenever state changes.
class GameNotifier extends StateNotifier<GameState> {
  GameNotifier(this._socket, GameState initialState) : super(initialState) {
    _subscribeAll();
  }

  final SocketService _socket;

  // ─── Subscribe to all server events ──────────────────────────────────────

  void _subscribeAll() {
    _socket.on('game-started', _onGameStarted);
    _socket.on('question-selected', _onQuestionSelected);
    _socket.on('timer-tick', _onTimerTick);
    _socket.on('timer-ended', _onTimerEnded);
    _socket.on('answer-revealed', _onAnswerRevealed);
    _socket.on('score-updated', _onScoreUpdated);
    _socket.on('question-skipped', _onQuestionSkipped);
    _socket.on('round-changed', _onRoundChanged);
    _socket.on('game-ended', _onGameEnded);
    _socket.on('host-disconnected', _onHostDisconnected);
  }

  @override
  void dispose() {
    _socket.off('game-started');
    _socket.off('question-selected');
    _socket.off('timer-tick');
    _socket.off('timer-ended');
    _socket.off('answer-revealed');
    _socket.off('score-updated');
    _socket.off('question-skipped');
    _socket.off('round-changed');
    _socket.off('game-ended');
    _socket.off('host-disconnected');
    super.dispose();
  }

  // ─── Event handlers ───────────────────────────────────────────────────────

  void _onGameStarted(dynamic data) {
    if (data is! Map) return;
    final rounds = parseRoundsFromServerJson(
      (data['rounds'] as List?) ?? [],
    );
    final teams = parseTeamsFromServerJson(
      (data['teams'] as List?) ?? [],
    );
    state = state.copyWith(
      phase: GamePhase.board,
      rounds: rounds.isEmpty ? state.rounds : rounds,
      teams: teams.isEmpty ? state.teams : teams,
      currentRound: (data['current_round'] as num?)?.toInt() ?? 0,
      usedQuestionIds: const {},
    );
  }

  void _onQuestionSelected(dynamic data) {
    if (data is! Map) return;
    final question = ActiveQuestion(
      questionId: (data['questionId'] as num).toInt(),
      questionText: data['questionText'] as String,
      score: (data['score'] as num).toInt(),
      type: data['type'] as String? ?? 'normal',
      roundIdx: (data['roundIdx'] as num).toInt(),
      topicIdx: (data['topicIdx'] as num).toInt(),
      scoreIdx: (data['scoreIdx'] as num).toInt(),
    );
    state = state.copyWith(
      phase: GamePhase.question,
      activeQuestion: question,
      timerSeconds: (data['timerSeconds'] as num?)?.toInt() ?? 60,
      revealedAnswer: null,
      awardedTeamId: null,
      awardedScore: null,
    );
  }

  void _onTimerTick(dynamic data) {
    if (data is! Map) return;
    final secs = (data['seconds'] as num?)?.toInt() ?? 0;
    state = state.copyWith(timerSeconds: secs);
  }

  void _onTimerEnded(dynamic _) {
    state = state.copyWith(timerSeconds: 0);
  }

  void _onAnswerRevealed(dynamic data) {
    if (data is! Map) return;
    state = state.copyWith(
      phase: GamePhase.result,
      revealedAnswer: data['answerText'] as String?,
    );
  }

  void _onScoreUpdated(dynamic data) {
    if (data is! Map) return;
    final rawTeams = (data['teams'] as List?) ?? [];
    final teams = parseTeamsFromServerJson(rawTeams);
    final awardedTeamId =
        data['awardedTeamId'] != null ? (data['awardedTeamId'] as num).toInt() : null;
    final awardedScore =
        data['awardedScore'] != null ? (data['awardedScore'] as num).toInt() : null;
    final questionId =
        data['questionId'] != null ? (data['questionId'] as num).toInt() : null;

    final newUsed = {...state.usedQuestionIds};
    if (questionId != null) newUsed.add(questionId);

    state = state.copyWith(
      phase: GamePhase.board,
      teams: teams,
      awardedTeamId: awardedTeamId,
      awardedScore: awardedScore,
      usedQuestionIds: newUsed,
      activeQuestion: null,
      revealedAnswer: null,
    );
  }

  void _onQuestionSkipped(dynamic data) {
    final questionId = data is Map && data['questionId'] != null
        ? (data['questionId'] as num).toInt()
        : null;
    final newUsed = {...state.usedQuestionIds};
    if (questionId != null) newUsed.add(questionId);
    state = state.copyWith(
      phase: GamePhase.board,
      usedQuestionIds: newUsed,
      activeQuestion: null,
      revealedAnswer: null,
      awardedTeamId: null,
      awardedScore: null,
    );
  }

  void _onRoundChanged(dynamic data) {
    if (data is! Map) return;
    final roundIdx = (data['roundIdx'] as num?)?.toInt() ?? state.currentRound;
    final updatedGame = data['game'];
    List<LiveRoundState> rounds = state.rounds;
    List<TeamState> teams = state.teams;
    if (updatedGame is Map) {
      final r = parseRoundsFromServerJson((updatedGame['rounds'] as List?) ?? []);
      final t = parseTeamsFromServerJson((updatedGame['teams'] as List?) ?? []);
      if (r.isNotEmpty) rounds = r;
      if (t.isNotEmpty) teams = t;
    }
    state = state.copyWith(
      currentRound: roundIdx,
      rounds: rounds,
      teams: teams,
      phase: GamePhase.board,
      usedQuestionIds: const {},
      activeQuestion: null,
    );
  }

  void _onGameEnded(dynamic data) {
    if (data is! Map) return;
    final rawTeams = (data['teams'] as List?) ?? [];
    final teams = parseTeamsFromServerJson(rawTeams);
    state = state.copyWith(
      phase: GamePhase.gameOver,
      teams: teams.isEmpty ? state.teams : teams,
      activeQuestion: null,
      revealedAnswer: null,
    );
  }

  void _onHostDisconnected(dynamic _) {
    // Keep current state — players will see a "host disconnected" notice
    // when we add that UI later. For now stay on current phase.
  }
}
