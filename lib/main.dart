import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'app/app.dart';
import 'data/datasources/pb_helper.dart';
import 'services/pb_client.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('id_ID', null);
  await PbClient.init();
  await PbHelper().initialize();
  runApp(const FinanceApp());
}
