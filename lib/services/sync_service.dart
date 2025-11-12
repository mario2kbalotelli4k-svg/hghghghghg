import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';
import 'package:smart_market/config.dart';
import 'package:smart_market/services/remote_fetcher.dart';

/// Central sync service that keeps local cached copies of remote JSON files and
/// triggers listeners via ChangeNotifier. Start this service early (e.g. in
/// main()) so it runs while the app is alive.
class SyncService extends ChangeNotifier {
  static final SyncService _instance = SyncService._internal();
  factory SyncService() => _instance;
  SyncService._internal();

  late RemoteFetcher<Map<String, dynamic>> homeFetcher;
  late RemoteFetcher<Map<String, dynamic>> calculatorFetcher;
  late RemoteFetcher<Map<String, dynamic>> goldFetcher;
  late RemoteFetcher<Map<String, dynamic>> cryptoFetcher;

  Map<String, dynamic>? homeData;
  Map<String, dynamic>? calculatorData;
  Map<String, dynamic>? goldData;
  Map<String, dynamic>? cryptoData;

  Future<void> init() async {
    // create fetchers with desired intervals
    homeFetcher = RemoteFetcher<Map<String, dynamic>>(
      url: homeJsonUrl,
      interval: const Duration(hours: 8),
      parser: (json) => Map<String, dynamic>.from(json),
    );

    calculatorFetcher = RemoteFetcher<Map<String, dynamic>>(
      url: calculatorJsonUrl,
      interval: const Duration(hours: 8),
      parser: (json) => Map<String, dynamic>.from(json),
    );

    goldFetcher = RemoteFetcher<Map<String, dynamic>>(
      url: goldJsonUrl,
      interval: const Duration(hours: 8),
      parser: (json) => Map<String, dynamic>.from(json),
    );

    cryptoFetcher = RemoteFetcher<Map<String, dynamic>>(
      url: cryptoJsonUrl,
      interval: const Duration(seconds: 10),
      parser: (json) => Map<String, dynamic>.from(json),
    );

    // load cached values from preferences if any
    final prefs = await SharedPreferences.getInstance();
    final h = prefs.getString('sync_home');
    final c = prefs.getString('sync_calculator');
    final g = prefs.getString('sync_gold');
    final x = prefs.getString('sync_crypto');

    if (h != null) homeData = json.decode(h);
    if (c != null) calculatorData = json.decode(c);
    if (g != null) goldData = json.decode(g);
    if (x != null) cryptoData = json.decode(x);

    // start polling
    homeFetcher.start();
    calculatorFetcher.start();
    goldFetcher.start();
    cryptoFetcher.start();

    // periodic saver/notify loop
    Timer.periodic(const Duration(seconds: 5), (_) => _collect());
  }

  Future<void> _collect() async {
    bool changed = false;
    final prefs = await SharedPreferences.getInstance();

    if (homeFetcher.last != null) {
      final value = homeFetcher.last!;
      if (!mapEquals(value, homeData)) {
        homeData = value;
        await prefs.setString('sync_home', json.encode(value));
        changed = true;
      }
    }

    if (calculatorFetcher.last != null) {
      final value = calculatorFetcher.last!;
      if (!mapEquals(value, calculatorData)) {
        calculatorData = value;
        await prefs.setString('sync_calculator', json.encode(value));
        changed = true;
      }
    }

    if (goldFetcher.last != null) {
      final value = goldFetcher.last!;
      if (!mapEquals(value, goldData)) {
        goldData = value;
        await prefs.setString('sync_gold', json.encode(value));
        changed = true;
      }
    }

    if (cryptoFetcher.last != null) {
      final value = cryptoFetcher.last!;
      if (!mapEquals(value, cryptoData)) {
        cryptoData = value;
        await prefs.setString('sync_crypto', json.encode(value));
        changed = true;
      }
    }

    if (changed) notifyListeners();
  }

  // helper getters for pages to read
  Map<String, dynamic>? getHomeData() => homeData;
  Map<String, dynamic>? getCalculatorData() => calculatorData;
  Map<String, dynamic>? getGoldData() => goldData;
  Map<String, dynamic>? getCryptoData() => cryptoData;

  void disposeService() {
    homeFetcher.stop();
    calculatorFetcher.stop();
    goldFetcher.stop();
    cryptoFetcher.stop();
  }
}
