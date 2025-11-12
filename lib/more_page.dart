import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class MorePage extends StatefulWidget {
  const MorePage({super.key});

  @override
  State<MorePage> createState() => _MorePageState();
}

class _MorePageState extends State<MorePage> {
  final List<Map<String, String>> links = [
    {
      'title': 'Instagram Page',
      'url': 'http://www.instagram.com/smart_kurrency07',
    },
    {
      'title': 'Facebook Page',
      'url': 'https://www.facebook.com/share/1Q8WigQNH1/',
    },
    {
      'title': 'Telegram Channel',
      'url': 'https://t.me/smart2currency',
    },
  ];

  final List<Map<String, String>> faqs = [
    {
      'question': 'What is the purpose of Smart Currency App?',
      'answer':
          'The app helps users convert currencies, track exchange rates, and manage their portfolio efficiently.',
    },
    {
      'question': 'How often are exchange rates updated?',
      'answer': 'Exchange rates are updated in real-time to ensure accuracy.',
    },
    {
      'question': 'Can I track cryptocurrency prices?',
      'answer': 'Yes, the app provides live updates for cryptocurrency prices.',
    },
    {
      'question': 'Is the app free to use?',
      'answer': 'Yes, the app is completely free with no hidden charges.',
    },
  ];

  void _launchURL(String url) async {
    final Uri uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      throw 'Could not launch $url';
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('More'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          // إضافة ScrollView لتجنب مشاكل العرض
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // الروابط
              ...links.map((link) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor:
                          isDarkMode ? Colors.black87 : Colors.grey[200],
                      foregroundColor: isDarkMode ? Colors.white : Colors.black,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    onPressed: () => _launchURL(link['url']!),
                    child: Text(
                      link['title']!,
                      style: const TextStyle(
                          fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                  ),
                );
              }),

              const SizedBox(height: 30),

              // الأسئلة والأجوبة
              const Text(
                'FAQs',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),
              ...faqs.map((faq) {
                return ExpansionTile(
                  title: Text(
                    faq['question']!,
                    style: const TextStyle(
                        fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: Text(
                        faq['answer']!,
                        style: const TextStyle(fontSize: 16),
                      ),
                    ),
                  ],
                );
              })
            ],
          ),
        ),
      ),
    );
  }
}
