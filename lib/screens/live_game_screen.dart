import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/game_state.dart';
import '../services/game_api_service.dart';
import '../services/session_service.dart';
import '../state/providers.dart';
import 'scoreboard_screen.dart';

/// Single screen that drives all game phases via Riverpod GameState.
class LiveGameScreen extends ConsumerStatefulWidget {
  final String gameCode;

  const LiveGameScreen({super.key, required this.gameCode});

  @override
  ConsumerState<LiveGameScreen> createState() => _LiveGameScreenState();
}

class _LiveGameScreenState extends ConsumerState<LiveGameScreen> {
  static const List<int> _scores = [500, 1000, 1500, 2000, 2500];

  String? _pendingCell;
  bool _actionLock = false;
  bool _connected = true;
  StreamSubscription<bool>? _connSub;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final socket = ref.read(socketServiceProvider);
      setState(() => _connected = socket.isConnected);
      _connSub = socket.connectionStream.listen((connected) {
        if (mounted) setState(() => _connected = connected);
      });
    });
  }

  @override
  void dispose() {
    _connSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final game = ref.watch(gameProvider);

    // Clear pending cell when phase leaves board
    if (game.phase != GamePhase.board && _pendingCell != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) setState(() => _pendingCell = null);
      });
    }

    if (game.phase == GamePhase.gameOver) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        SessionService.clear();
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => ScoreboardScreen(
              teams: game.teams.map((t) => t.name).toList(),
              scores: game.scoreMap,
            ),
          ),
        );
      });
    }

    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/images/bg.png'),
            fit: BoxFit.cover,
          ),
        ),
        child: SafeArea(
          child: Stack(
            children: [
              _BoardLayer(
                game: game,
                scores: _scores,
                onCellTap: game.isHost ? _onHostSelectQuestion : null,
                pendingCell: _pendingCell,
                onEndGame: game.isHost ? _onEndGame : null,
              ),

              if (game.phase == GamePhase.board && !game.isHost)
                const _PlayerBoardOverlay(),

              if (game.phase == GamePhase.question &&
                  game.activeQuestion?.type == 'cat' &&
                  !game.catRevealed)
                _CatOverlay(
                  game: game,
                  onRevealQuestion: _onRevealCatQuestion,
                ),

              if (game.phase == GamePhase.question &&
                  (game.activeQuestion?.type != 'cat' || game.catRevealed))
                _QuestionOverlay(game: game, onReveal: _onReveal),

              if (game.phase == GamePhase.result)
                _ResultOverlay(
                  game: game,
                  onAssignScore: _onAssignScore,
                  onSkip: _onSkip,
                  onPenalizeTeam: _onPenalizeTeam,
                ),

              if (game.isHost)
                Positioned(
                  left: 16,
                  top: 16,
                  child: Row(
                    children: [
                      _Pressable(
                        onTap: () {
                          SessionService.clear();
                          Navigator.pop(context);
                        },
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: const Color(0xFF863C15),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(Icons.arrow_back,
                              color: Colors.white, size: 24),
                        ),
                      ),
                      const SizedBox(width: 12),
                      _Pressable(
                        onTap: _onEndGame,
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: const Color(0xFF863C15),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(Icons.stop_circle_outlined,
                              color: Colors.white, size: 24),
                        ),
                      ),
                    ],
                  ),
                ),

              // ─── Connection status banner ──────────────────────────────────
              if (!_connected)
                Positioned(
                  bottom: 72,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 10),
                      decoration: BoxDecoration(
                        color: const Color(0xFFD94F00),
                        borderRadius: BorderRadius.circular(50),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.3),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          ),
                          SizedBox(width: 10),
                          Text(
                            'Нет связи с сервером… Переподключение',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  // ─── End game ────────────────────────────────────────────────────────────

  Future<void> _onEndGame() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFFFFF1E4),
        title: const Text('Подвести итоги?'),
        content: const Text(
            'Вы уверены, что хотите завершить игру и подвести итоги?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Отмена'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFFFA8723)),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Подвести итоги'),
          ),
        ],
      ),
    );
    if (confirm == true && mounted) {
      SessionService.clear();
      final socket = ref.read(socketServiceProvider);
      socket.endGame(widget.gameCode);
      final api = GameApiService();
      try {
        await api.deleteGame(widget.gameCode);
      } catch (_) {}
      api.close();
    }
  }

  // ─── Host actions with debounce ───────────────────────────────────────────

  void _onHostSelectQuestion(int roundIdx, int topicIdx, int scoreIdx) {
    if (_actionLock || _pendingCell != null) return;
    _actionLock = true;
    setState(() => _pendingCell = '$roundIdx-$topicIdx-$scoreIdx');

    final socket = ref.read(socketServiceProvider);
    socket.selectQuestion(
      code: widget.gameCode,
      roundIdx: roundIdx,
      topicIdx: topicIdx,
      scoreIdx: scoreIdx,
    );

    Future.delayed(const Duration(milliseconds: 500), () {
      _actionLock = false;
    });
  }

  void _onReveal() {
    if (_actionLock) return;
    _actionLock = true;
    final socket = ref.read(socketServiceProvider);
    socket.revealAnswer(widget.gameCode);
    Future.delayed(const Duration(milliseconds: 500), () {
      _actionLock = false;
    });
  }

  void _onAssignScore(int teamId) {
    if (_actionLock) return;
    _actionLock = true;
    final socket = ref.read(socketServiceProvider);
    socket.assignScore(code: widget.gameCode, teamId: teamId);
    Future.delayed(const Duration(milliseconds: 500), () {
      _actionLock = false;
    });
  }

  void _onSkip() {
    if (_actionLock) return;
    _actionLock = true;
    final socket = ref.read(socketServiceProvider);
    socket.skipQuestion(widget.gameCode);
    Future.delayed(const Duration(milliseconds: 500), () {
      _actionLock = false;
    });
  }

  void _onRevealCatQuestion() {
    if (_actionLock) return;
    _actionLock = true;
    final socket = ref.read(socketServiceProvider);
    socket.revealCatQuestion(widget.gameCode);
    Future.delayed(const Duration(milliseconds: 500), () {
      _actionLock = false;
    });
  }

  void _onPenalizeTeam(int teamId) {
    if (_actionLock) return;
    _actionLock = true;
    final socket = ref.read(socketServiceProvider);
    socket.penalizeTeam(code: widget.gameCode, teamId: teamId);
    Future.delayed(const Duration(milliseconds: 500), () {
      _actionLock = false;
    });
  }
}

