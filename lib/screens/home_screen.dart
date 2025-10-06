import 'dart:async';
import 'dart:io';
import 'package:azmoonak_app/helpers/adaptive_text_size.dart';
import 'package:azmoonak_app/helpers/hive_db_service.dart';
import 'package:azmoonak_app/models/purchased_subject.dart';
import 'package:azmoonak_app/models/quiz_attempt.dart';
import 'package:azmoonak_app/models/subject.dart';
import 'package:azmoonak_app/models/user.dart';
import 'package:azmoonak_app/screens/deactivated_screen.dart';
import 'package:azmoonak_app/screens/profile_screen.dart';
import 'package:azmoonak_app/screens/trial_quiz_screen.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timer_builder/timer_builder.dart';
import '../providers/auth_provider.dart';
import '../services/api_service.dart';
import '../models/question.dart';
import 'premium_screen.dart';
import 'test_setup_screen.dart';

class HomeScreen extends StatefulWidget {
  final bool isPickerMode;
  const HomeScreen({super.key, this.isPickerMode = false});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with WidgetsBindingObserver {

  final ApiService _apiService = ApiService();
  final HiveService _hiveService = HiveService();
  bool _isSyncing = false; 
  List<Subject> _subjectTree = [];
  bool _isLoading = true;
  String _errorMessage = '';
  bool _isInit = true;
  // --- پالت رنگی ---
  static const Color primaryTeal = Color(0xFF008080);
  static const Color lightTeal = Color(0xFF4DB6AC);
  static const Color darkTeal = Color(0xFF004D40);
  static const Color accentYellow = Color(0xFFFFD700);
  static const Color textDark = Color(0xFF212121);
  static const Color textMedium = Color(0xFF607D8B);
  static const Color backgroundLight = Color(0xFFF8F9FA);

  @override
  void initState() {
    super.initState();
   WidgetsBinding.instance.addObserver(this); // ثبت ناظر
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadInitialData();
       _syncPremiumContentIfNeeded(); 
       
    });
  }
@override
void dispose() {
  // این خط بسیار مهم است
  WidgetsBinding.instance.removeObserver(this); // حذف ناظر
  super.dispose();
}
  Future<void> _syncPremiumContentIfNeeded() async {
    // این همگام‌سازی فقط برای کاربران ویژه است
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final user = authProvider.user;
    if (user == null || !user.isPremium) {
      print("همگام‌سازی خودکار ویژه لغو شد: کاربر وارد نشده یا ویژه نیست.");
      return;
    }
    
    // ۱. دریافت SharedPreferences
    final prefs = await SharedPreferences.getInstance();
    
    // ۲. خواندن تاریخ آخرین همگام‌سازی
    // ما از یک کلید منحصر به فرد برای هر کاربر استفاده می‌کنیم
    final lastSyncString = prefs.getString('lastPremiumSync_${user.id}');
    
    // ۳. بررسی شرط زمانی (مثلاً ۷ روز)
    bool shouldSync = true; // به صورت پیش‌فرض همگام‌سازی می‌کنیم
    if (lastSyncString != null) {
      final lastSyncDate = DateTime.parse(lastSyncString);
      // اگر کمتر از ۷ روز از آخرین همگام‌سازی گذشته باشد، نیازی به همگام‌سازی جدید نیست
      if (DateTime.now().difference(lastSyncDate).inMinutes < 2) {
        shouldSync = false;
      }
    }

    if (!shouldSync) {
      print("همگام‌سازی خودکار ویژه لازم نیست (کمتر از ۷ روز از آخرین همگام‌سازی گذشته).");
      return;
    }

    // ۴. اگر نیاز به همگام‌سازی بود، اتصال اینترنت را بررسی کن
    final connectivityResult = await (Connectivity().checkConnectivity());
    if (connectivityResult == ConnectivityResult.none) {
      print("همگام‌سازی خودکار ویژه لغو شد: اتصال به اینترنت برقرار نیست.");
      return;
    }

    // ۵. اگر تمام شرایط برقرار بود، همگام‌سازی را در پس‌زمینه شروع کن
    print("شروع همگام‌سازی خودکار محتوای ویژه در پس‌زمینه...");
    
    // برای جلوگیری از نمایش لودینگ و مزاحمت برای کاربر،
    // ما وضعیت isSyncing را در اینجا تغییر نمی‌دهیم.
    // این عملیات کاملاً در سکوت انجام می‌شود.
    try {
      final token = authProvider.token!;
      final onlineTree = await _apiService.fetchSubjectTree();
      final flatList = _flattenTree(onlineTree);
      
      // همگام‌سازی لیست موضوعات
      await _hiveService.syncData<Subject>('subjects', flatList, user.id);
      
      // همگام‌سازی تمام سوالات
      List<Question> allQuestions = [];
      for (var subject in flatList) {
        // فقط برای موضوعات نهایی (که فرزند ندارند) سوالات را بگیر
        if (subject.children.isEmpty) { 
          final questions = await _apiService.fetchAllQuestionsForSubject(subject.id, token);
          allQuestions.addAll(questions);
        }
      }
      await _hiveService.syncData<Question>('questions', allQuestions, user.id);
      
      // ۶. پس از موفقیت، تاریخ جدید را ذخیره کن
      await prefs.setString('lastPremiumSync_${user.id}', DateTime.now().toIso8601String());
      
      print("همگام‌سازی خودکار محتوای ویژه با موفقیت به پایان رسید.");

    } catch (e) {
      print("خطا در هنگام همگام‌سازی خودکار محتوای ویژه: $e");
      // در صورت خطا، ما تاریخ را آپدیت نمی‌کنیم تا در اجرای بعدی دوباره تلاش شود.
    }
  }

