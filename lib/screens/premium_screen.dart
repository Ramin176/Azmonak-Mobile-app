import 'package:flutter/material.dart';

class PremiumScreen extends StatelessWidget {
  const PremiumScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // رنگ Teal
    const tealColor = Color(0xFF008080);

    return Scaffold(
      appBar: AppBar(
        title: const Text('عضویت ویژه'),
        backgroundColor: tealColor,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Icon(Icons.star, color: Colors.amber, size: 80),
            const SizedBox(height: 16),
            const Text(
              'به دنیای آزمونک پرمیوم بپیوندید!',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: tealColor),
            ),
            const SizedBox(height: 8),
            const Text(
              'با دسترسی نامحدود به تمام سوالات، شانس قبولی خود را تضمین کنید.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16, color: Colors.black54),
            ),
            const SizedBox(height: 32),
            
            // لیست پلن‌ها
            _buildPlanCard('۱ هفته', '۱۰۰ دالر'),
            _buildPlanCard('۱ ماه', '۲۰۰ دالر'),
            _buildPlanCard('۳ ماه', '۴۰۰ دالر'),
            _buildPlanCard('۶ ماه', '۵۵۰ دالر'),
            _buildPlanCard('۱ سال', '۷۰۰ دالر'),

            const SizedBox(height: 32),
            const Divider(),
            const SizedBox(height: 16),

            const Text(
              'نحوه پرداخت',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            const Card(
              elevation: 0,
              color: Color(0xFFF0F8FF),
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: Text(
                  'لطفا مبلغ پلن مورد نظر را به حساب بانکی X واریز کرده و رسید آن را به همراه ایمیل حساب کاربری خود به آیدی تلگرام @AzmoonakSupport ارسال کنید. حساب شما طی ۲۴ ساعت فعال خواهد شد.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 15, height: 1.5),
                ),
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildPlanCard(String duration, String price) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: ListTile(
        leading: const Icon(Icons.check_circle, color: Color(0xFF008080)),
        title: Text(duration, style: const TextStyle(fontWeight: FontWeight.bold)),
        trailing: Text(price, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF008080))),
      ),
    );
  }
}