// ─── Board Layer ─────────────────────────────────────────────────────────────

class _BoardLayer extends StatelessWidget {
  final GameState game;
  final List<int> scores;
  final void Function(int roundIdx, int topicIdx, int scoreIdx)? onCellTap;
  final String? pendingCell;
  final VoidCallback? onEndGame;

  const _BoardLayer({
    required this.game,
    required this.scores,
    this.onCellTap,
    this.pendingCell,
    this.onEndGame,
  });

  @override
  Widget build(BuildContext context) {
    if (game.rounds.isEmpty) return const SizedBox.shrink();

    final round = game.rounds[game.currentRound.clamp(0, game.rounds.length - 1)];
    final topics = round.topics;

    return LayoutBuilder(
      builder: (context, constraints) {
        return Column(
          children: [
            if (game.rounds.length > 1)
              _RoundTabs(game: game),

            Expanded(
              child: FittedBox(
                fit: BoxFit.contain,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: List.generate(topics.length, (ti) {
                    return Padding(
                      padding: EdgeInsets.only(
                          bottom: ti < topics.length - 1 ? 14 : 0),
                      child: _TopicRow(
                        topicName: topics[ti].name,
                        scores: scores,
                        roundIdx: game.currentRound,
                        topicIdx: ti,
                        usedQuestionIds: game.usedQuestionIds,
                        game: game,
                        onCellTap: onCellTap,
                        pendingCell: pendingCell,
                      ),
                    );
                  }),
                ),
              ),
            ),

            if (game.isHost && onEndGame != null)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 6),
                child: _Pressable(
                  onTap: onEndGame,
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFA8723),
                      borderRadius: BorderRadius.circular(50),
                    ),
                    child: const Center(
                      child: Text(
                        'Итоги',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                          letterSpacing: -0.4,
                          height: 1.0,
                        ),
                      ),
                    ),
                  ),
                ),
              ),

            _TeamScoresBar(teams: game.teams),
          ],
        );
      },
    );
  }
}

