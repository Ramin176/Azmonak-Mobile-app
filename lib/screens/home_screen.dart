import 'package:azmoonak_app/helpers/hive_db_service.dart';
import 'package:azmoonak_app/screens/trial_quiz_screen.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
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
      await authProvider.refreshUser();
      
      final user = authProvider.user;
      final token = authProvider.token;
      
      if (user != null && user.isPremium) {
        await _loadPremiumUserData(token);
      } else if (token != null) {
        await _loadFreeUserData(token);
      } else {
        throw Exception('کاربر وارد نشده است.');
      }
      final onlineCategories = await _apiService.fetchCategories(token!);
    } catch (e) {
      
      if (mounted) setState(() { _errorMessage = e.toString().replaceAll("Exception: ", ""); });
    } finally {
      if (mounted) setState(() { _isLoading = false; });
    }
  }

  Future<void> _loadPremiumUserData(String? token) async {
    final localCategories = await _hiveService.getCategories();
    if (mounted && localCategories.isNotEmpty) {
      setState(() { _categories = localCategories; });
    } else if (mounted && token != null) {
      // اگر دیتابیس محلی خالی بود، یک بار از سرور بگیر و به کاربر بگو دانلود کند
      final onlineCategories = await _apiService.fetchCategories(token);
      setState(() {
        _categories = onlineCategories;
        _errorMessage = 'برای استفاده آفلاین، لطفا داده‌ها را همگام‌سازی کنید.';
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
    if (connectivityResult == ConnectivityResult.none || !mounted) {
      if(showSuccessMessage) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('برای همگام‌سازی به اینترنت نیاز دارید.')));
      return;
    }
    
    final token = Provider.of<AuthProvider>(context, listen: false).token;
    if (token == null) return;

    if (mounted) setState(() { _isSyncing = true; });
    try {
      final onlineCategories = await _apiService.fetchCategories(token);
      await _hiveService.syncData<Category>(HiveService.categoriesBoxName, onlineCategories);
      
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

      await _hiveService.syncData<Course>(HiveService.coursesBoxName, allCourses);
      await _hiveService.syncData<Question>(HiveService.questionsBoxName, allQuestions);

      final latestCategories = await _hiveService.getCategories();
      if (mounted) {
        setState(() { _categories = latestCategories; _errorMessage = ''; });
        if(showSuccessMessage) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تمام محتوا با موفقیت برای دسترسی آفلاین ذخیره شد!')));
        }
      }
    } catch (e) {
      print("Sync Error: $e");
      if(mounted && showSuccessMessage) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('خطا در همگام‌سازی: $e')));
    } finally {
      if (mounted) setState(() { _isSyncing = false; });
    }
  }

  Future<void> _syncOfflineAttempts() async {
    final connectivityResult = await (Connectivity().checkConnectivity());
    if (connectivityResult == ConnectivityResult.none) return;
    
    final token = Provider.of<AuthProvider>(context, listen: false).token;
    if (token == null) return;
    
    final unsyncedAttempts = await _hiveService.getUnsyncedAttempts();
    if (unsyncedAttempts.isEmpty) return;
    
    print("Syncing ${unsyncedAttempts.length} offline quiz results...");
    for (var attempt in unsyncedAttempts) {
      try {
        // await _apiService.submitOfflineAttempt(attempt, token);
        await _hiveService.markAttemptAsSynced(attempt);
      } catch (e) {
        print("Failed to sync attempt ${attempt.id}: $e");
      }
    }
  }
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
  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final user = authProvider.user;
    const tealColor = Color(0xFF008080);

    return Consumer<AuthProvider>(
    builder: (context, authProvider, child) {
      final user = authProvider.user;
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
            SliverAppBar(
              backgroundColor: tealColor,
              expandedHeight: 150.0,
              pinned: true,
              flexibleSpace: FlexibleSpaceBar(
                title: Text('سلام، ${user?.name ?? 'کاربر'}!', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                background: Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(colors: [tealColor, Color(0xFF004D40)], begin: Alignment.topLeft, end: Alignment.bottomRight),
                  ),
                ),
              ),
            ),
            
            // --- بخش جدید: دسترسی‌های سریع ---
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    if (user != null && !user.isPremium) _buildPremiumCallToAction(context),
                    const SizedBox(height: 16),
                    _buildTrialQuizCard(),
                  ],
                ),
              ),
            ),
            // -----------------------------

            const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 8.0),
                child: Text('دسته‌بندی‌های اصلی', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
              ),
            ),
            
            _isLoading
              ? const SliverToBoxAdapter(child: Center(child: Padding(padding: EdgeInsets.all(32.0), child: CircularProgressIndicator())))
              : _errorMessage.isNotEmpty
                ? SliverToBoxAdapter(child: Center(child: Padding(padding: const EdgeInsets.all(32.0), child: Text(_errorMessage, textAlign: TextAlign.center))))
                : SliverPadding(
                    padding: const EdgeInsets.fromLTRB(16.0, 8.0, 16.0, 80.0),
                    // --- بخش جدید: استفاده از GridView ---
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

   Widget _buildSubscriptionCard(BuildContext context, bool isPremium) {
     if (isPremium) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
          child: Card(
            child: ListTile(
              leading: const Icon(Icons.cloud_done, color: Colors.green),
              title: const Text('شما عضو ویژه هستید'),
              subtitle: const Text('برای استفاده آفلاین، داده‌ها را همگام‌سازی کنید.'),
              trailing: _isSyncing 
                ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2))
                : IconButton(
                    icon: const Icon(Icons.sync),
                    onPressed: _syncAllPremiumContent,
                    tooltip: 'همگام‌سازی مجدد',
                  ),
            ),
          ),
        );
      } else {
          return _buildPremiumCallToAction(context);
      }
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
   }
   