Future<void> _loadInitialData() async {
  if (!mounted) return;
  setState(() { _isLoading = true; _errorMessage = ''; });

  try {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
     await authProvider.refreshUser(); 

if (authProvider.isDeactivated) {
      // اگر در حین رفرش متوجه شدیم کاربر غیرفعال شده،
      // او را به صفحه DeactivatedScreen هدایت کن
      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (ctx) => DeactivatedScreen()),
          (route) => false, // تمام صفحات قبلی را حذف کن
        );
      }
      return; // ادامه تابع را اجرا نکن
    }
    print("state: ${authProvider.isDeactivated}");
    final user = authProvider.user;

    if (user == null) {
      // حالت بدون کاربر (مثلاً در صفحه انتخاب)
      _subjectTree = await _apiService.fetchSubjectTree();
      if (mounted) setState(() { _isLoading = false; });
      return;
    }
    
    // --- منطق جدید و کامل ---
    try {
      // ما همیشه ابتدا تلاش می‌کنیم از اینترنت بخوانیم
      print("Attempting to fetch data from API...");
      final onlineTree = await _apiService.fetchSubjectTree();
      if (mounted) {
        setState(() {
          _subjectTree = onlineTree;
          _errorMessage = ''; // پاک کردن پیام خطای آفلاین قبلی
        });
      }
      // اگر موفق شدیم، داده‌ها را در پس‌زمینه در Hive ذخیره می‌کنیم
      await _hiveService.syncData<Subject>('subjects', _flattenTree(onlineTree), user.id);
      print("Online data fetched and cached successfully.");
    } on SocketException catch (e) {
      // اگر خطای شبکه رخ داد (مثلاً Network Unreachable)
      print("Network error (SocketException) detected. Falling back to local DB. Error: $e");
      await _loadFromLocalDb(user.id, errorFromOnline: true);
    } catch (e) {
      // اگر خطای دیگری رخ داد (مثلاً خطای سرور 500)
      print("Other API error detected. Falling back to local DB. Error: $e");
      await _loadFromLocalDb(user.id, errorFromOnline: true);
    }
    // ----------------------

  } catch (e) {
    if (mounted) _errorMessage = "خطای کلی: ${e.toString()}";
  } finally {
    if (mounted) setState(() { _isLoading = false; });
  }
}
 Future<void> _loadFromLocalDb(String userId, {bool errorFromOnline = false}) async {
  final localSubjects = await _hiveService.getSubjects(userId);
  if (mounted) {
    if (localSubjects.isNotEmpty) {
      // اگر دیتای محلی وجود داشت
      setState(() {
        _subjectTree = _buildTreeFromFlatList(localSubjects);
        // کلید حل مشکل: متغیر خطا را خالی می‌کنیم تا لیست نمایش داده شود
        _errorMessage = ''; 
      });
    } else {
      // اگر هیچ دیتای محلی برای نمایش وجود نداشت، آنگاه خطا نمایش می‌دهیم
      setState(() { 
        _subjectTree = []; // اطمینان از خالی بودن لیست
        _errorMessage = 'هیچ داده‌ای برای نمایش آفلاین وجود ندارد. لطفا به اینترنت متصل شوید.'; 
      });
    }
  }
}
  // List<Subject> _flattenTree(List<Subject> tree) {
  //   List<Subject> flatList = [];
  //   for (var node in tree) {
  //     flatList.add(Subject(id: node.id, name: node.name, parent: node.parent, price: node.price, children: []));
  //     if (node.children.isNotEmpty) {
  //       flatList.addAll(_flattenTree(node.children));
  //     }
  //   }
  //   return flatList;
  // }
  
List<Subject> _flattenTree(List<Subject> tree) {
  List<Subject> flatList = [];
  for (var node in tree) {
    // ما یک کپی از نود ایجاد می‌کنیم اما فرزندان آن را خالی می‌گذاریم
    // تا فقط رابطه والد-فرزند از طریق فیلد `parent` ذخیره شود.
    flatList.add(
      Subject(
        id: node.id,
        name: node.name,
        parent: node.parent,
        price: node.price,
        children: [], // همیشه خالی
      )
    );
    // به صورت بازگشتی روی فرزندان واقعی تکرار می‌کنیم
    if (node.children.isNotEmpty) {
      flatList.addAll(_flattenTree(node.children));
    }
  }
  return flatList;
}

  // List<Subject> _buildTreeFromFlatList(List<Subject> flatList) {
  //   for (var sub in flatList) { sub.children = []; }
  //   Map<String, Subject> map = {for (var sub in flatList) sub.id: sub};
  //   List<Subject> tree = [];
  //   for (var sub in flatList) {
  //     if (sub.parent != null && map.containsKey(sub.parent)) {
  //       map[sub.parent]!.children.add(sub);
  //     } else {
  //       tree.add(sub);
  //     }
  //   }
  //   return tree;
  // }
  
