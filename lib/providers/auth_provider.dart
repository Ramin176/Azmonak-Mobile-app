import 'dart:convert';
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

  String? _token;
  AppUser? _user;

  bool get isAuthenticated => _token != null && _user != null;
  String? get token => _token;
  AppUser? get user => _user;
  String? _errorMessage;
  String? get errorMessage => _errorMessage;
    final HiveService _hiveService = HiveService();
Future<bool> _handleAuthResponse(Map<String, dynamic> response) async {
    _errorMessage = null;
    if (response.containsKey('token') && response.containsKey('user')) {
      _token = response['token'];
      
      // ۱. آبجکت کاربر را از پاسخ سرور بساز
      final userFromServer = AppUser.fromJson(response['user']);
      
      // ۲. آبجکت کاربر قدیمی (که ممکن است عکس داشته باشد) را از Hive بخوان
      final userBox = await Hive.openBox<AppUser>('userBox');
      final oldUser = userBox.get('currentUser');
      
      // ۳. اطلاعات عکس را از کاربر قدیمی به کاربر جدید منتقل کن
      if (oldUser != null && oldUser.id == userFromServer.id) {
        userFromServer.profileImagePath = oldUser.profileImagePath;
      }
      
      _user = userFromServer;
      
      // ۴. اطلاعات کامل و ترکیب شده را در حافظه ذخیره کن
      await _storage.write(key: 'token', value: _token);
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
    try {
      final token = await _storage.read(key: 'token');
      final userBox = await Hive.openBox<AppUser>('userBox');
      final user = userBox.get('currentUser');
      if (token != null && user != null && user.id.isNotEmpty) {
         final prefs = await SharedPreferences.getInstance();
      final imagePath = prefs.getString('profile_image_path_${user.id}'); 
      _user = user.copyWith(profileImagePath: imagePath);
        _token = token;
        _user = user;
        notifyListeners();
        // رفرش در پس‌زمینه برای گرفتن آخرین وضعیت اشتراک
        refreshUser(); 
        return true;
      }
      await logout();
      return false;
    } catch (e) {
      await logout();
      return false;
    }
  }
  
  Future<void> refreshUser() async {
    if (_token == null) return;
    try {
      final userData = await _apiService.fetchCurrentUser(_token!);
      final currentUser = AppUser.fromJson(userData);
      currentUser.profileImagePath = _user?.profileImagePath;
      _user = currentUser;
      
      final userBox = await Hive.openBox<AppUser>('userBox');
      await userBox.put('currentUser', _user!);
      notifyListeners();
    } catch (e) {
      print("Failed to refresh user: $e");
    }
  }
}