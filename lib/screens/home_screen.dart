import 'dart:io';

import 'package:azmoonak_app/helpers/adaptive_text_size.dart'; // Import the new helper
import 'package:azmoonak_app/helpers/hive_db_service.dart';
import 'package:azmoonak_app/models/quiz_attempt.dart';
import 'package:azmoonak_app/screens/profile_screen.dart';
import 'package:azmoonak_app/screens/trial_quiz_screen.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:timer_builder/timer_builder.dart';
import '../providers/auth_provider.dart';
import '../services/api_service.dart';
import '../models/category.dart';
import '../models/course.dart';
import '../models/question.dart';
import 'premium_screen.dart';
import 'test_setup_screen.dart';
import 'course_list_screen.dart';

class HomeScreen extends StatefulWidget {
  final bool isPickerMode;
  const HomeScreen({super.key, this.isPickerMode = false});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final ApiService _apiService = ApiService();
  final HiveService _hiveService = HiveService();

  List<Category> _categories = [];
  bool _isLoading = true;
  bool _isSyncing = false;
  String _errorMessage = '';
bool _isInit = true;
  // --- پالت رنگی جدید (Teal) ---
  static const Color primaryTeal = Color(0xFF008080); // Teal اصلی
  static const Color lightTeal = Color(0xFF4DB6AC); // Teal روشن‌تر
  static const Color darkTeal = Color(0xFF004D40); // Teal تیره‌تر
  static const Color accentYellow = Color(0xFFFFD700); // زرد تاکید (برای ستاره)
  static const Color textDark = Color(0xFF212121); // متن تیره
  static const Color textMedium = Color(0xFF607D8B); // متن متوسط
  static const Color backgroundLight = Color(0xFFF8F9FA); // پس‌زمینه روشن

  @override
  void didChangeDependencies() {
    // این متد بعد از initState و هر بار که وابستگی‌ها تغییر می‌کنند، اجرا می‌شود
    if (_isInit) {
      _loadInitialData();
    }
    _isInit = false;
    super.didChangeDependencies();
  }

