import 'package:pocketbase/pocketbase.dart';

class AssetModel {
  final String? id;
  final String name;
  final String type;
  final double amount;
  final String currency;
  final double exchangeRateToIdr;
  final DateTime? purchaseDate;
  final String note;
  final bool isActive;
  final String? user;

  AssetModel({
    this.id,
    required this.name,
    required this.type,
    required this.amount,
    this.currency = 'IDR',
    this.exchangeRateToIdr = 1.0,
    this.purchaseDate,
    this.note = '',
    this.isActive = true,
    this.user,
  });

  String get safeId => id ?? '';

  factory AssetModel.fromRecord(RecordModel record) {
    return AssetModel(
      id: record.id,
      name: record.data['name'] as String,
      type: record.data['type'] as String,
      amount: (record.data['amount'] as num).toDouble(),
      currency: (record.data['currency'] as String?) ?? 'IDR',
      exchangeRateToIdr: ((record.data['exchange_rate_to_idr'] as num?) ?? 1.0).toDouble(),
      purchaseDate: record.data['purchase_date'] != null
          ? DateTime.parse(record.data['purchase_date'] as String)
          : null,
      note: (record.data['note'] as String?) ?? '',
      isActive: (record.data['is_active'] as bool?) ?? true,
      user: record.data['user'] as String?,
    );
  }

  factory AssetModel.fromMap(Map<String, dynamic> map) {
    return AssetModel(
      id: map['id'] as String?,
      name: map['name'] as String,
      type: map['type'] as String,
      amount: (map['amount'] as num).toDouble(),
      currency: (map['currency'] as String?) ?? 'IDR',
      exchangeRateToIdr: ((map['exchange_rate_to_idr'] as num?) ?? 1.0).toDouble(),
      purchaseDate: map['purchase_date'] != null
          ? DateTime.parse(map['purchase_date'] as String)
          : null,
      note: (map['note'] as String?) ?? '',
      isActive: (map['is_active'] as bool?) ?? true,
      user: map['user'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'type': type,
      'amount': amount,
      'currency': currency,
      'exchange_rate_to_idr': exchangeRateToIdr,
      'purchase_date': purchaseDate?.toIso8601String(),
      'note': note,
      'is_active': isActive,
      if (user != null) 'user': user,
    };
  }

  AssetModel copyWith({
    String? id,
    String? name,
    String? type,
    double? amount,
    String? currency,
    double? exchangeRateToIdr,
    DateTime? purchaseDate,
    String? note,
    bool? isActive,
    String? user,
  }) {
    return AssetModel(
      id: id ?? this.id,
      name: name ?? this.name,
      type: type ?? this.type,
      amount: amount ?? this.amount,
      currency: currency ?? this.currency,
      exchangeRateToIdr: exchangeRateToIdr ?? this.exchangeRateToIdr,
      purchaseDate: purchaseDate ?? this.purchaseDate,
      note: note ?? this.note,
      isActive: isActive ?? this.isActive,
      user: user ?? this.user,
    );
  }

  static const List<String> assetTypes = [
    'cash',
    'bank',
    'investment',
    'property',
    'vehicle',
    'electronics',
    'other',
  ];

  static const Map<String, String> assetTypeLabels = {
    'cash': 'Tunai',
    'bank': 'Bank',
    'investment': 'Investasi',
    'property': 'Properti',
    'vehicle': 'Kendaraan',
    'electronics': 'Elektronik',
    'other': 'Lainnya',
  };
}
