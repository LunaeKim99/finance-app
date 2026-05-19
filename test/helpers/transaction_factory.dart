import 'package:uwangku/data/models/transaction_model.dart';
import 'package:uwangku/data/models/transaction_type.dart';

TransactionModel makeTransaction({
  String? id,
  String title = 'Test Transaction',
  double amount = 100000,
  TransactionType type = TransactionType.expense,
  String categoryId = 'cat_123',
  DateTime? date,
  String note = '',
  bool isSynced = true,
}) {
  return TransactionModel(
    id: id,
    title: title,
    amount: amount,
    type: type,
    categoryId: categoryId,
    date: date ?? DateTime.now(),
    note: note,
    isSynced: isSynced,
  );
}

TransactionModel makeIncome(double amount, {
  String title = 'Test Income',
  String categoryId = 'cat_income_123',
  DateTime? date,
  String note = '',
}) {
  return makeTransaction(
    title: title,
    amount: amount,
    type: TransactionType.income,
    categoryId: categoryId,
    date: date,
    note: note,
  );
}

TransactionModel makeExpense(double amount, {
  String title = 'Test Expense',
  String categoryId = 'cat_expense_123',
  DateTime? date,
  String note = '',
}) {
  return makeTransaction(
    title: title,
    amount: amount,
    type: TransactionType.expense,
    categoryId: categoryId,
    date: date,
    note: note,
  );
}