import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/game_state.dart';
import '../services/game_api_service.dart';
import '../services/session_service.dart';
import '../state/providers.dart';
import '../widgets/pressable.dart';
import 'live_game_screen.dart';


/// Player enters a game code → verifies game via REST → emits join-game via
/// Socket.IO → navigates to LiveGameScreen with Riverpod GameState override.
class PlayerJoinScreen extends ConsumerStatefulWidget {
  const PlayerJoinScreen({super.key});

  @override
  ConsumerState<PlayerJoinScreen> createState() => _PlayerJoinScreenState();
}

class _PlayerJoinScreenState extends ConsumerState<PlayerJoinScreen> {
  final _codeCtrl = TextEditingController();

  bool _loading = false;
  String? _error;

  // Populated after REST fetch
  String? _loadedCode;
  String _gameName = '';
  List<TeamState> _teams = [];
  List<LiveRoundState> _rounds = [];
  Set<int> _usedQuestionIds = {};

  @override
  void dispose() {
    _codeCtrl.dispose();
    super.dispose();
  }

  // ─── Step 1: Verify game via REST ─────────────────────────────────────────

  Future<void> _verifyCode() async {
    final code = _codeCtrl.text.trim();
    if (code.isEmpty) {
      setState(() => _error = 'Введите код игры');
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
      _loadedCode = null;
    });
    final api = GameApiService();
    try {
      final result = await api.fetchGame(code);
      if (!mounted) return;
      if (result.rounds.isEmpty) {
        setState(() {
          _loading = false;
          _error = 'Ведущий ещё не настроил вопросы для этой игры';
        });
        return;
      }
      setState(() {
        _loading = false;
        _loadedCode = code;
        _gameName = result.game.name;
        _teams = result.teams;
        _rounds = result.rounds;
        _usedQuestionIds = result.usedQuestionIds;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = e.toString();
      });
    } finally {
      api.close();
    }
  }

  // ─── Step 2: Connect socket and enter game ────────────────────────────────

  void _enterGame() {
    final code = _loadedCode;
    if (code == null) return;

    setState(() => _loading = true);

    final socket = ref.read(socketServiceProvider);
    socket.connect();

    socket.whenConnected(
      () {
        socket.joinGame(code, ack: (ack) {
          if (!mounted) return;
          if (ack['error'] != null) {
            setState(() {
              _loading = false;
              _error = ack['error'].toString();
            });
            return;
          }

          final gameData = ack['game'] as Map?;
          List<TeamState> teams = _teams;
          List<LiveRoundState> rounds = _rounds;
          Set<int> usedQuestionIds = _usedQuestionIds;
          if (gameData != null) {
            final rawTeams = (gameData['teams'] as List?) ?? [];
            final rawRounds = (gameData['rounds'] as List?) ?? [];
            if (rawTeams.isNotEmpty) teams = parseTeamsFromServerJson(rawTeams);
            if (rawRounds.isNotEmpty) {
              rounds = parseRoundsFromServerJson(rawRounds);
              // Extract used ids from rawRounds in gameData if needed,
              // but parseRoundsFromServerJson doesn't do that.
              // However, the initial state is mostly for lobby.
            }
          }

          final initialState = GameState.lobby(
            gameCode: code,
            role: PlayerRole.player,
            teams: teams,
            rounds: rounds,
          ).copyWith(usedQuestionIds: usedQuestionIds);

          SessionService.save(GameSession(
            gameCode: code,
            role: 'player',
            screen: 'live',
          ));

          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (_) => ProviderScope(
                overrides: [
                  createGameOverride(
                      socket: socket, initialState: initialState),
                ],
                child: LiveGameScreen(gameCode: code),
              ),
            ),
          );
        });
      },
      onError: (err) {
        if (!mounted) return;
        setState(() {
          _loading = false;
          _error = 'Не удалось подключиться к серверу: $err';
        });
      },
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
          child: Column(
            children: [
              // Back button
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: () {
                        SessionService.clear();
                        Navigator.pop(context);
                      },
                      behavior: HitTestBehavior.opaque,
                      child: const Padding(
                        padding: EdgeInsets.all(8),
                        child: Icon(Icons.arrow_back_ios_new,
                            color: Color(0xFF3A1800), size: 24),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Center(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 28),
                    child: _loadedCode == null
                        ? _buildCodeEntry()
                        : _buildGamePreview(),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ─── Step 1 UI: Enter code ────────────────────────────────────────────────

  Widget _buildCodeEntry() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          'Режим игрока',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Color(0xFF3A1800),
            fontSize: 34,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.8,
            height: 1.0,
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'Введите код игры от ведущего',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Color(0xFF9C532C),
            fontSize: 18,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 36),
        Container(
          decoration: BoxDecoration(
            color: const Color(0xFFFFF1E4),
            borderRadius: BorderRadius.circular(20),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
          child: TextField(
            controller: _codeCtrl,
            autofocus: true,
            keyboardType: TextInputType.number,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Color(0xFF3A1800),
              fontSize: 36,
              fontWeight: FontWeight.w700,
              letterSpacing: 8,
            ),
            decoration: const InputDecoration(
              hintText: '0000',
              hintStyle: TextStyle(
                color: Color(0xFFCCB099),
                fontSize: 36,
                fontWeight: FontWeight.w700,
                letterSpacing: 8,
              ),
              border: InputBorder.none,
            ),
            onSubmitted: (_) => _verifyCode(),
          ),
        ),
        if (_error != null) ...[
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF1E4),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Text(
              _error!,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Color(0xFF863C15),
                fontSize: 15,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
        const SizedBox(height: 28),
        _JoinButton(loading: _loading, onTap: _loading ? null : _verifyCode),
      ],
    );
  }

  // ─── Step 2 UI: Preview + enter ───────────────────────────────────────────

  Widget _buildGamePreview() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          _gameName.isNotEmpty ? _gameName : 'Игра',
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: Color(0xFF3A1800),
            fontSize: 30,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.6,
            height: 1.0,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          '${_rounds.length} ${_roundWord(_rounds.length)} · '
          '${_rounds.fold(0, (s, r) => s + r.topics.length)} тем',
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: Color(0xFF9C532C),
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 28),

        if (_teams.isEmpty)
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF1E4),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Text(
              'Ведущий ещё не добавил команды.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Color(0xFF9C532C),
                fontSize: 16,
                fontWeight: FontWeight.w500,
                height: 1.4,
              ),
            ),
          )
        else ...[
          const Padding(
            padding: EdgeInsets.only(left: 4, bottom: 14),
            child: Text(
              'Команды',
              style: TextStyle(
                color: Color(0xFF3A1800),
                fontSize: 20,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.4,
              ),
            ),
          ),
          ..._teams.map(
            (t) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 20, vertical: 14),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF1E4),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.groups,
                        color: Color(0xFF9C532C), size: 24),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Text(
                        t.name,
                        style: const TextStyle(
                          color: Color(0xFF3A1800),
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          letterSpacing: -0.3,
                        ),
                      ),
                    ),
                    Text(
                      '${t.score}',
                      style: const TextStyle(
                        color: Color(0xFF863C15),
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],

        const SizedBox(height: 28),
        _JoinButton(
          label: 'Войти в игру',
          loading: _loading,
          onTap: _loading ? null : _enterGame,
        ),
        const SizedBox(height: 12),
        GestureDetector(
          onTap: () => setState(() {
            _loadedCode = null;
            _error = null;
          }),
          child: const Center(
            child: Text(
              'Ввести другой код',
              style: TextStyle(
                color: Color(0xFF9C532C),
                fontSize: 15,
                fontWeight: FontWeight.w500,
                decoration: TextDecoration.underline,
                decorationColor: Color(0xFF9C532C),
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
      ],
    );
  }

  String _roundWord(int n) {
    if (n % 10 == 1 && n % 100 != 11) return 'раунд';
    if (n % 10 >= 2 && n % 10 <= 4 && !(n % 100 >= 12 && n % 100 <= 14)) {
      return 'раунда';
    }
    return 'раундов';
  }
}

// ─── Button widget ────────────────────────────────────────────────────────────

class _JoinButton extends StatelessWidget {
  final String label;
  final bool loading;
  final VoidCallback? onTap;

  const _JoinButton({
    this.label = 'Войти',
    required this.loading,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Pressable(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 20),
        decoration: BoxDecoration(
          gradient: (onTap != null && !loading)
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
          child: loading
              ? const SizedBox(
                  width: 26,
                  height: 26,
                  child: CircularProgressIndicator(
                      color: Colors.white, strokeWidth: 3),
                )
              : Text(
                  label,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.w600,
                    letterSpacing: -0.5,
                    height: 1.0,
                  ),
                ),
        ),
      ),
    );
  }
}
