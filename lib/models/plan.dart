// lib/models/plan.dart
import 'package:hive/hive.dart';
part 'plan.g.dart';

@HiveType(typeId: 7)
class Plan {
  @HiveField(0)
  final String duration; // e.g., '۱ هفته' (برای نمایش)
  
  @HiveField(1)
  final String price; // e.g., '۱۰۰ افغانی' (برای نمایش)
  
  @HiveField(2)
  final int questionLimit; // این دیگر استفاده نمی‌شود، اما برای سازگاری نگه می‌داریم

  // --- فیلد جدید و کلیدی ---
  @HiveField(3)
  final String planKey; // e.g., 'weekly' (برای ارسال به API)

  Plan({
    required this.duration, 
    required this.price, 
    required this.questionLimit,
    required this.planKey,
  });

  factory Plan.fromJson(Map<String, dynamic> json) {
    return Plan(
      duration: json['duration'] ?? '', 
      price: json['price'] ?? '', 
      questionLimit: json['questionLimit'] as int? ?? 0,
      planKey: json['planKey'] ?? '', // <-- خواندن فیلد جدید از JSON
    );
  }
}