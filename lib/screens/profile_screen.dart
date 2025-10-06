import 'dart:io';
import 'dart:math'; // برای استفاده از تابع min
import 'package:azmoonak_app/helpers/adaptive_text_size.dart'; // Import the new helper
import 'package:azmoonak_app/helpers/hive_db_service.dart';
import 'package:azmoonak_app/screens/AllExamsPage.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../models/quiz_attempt.dart';
import '../providers/auth_provider.dart';
import 'login_screen.dart';
import 'premium_screen.dart';
import 'review_screen.dart';
import 'edit_profile_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});
  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  late Future<List<QuizAttempt>> _historyFuture;
  final HiveService _hiveService = HiveService();

  // --- پالت رنگی جدید (Teal) - همانند HomeScreen ---
  static const Color primaryTeal = Color(0xFF008080); // Teal اصلی
  static const Color lightTeal = Color(0xFF4DB6AC); // Teal روشن‌تر
  static const Color darkTeal = Color(0xFF004D40); // Teal تیره‌تر
  static const Color accentYellow = Color(0xFFFFD700); // زرد تاکید (برای ستاره)
  static const Color textDark = Color(0xFF212121); // متن تیره
  static const Color textMedium = Color(0xFF607D8B); // متن متوسط
  static const Color backgroundLight = Color(0xFFF8F9FA); // پس‌زمینه روشن

  // Helper to get responsive sizes based on screen width
  double _getResponsiveSize(BuildContext context, double baseSize) {
    final screenWidth = MediaQuery.of(context).size.width;
    // Adjust this multiplier as needed for different screen sizes
    return baseSize * (screenWidth / 375.0); // Assuming 375 is a common base width (e.g., iPhone 8)
  }

  @override
  void initState() {
    super.initState();
    final user = Provider.of<AuthProvider>(context, listen: false).user;
    if (user != null) {
      _historyFuture = _hiveService.getQuizHistory(user.id);
    } else {
      _historyFuture = Future.value([]);
    }
  }

  Future<void> _refreshData() async {
    final user = Provider.of<AuthProvider>(context, listen: false).user;
    await Provider.of<AuthProvider>(context, listen: false).refreshUser();
    if (user != null) {
      setState(() {
        _historyFuture = _hiveService.getQuizHistory(user.id);
      });
    }
  }

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
          style: TextStyle(fontWeight: FontWeight.bold, color: primaryTeal, fontFamily: 'Vazirmatn', fontSize: _getResponsiveSize(context, 18)),
        ),
        content: AdaptiveTextSize(
          text: 'مرور سوالات آزمون‌های قبلی یک قابلیت ویژه برای اعضای Premium است.',
          style: TextStyle(color: textDark, fontFamily: 'Vazirmatn', fontSize: _getResponsiveSize(context, 15)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: AdaptiveTextSize(
              text: 'انصراف',
              style: TextStyle(color: textMedium, fontFamily: 'Vazirmatn', fontSize: _getResponsiveSize(context, 14)),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryTeal,
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
    final authProvider = Provider.of<AuthProvider>(context);
    final user = authProvider.user;
    final profileImageFile = user?.profileImagePath != null ? File(user!.profileImagePath!) : null;

    return Scaffold(
      backgroundColor: backgroundLight,
      appBar: AppBar(
        title: AdaptiveTextSize(
          text: 'پروفایل و پیشرفت',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontFamily: 'Vazirmatn',
            fontSize: _getResponsiveSize(context, 20),
          ),
        ),
        backgroundColor: primaryTeal,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white), // Color of the back button
        actions: [
          IconButton(
            icon: Icon(Icons.logout, color: Colors.white, size: _getResponsiveSize(context, 24)),
            tooltip: 'خروج از حساب',
            onPressed: () {
              authProvider.logout();
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (ctx) => const LoginScreen()),
                (route) => false,
              );
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _refreshData,
        color: primaryTeal,
        child: ListView(
          padding: EdgeInsets.all(_getResponsiveSize(context, 16.0)),
          children: [
            // --- بخش ۱: اطلاعات پروفایل ---
            InkWell(
              onTap: () {
                Navigator.of(context).push(MaterialPageRoute(builder: (ctx) => const EditProfileScreen()));
              },
              borderRadius: BorderRadius.circular(_getResponsiveSize(context, 12)),
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: _getResponsiveSize(context, 8.0)),
                child: Row(children: [
                  Hero(
                    tag: 'profileImage', // Use the same tag as HomeScreen
                    child: CircleAvatar(
                      radius: _getResponsiveSize(context, 40),
                      backgroundColor: lightTeal.withOpacity(0.3),
                      backgroundImage: profileImageFile != null ? FileImage(profileImageFile) : null,
                      child: profileImageFile == null
                          ? AdaptiveTextSize(
                              text: user?.name.isNotEmpty == true ? user!.name.substring(0, 1) : 'U',
                              style: TextStyle(
                                  fontSize: _getResponsiveSize(context, 32),
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold),
                            )
                          : null,
                    ),
                  ),
                  SizedBox(width: _getResponsiveSize(context, 16)),
                  Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      AdaptiveTextSize(
                        text: user?.name ?? 'کاربر',
                        style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: _getResponsiveSize(context, 20),
                            color: textDark,
                            fontFamily: 'Vazirmatn'),
                      ),
                      AdaptiveTextSize(
                        text: user?.email ?? '',
                        style: TextStyle(color: textMedium, fontSize: _getResponsiveSize(context, 14), fontFamily: 'Vazirmatn'),
                      ),
                    ]),
                  ),
                  Icon(Icons.edit_outlined, color: textMedium, size: _getResponsiveSize(context, 24)),
                ]),
              ),
            ),
            Divider(height: _getResponsiveSize(context, 32), color: Colors.grey.withOpacity(0.4)),

            // --- بخش ۲: آمار و نمودارها (وابسته به Future) ---
            FutureBuilder<List<QuizAttempt>>(
              future: _historyFuture,
              builder: (context, snapshot) {
                // حالت لودینگ
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(
                      child: Padding(
                          padding: EdgeInsets.all(_getResponsiveSize(context, 50.0)),
                          child: CircularProgressIndicator(color: primaryTeal)));
                }

                // حالت خطا
                if (snapshot.hasError) {
                  return Center(
                      child: AdaptiveTextSize(
                    text: 'خطا در دریافت تاریخچه: ${snapshot.error}',
                    style: TextStyle(color: Colors.red.shade700, fontFamily: 'Vazirmatn', fontSize: _getResponsiveSize(context, 14)),
                  ));
                }

                // حالت بدون آزمون (داده خالی)
                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return Center(
                      child: Padding(
                    padding: EdgeInsets.all(_getResponsiveSize(context, 50.0)),
                    child: AdaptiveTextSize(
                      text: 'هنوز هیچ آزمونی ثبت نشده است. \n با شرکت در آزمون‌ها، پیشرفت خود را اینجا ببینید.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: textMedium, fontFamily: 'Vazirmatn', fontSize: _getResponsiveSize(context, 15)),
                    ),
                  ));
                }

                // حالت موفقیت‌آمیز (داده وجود دارد)
                final history = snapshot.data!;
                final totalTests = history.length;
                final averageScore = history.map((h) => h.percentage).reduce((a, b) => a + b) / totalTests;

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildStatsSection(totalTests, averageScore),
                    SizedBox(height: _getResponsiveSize(context, 24)),
                    _buildLineChartSection(history),
                    SizedBox(height: _getResponsiveSize(context, 24)),
                    // _buildBarChartSection(avgPerformanceByCourse), // Still commented out
                    SizedBox(height: _getResponsiveSize(context, 24)),
                    _buildRecentHistorySection(history),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsSection(int totalTests, double averageScore) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AdaptiveTextSize(
          text: 'آمار کلی عملکرد شما',
          style: TextStyle(
              fontSize: _getResponsiveSize(context, 18),
              fontWeight: FontWeight.bold,
              color: textDark,
              fontFamily: 'Vazirmatn'),
        ),
        SizedBox(height: _getResponsiveSize(context, 16)),
        Row(
          children: [
            Expanded(
                child: _buildStatCard('تعداد آزمون', totalTests.toString(), Icons.playlist_add_check_rounded, primaryTeal)),
            SizedBox(width: _getResponsiveSize(context, 16)),
            Expanded(
                child: _buildStatCard('میانگین نمره', '${averageScore.toStringAsFixed(1)}%', Icons.show_chart_rounded, primaryTeal)),
          ],
        )
      ],
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color iconColor) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(_getResponsiveSize(context, 20))),
      child: Container(
        padding: EdgeInsets.all(_getResponsiveSize(context, 16.0)),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(_getResponsiveSize(context, 20)),
          gradient: LinearGradient(
            colors: [iconColor.withOpacity(0.08), Colors.white],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Column(
          children: [
            Icon(icon, size: _getResponsiveSize(context, 36), color: iconColor),
            SizedBox(height: _getResponsiveSize(context, 8)),
            AdaptiveTextSize(
              text: value,
              style: TextStyle(
                  fontSize: _getResponsiveSize(context, 22),
                  fontWeight: FontWeight.bold,
                  color: textDark,
                  fontFamily: 'Vazirmatn'),
            ),
            SizedBox(height: _getResponsiveSize(context, 4)),
            AdaptiveTextSize(
              text: title,
              style: TextStyle(color: textMedium, fontFamily: 'Vazirmatn', fontSize: _getResponsiveSize(context, 13)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLineChartSection(List<QuizAttempt> history) {
    final reversedHistory = history.reversed.toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AdaptiveTextSize(
          text: 'روند پیشرفت',
          style: TextStyle(
              fontSize: _getResponsiveSize(context, 18),
              fontWeight: FontWeight.bold,
              color: textDark,
              fontFamily: 'Vazirmatn'),
        ),
        SizedBox(height: _getResponsiveSize(context, 16)),
        Card(
          elevation: 4,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(_getResponsiveSize(context, 20))),
          child: Padding(
            padding: EdgeInsets.all(_getResponsiveSize(context, 16.0)),
            child: SizedBox(
              height: _getResponsiveSize(context, 200),
              child: LineChart(
                LineChartData(
                  gridData: const FlGridData(show: false),
                  borderData: FlBorderData(show: false),
                  lineTouchData: LineTouchData(
                    touchTooltipData: LineTouchTooltipData(
                      getTooltipItems: (touchedSpots) {
                        return touchedSpots.map((spot) {
                          final attempt = reversedHistory[spot.spotIndex];
                          return LineTooltipItem(
                            '${attempt.percentage.toStringAsFixed(1)}%\n',
                            TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: _getResponsiveSize(context, 14)),
                            children: [
                              TextSpan(
                                text: DateFormat('yy/MM/dd', 'fa').format(attempt.createdAt),
                                style: TextStyle(
                                    color: Colors.white70, fontSize: _getResponsiveSize(context, 12)),
                              )
                            ],
                          );
                        }).toList();
                      },
                     
                    ),
                  ),
                  titlesData: FlTitlesData(
                    leftTitles: AxisTitles(
                        sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: _getResponsiveSize(context, 40),
                            getTitlesWidget: (value, meta) {
                              return Text(value.toInt().toString(),
                                  style: TextStyle(color: textMedium, fontSize: _getResponsiveSize(context, 10)),
                                  textAlign: TextAlign.center);
                            })),
                    topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: _getResponsiveSize(context, 25),
                        getTitlesWidget: (value, meta) {
                          if (value.toInt() < reversedHistory.length) {
                            final date = reversedHistory[value.toInt()].createdAt;
                            return Padding(
                              padding: EdgeInsets.only(top: _getResponsiveSize(context, 8.0)),
                              child: Text(DateFormat('MM/dd', 'fa').format(date),
                                  style: TextStyle(color: textMedium, fontSize: _getResponsiveSize(context, 10))),
                            );
                          }
                          return const Text('');
                        },
                      ),
                    ),
                  ),
                  lineBarsData: [
                    LineChartBarData(
                      spots: reversedHistory.asMap().entries.map((entry) => FlSpot(entry.key.toDouble(), entry.value.percentage)).toList(),
                      isCurved: true,
                      color: primaryTeal,
                      barWidth: _getResponsiveSize(context, 4),
                      belowBarData: BarAreaData(show: true, color: primaryTeal.withOpacity(0.2)),
                      dotData: const FlDotData(show: false), // Hide dots for cleaner look
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRecentHistorySection(List<QuizAttempt> history) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          AdaptiveTextSize(
            text: 'تاریخچه اخیر آزمون‌ها',
            style: TextStyle(
                fontSize: _getResponsiveSize(context, 18),
                fontWeight: FontWeight.bold,
                color: textDark,
                fontFamily: 'Vazirmatn'),
          ),
          TextButton(
              onPressed: () {
                // TODO: Implement navigation to all history
                 Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => AllExamsPage(history: history),
                      ),
                    );
              },
              child: AdaptiveTextSize(
                text: 'مشاهده همه',
                style: TextStyle(color: primaryTeal, fontSize: _getResponsiveSize(context, 14), fontFamily: 'Vazirmatn'),
              )),
        ]),
        SizedBox(height: _getResponsiveSize(context, 8)),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: history.length > 5 ? 5 : history.length, // Display up to 5 recent attempts
          itemBuilder: (context, index) {
            final attempt = history[index];
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
                                color: textDark),
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
                                color: textDark,
                                fontFamily: 'Vazirmatn'),
                          ),
                          SizedBox(height: _getResponsiveSize(context, 4)),
                          AdaptiveTextSize(
                            text: DateFormat('yyyy/MM/dd – kk:mm', 'fa').format(attempt.createdAt),
                            style: TextStyle(
                                color: textMedium,
                                fontSize: _getResponsiveSize(context, 12),
                                fontFamily: 'Vazirmatn'),
                          ),
                        ]),
                      ),
                      Icon(Icons.arrow_forward_ios_rounded, size: _getResponsiveSize(context, 18), color: textMedium.withOpacity(0.7)),
                    ],
                  ),
                ),
              ),
            );
          },
        )
      ],
    );
  }
}