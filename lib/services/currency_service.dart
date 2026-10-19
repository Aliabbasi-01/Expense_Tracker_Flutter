import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:sqflite/sqflite.dart';

import 'package:expense_tracker/database/database_helper.dart';

class CurrencyOption {
  final String code;
  final String name;
  final String symbol;
  final int decimalDigits;

  const CurrencyOption(
    this.code,
    this.name,
    this.symbol, {
    this.decimalDigits = 2,
  });

  String get label => '$code ($symbol) · $name';
}

class CurrencyService {
  CurrencyService._();
  static final CurrencyService instance = CurrencyService._();

  static const currencies = <CurrencyOption>[
    CurrencyOption('PKR', 'Pakistani Rupee', 'Rs'),
    CurrencyOption('USD', 'US Dollar', r'$'),
    CurrencyOption('EUR', 'Euro', '€'),
    CurrencyOption('GBP', 'British Pound', '£'),
    CurrencyOption('INR', 'Indian Rupee', '₹'),
    CurrencyOption('AED', 'UAE Dirham', 'د.إ'),
    CurrencyOption('SAR', 'Saudi Riyal', 'ر.س'),
    CurrencyOption('BDT', 'Bangladeshi Taka', '৳'),
    CurrencyOption('CAD', 'Canadian Dollar', r'CA$'),
    CurrencyOption('AUD', 'Australian Dollar', r'A$'),
    CurrencyOption('JPY', 'Japanese Yen', '¥', decimalDigits: 0),
    CurrencyOption('CNY', 'Chinese Yuan', '¥'),
    CurrencyOption('TRY', 'Turkish Lira', '₺'),
    CurrencyOption('CHF', 'Swiss Franc', 'CHF'),
    CurrencyOption('SGD', 'Singapore Dollar', r'S$'),
    CurrencyOption('NZD', 'New Zealand Dollar', r'NZ$'),
    CurrencyOption('QAR', 'Qatari Riyal', 'ر.ق'),
    CurrencyOption('KWD', 'Kuwaiti Dinar', 'د.ك'),
  ];

  static const _ratesUri = 'https://open.er-api.com/v6/latest/PKR';
  static const _refreshInterval = Duration(hours: 24);

  final ValueNotifier<int> changes = ValueNotifier<int>(0);
  final Map<String, double> _rates = {'PKR': 1};
  final http.Client _client = http.Client();

  String _selectedCode = 'PKR';
  DateTime? _lastUpdated;
  String? _lastRefreshError;

  String get selectedCode => _selectedCode;
  CurrencyOption get selectedCurrency =>
      currencies.firstWhere((currency) => currency.code == _selectedCode);
  DateTime? get lastUpdated => _lastUpdated;
  String? get lastRefreshError => _lastRefreshError;

  Future<bool> initialize(String code) async {
    if (!currencies.any((currency) => currency.code == code)) {
      throw StateError('Unsupported saved currency: $code');
    }

    _lastRefreshError = null;
    _selectedCode = code;
    await _loadCachedRates();

    if (code == 'PKR') {
      changes.value++;
      return true;
    }

    if (!_hasFreshRates || !_rates.containsKey(code)) {
      try {
        await _refreshRates();
      } on Exception catch (error) {
        _lastRefreshError = error.toString();
        if (!_rates.containsKey(code)) {
          throw StateError(
            'Could not load $code exchange rates. Check your internet connection.',
          );
        }
        changes.value++;
        return false;
      }
    }

    changes.value++;
    return true;
  }

  Future<void> selectCurrency(String code, {required int userId}) async {
    if (!currencies.any((currency) => currency.code == code)) {
      throw ArgumentError.value(code, 'code', 'Unsupported currency');
    }

    if (code != 'PKR' && (!_hasFreshRates || !_rates.containsKey(code))) {
      await _refreshRates();
    }
    if (!_rates.containsKey(code)) {
      throw StateError('No exchange rate is available for $code');
    }

    final db = await DatabaseHelper.instance.database;
    final updated = await db.update(
      'users',
      {'currency_code': code},
      where: 'id = ?',
      whereArgs: [userId],
    );
    if (updated != 1) {
      throw StateError('Could not save currency preference');
    }

    _selectedCode = code;
    _lastRefreshError = null;
    changes.value++;
  }

