import 'package:hive/hive.dart';

import 'plan.dart';
part 'settings.g.dart';

@HiveType(typeId: 8) // یک ID جدید
class AppSettings extends HiveObject {
  @HiveField(0)
  String paymentInstructions;
  @HiveField(1)
  String telegramLink;
  @HiveField(2)
  String accountNumber;
  @HiveField(3)
  List<Plan> subscriptionPlans;

  AppSettings({
    required this.paymentInstructions,
    required this.telegramLink,
    required this.accountNumber,
    required this.subscriptionPlans,
  });

  factory AppSettings.fromJson(Map<String, dynamic> json) {
    return AppSettings(
      paymentInstructions: json['paymentInstructions'] ?? '',
      telegramLink: json['telegramLink'] ?? '',
      accountNumber: json['accountNumber'] ?? '',
      subscriptionPlans: (json['subscriptionPlans'] as List? ?? [])
          .map((p) => Plan.fromJson(p as Map<String, dynamic>))
          .toList(),
    );
  }
}