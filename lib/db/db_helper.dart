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
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqlite3/sqlite3.dart';

class DbHelper {
  static final DbHelper _instance = DbHelper._();

  DbHelper._() {}

  static DbHelper get instance => _instance;

  final dbName = "expenses.db";

  final dbVersion = "1.0";

  String? _dbPath;
  
  bool _isURI = false;

  Future<void> initialize() async {
    SharedPreferences preferences = await SharedPreferences.getInstance();
    String? directory = preferences.getString(Constants.prefDbFileLocation);
    Directory appDocumentsDir;
    if (directory != null) {
      appDocumentsDir = Directory(directory);
    } else {
      appDocumentsDir = await getApplicationDocumentsDirectory();
    }
    _dbPath = p.join(appDocumentsDir.path, "databases", dbName);

    /**
     * Handle migrations
     */
    await Migrations(dbPath: _dbPath!, isURI: _isURI).run();

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
    Database db = sqlite3.open(_dbPath!, uri: _isURI);

    var result = db.select('select * from settings');
    settings = result.map((item) => Setting.fromJson(item)).toList();

    db.dispose();

    return settings;
  }

  Future<Setting?> getSetting(String key) async {
    Setting? setting;
    Database db = sqlite3.open(_dbPath!, uri: _isURI);

    var result = db.select(
      'select * from settings where key = ?',
      [key],
    );

    setting = result.map((item) => Setting.fromJson(item)).firstOrNull;

    db.dispose();

    return setting;
  }

  Future<int> createOrUpdateSetting(String key, dynamic value) async {
    Database db = sqlite3.open(_dbPath!, uri: _isURI);

    var result = db.select(
      'select * from settings where key = ?',
      [key],
    );

    Setting? setting = result.map((item) => Setting.fromJson(item)).firstOrNull;

    if (setting != null) {
      final statement = db.prepare('update settings set value = ?');
      statement.execute([value.toString()]);

      statement.dispose();
      db.dispose();

      return setting.id;
    } else {
      final statement = db.prepare('insert into settings (key, value) values (?, ?)');
      statement.execute([key, value.toString()]);

      int insertId = db.lastInsertRowId;

      statement.dispose();
      db.dispose();

      return insertId;
    }
  }

  Future<List<Account>> getAccounts() async {
    List<Account> accounts;
    Database? db = sqlite3.open(_dbPath!, uri: _isURI);

    var result = db.select(
      'select * from accounts where deleted_at IS NULL',
    );
    accounts = result.map((item) => Account.fromJson(item)).toList();

    db.dispose();

    return accounts;
  }

  Future<int> createAccount(String accountTitle, String accountDescription,
      {int balance = 0, int initialBalance = 0, bool isDefault = false}) async {
    Database? db = sqlite3.open(_dbPath!, uri: _isURI);
        final statement = db.prepare('insert into accounts ("title", "description", "balance", "initial_balance", "default") values (?, ?, ?, ?, ?)');
    statement.execute([accountTitle, accountDescription, balance, initialBalance, isDefault ? 1 : 0]);

    int insertId = db.lastInsertRowId;

    statement.dispose();
    db.dispose();

    return insertId;
  }

  Future<Account?> getAccount(int accountId) async {
    Database? db = sqlite3.open(_dbPath!, uri: _isURI);
    var result = db.select(
      'select * from accounts where id = ?',
      [accountId],
    );

    Account? account = result.map((item) => Account.fromJson(item)).firstOrNull;

    db.dispose();

    return account;
  }

  Future<List<AccountTransaction>> getTransactions() async {
    List<AccountTransaction> transactionList;
    Database? db = sqlite3.open(_dbPath!, uri: _isURI);
    var result = db.select(
      'select * from account_transactions where deleted_at is null order by datetime(transaction_time) desc',
    );

    transactionList =
        result.map((item) => AccountTransaction.fromJson(item)).toList();

    db.dispose();

    return transactionList;
  }

  Future<List<AccountTransaction>> getAccountTransactions(int accountId) async {
    List<AccountTransaction> transactionList;
    Database? db = sqlite3.open(_dbPath!, uri: _isURI);
    var result = db.select(
      'select * from account_transactions where account_id = ? and deleted_at is null order by datetime(transaction_time) desc',
      [accountId],
    );

    transactionList =
        result.map((item) => AccountTransaction.fromJson(item)).toList();

    db.dispose();

    return transactionList;
  }

  Future<AccountTransaction?> getTransaction(int txnId) async {
    Database? db = sqlite3.open(_dbPath!, uri: _isURI);
    var result = db.select(
      'select * from account_transactions where id = ?',
      [txnId],
    );

    AccountTransaction? transaction =
        result.map((item) => AccountTransaction.fromJson(item)).firstOrNull;

    db.dispose();

    return transaction;
  }

