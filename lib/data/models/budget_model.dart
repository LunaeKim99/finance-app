import 'package:pocketbase/pocketbase.dart';

class BudgetModel {
  final String? id;
  final String name;
  final double amount;
  final double spent;
  final String category;
  final int month;
  final int year;
  final String note;
  final bool isActive;
  final String? user;

  BudgetModel({
    this.id,
    required this.name,
    required this.amount,
    this.spent = 0,
    this.category = '',
    required this.month,
    required this.year,
    this.note = '',
    this.isActive = true,
    this.user,
  });

  String get safeId => id ?? '';

  double get remaining => amount - spent;

  double get percentage => amount > 0 ? (spent / amount) * 100 : 0;

  factory BudgetModel.fromRecord(RecordModel record) {
    return BudgetModel(
      id: record.id,
      name: record.data['name'] as String,
      amount: (record.data['amount'] as num).toDouble(),
      spent: (record.data['spent'] as num?)?.toDouble() ?? 0,
      category: (record.data['category'] as String?) ?? '',
      month: record.data['month'] as int,
      year: record.data['year'] as int,
      note: (record.data['note'] as String?) ?? '',
      isActive: (record.data['is_active'] as bool?) ?? true,
      user: record.data['user'] as String?,
    );
  }

  factory BudgetModel.fromMap(Map<String, dynamic> map) {
    return BudgetModel(
      id: map['id'] as String?,
      name: map['name'] as String,
      amount: (map['amount'] as num).toDouble(),
      spent: (map['spent'] as num?)?.toDouble() ?? 0,
      category: (map['category'] as String?) ?? '',
      month: map['month'] as int,
      year: map['year'] as int,
      note: (map['note'] as String?) ?? '',
      isActive: (map['is_active'] as bool?) ?? true,
      user: map['user'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'amount': amount,
      'spent': spent,
      'category': category,
      'month': month,
      'year': year,
      'note': note,
      'is_active': isActive,
      if (user != null) 'user': user,
    };
  }

  BudgetModel copyWith({
    String? id,
    String? name,
    double? amount,
    double? spent,
    String? category,
    int? month,
    int? year,
    String? note,
    bool? isActive,
    String? user,
  }) {
    return BudgetModel(
      id: id ?? this.id,
      name: name ?? this.name,
      amount: amount ?? this.amount,
      spent: spent ?? this.spent,
      category: category ?? this.category,
      month: month ?? this.month,
      year: year ?? this.year,
      note: note ?? this.note,
      isActive: isActive ?? this.isActive,
      user: user ?? this.user,
    );
  }
}
