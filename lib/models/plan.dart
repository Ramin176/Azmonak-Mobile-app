import 'package:hive/hive.dart';

part 'plan.g.dart';

@HiveType(typeId: 7) // یک ID جدید
class Plan {
  @HiveField(0)
  final String duration;
  @HiveField(1)
  final String price;
  @HiveField(2)
  final int questionLimit;

  Plan({required this.duration, required this.price, required this.questionLimit});
  factory Plan.fromJson(Map<String, dynamic> json) {
    return Plan(
      duration: json['duration'] ?? '', 
      price: json['price'] ?? '', 
      // --- اینجا کلید باید دقیقاً با بک‌اند یکی باشد ---
      questionLimit: json['questionLimit'] as int? ?? 0,
    );
  }
}