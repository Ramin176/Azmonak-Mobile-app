import 'package:azmoonak_app/helpers/hive_db_service.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../helpers/adaptive_text_size.dart'; // Import the new helper
import '../models/category.dart';
import '../models/course.dart';
import '../providers/auth_provider.dart';
import '../services/api_service.dart';

class CourseListScreen extends StatefulWidget {
  final Category category;
  final bool isPickerMode;
  const CourseListScreen({super.key, required this.category, this.isPickerMode = false});

  @override
  State<CourseListScreen> createState() => _CourseListScreenState();
}

class _CourseListScreenState extends State<CourseListScreen> {
  // final ApiService _apiService = ApiService();
  // final List<Course> _selectedCoursesInThisScreen = [];
    final ApiService _apiService = ApiService();
  final HiveService _hiveService = HiveService();
  
  List<Course> _courses = [];
  bool _isLoading = true;
  String _errorMessage = '';
  final List<Course> _selectedCoursesInThisScreen = [];

  // --- پالت رنگی جدید (Teal) از HomeScreen ---
  static const Color primaryTeal = Color(0xFF008080); // Teal اصلی
  static const Color lightTeal = Color(0xFF4DB6AC); // Teal روشن‌تر
  static const Color darkTeal = Color(0xFF004D40); // Teal تیره‌تر
  static const Color accentYellow = Color(0xFFFFD700); // زرد تاکید (برای ستاره)
  static const Color textDark = Color(0xFF212121); // متن تیره
  static const Color textMedium = Color(0xFF607D8B); // متن متوسط
  static const Color backgroundLight = Color(0xFFF8F9FA); // پس‌زمینه روشن

  @override
  void initState() {
    super.initState();
    // final token = Provider.of<AuthProvider>(context, listen: false).token;
    // _coursesFuture = _apiService.fetchCoursesByCategory(widget.category.id, token!);
       _loadInitialData();
  }

