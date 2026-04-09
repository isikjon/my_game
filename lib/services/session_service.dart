import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

/// Persists the active screen so the app can recover after page refresh.
class SessionService {
  static const _key = 'active_session';

  static Future<void> save(GameSession session) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, jsonEncode(session.toJson()));
  }

  static Future<GameSession?> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null) return null;
    try {
      return GameSession.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } catch (_) {
      await prefs.remove(_key);
      return null;
    }
  }

  static Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
  }
}

class GameSession {
  /// Screen identifier:
  /// 'host_setup', 'game_setup', 'team_count', 'host_lobby',
  /// 'live', 'player_join'
  final String screen;
  final String? gameCode;
  final String? role; // 'host' or 'player' (for 'live')
  final String? gameName; // for game_setup without a saved game

  const GameSession({
    required this.screen,
    this.gameCode,
    this.role,
    this.gameName,
  });

  bool get isHost => role == 'host';

  Map<String, dynamic> toJson() => {
        'screen': screen,
        if (gameCode != null) 'gameCode': gameCode,
        if (role != null) 'role': role,
        if (gameName != null) 'gameName': gameName,
      };

  factory GameSession.fromJson(Map<String, dynamic> j) => GameSession(
        screen: j['screen'] as String,
        gameCode: j['gameCode'] as String?,
        role: j['role'] as String?,
        gameName: j['gameName'] as String?,
      );
}
