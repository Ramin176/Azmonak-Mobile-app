// فایل: screens/premium_screen.dart

import 'package:azmoonak_app/helpers/adaptive_text_size.dart';
import 'package:azmoonak_app/helpers/hive_db_service.dart';
import 'package:azmoonak_app/models/settings.dart';
import 'package:azmoonak_app/models/subject.dart';
import 'package:azmoonak_app/providers/auth_provider.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/api_service.dart';

class PremiumScreen extends StatefulWidget {
  const PremiumScreen({super.key});
  @override
  State<PremiumScreen> createState() => _PremiumScreenState();
}

class _PremiumScreenState extends State<PremiumScreen> {
  // --- متغیرهای State ---
  final ApiService _apiService = ApiService();
  final HiveService _hiveService = HiveService();
  
  Future<Map<String, dynamic>>? _dataFuture;
  bool _isInit = true;
  String _selectedDuration = 'همه'; // برای فیلتر کردن، 'همه' به عنوان پیش‌فرض

  // --- پالت رنگی هماهنگ با HomeScreen ---
  static const Color primaryTeal = Color(0xFF008080);
  static const Color accentYellow = Color(0xFFFFD700);
  static const Color textDark = Color(0xFF212121);
  static const Color backgroundLight = Color(0xFFF8F9FA);

