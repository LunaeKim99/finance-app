import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../constants/currencies.dart';

class ExchangeRateService {
  ExchangeRateService._();

  static final ExchangeRateService _instance = ExchangeRateService._();
  static ExchangeRateService get instance => _instance;

  static const String _baseUrl = 'https://open.er-api.com/v6/latest/USD';
  static const String _prefsKey = 'cached_exchange_rates';
  static const String _prefsTimestamp = 'cached_exchange_rates_timestamp';
  static const Duration _cacheDuration = Duration(minutes: 30);

  Map<String, double> _rates = Map.from(AppCurrencies.defaultRates);
  DateTime? _lastUpdated;

  Map<String, double> get rates => Map.unmodifiable(_rates);
  DateTime? get lastUpdated => _lastUpdated;

  double getRate(String currencyCode) {
    return _rates[currencyCode] ?? AppCurrencies.defaultRates[currencyCode] ?? 1.0;
  }

  Future<void> initialize() async {
    await _loadCache();
    if (_isStale()) {
      await _fetchRates();
    }
  }

  Future<void> refreshIfNeeded() async {
    if (_isStale()) {
      await _fetchRates();
    }
  }

  Future<void> _fetchRates() async {
    try {
      final response = await http
          .get(Uri.parse(_baseUrl))
          .timeout(const Duration(seconds: 10));

      if (response.statusCode != 200) return;

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final usdRates = data['rates'] as Map<String, dynamic>;

      final usdToIdr = (usdRates['IDR'] as num).toDouble();

      final Map<String, double> idrBased = {};
      for (final entry in AppCurrencies.defaultRates.entries) {
        if (entry.key == 'IDR') {
          idrBased['IDR'] = 1.0;
          continue;
        }
        final usdRate = usdRates[entry.key];
        if (usdRate != null) {
          idrBased[entry.key] = usdToIdr / (usdRate as num).toDouble();
        } else {
          idrBased[entry.key] = entry.value;
        }
      }

      _rates = idrBased;
      _lastUpdated = DateTime.now();
      await _saveCache();
      debugPrint('[ExchangeRate] Rates updated: ${_rates.entries.map((e) => '${e.key}=${e.value.toStringAsFixed(2)}').join(', ')}');
    } catch (e) {
      debugPrint('[ExchangeRate] Fetch failed: $e, using cached/default rates');
    }
  }

  Future<void> _saveCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonData = jsonEncode(_rates);
      await prefs.setString(_prefsKey, jsonData);
      await prefs.setString(_prefsTimestamp, _lastUpdated!.toIso8601String());
    } catch (e) {
      debugPrint('[ExchangeRate] Cache save failed: $e');
    }
  }

  Future<void> _loadCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonData = prefs.getString(_prefsKey);
      final timestampStr = prefs.getString(_prefsTimestamp);

      if (jsonData != null) {
        final decoded = jsonDecode(jsonData) as Map<String, dynamic>;
        _rates = decoded.map((k, v) => MapEntry(k, (v as num).toDouble()));
      }

      if (timestampStr != null) {
        _lastUpdated = DateTime.tryParse(timestampStr);
      }

      debugPrint('[ExchangeRate] Cache loaded: ${_rates.entries.map((e) => '${e.key}=${e.value.toStringAsFixed(2)}').join(', ')}');
    } catch (e) {
      debugPrint('[ExchangeRate] Cache load failed: $e');
    }
  }

  bool _isStale() {
    if (_lastUpdated == null) return true;
    return DateTime.now().difference(_lastUpdated!) > _cacheDuration;
  }
}
