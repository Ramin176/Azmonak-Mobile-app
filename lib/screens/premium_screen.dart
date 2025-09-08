import 'package:azmoonak_app/helpers/hive_db_service.dart';
import 'package:azmoonak_app/models/settings.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/api_service.dart';
import '../models/plan.dart';
class PremiumScreen extends StatefulWidget {
  const PremiumScreen({super.key});
  @override
  State<PremiumScreen> createState() => _PremiumScreenState();
}

class _PremiumScreenState extends State<PremiumScreen> {
   Future<AppSettings?>? _settingsFuture;
  final ApiService _apiService = ApiService();
  AppSettings? _settings;
  bool _isLoading = true;
  final HiveService _hiveService = HiveService();
  @override
  void initState() {
    super.initState();
    // _settingsFuture = _apiService.fetchSettings();
     _loadSettings();
  }


 // ۴. منطق اصلی دریافت داده‌ها در یک تابع جداگانه
  Future<AppSettings?> _fetchAndCacheSettings() async {
    // ابتدا از دیتابیس محلی بخوان
    final localSettings = await _hiveService.getSettings();
    
    // سپس، اگر آنلاین بود، از سرور آپدیت بگیر
    final connectivityResult = await (Connectivity().checkConnectivity());
    if (connectivityResult != ConnectivityResult.none) {
      try {
        final onlineSettingsJson = await _apiService.fetchSettings();
        final onlineSettings = AppSettings.fromJson(onlineSettingsJson);
        await _hiveService.saveSettings(onlineSettings); // آپدیت دیتابیس محلی
        return onlineSettings;
      } catch (e) {
        print("Could not sync settings: $e");
        // اگر همگام‌سازی آنلاین ناموفق بود، داده‌های محلی را برگردان (اگر وجود داشت)
        return localSettings;
      }
    }
    // اگر آفلاین بود، فقط داده‌های محلی را برگردان
    return localSettings;
  }
  
  void _launchTelegram(String url) async {
    final uri = Uri.parse(url);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      if(mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('خطا در باز کردن تلگرام.')));
    }
  }
  Future<void> _loadSettings() async {
    setState(() { _isLoading = true; _settingsFuture = _fetchAndCacheSettings();});
    
    // ۱. ابتدا از دیتابیس محلی بخوان
    final localSettings = await _hiveService.getSettings();
    if (mounted && localSettings != null) {
      setState(() { _settings = localSettings; });
    }
    
    // ۲. سپس، اگر آنلاین بود، از سرور آپدیت بگیر
    final connectivityResult = await (Connectivity().checkConnectivity());
    if (connectivityResult != ConnectivityResult.none) {
      try {
        final onlineSettingsJson = await _apiService.fetchSettings();
        final onlineSettings = AppSettings.fromJson(onlineSettingsJson);
        await _hiveService.saveSettings(onlineSettings); // آپدیت دیتابیس محلی
        if (mounted) setState(() { _settings = onlineSettings; });
      } catch (e) {
        print("Could not sync settings: $e");
        if (_settings == null) { // اگر از اول هم داده‌ای نبود، خطا نشان بده
          // مدیریت خطا
        }
      }
    }
    
    if (mounted) setState(() { _isLoading = false; });
  }

  @override
  Widget build(BuildContext context) {
    const tealColor = Color(0xFF008080);
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
     if (_settings == null) {
      return const Scaffold(body: Center(child: Text('اطلاعات پلن‌ها یافت نشد.')));
    }
     final plans = _settings!.subscriptionPlans;
    final paymentInstructions = _settings!.paymentInstructions;
    return Scaffold(
      appBar: AppBar(
        title: const Text('عضویت ویژه'),
        backgroundColor: tealColor,
        foregroundColor: Colors.white,
      ),
      body: FutureBuilder<AppSettings?>(
        future: _settingsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError || !snapshot.hasData) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Text('خطا در دریافت اطلاعات پلن‌ها. لطفا اتصال اینترنت خود را بررسی کرده و دوباره تلاش کنید.\n\n${snapshot.error ?? ''}'),
              ),
            );
          }

          final settings = snapshot.data!;
          final List<Plan> plans = settings.subscriptionPlans;
          final paymentInstructions = settings.paymentInstructions ?? 'اطلاعات پرداخت به زودی اضافه خواهد شد.';
          final telegramLink = settings.telegramLink ?? '';
          
          return CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24.0, 24.0, 24.0, 16.0),
                  child: Column(
                    children: [
                      const Icon(Icons.star_rounded, color: Colors.amber, size: 80),
                      const SizedBox(height: 16),
                      const Text('به دنیای آزمونک پرمیوم بپیوندید!', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: tealColor)),
                      const SizedBox(height: 8),
                      const Text('با دسترسی نامحدود به تمام سوالات، شانس قبولی خود را تضمین کنید.', textAlign: TextAlign.center, style: TextStyle(fontSize: 16, color: Colors.black54)),
                    ],
                  ),
                ),
              ),
              
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) => _buildPlanCard(plans[index], isPopular: index == 1),
                    childCount: plans.length,
                  ),
                ),
              ),

              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    children: [
                      const Divider(height: 32),
                      const Text('نحوه پرداخت', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
                      const SizedBox(height: 16),
                      Card(
                        elevation: 0,
                        color: const Color(0xFFF0F8FF),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        child: Padding(
                          padding: const EdgeInsets.all(20.0),
                          child: Column(
                            children: [
                              Text(paymentInstructions, textAlign: TextAlign.center, style: const TextStyle(fontSize: 15, height: 1.5)),
                              if (telegramLink.isNotEmpty) const SizedBox(height: 20),
                              if (telegramLink.isNotEmpty)
                                ElevatedButton.icon(
                                  onPressed: () => _launchTelegram(telegramLink),
                                  icon: const Icon(Icons.send_rounded),
                                  label: const Text('ارسال رسید در تلگرام'),
                                ),
                            ],
                          ),
                        ),
                      )
                    ]
                  ),
                ),
              )
            ],
          );
        },
      ),
    );
  }

  Widget _buildPlanCard(Plan plan, {bool isPopular = false}) {
    const tealColor = Color(0xFF008080);
    return Card(
      elevation: isPopular ? 8 : 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: isPopular ? tealColor : Colors.transparent, width: 2),
      ),
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
         
          children: [
            if(isPopular)
              const Chip(label: Text('محبوب‌ترین'), backgroundColor: tealColor, labelStyle: TextStyle(color: Colors.white)),
            if(isPopular) const SizedBox(height: 8),

            Text(plan.duration, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text(plan.price, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: tealColor)),
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 16),
            _buildFeatureRow('سقف ${plan.questionLimit} سوال در هر آزمون'),
            _buildFeatureRow('دسترسی به تمام دوره‌ها'),
            _buildFeatureRow('مرور آزمون‌های قبلی'),
            _buildFeatureRow('استفاده آفلاین'),
          ],
        ),
      ),
    );
  }
  
  Widget _buildFeatureRow(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        children: [
          const Icon(Icons.check_circle_outline_rounded, color: Colors.green, size: 20),
          const SizedBox(width: 8),
          Text(text),
        ],
      ),
    );
  }
}