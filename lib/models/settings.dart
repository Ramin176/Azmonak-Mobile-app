// فایل: models/settings.dart

import 'package:hive/hive.dart';

part 'settings.g.dart';

@HiveType(typeId: 11)
class SubscriptionPlan extends HiveObject {
  @HiveField(0)
  final String duration;
  
  @HiveField(1)
  final String price;
  
  @HiveField(2)
  final String planKey;

  @HiveField(3)
  final String name;

  @HiveField(4)
  final String description;

  @HiveField(5)
  final List<String> subjectIds;

  SubscriptionPlan({
    required this.duration, 
    required this.price, 
    required this.planKey,
    required this.name,
    required this.description,
    required this.subjectIds,
  });

  factory SubscriptionPlan.fromJson(Map<String, dynamic> json) {
    // --- تغییر اساسی اینجاست ---
    List<String> parsedSubjectIds = [];
    if (json['subjectIds'] != null && json['subjectIds'] is List) {
      // لیست آبجکت‌ها را می‌گیریم و از هر آبجکت، فقط مقدار _id را استخراج می‌کنیم
      parsedSubjectIds = (json['subjectIds'] as List)
          .map((item) {
            // هر آیتم یک آبجکت است، مثل: {'_id': '...', 'name': '...'}
            if (item is Map<String, dynamic> && item.containsKey('_id')) {
              return item['_id']?.toString() ?? '';
            }
            return '';
          })
          .where((id) => id.isNotEmpty) // ID های خالی را حذف می‌کنیم
          .toList();
    }
    // -------------------------

    return SubscriptionPlan(
      duration: json['duration']?.toString() ?? '',
      price: json['price']?.toString() ?? '',
      planKey: json['planKey']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      subjectIds: parsedSubjectIds, // <-- از لیست ID های استخراج شده استفاده می‌کنیم
    );
  }
}

@HiveType(typeId: 8)
class AppSettings extends HiveObject {
  // این کلاس نیازی به تغییر ندارد و کاملاً درست است
  @HiveField(0)
  String paymentInstructions;
  
  @HiveField(1)
  String telegramLink;
  
  @HiveField(2)
  String accountNumber;
  
  @HiveField(3)
  List<SubscriptionPlan> subscriptionPlans;

  @HiveField(4)
  String aboutUsText;

  @HiveField(5)
  String deactivatedUserMessage;

  AppSettings({
    required this.paymentInstructions,
    required this.telegramLink,
    required this.accountNumber,
    required this.subscriptionPlans,
    required this.aboutUsText,
    required this.deactivatedUserMessage,
  });

  factory AppSettings.fromJson(Map<String, dynamic> json) {
    return AppSettings(
      paymentInstructions: json['paymentInstructions']?.toString() ?? '',
      telegramLink: json['telegramLink']?.toString() ?? '',
      accountNumber: json['accountNumber']?.toString() ?? '',
      subscriptionPlans: (json['subscriptionPlans'] as List? ?? [])
          .map((p) => SubscriptionPlan.fromJson(p as Map<String, dynamic>))
          .toList(),
      aboutUsText: json['aboutUsText']?.toString() ?? '',
      deactivatedUserMessage: json['deactivatedUserMessage']?.toString() ?? '',
    );
  }
}