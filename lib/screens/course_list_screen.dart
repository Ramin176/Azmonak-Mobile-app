import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
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
  final ApiService _apiService = ApiService();
  late Future<List<Course>> _coursesFuture;
  final List<Course> _selectedCoursesInThisScreen = [];

  @override
  void initState() {
    super.initState();
    final token = Provider.of<AuthProvider>(context, listen: false).token;
    _coursesFuture = _apiService.fetchCoursesByCategory(widget.category.id, token!);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.category.name),
        backgroundColor: const Color(0xFF008080),
        actions: widget.isPickerMode ? [
          IconButton(
            icon: const Icon(Icons.check),
            onPressed: _selectedCoursesInThisScreen.isEmpty ? null : () {
              Navigator.of(context).pop(_selectedCoursesInThisScreen);
            },
          )
        ] : null,
      ),
      body: FutureBuilder<List<Course>>(
        future: _coursesFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('خطا: ${snapshot.error}'));
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('هیچ دوره‌ای در این دسته‌بندی یافت نشد.'));
          }
          
          final courses = snapshot.data!;
          return ListView.builder(
            itemCount: courses.length,
            itemBuilder: (ctx, index) {
              final course = courses[index];
              if (widget.isPickerMode) {
                final isSelected = _selectedCoursesInThisScreen.any((c) => c.id == course.id);
                return CheckboxListTile(
                  title: Text(course.name),
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
                );
              } else {
                return ListTile(
                  title: Text(course.name),
                  onTap: () { /* در حالت عادی، می‌توان به صفحه جزئیات دوره رفت */ }
                );
              }
            },
          );
        },
      ),
    );
  }
}