class _RoundTabs extends ConsumerWidget {
  final GameState game;

  const _RoundTabs({required this.game});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: List.generate(game.rounds.length, (ri) {
            final selected = ri == game.currentRound;
            return Padding(
              padding: EdgeInsets.only(right: ri < game.rounds.length - 1 ? 10 : 0),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 10),
                decoration: BoxDecoration(
                  color: selected ? const Color(0xFF863C15) : Colors.transparent,
                  border: selected
                      ? null
                      : Border.all(color: const Color(0xFF863C15), width: 2),
                  borderRadius: BorderRadius.circular(50),
                ),
                child: Text(
                  game.rounds[ri].name,
                  style: TextStyle(
                    color: selected ? Colors.white : const Color(0xFF863C15),
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            );
          }),
        ),
      ),
    );
  }
}

class _ScoreHeader extends StatelessWidget {
  final List<int> scores;

  const _ScoreHeader({required this.scores});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
      child: Row(
        children: [
          const SizedBox(width: 200),
          ...scores.map(
            (s) => Expanded(
              child: Center(
                child: Text(
                  s.toString(),
                  style: const TextStyle(
                    color: Color(0xFF3A1800),
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TopicRow extends StatelessWidget {
  final String topicName;
  final List<int> scores;
  final int roundIdx;
  final int topicIdx;
  final Set<int> usedQuestionIds;
  final GameState game;
  final void Function(int roundIdx, int topicIdx, int scoreIdx)? onCellTap;
  final String? pendingCell;

  const _TopicRow({
    required this.topicName,
    required this.scores,
    required this.roundIdx,
    required this.topicIdx,
    required this.usedQuestionIds,
    required this.game,
    required this.onCellTap,
    this.pendingCell,
  });

  bool _isUsed(int scoreIdx) {
    final aq = game.activeQuestion;
    if (game.phase != GamePhase.board) {
      if (aq != null &&
          aq.roundIdx == roundIdx &&
          aq.topicIdx == topicIdx &&
          aq.scoreIdx == scoreIdx) {
        return true;
      }
    }

    if (roundIdx >= game.rounds.length) return false;
    final round = game.rounds[roundIdx];
    if (topicIdx >= round.topics.length) return false;
    final topic = round.topics[topicIdx];
    if (scoreIdx >= topic.questionIds.length) return false;
    final qid = topic.questionIds[scoreIdx];
    if (qid != null && game.usedQuestionIds.contains(qid)) {
      return true;
    }

    return false;
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 200,
          height: 72,
          decoration: BoxDecoration(
            color: const Color(0xFFFFFBF7),
            borderRadius: BorderRadius.circular(18),
          ),
          alignment: Alignment.center,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Text(
              topicName,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Color(0xFF3A1800),
                fontSize: 22,
                fontWeight: FontWeight.w600,
                letterSpacing: -0.4,
                height: 1.2,
              ),
            ),
          ),
        ),
        const SizedBox(width: 14),
        ...List.generate(scores.length, (si) {
          final used = _isUsed(si);
          final isPending = pendingCell == '$roundIdx-$topicIdx-$si';
          final canTap = !used && !isPending && pendingCell == null && onCellTap != null;
          return Padding(
            padding: EdgeInsets.only(right: si < scores.length - 1 ? 12 : 0),
            child: _Pressable(
              onTap: canTap ? () => onCellTap!(roundIdx, topicIdx, si) : null,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                width: 110,
                height: 72,
                decoration: BoxDecoration(
                  color: isPending
                      ? const Color(0xFFA35A33)
                      : used
                          ? const Color(0xFFD4B89A).withValues(alpha: 0.5)
                          : const Color(0xFF863C15),
                  borderRadius: BorderRadius.circular(18),
                ),
                alignment: Alignment.center,
                child: isPending
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          color: Colors.white,
                        ),
                      )
                    : Opacity(
                        opacity: used ? 0.5 : 1.0,
                        child: Text(
                          scores[si].toString(),
                          style: TextStyle(
                            color: used
                                ? const Color(0xFFB89070)
                                : Colors.white,
                            fontSize: 28,
                            fontWeight: FontWeight.w700,
                            letterSpacing: -0.5,
                            height: 1.0,
                          ),
                        ),
                      ),
              ),
            ),
          );
        }),
      ],
    );
  }
}