List<Subject> _buildTreeFromFlatList(List<Subject> flatList) {
  // ۱. یک کپی از لیست ایجاد می‌کنیم تا لیست اصلی تغییر نکند
  final List<Subject> subjectsCopy = flatList.map((s) => 
    Subject(id: s.id, name: s.name, parent: s.parent, price: s.price, children: [])
  ).toList();

  // ۲. یک Map برای دسترسی سریع به نودها بر اساس ID می‌سازیم
  Map<String, Subject> map = {for (var sub in subjectsCopy) sub.id: sub};
  
  // ۳. لیست نهایی درخت را آماده می‌کنیم
  List<Subject> tree = [];

  for (var sub in subjectsCopy) {
    if (sub.parent != null && map.containsKey(sub.parent)) {
      // اگر نود والد داشت، آن را به لیست فرزندان والدش اضافه کن
      map[sub.parent]!.children.add(sub);
    } else {
      // اگر نود والد نداشت، این یک نود ریشه است
      tree.add(sub);
    }
  }
  return tree;
}
 Future<void> _syncAllPremiumContent({bool showSuccessMessage = true}) async {
    if (_isSyncing) return;
    
    final connectivityResult = await (Connectivity().checkConnectivity());
    if (connectivityResult == ConnectivityResult.none) {
      if (showSuccessMessage && mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('برای همگام‌سازی به اینترنت نیاز دارید.')));
      return;
    }
    
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final user = authProvider.user;
    final token = authProvider.token;
    if (user == null || token == null || !user.isPremium) return;

    if (mounted) setState(() { _isSyncing = true; });
    try {
      final onlineTree = await _apiService.fetchSubjectTree();
      final flatList = _flattenTree(onlineTree);
      
      await _hiveService.syncData<Subject>('subjects', flatList, user.id);
      
      List<Question> allQuestions = [];
      for (var subject in flatList) {
        if (subject.children.isEmpty) { 
          final questions = await _apiService.fetchAllQuestionsForSubject(subject.id, token);
          allQuestions.addAll(questions);
        }
      }
      await _hiveService.syncData<Question>('questions', allQuestions, user.id);
      
      if (mounted) {
        setState(() { _subjectTree = onlineTree; _errorMessage = ''; });
        if (showSuccessMessage) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('همگام‌سازی کامل با موفقیت انجام شد!')));
        }
      }
    } catch (e) {
      print("Sync Error: $e");
      if (mounted && showSuccessMessage) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('خطا در همگام‌سازی: ${e.toString()}')));
    } finally {
      if (mounted) setState(() { _isSyncing = false; });
    }
  }
  
  void _startTrialQuiz() async {
    showDialog(context: context, builder: (_) => const Center(child: CircularProgressIndicator()));
    try {
      final trialQuestions = await _hiveService.getTrialQuestions();
      if (mounted) Navigator.of(context, rootNavigator: true).pop();
      if (trialQuestions.isNotEmpty) {
        Navigator.of(context).push(MaterialPageRoute(builder: (ctx) => TrialQuizScreen(questions: trialQuestions)));
      } else {
        throw Exception('سوالات آزمایشی یافت نشد. لطفا به اینترنت متصل شوید و برنامه را دوباره باز کنید.');
      }
    } catch (e) {
      if (mounted) {
        Navigator.of(context, rootNavigator: true).pop();
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString().replaceAll("Exception: ", ""))));
      }
    }
  }


  void _onSubjectTap(Subject subject) {
    if (widget.isPickerMode) {
      if (subject.children.isNotEmpty) {
        // در حالت انتخاب، با کلیک روی دسته اصلی، وارد آن می‌شویم
        Navigator.of(context).push(MaterialPageRoute(
          builder: (ctx) => SubCategoryScreen(category: subject, isPickerMode: true),
        )).then((result){
          // اگر از صفحه زیرمجموعه نتیجه‌ای برگشت، آن را به BottomSheet برمی‌گردانیم
          if (result != null && result is List<Subject> && result.isNotEmpty){
             Navigator.of(context).pop(result);
          }
        });
      } else {
        // با کلیک روی موضوع نهایی، آن را به عنوان نتیجه BottomSheet برمی‌گردانیم
        Navigator.of(context).pop([subject]);
      }
    } else {
      // منطق حالت عادی
      if (subject.children.isNotEmpty) {
        Navigator.of(context).push(MaterialPageRoute(
          builder: (ctx) => SubCategoryScreen(category: subject, isPickerMode: false),
        ));
      } else {
        Navigator.of(context).push(MaterialPageRoute(
          builder: (ctx) => TestSetupScreen(preselectedSubject: subject),
        ));
      }
    }
  }

  // --- توابع کمکی برای UI ---
  double _getResponsiveValue(double baseSize) {
    const double referenceWidth = 375.0;
    final double screenWidth = MediaQuery.of(context).size.width;
    double scaleFactor = screenWidth / referenceWidth;
    if (scaleFactor > 1.5) scaleFactor = 1.5;
    return baseSize * scaleFactor;
  }
  
  TextStyle _responsiveTextStyle(double baseFontSize, {Color color = textDark, FontWeight fontWeight = FontWeight.normal}) {
    return TextStyle(
      fontSize: _getResponsiveValue(baseFontSize),
      color: color,
      fontWeight: fontWeight,
      fontFamily: 'Vazirmatn'
    );
  }

  // --- ویجت اصلی Build ---
  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(builder: (context, authProvider, child) {
      final user = authProvider.user;
      final profileImageFile = user?.profileImagePath != null ? File(user!.profileImagePath!) : null;

      // در حالت انتخاب، یک UI ساده‌تر فقط برای انتخاب نمایش داده می‌شود
      if(widget.isPickerMode){
        return _buildPickerUI();
      }

      // حالت عادی نمایش صفحه اصلی
      return Scaffold(
        backgroundColor: backgroundLight,
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (ctx) => const TestSetupScreen())),
          label: Text('ساخت آزمون سفارشی', style: _responsiveTextStyle(14, color: Colors.white, fontWeight: FontWeight.bold)),
          icon: Icon(Icons.add_circle_outline, color: Colors.white, size: _getResponsiveValue(24)),
          backgroundColor: primaryTeal,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(_getResponsiveValue(30))),
          elevation: 6,
        ),
        body: RefreshIndicator(
          onRefresh: _loadInitialData,
          color: primaryTeal,
          child: CustomScrollView(
            slivers: [
              SliverToBoxAdapter(child: _buildHeader(profileImageFile, user)),
              SliverPadding(
                padding: EdgeInsets.fromLTRB(16, _getResponsiveValue(20), 16, 8),
                sliver: SliverToBoxAdapter(child: _buildSubscriptionCard(context, user)),
              ),
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                sliver: SliverToBoxAdapter(child: _buildQuickStatsSection()),
              ),
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                sliver: SliverToBoxAdapter(child: _buildTrialQuizCard()),
              ),
              SliverToBoxAdapter(child: _buildCategoryListHeader()),
              _buildCategorySliverList(),
            ],
          ),
        ),
      );
    });
  }

    @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    // هر زمان که اپلیکیشن به حالت فعال برگشت، اطلاعات را دوباره بارگذاری کن
    if (state == AppLifecycleState.resumed) {
      print("برنامه به حالت فعال بازگشت. در حال تازه‌سازی اطلاعات...");
      _loadInitialData();
    }
  }
  
  // --- ویجت‌های کمکی کامل ---

  Widget _buildPickerUI(){
     return Column(
       children: [
         // هدر برای BottomSheet
         Padding(
           padding: const EdgeInsets.all(16.0),
           child: Row(
             mainAxisAlignment: MainAxisAlignment.spaceBetween,
             children: [
               Text('انتخاب موضوع', style: _responsiveTextStyle(20, fontWeight: FontWeight.bold)),
               IconButton(
                 icon: const Icon(Icons.close),
                 onPressed: () => Navigator.of(context).pop(),
               )
             ],
           ),
         ),
         const Divider(height: 1),
         Expanded(
           child: _buildCategoryListBody(),
         ),
       ],
     );
  }

  Widget _buildCategoryListHeader() {
    return Padding(
      padding: EdgeInsets.fromLTRB(16, _getResponsiveValue(32), 16, 16),
      child: Text(
        'دسته‌بندی‌ها',
        style: _responsiveTextStyle(22, fontWeight: FontWeight.bold),
      ),
    );
  }
  
  Widget _buildCategoryListBody(){
     if (_isLoading) {
       return const Center(child: CircularProgressIndicator(color: primaryTeal));
     }
     if(_errorMessage.isNotEmpty){
       return Center(child: Padding(padding: EdgeInsets.all(_getResponsiveValue(32)), child: Text(_errorMessage, textAlign: TextAlign.center, style: _responsiveTextStyle(15, color: Colors.red.shade700))));
     }
     if(_subjectTree.isEmpty){
       return Center(child: Padding(padding: EdgeInsets.all(_getResponsiveValue(32)), child: Text('هیچ دسته‌بندی یافت نشد.', style: _responsiveTextStyle(16))));
     }
     return ListView.builder(
       padding: EdgeInsets.fromLTRB(16, 8, 16, _getResponsiveValue(80)),
       itemCount: _subjectTree.length,
       itemBuilder: (context, index) {
         return SubjectTile(
           subject: _subjectTree[index],
           onTap: () => _onSubjectTap(_subjectTree[index]),
         );
       },
     );
  }
  
  Widget _buildCategorySliverList(){
    if (_isLoading) {
       return SliverToBoxAdapter(child: Center(child: Padding(padding: EdgeInsets.all(_getResponsiveValue(32)), child: const CircularProgressIndicator(color: primaryTeal))));
     }
     if(_errorMessage.isNotEmpty){
       return SliverToBoxAdapter(child: Center(child: Padding(padding: EdgeInsets.all(_getResponsiveValue(32)), child: Text(_errorMessage, textAlign: TextAlign.center, style: _responsiveTextStyle(15, color: Colors.red.shade700)))));
     }
     if(_subjectTree.isEmpty){
       return SliverToBoxAdapter(child: Center(child: Padding(padding: EdgeInsets.all(_getResponsiveValue(32)), child: Text('هیچ دسته‌بندی یافت نشد.', style: _responsiveTextStyle(16)))));
     }
     return SliverPadding(
        padding: EdgeInsets.fromLTRB(16, 8, 16, _getResponsiveValue(80)),
        sliver: SliverList(
          delegate: SliverChildBuilderDelegate(
            (context, index) {
              return SubjectTile(
                subject: _subjectTree[index],
                onTap: () => _onSubjectTap(_subjectTree[index]),
              );
            },
            childCount: _subjectTree.length,
          ),
        ),
      );
  }

  Widget _buildHeader(File? profileImageFile, AppUser? user) {
    final double screenHeight = MediaQuery.of(context).size.height;
    return Stack(
      children: [
        Container(
          height: screenHeight * 0.25,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [primaryTeal, lightTeal.withOpacity(0.8)],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
            borderRadius: BorderRadius.vertical(bottom: Radius.circular(_getResponsiveValue(30))),
          ),
        ),
        Padding(
          padding: EdgeInsets.only(
            top: MediaQuery.of(context).padding.top + _getResponsiveValue(10),
            left: _getResponsiveValue(16.0),
            right: _getResponsiveValue(16.0),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  GestureDetector(
                    onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (ctx) => const ProfileScreen())),
                    child: Hero(
                      tag: 'profileImage',
                      child: CircleAvatar(
                        radius: _getResponsiveValue(24),
                        backgroundColor: Colors.white.withOpacity(0.3),
                        backgroundImage: profileImageFile != null ? FileImage(profileImageFile) : null,
                        child: profileImageFile == null
                            ? Text(
                                user?.name.isNotEmpty == true ? user!.name.substring(0, 1) : 'U',
                                style: _responsiveTextStyle(22, color: Colors.white, fontWeight: FontWeight.bold),
                              )
                            : null,
                      ),
                    ),
                  ),
                  Text(
                    "آزمونک طبی",
                    style: _responsiveTextStyle(28, color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                    IconButton(
      icon: Icon(_isSyncing ? Icons.sync : Icons.sync_disabled, color: Colors.white),
      onPressed: _isSyncing ? null : () => _syncAllPremiumContent(showSuccessMessage: true),
    ),
         
                ],
              ),
              SizedBox(height: _getResponsiveValue(25)),
              Text(
                'سلام،',
                style: _responsiveTextStyle(20, color: Colors.white.withOpacity(0.9)),
              ),
              Text(
                user?.name ?? 'کاربر گرامی',
                style: _responsiveTextStyle(28, color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSubscriptionCard(BuildContext context, AppUser? user) {
    if (user == null) return _buildPremiumCallToAction(context);
    final activeSubscription = user.purchasedSubjects.firstWhere(
      (sub) => sub.expiresAt.isAfter(DateTime.now()),
      orElse: () => PurchasedSubject(subjectId: '', expiresAt: DateTime.now()),
    );
    if (activeSubscription.subjectId.isNotEmpty) {
      return _buildPremiumStatusCard(activeSubscription.expiresAt);
    } else {
      return _buildPremiumCallToAction(context);
    }
  }

  Widget _buildPremiumStatusCard(DateTime expiryDate) {
    return Card(
      color: Colors.white,
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(_getResponsiveValue(20))),
      child: Container(
        padding: EdgeInsets.all(_getResponsiveValue(20.0)),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(_getResponsiveValue(20)),
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
                Icon(Icons.workspace_premium_rounded, color: primaryTeal, size: _getResponsiveValue(30)),
                SizedBox(width: _getResponsiveValue(10)),
                Text('شما عضو ویژه هستید', style: _responsiveTextStyle(17, color: primaryTeal, fontWeight: FontWeight.bold)),
              ],
            ),
            SizedBox(height: _getResponsiveValue(16)),
            Text('زمان باقی‌مانده از اشتراک شما:', style: _responsiveTextStyle(13, color: textMedium)),
            SizedBox(height: _getResponsiveValue(10)),
            TimerBuilder.periodic(
              const Duration(seconds: 1),
              builder: (context) {
                final now = DateTime.now();
                final remaining = expiryDate.difference(now);
                if (remaining.isNegative) {
                  WidgetsBinding.instance.addPostFrameCallback((_) => _loadInitialData());
                  return Text('اشتراک شما به پایان رسیده است.', style: _responsiveTextStyle(16, color: Colors.red, fontWeight: FontWeight.bold));
                }
                final days = remaining.inDays;
                final hours = remaining.inHours % 24;
                final minutes = remaining.inMinutes % 60;
                final seconds = remaining.inSeconds % 60;
                return Text('$days روز و $hours ساعت و $minutes دقیقه و $seconds ثانیه', style: _responsiveTextStyle(19, color: darkTeal, fontWeight: FontWeight.bold));
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
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(_getResponsiveValue(20))),
      child: InkWell(
        borderRadius: BorderRadius.circular(_getResponsiveValue(20)),
        onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (ctx) => const PremiumScreen())),
        child: Container(
          padding: EdgeInsets.all(_getResponsiveValue(20.0)),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(_getResponsiveValue(20)),
            gradient: LinearGradient(colors: [accentYellow.withOpacity(0.1), Colors.white], begin: Alignment.topLeft, end: Alignment.bottomRight),
          ),
          child: Row(
            children: [
              Icon(Icons.star_rounded, color: accentYellow, size: _getResponsiveValue(36)),
              SizedBox(width: _getResponsiveValue(16)),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('عضویت ویژه', style: _responsiveTextStyle(18, fontWeight: FontWeight.bold)),
                    Text('دسترسی نامحدود به تمامی امکانات', style: _responsiveTextStyle(14, color: textMedium)),
                  ],
                ),
              ),
              Icon(Icons.arrow_forward_ios_rounded, color: textMedium.withOpacity(0.7), size: _getResponsiveValue(20)),
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildTrialQuizCard() {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(_getResponsiveValue(20))),
      child: InkWell(
        borderRadius: BorderRadius.circular(_getResponsiveValue(20)),
        onTap: _startTrialQuiz,
        child: Container(
          padding: EdgeInsets.all(_getResponsiveValue(20.0)),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(_getResponsiveValue(20)),
            gradient: LinearGradient(colors: [lightTeal.withOpacity(0.1), Colors.white], begin: Alignment.bottomRight, end: Alignment.topLeft),
          ),
          child: Row(
            children: [
              Icon(Icons.quiz_rounded, color: primaryTeal, size: _getResponsiveValue(36)),
              SizedBox(width: _getResponsiveValue(16)),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('آزمون آمادگی رایگان', style: _responsiveTextStyle(18, fontWeight: FontWeight.bold)),
                    Text('با ۱۰ سوال رایگان خود را بسنجید', style: _responsiveTextStyle(14, color: textMedium)),
                  ],
                ),
              ),
              Icon(Icons.arrow_forward_ios_rounded, color: textMedium.withOpacity(0.7), size: _getResponsiveValue(20)),
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
        if (!snapshot.hasData || snapshot.data!.isEmpty) return const SizedBox.shrink();
        final history = snapshot.data!;
        final totalTests = history.length;
        final averageScore = history.map((h) => h.percentage).reduce((a, b) => a + b) / totalTests;
        return Row(
          children: [
            Expanded(child: _buildStatCard('تعداد آزمون‌ها', totalTests.toString(), Icons.fact_check_rounded, Colors.orange.shade700)),
            SizedBox(width: _getResponsiveValue(16)),
            Expanded(child: _buildStatCard('میانگین نمره', '${averageScore.toStringAsFixed(0)}%', Icons.analytics_outlined, Colors.green.shade700)),
          ],
        );
      },
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(_getResponsiveValue(20))),
      color: Colors.white,
      child: Container(
        padding: EdgeInsets.all(_getResponsiveValue(16.0)),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(_getResponsiveValue(20)),
          gradient: LinearGradient(colors: [color.withOpacity(0.05), Colors.white], begin: Alignment.bottomLeft, end: Alignment.topRight),
        ),
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.all(_getResponsiveValue(10)),
              decoration: BoxDecoration(color: color.withOpacity(0.15), borderRadius: BorderRadius.circular(_getResponsiveValue(15))),
              child: Icon(icon, size: _getResponsiveValue(30), color: color),
            ),
            SizedBox(width: _getResponsiveValue(12)),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(value, style: _responsiveTextStyle(22, fontWeight: FontWeight.bold)),
                  Text(title, style: _responsiveTextStyle(13, color: textMedium), maxLines: 1, overflow: TextOverflow.ellipsis),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ====================================================================
