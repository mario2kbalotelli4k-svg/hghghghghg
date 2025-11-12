import 'package:flutter/material.dart';

class SplashScreen extends StatefulWidget {
  final VoidCallback showAd;

  const SplashScreen({
    super.key,
    required this.showAd,
  });

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  int progress = 0;

  @override
  void initState() {
    super.initState();
    _startLoading();
  }

  void _startLoading() {
    Future.delayed(const Duration(milliseconds: 50), () {
      setState(() {
        if (progress < 100) {
          progress += 2;
          _startLoading();
        } else {
          // ✅ نضيف تأخير بسيط قبل عرض الإعلان لضمان تحميل الإعلان
          Future.delayed(const Duration(seconds: 2), () {
            widget.showAd(); // عرض الإعلان بعد التأخير
            // تأخير إضافي للانتقال للصفحة الرئيسية بعد عرض الإعلان
            Future.delayed(const Duration(seconds: 1), () {
              if (mounted) {
                Navigator.pushReplacementNamed(context, '/home');
              }
            });
          });
        }
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 10, 1, 41),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'Smart market',
              style: TextStyle(
                fontSize: 34,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 30),
            Stack(
              alignment: Alignment.center,
              children: [
                CircularProgressIndicator(
                  value: progress / 100,
                  backgroundColor: Colors.grey[300],
                  color: const Color.fromARGB(255, 37, 1, 46),
                  strokeWidth: 6,
                ),
                Text(
                  '$progress%',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
