import 'package:azmoonak_app/screens/aboutUs.dart';
import 'package:azmoonak_app/screens/premium_screen.dart';
import 'package:flutter/material.dart';
import 'home_screen.dart';
import 'profile_screen.dart'; // فرض می‌کنیم این صفحه وجود دارد
// import 'test_history_screen.dart'; // صفحه‌ای برای تاریخچه آزمون‌ها

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;

  // لیست صفحاتی که در ناوبری نمایش داده می‌شوند
  static const List<Widget> _widgetOptions = <Widget>[
      HomeScreen(),
       ProfileScreen(),
       PremiumScreen(),
    AboutUsScreen(),
   
  
    // TestHistoryScreen(), // در آینده
    
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    const tealColor = Color(0xFF008080); // رنگ اصلی Teal

    return Scaffold(
      body: Center(
        child: _widgetOptions.elementAt(_selectedIndex),
      ),
      bottomNavigationBar: BottomNavigationBar(
         type: BottomNavigationBarType.fixed,
        items: const <BottomNavigationBarItem>[
             BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'خانه',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'پروفایل',
          ),
            BottomNavigationBarItem(
            icon: Icon(Icons.local_mall),
            label: 'بسته ها',
          ),
        
          
           BottomNavigationBarItem(
            icon: Icon(Icons.info),
            label: 'درباره ما',
          ),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: tealColor, 
        onTap: _onItemTapped,
      ),
    );
  }
}