import 'dart:io';
import 'dart:math'; // برای استفاده از تابع min
import 'package:azmoonak_app/helpers/hive_db_service.dart';
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
          if(mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('جزئیات این آزمون برای مرور یافت نشد.')));
          return;
      }
      if(mounted) {
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
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('خطا: ${e.toString()}')));
    }
  }

  void _showPremiumPrompt() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('قابلیت ویژه'),
        content: const Text('مرور سوالات آزمون‌های قبلی یک قابلیت ویژه برای اعضای Premium است.'),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('انصراف')),
          ElevatedButton(
            child: const Text('عضویت ویژه شو!'),
            onPressed: () {
              Navigator.of(ctx).pop();
              Navigator.of(context).push(MaterialPageRoute(builder: (ctx) => const PremiumScreen()));
            },
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
      appBar: AppBar(
        title: const Text('پروفایل و پیشرفت'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
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
      child: ListView( // از ListView به عنوان والد اصلی استفاده می‌کنیم
        padding: const EdgeInsets.all(16.0),
        children: [
          // --- بخش ۱: اطلاعات پروفایل (همیشه نمایش داده می‌شود) ---
          InkWell(
            onTap: () {
              Navigator.of(context).push(
                  MaterialPageRoute(builder: (ctx) => const EditProfileScreen()));
            },
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: Row(children: [
             CircleAvatar(
          radius: 40,
          backgroundImage: profileImageFile != null ? FileImage(profileImageFile) : null,
  child: profileImageFile == null 
      ? Text(user?.name.isNotEmpty == true ? user!.name.substring(0, 1) : 'U', style: const TextStyle(fontSize: 32))
      : null,
),
              
                const SizedBox(width: 16),
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(user?.name ?? 'کاربر', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20)),
                    Text(user?.email ?? '', style: const TextStyle(color: Colors.grey)),
                  ]),
                ),
                const Icon(Icons.edit_outlined, color: Colors.grey),
              ]),
            ),
          ),
          const Divider(height: 32),

          // --- بخش ۲: آمار و نمودارها (وابسته به Future) ---
          FutureBuilder<List<QuizAttempt>>(
            future: _historyFuture,
            builder: (context, snapshot) {
              // حالت لودینگ
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: Padding(padding: EdgeInsets.all(50.0), child: CircularProgressIndicator()));
              }
              
              // حالت خطا
              if (snapshot.hasError) {
                return Center(child: Text('خطا در دریافت تاریخچه: ${snapshot.error}'));
              }
              
              // حالت بدون آزمون (داده خالی)
              if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return const Center(child: Padding(
                  padding: EdgeInsets.all(50.0),
                  child: Text('هنوز هیچ آزمونی ثبت نشده است. \n با شرکت در آزمون‌ها، پیشرفت خود را اینجا ببینید.', textAlign: TextAlign.center),
                ));
              }
              
              // حالت موفقیت‌آمیز (داده وجود دارد)
              final history = snapshot.data!;
              final totalTests = history.length;
              final averageScore = history.map((h) => h.percentage).reduce((a, b) => a + b) / totalTests;
              
              // ... (محاسبه avgPerformanceByCourse بدون تغییر) ...

              // ویجت Column برای نمایش تمام بخش‌های وابسته به تاریخچه
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildStatsSection(totalTests, averageScore),
                  const SizedBox(height: 24),
                  _buildLineChartSection(history),
                  const SizedBox(height: 24),
                  // _buildBarChartSection(avgPerformanceByCourse),
                  const SizedBox(height: 24),
                  _buildRecentHistorySection(history),
                ],
              );
            },
          ),
        ],
      ),
   ) );
  }
  
  Widget _buildStatsSection(int totalTests, double averageScore) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('آمار کلی عملکرد شما', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(child: _buildStatCard('تعداد آزمون', totalTests.toString(), Icons.playlist_add_check)),
            const SizedBox(width: 16),
            Expanded(child: _buildStatCard('میانگین نمره', '${averageScore.toStringAsFixed(1)}%', Icons.show_chart)),
          ],
        )
      ],
    );
  }
  
  Widget _buildStatCard(String title, String value, IconData icon) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Icon(icon, size: 32, color: Theme.of(context).primaryColor),
            const SizedBox(height: 8),
            Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text(title, style: const TextStyle(color: Colors.grey)),
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
        const Text('روند پیشرفت', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 16),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: SizedBox(
              height: 200,
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
                            const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                            children: [TextSpan(text: DateFormat('yy/MM/dd', 'fa').format(attempt.createdAt), style: const TextStyle(color: Colors.white70))],
                          );
                        }).toList();
                      },
                    ),
                  ),
                  titlesData: FlTitlesData(
                    leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 40)),
                    topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          if (value.toInt() < reversedHistory.length) {
                            final date = reversedHistory[value.toInt()].createdAt;
                            return Padding(
                              padding: const EdgeInsets.only(top: 8.0),
                              child: Text(DateFormat('MM/dd', 'fa').format(date), style: const TextStyle(fontSize: 10)),
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
                      color: Theme.of(context).primaryColor,
                      barWidth: 4,
                      belowBarData: BarAreaData(show: true, color: Theme.of(context).primaryColor.withOpacity(0.2)),
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
  Widget _buildBarChartSection(Map<String, double> data) {
    final keys = data.keys.toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('عملکرد بر اساس موضوع', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 16),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: SizedBox(
              height: 200,
              child: BarChart(
                BarChartData(
                  // ...
                  titlesData: FlTitlesData(
                    // ...
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 22,
                        getTitlesWidget: (value, meta) {
                           if (value.toInt() < keys.length) {
                             final text = keys[value.toInt()];
                             return Padding(
                               padding: const EdgeInsets.only(top: 8.0),
                               child: Text(text.substring(0, min(5, text.length)), style: const TextStyle(fontSize: 10)),
                             );
                           }
                           return const Text('');
                        },
                      ),
                    ),
                  ),
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
            const Text('تاریخچه اخیر آزمون‌ها', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            TextButton(onPressed: () {}, child: const Text('مشاهده همه')),
        ]),
        const SizedBox(height: 8),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: history.length > 5 ? 5 : history.length,
          itemBuilder: (context, index) {
            final attempt = history[index];
            final score = attempt.percentage.toInt();
            final scoreColor = score >= 70 ? Colors.green : (score >= 40 ? Colors.orange : Colors.red);

            return Card(
              child: InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: () => _handleReviewTap(attempt),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 50, height: 50,
                        child: Stack(fit: StackFit.expand, children: [
                            CircularProgressIndicator(value: score / 100, strokeWidth: 5, backgroundColor: scoreColor.withOpacity(0.2), valueColor: AlwaysStoppedAnimation<Color>(scoreColor)),
                            Center(child: Text('$score%', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14))),
                        ]),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            Text(attempt.courseName ?? 'آزمون عمومی', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                            const SizedBox(height: 4),
                            Text(DateFormat('yyyy/MM/dd – kk:mm', 'fa').format(attempt.createdAt), style: const TextStyle(color: Colors.grey, fontSize: 12)),
                        ]),
                      ),
                      const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
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