class Asset {
  final String? id;
  final String name;
  final String type;
  final double amount;
  final String currency;
  final DateTime? purchaseDate;
  final String? note;
  final bool isActive;

  const Asset({
    this.id,
    required this.name,
    required this.type,
    required this.amount,
    this.currency = 'IDR',
    this.purchaseDate,
    this.note,
    this.isActive = true,
  });

  String get safeId => id ?? '';

  Asset copyWith({
    String? id,
    String? name,
    String? type,
    double? amount,
    String? currency,
    DateTime? purchaseDate,
    String? note,
    bool? isActive,
  }) {
    return Asset(
      id: id ?? this.id,
      name: name ?? this.name,
      type: type ?? this.type,
      amount: amount ?? this.amount,
      currency: currency ?? this.currency,
      purchaseDate: purchaseDate ?? this.purchaseDate,
      note: note ?? this.note,
      isActive: isActive ?? this.isActive,
    );
  }
}
