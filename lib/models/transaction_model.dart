import 'package:pocketbase/pocketbase.dart';

class TransactionModel {
  final String? id;
  final String title;
  final double amount;
  final String type;
  final String category;
  final DateTime date;
  final String note;

  TransactionModel({
    this.id,
    required this.title,
    required this.amount,
    required this.type,
    required this.category,
    required this.date,
    required this.note,
  });

  factory TransactionModel.fromRecord(RecordModel record) {
    return TransactionModel(
      id: record.id,
      title: record.data['title'] as String,
      amount: (record.data['amount'] as num).toDouble(),
      type: record.data['type'] as String,
      category: record.data['category'] as String,
      date: DateTime.parse(record.data['date'] as String),
      note: (record.data['note'] as String?) ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'amount': amount,
      'type': type,
      'category': category,
      'date': date.toIso8601String(),
      'note': note,
    };
  }

  TransactionModel copyWith({
    String? id,
    String? title,
    double? amount,
    String? type,
    String? category,
    DateTime? date,
    String? note,
  }) {
    return TransactionModel(
      id: id ?? this.id,
      title: title ?? this.title,
      amount: amount ?? this.amount,
      type: type ?? this.type,
      category: category ?? this.category,
      date: date ?? this.date,
      note: note ?? this.note,
    );
  }
}