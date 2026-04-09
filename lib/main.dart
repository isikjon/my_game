import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'models/game_state.dart';
import 'screens/game_setup_screen.dart';
import 'screens/host_lobby_screen.dart';
import 'screens/host_setup_screen.dart';
import 'screens/live_game_screen.dart';
import 'screens/mode_selection_screen.dart';
import 'screens/player_join_screen.dart';
import 'screens/team_count_screen.dart';
import 'services/game_api_service.dart';
import 'services/session_service.dart';
import 'state/providers.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  runApp(const ProviderScope(child: ViktorinaApp()));
}

class ViktorinaApp extends StatelessWidget {
  const ViktorinaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Викторина',
        theme: ThemeData(
          fontFamily: '.SF Pro Display',
          fontFamilyFallback: const [
            'SF Pro Display',
            'SF Pro',
            '-apple-system',
            'Helvetica Neue',
            'Roboto',
            'sans-serif',
          ],
        ),
        home: const _AppHome(),
      ),
    );
  }
}

/// Checks for a saved session on startup and restores it if possible.
class _AppHome extends ConsumerStatefulWidget {
  const _AppHome();

  @override
  ConsumerState<_AppHome> createState() => _AppHomeState();
}

class _AppHomeState extends ConsumerState<_AppHome> {
  bool _checking = true;

  @override
  void initState() {
    super.initState();
    _tryRestore();
  }

  Future<void> _tryRestore() async {
    final session = await SessionService.load();
    if (session == null) {
      if (mounted) setState(() => _checking = false);
      return;
    }

    debugPrint('[SessionRestore] screen=${session.screen}, code=${session.gameCode}');

    try {
      switch (session.screen) {
        case 'host_setup':
          await _restoreHostSetup();
          break;
        case 'game_setup':
          await _restoreGameSetup(session);
          break;
        case 'team_count':
          await _restoreTeamCount(session);
          break;
        case 'host_lobby':
          await _restoreHostLobby(session);
          break;
        case 'live':
          await _restoreLiveGame(session);
          break;
        case 'player_join':
          await _restorePlayerJoin();
          break;
        default:
          await SessionService.clear();
          if (mounted) setState(() => _checking = false);
      }
    } catch (e) {
      debugPrint('[SessionRestore] Error: $e');
      await SessionService.clear();
      if (mounted) setState(() => _checking = false);
    }
  }

  // ─── Simple screens ────────────────────────────────────────────────────────

