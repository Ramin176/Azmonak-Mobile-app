import 'package:hive/hive.dart';

part 'category.g.dart'; // این فایل توسط build_runner ساخته می‌شود

@HiveType(typeId: 0) // ID منحصر به فرد برای Hive
class Category extends HiveObject{
  @HiveField(0)
  final String id;
  
  @HiveField(1)
  final String name;

  // سازنده اصلی کلاس
  Category({
    required this.id,
    required this.name,
  });

  // سازنده factory برای ساخت آبجکت از JSON (پاسخ API)
  factory Category.fromJson(Map<String, dynamic> json) {
    return Category(
      id: json['_id'],
      name: json['name'],
    );
  }
}