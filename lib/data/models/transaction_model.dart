import 'package:pocketbase/pocketbase.dart';
import 'transaction_type.dart';

class TransactionModel {
  final String? id;
  final String title;
  final double amount;
  final TransactionType type;
  final String category;
  final DateTime date;
  final String note;
  final String? user;
  final bool isSynced;

  TransactionModel({
    this.id,
    required this.title,
    required this.amount,
    required this.type,
    required this.category,
    required this.date,
    required this.note,
    this.user,
    this.isSynced = true,
  });

  String get safeId => id ?? '';

  factory TransactionModel.fromRecord(RecordModel record) {
    return TransactionModel(
      id: record.id,
      title: record.data['title'] as String,
      amount: (record.data['amount'] as num).toDouble(),
      type: TransactionType.fromString(record.data['type'] as String),
      category: record.data['category'] as String,
      date: DateTime.parse(record.data['date'] as String),
      note: (record.data['note'] as String?) ?? '',
      user: record.data['user'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'amount': amount,
      'type': type.value,
      'category': category,
      'date': date.toIso8601String(),
      'note': note,
      if (user != null) 'user': user,
    };
  }

  factory TransactionModel.fromMap(Map<String, dynamic> map) {
    return TransactionModel(
      id: map['id'] as String?,
      title: map['title'] as String,
      amount: (map['amount'] as num).toDouble(),
      type: TransactionType.fromString(map['type'] as String),
      category: map['category'] as String,
      date: DateTime.parse(map['date'] as String),
      note: (map['note'] as String?) ?? '',
      user: map['user'] as String?,
      isSynced: map['isSynced'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'amount': amount,
      'type': type.value,
      'category': category,
      'date': date.toIso8601String(),
      'note': note,
      'user': user,
      'isSynced': isSynced,
    };
  }

  TransactionModel copyWith({
    String? id,
    String? title,
    double? amount,
    TransactionType? type,
    String? category,
    DateTime? date,
    String? note,
    String? user,
    bool? isSynced,
  }) {
    return TransactionModel(
      id: id ?? this.id,
      title: title ?? this.title,
      amount: amount ?? this.amount,
      type: type ?? this.type,
      category: category ?? this.category,
      date: date ?? this.date,
      note: note ?? this.note,
      user: user ?? this.user,
      isSynced: isSynced ?? this.isSynced,
    );
  }
}
