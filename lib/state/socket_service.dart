import 'dart:async';
import 'dart:io' as dartio;
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

  /// Stream that emits true/false when connection state changes.
  final _connectionController = StreamController<bool>.broadcast();
  Stream<bool> get connectionStream => _connectionController.stream;

  // ─── Connection lifecycle ─────────────────────────────────────────────────

  void connect() {
    if (_socket != null) {
      if (!_socket!.connected) {
        debugPrint('[Socket] reconnecting existing socket...');
        _socket!.connect();
      }
      return;
    }

    debugPrint('[Socket] connecting to ${ServerConfig.baseUrl}');

    // Manual HTTP diagnostic to socket.io endpoint
    _testSocketEndpoint();

    _socket = io.io(
      ServerConfig.baseUrl,
      io.OptionBuilder()
          .setTransports(['websocket', 'polling'])
          .disableAutoConnect()
          .enableReconnection()
          .setReconnectionDelay(1000)
          .setReconnectionDelayMax(10000)
          .setReconnectionAttempts(999999)
          .build(),
    );

    _socket!.onConnect((_) {
      debugPrint('[Socket] CONNECTED (id: ${_socket!.id})');
      _connectionController.add(true);
    });
    _socket!.onDisconnect((r) {
      debugPrint('[Socket] DISCONNECTED (reason: $r)');
      _connectionController.add(false);
    });
    _socket!.onReconnect((_) {
      debugPrint('[Socket] RECONNECTED');
      _connectionController.add(true);
    });
    _socket!.onReconnectAttempt((attempt) {
      debugPrint('[Socket] reconnect attempt #$attempt');
    });
    _socket!.onConnectError((e) {
      debugPrint('[Socket] CONNECT ERROR ($e)');
      debugPrint('[Socket] CONNECT ERROR type: ${e.runtimeType}');
    });
    _socket!.onError((e) {
      debugPrint('[Socket] ERROR ($e)');
      debugPrint('[Socket] ERROR type: ${e.runtimeType}');
    });

    _socket!.connect();
  }

  Future<void> _testSocketEndpoint() async {
    try {
      final url = '${ServerConfig.baseUrl}/socket.io/?EIO=4&transport=polling';
      debugPrint('[Socket-DIAG] Testing: $url');
      final client = dartio.HttpClient();
      client.connectionTimeout = const Duration(seconds: 10);
      final request = await client.getUrl(Uri.parse(url));
      final response = await request.close();
      final body = await response.transform(const dartio.SystemEncoding().decoder).join();
      debugPrint('[Socket-DIAG] HTTP ${response.statusCode}: ${body.substring(0, body.length.clamp(0, 200))}');
      client.close();
    } catch (e) {
      debugPrint('[Socket-DIAG] FAILED: $e');
    }

    try {
      final wsUrl = '${ServerConfig.baseUrl.replaceFirst('https', 'wss')}/socket.io/?EIO=4&transport=websocket';
      debugPrint('[Socket-DIAG] Testing WSS: $wsUrl');
      final ws = await dartio.WebSocket.connect(wsUrl).timeout(const Duration(seconds: 10));
      debugPrint('[Socket-DIAG] WSS connected OK, readyState=${ws.readyState}');
      await ws.close();
    } catch (e) {
      debugPrint('[Socket-DIAG] WSS FAILED: $e');
    }
  }

  void disconnect() {
    _socket?.disconnect();
    _socket?.dispose();
    _socket = null;
  }

  void dispose() {
    disconnect();
    _connectionController.close();
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
      debugPrint('[Socket] emit "$event" skipped — not connected, will retry on reconnect');
      // Try to reconnect
      if (_socket != null && !_socket!.connected) {
        _socket!.connect();
      }
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

  void hostGame(String code, {AckHandler? ack}) {
    _emit('host-game', code, ack);
  }

  void joinGame(String code, {AckHandler? ack}) {
    _emit('join-game', code, ack);
  }

  void startGame(String code, {AckHandler? ack}) {
    _emit('start-game', code, ack);
  }

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

  void revealAnswer(String code, {AckHandler? ack}) {
    _emit('reveal-answer', code, ack);
  }

  void revealCatQuestion(String code, {AckHandler? ack}) {
    _emit('reveal-cat-question', code, ack);
  }

  void penalizeTeam({
    required String code,
    required int teamId,
    AckHandler? ack,
  }) {
    _emit('penalize-team', {'code': code, 'teamId': teamId}, ack);
  }

  void assignScore({
    required String code,
    required int teamId,
    AckHandler? ack,
  }) {
    _emit('assign-score', {'code': code, 'teamId': teamId}, ack);
  }

  void skipQuestion(String code, {AckHandler? ack}) {
    _emit('skip-question', code, ack);
  }

  void nextRound({
    required String code,
    required int roundIdx,
    AckHandler? ack,
  }) {
    _emit('next-round', {'code': code, 'roundIdx': roundIdx}, ack);
  }

  void endGame(String code, {AckHandler? ack}) {
    _emit('end-game', code, ack);
  }

  void getState(String code, {AckHandler? ack}) {
    _emit('get-state', code, ack);
  }
}