// ==== صفحه زیرمجموعه‌ها (SubCategoryScreen) ====
// ====================================================================
class SubCategoryScreen extends StatelessWidget {
  final Subject category;
  final bool isPickerMode;

  const SubCategoryScreen({
    super.key, 
    required this.category,
    this.isPickerMode = false,
  });

  void _onSubjectTap(BuildContext context, Subject subject) async {
    if (isPickerMode) {
      if (subject.children.isNotEmpty) {
        // اگر دسته اصلی بود، منتظر نتیجه از صفحه بعدی بمان
        final result = await Navigator.of(context).push<List<Subject>>(
          MaterialPageRoute(
            builder: (ctx) => SubCategoryScreen(category: subject, isPickerMode: true),
          ),
        );
        // اگر از صفحه بعدی نتیجه‌ای برگشت، آن را به صفحه قبلی پاس بده
        if (result != null && result.isNotEmpty && context.mounted) {
          Navigator.of(context).pop(result);
        }
      } else {
        // اگر موضوع نهایی بود، آن را به عنوان نتیجه برگردان
        Navigator.of(context).pop([subject]);
      }
    } else {
      // منطق حالت عادی
      if (subject.children.isNotEmpty) {
        Navigator.of(context).push(MaterialPageRoute(
          builder: (ctx) => SubCategoryScreen(category: subject, isPickerMode: false),
        ));
      } else {
        Navigator.of(context).push(MaterialPageRoute(
          builder: (ctx) => TestSetupScreen(preselectedSubject: subject),
        ));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _HomeScreenState.backgroundLight,
      appBar: AppBar(
        title: Text(category.name, style: const TextStyle(fontFamily: 'Vazirmatn', fontWeight: FontWeight.bold)),
        backgroundColor: _HomeScreenState.primaryTeal,
        foregroundColor: Colors.white,
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16.0),
        itemCount: category.children.length,
        itemBuilder: (context, index) {
          final subCategory = category.children[index];
          return SubjectTile(
            subject: subCategory,
            onTap: () => _onSubjectTap(context, subCategory),
          );
        },
      ),
    );
  }
}

