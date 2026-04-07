import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/game_state.dart';
import '../state/providers.dart';
import 'live_game_over_screen.dart';

/// Single screen that drives all game phases via Riverpod GameState.
/// Phase rendering:
///   board    → tappable grid (host) / locked grid + overlay (player)
///   question → question text + countdown timer
///   result   → answer reveal + score assignment (host) or wait (player)
///   gameOver → navigates to LiveGameOverScreen
class LiveGameScreen extends ConsumerStatefulWidget {
  final String gameCode;

  const LiveGameScreen({super.key, required this.gameCode});

  @override
  ConsumerState<LiveGameScreen> createState() => _LiveGameScreenState();
}

class _LiveGameScreenState extends ConsumerState<LiveGameScreen> {
  static const List<int> _scores = [500, 1000, 1500, 2000, 2500];

  @override
  Widget build(BuildContext context) {
    final game = ref.watch(gameProvider);

    // Navigate to game over when phase changes
    if (game.phase == GamePhase.gameOver) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => LiveGameOverScreen(teams: game.teams),
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
              // ── Always-visible board ──────────────────────────────────────
              _BoardLayer(
                game: game,
                scores: _scores,
                onCellTap: game.isHost ? _onHostSelectQuestion : null,
              ),

              // ── Phase overlays ────────────────────────────────────────────
              if (game.phase == GamePhase.board && !game.isHost)
                const _PlayerBoardOverlay(),

              if (game.phase == GamePhase.question)
                _QuestionOverlay(game: game, onReveal: _onReveal),

              if (game.phase == GamePhase.result)
                _ResultOverlay(
                  game: game,
                  onAssignScore: _onAssignScore,
                  onSkip: _onSkip,
                ),
            ],
          ),
        ),
      ),
    );
  }

  // ─── Host actions ─────────────────────────────────────────────────────────

  void _onHostSelectQuestion(int roundIdx, int topicIdx, int scoreIdx) {
    final socket = ref.read(socketServiceProvider);
    socket.selectQuestion(
      code: widget.gameCode,
      roundIdx: roundIdx,
      topicIdx: topicIdx,
      scoreIdx: scoreIdx,
    );
  }

  void _onReveal() {
    final socket = ref.read(socketServiceProvider);
    socket.revealAnswer(widget.gameCode);
  }

  void _onAssignScore(int teamId) {
    final socket = ref.read(socketServiceProvider);
    socket.assignScore(code: widget.gameCode, teamId: teamId);
  }

  void _onSkip() {
    final socket = ref.read(socketServiceProvider);
    socket.skipQuestion(widget.gameCode);
  }
}

// ─── Board Layer ─────────────────────────────────────────────────────────────

class _BoardLayer extends StatelessWidget {
  final GameState game;
  final List<int> scores;
  // null = board is locked (player mode)
  final void Function(int roundIdx, int topicIdx, int scoreIdx)? onCellTap;

  const _BoardLayer({
    required this.game,
    required this.scores,
    this.onCellTap,
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
            // Round tabs
            if (game.rounds.length > 1)
              _RoundTabs(game: game),

            // Score header
            _ScoreHeader(scores: scores),

            // Topic rows
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
                      ),
                    );
                  }),
                ),
              ),
            ),

            // Scores footer
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

  const _TopicRow({
    required this.topicName,
    required this.scores,
    required this.roundIdx,
    required this.topicIdx,
    required this.usedQuestionIds,
    required this.game,
    required this.onCellTap,
  });

  bool _isUsed(int scoreIdx) {
    // Check coordinate-based active question
    final aq = game.activeQuestion;
    if (game.phase != GamePhase.board) {
      if (aq != null &&
          aq.roundIdx == roundIdx &&
          aq.topicIdx == topicIdx &&
          aq.scoreIdx == scoreIdx) {
        return true;
      }
    }

    // Check permanent used status from question IDs
    final round = game.rounds[roundIdx];
    final topic = round.topics[topicIdx];
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
        // Topic name
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
        // Score cells
        ...List.generate(scores.length, (si) {
          final used = _isUsed(si);
          final canTap = !used && onCellTap != null;
          return Padding(
            padding: EdgeInsets.only(right: si < scores.length - 1 ? 12 : 0),
            child: GestureDetector(
              onTap: canTap ? () => onCellTap!(roundIdx, topicIdx, si) : null,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                width: 110,
                height: 72,
                decoration: BoxDecoration(
                  color: used
                      ? const Color(0xFFD4B89A)
                      : const Color(0xFF863C15),
                  borderRadius: BorderRadius.circular(18),
                ),
                alignment: Alignment.center,
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

// ─── Result Overlay ───────────────────────────────────────────────────────────

class _ResultOverlay extends StatelessWidget {
  final GameState game;
  final void Function(int teamId) onAssignScore;
  final VoidCallback onSkip;

  const _ResultOverlay({
    required this.game,
    required this.onAssignScore,
    required this.onSkip,
  });

  @override
  Widget build(BuildContext context) {
    final aq = game.activeQuestion;

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
                  // Answer
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
                      game.revealedAnswer ?? '—',
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
                      '${aq.score} очков',
                      style: const TextStyle(
                        color: Color(0xFF9C532C),
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],

                  const SizedBox(height: 24),

                  // Host: assign score OR player: wait
                  if (game.isHost) ...[
                    const Text(
                      'Кто ответил правильно?',
                      style: TextStyle(
                        color: Color(0xFF3A1800),
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      alignment: WrapAlignment.center,
                      children: game.teams
                          .map((t) => _ActionButton(
                                label: t.name,
                                onTap: () => onAssignScore(t.id),
                              ))
                          .toList(),
                    ),
                    const SizedBox(height: 12),
                    GestureDetector(
                      onTap: onSkip,
                      child: const Text(
                        'Никто не ответил',
                        style: TextStyle(
                          color: Color(0xFF9C532C),
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          decoration: TextDecoration.underline,
                          decorationColor: Color(0xFF9C532C),
                        ),
                      ),
                    ),
                  ] else ...[
                    // Score update feedback for players
                    if (game.awardedTeamId != null)
                      _ScoreAwardedBadge(
                        teamName: game.teams
                            .firstWhere(
                              (t) => t.id == game.awardedTeamId,
                              orElse: () => TeamState(
                                  id: 0, name: '?', score: 0),
                            )
                            .name,
                        score: game.awardedScore ?? 0,
                      )
                    else
                      const Text(
                        'Ведущий присваивает очки…',
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

class _ActionButton extends StatelessWidget {
  final String label;
  final VoidCallback? onTap;

  const _ActionButton({required this.label, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
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
