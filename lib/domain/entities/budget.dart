class Budget {
  final String? id;
  final String name;
  final double amount;
  final double spent;
  final String category;
  final int month;
  final int year;
  final String? note;
  final bool isActive;
  final String currency;

  const Budget({
    this.id,
    required this.name,
    required this.amount,
    this.spent = 0,
    required this.category,
    required this.month,
    required this.year,
    this.note,
    this.isActive = true,
    this.currency = 'IDR',
  });

  String get safeId => id ?? '';
  double get remaining => amount - spent;
  double get percentage => amount > 0 ? (spent / amount) * 100 : 0;

  Budget copyWith({
    String? id,
    String? name,
    double? amount,
    double? spent,
    String? category,
    int? month,
    int? year,
    String? note,
    bool? isActive,
    String? currency,
  }) {
    return Budget(
      id: id ?? this.id,
      name: name ?? this.name,
      amount: amount ?? this.amount,
      spent: spent ?? this.spent,
      category: category ?? this.category,
      month: month ?? this.month,
      year: year ?? this.year,
      note: note ?? this.note,
      isActive: isActive ?? this.isActive,
      currency: currency ?? this.currency,
    );
  }
}
