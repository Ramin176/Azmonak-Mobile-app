import 'package:hive/hive.dart';
import 'package:azmoonak_app/models/subject.dart';

part 'purchased_subject.g.dart';

@HiveType(typeId: 10) // یک ID جدید و استفاده نشده
class PurchasedSubject extends HiveObject {
  @HiveField(0)
  final String subjectId;

  @HiveField(1)
  final DateTime expiresAt;
  
  // این فیلد در Hive ذخیره نمی‌شود
  String subjectName;

  PurchasedSubject({
    required this.subjectId,
    required this.expiresAt,
    this.subjectName = '',
  });

  factory PurchasedSubject.fromJson(Map<String, dynamic> json) {
    return PurchasedSubject(
      subjectId: json['subjectId']['_id'],
      subjectName: json['subjectId']['name'] ?? 'نامشخص',
      expiresAt: DateTime.parse(json['expiresAt']),
    );
  }
}