  // --- منطق بارگذاری داده‌ها (بدون تغییر) ---
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_isInit) {
      _dataFuture = _loadData();
    }
    _isInit = false;
  }

  Future<Map<String, dynamic>> _loadData() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final user = authProvider.user;
    final connectivityResult = await (Connectivity().checkConnectivity());
    
    if (connectivityResult != ConnectivityResult.none) {
      try {
        final settingsJson = await _apiService.fetchSettings();
        final settings = AppSettings.fromJson(settingsJson);
        await _hiveService.saveSettings(settings);

        final subjectTree = await _apiService.fetchSubjectTree();
        final subjects = _flattenTree(subjectTree);
        if (user != null) {
          await _hiveService.syncData<Subject>('subjects', subjects, user.id);
        }
        
        return {'settings': settings, 'subjects': subjects};
      } catch (e) {
        debugPrint("PremiumScreen: API error, falling back to local data. Error: $e");
        return await _loadFromLocal(user?.id);
      }
    } else {
      debugPrint("PremiumScreen: Offline mode detected.");
      return await _loadFromLocal(user?.id);
    }
  }

  Future<Map<String, dynamic>> _loadFromLocal(String? userId) async {
    debugPrint("PremiumScreen: Loading from local Hive cache.");
    final settings = await _hiveService.getSettings();
    if (settings == null) {
      throw Exception('شما آفلاین هستید و هیچ داده‌ای برای نمایش ذخیره نشده است.');
    }
    List<Subject> localSubjects = [];
    if (userId != null) {
       localSubjects = await _hiveService.getSubjects(userId);
    }
    return {'settings': settings, 'subjects': localSubjects};
  }

  List<Subject> _flattenTree(List<Subject> tree) {
    List<Subject> flatList = [];
    for (var node in tree) {
      flatList.add(node);
      if (node.children.isNotEmpty) {
        flatList.addAll(_flattenTree(node.children));
      }
    }
    return flatList;
  }
  
  void _launchTelegram(String url) async {
    final uri = Uri.parse(url);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      if(mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('خطا در باز کردن تلگرام. لطفا مطمئن شوید تلگرام نصب است.')));
    }
  }

  void _sendOrderToTelegramForPlan(SubscriptionPlan plan, AppSettings settings, List<Subject> allSubjects) async {
    // ... این متد بدون تغییر باقی می‌ماند ...
    final user = Provider.of<AuthProvider>(context, listen: false).user;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('لطفا ابتدا وارد حساب کاربری خود شوید.')));
      return;
    }
    if (settings.telegramLink.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('اطلاعات تماس با ادمین یافت نشد.')));
      return;
    }
    final subjectNames = plan.subjectIds.map((subId) {
      try {
        return allSubjects.firstWhere((s) => s.id == subId).name;
      } catch (e) { return 'موضوع نامشخص'; }
    }).join('، ');

    final message = """
*📣 سفارش جدید اشتراک (بسته)*
- - - - - - - - - - - - - - - - - -
*اطلاعات کاربر:*
👤 *نام:* ${user.name}
✉️ *ایمیل:* `${user.email}`
*جزئیات سفارش:*
📦 *نام بسته:* ${plan.name}
📚 *شامل موضوعات:* ${subjectNames}
⏳ *مدت زمان:* ${plan.duration}
💵 *قیمت:* ${plan.price} افغانی
- - - - - - - - - - - - - - - - - -
*اقدام مورد نیاز:*
لطفاً پس از بررسی، اشتراک را از طریق پنل مدیریت برای کاربر فعال نمایید.
- - - - - - - - - - - - - - - - - -
*⚠️ توجه برای کاربر:*
*لطفاً تصویر فیش پرداختی خود را در همین صفحه تلگرام برای ما ارسال کنید تا سفارش شما تایید شود.*
""";

    final encodedMessage = Uri.encodeComponent(message);
    final url = '${settings.telegramLink}?text=$encodedMessage&parse_mode=Markdown';
    _launchTelegram(url);
  }

  // --- ویجت اصلی Build ---
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundLight,
      appBar: AppBar(
        title: const Text('عضویت ویژه', style: TextStyle(fontFamily: 'Vazirmatn', fontWeight: FontWeight.bold)),
        backgroundColor: primaryTeal,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: FutureBuilder<Map<String, dynamic>>(
        future: _dataFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: primaryTeal));
          }
          
          if (snapshot.hasError || !snapshot.hasData) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(32.0), 
                child: Text(
                  snapshot.error.toString().replaceAll("Exception: ", ""), 
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 16, color: Colors.red.shade700, fontFamily: 'Vazirmatn'),
                )
              )
            );
          }

          final AppSettings settings = snapshot.data!['settings'];
          final List<Subject> allSubjects = snapshot.data!['subjects'];
          final List<SubscriptionPlan> allPlans = settings.subscriptionPlans;

          // استخراج مدت زمان‌های یکتا برای فیلتر
          final uniqueDurations = ['همه', ...allPlans.map((p) => p.duration).toSet().toList()];

          // اعمال فیلتر بر روی لیست بسته‌ها
          final filteredPlans = _selectedDuration == 'همه'
              ? allPlans
              : allPlans.where((plan) => plan.duration == _selectedDuration).toList();
          
          return Stack(
            children: [
              // --- لایه زیرین: محتوای قابل اسکرول ---
              CustomScrollView(
                // مقداری Padding در پایین اضافه می‌کنیم تا محتوا زیر دکمه پرداخت قرار نگیرد
                slivers: [
                  SliverToBoxAdapter(child: _buildHeader()),
                  SliverToBoxAdapter(child: _buildFilterChips(uniqueDurations)),
                  
                  if (filteredPlans.isEmpty)
                    const SliverToBoxAdapter(
                      child: Center(
                        child: Padding(
                          padding: EdgeInsets.symmetric(vertical: 60.0),
                          child: Text('هیچ بسته‌ای با این فیلتر یافت نشد.', style: TextStyle(fontFamily: 'Vazirmatn', fontSize: 16, color: Colors.grey)),
                        )
                      )
                    ),
                  
                  if (filteredPlans.isNotEmpty)
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 120), // Padding بیشتر در پایین
                      sliver: SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (context, index) => _buildPlanCard(filteredPlans[index], settings, allSubjects),
                          childCount: filteredPlans.length,
                        ),
                      ),
                    ),
                ],
              ),

              // --- لایه رویی: دکمه ثابت پرداخت در پایین ---
              if (settings.paymentInstructions.isNotEmpty)
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: _buildFixedPaymentButton(settings),
                ),
            ],
          );
        },
      ),
    );
  }
  
  // --- ویجت‌های کمکی ---
  
  Widget _buildHeader() {
    // این ویجت بدون تغییر باقی می‌ماند
    return Container(
      padding: const EdgeInsets.all(24.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(30)),
        boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.1), spreadRadius: 5, blurRadius: 10)],
      ),
      child: Column(
        children: const [
          Icon(Icons.workspace_premium_rounded, color: accentYellow, size: 80),
          SizedBox(height: 16),
          Text(
            'بسته‌های اشتراک ویژه', 
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: textDark, fontFamily: 'Vazirmatn')
          ),
          SizedBox(height: 8),
          Text(
            'با خرید هر بسته، به تمام آزمون‌های آن دسترسی نامحدود پیدا کنید.', 
            textAlign: TextAlign.center, 
            style: TextStyle(fontSize: 16, color: textDark, fontFamily: 'Vazirmatn')
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChips(List<String> durations) {
    return SizedBox(
      height: 50,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: durations.length,
        itemBuilder: (context, index) {
          final duration = durations[index];
          final isSelected = _selectedDuration == duration;
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4.0),
            child: ChoiceChip(
              label: Text(duration, style: TextStyle(fontFamily: 'Vazirmatn', color: isSelected ? Colors.white : textDark, fontWeight: FontWeight.bold)),
              selected: isSelected,
              onSelected: (selected) {
                if (selected) {
                  setState(() {
                    _selectedDuration = duration;
                  });
                }
              },
              selectedColor: primaryTeal,
              backgroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: BorderSide(color: isSelected ? primaryTeal : Colors.grey.shade300)
              ),
            ),
          );
        },
      ),
    );
  }
  
  Widget _buildPlanCard(SubscriptionPlan plan, AppSettings settings, List<Subject> allSubjects) {
    // این ویجت بدون تغییر باقی می‌ماند
    return Card(
      elevation: 4,
      margin: const EdgeInsets.symmetric(vertical: 10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => _sendOrderToTelegramForPlan(plan, settings, allSubjects),
        child: Container(
          decoration: BoxDecoration(gradient: LinearGradient(colors: [primaryTeal.withOpacity(0.05), Colors.white], begin: Alignment.bottomLeft, end: Alignment.topRight)),
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(plan.name, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color.fromARGB(255, 128, 119, 0), fontFamily: 'Vazirmatn')),
                   
                   Text(plan.duration, style: TextStyle(color: Color.fromARGB(255, 128, 119, 0), fontSize: 22, fontWeight: FontWeight.bold, fontFamily: 'Vazirmatn')),

                ],),
              if (plan.description.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(plan.description, style: const TextStyle(fontSize: 14, color: textDark, fontFamily: 'Vazirmatn', height: 1.5)),
                ],
                const Divider(height: 32, thickness: 0.5),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                         const Text("قیمت", style: TextStyle(color: textDark, fontSize: 13, fontFamily: 'Vazirmatn')),
                        Text('${plan.price} افغانی', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: textDark, fontFamily: 'Vazirmatn')),
                      ],
                    ),
                    
                    ElevatedButton.icon(
                      onPressed: () => _sendOrderToTelegramForPlan(plan, settings, allSubjects),
                      icon: const Icon(Icons.shopping_cart_checkout_rounded, size: 20),
                      label: const Text('سفارش', style: TextStyle(fontFamily: 'Vazirmatn', fontWeight: FontWeight.bold)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: accentYellow,
                        foregroundColor: textDark,
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        elevation: 2,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFixedPaymentButton(AppSettings settings) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 10, spreadRadius: 0, offset: const Offset(0, -4)),
        ],
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: ElevatedButton.icon(
        icon: const Icon(Icons.payment_rounded),
        label: const Text("مشاهده نحوه پرداخت", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, fontFamily: 'Vazirmatn')),
        onPressed: () {
          _showPaymentBottomSheet(context, settings);
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryTeal,
          foregroundColor: Colors.white,
          minimumSize: const Size(double.infinity, 50),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
      ),
    );
  }

  void _showPaymentBottomSheet(BuildContext context, AppSettings settings) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 50,
                height: 5,
                decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(10)),
              ),
              const SizedBox(height: 24),
              const Text(
                'نحوه پرداخت',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, fontFamily: 'Vazirmatn'),
              ),
              const SizedBox(height: 16),
              Text(
                settings.paymentInstructions,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 16, height: 1.6, fontFamily: 'Vazirmatn'),
              ),
              if (settings.telegramLink.isNotEmpty) ...[
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  onPressed: () {
                    Navigator.of(ctx).pop(); // بستن BottomSheet قبل از باز کردن تلگرام
                    _launchTelegram(settings.telegramLink);
                  },
                  icon: const Icon(Icons.send_rounded),
                  label: const Text('ارسال رسید در تلگرام', style: TextStyle(fontFamily: 'Vazirmatn')),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2AABEE), // Telegram Blue
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  ),
                ),
              ],
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }
}