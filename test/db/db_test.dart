import 'dart:convert';
import 'dart:math';

import 'package:currency_picker/currency_picker.dart';
import 'package:expenses_app/db/db_helper.dart';
import 'package:expenses_app/models/account_transaction.dart';
import 'package:expenses_app/models/accounts.dart';
import 'package:expenses_app/models/categories.dart';
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
      List<Account> accounts = await DbHelper.instance.geAccounts();
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
      int id = await DbHelper.instance
          .createAccount('Account One', 'Account description');

      expect(id, isPositive);

      Account? account = await DbHelper.instance.getAccount(id);
      expect(account, isNotNull);
      expect(account!.title, 'Account One');
      expect(account.description, 'Account description');
      expect(account.balance, isZero);
      expect(account.initialBalance, isZero);
    });

    test('Category test', () async {
      int color = (Random().nextDouble() * 0xFFFFFF).toInt();
      int id = await DbHelper.instance
          .createCategory('Category', 'Category description', color);

      expect(id, isPositive);

      Category? category = await DbHelper.instance.getCategory(id);
      expect(category, isNotNull);
      expect(category!.title, 'Category');
      expect(category.description, 'Category description');
      expect(category.color, color);

      color = (Random().nextDouble() * 0xFFFFFF).toInt();
      id = await DbHelper.instance.updateCategory(
        id,
        'Category updated',
        'Category description updated',
        color,
      );

      category = await DbHelper.instance.getCategory(id);
      expect(category, isNotNull);
      expect(category!.title, 'Category updated');
      expect(category.description, 'Category description updated');
      expect(category.color, color);
    });

    test('Transaction create test', () async {
      Account? account = await DbHelper.instance.getAccount(1);
      expect(account, isNotNull);

      int color = (Random().nextDouble() * 0xFFFFFF).toInt();
      int categoryId =
          await DbHelper.instance.createCategory('Fuel', '', color);

      int total = 10000;
      String type = 'debit';
      DateTime transactionTime = DateTime.now();
      int txnId = await DbHelper.instance.createTransaction(
        account!.id,
        'Fuel charges',
        'Petrol for my car',
        total,
        type,
        transactionTime,
      );
      expect(txnId, isPositive);

      int txnCategoryId =
          await DbHelper.instance.createTransactionCategory(txnId, categoryId);
      expect(txnCategoryId, isPositive);

      AccountTransaction? txn = await DbHelper.instance.getTransaction(txnId);
      expect(txn, isNotNull);
      expect(txn!.accountId, account.id);
      expect(txn.title, 'Fuel charges');
      expect(txn.description, 'Petrol for my car');
      expect(txn.total, total);
      expect(txn.type, type);
      expect(txn.transactionTime, transactionTime);

      TransactionCategory? txnCategory =
          await DbHelper.instance.getTransactionCategory(txnId);
      expect(txnCategory, isNotNull);
      expect(txnCategory!.id, txnCategoryId);
      expect(txnCategory.accountTransactionId, txnId);
      expect(txnCategory.categoryId, categoryId);
    });

    test('Settings test', () async {
      int settingId = await DbHelper.instance.createOrUpdateSetting(
        'key_setting',
        'test value',
      );

      expect(settingId, isPositive);

      Setting? setting = await DbHelper.instance.getSetting('key_setting');
      expect(setting, isNotNull);
      expect(setting!.value, 'test value');
    });
  });
}
