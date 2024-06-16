import 'dart:convert';
import 'dart:math';

import 'package:currency_picker/currency_picker.dart';
import 'package:expenses_app/db/db_helper.dart';
import 'package:expenses_app/models/account_transaction.dart';
import 'package:expenses_app/models/accounts.dart';
import 'package:expenses_app/models/categories.dart';
import 'package:expenses_app/models/charts/category_map.dart';
import 'package:expenses_app/models/settings.dart';
import 'package:expenses_app/models/transaction_categories.dart';
import 'package:expenses_app/utils/constants.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMethodCallHandler(
          const MethodChannel('plugins.flutter.io/path_provider'),
          (MethodCall methodCall) async {
    return '.';
  });

  sqfliteFfiInit();

  databaseFactory = databaseFactoryFfiNoIsolate;

  group("DB Tester", () {
    test('Initialization test', () async {
      // Run DB initialization
      await DbHelper.instance.initialize();

      // Test if default account created
      List<Account> accounts = await DbHelper.instance.getAccounts();
      expect(accounts.isNotEmpty, isTrue);

      // Test if default category created
      List<Category> categories = await DbHelper.instance.getCategories();
      expect(categories.isNotEmpty, isTrue);

      // Test if default theme is set
      Setting? defaultThemeSetting = await DbHelper.instance
          .getSetting(Constants.settingApplicationThemeMode);
      expect(bool.parse(defaultThemeSetting!.value), isFalse);

      // Test is default currency is set
      Currency? currencyINR = CurrencyService().findByCode("INR");
      Setting? defaultCurrencySetting = await DbHelper.instance
          .getSetting(Constants.settingApplicationCurrency);
      Currency? applicationCurrency =
          Currency.from(json: jsonDecode(defaultCurrencySetting!.value));

      expect(currencyINR!.code == applicationCurrency.code, isTrue);
    });

    test('Account creation test', () async {
      String accountOne = 'Account One';
      String accountDescription = 'Account description';
      int id =
          await DbHelper.instance.createAccount(accountOne, accountDescription);

      expect(id, isPositive);

      Account? account = await DbHelper.instance.getAccount(id);
      expect(account, isNotNull);
      expect(account!.title, accountOne);
      expect(account.description, accountDescription);
      expect(account.balance, isZero);
      expect(account.initialBalance, isZero);
    });

    test('Category test', () async {
      int color = (Random().nextDouble() * 0xFFFFFF).toInt();
      String categoryName = 'Category';
      String categoryDescription = 'Category description';

      int id = await DbHelper.instance
          .createCategory(categoryName, categoryDescription, color);
      expect(id, isPositive);

      Category? category = await DbHelper.instance.getCategory(id);
      expect(category, isNotNull);
      expect(category!.title, categoryName);
      expect(category.description, categoryDescription);
      expect(category.color, color);

      String updatedCategoryName = 'Category updated';
      String updatedCategoryDescription = 'Category description updated';
      color = (Random().nextDouble() * 0xFFFFFF).toInt();
      id = await DbHelper.instance.updateCategory(
        id,
        updatedCategoryName,
        updatedCategoryDescription,
        color,
      );

      category = await DbHelper.instance.getCategory(id);
      expect(category, isNotNull);
      expect(category!.title, updatedCategoryName);
      expect(category.description, updatedCategoryDescription);
      expect(category.color, color);
    });

    test('Transaction test', () async {
      // Test if we can get default account
      Account? account = await DbHelper.instance.getAccount(1);
      expect(account, isNotNull);

      // Create a category
      int color = (Random().nextDouble() * 0xFFFFFF).toInt();
      int categoryId =
          await DbHelper.instance.createCategory('Fuel', '', color);
      expect(categoryId, isPositive);

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
      expect(txnId, isPositive);

      // Assign a category
      int txnCategoryId =
          await DbHelper.instance.createTransactionCategory(txnId, categoryId);
      expect(txnCategoryId, isPositive);

      // Verify transaction
      AccountTransaction? txn = await DbHelper.instance.getTransaction(txnId);
      expect(txn, isNotNull);
      expect(txn!.accountId, account.id);
      expect(txn.title, txnTitle);
      expect(txn.description, txnDescription);
      expect(txn.total, total);
      expect(txn.type, type);
      expect(txn.transactionTime, transactionTime);

      // Verify transaction category
      TransactionCategory? txnCategory =
          await DbHelper.instance.getTransactionCategory(txnId);
      expect(txnCategory, isNotNull);
      expect(txnCategory!.id, txnCategoryId);
      expect(txnCategory.accountTransactionId, txnId);
      expect(txnCategory.categoryId, categoryId);

      // Update transaction
      String updatedTxnTitle = 'Fuel charges updated';
      String updatedTxnDescription = 'Petrol for my car updated';
      int updatedTotal = 5000;
      txn.title = updatedTxnTitle;
      txn.description = updatedTxnDescription;
      txn.total = updatedTotal;

      await DbHelper.instance.updateTransaction(txn);
      txn = await DbHelper.instance.getTransaction(txn.id);
      expect(txn, isNotNull);
      expect(txn!.accountId, account.id);
      expect(txn.title, updatedTxnTitle);
      expect(txn.description, updatedTxnDescription);
      expect(txn.total, updatedTotal);

      // Update transaction category
      await DbHelper.instance.updateTransactionCategory(
        txnCategory.id,
        txn.id,
        1,
      );
      txnCategory = await DbHelper.instance.getTransactionCategory(txnId);
      expect(txnCategory!.accountTransactionId, txnId);
      expect(txnCategory.categoryId, 1);

      // Get all transactions
      List<AccountTransaction> transactions =
          await DbHelper.instance.getTransactions();
      expect(transactions, isNotEmpty);

      // Get all transactions for a particular account
      transactions = await DbHelper.instance.getAccountTransactions(account.id);
      expect(transactions, isNotEmpty);
    });

    test('Settings test', () async {
      // Check if initial settings are existing
      List<Setting>? settings = await DbHelper.instance.getSettings();
      expect(settings.length, isNonZero);

      String key = 'key_setting';
      String value = 'Test value';
      int settingId = await DbHelper.instance.createOrUpdateSetting(
        key,
        value,
      );

      expect(settingId, isPositive);

      Setting? setting = await DbHelper.instance.getSetting(key);
      expect(setting, isNotNull);
      expect(setting!.value, value);

      String updatedValue = 'Updated test value';
      int newSettingId = await DbHelper.instance.createOrUpdateSetting(
        key,
        updatedValue,
      );
      expect(newSettingId == settingId, isTrue);

      setting = await DbHelper.instance.getSetting(key);
      expect(setting, isNotNull);
      expect(setting!.value, updatedValue);
    });

    // FIXME: Clearing database is failing due to mock path
    // test('Clear database', () async {
    //   await DbHelper.instance.clearDatabase();

    //   List<Account> accounts = await DbHelper.instance.getAccounts();
    //   expect(accounts.length, 1);
    // });

    test('Get chart data', () async {
      List<CategoryMap> chartData = await DbHelper.instance.getChartData();
      expect(chartData, isNotEmpty);
    });
  });
}
