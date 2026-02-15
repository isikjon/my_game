import '../models/game_model.dart';
import '../models/team_model.dart';
import '../models/question_model.dart';
import 'api_service.dart';

class GameService {
  final ApiService _apiService;

  GameService(this._apiService);

  Future<List<GameModel>> getGames() async {
    final response = await _apiService.get('/games');
    return (response.data as List<dynamic>)
        .map((g) => GameModel.fromJson(g as Map<String, dynamic>))
        .toList();
  }

  Future<GameModel> getGame(String gameId) async {
    final response = await _apiService.get('/games/$gameId');
    return GameModel.fromJson(response.data as Map<String, dynamic>);
  }

  Future<GameModel> createGame(String name, List<TeamModel> teams) async {
    final response = await _apiService.post(
      '/games',
      data: {
        'name': name,
        'teams': teams.map((t) => t.toJson()).toList(),
      },
    );
    return GameModel.fromJson(response.data as Map<String, dynamic>);
  }

  Future<GameModel> updateGame(GameModel game) async {
    final response = await _apiService.put(
      '/games/${game.id}',
      data: game.toJson(),
    );
    return GameModel.fromJson(response.data as Map<String, dynamic>);
  }

  Future<void> deleteGame(String gameId) async {
    await _apiService.delete('/games/$gameId');
  }

  Future<void> startGame(String gameId) async {
    await _apiService.post('/games/$gameId/start');
  }

  Future<void> pauseGame(String gameId) async {
    await _apiService.post('/games/$gameId/pause');
  }

  Future<void> answerQuestion(
    String gameId,
    String questionId,
    String teamId,
    bool isCorrect,
  ) async {
    await _apiService.post(
      '/games/$gameId/questions/$questionId/answer',
      data: {
        'team_id': teamId,
        'is_correct': isCorrect,
      },
    );
  }

  Future<void> updateTeamScore(String gameId, String teamId, int points) async {
    await _apiService.post(
      '/games/$gameId/teams/$teamId/score',
      data: {'points': points},
    );
  }
}