// ====================================================================
// ==== ویجت تایل موضوع (SubjectTile) ====
// ====================================================================
class SubjectTile extends StatelessWidget {
  final Subject subject;
  final VoidCallback onTap;

  const SubjectTile({super.key, required this.subject, required this.onTap});

  double _getResponsiveValue(BuildContext context, double baseSize) {
    const double referenceWidth = 375.0;
    final double screenWidth = MediaQuery.of(context).size.width;
    double scaleFactor = screenWidth / referenceWidth;
    if (scaleFactor > 1.5) scaleFactor = 1.5;
    return baseSize * scaleFactor;
  }
  
  TextStyle _responsiveTextStyle(BuildContext context, double baseFontSize, {Color color = _HomeScreenState.textDark, FontWeight fontWeight = FontWeight.normal}) {
    return TextStyle(
      fontSize: _getResponsiveValue(context, baseFontSize),
      color: color,
      fontWeight: fontWeight,
      fontFamily: 'Vazirmatn'
    );
  }

  @override
  Widget build(BuildContext context) {
    bool isCategory = subject.children.isNotEmpty;
    return Card(
      elevation: 3,
      margin: const EdgeInsets.symmetric(vertical: 6),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(_getResponsiveValue(context, 15))),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        borderRadius: BorderRadius.circular(_getResponsiveValue(context, 15)),
        onTap: onTap,
        child: Container(
          padding: EdgeInsets.all(_getResponsiveValue(context, 16)),
          decoration: isCategory 
            ? BoxDecoration(
                gradient: LinearGradient(
                  colors: [_HomeScreenState.primaryTeal.withOpacity(0.05), Colors.white],
                  begin: Alignment.bottomLeft,
                  end: Alignment.topRight,
                )
              )
            : null,
          child: Row(
            children: [
              Container(
                padding: EdgeInsets.all(_getResponsiveValue(context, 8)),
                decoration: BoxDecoration(
                  color: _HomeScreenState.primaryTeal.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(_getResponsiveValue(context, 10)),
                ),
                child: Icon(
                  isCategory ? Icons.folder_copy_outlined : Icons.article_outlined, 
                  color: _HomeScreenState.primaryTeal, 
                  size: _getResponsiveValue(context, 28)
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      subject.name, 
                      style: _responsiveTextStyle(context, 16, fontWeight: FontWeight.bold, color: isCategory ? _HomeScreenState.darkTeal : _HomeScreenState.textDark)
                    ),
                    if(isCategory)
                      Padding(
                        padding: const EdgeInsets.only(top: 4.0),
                        child: Text(
                          "${subject.children.length} زیرمجموعه",
                           style: _responsiveTextStyle(context, 12, color: _HomeScreenState.textMedium)
                        ),
                      ),
                  ],
                ),
              ),
              Icon(Icons.arrow_forward_ios_rounded, color: _HomeScreenState.textMedium.withOpacity(0.7), size: _getResponsiveValue(context, 18)),
            ],
          ),
        ),
      ),
    );
  }
  
}

// class HomeScreen extends StatefulWidget {
//   final bool isPickerMode;
//   const HomeScreen({super.key, this.isPickerMode = false});
//   @override
//   State<HomeScreen> createState() => _HomeScreenState();
// }

// class _HomeScreenState extends State<HomeScreen> {
//   final ApiService _apiService = ApiService();
//   final HiveService _hiveService = HiveService();
//  bool _isSyncing = false; 
//   List<Subject> _subjectTree = [];
//   bool _isLoading = true;
//   String _errorMessage = '';
//   bool _isInit = true;

//   static const Color primaryTeal = Color(0xFF008080);
//   static const Color lightTeal = Color(0xFF4DB6AC);
//   static const Color darkTeal = Color(0xFF004D40);
//   static const Color accentYellow = Color(0xFFFFD700);
//   static const Color textDark = Color(0xFF212121);
//   static const Color textMedium = Color(0xFF607D8B);
//   static const Color backgroundLight = Color(0xFFF8F9FA);


//   @override
//   void initState() {
//     super.initState();
//     // initState باید این دو تابع را فراخوانی کند
//     _loadInitialData();
//     _syncAllPremiumContent(showSuccessMessage: false);
//   }

//   @override
//   void didChangeDependencies() {
//     if (_isInit) {
//       _loadInitialData();
//     }
//     _isInit = false;
//     super.didChangeDependencies();
//   }

//   Future<void> _loadInitialData() async {
//     if (!mounted) return;
//     setState(() { _isLoading = true; _errorMessage = ''; });
//     try {
//       final authProvider = Provider.of<AuthProvider>(context, listen: false);
//       await authProvider.refreshUser();
//       final user = authProvider.user;

//       if (user != null) {
//         final connectivityResult = await (Connectivity().checkConnectivity());
//         if (connectivityResult != ConnectivityResult.none) {
//           try {
//             final onlineTree = await _apiService.fetchSubjectTree();
//             if (mounted) setState(() { _subjectTree = onlineTree; });
//             // داده‌ها را برای استفاده آفلاین در Hive ذخیره می‌کنیم
//             await _hiveService.syncData<Subject>('subjects', _flattenTree(onlineTree), user.id);
//           } catch (e) {
//             await _loadFromLocalDb(user.id, errorFromOnline: true);
//           }
//         } else {
//           await _loadFromLocalDb(user.id);
//         }
//       } else {
//         if (mounted) setState(() { _subjectTree = []; });
//       }
//     } catch (e) {
//       if (mounted) setState(() { _errorMessage = "خطا: ${e.toString().replaceAll("Exception: ", "")}"; });
//     } finally {
//       if (mounted) setState(() { _isLoading = false; });
//     }
//   }