  Future<void> _restoreHostSetup() async {
    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const HostSetupScreen()),
    );
  }

  Future<void> _restorePlayerJoin() async {
    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const PlayerJoinScreen()),
    );
  }

  // ─── GameSetupScreen ───────────────────────────────────────────────────────

  Future<void> _restoreGameSetup(GameSession session) async {
    if (session.gameCode != null) {
      final api = GameApiService();
      try {
        final result = await api.fetchGame(session.gameCode!);
        if (!mounted) return;
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => GameSetupScreen(
              gameName: result.game.name,
              gameCode: session.gameCode,
            ),
          ),
        );
        return;
      } catch (_) {
        // Game might have been deleted — fall through
      } finally {
        api.close();
      }
    }

    // New game without code or game not found — show GameSetupScreen with name only
    if (session.gameName != null && session.gameName!.isNotEmpty) {
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => GameSetupScreen(gameName: session.gameName!),
        ),
      );
      return;
    }

    // Fallback
    await SessionService.clear();
    if (mounted) setState(() => _checking = false);
  }

  // ─── TeamCountScreen ───────────────────────────────────────────────────────

  Future<void> _restoreTeamCount(GameSession session) async {
    final code = session.gameCode;
    if (code == null) {
      await SessionService.clear();
      if (mounted) setState(() => _checking = false);
      return;
    }

    final api = GameApiService();
    try {
      final result = await api.fetchGame(code);
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => TeamCountScreen(game: result.game, gameCode: code),
        ),
      );
    } catch (_) {
      await SessionService.clear();
      if (mounted) setState(() => _checking = false);
    } finally {
      api.close();
    }
  }

  // ─── HostLobbyScreen ──────────────────────────────────────────────────────

  Future<void> _restoreHostLobby(GameSession session) async {
    final code = session.gameCode;
    if (code == null) {
      await SessionService.clear();
      if (mounted) setState(() => _checking = false);
      return;
    }

    final api = GameApiService();
    try {
      final result = await api.fetchGame(code);
      if (!mounted) return;

      final teamNames = result.teams.map((t) => t.name).toList();
      final rounds = result.rounds;

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => HostLobbyScreen(
            gameCode: code,
            teamNames: teamNames,
            rounds: rounds,
          ),
        ),
      );
    } catch (_) {
      await SessionService.clear();
      if (mounted) setState(() => _checking = false);
    } finally {
      api.close();
    }
  }

  // ─── LiveGameScreen ────────────────────────────────────────────────────────

  Future<void> _restoreLiveGame(GameSession session) async {
    final code = session.gameCode;
    if (code == null) {
      await SessionService.clear();
      if (mounted) setState(() => _checking = false);
      return;
    }

    final api = GameApiService();
    try {
      final result = await api.fetchGame(code);

      if (result.status == 'finished' || result.status == 'setup') {
        debugPrint('[SessionRestore] Game status=${result.status}, clearing');
        await SessionService.clear();
        if (mounted) setState(() => _checking = false);
        return;
      }

      if (!mounted) return;

      final socket = ref.read(socketServiceProvider);
      socket.connect();

      final completer = Completer<Map<String, dynamic>?>();

      socket.whenConnected(
        () {
          void ackHandler(Map<String, dynamic> ack) {
            if (ack['error'] != null) {
              completer.complete(null);
            } else {
              completer.complete(ack);
            }
          }

          if (session.isHost) {
            socket.hostGame(code, ack: ackHandler);
          } else {
            socket.joinGame(code, ack: ackHandler);
          }
        },
        onError: (_) {
          if (!completer.isCompleted) completer.complete(null);
        },
      );

      final ack = await completer.future.timeout(
        const Duration(seconds: 10),
        onTimeout: () => null,
      );

      if (ack == null || !mounted) {
        await SessionService.clear();
        if (mounted) setState(() => _checking = false);
        return;
      }

      GamePhase phase = GamePhase.board;
      ActiveQuestion? activeQuestion;
      String? revealedAnswer;
      int timerSeconds = 0;
      bool catRevealed = false;

      final liveState = ack['liveState'] as Map?;
      if (liveState != null) {
        final serverPhase = liveState['phase'] as String?;
        if (serverPhase == 'question' || serverPhase == 'result') {
          final aq = liveState['activeQuestion'] as Map?;
          if (aq != null) {
            activeQuestion = ActiveQuestion(
              questionId: (aq['questionId'] as num).toInt(),
              questionText: aq['questionText'] as String,
              score: (aq['score'] as num).toInt(),
              type: aq['type'] as String? ?? 'normal',
              roundIdx: (aq['roundIdx'] as num).toInt(),
              topicIdx: (aq['topicIdx'] as num).toInt(),
              scoreIdx: (aq['scoreIdx'] as num).toInt(),
            );
            timerSeconds = (aq['timerSeconds'] as num?)?.toInt() ?? 0;
          }
          if (serverPhase == 'question') {
            phase = GamePhase.question;
          } else {
            phase = GamePhase.result;
            revealedAnswer = liveState['revealedAnswer'] as String?;
          }
        }
        catRevealed = liveState['catRevealed'] == true;
      }

      final initialState = GameState(
        phase: phase,
        gameCode: code,
        role: session.isHost ? PlayerRole.host : PlayerRole.player,
        teams: result.teams,
        rounds: result.rounds,
        currentRound: result.currentRound,
        activeQuestion: activeQuestion,
        timerSeconds: timerSeconds,
        revealedAnswer: revealedAnswer,
        usedQuestionIds: result.usedQuestionIds,
        catRevealed: catRevealed,
      );

      if (!mounted) return;

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => ProviderScope(
            overrides: [
              createGameOverride(socket: socket, initialState: initialState),
            ],
            child: LiveGameScreen(gameCode: code),
          ),
        ),
      );
    } catch (e) {
      debugPrint('[SessionRestore] LiveGame error: $e');
      await SessionService.clear();
      if (mounted) setState(() => _checking = false);
    } finally {
      api.close();
    }
  }

  // ─── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    if (_checking) {
      return Scaffold(
        body: Container(
          decoration: const BoxDecoration(
            image: DecorationImage(
              image: AssetImage('assets/images/bg.png'),
              fit: BoxFit.cover,
            ),
          ),
          child: const Center(
            child: CircularProgressIndicator(color: Color(0xFF863C15)),
          ),
        ),
      );
    }
    return const ModeSelectionScreen();
  }
}
