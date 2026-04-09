import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'server_config.dart';

class GameTemplate {
  final int? id;
  final String name;
  final DateTime createdAt;
  final List<RoundTemplate> rounds;

  const GameTemplate({
    this.id,
    required this.name,
    required this.createdAt,
    required this.rounds,
  });

  Map<String, dynamic> toDataJson() => {
        'rounds': rounds.map((r) => r.toJson()).toList(),
      };

  factory GameTemplate.fromListJson(Map<String, dynamic> j) => GameTemplate(
        id: (j['id'] as num).toInt(),
        name: j['name'] as String,
        createdAt: DateTime.tryParse(j['created_at'] as String? ?? '') ??
            DateTime.now(),
        rounds: const [],
      );

  factory GameTemplate.fromFullJson(Map<String, dynamic> j) {
    final data = j['data'] as Map<String, dynamic>? ?? {};
    final rawRounds = (data['rounds'] as List?) ?? [];
    return GameTemplate(
      id: (j['id'] as num).toInt(),
      name: j['name'] as String,
      createdAt: DateTime.tryParse(j['created_at'] as String? ?? '') ??
          DateTime.now(),
      rounds: rawRounds
          .map((r) => RoundTemplate.fromJson(r as Map<String, dynamic>))
          .toList(),
    );
  }
}

class RoundTemplate {
  final String name;
  final int timeSeconds;
  final List<TopicTemplate> topics;

  const RoundTemplate({
    required this.name,
    required this.timeSeconds,
    required this.topics,
  });

  Map<String, dynamic> toJson() => {
        'name': name,
        'timeSeconds': timeSeconds,
        'topics': topics.map((t) => t.toJson()).toList(),
      };

  factory RoundTemplate.fromJson(Map<String, dynamic> j) => RoundTemplate(
        name: j['name'] as String,
        timeSeconds: (j['timeSeconds'] as num?)?.toInt() ?? 60,
        topics: ((j['topics'] as List?) ?? [])
            .map((t) => TopicTemplate.fromJson(t as Map<String, dynamic>))
            .toList(),
      );
}

class TopicTemplate {
  final String name;
  final List<QuestionTemplate?> questions;

  const TopicTemplate({required this.name, required this.questions});

  Map<String, dynamic> toJson() => {
        'name': name,
        'questions': questions.map((q) => q?.toJson()).toList(),
      };

  factory TopicTemplate.fromJson(Map<String, dynamic> j) => TopicTemplate(
        name: j['name'] as String,
        questions: ((j['questions'] as List?) ?? [])
            .map((q) => q == null
                ? null
                : QuestionTemplate.fromJson(q as Map<String, dynamic>))
            .toList(),
      );
}

class QuestionTemplate {
  final String type;
  final String question;
  final String answer;

  const QuestionTemplate({
    required this.type,
    required this.question,
    required this.answer,
  });

  Map<String, dynamic> toJson() => {
        'type': type,
        'question': question,
        'answer': answer,
      };

  factory QuestionTemplate.fromJson(Map<String, dynamic> j) =>
      QuestionTemplate(
        type: j['type'] as String? ?? 'normal',
        question: j['question'] as String? ?? '',
        answer: j['answer'] as String? ?? '',
      );
}

class TemplateService {
  static final _client = http.Client();

  static Future<List<GameTemplate>> loadAll() async {
    try {
      final resp = await _client
          .get(ServerConfig.uri('/api/templates'))
          .timeout(const Duration(seconds: 10));
      if (resp.statusCode != 200) return [];
      final list = jsonDecode(resp.body) as List;
      return list
          .map((j) => GameTemplate.fromListJson(j as Map<String, dynamic>))
          .toList();
    } catch (e) {
      debugPrint('[TemplateService] loadAll error: $e');
      return [];
    }
  }

  static Future<GameTemplate?> loadById(int id) async {
    try {
      final resp = await _client
          .get(ServerConfig.uri('/api/templates/$id'))
          .timeout(const Duration(seconds: 10));
      if (resp.statusCode != 200) return null;
      return GameTemplate.fromFullJson(
          jsonDecode(resp.body) as Map<String, dynamic>);
    } catch (e) {
      debugPrint('[TemplateService] loadById error: $e');
      return null;
    }
  }

  static Future<bool> save(GameTemplate template) async {
    try {
      final resp = await _client.post(
        ServerConfig.uri('/api/templates'),
        headers: {'Content-Type': 'application/json; charset=utf-8'},
        body: jsonEncode({
          'name': template.name,
          'data': template.toDataJson(),
        }),
      );
      return resp.statusCode == 201;
    } catch (e) {
      debugPrint('[TemplateService] save error: $e');
      return false;
    }
  }

  static Future<bool> delete(int id) async {
    try {
      final resp = await _client
          .delete(ServerConfig.uri('/api/templates/$id'))
          .timeout(const Duration(seconds: 10));
      return resp.statusCode == 200;
    } catch (e) {
      debugPrint('[TemplateService] delete error: $e');
      return false;
    }
  }
}
