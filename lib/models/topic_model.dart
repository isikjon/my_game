import 'question_model.dart';

class TopicModel {
  final String id;
  final String name;
  final List<QuestionModel> questions;
  final bool isCompleted;

  TopicModel({
    required this.id,
    required this.name,
    required this.questions,
    this.isCompleted = false,
  });

  factory TopicModel.fromJson(Map<String, dynamic> json) {
    return TopicModel(
      id: json['id'] as String,
      name: json['name'] as String,
      questions: (json['questions'] as List<dynamic>)
          .map((q) => QuestionModel.fromJson(q as Map<String, dynamic>))
          .toList(),
      isCompleted: json['is_completed'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'questions': questions.map((q) => q.toJson()).toList(),
      'is_completed': isCompleted,
    };
  }
}

