import 'dart:convert';

import 'package:hive/hive.dart';
part 'question.g.dart';
@HiveType(typeId: 2)
class Question extends HiveObject{
  @HiveField(0)
  final String id;
  @HiveField(1)
  final String subjectId;
  @HiveField(2)
  final String text;
  @HiveField(3)
  final String type;
  @HiveField(4)
  final List<Map<String, String>> options; // Hive از این نوع پشتیبانی می‌کند
  @HiveField(5)
  final int correctAnswerIndex;
  @HiveField(6)
  final String explanation;
  @HiveField(7)
  final int score;
   @HiveField(8)
  final String? imageUrl;
  Question( {
    required this.score,
    required this.id,
    required this.subjectId,
    required this.text,
    required this.type,
    required this.options,
    required this.correctAnswerIndex,
    required this.explanation,
     this.imageUrl,
  });

  factory Question.fromJson(Map<String, dynamic> json) {
    return Question(
      // id: json['_id'],
      // subjectId: json['subject'] ?? 'trial_subject',
      // text: json['text'],
      // type: json['type'],
      // options: (json['options'] as List<dynamic>?)
      //     ?.map((opt) => {'text': opt['text'].toString()})
      //     .toList() ?? [],
      //   explanation: json['explanation'] ?? '',
      // correctAnswerIndex: json['correctAnswerIndex'],
      // score: json['score'] ?? 1,
      //  imageUrl: json['imageUrl'],
        id: json['_id'] ?? '', // اگر آیدی null بود، رشته خالی بگذار
    subjectId: json['subject'] ?? 'trial_subject', // <--- اصلاح کلیدی
    text: json['text'] ?? 'متن سوال یافت نشد', // برای اطمینان
    type: json['type'] ?? 'multiple_choice',
    options: (json['options'] as List<dynamic>?)
        ?.map((opt) => {'text': opt['text']?.toString() ?? ''})
        .toList() ?? [],
    explanation: json['explanation'] ?? '',
    correctAnswerIndex: json['correctAnswerIndex'] ?? 0,
    score: json['score'] ?? 1,
    imageUrl: json['imageUrl'], // این چون از قبل nullable است، مشکلی ندارد
    );
  }
  
  Map<String, dynamic> toDbMap() {
    return {
      'id': id,
      'subjectId': subjectId,
      'text': text,
      'type': type,
      'options': json.encode(options), // به صورت رشته JSON
    };
  }

  factory Question.fromDb(Map<String, dynamic> dbData) {
    return Question(
      score: dbData['score'] ?? 0,
      id: dbData['id'],
      subjectId: dbData['subjectId'],
      text: dbData['text'],
      type: dbData['type'],
      options: (json.decode(dbData['options']) as List<dynamic>)
          .map((opt) => {'text': opt['text'].toString()})
          .toList(),
          explanation: dbData['explanation'] ?? '',
      correctAnswerIndex: dbData['correctAnswerIndex'] ?? 0,
    );
  }
}