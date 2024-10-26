import 'dart:io';
import 'dart:math';

import 'package:expenses_app/db/db_helper.dart';
import 'package:expenses_app/models/accounts.dart';
import 'package:expenses_app/screens/components/transaction_form.dart';
import 'package:expenses_app/screens/dashboard.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  const dbName = "expenses.db";

  LiveTestWidgetsFlutterBinding.ensureInitialized();

  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMethodCallHandler(
          const MethodChannel('plugins.flutter.io/path_provider'),
          (MethodCall methodCall) async {
    return '.';
  });

  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfiNoIsolate;

  group('Dashboard Test', () {
    setUp(() async {
      Directory appDocumentsDir = await getApplicationDocumentsDirectory();
      String dbPath = p.join(appDocumentsDir.path, '', dbName);
      await databaseFactory.deleteDatabase(dbPath);
      SharedPreferences.setMockInitialValues({});

      await DbHelper.instance.initialize();
    });

    testWidgets('Empty Dashboard Check', (tester) async {
      await tester.pumpWidget(const MaterialApp(
        home: Scaffold(
          body: Dashboard(),
        ),
      ));

      expect(
        find.byType(CircularProgressIndicator),
        findsOneWidget,
      );

      expect(
        find.byType(FloatingActionButton),
        findsOneWidget,
      );

      await tester.pumpAndSettle();

      expect(
        find.text("No Transactions"),
        findsOneWidget,
      );
    });

    testWidgets('Floating action button check', (tester) async {
      await tester.pumpWidget(const MaterialApp(
        home: Scaffold(
          body: Dashboard(),
        ),
      ));

      await tester.pumpAndSettle();

      await tester.tap(find.byType(FloatingActionButton));

      await tester.pumpAndSettle();

      expect(
        find.byType(TransactionForm),
        findsOneWidget,
      );
    });

    testWidgets('Dashboard shows transactions', (tester) async {
      Account? account = await DbHelper.instance.getAccount(1);

      // Create transaction
      String txnTitle = 'Fuel charges';
      String txnDescription = 'Petrol for my car';
      int total = 10000;
      String type = 'debit';
      DateTime transactionTime = DateTime.now();
      int txnId = await DbHelper.instance.createTransaction(
        account!.id,
        txnTitle,
        txnDescription,
        total,
        type,
        transactionTime,
      );

      int color = (Random().nextDouble() * 0xFFFFFF).toInt();
      int categoryId =
          await DbHelper.instance.createCategory('Fuel', '', color);

      int txnCategoryId =
          await DbHelper.instance.createTransactionCategory(txnId, categoryId);

      await tester.pumpWidget(const MaterialApp(
        home: Scaffold(
          body: Dashboard(),
        ),
      ));

      await tester.pumpAndSettle();

      // Find the transaction list tile
      expect(
        find.text('Fuel charges'),
        findsOneWidget,
      );

      // Find the chart
      expect(
        find.byType(PieChart),
        findsOneWidget,
      );

      // Test if we can tap the list tile for editing
      await tester.tap(find.text('Fuel charges'));
      await tester.pumpAndSettle();

      expect(
        find.byType(TransactionForm),
        findsOneWidget,
      );
    });
  });
}