  @override
  void initState() {
    super.initState();
    _loadInitialData();
    _syncAllPremiumContent(showSuccessMessage: false);
  }
Future<void> _loadInitialData() async {
    if (!mounted) return;
    setState(() { _isLoading = true; _errorMessage = ''; });
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      await authProvider.refreshUser();
      
      final user = authProvider.user;
      final token = authProvider.token;
      
      if (user != null && token != null) {
        await _syncOfflineAttempts(userId: user.id, token: token);
        if (user.isPremium) {
          await _loadPremiumUserData(userId: user.id, token: token);
        } else {
          await _loadFreeUserData(token);
        }
      } else {
        setState(() { _categories = []; });
      }
    } catch (e) {
      if (mounted) setState(() { _errorMessage = e.toString().replaceAll("Exception: ", ""); });
    } finally {
      if (mounted) setState(() { _isLoading = false; });
    }
  }

  Future<void> _loadPremiumUserData({required String userId, required String token}) async {
    final localCategories = await _hiveService.getCategories(userId);
    if (mounted && localCategories.isNotEmpty) {
      setState(() { _categories = localCategories; });
    } else if (mounted) {
      final onlineCategories = await _apiService.fetchCategories(token);
      setState(() {
        _categories = onlineCategories;
        if (localCategories.isEmpty) _errorMessage = 'برای استفاده آفلاین، لطفا داده‌ها را همگام‌سازی کنید.';
      });
    }
  }

  Future<void> _loadFreeUserData(String token) async {
    final onlineCategories = await _apiService.fetchCategories(token);
    if (mounted) setState(() { _categories = onlineCategories; });
  }

  Future<void> _syncAllPremiumContent({bool showSuccessMessage = true}) async {
    if (_isSyncing) return;
    
    final connectivityResult = await (Connectivity().checkConnectivity());
    if (connectivityResult == ConnectivityResult.none) {
      if (showSuccessMessage) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('برای همگام‌سازی به اینترنت نیاز دارید.')));
      return;
    }
    
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final user = authProvider.user;
    final token = authProvider.token;
    if (user == null || token == null || !user.isPremium) return;

    setState(() { _isSyncing = true; });
    try {
      // دانلود و ذخیره تمام داده‌ها
      final onlineCategories = await _apiService.fetchCategories(token);
      await _hiveService.syncData<Category>('categories', onlineCategories, user.id);
      
      List<Course> allCourses = [];
      List<Question> allQuestions = [];
      for (var cat in onlineCategories) {
        final courses = await _apiService.fetchCoursesByCategory(cat.id, token);
        allCourses.addAll(courses);
        for (var course in courses) {
          final questions = await _apiService.fetchAllQuestionsForCourse(course.id, token);
          allQuestions.addAll(questions);
        }
      }
      await _hiveService.syncData<Course>('courses', allCourses, user.id);
      await _hiveService.syncData<Question>('questions', allQuestions, user.id);
      
      await _hiveService.debugHive(user.id);
      // آپدیت UI با داده‌های جدید
      if (mounted) {
        setState(() { _categories = onlineCategories; _errorMessage = ''; });
        if (showSuccessMessage) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('همگام‌سازی کامل با موفقیت انجام شد!')));
        }
      }
    } catch (e) {
      print("Sync Error: $e");
    } finally {
      if (mounted) setState(() { _isSyncing = false; });
    }
  }
  // Helper to get responsive sizes based on screen width
  double _getResponsiveSize(BuildContext context, double baseSize) {
    final screenWidth = MediaQuery.of(context).size.width;
    // Adjust this multiplier as needed for different screen sizes
    return baseSize * (screenWidth / 375.0); // Assuming 375 is a common base width (e.g., iPhone 8)
  }


  Future<void> _syncOfflineAttempts({required String userId, required String token}) async {
    // این تابع برای آینده است و فعلا منطق پیچیده‌ای ندارد
  }
  

  void _startTrialQuiz() async {
    showDialog(context: context, builder: (_) => const Center(child: CircularProgressIndicator()));
    try {
      final trialQuestions = await _hiveService.getTrialQuestions();
      if (mounted) Navigator.of(context).pop();

      if (trialQuestions.isNotEmpty) {
        Navigator.of(context).push(MaterialPageRoute(builder: (ctx) => TrialQuizScreen(questions: trialQuestions)));
      } else {
        throw Exception('سوالات آزمایشی یافت نشد. لطفا به اینترنت متصل شوید و برنامه را دوباره باز کنید.');
      }
    } catch (e) {
      if (mounted) Navigator.of(context).pop();
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString().replaceAll("Exception: ", ""))));
    }
  }

  Future<void> _loadFromLocalDb(String userId) async {
    final localCategories = await _hiveService.getCategories(userId);
    if (mounted) {
      setState(() {
        _categories = localCategories;
        _errorMessage = '';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    return Consumer<AuthProvider>(builder: (context, authProvider, child) {
      final user = authProvider.user;
      final profileImageFile = user?.profileImagePath != null ? File(user!.profileImagePath!) : null;

      return Scaffold(
        backgroundColor: backgroundLight,
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (ctx) => const TestSetupScreen())),
          label: AdaptiveTextSize(
            text: 'ساخت آزمون سفارشی',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontFamily: 'Vazirmatn', fontSize: 16),
          ),
          icon: Icon(Icons.add_circle_outline, color: Colors.white, size: _getResponsiveSize(context, 24)),
          backgroundColor: primaryTeal,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(_getResponsiveSize(context, 30))),
          elevation: 6,
        ),
        body: RefreshIndicator(
          onRefresh: _loadInitialData,
          color: primaryTeal,
          child: CustomScrollView(
            slivers: [
              // Custom Header with Wave Shape (Teal Gradient)
              if (!widget.isPickerMode)
              
                SliverToBoxAdapter(
                  child: Stack(
                    children: [
                      Container(
                        height: screenHeight * 0.25, // Responsive height for header
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [primaryTeal, lightTeal.withOpacity(0.8)],
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                          ),
                          borderRadius: BorderRadius.vertical(bottom: Radius.circular(_getResponsiveSize(context, 30))),
                        ),
                      ),
                      Padding(
                        padding: EdgeInsets.only(
                          top: _getResponsiveSize(context, 40.0),
                          left: _getResponsiveSize(context, 16.0),
                          right: _getResponsiveSize(context, 16.0),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                GestureDetector(
                                  onTap: () {
                                    Navigator.of(context).push(MaterialPageRoute(builder: (ctx) => const ProfileScreen()));
                                  },
                                  child: Hero(
                                    tag: 'profileImage',
                                    child: CircleAvatar(
                                      radius: _getResponsiveSize(context, 24),
                                      backgroundColor: Colors.white.withOpacity(0.3),
                                      backgroundImage: profileImageFile != null ? FileImage(profileImageFile) : null,
                                      child: profileImageFile == null
                                          ? AdaptiveTextSize(
                                              text: user?.name.isNotEmpty == true ? user!.name.substring(0, 1) : 'U',
                                              style: TextStyle(
                                                  fontSize: 22, color: Colors.white, fontWeight: FontWeight.bold),
                                            )
                                          : null,
                                    ),
                                  ),
                                ),
                                AdaptiveTextSize(
                                  text: "آزمونک",
                                  style: TextStyle(
                                    fontSize: 28,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                    fontFamily: 'Vazirmatn',
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: _getResponsiveSize(context, 30)),
                            AdaptiveTextSize(
                              text: 'سلام،',
                              style: TextStyle(
                                  fontSize: 20, color: Colors.white.withOpacity(0.9), fontFamily: 'Vazirmatn'),
                            ),
                            AdaptiveTextSize(
                              text: user?.name ?? 'کاربر گرامی',
                              style: TextStyle(
                                  fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white, fontFamily: 'Vazirmatn'),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

              SliverPadding(
                padding: EdgeInsets.fromLTRB(
                  _getResponsiveSize(context, 16.0),
                  _getResponsiveSize(context, 20.0),
                  _getResponsiveSize(context, 16.0),
                  _getResponsiveSize(context, 8.0),
                ),
                sliver: SliverToBoxAdapter(
                  child: _buildSubscriptionCard(context, user?.isPremium ?? false, user?.subscriptionExpiresAt),
                ),
              ),
              SliverPadding(
                padding: EdgeInsets.symmetric(
                    horizontal: _getResponsiveSize(context, 16.0), vertical: _getResponsiveSize(context, 8.0)),
                sliver: SliverToBoxAdapter(
                  child: _buildQuickStatsSection(),
                ),
              ),
              SliverPadding(
                padding: EdgeInsets.symmetric(
                    horizontal: _getResponsiveSize(context, 16.0), vertical: _getResponsiveSize(context, 8.0)),
                sliver: SliverToBoxAdapter(
                  child: _buildTrialQuizCard(),
                ),
              ),

              SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.fromLTRB(
                    _getResponsiveSize(context, 16.0),
                    _getResponsiveSize(context, 32.0),
                    _getResponsiveSize(context, 16.0),
                    _getResponsiveSize(context, 16.0),
                  ),
                  child: AdaptiveTextSize(
                    text: 'دسته‌بندی‌های اصلی',
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: textDark, fontFamily: 'Vazirmatn'),
                  ),
                ),
              ),

              _isLoading
                  ? SliverToBoxAdapter(
                      child: Center(
                          child: Padding(
                              padding: EdgeInsets.all(_getResponsiveSize(context, 32.0)),
                              child: CircularProgressIndicator(color: primaryTeal))))
                  : _errorMessage.isNotEmpty
                      ? SliverToBoxAdapter(
                          child: Center(
                              child: Padding(
                                  padding: EdgeInsets.all(_getResponsiveSize(context, 32.0)),
                                  child: AdaptiveTextSize(
                                      text: _errorMessage,
                                      textAlign: TextAlign.center,
                                      style: TextStyle(color: Colors.red.shade700, fontFamily: 'Vazirmatn')))))
                      : SliverPadding(
                          padding: EdgeInsets.fromLTRB(
                            _getResponsiveSize(context, 16.0),
                            _getResponsiveSize(context, 8.0),
                            _getResponsiveSize(context, 16.0),
                            _getResponsiveSize(context, 80.0),
                          ),
                          sliver: SliverGrid(
                            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: screenWidth > 600 ? 3 : 2, // 3 columns for wider screens
                              crossAxisSpacing: _getResponsiveSize(context, 16),
                              mainAxisSpacing: _getResponsiveSize(context, 16),
                              childAspectRatio: screenWidth > 600 ? 1.2 : 1.0, // Adjust aspect ratio for wider screens
                            ),
                            delegate: SliverChildBuilderDelegate(
                              (context, index) {
                                return _buildCategoryCard(_categories[index]);
                              },
                              childCount: _categories.length,
                            ),
                          ),
                        ),
            ],
          ),
        ),
      );
    });
  }

  Widget _buildSubscriptionCard(BuildContext context, bool isPremium, DateTime? expiryDate) {
    if (isPremium && expiryDate != null) {
      return _buildPremiumStatusCard(expiryDate);
    } else {
      return _buildPremiumCallToAction(context);
    }
  }

  Widget _buildPremiumStatusCard(DateTime expiryDate) {
    return Card(
      color: Colors.white,
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(_getResponsiveSize(context, 20))),
      child: Container(
        padding: EdgeInsets.all(_getResponsiveSize(context, 20.0)),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(_getResponsiveSize(context, 20)),
          gradient: LinearGradient(
            colors: [lightTeal.withOpacity(0.1), backgroundLight],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                Icon(Icons.workspace_premium_rounded, color: primaryTeal, size: _getResponsiveSize(context, 30)),
                SizedBox(width: _getResponsiveSize(context, 10)),
                AdaptiveTextSize(
                  text: 'شما عضو ویژه هستید',
                  style: TextStyle(fontWeight: FontWeight.bold, color: primaryTeal, fontSize: 17, fontFamily: 'Vazirmatn'),
                ),
              ],
            ),
            SizedBox(height: _getResponsiveSize(context, 16)),
            AdaptiveTextSize(
              text: 'زمان باقی‌مانده از اشتراک شما:',
              
              style: TextStyle(color: textMedium, fontSize: 13, fontFamily: 'Vazirmatn'),
            ),
            SizedBox(height: _getResponsiveSize(context, 10)),
            TimerBuilder.periodic(
              const Duration(seconds: 1),
              builder: (context) {
                final now = DateTime.now();
                final remaining = expiryDate.difference(now);

                if (remaining.isNegative) {
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    _loadInitialData();
                  });
                  return AdaptiveTextSize(
                    text: 'اشتراک شما به پایان رسیده است.',
                    style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red, fontFamily: 'Vazirmatn', fontSize: 16),
                  );
                }

                final days = remaining.inDays;
                final hours = remaining.inHours % 24;
                final minutes = remaining.inMinutes % 60;
                final seconds = remaining.inSeconds % 60;

                return AdaptiveTextSize(
                  text: '$days روز و $hours ساعت و $minutes دقیقه و $seconds ثانیه',
                  style: TextStyle(
                    fontSize: 19,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Vazirmatn',
                    color: darkTeal,
                    
                  ),
                 
                );
              },
            )
          ],
        ),
      ),
    );
  }

  Widget _buildPremiumCallToAction(BuildContext context) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(_getResponsiveSize(context, 20))),
      child: InkWell(
        borderRadius: BorderRadius.circular(_getResponsiveSize(context, 20)),
        onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (ctx) => const PremiumScreen())),
        child: Container(
          padding: EdgeInsets.all(_getResponsiveSize(context, 20.0)),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(_getResponsiveSize(context, 20)),
            gradient: LinearGradient(
              colors: [accentYellow.withOpacity(0.1), Colors.white],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Row(
            children: [
              Icon(Icons.star_rounded, color: accentYellow, size: _getResponsiveSize(context, 36)),
              SizedBox(width: _getResponsiveSize(context, 16)),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AdaptiveTextSize(
                      text: 'عضویت ویژه',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: textDark, fontFamily: 'Vazirmatn'),
                    ),
                    AdaptiveTextSize(
                      text: 'دسترسی نامحدود به تمامی امکانات',
                      style: TextStyle(color: textMedium, fontSize: 14, fontFamily: 'Vazirmatn'),
                    ),
                  ],
                ),
              ),
              Icon(Icons.arrow_forward_ios_rounded, color: textMedium.withOpacity(0.7), size: _getResponsiveSize(context, 20)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryCard(Category category) {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(_getResponsiveSize(context, 20))),
      child: InkWell(
        borderRadius: BorderRadius.circular(_getResponsiveSize(context, 20)),
        onTap: () async {
          final List<Course>? result = await Navigator.of(context).push<List<Course>>(
            MaterialPageRoute(
              builder: (ctx) => CourseListScreen(category: category, isPickerMode: widget.isPickerMode),
            ),
          );

          if (widget.isPickerMode && result != null && result.isNotEmpty) {
            Navigator.of(context).pop(result);
          }
        },
        child: Padding(
          padding: EdgeInsets.all(_getResponsiveSize(context, 16.0)),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: EdgeInsets.all(_getResponsiveSize(context, 15)),
                decoration: BoxDecoration(
                  color: primaryTeal.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.school_rounded, color: primaryTeal, size: _getResponsiveSize(context, 40)),
              ),
              SizedBox(height: _getResponsiveSize(context, 18)),
              AdaptiveTextSize(
                text: category.name,
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: textDark, fontFamily: 'Vazirmatn'),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTrialQuizCard() {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(_getResponsiveSize(context, 20))),
      child: InkWell(
        borderRadius: BorderRadius.circular(_getResponsiveSize(context, 20)),
        onTap: _startTrialQuiz,
        child: Container(
          padding: EdgeInsets.all(_getResponsiveSize(context, 20.0)),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(_getResponsiveSize(context, 20)),
            gradient: LinearGradient(
              colors: [lightTeal.withOpacity(0.1), Colors.white],
              begin: Alignment.bottomRight,
              end: Alignment.topLeft,
            ),
          ),
          child: Row(
            children: [
              Icon(Icons.quiz_rounded, color: primaryTeal, size: _getResponsiveSize(context, 36)),
              SizedBox(width: _getResponsiveSize(context, 16)),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AdaptiveTextSize(
                      text: 'آزمون آمادگی رایگان',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: textDark, fontFamily: 'Vazirmatn'),
                    ),
                    AdaptiveTextSize(
                      text: 'با ۱۰ سوال رایگان خود را بسنجید',
                      style: TextStyle(color: textMedium, fontSize: 14, fontFamily: 'Vazirmatn'),
                    ),
                  ],
                ),
              ),
              Icon(Icons.arrow_forward_ios_rounded, color: textMedium.withOpacity(0.7), size: _getResponsiveSize(context, 20)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuickStatsSection() {
    final user = Provider.of<AuthProvider>(context, listen: false).user;
    if (user == null) return const SizedBox.shrink();
    return FutureBuilder<List<QuizAttempt>>(
      future: _hiveService.getQuizHistory(user.id),
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const SizedBox.shrink();
        }
        final history = snapshot.data!;
        final totalTests = history.length;
        final averageScore = history.map((h) => h.percentage).reduce((a, b) => a + b) / totalTests;

        return Row(
          children: [
            Expanded(
                child: _buildStatCard(
                    'تعداد آزمون‌ها', totalTests.toString(), Icons.fact_check_rounded, Colors.orange.shade700)),
            SizedBox(width: _getResponsiveSize(context, 16)),
            Expanded(
                child: _buildStatCard(
                    'میانگین نمره', '${averageScore.toStringAsFixed(0)}%', Icons.analytics_outlined, Colors.green.shade700)),
          ],
        );
      },
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(_getResponsiveSize(context, 20))),
      color: Colors.white,
      child: Container(
        padding: EdgeInsets.all(_getResponsiveSize(context, 16.0)),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(_getResponsiveSize(context, 20)),
          gradient: LinearGradient(
            colors: [color.withOpacity(0.05), Colors.white],
            begin: Alignment.bottomLeft,
            end: Alignment.topRight,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.all(_getResponsiveSize(context, 10)),
              decoration: BoxDecoration(
                color: color.withOpacity(0.15),
                borderRadius: BorderRadius.circular(_getResponsiveSize(context, 15)),
              ),
              child: Icon(icon, size: _getResponsiveSize(context, 30), color: color),
            ),
            SizedBox(width: _getResponsiveSize(context, 12)),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AdaptiveTextSize(
                    text: value,
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: textDark),
                  ),
                  AdaptiveTextSize(
                    text: title,
                    style: TextStyle(color: textMedium, fontSize: 13, fontFamily: 'Vazirmatn'),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}