enum TransactionType { income, expense }

class Transaction {
  final String? id;
  final String title;
  final double amount;
  final TransactionType type;
  final String category;
  final DateTime date;
  final String? note;
  final bool isSynced;
  final String currency;
  final double exchangeRateToIdr;

  const Transaction({
    this.id,
    required this.title,
    required this.amount,
    required this.type,
    required this.category,
    required this.date,
    this.note,
    this.isSynced = false,
    this.currency = 'IDR',
    this.exchangeRateToIdr = 1.0,
  });

  String get safeId => id ?? '';

  double get amountInIdr => amount * exchangeRateToIdr;

  Transaction copyWith({
    String? id,
    String? title,
    double? amount,
    TransactionType? type,
    String? category,
    DateTime? date,
    String? note,
    bool? isSynced,
    String? currency,
    double? exchangeRateToIdr,
  }) {
    return Transaction(
      id: id ?? this.id,
      title: title ?? this.title,
      amount: amount ?? this.amount,
      type: type ?? this.type,
      category: category ?? this.category,
      date: date ?? this.date,
      note: note ?? this.note,
      isSynced: isSynced ?? this.isSynced,
      currency: currency ?? this.currency,
      exchangeRateToIdr: exchangeRateToIdr ?? this.exchangeRateToIdr,
    );
  }
}
