import '../../data/models/transaction_model.dart';
import '../../data/models/asset_model.dart';
import '../../data/models/debt_model.dart';
import '../../data/models/budget_model.dart';

abstract class DbInterface {
  Future<void> initialize();
  
  // Transactions
  Future<List<TransactionModel>> fetchAllTransactions();
  Future<TransactionModel> createTransaction(TransactionModel t);
  Future<void> deleteTransaction(String id);
  Future<TransactionModel> updateTransaction(String id, TransactionModel t);
  Future<List<TransactionModel>> fetchTransactionsByMonth(int month, int year);
  
  // Assets
  Future<List<AssetModel>> fetchAllAssets();
  Future<AssetModel> createAsset(AssetModel a);
  Future<void> deleteAsset(String id);
  Future<AssetModel> updateAsset(String id, AssetModel a);
  
  // Debts
  Future<List<DebtModel>> fetchAllDebts();
  Future<DebtModel> createDebt(DebtModel d);
  Future<void> deleteDebt(String id);
  Future<DebtModel> updateDebt(String id, DebtModel d);
  Future<List<DebtModel>> fetchUnpaidDebts();
  
  // Budgets
  Future<List<BudgetModel>> fetchAllBudgets();
  Future<BudgetModel> createBudget(BudgetModel b);
  Future<void> deleteBudget(String id);
  Future<BudgetModel> updateBudget(String id, BudgetModel b);
  Future<List<BudgetModel>> fetchBudgetsByMonth(int month, int year);
  Future<void> updateBudgetSpent(String id, double spent);
}
