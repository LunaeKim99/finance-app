class ReceiptItem {
  final String name;
  final double price;
  final String category;

  const ReceiptItem({
    required this.name,
    required this.price,
    required this.category,
  });

  ReceiptItem copyWith({String? name, double? price, String? category}) {
    return ReceiptItem(
      name: name ?? this.name,
      price: price ?? this.price,
      category: category ?? this.category,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'price': price,
      'category': category,
    };
  }

  factory ReceiptItem.fromJson(Map<String, dynamic> json) {
    return ReceiptItem(
      name: json['name'] as String? ?? '',
      price: (json['price'] as num?)?.toDouble() ?? 0,
      category: json['category'] as String? ?? 'Lainnya',
    );
  }
}

class ReceiptScanResult {
  final String merchant;
  final DateTime? date;
  final double total;
  final String currency;
  final List<ReceiptItem> items;

  const ReceiptScanResult({
    this.merchant = '',
    this.date,
    this.total = 0,
    this.currency = 'IDR',
    this.items = const [],
  });

  ReceiptScanResult copyWith({
    String? merchant,
    DateTime? date,
    double? total,
    String? currency,
    List<ReceiptItem>? items,
  }) {
    return ReceiptScanResult(
      merchant: merchant ?? this.merchant,
      date: date ?? this.date,
      total: total ?? this.total,
      currency: currency ?? this.currency,
      items: items ?? this.items,
    );
  }
}