//   Future<void> _loadFromLocalDb(String userId, {bool errorFromOnline = false}) async {
//     final localSubjects = await _hiveService.getSubjects(userId);
//     if (mounted) {
//       if (localSubjects.isNotEmpty) {
//         setState(() {
//           _subjectTree = _buildTreeFromFlatList(localSubjects);
//           _errorMessage = errorFromOnline ? 'خطا در ارتباط. نمایش داده‌های آفلاین.' : '';
//         });
//       } else {
//         setState(() { _errorMessage = 'هیچ داده‌ای برای نمایش آفلاین وجود ندارد. لطفا به اینترنت متصل شوید.'; });
//       }
//     }
//   }

//   List<Subject> _flattenTree(List<Subject> tree) {
//     List<Subject> flatList = [];
//     for (var node in tree) {
//       flatList.add(Subject(id: node.id, name: node.name, parent: node.parent, price: node.price));
//       if (node.children.isNotEmpty) {
//         flatList.addAll(_flattenTree(node.children));
//       }
//     }
//     return flatList;
//   }

//   List<Subject> _buildTreeFromFlatList(List<Subject> flatList) {
//     for (var sub in flatList) { sub.children = []; }
//     Map<String, Subject> map = {for (var sub in flatList) sub.id: sub};
//     List<Subject> tree = [];
//     for (var sub in flatList) {
//       if (sub.parent != null && map.containsKey(sub.parent)) {
//         map[sub.parent]!.children.add(sub);
//       } else {
//         tree.add(sub);
//       }
//     }
//     return tree;
//   }
//   Future<void> _syncAllPremiumContent({bool showSuccessMessage = true}) async {
//     if (_isSyncing) return;
    
//     final connectivityResult = await (Connectivity().checkConnectivity());
//     if (connectivityResult == ConnectivityResult.none) {
//       if (showSuccessMessage && mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('برای همگام‌سازی به اینترنت نیاز دارید.')));
//       return;
//     }
    
//     final authProvider = Provider.of<AuthProvider>(context, listen: false);
//     final user = authProvider.user;
//     final token = authProvider.token;
//     if (user == null || token == null || !user.isPremium) return;

//     if (mounted) setState(() { _isSyncing = true; });
//     try {
//       final onlineTree = await _apiService.fetchSubjectTree();
//       final flatList = _flattenTree(onlineTree);
      
//       await _hiveService.syncData<Subject>('subjects', flatList, user.id);
      
//       List<Question> allQuestions = [];
//       for (var subject in flatList) {
//         if (subject.children.isEmpty) { 
//           final questions = await _apiService.fetchAllQuestionsForSubject(subject.id, token);
//           allQuestions.addAll(questions);
//         }
//       }
//       await _hiveService.syncData<Question>('questions', allQuestions, user.id);
      
//       if (mounted) {
//         setState(() { _subjectTree = onlineTree; _errorMessage = ''; });
//         if (showSuccessMessage) {
//           ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('همگام‌سازی کامل با موفقیت انجام شد!')));
//         }
//       }
//     } catch (e) {
//       print("Sync Error: $e");
//       if (mounted && showSuccessMessage) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('خطا در همگام‌سازی: ${e.toString()}')));
//     } finally {
//       if (mounted) setState(() { _isSyncing = false; });
//     }
//   }
//   void _startTrialQuiz() async {
//     showDialog(context: context, builder: (_) => const Center(child: CircularProgressIndicator()));
//     try {
//       final trialQuestions = await _hiveService.getTrialQuestions();
//       if (mounted) Navigator.of(context, rootNavigator: true).pop();
//       if (trialQuestions.isNotEmpty) {
//         Navigator.of(context).push(MaterialPageRoute(builder: (ctx) => TrialQuizScreen(questions: trialQuestions)));
//       } else {
//         throw Exception('سوالات آزمایشی یافت نشد. لطفا به اینترنت متصل شوید و برنامه را دوباره باز کنید.');
//       }
//     } catch (e) {
//       if (mounted) {
//         Navigator.of(context, rootNavigator: true).pop();
//         ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString().replaceAll("Exception: ", ""))));
//       }
//     }
//   }
  
//   double _getResponsiveSize(BuildContext context, double baseSize) {
//     final screenWidth = MediaQuery.of(context).size.width;
//     return baseSize * (screenWidth / 375.0);
//   }

//   void _onSubjectTap(Subject subject) {
//     final authProvider = Provider.of<AuthProvider>(context, listen: false);
//     final user = authProvider.user;

//     if (widget.isPickerMode) {
//       Navigator.of(context).pop([subject]);
//     } else {
//       // اینجا می‌توانید منطق چک کردن اشتراک را اضافه کنید
//       // برای سادگی، فعلا مستقیم به صفحه ساخت آزمون می‌رویم
//       Navigator.of(context).push(MaterialPageRoute(
//         builder: (ctx) => TestSetupScreen(preselectedSubject: subject),
//       ));
//     }
//   }
  
//   @override
//   Widget build(BuildContext context) {
//     final screenWidth = MediaQuery.of(context).size.width;
//     final screenHeight = MediaQuery.of(context).size.height;

//     return Consumer<AuthProvider>(builder: (context, authProvider, child) {
//       final user = authProvider.user;
//       final profileImageFile = user?.profileImagePath != null ? File(user!.profileImagePath!) : null;

//       return Scaffold(
//         backgroundColor: backgroundLight,
//         floatingActionButton: FloatingActionButton.extended(
//           onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (ctx) => const TestSetupScreen())),
//           label: const Text('ساخت آزمون سفارشی', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontFamily: 'Vazirmatn')),
//           icon: Icon(Icons.add_circle_outline, color: Colors.white, size: _getResponsiveSize(context, 24)),
//           backgroundColor: primaryTeal,
//           shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(_getResponsiveSize(context, 30))),
//           elevation: 6,
//         ),
//         body: RefreshIndicator(
//           onRefresh: _loadInitialData,
//           color: primaryTeal,
//           child: CustomScrollView(
//             slivers: [
//               if (!widget.isPickerMode)
//                 SliverToBoxAdapter(
//                   child: _buildHeader(screenHeight, profileImageFile, user),
//                 ),
//               if (!widget.isPickerMode)
//                 SliverPadding(
//                   padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
//                   sliver: SliverToBoxAdapter(child: _buildSubscriptionCard(context, user)),
//                 ),
//               if (!widget.isPickerMode)
//                 SliverPadding(
//                   padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
//                   sliver: SliverToBoxAdapter(child: _buildQuickStatsSection()),
//                 ),
//               if (!widget.isPickerMode)
//                 SliverPadding(
//                   padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
//                   sliver: SliverToBoxAdapter(child: _buildTrialQuizCard()),
//                 ),

