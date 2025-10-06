import 'package:azmoonak_app/helpers/adaptive_text_size.dart';
import 'package:azmoonak_app/models/quiz_attempt.dart';
import 'package:azmoonak_app/providers/auth_provider.dart';
import 'package:azmoonak_app/screens/premium_screen.dart';
import 'package:azmoonak_app/screens/review_screen.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../helpers/hive_db_service.dart';

class AllExamsPage extends StatefulWidget {
  final List<QuizAttempt> history;

  const AllExamsPage({super.key, required this.history});
static const Color primaryTeal = Color(0xFF008080); // Teal اصلی
  static const Color lightTeal = Color(0xFF4DB6AC); // Teal روشن‌تر
  static const Color darkTeal = Color(0xFF004D40); // Teal تیره‌تر
  static const Color accentYellow = Color(0xFFFFD700); // زرد تاکید (برای ستاره)
  static const Color textDark = Color(0xFF212121); // متن تیره
  static const Color textMedium = Color(0xFF607D8B); // متن متوسط
  static const Color backgroundLight = Color(0xFFF8F9FA); 
  @override
  State<AllExamsPage> createState() => _AllExamsPageState();
}

class _AllExamsPageState extends State<AllExamsPage> {
    late Future<List<QuizAttempt>> _historyFuture;
  final HiveService _hiveService = HiveService();
 // پس‌زمینه روشن
  void _navigateToReviewScreen(String attemptId) async {
    final user = Provider.of<AuthProvider>(context, listen: false).user;
    try {
      showDialog(context: context, builder: (_) => const Center(child: CircularProgressIndicator()));
      if (user == null) return;
      final details = await _hiveService.getAttemptDetails(attemptId, user.id);
      if (mounted) Navigator.of(context, rootNavigator: true).pop();
      if (details == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: AdaptiveTextSize(text: 'جزئیات این آزمون برای مرور یافت نشد.', style: TextStyle(color: Colors.white, fontFamily: 'Vazirmatn', fontSize: _getResponsiveSize(context, 14)))));
        }
        return;
      }
      if (mounted) {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (ctx) => ReviewScreen(
              questions: details.questions,
              userAnswers: details.userAnswers,
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) Navigator.of(context, rootNavigator: true).pop();
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: AdaptiveTextSize(text: 'خطا: ${e.toString()}', style: TextStyle(color: Colors.white, fontFamily: 'Vazirmatn', fontSize: _getResponsiveSize(context, 14)))));
      }
    }
  }

  void _showPremiumPrompt() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(_getResponsiveSize(context, 15))),
        title: AdaptiveTextSize(
          text: 'قابلیت ویژه',
          style: TextStyle(fontWeight: FontWeight.bold, color: AllExamsPage.primaryTeal, fontFamily: 'Vazirmatn', fontSize: _getResponsiveSize(context, 18)),
        ),
        content: AdaptiveTextSize(
          text: 'مرور سوالات آزمون‌های قبلی یک قابلیت ویژه برای اعضای Premium است.',
          style: TextStyle(color: AllExamsPage.textDark, fontFamily: 'Vazirmatn', fontSize: _getResponsiveSize(context, 15)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: AdaptiveTextSize(
              text: 'انصراف',
              style: TextStyle(color: AllExamsPage.textMedium, fontFamily: 'Vazirmatn', fontSize: _getResponsiveSize(context, 14)),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AllExamsPage.primaryTeal,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(_getResponsiveSize(context, 10))),
            ),
            onPressed: () {
              Navigator.of(ctx).pop();
              Navigator.of(context).push(MaterialPageRoute(builder: (ctx) => const PremiumScreen()));
            },
            child: AdaptiveTextSize(
              text: 'عضویت ویژه شو!',
              style: TextStyle(color: Colors.white, fontFamily: 'Vazirmatn', fontSize: _getResponsiveSize(context, 14)),
            ),
          ),
        ],
      ),
    );
  }

  // Helper to get responsive sizes based on screen width
  double _getResponsiveSize(BuildContext context, double baseSize) {
    final screenWidth = MediaQuery.of(context).size.width;
    // Adjust this multiplier as needed for different screen sizes
    return baseSize * (screenWidth / 375.0); // Assuming 375 is a common base width (e.g., iPhone 8)
  }

    void _handleReviewTap(QuizAttempt attempt) {
    final user = Provider.of<AuthProvider>(context, listen: false).user;
    if (user != null && user.isPremium) {
      _navigateToReviewScreen(attempt.id);
    } else {
      _showPremiumPrompt();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: AdaptiveTextSize(
          text:'تمام آزمون ها',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontFamily: 'Vazirmatn',
            fontSize: _getResponsiveSize(context, 20),
          ),
        ),
        backgroundColor:const Color.fromRGBO(0, 128, 128, 1),
        elevation: 0,
        centerTitle: true,),
      body:  ListView.builder(
          shrinkWrap: true,
          // physics: const NeverScrollableScrollPhysics(),
          itemCount: widget.history.length, //
          itemBuilder: (context, index) {
            final attempt = widget.history[index];
            final score = attempt.percentage.toInt();
            final scoreColor = score >= 70 ? Colors.green.shade600 : (score >= 40 ? Colors.orange.shade600 : Colors.red.shade600);

            return Card(
              elevation: 3,
              margin: EdgeInsets.symmetric(vertical: _getResponsiveSize(context, 6)),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(_getResponsiveSize(context, 15))),
              child: InkWell(
                borderRadius: BorderRadius.circular(_getResponsiveSize(context, 15)),
                onTap: () => _handleReviewTap(attempt),
                child: Padding(
                  padding: EdgeInsets.all(_getResponsiveSize(context, 16.0)),
                  child: Row(
                    children: [
                      SizedBox(
                        width: _getResponsiveSize(context, 50),
                        height: _getResponsiveSize(context, 50),
                        child: Stack(fit: StackFit.expand, children: [
                          CircularProgressIndicator(
                              value: score / 100,
                              strokeWidth: _getResponsiveSize(context, 5),
                              backgroundColor: scoreColor.withOpacity(0.2),
                              valueColor: AlwaysStoppedAnimation<Color>(scoreColor)),
                          Center(
                              child: AdaptiveTextSize(
                            text: '$score%',
                            style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: _getResponsiveSize(context, 14),
                                color: AllExamsPage.textDark),
                          )),
                        ]),
                      ),
                      SizedBox(width: _getResponsiveSize(context, 16)),
                      Expanded(
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          AdaptiveTextSize(
                            text: attempt.subjectName ?? 'آزمون عمومی',
                            style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: _getResponsiveSize(context, 16),
                                color: AllExamsPage.textDark,
                                fontFamily: 'Vazirmatn'),
                          ),
                          SizedBox(height: _getResponsiveSize(context, 4)),
                          AdaptiveTextSize(
                            text: DateFormat('yyyy/MM/dd – kk:mm', 'fa').format(attempt.createdAt),
                            style: TextStyle(
                                color: AllExamsPage.textMedium,
                                fontSize: _getResponsiveSize(context, 12),
                                fontFamily: 'Vazirmatn'),
                          ),
                        ]),
                      ),
                      Icon(Icons.arrow_forward_ios_rounded, size: _getResponsiveSize(context, 18), color: AllExamsPage.textMedium.withOpacity(0.7)),
                    ],
                  ),
                ),
              ),
            );
          },
        )
    );
  }
}
