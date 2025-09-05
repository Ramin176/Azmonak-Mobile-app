
import 'package:hive_flutter/hive_flutter.dart';
part 'user.g.dart';
@HiveType(typeId: 4) // ID منحصر به فرد

class AppUser {
  @HiveField(0)
  final String id;
  
  @HiveField(1)
  final String name;
  
  @HiveField(2)
  final String email;
  
  @HiveField(3)
  final String subscriptionType;
  
  @HiveField(4)
  final DateTime? subscriptionExpiresAt;

  AppUser({
    required this.id,
    required this.name,
    required this.email,
    required this.subscriptionType,
    this.subscriptionExpiresAt,
  });

  // یک getter هوشمند برای چک کردن وضعیت Premium
    bool get isPremium {
    // اگر نوع اشتراک "رایگان" باشد، قطعا Premium نیست
    if (subscriptionType == 'free') return false;
    
    // اگر تاریخ انقضا وجود نداشته باشد، Premium نیست
    if (subscriptionExpiresAt == null) return false;
    
    // اگر تاریخ انقضا "بعد از" لحظه حال باشد، کاربر Premium است
    return subscriptionExpiresAt!.isAfter(DateTime.now());
  }

  factory AppUser.fromJson(Map<String, dynamic> json) {
    return AppUser(
      id: json['_id'],
      name: json['name'],
      email: json['email'],
      subscriptionType: json['subscriptionType'] ?? 'free',
      subscriptionExpiresAt: json['subscriptionExpiresAt'] != null
          ? DateTime.parse(json['subscriptionExpiresAt'])
          : null,
    );
  }
}