import 'package:flutter/material.dart';

import 'package:hive_flutter/hive_flutter.dart';

class AboutUsScreen extends StatefulWidget {
  const AboutUsScreen({super.key});

  @override
  State<AboutUsScreen> createState() => _AboutUsScreenState();
}

class _AboutUsScreenState extends State<AboutUsScreen> {
  String _aboutText = "در حال بارگذاری محتوا...";
  // Helper to get responsive sizes based on screen width
  double _getResponsiveSize(BuildContext context, double baseSize) {
    final screenWidth = MediaQuery.of(context).size.width;
    // Adjust this multiplier as needed for different screen sizes
    return baseSize * (screenWidth / 375.0); // Assuming 375 is a common base width (e.g., iPhone 8)
  }
  @override
  void initState() {
    super.initState();
    _loadAboutText();
  }

  Future<void> _loadAboutText() async {
    // متن را از Box 'app_settings' در Hive بخوان
    try {
      final settingsBox = await Hive.openBox('app_settings');
      final savedText = settingsBox.get(
        'about_us_text', 
        defaultValue: 'محتوایی یافت نشد. لطفا به اینترنت متصل شده و برنامه را دوباره باز کنید.'
      );
      if (mounted) {
        setState(() {
          _aboutText = savedText;
        });
      }
    } catch (e) {
      print("Error loading 'About Us' text from Hive: $e");
      if(mounted) {
        setState(() {
          _aboutText = "خطا در بارگذاری محتوا.";
        });
      }
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title:  Text('درباره ما',  style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontFamily: 'Vazirmatn',
            fontSize: _getResponsiveSize(context, 20),
          ),),
        backgroundColor: Color(0xFF008080),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Icon(Icons.school_rounded, size: 80, color: Theme.of(context).primaryColor),
            const SizedBox(height: 16),
            Text(
              'آزمونک طبی',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: Theme.of(context).primaryColor,
              ),
            ),
            const SizedBox(height: 24),
            // نمایش متن با استایل خوانا و justify
            Text(
              _aboutText,
              textAlign: TextAlign.justify,
              style: const TextStyle(fontSize: 16, height: 1.8, color: Colors.black87),
            ),
          ],
        ),
      ),
    );
  }
}