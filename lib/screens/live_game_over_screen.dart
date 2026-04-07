import 'package:flutter/material.dart';

import '../models/game_state.dart';
import 'mode_selection_screen.dart';

/// Final leaderboard shown to all clients when the game ends.
class LiveGameOverScreen extends StatelessWidget {
  final List<TeamState> teams;

  const LiveGameOverScreen({super.key, required this.teams});

  @override
  Widget build(BuildContext context) {
    final sorted = [...teams]..sort((a, b) => b.score.compareTo(a.score));

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
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 28),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'Итоги игры',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Color(0xFF3A1800),
                    fontSize: 36,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.8,
                    height: 1.0,
                  ),
                ),
                const SizedBox(height: 32),
                Expanded(
                  child: ListView.builder(
                    itemCount: sorted.length,
                    itemBuilder: (_, i) =>
                        _LeaderboardRow(team: sorted[i], rank: i + 1),
                  ),
                ),
                const SizedBox(height: 24),
                _FinishButton(
                  onTap: () => Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(
                      builder: (_) => const ModeSelectionScreen(),
                    ),
                    (_) => false,
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

// ─── Leaderboard row ──────────────────────────────────────────────────────────

class _LeaderboardRow extends StatelessWidget {
  final TeamState team;
  final int rank;

  const _LeaderboardRow({required this.team, required this.rank});

  @override
  Widget build(BuildContext context) {
    final isFirst = rank == 1;
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
        decoration: BoxDecoration(
          color: isFirst ? const Color(0xFF863C15) : const Color(0xFFFFF1E4),
          borderRadius: BorderRadius.circular(18),
          boxShadow: isFirst
              ? [
                  BoxShadow(
                    color: const Color(0xFF863C15).withValues(alpha: 0.3),
                    blurRadius: 16,
                    offset: const Offset(0, 4),
                  )
                ]
              : null,
        ),
        child: Row(
          children: [
            // Rank
            SizedBox(
              width: 40,
              child: Text(
                '$rank',
                style: TextStyle(
                  color: isFirst ? Colors.white : const Color(0xFF9C532C),
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const SizedBox(width: 12),
            // Trophy for 1st
            if (isFirst) ...[
              const Icon(Icons.emoji_events, color: Colors.amber, size: 28),
              const SizedBox(width: 12),
            ],
            // Name
            Expanded(
              child: Text(
                team.name,
                style: TextStyle(
                  color: isFirst ? Colors.white : const Color(0xFF3A1800),
                  fontSize: 22,
                  fontWeight: FontWeight.w600,
                  letterSpacing: -0.4,
                ),
              ),
            ),
            // Score
            Text(
              '${team.score}',
              style: TextStyle(
                color: isFirst ? Colors.white : const Color(0xFF863C15),
                fontSize: 26,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.5,
              ),
            ),
            Text(
              ' очков',
              style: TextStyle(
                color: isFirst
                    ? Colors.white.withValues(alpha: 0.8)
                    : const Color(0xFF9C532C),
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FinishButton extends StatelessWidget {
  final VoidCallback onTap;

  const _FinishButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 18),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFA35A33), Color(0xFF863C15)],
          ),
          borderRadius: BorderRadius.circular(50),
        ),
        child: const Center(
          child: Text(
            'Завершить',
            style: TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.w600,
              letterSpacing: -0.4,
              height: 1.0,
            ),
          ),
        ),
      ),
    );
  }
}
