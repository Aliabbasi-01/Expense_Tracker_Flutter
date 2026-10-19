import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart';

import 'package:expense_tracker/database/database_helper.dart';
import 'package:expense_tracker/services/currency_service.dart';

// ===================== Theme colors =====================
const Color kPrimary = Color(0xFF5B4BFF);
const Color kDark = Color(0xFF1B1B2F);
const Color kIncome = Color(0xFF00B894);
const Color kExpense = Color(0xFFFF6B6B);
const Color kBackground = Color(0xFFF7F7FB);

// ===================== Session =====================
/// Login ke baad yahan current user save hota hai.
class Session {
  static int? userId;
  static String? userName;
  static String? userEmail;

  static void clear() {
    userId = null;
    userName = null;
    userEmail = null;
  }
}

// ===================== Formatting helpers =====================
const _fullMonths = [
  'January',
  'February',
  'March',
  'April',
  'May',
  'June',
  'July',
  'August',
  'September',
  'October',
  'November',
  'December',
];
const _shortMonths = [
  'Jan',
  'Feb',
  'Mar',
  'Apr',
  'May',
  'Jun',
  'Jul',
  'Aug',
  'Sep',
  'Oct',
  'Nov',
  'Dec',
];

String monthName(int m) => _fullMonths[m - 1];
String shortMonth(int m) => _shortMonths[m - 1];

/// Format a stored PKR amount in the user's selected display currency.
String money(double v) => CurrencyService.instance.format(v);

/// 1500 -> "1.5k", 2000000 -> "2M" (chart labels ke liye)
String compact(double v) {
  v = CurrencyService.instance.convertFromBase(v);
  final currency = CurrencyService.instance.selectedCurrency;
  final symbolSpace =
      const {'PKR', 'AED', 'SAR', 'CHF', 'QAR', 'KWD'}.contains(currency.code)
      ? ' '
      : '';
  final prefix = '${currency.symbol}$symbolSpace';
  if (v >= 1000000) {
    return '$prefix${(v / 1000000).toStringAsFixed(v % 1000000 == 0 ? 0 : 1)}M';
  }
  if (v >= 1000) {
    return '$prefix${(v / 1000).toStringAsFixed(v % 1000 == 0 ? 0 : 1)}k';
  }
  return '$prefix${v.toStringAsFixed(0)}';
}

String friendlyDate(DateTime d) {
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final day = DateTime(d.year, d.month, d.day);
  final diff = today.difference(day).inDays;
  if (diff == 0) return 'Today';
  if (diff == 1) return 'Yesterday';
  return '${d.day} ${shortMonth(d.month)} ${d.year}';
}

InputDecoration fieldDecoration(String hint, IconData icon) {
  return InputDecoration(
    hintText: hint,
    prefixIcon: Icon(icon, color: Colors.grey.shade600),
    filled: true,
    fillColor: const Color(0xFFF3F4F8),
    contentPadding: const EdgeInsets.symmetric(vertical: 18),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: BorderSide.none,
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: const BorderSide(color: kPrimary, width: 1.5),
    ),
    errorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: const BorderSide(color: Colors.redAccent),
    ),
    focusedErrorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: const BorderSide(color: Colors.redAccent, width: 1.5),
    ),
  );
}

// ===================== Categories & wallet types =====================
class CategoryInfo {
  final String name;
  final IconData icon;
  final Color color;
  const CategoryInfo(this.name, this.icon, this.color);
}

class Categories {
  static const expense = [
    CategoryInfo('Food', Icons.restaurant, Color(0xFFFF7043)),
    CategoryInfo('Transport', Icons.directions_car, Color(0xFF0984E3)),
    CategoryInfo('Shopping', Icons.shopping_bag, Color(0xFFE84393)),
    CategoryInfo('Bills', Icons.receipt_long, Color(0xFFFDCB6E)),
    CategoryInfo('Health', Icons.favorite, Color(0xFFD63031)),
    CategoryInfo('Entertainment', Icons.movie, Color(0xFF6C5CE7)),
    CategoryInfo('Education', Icons.school, Color(0xFF00B894)),
    CategoryInfo('Other', Icons.category, Color(0xFF636E72)),
  ];

