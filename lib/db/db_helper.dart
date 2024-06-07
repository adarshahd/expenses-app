import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:currency_picker/currency_picker.dart';
import 'package:expenses_app/db/initialize.dart';
import 'package:expenses_app/db/migrations.dart';
import 'package:expenses_app/models/account_transaction.dart';
import 'package:expenses_app/models/accounts.dart';
import 'package:expenses_app/models/settings.dart';
import 'package:expenses_app/models/transaction_categories.dart';
import 'package:expenses_app/utils/constants.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

class DbHelper {
  static final DbHelper _instance = DbHelper._();

  DbHelper._() {}

  static DbHelper get instance => _instance;

  final dbName = "expenses.db";

  final dbVersion = "1.0";

  String? _dbPath;

  Future<void> initialize() async {
    Directory appDocumentsDir = await getApplicationDocumentsDirectory();
    _dbPath = p.join(appDocumentsDir.path, "databases", dbName);

    /**
     * Handle migrations
     */
    await Migrations(dbPath: _dbPath!).run();

    /**
     * Initialize database with essential entries
     */
    await Initialize(dbPath: _dbPath!).run();
  }

  Future<void> clearDatabase() async {
    File.fromUri(Uri.file(_dbPath!)).deleteSync();
    initialize();
  }

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
      return setting.id;
    } else {
      int id =
          await db.insert('settings', {'key': key, 'value': value.toString()});

      return id;
    }
  }

  Future<List<Account>> geAccounts() async {
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

    return id;
  }

  Future<List<AccountTransaction>> getTransactions() async {
    List<AccountTransaction> transactionList;
    Database? db = await databaseFactory.openDatabase(_dbPath!);
    var result = await db.query(
      'account_transactions',
      where: 'deleted_at IS NULL',
      orderBy: 'id desc',
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
      orderBy: 'id desc',
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

    return id;
  }

  Future<List<TransactionCategory>> getCategories() async {
    List<TransactionCategory> categories;
    Database? db = await databaseFactory.openDatabase(_dbPath!);

    var result = await db.query(
      'categories',
      where: 'deleted_at IS NULL',
      orderBy: 'id desc',
    );
    categories =
        result.map((item) => TransactionCategory.fromJson(item)).toList();

    return categories;
  }

  Future<TransactionCategory?> getCategory(int id) async {
    Database? db = await databaseFactory.openDatabase(_dbPath!);

    var result = await db.query(
      'categories',
      where: 'id = ?1 AND deleted_at IS NULL',
      whereArgs: [id],
    );
    TransactionCategory? category =
        result.map((item) => TransactionCategory.fromJson(item)).firstOrNull;

    return category;
  }

  Future<int> createCategory(String title, String description) async {
    Database? db = await databaseFactory.openDatabase(_dbPath!);

    int id = await db.insert('categories', {
      'title': title,
      'description': description,
    });

    return id;
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

  Future<int> createOrUpdateTransactionCategory(
    int txnId,
    int categoryId,
  ) async {
    Database? db = await databaseFactory.openDatabase(_dbPath!);
    TransactionCategory? category = await getTransactionCategory(txnId);
    int id;
    if (category == null) {
      id = await db.insert(
        'transaction_categories',
        {
          'account_transaction_id': txnId,
          'category_id': categoryId,
        },
      );
    } else {
      id = category.id;
      await db.update(
          'transaction_categories',
          {
            'account_transaction_id': txnId,
            'category_id': categoryId,
          },
          where: 'id = ?',
          whereArgs: [id]);
    }

    return id;
  }
}
