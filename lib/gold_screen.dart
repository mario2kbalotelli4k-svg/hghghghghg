import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:share_plus/share_plus.dart';
import 'package:csv/csv.dart';

class GoldScreen extends StatefulWidget {
  const GoldScreen({super.key});

  @override
  _GoldScreenState createState() => _GoldScreenState();
}

class _GoldScreenState extends State<GoldScreen> {
  final String goldApiUrl =
      'https://raw.githubusercontent.com/Khatym/khatom00007/main/gold.json';

  final String currencyApiUrl =
      'https://raw.githubusercontent.com/Khatym/khatom00007/main/currency.json';

  final String sdgApiUrl =
      'https://docs.google.com/spreadsheets/d/17gLQV0dE_rDv_WU83-FZuZCttlDUkj9nkz6LaXhduJ0/export?format=csv';

  final Map<String, double> karatFactors = {
    '24': 1.0,
    '22': 22 / 24,
    '21': 21 / 24,
    '20': 20 / 24,
    '18': 18 / 24,
    '16': 16 / 24,
    '14': 14 / 24,
    '12': 12 / 24,
    '10': 10 / 24,
    '9': 9 / 24,
    '8': 8 / 24,
  };

  final List<Map<String, String>> currencies = [
    {'code': 'USD', 'name': 'USD - US Dollar', 'flag': '🇺🇸'},
    {'code': 'SDG', 'name': 'SDG - Sudanese Pound', 'flag': '🇸🇩'},
    {'code': 'EGP', 'name': 'EGP - Egyptian Pound', 'flag': '🇪🇬'},
    {'code': 'SAR', 'name': 'SAR - Saudi Riyal', 'flag': '🇸🇦'},
  ];

  String selectedCurrency = 'USD';
  Map<String, double> prices = {};
  Map<String, double> previousPrices = {};
  Map<String, Map<String, double>> allPreviousPrices =
      {}; // currency -> {karat: price}
  Set<String> favoriteKarats = {};
  bool isLoading = true;

  // SDG rates for percentage calculation
  double? sdgCurrentRate;
  double? sdgPreviousRate;

  @override
  void initState() {
    super.initState();
    loadFavorites();
    loadPrices();
  }

  Future<void> loadFavorites() async {
    final prefs = await SharedPreferences.getInstance();
    final favs = prefs.getStringList('favorite_karats') ?? [];
    setState(() {
      favoriteKarats = favs.toSet();
    });
  }