  static const income = [
    CategoryInfo('Salary', Icons.work, Color(0xFF00B894)),
    CategoryInfo('Business', Icons.storefront, Color(0xFF0984E3)),
    CategoryInfo('Gift', Icons.card_giftcard, Color(0xFFE84393)),
    CategoryInfo('Investment', Icons.trending_up, Color(0xFF6C5CE7)),
    CategoryInfo('Other', Icons.category, Color(0xFF636E72)),
  ];

  static CategoryInfo find(String name, {required bool income}) {
    final list = income ? Categories.income : Categories.expense;
    return list.firstWhere(
      (c) => c.name == name,
      orElse: () =>
          const CategoryInfo('Other', Icons.category, Color(0xFF636E72)),
    );
  }
}

class WalletTypes {
  static const keys = ['cash', 'bank', 'card', 'mobile'];

  static String label(String key) {
    switch (key) {
      case 'bank':
        return 'Bank';
      case 'card':
        return 'Card';
      case 'mobile':
        return 'Mobile wallet';
      default:
        return 'Cash';
    }
  }

  static IconData icon(String key) {
    switch (key) {
      case 'bank':
        return Icons.account_balance;
      case 'card':
        return Icons.credit_card;
      case 'mobile':
        return Icons.phone_android;
      default:
        return Icons.payments;
    }
  }
}

const List<int> kWalletColors = [
  0xFF5B4BFF,
  0xFF00B894,
  0xFFFF7043,
  0xFF0984E3,
  0xFFE84393,
  0xFF2D3436,
];

// ===================== Models =====================
class Wallet {
  final int id;
  final String name;
  final String type;
  final double initialBalance;
  final int color;
  final double balance; // initial + income - expense

  const Wallet({
    required this.id,
    required this.name,
    required this.type,
    required this.initialBalance,
    required this.color,
    required this.balance,
  });

  factory Wallet.fromMap(Map<String, Object?> m) {
    final initial = (m['initial_balance'] as num).toDouble();
    final delta = (m['delta'] as num?)?.toDouble() ?? 0;
    return Wallet(
      id: m['id'] as int,
      name: m['name'] as String,
      type: m['type'] as String,
      initialBalance: initial,
      color: m['color'] as int,
      balance: initial + delta,
    );
  }

  IconData get icon => WalletTypes.icon(type);
}

class TxItem {
  final int id;
  final int walletId;
  final String walletName;
  final bool isIncome;
  final double amount;
  final String category;
  final String note;
  final DateTime date;

  const TxItem({
    required this.id,
    required this.walletId,
    required this.walletName,
    required this.isIncome,
    required this.amount,
    required this.category,
    required this.note,
    required this.date,
  });

  factory TxItem.fromMap(Map<String, Object?> m) {
    return TxItem(
      id: m['id'] as int,
      walletId: m['wallet_id'] as int,
      walletName: m['wallet_name'] as String,
      isIncome: m['type'] == 'income',
      amount: (m['amount'] as num).toDouble(),
      category: m['category'] as String,
      note: (m['note'] as String?) ?? '',
      date: DateTime.parse(m['date'] as String),
    );
  }
}

// ===================== Service =====================
class FinanceService {
  FinanceService._();
  static final FinanceService instance = FinanceService._();

  /// Jab bhi data badalta hai ye number badhta hai; screens isay sun kar reload karti hain.
  final ValueNotifier<int> changes = ValueNotifier<int>(0);
  void _notify() => changes.value++;

  int get _uid {
    final id = Session.userId;
    if (id == null) throw StateError('No user logged in');
    return id;
  }

  Future<Database> get _db => DatabaseHelper.instance.database;

  // ---------- wallets ----------
  Future<List<Map<String, Object?>>> _walletRows(Database db) {
    return db.rawQuery(
      '''
      SELECT w.*,
        COALESCE((
          SELECT SUM(CASE WHEN t.type = 'income' THEN t.amount ELSE -t.amount END)
          FROM transactions t WHERE t.wallet_id = w.id
        ), 0) AS delta
      FROM wallets w
      WHERE w.user_id = ?
      ORDER BY w.id
    ''',
      [_uid],
    );
  }

