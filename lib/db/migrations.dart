import 'package:sqflite_common_ffi/sqflite_ffi.dart';

class Migrations {
  late final String _dbPath;

  Migrations({required String dbPath}) {
    _dbPath = dbPath;
  }

  Future<void> run() async {
    _createAccountsTable();
    _createAccountTransactionsTable();
    _createAccountTransfersTabel();
    _createCategoriesTable();
    _createTrasactionCategoriesTable();
    _createTagsTable();
    _createTransactionTagsTable();
    _createSettingsTable();
  }

  Future<void> _createAccountsTable() async {
    Database db = await databaseFactory.openDatabase(_dbPath);
    db.execute('''
      CREATE TABLE IF NOT EXISTS "accounts" (
        "id"	INTEGER NOT NULL,
        "title"	text NOT NULL,
        "description"	text,
        "active"	integer NOT NULL DEFAULT 1,
        "default" integer NOT NULL DEFAULT 0,
        "icon"	text,
        "balance"	INTEGER NOT NULL,
        "initial_balance"	INTEGER NOT NULL DEFAULT 0,
        "created_at"	TEXT DEFAULT CURRENT_TIMESTAMP,
        "updated_at"	TEXT DEFAULT CURRENT_TIMESTAMP,
        "deleted_at"	text,
        PRIMARY KEY("id" AUTOINCREMENT)
      );
    ''');
  }

  Future<void> _createAccountTransactionsTable() async {
    Database db = await databaseFactory.openDatabase(_dbPath);
    db.execute('''
      CREATE TABLE IF NOT EXISTS "account_transactions" (
        "id"	INTEGER NOT NULL,
        "account_id"	INTEGER NOT NULL,
        "title"	TEXT,
        "description"	TEXT,
        "total"	INTEGER NOT NULL,
        "type"	TEXT NOT NULL,
        "transaction_time"	TEXT NOT NULL,
        "created_at"	TEXT DEFAULT CURRENT_TIMESTAMP,
        "updated_at"	TEXT DEFAULT CURRENT_TIMESTAMP,
        "deleted_at"	TEXT,
        PRIMARY KEY("id" AUTOINCREMENT),
        FOREIGN KEY("account_id") REFERENCES "accounts"("id")
      );
    ''');
  }

  Future<void> _createAccountTransfersTabel() async {
    Database db = await databaseFactory.openDatabase(_dbPath);
    db.execute('''
      CREATE TABLE IF NOT EXISTS "account_transfers" (
        "id"	INTEGER NOT NULL,
        "title"	TEXT,
        "description"	TEXT,
        "account_from"	INTEGER NOT NULL,
        "account_to"	INTEGER NOT NULL,
        "total"	INTEGER NOT NULL,
        "created_at"	TEXT DEFAULT CURRENT_TIMESTAMP,
        "updated_at"	TEXT DEFAULT CURRENT_TIMESTAMP,
        "deleted_at"	TEXT,
        PRIMARY KEY("id" AUTOINCREMENT),
        FOREIGN KEY("account_from") REFERENCES "accounts"("id"),
        FOREIGN KEY("account_to") REFERENCES "accounts"("id")
      );
    ''');
  }

  Future<void> _createCategoriesTable() async {
    Database db = await databaseFactory.openDatabase(_dbPath);
    db.execute('''
      CREATE TABLE IF NOT EXISTS "categories" (
        "id"	INTEGER NOT NULL,
        "title"	TEXT NOT NULL,
        "description"	TEXT,
        "created_at"	TEXT DEFAULT CURRENT_TIMESTAMP,
        "updated_at"	TEXT DEFAULT CURRENT_TIMESTAMP,
        "deleted_at"	TEXT,
        PRIMARY KEY("id" AUTOINCREMENT)
      );
    ''');
  }

  Future<void> _createTrasactionCategoriesTable() async {
    Database db = await databaseFactory.openDatabase(_dbPath);
    db.execute('''
      CREATE TABLE IF NOT EXISTS "transaction_categories" (
        "id"	INTEGER NOT NULL,
        "account_transaction_id"	INTEGER NOT NULL,
        "category_id"	INTEGER NOT NULL,
        "created_at"	TEXT DEFAULT CURRENT_TIMESTAMP,
        "updated_at"	TEXT DEFAULT CURRENT_TIMESTAMP,
        "deleted_at"	TEXT,
        PRIMARY KEY("id" AUTOINCREMENT),
        FOREIGN KEY("account_transaction_id") REFERENCES "account_transactions"("id"),
        FOREIGN KEY("category_id") REFERENCES "categories"("id")
      );
    ''');
  }

  Future<void> _createTagsTable() async {
    Database db = await databaseFactory.openDatabase(_dbPath);
    db.execute('''
      CREATE TABLE IF NOT EXISTS "tags" (
        "id"	INTEGER NOT NULL,
        "title"	TEXT NOT NULL,
        "description"	TEXT,
        "color"	TEXT,
        "created_at"	TEXT DEFAULT CURRENT_TIMESTAMP,
        "updated_at"	TEXT DEFAULT CURRENT_TIMESTAMP,
        "deleted_at"	TEXT,
        PRIMARY KEY("id" AUTOINCREMENT)
      );
    ''');
  }

  Future<void> _createTransactionTagsTable() async {
    Database db = await databaseFactory.openDatabase(_dbPath);
    db.execute('''
      CREATE TABLE IF NOT EXISTS "transaction_tags" (
        "id"	INTEGER NOT NULL,
        "account_transaction_id"	INTEGER NOT NULL,
        "tag_id"	INTEGER NOT NULL,
        "created_at"	TEXT DEFAULT CURRENT_TIMESTAMP,
        "updated_at"	TEXT DEFAULT CURRENT_TIMESTAMP,
        "deleted_at"	TEXT,
        PRIMARY KEY("id" AUTOINCREMENT),
        FOREIGN KEY("account_transaction_id") REFERENCES "account_transactions"("id"),
        FOREIGN KEY("tag_id") REFERENCES "tags"("id")
      );
    ''');
  }

  Future<void> _createSettingsTable() async {
    Database db = await databaseFactory.openDatabase(_dbPath);
    db.execute('''
      CREATE TABLE IF NOT EXISTS "settings" (
        "id"	INTEGER NOT NULL,
        "key"	TEXT NOT NULL,
        "value"	TEXT NOT NULL,
        "description"	TEXT,
        "created_at"	TEXT DEFAULT CURRENT_TIMESTAMP,
        "updated_at"	TEXT DEFAULT CURRENT_TIMESTAMP,
        "deleted_at"	TEXT,
        PRIMARY KEY("id" AUTOINCREMENT)
      );
    ''');
  }
}
