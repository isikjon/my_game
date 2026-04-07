import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../models/game_model.dart';
import '../models/game_state.dart'
    show parseRoundsFromServerJson, TeamState, LiveRoundState;
import 'server_config.dart';

/// REST API сервера `server/` — создание игры и загрузка полной схемы (раунды, **имена тем**, вопросы).
class GameApiService {
  GameApiService({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;

  static const List<int> scoreOrder = [500, 1000, 1500, 2000, 2500];

  /// POST /api/games — возвращает `code` для дальнейшего PUT setup.
  Future<String> createGame(String name) async {
    final uri = ServerConfig.uri('/api/games');
    final resp = await _client.post(
      uri,
      headers: {'Content-Type': 'application/json; charset=utf-8'},
      body: jsonEncode({'name': name}),
    );
    if (resp.statusCode != 201) {
      throw GameApiException(
        'Создание игры: ${resp.statusCode} ${resp.body}',
      );
    }
    final map = jsonDecode(resp.body) as Map<String, dynamic>;
    final code = map['code']?.toString();
    if (code == null || code.isEmpty) {
      throw GameApiException('Сервер не вернул code');
    }
    return code;
  }

  /// GET /api/games — список всех существующих игр.
  Future<List<Map<String, dynamic>>> listGames() async {
    final uri = ServerConfig.uri('/api/games');
    final resp = await _client.get(uri);
    if (resp.statusCode != 200) {
      throw GameApiException('Ошибка получения списка игр: ${resp.statusCode}');
    }
    return List<Map<String, dynamic>>.from(jsonDecode(resp.body));
  }

  /// GET /api/teams — список всех уникальных команд.
  Future<List<String>> listTeams() async {
    final uri = ServerConfig.uri('/api/teams');
    final resp = await _client.get(uri);
    if (resp.statusCode != 200) {
      throw GameApiException('Ошибка получения списка команд: ${resp.statusCode}');
    }
    final list = jsonDecode(resp.body) as List;
    return list.map((t) => (t as Map)['name'].toString()).toList();
  }

  /// PUT /api/games/:code/setup — то же дерево, что видит SQLite (включая `topics[].name`).
  Future<void> uploadSetup(String code, GameModel game) async {
    final uri = ServerConfig.uri('/api/games/$code/setup');
    final body = jsonEncode({
      'rounds': gameModelToRoundsJson(game),
    });
    final resp = await _client.put(
      uri,
      headers: {'Content-Type': 'application/json; charset=utf-8'},
      body: body,
    );
    if (resp.statusCode != 200) {
      throw GameApiException(
        'Загрузка схемы игры: ${resp.statusCode} ${resp.body}',
      );
    }
  }

  /// DELETE /api/games/:code — удаление игры.
  Future<void> deleteGame(String code) async {
    final uri = ServerConfig.uri('/api/games/$code');
    final resp = await _client.delete(uri);
    if (resp.statusCode != 200) {
      throw GameApiException('Ошибка удаления игры: ${resp.statusCode}');
    }
  }

  /// GET /api/games/:code — загружает игру с сервера и возвращает GameModel + список команд.
  Future<({GameModel game, List<TeamState> teams, List<LiveRoundState> rounds, Set<int> usedQuestionIds})> fetchGame(String code) async {
    final uri = ServerConfig.uri('/api/games/$code');
    final resp =
        await _client.get(uri).timeout(const Duration(seconds: 10));
    if (resp.statusCode == 404) {
      throw GameApiException('Игра с кодом «$code» не найдена');
    }
    if (resp.statusCode != 200) {
      throw GameApiException('Ошибка сервера: ${resp.statusCode}');
    }
    final json = jsonDecode(resp.body) as Map<String, dynamic>;
    return _parseServerGame(json);
  }

  static ({GameModel game, List<TeamState> teams, List<LiveRoundState> rounds, Set<int> usedQuestionIds})
      _parseServerGame(Map<String, dynamic> json) {
    final rawRounds = (json['rounds'] as List?) ?? [];
    final usedQids = <int>{};

    // Build GameModel (for question content)
    final gameRounds = rawRounds.map((r) {
      final rawTopics = (r['topics'] as List?) ?? [];
      final topics = rawTopics.map((t) {
        final rawQuestions = (t['questions'] as List?) ?? [];
        final questions = List<GameQuestionModel?>.filled(5, null);
        for (final q in rawQuestions) {
          final qid = (q['id'] as num).toInt();
          final isUsed = (q['is_used'] as num?)?.toInt() == 1;
          if (isUsed) usedQids.add(qid);

          final score = (q['score'] as num).toInt();
          final idx = scoreOrder.indexOf(score);
          if (idx >= 0) {
            questions[idx] = GameQuestionModel(
              type: _parseQuestionType(q['type'] as String? ?? 'normal'),
              question: q['question_text'] as String? ?? '',
              answer: q['answer_text'] as String? ?? '',
            );
          }
        }
        return GameTopicModel(name: t['name'] as String, questions: questions);
      }).toList();
      return GameRoundModel(
        name: r['name'] as String,
        timeSeconds: (r['time_seconds'] as num?)?.toInt() ?? 60,
        topics: topics,
      );
    }).toList();

    // Build LiveRoundState (for board rendering)
    final liveRounds = parseRoundsFromServerJson(rawRounds);

    final rawTeams = (json['teams'] as List?) ?? [];
    final teams = rawTeams
        .map((t) => TeamState.fromJson(t as Map<String, dynamic>))
        .toList();

    return (
      game: GameModel(name: json['name'] as String? ?? '', rounds: gameRounds),
      teams: teams,
      rounds: liveRounds,
      usedQuestionIds: usedQids,
    );
  }

  static GameQuestionType _parseQuestionType(String type) {
    switch (type) {
      case 'bonus':
        return GameQuestionType.bonus;
      case 'cat':
        return GameQuestionType.cat;
      default:
        return GameQuestionType.normal;
    }
  }

  /// POST /api/games/:code/teams/bulk — сохраняет список команд на сервере.
  Future<void> addTeamsBulk(String code, List<String> names) async {
    final uri = ServerConfig.uri('/api/games/$code/teams/bulk');
    final resp = await _client.post(
      uri,
      headers: {'Content-Type': 'application/json; charset=utf-8'},
      body: jsonEncode({'names': names}),
    );
    if (resp.statusCode != 201) {
      throw GameApiException(
        'Сохранение команд: ${resp.statusCode} ${resp.body}',
      );
    }
  }

  /// Проверка доступности сервера.
  Future<bool> ping() async {
    try {
      final uri = ServerConfig.uri('/health');
      final resp = await _client.get(uri).timeout(const Duration(seconds: 5));
      return resp.statusCode == 200;
    } catch (e, st) {
      debugPrint('[GameApiService] ping failed: $e\n$st');
      return false;
    }
  }

  @visibleForTesting
  static List<Map<String, dynamic>> gameModelToRoundsJson(GameModel game) {
    return game.rounds.map((round) {
      return <String, dynamic>{
        'name': round.name,
        'timeSeconds': round.timeSeconds,
        'topics': round.topics.map((topic) {
          final questions = <Map<String, dynamic>>[];
          for (var i = 0; i < scoreOrder.length; i++) {
            final q = topic.questions[i];
            if (q == null) {
              throw StateError('Вопрос $i темы «${topic.name}» отсутствует');
            }
            questions.add({
              'score': scoreOrder[i],
              'type': _questionTypeApi(q.type),
              'question': q.question,
              'answer': q.answer,
            });
          }
          return <String, dynamic>{
            'name': topic.name,
            'questions': questions,
          };
        }).toList(),
      };
    }).toList();
  }

  static String _questionTypeApi(GameQuestionType t) {
    switch (t) {
      case GameQuestionType.normal:
        return 'normal';
      case GameQuestionType.bonus:
        return 'bonus';
      case GameQuestionType.cat:
        return 'cat';
    }
  }

  void close() {
    _client.close();
  }
}

class GameApiException implements Exception {
  GameApiException(this.message);
  final String message;

  @override
  String toString() => message;
}