  Future<List<Wallet>> getWallets() async {
    final db = await _db;
    var rows = await _walletRows(db);

    // Pehli dafa user ke liye default "Cash" wallet bana dete hain
    if (rows.isEmpty) {
      await db.insert('wallets', {
        'user_id': _uid,
        'name': 'Cash',
        'type': 'cash',
        'initial_balance': 0,
        'color': kWalletColors[0],
        'created_at': DateTime.now().toIso8601String(),
      });
      rows = await _walletRows(db);
    }
    return rows.map(Wallet.fromMap).toList();
  }

  Future<void> addWallet({
    required String name,
    required String type,
    required double initialBalance,
    required int color,
  }) async {
    final db = await _db;
    await db.insert('wallets', {
      'user_id': _uid,
      'name': name.trim(),
      'type': type,
      'initial_balance': initialBalance,
      'color': color,
      'created_at': DateTime.now().toIso8601String(),
    });
    _notify();
  }

  Future<void> updateWallet({
    required int id,
    required String name,
    required String type,
    required double initialBalance,
    required int color,
  }) async {
    final db = await _db;
    await db.update(
      'wallets',
      {
        'name': name.trim(),
        'type': type,
        'initial_balance': initialBalance,
        'color': color,
      },
      where: 'id = ? AND user_id = ?',
      whereArgs: [id, _uid],
    );
    _notify();
  }

  Future<void> deleteWallet(int id) async {
    final db = await _db;
    await db.transaction((txn) async {
      await txn.delete(
        'transactions',
        where: 'wallet_id = ? AND user_id = ?',
        whereArgs: [id, _uid],
      );
      await txn.delete(
        'wallets',
        where: 'id = ? AND user_id = ?',
        whereArgs: [id, _uid],
      );
    });
    _notify();
  }

  // ---------- transactions ----------
  Future<void> addTransaction({
    required int walletId,
    required bool isIncome,
    required double amount,
    required String category,
    required String note,
    required DateTime date,
  }) async {
    final db = await _db;
    await db.insert('transactions', {
      'user_id': _uid,
      'wallet_id': walletId,
      'type': isIncome ? 'income' : 'expense',
      'amount': amount,
      'category': category,
      'note': note.trim(),
      'date': date.toIso8601String(),
    });
    _notify();
  }

  Future<void> deleteTransaction(int id) async {
    final db = await _db;
    await db.delete(
      'transactions',
      where: 'id = ? AND user_id = ?',
      whereArgs: [id, _uid],
    );
    _notify();
  }

  Future<List<TxItem>> getTransactions({int? walletId, int limit = 100}) async {
    final db = await _db;
    final rows = await db.rawQuery(
      '''
      SELECT t.*, w.name AS wallet_name
      FROM transactions t
      JOIN wallets w ON w.id = t.wallet_id
      WHERE t.user_id = ? ${walletId != null ? 'AND t.wallet_id = ?' : ''}
      ORDER BY t.date DESC, t.id DESC
      LIMIT ?
    ''',
      [_uid, if (walletId != null) walletId, limit],
    );
    return rows.map(TxItem.fromMap).toList();
  }

  Future<int> countTransactions() async {
    final db = await _db;
    final r = await db.rawQuery(
      'SELECT COUNT(*) AS c FROM transactions WHERE user_id = ?',
      [_uid],
    );
    return Sqflite.firstIntValue(r) ?? 0;
  }

  /// [start] inclusive, [end] exclusive
  Future<List<TxItem>> getTransactionsBetween(
    DateTime start,
    DateTime end, {
    int? walletId,
  }) async {
    final db = await _db;
    final rows = await db.rawQuery(
      '''
      SELECT t.*, w.name AS wallet_name
      FROM transactions t
      JOIN wallets w ON w.id = t.wallet_id
      WHERE t.user_id = ? AND t.date >= ? AND t.date < ?
        ${walletId != null ? 'AND t.wallet_id = ?' : ''}
      ORDER BY t.date DESC, t.id DESC
    ''',
      [
        _uid,
        start.toIso8601String(),
        end.toIso8601String(),
        if (walletId != null) walletId,
      ],
    );
    return rows.map(TxItem.fromMap).toList();
  }
}