  double convertFromBase(double amount) {
    final rate = _rates[_selectedCode];
    if (rate == null) {
      throw StateError('Exchange rate for $_selectedCode is not available');
    }
    return amount * rate;
  }

  double convertToBase(double amount) {
    final rate = _rates[_selectedCode];
    if (rate == null) {
      throw StateError('Exchange rate for $_selectedCode is not available');
    }
    return double.parse((amount / rate).toStringAsFixed(2));
  }

  String format(double baseAmount) {
    final currency = selectedCurrency;
    final amount = convertFromBase(baseAmount);
    final sign = amount < 0 ? '-' : '';
    final digits = amount.abs().toStringAsFixed(currency.decimalDigits);
    final parts = digits.split('.');
    final grouped = parts.first.replaceAllMapped(
      RegExp(r'\B(?=(\d{3})+(?!\d))'),
      (_) => ',',
    );
    final fraction = parts.length > 1 ? '.${parts[1]}' : '';
    final symbolSpace =
        const {'PKR', 'AED', 'SAR', 'CHF', 'QAR', 'KWD'}.contains(currency.code)
        ? ' '
        : '';
    return '$sign${currency.symbol}$symbolSpace$grouped$fraction';
  }

  bool get _hasFreshRates =>
      _lastUpdated != null &&
      DateTime.now().difference(_lastUpdated!) < _refreshInterval;

  Future<void> _loadCachedRates() async {
    final db = await DatabaseHelper.instance.database;
    final rows = await db.query('exchange_rates');
    _rates
      ..clear()
      ..addAll({'PKR': 1});
    _lastUpdated = null;

    for (final row in rows) {
      final code = row['code'] as String;
      final rate = (row['rate'] as num).toDouble();
      if (rate <= 0) continue;
      _rates[code] = rate;
      _lastUpdated ??= DateTime.parse(row['fetched_at'] as String);
    }
  }

  Future<void> _refreshRates() async {
    final response = await _client
        .get(Uri.parse(_ratesUri))
        .timeout(const Duration(seconds: 12));
    if (response.statusCode != 200) {
      throw Exception('Exchange-rate service returned ${response.statusCode}');
    }

    final payload = jsonDecode(response.body);
    if (payload is! Map<String, dynamic> ||
        payload['result'] != 'success' ||
        payload['base_code'] != 'PKR' ||
        payload['rates'] is! Map<String, dynamic>) {
      throw const FormatException('Invalid exchange-rate response');
    }

    final rates = <String, double>{'PKR': 1};
    (payload['rates'] as Map<String, dynamic>).forEach((code, value) {
      if (value is num && value > 0) rates[code] = value.toDouble();
    });
    for (final currency in currencies) {
      if (!rates.containsKey(currency.code)) {
        throw FormatException('Rate missing for ${currency.code}');
      }
    }

    final timestamp = payload['time_last_update_unix'];
    final fetchedAt = timestamp is num
        ? DateTime.fromMillisecondsSinceEpoch(
            timestamp.toInt() * 1000,
            isUtc: true,
          ).toLocal()
        : DateTime.now();

    final db = await DatabaseHelper.instance.database;
    await db.transaction((txn) async {
      for (final entry in rates.entries) {
        await txn.insert('exchange_rates', {
          'code': entry.key,
          'rate': entry.value,
          'fetched_at': fetchedAt.toIso8601String(),
        }, conflictAlgorithm: ConflictAlgorithm.replace);
      }
    });

    _rates
      ..clear()
      ..addAll(rates);
    _lastUpdated = fetchedAt;
    _lastRefreshError = null;
  }
}