//               SliverToBoxAdapter(
//                 child: Padding(
//                   padding: const EdgeInsets.fromLTRB(16, 32, 16, 16),
//                   child: Text(
//                     widget.isPickerMode ? 'انتخاب موضوع' : 'دسته‌بندی‌ها',
//                     style: TextStyle(fontSize: _getResponsiveSize(context, 22), fontWeight: FontWeight.bold, color: textDark, fontFamily: 'Vazirmatn'),
//                   ),
//                 ),
//               ),

//               _isLoading
//                   ? const SliverToBoxAdapter(child: Center(child: Padding(padding: EdgeInsets.all(32.0), child: CircularProgressIndicator(color: primaryTeal))))
//                   : _errorMessage.isNotEmpty
//                       ? SliverToBoxAdapter(child: Center(child: Padding(padding: const EdgeInsets.all(32.0), child: Text(_errorMessage, textAlign: TextAlign.center, style: TextStyle(color: Colors.red.shade700, fontFamily: 'Vazirmatn')))))
//                       : _subjectTree.isEmpty
//                           ? const SliverToBoxAdapter(child: Center(child: Padding(padding: EdgeInsets.all(32.0), child: Text('هیچ دسته‌بندی یافت نشد.'))))
//                           : SliverPadding(
//                               padding: const EdgeInsets.fromLTRB(16, 8, 16, 80),
//                               sliver: SliverList(
//                                 delegate: SliverChildBuilderDelegate(
//                                   (context, index) {
//                                     return _buildSubjectTile(_subjectTree[index]);
//                                   },
//                                   childCount: _subjectTree.length,
//                                 ),
//                               ),
//                             ),
//             ],
//           ),
//         ),
//       );
//     });
//   }
  
//   // --- ویجت‌های Build (کپی شده از کد قبلی شما با اصلاحات جزئی) ---

//   Widget _buildHeader(double screenHeight, File? profileImageFile, AppUser? user) {
//     return Stack(
//       children: [
//         Container(
//           height: screenHeight * 0.25,
//           decoration: BoxDecoration(
//             gradient: LinearGradient(
//               colors: [primaryTeal, lightTeal.withOpacity(0.8)],
//               begin: Alignment.topCenter,
//               end: Alignment.bottomCenter,
//             ),
//             borderRadius: BorderRadius.vertical(bottom: Radius.circular(_getResponsiveSize(context, 30))),
//           ),
//         ),
//         Padding(
//           padding: EdgeInsets.only(
//             top: _getResponsiveSize(context, 40.0),
//             left: _getResponsiveSize(context, 16.0),
//             right: _getResponsiveSize(context, 16.0),
//           ),
//           child: Column(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               Row(
//                 mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                 children: [
//                   GestureDetector(
//                     onTap: () {
//                       Navigator.of(context).push(MaterialPageRoute(builder: (ctx) => const ProfileScreen()));
//                     },
//                     child: Hero(
//                       tag: 'profileImage',
//                       child: CircleAvatar(
//                         radius: _getResponsiveSize(context, 24),
//                         backgroundColor: Colors.white.withOpacity(0.3),
//                         backgroundImage: profileImageFile != null ? FileImage(profileImageFile) : null,
//                         child: profileImageFile == null
//                             ? Text(
//                                 user?.name.isNotEmpty == true ? user!.name.substring(0, 1) : 'U',
//                                 style: const TextStyle(fontSize: 22, color: Colors.white, fontWeight: FontWeight.bold),
//                               )
//                             : null,
//                       ),
//                     ),
//                   ),
//                   const Text(
//                     "آزمونک",
//                     style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white, fontFamily: 'Vazirmatn'),
//                   ),
//                 ],
//               ),
//               SizedBox(height: _getResponsiveSize(context, 30)),
//               Text(
//                 'سلام،',
//                 style: TextStyle(fontSize: _getResponsiveSize(context, 20), color: Colors.white.withOpacity(0.9), fontFamily: 'Vazirmatn'),
//               ),
//               Text(
//                 user?.name ?? 'کاربر گرامی',
//                 style: TextStyle(fontSize: _getResponsiveSize(context, 28), fontWeight: FontWeight.bold, color: Colors.white, fontFamily: 'Vazirmatn'),
//               ),
//             ],
//           ),
//         ),
//       ],
//     );
//   }

//   Widget _buildSubjectTile(Subject subject) {
//     if (subject.children.isEmpty) {
//       return Card(
//         elevation: 2,
//         shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
//         margin: const EdgeInsets.symmetric(vertical: 6),
//         child: InkWell(
//           borderRadius: BorderRadius.circular(15),
//           onTap: () => _onSubjectTap(subject),
//           child: Padding(
//             padding: const EdgeInsets.all(16.0),
//             child: Row(
//               children: [
//                 Icon(Icons.article_outlined, color: primaryTeal, size: _getResponsiveSize(context, 30)),
//                 const SizedBox(width: 16),
//                 Expanded(child: Text(subject.name, style: TextStyle(fontWeight: FontWeight.bold, fontSize: _getResponsiveSize(context, 16)))),
//                 Icon(Icons.arrow_forward_ios_rounded, color: textMedium.withOpacity(0.7), size: _getResponsiveSize(context, 18)),
//               ],
//             ),
//           ),
//         ),
//       );
//     }
    
//     return Card(
//       elevation: 2,
//       margin: const EdgeInsets.symmetric(vertical: 6),
//       shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
//       clipBehavior: Clip.antiAlias,
//       child: ExpansionTile(
//         leading: Icon(Icons.folder_copy_outlined, color: primaryTeal, size: _getResponsiveSize(context, 30)),
//         title: Text(subject.name, style: TextStyle(fontWeight: FontWeight.bold, fontSize: _getResponsiveSize(context, 17), color: textDark)),
//         childrenPadding: const EdgeInsets.only(left: 24, right: 8, bottom: 8),
//         children: subject.children.map((child) => _buildSubjectTile(child)).toList(),
//       ),
//     );
//   }

//   Widget _buildSubscriptionCard(BuildContext context, AppUser? user) {
//     if (user == null) return _buildPremiumCallToAction(context);
//     final activeSubscription = user.purchasedSubjects.firstWhere(
//       (sub) => sub.expiresAt.isAfter(DateTime.now()),
//       orElse: () => PurchasedSubject(subjectId: '', expiresAt: DateTime.now()),
//     );
//     if (activeSubscription.subjectId.isNotEmpty) {
//       return _buildPremiumStatusCard(activeSubscription.expiresAt);
//     } else {
//       return _buildPremiumCallToAction(context);
//     }
//   }

