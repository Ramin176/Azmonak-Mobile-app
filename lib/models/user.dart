
import 'package:azmoonak_app/models/purchased_subject.dart';
import 'package:hive_flutter/hive_flutter.dart';
part 'user.g.dart';
@HiveType(typeId: 4) // ID منحصر به فرد
class AppUser extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String name;

  @HiveField(2)
  final String email;

  @HiveField(3)
  List<PurchasedSubject> purchasedSubjects;

  @HiveField(4)
  String? profileImagePath;

  @HiveField(5)
  final bool isActive;
  
  @HiveField(6)
  final String role;

 @HiveField(7)
  String status; // وضعیت را به صورت رشته ذخیره کنید


  AppUser({
    required this.id,
    required this.name,
    required this.email,
    required this.purchasedSubjects,
    this.profileImagePath,
    required this.isActive,
    required this.role,
     this.status = 'active',
  });

  // Getter هوشمند جدید برای چک کردن وضعیت Premium
  bool get isPremium {
    if (role == 'admin') return true;
    if (purchasedSubjects.isEmpty) return false;
    // اگر حداقل یک اشتراک فعال وجود داشته باشد، کاربر Premium محسوب می‌شود
    return purchasedSubjects.any((sub) => sub.expiresAt.isAfter(DateTime.now()));
  }

  // تابع برای چک کردن دسترسی به یک موضوع خاص
  bool canAccessSubject(String subjectId) {
    if (role == 'admin') return true;
    final now = DateTime.now();
    return purchasedSubjects.any((sub) => sub.subjectId == subjectId && sub.expiresAt.isAfter(now));
  }

  AppUser copyWith({String? name, String? profileImagePath}) {
    return AppUser(
      id: id,
      name: name ?? this.name,
      email: email,
      purchasedSubjects: purchasedSubjects,
      profileImagePath: profileImagePath ?? this.profileImagePath,
      isActive: isActive,
         status: status ?? this.status,
      role: role,
    );
  }

  factory AppUser.fromJson(Map<String, dynamic> json) {
     print("---------- DEBUG AppUser.fromJson ----------");
  print("INPUT JSON: $json");
  print("STATUS FIELD: ${json['status']}");
  print("------------------------------------------");
    return AppUser(
      id: json['_id'],
      name: json['name'],
      email: json['email'],
      purchasedSubjects: (json['purchasedSubjects'] as List<dynamic>? ?? [])
          .map((sub) => PurchasedSubject.fromJson(sub))
          .toList(),
      isActive: json['isActive'] ?? true,
       status: json['status'] ?? 'active',
      role: json['role'] ?? 'user',
    );
  }
}