  Future<void> toggleFavorite(String karat) async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      if (favoriteKarats.contains(karat)) {
        favoriteKarats.remove(karat);
      } else {
        favoriteKarats.add(karat);
      }
    });
    await prefs.setStringList('favorite_karats', favoriteKarats.toList());
  }

  Future<void> loadPrices() async {
    final prefs = await SharedPreferences.getInstance();
    final lastUpdated = prefs.getInt('last_updated_gold') ?? 0;
    final now = DateTime.now().millisecondsSinceEpoch;

    // تحميل previousPrices لكل عملة
    final prevPricesStr = prefs.getString('gold_previous_prices') ?? '{}';
    allPreviousPrices = Map<String, Map<String, double>>.from(
      (json.decode(prevPricesStr) as Map).map((k, v) => MapEntry(
            k,
            Map<String, double>.from(v as Map),
          )),
    );
    previousPrices = allPreviousPrices[selectedCurrency] ?? {};

    double? goldPriceUSD;

    // Load previous SDG rate for percentage calculation
    sdgPreviousRate = prefs.getDouble('gold_sdg_previous_rate');

    if (now - lastUpdated >= 8 * 60 * 60 * 1000) {
      goldPriceUSD = await fetchGoldPrice();
      if (goldPriceUSD != null) {
        await prefs.setDouble('gold_price_usd', goldPriceUSD);
        await prefs.setInt('last_updated_gold', now);
      }
    } else {
      goldPriceUSD = prefs.getDouble('gold_price_usd');
      if (goldPriceUSD == null) {
        goldPriceUSD = await fetchGoldPrice();
        if (goldPriceUSD != null) {
          await prefs.setDouble('gold_price_usd', goldPriceUSD);
          await prefs.setInt('last_updated_gold', now);
        }
      }
    }

    if (goldPriceUSD != null) {
      await calculatePrices(goldPriceUSD);
    } else {
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<double?> fetchGoldPrice() async {
    try {
      final goldRes = await http.get(Uri.parse(goldApiUrl));
      if (goldRes.statusCode == 200) {
        final data = json.decode(goldRes.body);
        final price = (data['price'] as num?)?.toDouble();
        return price;
      }
    } catch (e) {
      // ignore
    }
    return null;
  }

  Future<double?> fetchSDGRateFromGoogleSheet() async {
    try {
      final response = await http.get(Uri.parse(sdgApiUrl));
      if (response.statusCode == 200) {
        final csvTable = const CsvToListConverter().convert(response.body);
        for (int i = 1; i < csvTable.length; i++) {
          final row = csvTable[i];
          if (row[0].toString().trim().toUpperCase() == 'SDG') {
            return double.tryParse(row[1].toString().replaceAll(',', ''));
          }
        }
      }
    } catch (e) {
      print('Error fetching SDG rate: $e');
    }
    return null;
  }

  Future<void> calculatePrices(double goldPriceUSD) async {
    double exchangeRate = 1.0;

    if (selectedCurrency == 'SDG') {
      try {
        // استخدم csv/csv.dart لجلب سعر SDG من Google Sheet
        final sdgRate = await fetchSDGRateFromGoogleSheet();
        if (sdgRate != null) {
          exchangeRate = sdgRate;
          sdgCurrentRate = exchangeRate;

          // حفظ آخر سعر SDG للمقارنة في التحديث القادم
          final prefs = await SharedPreferences.getInstance();
          await prefs.setDouble('gold_sdg_previous_rate', sdgCurrentRate!);
        }
      } catch (e) {}
    } else if (selectedCurrency != 'USD') {
      try {
        final res = await http.get(Uri.parse(currencyApiUrl));
        if (res.statusCode == 200) {
          final data = json.decode(res.body);
          final rate = (data['rates'][selectedCurrency] as num?)?.toDouble();
          exchangeRate = rate ?? 1.0;
        }
      } catch (e) {}
    }

    final gramPrice = goldPriceUSD / 31.1035;
    final newPrices = <String, double>{};

    karatFactors.forEach((karat, factor) {
      newPrices[karat] =
          double.parse((gramPrice * factor * exchangeRate).toStringAsFixed(2));
    });

    // حفظ الأسعار الحالية كـ previousPrices للعملة الحالية
    final prefs = await SharedPreferences.getInstance();
    allPreviousPrices[selectedCurrency] = newPrices;
    await prefs.setString(
        'gold_previous_prices', json.encode(allPreviousPrices));

    setState(() {
      prices = newPrices;
      isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor =
        isDark ? const Color.fromARGB(255, 236, 237, 239) : Colors.white;

    return Scaffold(
      appBar: AppBar(
        title: const Text('أسعار الذهب'),
        backgroundColor: isDark ? const Color(0xFF181A20) : Colors.white,
        elevation: 0,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 16.0),
            child: DropdownButton<String>(
              value: selectedCurrency,
              underline: const SizedBox(),
              onChanged: (val) {
                if (val != null) {
                  setState(() {
                    selectedCurrency = val;
                    isLoading = true;
                  });
                  loadPrices();
                }
              },
              items: currencies.map((currency) {
                return DropdownMenuItem<String>(
                  value: currency['code'],
                  child: Row(
                    children: [
                      Text(currency['flag'] ?? ''),
                      const SizedBox(width: 8),
                      Text(currency['code'] ?? ''),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
          isLoading
              ? const Expanded(
                  child: Center(child: CircularProgressIndicator()))
              : Expanded(
                  child: ListView(
                    padding: const EdgeInsets.all(8),
                    children: prices.entries.map((entry) {
                      final karat = entry.key;
                      final price = entry.value;
                      final prevPrice = previousPrices[karat];

                      double percentChange = 0.0;

                      if (prevPrice != null && prevPrice != 0) {
                        percentChange = ((price - prevPrice) / prevPrice) * 100;
                      }

                      final percentColor = percentChange > 0
                          ? Colors.green
                          : percentChange < 0
                              ? Colors.red
                              : Colors.grey;

                      final arrowIcon = percentChange > 0
                          ? Icons.arrow_upward
                          : percentChange < 0
                              ? Icons.arrow_downward
                              : Icons.remove;

                      return Card(
                        elevation: 3,
                        color: cardColor,
                        margin: const EdgeInsets.symmetric(vertical: 6),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15),
                          side: BorderSide(
                            color: Colors.transparent,
                            width: 0,
                          ),
                        ),
                        child: Column(
                          children: [
                            ListTile(
                              leading: Image.asset(
                                'assets/images/gold/gold_bar.png',
                                width: 60,
                                height: 60,
                              ),
                              title: Text(
                                'عيار $karat',
                                style: const TextStyle(
                                    color: Colors.black,
                                    fontWeight: FontWeight.bold),
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'السعر: $price $selectedCurrency',
                                    style: const TextStyle(color: Colors.black),
                                  ),
                                  const SizedBox(height: 4),
                                  Row(
                                    children: [
                                      Icon(
                                        arrowIcon,
                                        color: percentColor,
                                        size: 18,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        '${percentChange > 0 ? '+' : ''}${percentChange.toStringAsFixed(2)}%',
                                        style: TextStyle(
                                          color: percentColor,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.share,
                                        color: Colors.blueAccent),
                                    tooltip: 'مشاركة سعر الذهب',
                                    onPressed: () {
                                      Share.share(
                                        'سعر الذهب عيار $karat: $price $selectedCurrency\n'
                                        'نسبة التغير: ${percentChange.toStringAsFixed(2)}%\n'
                                        '📱 تابع الأسعار أول بأول من تطبيق "العملة الذكية":\n'
                                        'https://play.google.com/store/apps/details?id=com.yourapp.id',
                                      );
                                    },
                                    splashRadius: 22,
                                  ),
                                  IconButton(
                                    icon: Icon(
                                      favoriteKarats.contains(karat)
                                          ? Icons.favorite
                                          : Icons.favorite_border,
                                      color: favoriteKarats.contains(karat)
                                          ? Colors.red
                                          : Colors.black,
                                      size: 24,
                                    ),
                                    tooltip: favoriteKarats.contains(karat)
                                        ? 'إزالة من المفضلة'
                                        : 'إضافة إلى المفضلة',
                                    onPressed: () => toggleFavorite(karat),
                                    splashRadius: 22,
                                  ),
                                ],
                              ),
                            ),
                            Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 16),
                              child: Divider(
                                color: isDark ? Colors.white : Colors.grey[300],
                                thickness: 1,
                                height: 0,
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                ),
        ],
      ),
    );
  }
}
