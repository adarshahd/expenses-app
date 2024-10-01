import 'dart:async';
import 'dart:io';
import 'package:expenses_app/db/initialize.dart';
import 'package:expenses_app/db/migrations.dart';
import 'package:expenses_app/models/account_transaction.dart';
import 'package:expenses_app/models/accounts.dart';
import 'package:expenses_app/models/categories.dart';
import 'package:expenses_app/models/charts/category_map.dart';
import 'package:expenses_app/models/charts/transaction_total.dart';
import 'package:expenses_app/models/settings.dart';
import 'package:expenses_app/models/transaction_categories.dart';
import 'package:expenses_app/utils/constants.dart';
import 'package:flutter/services.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

class DbHelper {
  static final DbHelper _instance = DbHelper._();

  static const MethodChannel _channel = MethodChannel("io.gthink.expenses/file_operations");

  DbHelper._() {}

  static DbHelper get instance => _instance;

  static const dbName = "expenses.db";

  final dbVersion = "1.0";

  String? _dbPath;

  String? _customPath;

  Future<void> initialize() async {
    SharedPreferences preferences = await SharedPreferences.getInstance();
    _customPath = preferences.getString(Constants.prefDbFileLocation);
    Directory appDocumentsDir = await getApplicationDocumentsDirectory();

    _dbPath = p.join(appDocumentsDir.path, '', dbName);

    if (_customPath != null) {
      if(Platform.isAndroid) {
        await _syncDatabaseFile(false);
      } else {
        _dbPath = _customPath;
      }
    }

    /**
     * Handle migrations
     */
    await Migrations(dbPath: _dbPath!).run();

    /**
     * Initialize database with essential entries
     */
    await Initialize(dbPath: _dbPath!).run();
  }

  // Future<void> clearDatabase() async {
  //   File(_dbPath!).deleteSync();
  //   initialize();
  // }

  Future<List<Setting>> getSettings() async {
    List<Setting> settings;
    Database db = await databaseFactory.openDatabase(_dbPath!);

    var result = await db.query('settings');
    settings = result.map((item) => Setting.fromJson(item)).toList();

    return settings;
  }

  Future<Setting?> getSetting(String key) async {
    Setting? setting;
    Database db = await databaseFactory.openDatabase(_dbPath!);

    var result = await db.query(
      'settings',
      where: 'key = ?1',
      whereArgs: [key],
    );

    setting = result.map((item) => Setting.fromJson(item)).firstOrNull;

    return setting;
  }

  Future<int> createOrUpdateSetting(String key, dynamic value) async {
    Database db = await databaseFactory.openDatabase(_dbPath!);

    var result = await db.query(
      'settings',
      where: 'key = ?1',
      whereArgs: [key],
    );

    Setting? setting = result.map((item) => Setting.fromJson(item)).firstOrNull;

    if (setting != null) {
      await db.update(
        'settings',
        {'key': key, 'value': value.toString()},
        where: 'key = ?',
        whereArgs: [key],
      );

      if(Platform.isAndroid) {
        await _syncDatabaseFile(true);
      }

      return setting.id;
    } else {
      int id =
          await db.insert('settings', {'key': key, 'value': value.toString()});

      if(Platform.isAndroid) {
        await _syncDatabaseFile(true);
      }

      return id;
    }
  }

  Future<List<Account>> getAccounts() async {
    List<Account> accounts;
    Database? db = await databaseFactory.openDatabase(_dbPath!);

    var result = await db.query(
      'accounts',
      where: 'deleted_at IS NULL',
    );
    accounts = result.map((item) => Account.fromJson(item)).toList();

    return accounts;
  }

  Future<int> createAccount(String accountTitle, String accountDescription,
      {int balance = 0, int initialBalance = 0, bool isDefault = false}) async {
    Database? db = await databaseFactory.openDatabase(_dbPath!);
    int id = await db.insert('accounts', {
      'title': accountTitle,
      'description': accountDescription,
      'balance': balance,
      'initial_balance': initialBalance,
      'default': isDefault ? 1 : 0
    });

    if(Platform.isAndroid) {
      await _syncDatabaseFile(true);
    }

    return id;
  }

  Future<Account?> getAccount(int accountId) async {
    Database? db = await databaseFactory.openDatabase(_dbPath!);
    var result = await db.query(
      'accounts',
      where: 'id = ?1',
      whereArgs: [accountId],
    );

    Account? account = result.map((item) => Account.fromJson(item)).firstOrNull;

    return account;
  }

  Future<List<AccountTransaction>> getTransactions() async {
    List<AccountTransaction> transactionList;
    Database? db = await databaseFactory.openDatabase(_dbPath!);
    var result = await db.query(
      'account_transactions',
      where: 'deleted_at IS NULL',
      orderBy: 'datetime(transaction_time) desc',
    );

    transactionList =
        result.map((item) => AccountTransaction.fromJson(item)).toList();
    return transactionList;
  }

  Future<List<AccountTransaction>> getAccountTransactions(int accountId) async {
    List<AccountTransaction> transactionList;
    Database? db = await databaseFactory.openDatabase(_dbPath!);
    var result = await db.query(
      'account_transactions',
      where: 'account_id = ?1 AND deleted_at IS NULL',
      whereArgs: [accountId],
      orderBy: 'datetime(transaction_time) desc',
    );

    transactionList =
        result.map((item) => AccountTransaction.fromJson(item)).toList();
    return transactionList;
  }

  Future<AccountTransaction?> getTransaction(int txnId) async {
    Database? db = await databaseFactory.openDatabase(_dbPath!);
    var result = await db.query(
      'account_transactions',
      where: 'id = ?1',
      whereArgs: [txnId],
    );

    AccountTransaction? transaction =
        result.map((item) => AccountTransaction.fromJson(item)).firstOrNull;
    return transaction;
  }