  Future<int> createTransaction(
      int accountId,
      String title,
      String? description,
      int total,
      String type,
      DateTime transactionTime) async {
    Database? db = sqlite3.open(_dbPath!, uri: _isURI);
    final statement = db.prepare('insert into account_transactions ("account_id", "title", "description", "total", "type", "transaction_time") values (?, ?, ?, ?, ?, ?)');
    statement.execute([accountId, title, description, total, type, transactionTime.toString()]);
    int insertId = db.lastInsertRowId;

    statement.dispose();
    db.dispose();

    return insertId;
  }

  Future<int> updateTransaction(AccountTransaction transaction) async {
    Database? db = sqlite3.open(_dbPath!, uri: _isURI);
    final statement = db.prepare('update account_transactions set account_id = ?, title = ?, description = ?, total = ?, type = ?, transaction_time = ? where id = ?');
    statement.execute([transaction.accountId, transaction.title, transaction.description, transaction.total, transaction.type, transaction.transactionTime.toString(), transaction.id]);

    statement.dispose();
    db.dispose();

    return transaction.id;
  }

  Future<List<Category>> getCategories() async {
    List<Category> categories;
    Database? db = sqlite3.open(_dbPath!, uri: _isURI);

    var result = db.select(
      'select * from categories where deleted_at is null order by id desc',
    );
    categories = result.map((item) => Category.fromJson(item)).toList();

    db.dispose();

    return categories;
  }

  Future<Category?> getCategory(int id) async {
    Database? db = sqlite3.open(_dbPath!, uri: _isURI);

    var result = db.select(
      'select * from categories where id = ? and deleted_at is null',
      [id],
    );
    Category? category =
        result.map((item) => Category.fromJson(item)).firstOrNull;

    db.dispose();

    return category;
  }

  Future<int> createCategory(
      String title, String description, int color) async {
    Database? db = sqlite3.open(_dbPath!, uri: _isURI);
    final statement = db.prepare('insert into categories ("title", "description", "color") values (?, ?, ?)');
    statement.execute([title, description, color]);
    int insertId = db.lastInsertRowId;

    statement.dispose();
    db.dispose();

    return insertId;
  }

  Future<int> updateCategory(
      int categoryId, String title, String description, int color) async {
    Database? db = sqlite3.open(_dbPath!, uri: _isURI);
    final statement = db.prepare('update categories set title = ?, description = ?, color = ? where id = ?');
    statement.execute([title, description, color, categoryId]);

    statement.dispose();
    db.dispose();

    return categoryId;
  }

  Future<TransactionCategory?> getTransactionCategory(int txnId) async {
    Database? db = sqlite3.open(_dbPath!, uri: _isURI);
    var result = db.select(
      'select * from transaction_categories where account_transaction_id = ? and deleted_at is null',
      [txnId],
    );
    TransactionCategory? transactionCategory =
        result.map((item) => TransactionCategory.fromJson(item)).firstOrNull;

    db.dispose();

    return transactionCategory;
  }

  Future<int> createTransactionCategory(
    int txnId,
    int categoryId,
  ) async {
    Database? db = sqlite3.open(_dbPath!, uri: _isURI);
    final statement = db.prepare('insert into transaction_categories ("account_transaction_id", "category_id") values(?, ?)');
    statement.execute([txnId, categoryId]);

    int insertId = db.lastInsertRowId;

    statement.dispose();
    db.dispose();

    return insertId;
  }

  Future<int> updateTransactionCategory(
    int transactionCategoryId,
    int txnId,
    int categoryId,
  ) async {
    Database? db = sqlite3.open(_dbPath!, uri: _isURI);
    final statement = db.prepare('update transaction_categories set account_transaction_id = ?, category_id = ? where id = ?');
    statement.execute([txnId, categoryId, transactionCategoryId]);

    statement.dispose();
    db.dispose();

    return transactionCategoryId;
  }

  Future<List<CategoryMap>> getChartData() async {
    Database? db = sqlite3.open(_dbPath!, uri: _isURI);
    var transactionTotalResult = db.select("""
      select sum(total) as total from account_transactions
      where type='debit' and deleted_at is null
    """);

    TransactionTotal transactionTotal = transactionTotalResult
        .map((item) => TransactionTotal.fromJson(item))
        .first;

    var categoryWiseResult = db.select("""
      select c.title, sum(a.total) as total, c.color from transaction_categories as tc
      inner join account_transactions as a on tc.account_transaction_id = a.id
      inner join categories as c on tc.category_id = c.id
      where a.type='debit' and a.deleted_at is null and tc.deleted_at is null
      group by c.title order by total DESC
    """);

    List<CategoryMap> map =
        categoryWiseResult.map((item) => CategoryMap.fromJson(item)).toList();

    map = map.map((item) {
      item.percent = (item.total! * 100 / transactionTotal.total!).round();
      return item;
    }).toList();

    db.dispose();

    return map;
  }
}
