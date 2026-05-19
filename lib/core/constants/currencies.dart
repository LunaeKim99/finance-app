class CurrencyInfo {
  final String code;
  final String symbol;
  final String name;
  final String locale;

  const CurrencyInfo({
    required this.code,
    required this.symbol,
    required this.name,
    required this.locale,
  });
}

class AppCurrencies {
  AppCurrencies._();

  static const List<CurrencyInfo> supported = [
    CurrencyInfo(code: 'IDR', symbol: 'Rp', name: 'Rupiah', locale: 'id_ID'),
    CurrencyInfo(code: 'USD', symbol: '\$', name: 'US Dollar', locale: 'en_US'),
    CurrencyInfo(code: 'EUR', symbol: '€', name: 'Euro', locale: 'de_DE'),
    CurrencyInfo(code: 'SGD', symbol: 'S\$', name: 'Singapore Dollar', locale: 'en_SG'),
    CurrencyInfo(code: 'MYR', symbol: 'RM', name: 'Malaysian Ringgit', locale: 'ms_MY'),
    CurrencyInfo(code: 'JPY', symbol: '¥', name: 'Japanese Yen', locale: 'ja_JP'),
    CurrencyInfo(code: 'GBP', symbol: '£', name: 'British Pound', locale: 'en_GB'),
    CurrencyInfo(code: 'AUD', symbol: 'A\$', name: 'Australian Dollar', locale: 'en_AU'),
    CurrencyInfo(code: 'SAR', symbol: '﷼', name: 'Saudi Riyal', locale: 'ar_SA'),
    CurrencyInfo(code: 'CNY', symbol: '¥', name: 'Chinese Yuan', locale: 'zh_CN'),
  ];

  static const Map<String, double> defaultRates = {
    'IDR': 1.0,
    'USD': 16250.0,
    'EUR': 17500.0,
    'SGD': 12000.0,
    'MYR': 3450.0,
    'JPY': 105.0,
    'GBP': 20500.0,
    'AUD': 10600.0,
    'SAR': 4330.0,
    'CNY': 2250.0,
  };

  static CurrencyInfo getById(String code) {
    return supported.firstWhere(
      (c) => c.code == code,
      orElse: () => supported.first,
    );
  }

  static String symbolFor(String code) {
    return getById(code).symbol;
  }
}
