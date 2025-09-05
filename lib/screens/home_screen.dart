import 'package:azmoonak_app/helpers/hive_db_service.dart';
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
        floatingActionButton: widget.isPickerMode ? null : FloatingActionButton.extended(
          onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (ctx) => const TestSetupScreen())),
          label: const Text('ساخت آزمون جدید'),
          icon: const Icon(Icons.add),
          backgroundColor: tealColor,
        ),
        body: RefreshIndicator(
            onRefresh: _loadInitialData, 
          child: CustomScrollView(
            slivers: [
              if (!widget.isPickerMode)
                SliverAppBar(
                  backgroundColor: tealColor, expandedHeight: 200.0, pinned: true,
                  flexibleSpace: FlexibleSpaceBar(
                    title: Text('سلام، ${user?.name ?? ''}!', style: const TextStyle(fontSize: 16)),
                    background: Container(
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(colors: [tealColor, Color(0xFF004D40)], begin: Alignment.topLeft, end: Alignment.bottomRight),
                      ),
                    ),
                  ),
                ),
              
              if (user != null && !widget.isPickerMode)
                SliverToBoxAdapter(child: _buildSubscriptionCard(context, user.isPremium)),
              
              const SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.fromLTRB(16.0, 24.0, 16.0, 8.0),
                  child: Text('دسته‌بندی آزمون‌ها', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                ),
              ),
              
              _isLoading
                ? const SliverToBoxAdapter(child: Center(child: Padding(padding: EdgeInsets.all(32.0), child: CircularProgressIndicator())))
                : _errorMessage.isNotEmpty
                  ? SliverToBoxAdapter(child: Center(child: Padding(padding: const EdgeInsets.all(32.0), child: Text(_errorMessage, textAlign: TextAlign.center))))
                  : _categories.isEmpty
                    ? const SliverToBoxAdapter(child: Center(child: Padding(padding: EdgeInsets.all(32.0), child: Text('هیچ دوره‌ای یافت نشد.'))))
                    : SliverPadding(
                        padding: const EdgeInsets.fromLTRB(16.0, 8.0, 16.0, 80.0),
                        sliver: SliverList(
                          delegate: SliverChildBuilderDelegate(
                            (context, index) {
                              return Card(
                                child: ListTile(
                                  title: Text(_categories[index].name, style: const TextStyle(fontWeight: FontWeight.bold)),
                                  trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                                  onTap: () async {
                                    final List<Course>? result = await Navigator.of(context).push<List<Course>>(
                                      MaterialPageRoute(
                                        builder: (ctx) => CourseListScreen(category: _categories[index], isPickerMode: widget.isPickerMode),
                                      ),
                                    );
                                    if (widget.isPickerMode && result != null && result.isNotEmpty) {
                                      Navigator.of(context).pop(result);
                                    }
                                  },
                                ),
                              );
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
     return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Card(
        elevation: 4,
        child: InkWell(
          onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (ctx) => const PremiumScreen())),
          child: Container(
            padding: const EdgeInsets.all(16.0),
            child: const Row(
              children: [
                Icon(Icons.star, color: Colors.amber, size: 40),
                SizedBox(width: 16),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('عضویت ویژه', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    Text('دسترسی نامحدود به همه سوالات', style: TextStyle(color: Colors.grey)),
                ],)),
                Icon(Icons.arrow_forward_ios),
              ],
            ),
          ),
        ),
      ),
    );
   }
}