import 'package:pocketbase/pocketbase.dart';

class DebtModel {
  final String? id;
  final String title;
  final String type;
  final double amount;
  final double? remainingAmount;
  final String personName;
  final DateTime? dueDate;
  final DateTime? startDate;
  final bool isPaid;
  final String note;
  final String? user;
  final String currency;
  final double exchangeRateToIdr;

  DebtModel({
    this.id,
    required this.title,
    required this.type,
    required this.amount,
    this.remainingAmount,
    this.personName = '',
    this.dueDate,
    this.startDate,
    this.isPaid = false,
    this.note = '',
    this.user,
    this.currency = 'IDR',
    this.exchangeRateToIdr = 1.0,
  });

  String get safeId => id ?? '';

  double get remaining => remainingAmount ?? amount;
  double get remainingInIdr => remaining * exchangeRateToIdr;

  factory DebtModel.fromRecord(RecordModel record) {
    return DebtModel(
      id: record.id,
      title: record.data['title'] as String,
      type: record.data['type'] as String,
      amount: (record.data['amount'] as num).toDouble(),
      remainingAmount: record.data['remaining_amount'] != null
          ? (record.data['remaining_amount'] as num).toDouble()
          : null,
      personName: (record.data['person_name'] as String?) ?? '',
      dueDate: record.data['due_date'] != null
          ? DateTime.parse(record.data['due_date'] as String)
          : null,
      startDate: record.data['start_date'] != null
          ? DateTime.parse(record.data['start_date'] as String)
          : null,
      isPaid: (record.data['is_paid'] as bool?) ?? false,
      note: (record.data['note'] as String?) ?? '',
      user: record.data['user'] as String?,
      currency: (record.data['currency'] as String?) ?? 'IDR',
      exchangeRateToIdr: ((record.data['exchange_rate_to_idr'] as num?) ?? 1.0).toDouble(),
    );
  }

  factory DebtModel.fromMap(Map<String, dynamic> map) {
    return DebtModel(
      id: map['id'] as String?,
      title: map['title'] as String,
      type: map['type'] as String,
      amount: (map['amount'] as num).toDouble(),
      remainingAmount: map['remaining_amount'] != null
          ? (map['remaining_amount'] as num).toDouble()
          : null,
      personName: (map['person_name'] as String?) ?? '',
      dueDate: map['due_date'] != null
          ? DateTime.parse(map['due_date'] as String)
          : null,
      startDate: map['start_date'] != null
          ? DateTime.parse(map['start_date'] as String)
          : null,
      isPaid: (map['is_paid'] as bool?) ?? false,
      note: (map['note'] as String?) ?? '',
      user: map['user'] as String?,
      currency: (map['currency'] as String?) ?? 'IDR',
      exchangeRateToIdr: ((map['exchange_rate_to_idr'] as num?) ?? 1.0).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'type': type,
      'amount': amount,
      'remaining_amount': remainingAmount ?? amount,
      'person_name': personName,
      'due_date': dueDate?.toIso8601String(),
      'start_date': startDate?.toIso8601String(),
      'is_paid': isPaid,
      'note': note,
      'currency': currency,
      'exchange_rate_to_idr': exchangeRateToIdr,
      if (user != null) 'user': user,
    };
  }

  DebtModel copyWith({
    String? id,
    String? title,
    String? type,
    double? amount,
    double? remainingAmount,
    String? personName,
    DateTime? dueDate,
    DateTime? startDate,
    bool? isPaid,
    String? note,
    String? user,
    String? currency,
    double? exchangeRateToIdr,
  }) {
    return DebtModel(
      id: id ?? this.id,
      title: title ?? this.title,
      type: type ?? this.type,
      amount: amount ?? this.amount,
      remainingAmount: remainingAmount ?? this.remainingAmount,
      personName: personName ?? this.personName,
      dueDate: dueDate ?? this.dueDate,
      startDate: startDate ?? this.startDate,
      isPaid: isPaid ?? this.isPaid,
      note: note ?? this.note,
      user: user ?? this.user,
      currency: currency ?? this.currency,
      exchangeRateToIdr: exchangeRateToIdr ?? this.exchangeRateToIdr,
    );
  }

  static const List<String> debtTypes = ['hutang', 'piutang'];

  static const Map<String, String> debtTypeLabels = {
    'hutang': 'Hutang',
    'piutang': 'Piutang',
  };
}
