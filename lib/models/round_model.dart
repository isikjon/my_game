import 'topic_model.dart';

class RoundModel {
  final String id;
  final String name;
  final int number;
  final List<TopicModel> topics;
  final bool isCompleted;

  RoundModel({
    required this.id,
    required this.name,
    required this.number,
    required this.topics,
    this.isCompleted = false,
  });

  factory RoundModel.fromJson(Map<String, dynamic> json) {
    return RoundModel(
      id: json['id'] as String,
      name: json['name'] as String,
      number: json['number'] as int,
      topics: (json['topics'] as List<dynamic>)
          .map((t) => TopicModel.fromJson(t as Map<String, dynamic>))
          .toList(),
      isCompleted: json['is_completed'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'number': number,
      'topics': topics.map((t) => t.toJson()).toList(),
      'is_completed': isCompleted,
    };
  }
}