  // Helper to get responsive sizes based on screen width
  double _getResponsiveSize(BuildContext context, double baseSize) {
    final screenWidth = MediaQuery.of(context).size.width;
    // Adjust this multiplier as needed for different screen sizes
    return baseSize * (screenWidth / 375.0); // Assuming 375 is a common base width (e.g., iPhone 8)
  }
    Future<void> _loadInitialData() async {
    if (!mounted) return;
    setState(() { _isLoading = true; _errorMessage = ''; });

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final user = authProvider.user;
      if (user == null) throw Exception('کاربر یافت نشد.');

      // ۱. همیشه و اول از همه، از دیتابیس محلی (Hive) بخوان
      final localCourses = await _hiveService.getCoursesByCategory(widget.category.id, user.id);
      if (mounted) {
        setState(() {
          _courses = localCourses;
          _isLoading = false;
        });
      }

      // ۲. حالا وضعیت اینترنت را برای به‌روزرسانی در پس‌زمینه چک کن
      final connectivityResult = await (Connectivity().checkConnectivity());
      if (connectivityResult != ConnectivityResult.none) {
        final onlineCourses = await _apiService.fetchCoursesByCategory(widget.category.id, authProvider.token!);
        if (mounted) {
          setState(() { _courses = onlineCourses; });
        }
      } else {
        if (localCourses.isEmpty) {
          setState(() { _errorMessage = 'شما آفلاین هستید و هیچ دوره‌ای برای این بخش ذخیره نشده است.'; });
        }
      }
    } catch(e) {
      if (mounted) setState(() { _errorMessage = 'خطا در بارگذاری دوره‌ها.'; e.toString(); });
    } finally {
      if (mounted && _isLoading) setState(() { _isLoading = false; });
    }
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundLight,
      appBar: AppBar(
        backgroundColor: primaryTeal,
        elevation: 0,
        centerTitle: true,
        title: AdaptiveTextSize(
          text: widget.category.name,
          style: TextStyle(
            fontSize: _getResponsiveSize(context, 20),
            fontWeight: FontWeight.bold,
            color: Colors.white,
            fontFamily: 'Vazirmatn',
          ),
        ),
        actions: widget.isPickerMode
            ? [
                IconButton(
                  icon: Icon(
                    Icons.check_circle_rounded,
                    color: _selectedCoursesInThisScreen.isEmpty ? Colors.white.withOpacity(0.5) : accentYellow,
                    size: _getResponsiveSize(context, 28),
                  ),
                  onPressed: _selectedCoursesInThisScreen.isEmpty
                      ? null
                      : () {
                          Navigator.of(context).pop(_selectedCoursesInThisScreen);
                        },
                ),
                SizedBox(width: _getResponsiveSize(context, 8)),
              ]
            : null,
      ),
      body: _isLoading
        ? Center(child: CircularProgressIndicator(color: primaryTeal))
        : _errorMessage.isNotEmpty
          ? Center(child: Text(_errorMessage))
          : ListView.builder(
              padding: EdgeInsets.all(_getResponsiveSize(context, 16.0)),
              itemCount: _courses.length,
              itemBuilder: (ctx, index) {
                final course = _courses[index];
                return _buildCourseCard(course);
              },
            ),
    );
  }
      //  FutureBuilder<List<Course>>(
      //   future: _coursesFuture,
      //   builder: (context, snapshot) {
      //     if (snapshot.connectionState == ConnectionState.waiting) {
      //       return Center(
      //           child: CircularProgressIndicator(
      //         color: primaryTeal,
      //       ));
      //     }
      //     if (snapshot.hasError) {
      //       return Center(
      //           child: Padding(
      //         padding: EdgeInsets.all(_getResponsiveSize(context, 24.0)),
      //         child: AdaptiveTextSize(
      //           text: 'خطا در بارگذاری دوره‌ها: ${snapshot.error}',
      //           textAlign: TextAlign.center,
      //           style: TextStyle(color: Colors.red.shade700, fontFamily: 'Vazirmatn', fontSize: _getResponsiveSize(context, 16)),
      //         ),
      //       ));
      //     }
      //     if (!snapshot.hasData || snapshot.data!.isEmpty) {
      //       return Center(
      //           child: Padding(
      //         padding: EdgeInsets.all(_getResponsiveSize(context, 24.0)),
      //         child: AdaptiveTextSize(
      //           text: 'هیچ دوره‌ای در این دسته‌بندی یافت نشد.',
      //           textAlign: TextAlign.center,
      //           style: TextStyle(color: textMedium, fontFamily: 'Vazirmatn', fontSize: _getResponsiveSize(context, 16)),
      //         ),
      //       ));
      //     }

      //     final courses = snapshot.data!;
      //     return ListView.builder(
      //       padding: EdgeInsets.all(_getResponsiveSize(context, 16.0)),
      //       itemCount: courses.length,
      //       itemBuilder: (ctx, index) {
      //         final course = courses[index];
      //         return _buildCourseCard(course);
      //       },
      //     );
      //   },
      // ),
  
  

  Widget _buildCourseCard(Course course) {
    final isSelected = _selectedCoursesInThisScreen.any((c) => c.id == course.id);

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(_getResponsiveSize(context, 20))),
      margin: EdgeInsets.symmetric(vertical: _getResponsiveSize(context, 8)),
      child: InkWell(
        borderRadius: BorderRadius.circular(_getResponsiveSize(context, 20)),
        onTap: () {
          if (widget.isPickerMode) {
            setState(() {
              if (isSelected) {
                _selectedCoursesInThisScreen.removeWhere((c) => c.id == course.id);
              } else {
                _selectedCoursesInThisScreen.add(course);
              }
            });
          } 
          // else {
          //   // TODO: Implement navigation to CourseDetailsScreen or similar
          //   ScaffoldMessenger.of(context).showSnackBar(
          //     SnackBar(content: AdaptiveTextSize(text: 'دوره ${course.name} کلیک شد!', style: TextStyle(fontFamily: 'Vazirmatn'))),
          //   );
          // }
        },
        child: Container(
          padding: EdgeInsets.symmetric(
              horizontal: _getResponsiveSize(context, 20.0), vertical: _getResponsiveSize(context, 16.0)),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(_getResponsiveSize(context, 20)),
            gradient: LinearGradient(
              colors: isSelected
                  ? [lightTeal.withOpacity(0.15), Colors.white]
                  : [Colors.white, backgroundLight],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            border: isSelected ? Border.all(color: primaryTeal, width: _getResponsiveSize(context, 2)) : null,
          ),
          child: Row(
            children: [
              if (widget.isPickerMode)
                Checkbox(
                  value: isSelected,
                  onChanged: (bool? value) {
                    setState(() {
                      if (value == true) {
                        _selectedCoursesInThisScreen.add(course);
                      } else {
                        _selectedCoursesInThisScreen.removeWhere((c) => c.id == course.id);
                      }
                    });
                  },
                  activeColor: primaryTeal,
                  checkColor: Colors.white,
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap, // برای کوچک‌تر کردن فضای لمس
                ),
              SizedBox(width: _getResponsiveSize(context, widget.isPickerMode ? 8 : 0)),
              Expanded(
                child: AdaptiveTextSize(
                  text: course.name,
                  style: TextStyle(
                    fontSize: _getResponsiveSize(context, 17),
                    fontWeight: FontWeight.bold,
                    color: textDark,
                    fontFamily: 'Vazirmatn',
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (!widget.isPickerMode)
                Icon(Icons.arrow_forward_ios_rounded, color: textMedium.withOpacity(0.7), size: _getResponsiveSize(context, 20)),
              if (widget.isPickerMode && isSelected) // آیکون انتخاب شده در حالت Picker
                Icon(Icons.check_circle_outline, color: primaryTeal, size: _getResponsiveSize(context, 24)),
            ],
          ),
        ),
      ),
    );
  }
}