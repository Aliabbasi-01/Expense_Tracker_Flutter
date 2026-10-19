import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

class DatabaseHelper {
  DatabaseHelper._();
  static final DatabaseHelper instance = DatabaseHelper._();

  static Database? _db;

  Future<Database> get database async => _db ??= await _init();

  Future<Database> _init() async {
    final path = join(await getDatabasesPath(), 'app.db');

    return openDatabase(
      path,
      version: 3,
      onConfigure: (db) async {
        await db.execute('PRAGMA foreign_keys = ON');
      },
      onCreate: (db, version) async {
        await _createUsers(db);
        await _createFinance(db);
        await _createCurrencyRates(db);
      },
      // Existing user and finance data is preserved during schema upgrades.
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          await _createFinance(db);
        }
        if (oldVersion < 3) {
          await db.execute(
            "ALTER TABLE users ADD COLUMN currency_code TEXT NOT NULL DEFAULT 'PKR'",
          );
          await _createCurrencyRates(db);
        }
      },
    );
  }

  Future<void> _createUsers(Database db) async {
    await db.execute('''
      CREATE TABLE users(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        email TEXT NOT NULL UNIQUE,
        phone TEXT NOT NULL,
        password_hash TEXT NOT NULL,
        created_at TEXT NOT NULL,
        currency_code TEXT NOT NULL DEFAULT 'PKR'
      )
    ''');
  }

  Future<void> _createCurrencyRates(Database db) async {
    await db.execute('''
      CREATE TABLE exchange_rates(
        code TEXT PRIMARY KEY,
        rate REAL NOT NULL,
        fetched_at TEXT NOT NULL
      )
    ''');
  }

  Future<void> _createFinance(Database db) async {
    await db.execute('''
      CREATE TABLE wallets(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id INTEGER NOT NULL,
        name TEXT NOT NULL,
        type TEXT NOT NULL,
        initial_balance REAL NOT NULL DEFAULT 0,
        color INTEGER NOT NULL,
        created_at TEXT NOT NULL,
        FOREIGN KEY(user_id) REFERENCES users(id) ON DELETE CASCADE
      )
    ''');
    await db.execute('''
      CREATE TABLE transactions(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id INTEGER NOT NULL,
        wallet_id INTEGER NOT NULL,
        type TEXT NOT NULL,
        amount REAL NOT NULL,
        category TEXT NOT NULL,
        note TEXT,
        date TEXT NOT NULL,
        FOREIGN KEY(user_id) REFERENCES users(id) ON DELETE CASCADE,
        FOREIGN KEY(wallet_id) REFERENCES wallets(id) ON DELETE CASCADE
      )
    ''');
    await db.execute(
      'CREATE INDEX idx_tx_user_date ON transactions(user_id, date)',
    );
  }
}
