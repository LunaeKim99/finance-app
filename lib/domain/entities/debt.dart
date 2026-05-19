class Debt {
  final String? id;
  final String title;
  final String type;
  final double amount;
  final double? remainingAmount;
  final String personName;
  final DateTime? dueDate;
  final DateTime? startDate;
  final bool isPaid;
  final String? note;
  final String currency;

  const Debt({
    this.id,
    required this.title,
    required this.type,
    required this.amount,
    this.remainingAmount,
    this.personName = '',
    this.dueDate,
    this.startDate,
    this.isPaid = false,
    this.note,
    this.currency = 'IDR',
  });

  String get safeId => id ?? '';
  double get remaining => remainingAmount ?? amount;

  Debt copyWith({
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
    String? currency,
  }) {
    return Debt(
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
      currency: currency ?? this.currency,
    );
  }
}
