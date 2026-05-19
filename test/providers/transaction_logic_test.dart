import 'package:flutter_test/flutter_test.dart';
import 'package:uwangku/data/models/transaction_model.dart';
import 'package:uwangku/data/models/transaction_type.dart';
import '../helpers/transaction_factory.dart';

void main() {
  group('TransactionModel', () {
    test('creates income transaction correctly', () {
      final income = makeIncome(500000, categoryId: 'Gaji');
      expect(income.type, TransactionType.income);
      expect(income.amount, 500000);
      expect(income.categoryId, 'Gaji');
    });

    test('creates expense transaction correctly', () {
      final expense = makeExpense(200000, categoryId: 'Makanan');
      expect(expense.type, TransactionType.expense);
      expect(expense.amount, 200000);
      expect(expense.categoryId, 'Makanan');
    });
  });

  group('calculateTotalBalance', () {
    double calculateTotalBalance(List<TransactionModel> transactions) {
      double income = 0;
      double expense = 0;
      for (final t in transactions) {
        if (t.type == TransactionType.income) {
          income += t.amount;
        } else {
          expense += t.amount;
        }
      }
      return income - expense;
    }

    test('returns 0 with empty list', () {
      final balance = calculateTotalBalance(<TransactionModel>[]);
      expect(balance, 0.0);
    });

    test('calculates income - expense correctly', () {
      final transactions = <TransactionModel>[
        makeIncome(500000),
        makeExpense(200000),
      ];
      expect(calculateTotalBalance(transactions), 300000.0);
    });

    test('returns negative when expense > income', () {
      final transactions = <TransactionModel>[
        makeIncome(100000),
        makeExpense(300000),
      ];
      expect(calculateTotalBalance(transactions), -200000.0);
    });
  });

  group('Monthly Filter', () {
    List<TransactionModel> filterByMonth(List<TransactionModel> transactions, int month, int year) {
      return transactions.where((t) => t.date.month == month && t.date.year == year).toList();
    }

    test('filters transactions by month correctly', () {
      final now = DateTime.now();
      final lastMonth = DateTime(now.year, now.month - 1, 1);

      final transactions = <TransactionModel>[
        makeIncome(400000, date: now),
        makeIncome(200000, date: lastMonth),
      ];

      final filtered = filterByMonth(transactions, now.month, now.year);
      expect(filtered.length, 1);
      expect(filtered.first.amount, 400000);
    });
  });

  group('Category Totals', () {
    Map<String, double> calculateCategoryTotals(List<TransactionModel> transactions, int month, int year) {
      final Map<String, double> categoryTotals = {};
      final filtered = transactions.where((t) =>
          t.type == TransactionType.expense &&
          t.date.month == month &&
          t.date.year == year);

      for (final t in filtered) {
        final cat = t.categoryName ?? t.categoryId;
        categoryTotals[cat] = (categoryTotals[cat] ?? 0) + t.amount;
      }
      return categoryTotals;
    }

    test('groups expenses by category correctly', () {
      final now = DateTime.now();
      final transactions = <TransactionModel>[
        makeExpense(80000, categoryId: 'Makanan', date: now),
        makeExpense(30000, categoryId: 'Makanan', date: now),
        makeExpense(50000, categoryId: 'Transport', date: now),
      ];

      final totals = calculateCategoryTotals(transactions, now.month, now.year);
      expect(totals['Makanan'], 110000.0);
      expect(totals['Transport'], 50000.0);
    });

    test('excludes income from category totals', () {
      final now = DateTime.now();
      final transactions = <TransactionModel>[
        makeIncome(500000, categoryId: 'Gaji', date: now),
      ];

      final totals = calculateCategoryTotals(transactions, now.month, now.year);
      expect(totals['Gaji'], isNull);
    });
  });

  group('Monthly Income', () {
    double calculateMonthlyIncome(List<TransactionModel> transactions, int month, int year) {
      return transactions
          .where((t) =>
              t.type == TransactionType.income &&
              t.date.month == month &&
              t.date.year == year)
          .fold(0.0, (sum, t) => sum + t.amount);
    }

    test('calculates income for specific month', () {
      final now = DateTime.now();
      final lastMonth = DateTime(now.year, now.month - 1, 1);

      final transactions = <TransactionModel>[
        makeIncome(500000, date: now),
        makeIncome(300000, date: lastMonth),
      ];

      expect(calculateMonthlyIncome(transactions, now.month, now.year), 500000.0);
    });

    test('excludes expenses from income', () {
      final now = DateTime.now();
      final transactions = <TransactionModel>[
        makeIncome(300000, date: now),
        makeExpense(100000, date: now),
      ];

      expect(calculateMonthlyIncome(transactions, now.month, now.year), 300000.0);
    });
  });

  group('Monthly Expense', () {
    double calculateMonthlyExpense(List<TransactionModel> transactions, int month, int year) {
      return transactions
          .where((t) =>
              t.type == TransactionType.expense &&
              t.date.month == month &&
              t.date.year == year)
          .fold(0.0, (sum, t) => sum + t.amount);
    }

    test('calculates expense for specific month', () {
      final now = DateTime.now();
      final lastMonth = DateTime(now.year, now.month - 1, 1);

      final transactions = <TransactionModel>[
        makeExpense(400000, date: now),
        makeExpense(100000, date: lastMonth),
      ];

      expect(calculateMonthlyExpense(transactions, now.month, now.year), 400000.0);
    });

    test('excludes income from expense', () {
      final now = DateTime.now();
      final transactions = <TransactionModel>[
        makeIncome(300000, date: now),
        makeExpense(100000, date: now),
      ];

      expect(calculateMonthlyExpense(transactions, now.month, now.year), 100000.0);
    });
  });
}