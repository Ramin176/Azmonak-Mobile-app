// فایل: models/subject.dart

import 'package:hive/hive.dart';

part 'subject.g.dart';

@HiveType(typeId: 9)
class Subject extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String name;

  @HiveField(2)
  final String? parent;

  @HiveField(3)
  final double price;

  // فیلد children را برمی‌گردانیم و به Hive معرفی‌اش می‌کنیم
  @HiveField(4)
  List<Subject> children; 
  @HiveField(5)
  final int questionCount;
  Subject({
    required this.id,
    required this.name,
    this.parent,
    required this.price,
    this.children = const [],
     required this.questionCount,
  });

  factory Subject.fromJson(Map<String, dynamic> json) {
    var childrenFromJson = json['children'] as List<dynamic>?;
    List<Subject> childrenList = [];
    if (childrenFromJson != null) {
      childrenList = childrenFromJson
          .map((childJson) => Subject.fromJson(childJson as Map<String, dynamic>))
          .toList();
    }

    return Subject(
      id: json['_id']?.toString() ?? '', 
      name: json['name']?.toString() ?? '',
      parent: json['parent']?.toString(),
      price: (json['price'] as num?)?.toDouble() ?? 0.0,
      children: childrenList,
       questionCount: json['questionCount'] as int? ?? 0,
    );
  }
}