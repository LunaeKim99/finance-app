import 'package:intl/intl.dart';
import '../constants/currencies.dart';
import '../services/exchange_rate_service.dart';

class CurrencyHelper {
  CurrencyHelper._();

  static final _defaultFormat = NumberFormat.currency(
    locale: 'id_ID',
    symbol: 'Rp ',
    decimalDigits: 0,
  );

  static String format(
    double amount, {
    String fromCurrency = 'IDR',
    String toCurrency = 'IDR',
    Map<String, double>? rates,
  }) {
    if (fromCurrency == toCurrency) {
      return _formatWithCode(amount, toCurrency);
    }
    final converted = convert(amount,
        fromCurrency: fromCurrency, toCurrency: toCurrency, rates: rates);
    return _formatWithCode(converted, toCurrency);
  }

  static double convert(
    double amount, {
    required String fromCurrency,
    required String toCurrency,
    Map<String, double>? rates,
  }) {
    if (fromCurrency == toCurrency) return amount;
    final effectiveRates = rates ?? _getLiveRates();
    final amountInIdr = amount * (effectiveRates[fromCurrency] ?? 1.0);
    return amountInIdr / (effectiveRates[toCurrency] ?? 1.0);
  }

  static Map<String, double> _getLiveRates() {
    final Map<String, double> live = {};
    for (final c in AppCurrencies.supported) {
      live[c.code] = ExchangeRateService.instance.getRate(c.code);
    }
    return live;
  }

  static String _formatWithCode(double amount, String currencyCode) {
    final info = AppCurrencies.getById(currencyCode);
    try {
      final format = NumberFormat.currency(
        locale: info.locale,
        symbol: '${info.symbol} ',
        decimalDigits: currencyCode == 'JPY' ? 0 : 0,
      );
      return format.format(amount);
    } catch (_) {
      return '${info.symbol}${_formatNumber(amount)}';
    }
  }

  static String _formatNumber(double amount) {
    final f = NumberFormat('#,###', 'id_ID');
    return f.format(amount.ceil());
  }

  static String formatAsIdr(double amount) {
    return _defaultFormat.format(amount);
  }
}
