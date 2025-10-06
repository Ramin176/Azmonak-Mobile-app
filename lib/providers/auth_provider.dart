import 'dart:convert';
import 'package:azmoonak_app/helpers/api_exceptions.dart';
import 'package:azmoonak_app/helpers/hive_db_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:hive/hive.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/api_service.dart';
import '../models/user.dart';

class AuthProvider with ChangeNotifier {
  final ApiService _apiService = ApiService();
  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  bool _isDeactivated = false;
  
  String? _token;
  AppUser? _user;


  bool get isAuthenticated => _token != null && _user != null && !_isDeactivated;
  bool get isDeactivated => _isDeactivated;
  String? get token => _token;
  AppUser? get user => _user;
  String? _errorMessage;
  String? get errorMessage => _errorMessage;
  void _handleApiError(dynamic e) {
    if (e.toString().contains('USER_DEACTIVATED')) {
      print("User is deactivated. Forcing logout.");
      _isDeactivated = true;
      logout(); // کاربر را به صورت اجباری خارج کن
    }
    // می‌توانید خطاهای دیگر را هم در اینجا مدیریت کنید
  }
    final HiveService _hiveService = HiveService();

  Future<bool> _handleAuthResponse(Map<String, dynamic> response) async {
    _errorMessage = null;
    if (response.containsKey('token') && response.containsKey('user')) {
      _token = response['token'];
      _user = AppUser.fromJson(response['user']);
      
      await _storage.write(key: 'token', value: _token);
      final userBox = await Hive.openBox<AppUser>('userBox');
      await userBox.put('currentUser', _user!);
      
      notifyListeners();
      return true;
    } else {
      _errorMessage = response['msg'] ?? response['error'] ?? 'An unknown error occurred';
      notifyListeners();
      return false;
    }
  }

  Future<bool> login(String email, String password) async {
    try {
      final response = await _apiService.login(email, password);
      return await _handleAuthResponse(response);
    } catch (e) {
      _errorMessage = 'Could not connect to the server.';
      notifyListeners();
      return false;
    }
  }
  
  Future<bool> register(String name, String email, String password) async {
    try {
      final response = await _apiService.register(name, email, password);
      return await _handleAuthResponse(response);
    } catch (e) {
      _errorMessage = 'Could not connect to the server.';
      notifyListeners();
      return false;
    }
  }

  Future<void> logout() async {
  _token = null;
  _user = null;
 _isDeactivated = false;
  await _storage.delete(key: 'token');
  
  // ما دیگر داده‌های Hive را پاک نمی‌کنیم. آنها برای ورود بعدی باقی می‌مانند.
  // فقط اطلاعات کاربر فعلی را از حافظه برنامه پاک می‌کنیم.
  
  final userBox = await Hive.openBox<AppUser>('userBox');
  await userBox.delete('currentUser'); // فقط کاربر فعلی را از box اصلی پاک کن
  await userBox.close();

  notifyListeners();
}
   Future<void> updateUserName(String newName) async {
    if (_user == null || _token == null) return;
    try {
        final updatedUserJson = await _apiService.updateUserDetails(newName, _token!);
        _user!.name = updatedUserJson['name']; // نام را مستقیماً آپدیت کن
        await _user!.save(); // آبجکت کاربر را در Hive آپدیت کن
        notifyListeners();
    } catch (e) {
        print("Failed to update user name: $e");
        throw e; // خطا را به UI بفرست
    }
  }
Future<void> updateProfileImage(String path) async {
    if (_user == null) return;
    _user!.profileImagePath = path;
    await _user!.save(); // آپدیت کردن آبجکت کاربر در Hive
    notifyListeners(); // اطلاع‌رسانی به تمام صفحات
  }

  
Future<bool> tryAutoLogin() async {
  final token = await _storage.read(key: 'token');
  if (token == null) {
    await logout(); // اطمینان از پاک بودن همه چیز
    return false;
  }

  _token = token; // توکن را در حافظه برنامه ست کن

  try {
    // ===== این بخش کلیدی است: منتظر رفرش می‌مانیم =====
    await refreshUser();
    
    // حالا که رفرش تمام شده، وضعیت isDeactivated آپدیت شده است
    if (_isDeactivated) {
      // اگر کاربر غیرفعال است، لاگین موفق نیست
      return false; 
    }
    
    // اگر کاربر فعال بود، اطلاعات محلی را هم بارگذاری کن
    final userBox = await Hive.openBox<AppUser>('userBox');
    _user = userBox.get('currentUser');
    notifyListeners();
    
    return _user != null;

  } catch (e) {
    // اگر رفرش به هر دلیلی (مثلاً توکن نامعتبر) خطا داد، لاگ اوت کن
    print("Auto-login failed during user refresh: $e");
    await logout();
    return false;
  }
}
  //اصل
  // Future<bool> tryAutoLogin() async {
  //   try {
  //     final token = await _storage.read(key: 'token');
  //     final userBox = await Hive.openBox<AppUser>('userBox');
  //     final user = userBox.get('currentUser');
  //     if (token != null && user != null && user.id.isNotEmpty) {
  //        final prefs = await SharedPreferences.getInstance();
  //     final imagePath = prefs.getString('profile_image_path_${user.id}'); 
  //     _user = user.copyWith(profileImagePath: imagePath);
  //       _token = token;
  //       _user = user;
  //       notifyListeners();
  //       // رفرش در پس‌زمینه برای گرفتن آخرین وضعیت اشتراک
  //       refreshUser(); 
  //       return true;
  //     }
  //     await logout();
  //     return false;
  //   } catch (e) {
  //     await logout();
  //     return false;
  //   }
  // }
  
