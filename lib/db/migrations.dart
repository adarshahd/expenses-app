import 'dart:io';

import 'package:sqlite3/sqlite3.dart';

class Migrations {
  late final String _dbPath;
  late final bool _isURI;

  Migrations({required String dbPath, required bool isURI}) {
    _dbPath = dbPath;
    _isURI = isURI;
  }

  Future<void> run() async {
    await _createAccountsTable();
    await _createAccountTransactionsTable();
    await _createAccountTransfersTabel();
    await _createCategoriesTable();
    await _createTrasactionCategoriesTable();
    await _createTagsTable();
    await _createTransactionTagsTable();
    await _createSettingsTable();
  }

  Future<void> _createAccountsTable() async {
    Database db = sqlite3.open(_dbPath, uri: _isURI);
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
    Database db = sqlite3.open(_dbPath, uri: _isURI);
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
    Database db = sqlite3.open(_dbPath, uri: _isURI);
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
    Database db = sqlite3.open(_dbPath, uri: _isURI);
    db.execute('''
      CREATE TABLE IF NOT EXISTS "categories" (
        "id"	INTEGER NOT NULL,
        "title"	TEXT NOT NULL,
        "description"	TEXT,
        "color" INTEGER,
        "created_at"	TEXT DEFAULT CURRENT_TIMESTAMP,
        "updated_at"	TEXT DEFAULT CURRENT_TIMESTAMP,
        "deleted_at"	TEXT,
        PRIMARY KEY("id" AUTOINCREMENT)
      );
    ''');
  }

  Future<void> _createTrasactionCategoriesTable() async {
    Database db = sqlite3.open(_dbPath, uri: _isURI);
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
    Database db = sqlite3.open(_dbPath, uri: _isURI);
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
    Database db = sqlite3.open(_dbPath, uri: _isURI);
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
    Database db = sqlite3.open(_dbPath, uri: _isURI);
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
