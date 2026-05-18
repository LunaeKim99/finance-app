import 'package:app_links/app_links.dart';
import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'app/app.dart';
import 'data/datasources/pb_helper.dart';
import 'services/pb_client.dart';
import 'services/oauth_handler.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('id_ID', null);
  await PbClient.init();
  await PbHelper().initialize();

  _initOAuthListener();

  runApp(const FinanceApp());
}

void _initOAuthListener() {
  final appLinks = AppLinks();

  appLinks.getInitialLink().then((Uri? uri) {
    if (uri != null && uri.scheme == 'com.example.uangku') {
      OAuthHandler.onRedirect(uri);
    }
  });

  appLinks.uriLinkStream.listen((Uri uri) {
    if (uri.scheme == 'com.example.uangku') {
      OAuthHandler.onRedirect(uri);
    }
  });
}