class _TeamScoresBar extends StatelessWidget {
  final List<TeamState> teams;

  const _TeamScoresBar({required this.teams});

  @override
  Widget build(BuildContext context) {
    if (teams.isEmpty) return const SizedBox.shrink();
    return Container(
      height: 56,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF1E4),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: teams.map((t) {
          return Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  t.name,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFF3A1800),
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  t.score.toString(),
                  style: const TextStyle(
                    color: Color(0xFF863C15),
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}

// ─── Player board overlay ─────────────────────────────────────────────────────

class _PlayerBoardOverlay extends StatelessWidget {
  const _PlayerBoardOverlay();

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: IgnorePointer(
        child: Container(
          color: Colors.black.withValues(alpha: 0.35),
          alignment: Alignment.center,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 20),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF1E4),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Text(
              'Ведущий выбирает вопрос…',
              style: TextStyle(
                color: Color(0xFF3A1800),
                fontSize: 22,
                fontWeight: FontWeight.w600,
                letterSpacing: -0.4,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Question Overlay ─────────────────────────────────────────────────────────

// ─── Cat Overlay ──────────────────────────────────────────────────────────────

class _CatOverlay extends StatelessWidget {
  final GameState game;
  final VoidCallback onRevealQuestion;

  const _CatOverlay({required this.game, required this.onRevealQuestion});

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: Container(
        color: Colors.black.withValues(alpha: 0.80),
        child: Center(
          child: Container(
            constraints: const BoxConstraints(maxWidth: 480),
            margin: const EdgeInsets.symmetric(horizontal: 32),
            padding: const EdgeInsets.all(40),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF1E4),
              borderRadius: BorderRadius.circular(28),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.pets,
                  size: 72,
                  color: Color(0xFF863C15),
                ),
                const SizedBox(height: 20),
                const Text(
                  'Кот в мешке!',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Color(0xFF3A1800),
                    fontSize: 32,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Команда выбирает, кто будет отвечать',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Color(0xFF9C532C),
                    fontSize: 18,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 32),
                if (game.isHost)
                  _ActionButton(
                    label: 'Показать вопрос',
                    onTap: onRevealQuestion,
                  )
                else
                  const Text(
                    'Ожидайте ведущего…',
                    style: TextStyle(
                      color: Color(0xFF9C532C),
                      fontSize: 18,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Question Overlay ─────────────────────────────────────────────────────────

class _QuestionOverlay extends StatelessWidget {
  final GameState game;
  final VoidCallback onReveal;

  const _QuestionOverlay({required this.game, required this.onReveal});

  @override
  Widget build(BuildContext context) {
    final aq = game.activeQuestion;
    if (aq == null) return const SizedBox.shrink();

    return Positioned.fill(
      child: Container(
        color: Colors.black.withValues(alpha: 0.75),
        child: Center(
          child: Container(
            constraints: const BoxConstraints(maxWidth: 680),
            margin: const EdgeInsets.symmetric(horizontal: 32),
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF1E4),
              borderRadius: BorderRadius.circular(28),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (aq.type == 'bonus') ...[
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFA8723),
                      borderRadius: BorderRadius.circular(50),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.star, color: Colors.white, size: 20),
                        SizedBox(width: 6),
                        Text(
                          'БОНУС x2',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
                // Score badge
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 20, vertical: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF863C15),
                    borderRadius: BorderRadius.circular(50),
                  ),
                  child: Text(
                    '${aq.score} очков',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                // Question text
                Text(
                  aq.questionText,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Color(0xFF3A1800),
                    fontSize: 26,
                    fontWeight: FontWeight.w600,
                    letterSpacing: -0.5,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 28),
                // Timer
                _TimerDisplay(seconds: game.timerSeconds),
                const SizedBox(height: 24),
                // Host-only reveal button
                if (game.isHost)
                  _ActionButton(
                    label: 'Раскрыть ответ',
                    onTap: onReveal,
                  )
                else
                  const Text(
                    'Ожидайте…',
                    style: TextStyle(
                      color: Color(0xFF9C532C),
                      fontSize: 18,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _TimerDisplay extends StatelessWidget {
  final int seconds;

  const _TimerDisplay({required this.seconds});

  @override
  Widget build(BuildContext context) {
    final color = seconds <= 10
        ? const Color(0xFFD94F00)
        : const Color(0xFF3A1800);
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.timer_outlined, color: color, size: 28),
        const SizedBox(width: 8),
        Text(
          '$seconds с',
          style: TextStyle(
            color: color,
            fontSize: 28,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.5,
          ),
        ),
      ],
    );
  }
}

// ─── Result Overlay (sequential turn-passing) ────────────────────────────────

class _ResultOverlay extends StatefulWidget {
  final GameState game;
  final void Function(int teamId) onAssignScore;
  final VoidCallback onSkip;
  final void Function(int teamId) onPenalizeTeam;

  const _ResultOverlay({
    required this.game,
    required this.onAssignScore,
    required this.onSkip,
    required this.onPenalizeTeam,
  });

  @override
  State<_ResultOverlay> createState() => _ResultOverlayState();
}

class _ResultOverlayState extends State<_ResultOverlay> {
  int _currentTeamIndex = 0;
  final Set<int> _penalizedTeamIds = {};
  bool _finished = false;

  void _onCorrect(int teamId) {
    widget.onAssignScore(teamId);
  }

  void _onWrong(int teamId) {
    _penalizedTeamIds.add(teamId);
    widget.onPenalizeTeam(teamId);
    _advanceToNext();
  }

  void _onDidNotAnswer() {
    _advanceToNext();
  }

  void _advanceToNext() {
    final nextIdx = _currentTeamIndex + 1;
    if (nextIdx >= widget.game.teams.length) {
      setState(() => _finished = true);
      widget.onSkip();
    } else {
      setState(() => _currentTeamIndex = nextIdx);
    }
  }

  void _skipAll() {
    widget.onSkip();
  }

  @override
  Widget build(BuildContext context) {
    final aq = widget.game.activeQuestion;
    final teams = widget.game.teams;

    return Positioned.fill(
      child: Container(
        color: Colors.black.withValues(alpha: 0.75),
        child: Center(
          child: Container(
            constraints: const BoxConstraints(maxWidth: 720),
            margin: const EdgeInsets.symmetric(horizontal: 32),
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF1E4),
              borderRadius: BorderRadius.circular(28),
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Правильный ответ',
                    style: TextStyle(
                      color: Color(0xFF9C532C),
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFE4C4),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(
                      widget.game.revealedAnswer ?? '—',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Color(0xFF3A1800),
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                        height: 1.3,
                      ),
                    ),
                  ),
                  if (aq != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      aq.type == 'bonus'
                          ? '${aq.score} очков (x2 бонус)'
                          : '${aq.score} очков',
                      style: const TextStyle(
                        color: Color(0xFF9C532C),
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],

                  const SizedBox(height: 24),

                  if (widget.game.isHost && !_finished) ...[
                    if (_currentTeamIndex < teams.length) ...[
                      Text(
                        'Отвечает: ${teams[_currentTeamIndex].name}',
                        style: const TextStyle(
                          color: Color(0xFF3A1800),
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Команда ${_currentTeamIndex + 1} из ${teams.length}',
                        style: const TextStyle(
                          color: Color(0xFF9C532C),
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 20),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _Pressable(
                            onTap: () =>
                                _onCorrect(teams[_currentTeamIndex].id),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 20, vertical: 12),
                              decoration: BoxDecoration(
                                color: const Color(0xFF2E7D32),
                                borderRadius: BorderRadius.circular(50),
                              ),
                              child: Text(
                                'Правильно +${aq?.score ?? 0}',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          _Pressable(
                            onTap: () =>
                                _onWrong(teams[_currentTeamIndex].id),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 20, vertical: 12),
                              decoration: BoxDecoration(
                                color: const Color(0xFFD94F00),
                                borderRadius: BorderRadius.circular(50),
                              ),
                              child: Text(
                                'Неправильно -${aq?.score ?? 0}',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      _Pressable(
                        onTap: _onDidNotAnswer,
                        child: const Text(
                          'Не отвечала',
                          style: TextStyle(
                            color: Color(0xFF9C532C),
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            decoration: TextDecoration.underline,
                            decorationColor: Color(0xFF9C532C),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      _Pressable(
                        onTap: _skipAll,
                        child: const Text(
                          'Пропустить всех',
                          style: TextStyle(
                            color: Color(0xFF9C532C),
                            fontSize: 14,
                            fontWeight: FontWeight.w400,
                            decoration: TextDecoration.underline,
                            decorationColor: Color(0xFF9C532C),
                          ),
                        ),
                      ),
                    ],
                  ] else if (!widget.game.isHost) ...[
                    if (widget.game.awardedTeamId != null)
                      _ScoreAwardedBadge(
                        teamName: widget.game.teams
                            .firstWhere(
                              (t) => t.id == widget.game.awardedTeamId,
                              orElse: () => const TeamState(
                                  id: 0, name: '?', score: 0),
                            )
                            .name,
                        score: widget.game.awardedScore ?? 0,
                      )
                    else
                      const Text(
                        'Ведущий оценивает ответы…',
                        style: TextStyle(
                          color: Color(0xFF9C532C),
                          fontSize: 18,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ScoreAwardedBadge extends StatelessWidget {
  final String teamName;
  final int score;

  const _ScoreAwardedBadge({required this.teamName, required this.score});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
      decoration: BoxDecoration(
        color: const Color(0xFF863C15),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        '$teamName +$score',
        style: const TextStyle(
          color: Colors.white,
          fontSize: 20,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

// ─── Shared UI primitives ─────────────────────────────────────────────────────

/// Wraps any child with scale-down press feedback.
class _Pressable extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;

  const _Pressable({required this.child, this.onTap});

  @override
  State<_Pressable> createState() => _PressableState();
}

class _PressableState extends State<_Pressable>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 80),
      reverseDuration: const Duration(milliseconds: 120),
    );
    _scale = Tween(begin: 1.0, end: 0.92).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _onTapDown(TapDownDetails _) {
    if (widget.onTap != null) _ctrl.forward();
  }

  void _onTapUp(TapUpDetails _) {
    _ctrl.reverse();
  }

  void _onTapCancel() {
    _ctrl.reverse();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: widget.onTap,
      onTapDown: _onTapDown,
      onTapUp: _onTapUp,
      onTapCancel: _onTapCancel,
      child: ScaleTransition(scale: _scale, child: widget.child),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final String label;
  final VoidCallback? onTap;

  const _ActionButton({required this.label, this.onTap});

  @override
  Widget build(BuildContext context) {
    return _Pressable(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFA35A33), Color(0xFF863C15)],
          ),
          borderRadius: BorderRadius.circular(50),
        ),
        child: Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w600,
            letterSpacing: -0.3,
          ),
        ),
      ),
    );
  }
}