  Future<int> createTransaction(
      int accountId,
      String title,
      String? description,
      int total,
      String type,
      DateTime transactionTime) async {
    Database? db = await databaseFactory.openDatabase(_dbPath!);

    int id = await db.insert(
      'account_transactions',
      {
        'account_id': accountId,
        'title': title,
        'description': description,
        'total': total,
        'type': type,
        'transaction_time': transactionTime.toString(),
      },
    );

    if(Platform.isAndroid) {
      await _syncDatabaseFile(true);
    }

    return id;
  }

  Future<int> updateTransaction(AccountTransaction transaction) async {
    Database? db = await databaseFactory.openDatabase(_dbPath!);
    int id = await db.update(
      'account_transactions',
      {
        'account_id': transaction.accountId,
        'title': transaction.title,
        'description': transaction.description,
        'total': transaction.total,
        'type': transaction.type,
        'transaction_time': transaction.transactionTime.toString(),
      },
      where: 'id = ?',
      whereArgs: [transaction.id],
    );

    if(Platform.isAndroid) {
      await _syncDatabaseFile(true);
    }

    return id;
  }

  Future<List<Category>> getCategories() async {
    List<Category> categories;
    Database? db = await databaseFactory.openDatabase(_dbPath!);

    var result = await db.query(
      'categories',
      where: 'deleted_at IS NULL',
      orderBy: 'id desc',
    );
    categories = result.map((item) => Category.fromJson(item)).toList();

    return categories;
  }

  Future<Category?> getCategory(int id) async {
    Database? db = await databaseFactory.openDatabase(_dbPath!);

    var result = await db.query(
      'categories',
      where: 'id = ?1 AND deleted_at IS NULL',
      whereArgs: [id],
    );
    Category? category =
        result.map((item) => Category.fromJson(item)).firstOrNull;

    return category;
  }

  Future<int> createCategory(
      String title, String description, int color) async {
    Database? db = await databaseFactory.openDatabase(_dbPath!);

    int id = await db.insert(
      'categories',
      {
        'title': title,
        'description': description,
        'color': color,
      },
    );

    if(Platform.isAndroid) {
      await _syncDatabaseFile(true);
    }

    return id;
  }

  Future<int> updateCategory(
      int categoryId, String title, String description, int color) async {
    Database? db = await databaseFactory.openDatabase(_dbPath!);

    await db.update(
      'categories',
      {
        'title': title,
        'description': description,
        'color': color,
      },
      where: 'id = ?',
      whereArgs: [categoryId],
    );

    if(Platform.isAndroid) {
      await _syncDatabaseFile(true);
    }

    return categoryId;
  }

  Future<TransactionCategory?> getTransactionCategory(int txnId) async {
    Database? db = await databaseFactory.openDatabase(_dbPath!);
    var result = await db.query(
      'transaction_categories',
      where: 'account_transaction_id = ?1 AND deleted_at IS NULL',
      whereArgs: [txnId],
    );
    TransactionCategory? transactionCategory =
        result.map((item) => TransactionCategory.fromJson(item)).firstOrNull;

    return transactionCategory;
  }

  Future<int> createTransactionCategory(
    int txnId,
    int categoryId,
  ) async {
    Database? db = await databaseFactory.openDatabase(_dbPath!);
    int id = await db.insert(
      'transaction_categories',
      {
        'account_transaction_id': txnId,
        'category_id': categoryId,
      },
    );

    if(Platform.isAndroid) {
      await _syncDatabaseFile(true);
    }

    return id;
  }

  Future<int> updateTransactionCategory(
    int transactionCategoryId,
    int txnId,
    int categoryId,
  ) async {
    Database? db = await databaseFactory.openDatabase(_dbPath!);
    await db.update(
      'transaction_categories',
      {
        'account_transaction_id': txnId,
        'category_id': categoryId,
      },
      where: 'id = ?',
      whereArgs: [transactionCategoryId],
    );

    if(Platform.isAndroid) {
      await _syncDatabaseFile(true);
    }

    return transactionCategoryId;
  }

  Future<List<CategoryMap>> getChartData() async {
    Database? db = await databaseFactory.openDatabase(_dbPath!);
    var transactionTotalResult = await db.rawQuery("""
      select sum(total) as total from account_transactions
      where type='debit' and deleted_at is null
    """);

    TransactionTotal transactionTotal = transactionTotalResult
        .map((item) => TransactionTotal.fromJson(item))
        .first;

    var categorywiseResult = await db.rawQuery("""
      select c.title, sum(a.total) as total, c.color from transaction_categories as tc
      inner join account_transactions as a on tc.account_transaction_id = a.id
      inner join categories as c on tc.category_id = c.id
      where a.type='debit' and a.deleted_at is null and tc.deleted_at is null
      group by c.title order by total DESC
    """);

    List<CategoryMap> map =
        categorywiseResult.map((item) => CategoryMap.fromJson(item)).toList();

    map = map.map((item) {
      item.percent = (item.total! * 100 / transactionTotal.total!).round();
      return item;
    }).toList();

    return map;
  }

  _syncDatabaseFile(bool shouldUpdateSource) async {
    if (_customPath == null) {
      return;
    }

    if(shouldUpdateSource) {
      await _channel.invokeMethod("copy_files", ['file://$_dbPath', _customPath]);
    } else {
      await _channel.invokeMethod("copy_files", [_customPath, 'file://$_dbPath']);
    }

    return;
  }
}
