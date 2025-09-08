import 'dart:io';

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

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

   Future<void> _loadInitialData() async {
    if (!mounted) return;
    setState(() { _isLoading = true; _errorMessage = ''; });

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      
      // ۱. همیشه اطلاعات کاربر را از سرور رفرش کن
      await authProvider.refreshUser();
      
      final user = authProvider.user;
      final token = authProvider.token;

      if (user != null && token != null) {
        // ۲. بر اساس وضعیت کاربر، داده‌های دوره‌ها را بارگذاری کن
        if (user.isPremium) {
          // برای کاربر Premium، ابتدا از دیتابیس محلی بخوان
          final localCategories = await _hiveService.getCategories(user.id);
          if (mounted) setState(() { _categories = localCategories; });
          
          // سپس در پس‌زمینه، همگام‌سازی را شروع کن
          _syncAllPremiumContent(showSuccessMessage: localCategories.isEmpty);
        } else {
          // برای کاربر رایگان، همیشه از سرور آنلاین بخوان
          final onlineCategories = await _apiService.fetchCategories(token);
          if (mounted) setState(() { _categories = onlineCategories; });
        }
      } else {
        if (mounted) setState(() { _categories = []; });
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
      // اگر دیتابیس محلی خالی بود، یک بار از سرور بگیر و به کاربر بگو دانلود کند
      final onlineCategories = await _apiService.fetchCategories(token);
      setState(() {
        _categories = onlineCategories;
        if (localCategories.isEmpty) { // فقط بار اول این پیام را نشان بده
          _errorMessage = 'برای استفاده آفلاین، لطفا داده‌ها را همگام‌سازی کنید.';
        }
      });
    }
  }
   Future<void> _loadFreeUserData(String token) async {
    final onlineCategories = await _apiService.fetchCategories(token);
    if (mounted) setState(() { _categories = onlineCategories; });
  }

  // --- توابع همگام‌سازی ---
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
    if (user == null || token == null) return;

    if (mounted) setState(() { _isSyncing = true; });
    try {
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

      final latestCategories = await _hiveService.getCategories(user.id);
      if (mounted) {
        setState(() { _categories = latestCategories; _errorMessage = ''; });
        if(showSuccessMessage) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تمام محتوا با موفقیت همگام‌سازی شد!')));
        }
      }
    } catch (e) {
      print("Sync Error: $e");
      if(mounted && showSuccessMessage) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('خطا در همگام‌سازی: $e')));
    } finally {
      if (mounted) setState(() { _isSyncing = false; });
    }
  }
  // Future<void> _syncOfflineAttempts() async {
  //   final connectivityResult = await (Connectivity().checkConnectivity());
  //   if (connectivityResult == ConnectivityResult.none) return;
    
  //   // final token = Provider.of<AuthProvider>(context, listen: false).token;
  //   // if (token == null) return;
    
  //   // final unsyncedAttempts = await _hiveService.getUnsyncedAttempts();
  //   // if (unsyncedAttempts.isEmpty) return;
    
  //   // print("Syncing ${unsyncedAttempts.length} offline quiz results...");
  //   // for (var attempt in unsyncedAttempts) {
  //   //   try {
  //   //     // await _apiService.submitOfflineAttempt(attempt, token);
  //   //     await _hiveService.markAttemptAsSynced(attempt);
  //   //   } catch (e) {
  //   //     print("Failed to sync attempt ${attempt.id}: $e");
  //   //   }
  //   // }
  // }
 void _startTrialQuiz() async {
    showDialog(context: context, builder: (_) => const Center(child: CircularProgressIndicator()));
    try {
      final trialQuestions = await _hiveService.getTrialQuestions();
      if(mounted) Navigator.of(context).pop();
      
      if (trialQuestions.isNotEmpty) {
          Navigator.of(context).push(
              MaterialPageRoute(builder: (ctx) => TrialQuizScreen(questions: trialQuestions))
          );
      } else {
          throw Exception('سوالات آزمایشی یافت نشد. لطفا به اینترنت متصل شوید و برنامه را دوباره باز کنید.');
      }
    } catch (e) {
      if(mounted) Navigator.of(context).pop();
      if(mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString().replaceAll("Exception: ", ""))));
    }
  }
   Future<void> _loadFromLocalDb(String userId) async {
    final localCategories = await _hiveService.getCategories(userId);
    if (mounted) {
      setState(() { _categories = localCategories; _errorMessage = ''; });
    }
  }
  @override
  Widget build(BuildContext context) {
    
    return Consumer<AuthProvider>(
    builder: (context, authProvider, child) {
      
      final authProvider = Provider.of<AuthProvider>(context);
       final user = authProvider.user;
      final profileImageFile = user?.profileImagePath != null ? File(user!.profileImagePath!) : null;

      const tealColor = Color(0xFF008080);
      return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (ctx) => const TestSetupScreen())),
        label: const Text('ساخت آزمون سفارشی', style: TextStyle(color: Colors.white),),
        icon: const Icon(Icons.add_circle_outline, color:  Colors.white,),
        backgroundColor: tealColor,
      ),
      body: RefreshIndicator(
        onRefresh: _loadInitialData,
        child: CustomScrollView(
          slivers: [
            
      if (!widget.isPickerMode)
                  SliverAppBar(
                    backgroundColor: Theme.of(context).scaffoldBackgroundColor,
                     
                    floating: true, // با اسکرول به بالا، بلافاصله ظاهر می‌شود
                    elevation: 0,
                   
                    actions: [
                      Padding(
                        padding: const EdgeInsets.only(left: 0.0),
                        child: GestureDetector(
                          onTap: () {
                            // پیدا کردن آبجکت MainScreenState و تغییر تب به پروفایل
                            // این روش نیازمند این است که MainScreen State خود را expose کند
                            // یا از یک State Management بهتر مثل Riverpod استفاده کنیم.
                            // فعلا به صورت مستقیم به صفحه پروفایل می‌رویم.
                            Navigator.of(context).push(MaterialPageRoute(builder: (ctx) => const ProfileScreen()));
                          },
                          child: Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: CircleAvatar(
                              radius: 35,
                              backgroundImage: profileImageFile != null ? FileImage(profileImageFile) : null,
                              child: profileImageFile == null 
                                  ? Text(user?.name.isNotEmpty == true ? user!.name.substring(0, 1) : 'U', style: const TextStyle(fontSize: 20))
                                  : null,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                 SliverToBoxAdapter(
                  child: Padding(padding: EdgeInsets.symmetric(horizontal: 16),
                  
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(height: 10,),
                        const Text('سلام، خوش آمدید! ', style: TextStyle(fontSize: 18, color: Colors.grey, ), textDirection: TextDirection.rtl, textAlign: TextAlign.center,),
                        Text(user?.name ?? 'کاربر گرامی', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.black87)),
                    
                    ],
                  ),
                  )
                 ),
                 if (user != null && !widget.isPickerMode)
      SliverToBoxAdapter(child: Padding(
       padding: const EdgeInsets.all(16.0),
        child: _buildSubscriptionCard(context,user.isPremium, user.subscriptionExpiresAt),
      )),
            SliverToBoxAdapter(child: Padding(
             padding: const EdgeInsets.symmetric( horizontal: 16.0),
              child: _buildQuickStatsSection(),
            )),
       
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child:  _buildTrialQuizCard(),
              ),
            ),
            // -----------------------------

            const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 8.0),
                child: Text('دسته‌بندی‌های اصلی', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ),
            ),
            
            _isLoading
              ? const SliverToBoxAdapter(child: Center(child: Padding(padding: EdgeInsets.all(32.0), child: CircularProgressIndicator())))
              : _errorMessage.isNotEmpty
                ? SliverToBoxAdapter(child: Center(child: Padding(padding: const EdgeInsets.all(32.0), child: Text(_errorMessage, textAlign: TextAlign.center))))
                : SliverPadding(
                    padding: const EdgeInsets.fromLTRB(16.0, 8.0, 16.0, 80.0),
                  
                    sliver: SliverGrid(
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2, // ۲ ستون در موبایل
                        crossAxisSpacing: 16,
                        mainAxisSpacing: 16,
                        childAspectRatio: 1.2, // نسبت عرض به ارتفاع کارت‌ها
                      ),
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          return _buildCategoryCard(_categories[index]);
                        },
                        childCount: _categories.length,
                      ),
                    ),
                    // ------------------------------------
                  ),
          ],
        ),
      ),
      );
  });
  }

   Widget _buildSubscriptionCard(BuildContext context, bool isPremium,DateTime? expiryDate) {
     if (isPremium && expiryDate != null) {
         return _buildPremiumStatusCard(expiryDate);
    } else {
          return _buildPremiumCallToAction(context);
      }
   }
     Widget _buildPremiumStatusCard(DateTime expiryDate) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Card(
        color: Colors.green.shade50,
        elevation: 2,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              const Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Icon(Icons.check_circle, color: Colors.green),
                  SizedBox(width: 8),
                  Text('شما عضو ویژه هستید', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.green, fontSize: 16)),
                ],
              ),
              const SizedBox(height: 12),
              const Text('زمان باقی‌مانده از اشتراک شما:', textDirection: TextDirection.rtl,),
              const SizedBox(height: 8),
              
              // --- تایمر معکوس زنده ---
              TimerBuilder.periodic(
                const Duration(seconds: 1),
                builder: (context) {
                  final now = DateTime.now();
                  final remaining = expiryDate.difference(now);

                  if (remaining.isNegative) {
                    // اگر زمان تمام شده بود، به کاربر اطلاع بده و صفحه را رفرش کن
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      _loadInitialData(); // رفرش کردن وضعیت برای تبدیل به کاربر رایگان
                    });
                    return const Text('اشتراک شما به پایان رسیده است.', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red));
                  }

                  final days = remaining.inDays;
                  final hours = remaining.inHours % 24;
                  final minutes = remaining.inMinutes % 60;
                  final seconds = remaining.inSeconds % 60;
                  
                  return Text(
                    '$days روز و $hours ساعت و $minutes دقیقه و $seconds ثانیه',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'monospace', // برای نمایش بهتر اعداد
                      color: Color(0xFF004D40),
                    ),
                    textDirection: TextDirection.rtl,
                  );
                },
              )
        ]  )
          )
          )
          );

     }
   Widget _buildPremiumCallToAction(BuildContext context) {
     return Card(
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (ctx) => const PremiumScreen())),
          child: const Padding(
            padding: EdgeInsets.all(16.0),
            child: Row(
              children: [
                Icon(Icons.star_rounded, color: Colors.amber, size: 32),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('عضویت ویژه', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      Text('دسترسی نامحدود', style: TextStyle(color: Colors.grey, fontSize: 12)),
                    ],
                  ),
                ),
                Icon(Icons.arrow_forward_ios, color: Colors.grey, size: 16),
              ],
            ),
          ),
        ),
      );
   }
   Widget _buildCategoryCard(Category category) {
    const tealColor = Color(0xFF008080);
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () async {
          // استفاده صحیح از Navigator.push
          final List<Course>? result = await Navigator.of(context).push<List<Course>>(
            MaterialPageRoute(
              builder: (ctx) => CourseListScreen(
                category: category, 
                isPickerMode: widget.isPickerMode
              ),
            ),
          );
          
          if (widget.isPickerMode && result != null && result.isNotEmpty) {
            Navigator.of(context).pop(result);
          }
        },
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: tealColor.withOpacity(0.1),
                child: const Icon(Icons.school_rounded, color: tealColor, size: 28),
              ),
              const SizedBox(height: 12),
              Text(category.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16), textAlign: TextAlign.center),
            ],
          ),
        ),
      ),
    );
   }
    Widget _buildTrialQuizCard() {
     return Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: _startTrialQuiz,
          child: const Padding(
            padding: EdgeInsets.all(16.0),
            child: Row(
              children: [
                Icon(Icons.quiz_rounded, color: Color(0xFF008080), size: 32),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('آزمون آمادگی', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      Text('با ۱۰ سوال رایگان خود را بسنجید', style: TextStyle(color: Colors.grey, fontSize: 12)),
                    ],
                  ),
                ),
                Icon(Icons.arrow_forward_ios, color: Colors.grey, size: 16),
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
          return const SizedBox.shrink(); // اگر داده‌ای نبود، چیزی نشان نده
        }
        final history = snapshot.data!;
        final totalTests = history.length;
        final averageScore = history.map((h) => h.percentage).reduce((a, b) => a + b) / totalTests;

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Row(
            children: [
              Expanded(child: _buildStatCard('تعداد آزمون', totalTests.toString(), Icons.playlist_add_check_rounded, Colors.orange)),
              const SizedBox(width: 16),
              Expanded(child: _buildStatCard('میانگین نمره', '${averageScore.toStringAsFixed(0)}%', Icons.show_chart_rounded, Colors.green)),
            ],
          ),
        );
      }
    );
    
   }
   
  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Card(
      elevation: 0,
      color: color.withOpacity(0.1),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Row(
          children: [
            Icon(icon, size: 32, color: color),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                Text(title, style: const TextStyle(color: Colors.black54, fontSize: 12)),
              ],
            ),
          ],
        ),
      ),
    );
}}