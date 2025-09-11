// فایل: lib/screens/review_screen.dart

import 'package:azmoonak_app/models/attempt_question.dart';
import 'package:flutter/material.dart';

class ReviewScreen extends StatelessWidget {
  // این صفحه به تمام اطلاعات آزمون اصلی نیاز دارد
  // ما در آینده باید این اطلاعات را به درستی به اینجا پاس بدهیم
  final List<AttemptQuestion> questions;
  final Map<String, int> userAnswers;

  const ReviewScreen({
    super.key, 
    required this.questions, 
    required this.userAnswers
  });
  static const Color primaryTeal = Color(0xFF008080); // Teal اصلی
  // Helper to get responsive sizes based on screen width
  double _getResponsiveSize(BuildContext context, double baseSize) {
    final screenWidth = MediaQuery.of(context).size.width;
    // Adjust this multiplier as needed for different screen sizes
    return baseSize * (screenWidth / 375.0); // Assuming 375 is a common base width (e.g., iPhone 8)
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
         backgroundColor: primaryTeal,
        elevation: 0,
        centerTitle: true,
        title:  Text('مرور آزمون',  style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontFamily: 'Vazirmatn',
            fontSize: _getResponsiveSize(context, 20),
          ),),
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16.0),
        itemCount: questions.length,
        itemBuilder: (context, index) {
          final question = questions[index];
          final userAnswerIndex = userAnswers[question.id];
          final isCorrect = userAnswerIndex == question.correctAnswerIndex;

          return Card(
            elevation: 2,
            margin: const EdgeInsets.symmetric(vertical: 8),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(
                color: isCorrect ? Colors.green : Colors.red,
                width: 2,
              )
            ),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('${index + 1}. ${question.text}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(height: 12),
                  // نمایش تمام گزینه‌ها با مشخص کردن پاسخ صحیح و پاسخ کاربر
                  ...List.generate(question.options.length, (optIndex) {
                    return _buildReviewOption(
  context,
  question.options[optIndex], // <-- حالا options یک لیست از رشته‌هاست
  isCorrect: optIndex == question.correctAnswerIndex,
  isSelected: optIndex == userAnswerIndex,
);
                  }),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildReviewOption(BuildContext context, String text, {required bool isCorrect, required bool isSelected}) {
    IconData? icon;
    Color color = Colors.transparent;

    if (isCorrect) {
      icon = Icons.check_circle;
      color = Colors.green;
    } else if (isSelected) {
      icon = Icons.cancel;
      color = Colors.red;
    }

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          if (icon != null) Icon(icon, color: color, size: 20),
          const SizedBox(width: 8),
          Expanded(child: Text(text)),
        ],
      ),
    );
  }
}