  // Future<void> refreshUser() async {
  //   if (_token == null) return;
  //   try {
  //     final userData = await _apiService.fetchCurrentUser(_token!);
  //     final currentUser = AppUser.fromJson(userData);
  //     final currentUserFromServer = AppUser.fromJson(userData);
  //     if (!currentUserFromServer.isActive) {
  //       print("User is deactivated by admin. Forcing logout state.");
  //       _isDeactivated = true;
  //       // ما کاربر را logout نمی‌کنیم، فقط وضعیت را تغییر می‌دهیم
  //       // تا main.dart صفحه DeactivatedScreen را نشان دهد
  //       notifyListeners();
  //       return; // ادامه نده
  //     }
  //     _isDeactivated = false;
  //     currentUser.profileImagePath = _user?.profileImagePath;
  //     _user = currentUser;
      
  //     final userBox = await Hive.openBox<AppUser>('userBox');
  //     await userBox.put('currentUser', _user!);
  //     notifyListeners();
      
  //   } catch (e) {
  //     print("Failed to refresh user: $e");
  //   }
  // }
 
  Future<void> refreshUser() async {
    if (_token == null) return;
    try {
      final userData = await _apiService.fetchCurrentUser(_token!);
      final serverUser = AppUser.fromJson(userData);
      _isDeactivated = false; 
      serverUser.profileImagePath = _user?.profileImagePath;
      _user = serverUser;
      
      final userBox = await Hive.openBox<AppUser>('userBox');
      await userBox.put('currentUser', _user!);
      notifyListeners();
       } on ApiException catch (e) { // <--- گرفتن خطای سفارشی
      print("AuthProvider: Caught an API Exception during refresh: ${e.message}, Code: ${e.code}");
      
      if (e.code == 'USER_DEACTIVATED' ) {
        _isDeactivated = true;
        notifyListeners();
        return; 
      } 
    
    } catch (e) {
      print("AuthProvider: Failed to refresh user: $e");
    }
  }
// Future<void> purchaseSubject(String subjectId, String duration) async {
//     if (_token == null) throw Exception('You are not logged in.');
//     try {
//       final response = await _apiService.purchaseSubject(subjectId, duration, _token!);
//       // پس از خرید موفق، سرور آبجکت کاربر آپدیت شده را برمی‌گرداند
//       // ما از این آبجکت برای آپدیت وضعیت برنامه استفاده می‌کنیم
//       await _handleAuthResponse(response);
//     } catch (e) {
//       rethrow; // خطا را به UI ارسال کن تا نمایش داده شود
//     }
//   }

Future<Map<String, dynamic>> purchaseSubject(String subjectId, String duration, String planDuration, String planPrice) async {
  if (_token == null) throw Exception('You are not logged in.');
  
  try {
    // از تابع جدید در ApiService استفاده می‌کنیم و تمام پارامترهای لازم را ارسال می‌کنیم
    final response = await _apiService.createSubjectOrder(
      subjectId: subjectId,
      planKey: duration, // planKey در بک‌اند همان duration است
      planDuration: planDuration,
      planPrice: planPrice,
      token: _token!,
    );
    
    // API جدید دیگر آبجکت user را برنمی‌گرداند، فقط یک پیام موفقیت
    // بنابراین ما هم فقط همان پیام را برمی‌گردانیم
    return response;

  } catch (e) {
    rethrow; // خطا را به UI ارسال کن تا نمایش داده شود
  }
}
}