enum PaymentStatus { pending, success, failed, cancelled }

enum PremiumPlan { monthly, lifetime }

class PaymentModel {
  final String orderId;
  final String? snapToken;
  final double amount;
  final PremiumPlan plan;
  final PaymentStatus status;
  final DateTime createdAt;

  PaymentModel({
    required this.orderId,
    this.snapToken,
    required this.amount,
    required this.plan,
    required this.status,
    required this.createdAt,
  });

  PaymentModel copyWith({
    String? orderId,
    String? snapToken,
    double? amount,
    PremiumPlan? plan,
    PaymentStatus? status,
    DateTime? createdAt,
  }) {
    return PaymentModel(
      orderId: orderId ?? this.orderId,
      snapToken: snapToken ?? this.snapToken,
      amount: amount ?? this.amount,
      plan: plan ?? this.plan,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}