import 'package:flutter/foundation.dart';
import 'package:socket_io_client/socket_io_client.dart' as io;

import '../services/server_config.dart';

typedef AckHandler = void Function(Map<String, dynamic> ack);

/// Thin wrapper around socket_io_client.
/// Provides typed emit helpers for every server event and
/// an on/off API for GameNotifier to subscribe.
class SocketService {
  io.Socket? _socket;

  bool get isConnected => _socket?.connected ?? false;

  // ─── Connection lifecycle ─────────────────────────────────────────────────

  void connect() {
    if (_socket != null) return; // already created (may still be connecting)

    _socket = io.io(
      ServerConfig.baseUrl,
      io.OptionBuilder()
          .setTransports(['websocket'])
          .disableAutoConnect()
          .enableReconnection()
          .setReconnectionAttempts(10)
          .setReconnectionDelay(2000)
          .build(),
    );

    _socket!.onConnect((_) => debugPrint('[Socket] connected'));
    _socket!.onDisconnect((r) => debugPrint('[Socket] disconnected: $r'));
    _socket!.onConnectError((e) => debugPrint('[Socket] connect error: $e'));

    _socket!.connect();
  }

  void disconnect() {
    _socket?.disconnect();
    _socket?.dispose();
    _socket = null;
  }

  /// Calls [action] immediately if already connected, otherwise waits for
  /// the 'connect' event (one-shot). Calls [onError] on connect_error.
  void whenConnected(
    void Function() action, {
    void Function(dynamic)? onError,
  }) {
    if (_socket == null) {
      debugPrint('[Socket] whenConnected: socket not created, call connect() first');
      return;
    }
    if (_socket!.connected) {
      action();
      return;
    }
    // One-shot listeners — declared before use so they can reference each other.
    late void Function(dynamic) connectHandler;
    late void Function(dynamic) errorHandler;
    connectHandler = (_) {
      _socket?.off('connect', connectHandler);
      _socket?.off('connect_error', errorHandler);
      action();
    };
    errorHandler = (dynamic err) {
      _socket?.off('connect', connectHandler);
      _socket?.off('connect_error', errorHandler);
      onError?.call(err);
    };
    _socket!.on('connect', connectHandler);
    _socket!.on('connect_error', errorHandler);
  }

  // ─── Event subscription ───────────────────────────────────────────────────

  void on(String event, void Function(dynamic data) handler) {
    _socket?.on(event, handler);
  }

  void off(String event) {
    _socket?.off(event);
  }

  // ─── Raw emit ─────────────────────────────────────────────────────────────

  void _emit(String event, dynamic data, [AckHandler? ack]) {
    if (_socket == null || !_socket!.connected) {
      debugPrint('[Socket] emit "$event" skipped — not connected');
      return;
    }
    if (ack != null) {
      _socket!.emitWithAck(event, data, ack: (response) {
        if (response is Map) {
          ack(Map<String, dynamic>.from(response));
        } else {
          ack({});
        }
      });
    } else {
      _socket!.emit(event, data);
    }
  }

  // ─── Typed host emit helpers ──────────────────────────────────────────────

  /// HOST: Register as game host and receive current game state.
  void hostGame(String code, {AckHandler? ack}) {
    _emit('host-game', code, ack);
  }

  /// PLAYER: Join a game room.
  void joinGame(String code, {AckHandler? ack}) {
    _emit('join-game', code, ack);
  }

  /// HOST: Start the game — triggers `game-started` broadcast.
  void startGame(String code, {AckHandler? ack}) {
    _emit('start-game', code, ack);
  }

  /// HOST: Select a question — triggers `question-selected` + timer broadcast.
  void selectQuestion({
    required String code,
    required int roundIdx,
    required int topicIdx,
    required int scoreIdx,
    AckHandler? ack,
  }) {
    _emit(
      'select-question',
      {'code': code, 'roundIdx': roundIdx, 'topicIdx': topicIdx, 'scoreIdx': scoreIdx},
      ack,
    );
  }

  /// HOST: Reveal the correct answer — triggers `answer-revealed` broadcast.
  void revealAnswer(String code, {AckHandler? ack}) {
    _emit('reveal-answer', code, ack);
  }

  /// HOST: Award score to a team — triggers `score-updated` broadcast.
  void assignScore({
    required String code,
    required int teamId,
    AckHandler? ack,
  }) {
    _emit('assign-score', {'code': code, 'teamId': teamId}, ack);
  }

  /// HOST: Skip question without awarding — triggers `question-skipped` broadcast.
  void skipQuestion(String code, {AckHandler? ack}) {
    _emit('skip-question', code, ack);
  }

  /// HOST: Advance to a new round — triggers `round-changed` broadcast.
  void nextRound({
    required String code,
    required int roundIdx,
    AckHandler? ack,
  }) {
    _emit('next-round', {'code': code, 'roundIdx': roundIdx}, ack);
  }

  /// HOST: End the game — triggers `game-ended` broadcast.
  void endGame(String code, {AckHandler? ack}) {
    _emit('end-game', code, ack);
  }

  /// ANY: Request full current state (used for reconnection).
  void getState(String code, {AckHandler? ack}) {
    _emit('get-state', code, ack);
  }
}
