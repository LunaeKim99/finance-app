import '../../../../data/datasources/smart_db_helper.dart';
import '../../../../data/models/transaction_model.dart';

class ReceiptDatasource {
  final SmartDbHelper _dbHelper;

  ReceiptDatasource(this._dbHelper);

  Future<TransactionModel> createTransaction(TransactionModel t) =>
      _dbHelper.createTransaction(t);
}
