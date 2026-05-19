import 'package:pocketbase/pocketbase.dart';
import 'transaction_type.dart';

class TransactionModel {
  final String? id;
  final String title;
  final double amount;
  final TransactionType type;
  final String categoryId;
  final String? categoryName;
  final DateTime date;
  final String note;
  final String? user;
  final bool isSynced;
  final String currency;
  final double exchangeRateToIdr;

  TransactionModel({
    this.id,
    required this.title,
    required this.amount,
    required this.type,
    required this.categoryId,
    this.categoryName,
    required this.date,
    required this.note,
    this.user,
    this.isSynced = true,
    this.currency = 'IDR',
    this.exchangeRateToIdr = 1.0,
  });

  String get safeId => id ?? '';
  double get amountInIdr => amount * exchangeRateToIdr;

  factory TransactionModel.fromRecord(RecordModel record) {
    final categoryData = record.data['category'];
    String catName = 'Lainnya';
    if (categoryData is RecordModel) {
      catName = categoryData.data['name'] as String? ?? 'Lainnya';
    } else if (categoryData is String) {
      catName = categoryData;
    }

    return TransactionModel(
      id: record.id,
      title: record.data['title'] as String,
      amount: (record.data['amount'] as num).toDouble(),
      type: TransactionType.fromString(record.data['type'] as String),
      categoryId: record.data['category'] is RecordModel 
          ? (record.data['category'] as RecordModel).id 
          : record.data['category'] as String,
      categoryName: catName,
      date: DateTime.parse(record.data['date'] as String),
      note: (record.data['note'] as String?) ?? '',
      user: record.data['user'] as String?,
      currency: (record.data['currency'] as String?) ?? 'IDR',
      exchangeRateToIdr: ((record.data['exchange_rate_to_idr'] as num?) ?? 1.0).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'amount': amount,
      'type': type.value,
      'category': categoryId,
      'date': date.toIso8601String(),
      'note': note,
      'currency': currency,
      'exchange_rate_to_idr': exchangeRateToIdr,
      if (user != null) 'user': user,
    };
  }

  factory TransactionModel.fromMap(Map<String, dynamic> map) {
    return TransactionModel(
      id: map['id'] as String?,
      title: map['title'] as String,
      amount: (map['amount'] as num).toDouble(),
      type: TransactionType.fromString(map['type'] as String),
      categoryId: map['category'] as String,
      categoryName: map['categoryName'] as String?,
      date: DateTime.parse(map['date'] as String),
      note: (map['note'] as String?) ?? '',
      user: map['user'] as String?,
      isSynced: map['isSynced'] as bool? ?? true,
      currency: (map['currency'] as String?) ?? 'IDR',
      exchangeRateToIdr: ((map['exchange_rate_to_idr'] as num?) ?? 1.0).toDouble(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'amount': amount,
      'type': type.value,
      'category': categoryId,
      'categoryName': categoryName,
      'date': date.toIso8601String(),
      'note': note,
      'user': user,
      'isSynced': isSynced,
      'currency': currency,
      'exchange_rate_to_idr': exchangeRateToIdr,
    };
  }

  TransactionModel copyWith({
    String? id,
    String? title,
    double? amount,
    TransactionType? type,
    String? categoryId,
    String? categoryName,
    DateTime? date,
    String? note,
    String? user,
    bool? isSynced,
    String? currency,
    double? exchangeRateToIdr,
  }) {
    return TransactionModel(
      id: id ?? this.id,
      title: title ?? this.title,
      amount: amount ?? this.amount,
      type: type ?? this.type,
      categoryId: categoryId ?? this.categoryId,
      categoryName: categoryName ?? this.categoryName,
      date: date ?? this.date,
      note: note ?? this.note,
      user: user ?? this.user,
      isSynced: isSynced ?? this.isSynced,
      currency: currency ?? this.currency,
      exchangeRateToIdr: exchangeRateToIdr ?? this.exchangeRateToIdr,
    );
  }
}
