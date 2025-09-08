import 'package:hive/hive.dart';

part 'course.g.dart'; // این فایل توسط build_runner ساخته می‌شود

@HiveType(typeId: 1) // ID منحصر به فرد برای Hive
class Course extends HiveObject{
  @HiveField(0)
  final String id;
  
  @HiveField(1)
  final String name;
  
  @HiveField(2)
  final String categoryId;

  // سازنده اصلی کلاس
  Course({
    required this.id,
    required this.name,
    required this.categoryId,
  });

  // سازنده factory برای ساخت آبجکت از JSON (پاسخ API)
  factory Course.fromJson(Map<String, dynamic> json) {
    return Course(
      id: json['_id'],
      name: json['name'],
      categoryId: json['category'],
    );
  }

  // سازنده factory برای ساخت آبجکت از داده‌های دیتابیس محلی (sqflite)
  // اگر کاملاً به Hive مهاجرت کرده‌اید، این دیگر لازم نیست، اما نگه داشتن آن ضرری ندارد
  factory Course.fromDb(Map<String, dynamic> dbData) {
    return Course(
      id: dbData['id'],
      name: dbData['name'],
      categoryId: dbData['categoryId'],
    );
  }
}