//   Widget _buildPremiumStatusCard(DateTime expiryDate) {
//     return Card(
//       color: Colors.white,
//       elevation: 4,
//       shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(_getResponsiveSize(context, 20))),
//       child: Container(
//         padding: EdgeInsets.all(_getResponsiveSize(context, 20.0)),
//         decoration: BoxDecoration(
//           borderRadius: BorderRadius.circular(_getResponsiveSize(context, 20)),
//           gradient: LinearGradient(
//             colors: [lightTeal.withOpacity(0.1), backgroundLight],
//             begin: Alignment.topLeft,
//             end: Alignment.bottomRight,
//           ),
//         ),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             Row(
//               mainAxisAlignment: MainAxisAlignment.start,
//               children: [
//                 Icon(Icons.workspace_premium_rounded, color: primaryTeal, size: _getResponsiveSize(context, 30)),
//                 SizedBox(width: _getResponsiveSize(context, 10)),
//                 Text('شما عضو ویژه هستید', style: TextStyle(fontWeight: FontWeight.bold, color: primaryTeal, fontSize: _getResponsiveSize(context, 17), fontFamily: 'Vazirmatn')),
//               ],
//             ),
//             SizedBox(height: _getResponsiveSize(context, 16)),
//             Text('زمان باقی‌مانده از اشتراک شما:', style: TextStyle(color: textMedium, fontSize: _getResponsiveSize(context, 13), fontFamily: 'Vazirmatn')),
//             SizedBox(height: _getResponsiveSize(context, 10)),
//             TimerBuilder.periodic(
//               const Duration(seconds: 1),
//               builder: (context) {
//                 final now = DateTime.now();
//                 final remaining = expiryDate.difference(now);
//                 if (remaining.isNegative) {
//                   WidgetsBinding.instance.addPostFrameCallback((_) => _loadInitialData());
//                   return Text('اشتراک شما به پایان رسیده است.', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red, fontFamily: 'Vazirmatn', fontSize: _getResponsiveSize(context, 16)));
//                 }
//                 final days = remaining.inDays;
//                 final hours = remaining.inHours % 24;
//                 final minutes = remaining.inMinutes % 60;
//                 final seconds = remaining.inSeconds % 60;
//                 return Text('$days روز و $hours ساعت و $minutes دقیقه و $seconds ثانیه', style: TextStyle(fontSize: _getResponsiveSize(context, 19), fontWeight: FontWeight.bold, fontFamily: 'Vazirmatn', color: darkTeal));
//               },
//             )
//           ],
//         ),
//       ),
//     );
//   }

//   Widget _buildPremiumCallToAction(BuildContext context) {
//     return Card(
//       elevation: 4,
//       shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(_getResponsiveSize(context, 20))),
//       child: InkWell(
//         borderRadius: BorderRadius.circular(_getResponsiveSize(context, 20)),
//         onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (ctx) => const PremiumScreen())),
//         child: Container(
//           padding: EdgeInsets.all(_getResponsiveSize(context, 20.0)),
//           decoration: BoxDecoration(
//             borderRadius: BorderRadius.circular(_getResponsiveSize(context, 20)),
//             gradient: LinearGradient(colors: [accentYellow.withOpacity(0.1), Colors.white], begin: Alignment.topLeft, end: Alignment.bottomRight),
//           ),
//           child: Row(
//             children: [
//               Icon(Icons.star_rounded, color: accentYellow, size: _getResponsiveSize(context, 36)),
//               SizedBox(width: _getResponsiveSize(context, 16)),
//               Expanded(
//                 child: Column(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     Text('عضویت ویژه', style: TextStyle(fontSize: _getResponsiveSize(context, 18), fontWeight: FontWeight.bold, color: textDark, fontFamily: 'Vazirmatn')),
//                     Text('دسترسی نامحدود به تمامی امکانات', style: TextStyle(color: textMedium, fontSize: _getResponsiveSize(context, 14), fontFamily: 'Vazirmatn')),
//                   ],
//                 ),
//               ),
//               Icon(Icons.arrow_forward_ios_rounded, color: textMedium.withOpacity(0.7), size: _getResponsiveSize(context, 20)),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
  
//   Widget _buildTrialQuizCard() {
//     return Card(
//       elevation: 3,
//       shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(_getResponsiveSize(context, 20))),
//       child: InkWell(
//         borderRadius: BorderRadius.circular(_getResponsiveSize(context, 20)),
//         onTap: _startTrialQuiz,
//         child: Container(
//           padding: EdgeInsets.all(_getResponsiveSize(context, 20.0)),
//           decoration: BoxDecoration(
//             borderRadius: BorderRadius.circular(_getResponsiveSize(context, 20)),
//             gradient: LinearGradient(colors: [lightTeal.withOpacity(0.1), Colors.white], begin: Alignment.bottomRight, end: Alignment.topLeft),
//           ),
//           child: Row(
//             children: [
//               Icon(Icons.quiz_rounded, color: primaryTeal, size: _getResponsiveSize(context, 36)),
//               SizedBox(width: _getResponsiveSize(context, 16)),
//               Expanded(
//                 child: Column(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     Text('آزمون آمادگی رایگان', style: TextStyle(fontSize: _getResponsiveSize(context, 18), fontWeight: FontWeight.bold, color: textDark, fontFamily: 'Vazirmatn')),
//                     Text('با ۱۰ سوال رایگان خود را بسنجید', style: TextStyle(color: textMedium, fontSize: _getResponsiveSize(context, 14), fontFamily: 'Vazirmatn')),
//                   ],
//                 ),
//               ),
//               Icon(Icons.arrow_forward_ios_rounded, color: textMedium.withOpacity(0.7), size: _getResponsiveSize(context, 20)),
//             ],
//           ),
//         ),
//       ),
//     );
//   }

//   Widget _buildQuickStatsSection() {
//     final user = Provider.of<AuthProvider>(context, listen: false).user;
//     if (user == null) return const SizedBox.shrink();
//     return FutureBuilder<List<QuizAttempt>>(
//       future: _hiveService.getQuizHistory(user.id),
//       builder: (context, snapshot) {
//         if (!snapshot.hasData || snapshot.data!.isEmpty) return const SizedBox.shrink();
//         final history = snapshot.data!;
//         final totalTests = history.length;
//         final averageScore = history.map((h) => h.percentage).reduce((a, b) => a + b) / totalTests;
//         return Row(
//           children: [
//             Expanded(child: _buildStatCard('تعداد آزمون‌ها', totalTests.toString(), Icons.fact_check_rounded, Colors.orange.shade700)),
//             SizedBox(width: _getResponsiveSize(context, 16)),
//             Expanded(child: _buildStatCard('میانگین نمره', '${averageScore.toStringAsFixed(0)}%', Icons.analytics_outlined, Colors.green.shade700)),
//           ],
//         );
//       },
//     );
//   }

//   Widget _buildStatCard(String title, String value, IconData icon, Color color) {
//     return Card(
//       elevation: 3,
//       shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(_getResponsiveSize(context, 20))),
//       color: Colors.white,
//       child: Container(
//         padding: EdgeInsets.all(_getResponsiveSize(context, 16.0)),
//         decoration: BoxDecoration(
//           borderRadius: BorderRadius.circular(_getResponsiveSize(context, 20)),
//           gradient: LinearGradient(colors: [color.withOpacity(0.05), Colors.white], begin: Alignment.bottomLeft, end: Alignment.topRight),
//         ),
//         child: Row(
//           children: [
//             Container(
//               padding: EdgeInsets.all(_getResponsiveSize(context, 10)),
//               decoration: BoxDecoration(color: color.withOpacity(0.15), borderRadius: BorderRadius.circular(_getResponsiveSize(context, 15))),
//               child: Icon(icon, size: _getResponsiveSize(context, 30), color: color),
//             ),
//             SizedBox(width: _getResponsiveSize(context, 12)),
//             Expanded(
//               child: Column(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   Text(value, style: TextStyle(fontSize: _getResponsiveSize(context, 22), fontWeight: FontWeight.bold, color: textDark)),
//                   Text(title, style: TextStyle(color: textMedium, fontSize: _getResponsiveSize(context, 13), fontFamily: 'Vazirmatn'), maxLines: 1, overflow: TextOverflow.ellipsis),
//                 ],
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }