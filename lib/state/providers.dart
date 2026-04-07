import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/game_state.dart';
import 'game_notifier.dart';
import 'socket_service.dart';

/// Single shared SocketService instance — connects on first use.
final socketServiceProvider = Provider<SocketService>((ref) {
  final service = SocketService();
  ref.onDispose(service.disconnect);
  return service;
});

/// The live GameState notifier.
/// Must be overridden via ProviderScope.overrides before entering a game.
/// Use [gameProvider.overrideWith] from HostLobbyScreen / PlayerJoinScreen.
final gameProvider =
    StateNotifierProvider<GameNotifier, GameState>((ref) {
  throw UnimplementedError(
    'gameProvider must be overridden with an initial GameState before use.',
  );
});

/// Convenience helper: create a Riverpod override for a specific game session.
/// Call this in HostLobbyScreen and PlayerJoinScreen when entering a live game.
Override createGameOverride({
  required SocketService socket,
  required GameState initialState,
}) {
  return gameProvider.overrideWith(
    (ref) => GameNotifier(socket, initialState),
  );
}
