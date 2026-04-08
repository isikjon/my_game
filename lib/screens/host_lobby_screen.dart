import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/game_state.dart';
import '../state/providers.dart';
import 'live_game_screen.dart';

/// Host arrives here after TeamCountScreen saves teams.
/// Emits host-game → shows code + team list → Start button emits start-game.
class HostLobbyScreen extends ConsumerStatefulWidget {
  final String gameCode;
  final List<String> teamNames;
  final List<LiveRoundState> rounds;

  const HostLobbyScreen({
    super.key,
    required this.gameCode,
    required this.teamNames,
    required this.rounds,
  });

  @override
  ConsumerState<HostLobbyScreen> createState() => _HostLobbyScreenState();
}

class _HostLobbyScreenState extends ConsumerState<HostLobbyScreen> {
  bool _connecting = true;
  bool _starting = false;
  String? _error;
  List<TeamState> _teams = [];
  Set<int> _usedQuestionIds = {};

  @override
  void initState() {
    super.initState();
    _connectAsHost();
  }

  void _connectAsHost() {
    final socket = ref.read(socketServiceProvider);
    socket.connect();

    socket.whenConnected(
      () {
        socket.hostGame(widget.gameCode, ack: (ack) {
          if (!mounted) return;
          if (ack['error'] != null) {
            setState(() {
              _connecting = false;
              _error = ack['error'].toString();
            });
            return;
          }
          final gameData = ack['game'] as Map?;
          final rawTeams = (gameData?['teams'] as List?) ?? [];
          final teams = parseTeamsFromServerJson(rawTeams);

          final usedQids = <int>{};
          final rawRounds = (gameData?['rounds'] as List?) ?? [];
          for (final r in rawRounds) {
            final topics = (r['topics'] as List?) ?? [];
            for (final t in topics) {
              final questions = (t['questions'] as List?) ?? [];
              for (final q in questions) {
                if ((q['is_used'] as num?)?.toInt() == 1) {
                  usedQids.add((q['id'] as num).toInt());
                }
              }
            }
          }

          final displayTeams = teams.isNotEmpty
              ? teams
              : widget.teamNames
                  .asMap()
                  .entries
                  .map((e) => TeamState(id: e.key, name: e.value, score: 0))
                  .toList();
          if (!mounted) return;
          setState(() {
            _connecting = false;
            _teams = displayTeams;
            _usedQuestionIds = usedQids;
          });
        });
      },
      onError: (err) {
        if (!mounted) return;
        setState(() {
          _connecting = false;
          _error = 'Не удалось подключиться к серверу: $err';
        });
      },
    );
  }

  void _startGame() {
    if (_starting) return;
    setState(() => _starting = true);

    final socket = ref.read(socketServiceProvider);

    // Build initial GameState for host
    final initialState = GameState.lobby(
      gameCode: widget.gameCode,
      role: PlayerRole.host,
      teams: _teams,
      rounds: widget.rounds,
    ).copyWith(usedQuestionIds: _usedQuestionIds);

    debugPrint('[DEBUG] HostLobbyScreen: Starting game with ${initialState.teams.length} teams');

    // Emit start-game BEFORE navigation to ensure server is ready
    socket.startGame(widget.gameCode);

    // Navigate to LiveGameScreen with overridden providers
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => ProviderScope(
          overrides: [
            createGameOverride(socket: socket, initialState: initialState),
          ],
          child: LiveGameScreen(gameCode: widget.gameCode),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
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
          child: _connecting
              ? _buildLoading('Подключение к серверу…')
              : _error != null
                  ? _buildError()
                  : _buildLobby(),
        ),
      ),
    );
  }

  Widget _buildLoading(String label) => Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(color: Color(0xFF863C15)),
            const SizedBox(height: 20),
            Text(
              label,
              style: const TextStyle(
                color: Color(0xFF3A1800),
                fontSize: 18,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      );

  Widget _buildError() => Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                _error!,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Color(0xFF863C15), fontSize: 18),
              ),
              const SizedBox(height: 24),
              _BrownButton(
                label: 'Попробовать снова',
                onTap: () => setState(() {
                  _connecting = true;
                  _error = null;
                  _connectAsHost();
                }),
              ),
            ],
          ),
        ),
      );

  Widget _buildLobby() => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 28),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Code badge
            Row(
              children: [
                const Text(
                  'Код игры',
                  style: TextStyle(
                    color: Color(0xFF9C532C),
                    fontSize: 18,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(width: 16),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 24, vertical: 10),
                  decoration: BoxDecoration(
                    color: const Color(0xFF863C15),
                    borderRadius: BorderRadius.circular(50),
                  ),
                  child: Text(
                    widget.gameCode,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 6,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),
            const Text(
              'Команды',
              style: TextStyle(
                color: Color(0xFF3A1800),
                fontSize: 22,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.4,
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: ListView.separated(
                itemCount: _teams.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (_, i) => _TeamTile(team: _teams[i]),
              ),
            ),
            const SizedBox(height: 24),
            _BrownButton(
              label: _starting ? 'Запуск…' : 'Начать игру',
              onTap: _starting ? null : _startGame,
            ),
          ],
        ),
      );
}

// ─── Reusable widgets ─────────────────────────────────────────────────────────

class _TeamTile extends StatelessWidget {
  final TeamState team;

  const _TeamTile({required this.team});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF1E4),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          const Icon(Icons.groups, color: Color(0xFF9C532C), size: 24),
          const SizedBox(width: 14),
          Text(
            team.name,
            style: const TextStyle(
              color: Color(0xFF3A1800),
              fontSize: 20,
              fontWeight: FontWeight.w600,
              letterSpacing: -0.4,
            ),
          ),
        ],
      ),
    );
  }
}

class _BrownButton extends StatelessWidget {
  final String label;
  final VoidCallback? onTap;

  const _BrownButton({required this.label, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 18),
        decoration: BoxDecoration(
          gradient: onTap != null
              ? const LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0xFFA35A33), Color(0xFF863C15)],
                )
              : const LinearGradient(
                  colors: [Color(0xFFBFBFBF), Color(0xFFAAAAAA)]),
          borderRadius: BorderRadius.circular(50),
        ),
        child: Center(
          child: Text(
            label,
            style: const TextStyle(
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
