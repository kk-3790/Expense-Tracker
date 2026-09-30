import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/transaction_model.dart';

class TransactionService {
  static String? _currentUserId;

  static String get _storageKey {
    if (_currentUserId == null || _currentUserId!.isEmpty) {
      return 'expense_tracker_transactions';
    }
    return 'expense_tracker_transactions_$_currentUserId';
  }

  static late SharedPreferences _prefs;

  static final ValueNotifier<List<TransactionModel>>
  transactions =
  ValueNotifier<List<TransactionModel>>([]);

  static double _cachedTotalIncome = 0.0;
  static double _cachedTotalExpense = 0.0;
  static double _cachedBalance = 0.0;

  static void _recalculateTotals() {
    double inc = 0.0;
    double exp = 0.0;
    for (final item in transactions.value) {
      if (item.isIncome) {
        inc += item.amount.abs();
      } else if (item.isExpense) {
        exp += item.amount.abs();
      }
    }
    _cachedTotalIncome = inc;
    _cachedTotalExpense = exp;
    _cachedBalance = inc - exp;
  }

  static Future<void> init({String? userId}) async {
    _prefs = await SharedPreferences.getInstance();
    await switchUser(userId ?? _currentUserId);
  }

  /// Switch the active user session and load their specific transactions
  static Future<void> switchUser(String? userId) async {
    _currentUserId = userId;
    final key = _storageKey;

    final saved = _prefs.getString(key);

    if (saved == null || saved.isEmpty) {
      // Check for legacy data migration for the initial account
      final legacy = _prefs.getString('expense_tracker_transactions');
      final migratedTo = _prefs.getString('expense_tracker_migrated_to');
      if (legacy != null && legacy.isNotEmpty && (migratedTo == null || migratedTo == userId)) {
        await _prefs.setString(key, legacy);
        await _prefs.setString('expense_tracker_migrated_to', userId ?? 'migrated');
        await switchUser(userId);
        return;
      }

      final now = DateTime.now();
      final defaultSeed = (_currentUserId == null || _currentUserId == 'offline' || _currentUserId == 'guest')
          ? [
              TransactionModel(
                id: 'seed-income-1',
                title: 'Monthly Salary',
                note: 'Direct Deposit',
                date: now.subtract(const Duration(days: 3)),
                amount: 80000,
                category: 'Other',
                type: 'Income',
              ),
              TransactionModel(
                id: 'seed-spotify',
                title: 'Spotify Premium (Duo)',
                note: 'Monthly Subscription',
                date: DateTime(now.year, now.month, now.day, 15, 30),
                amount: 179,
                category: 'Entertainment',
                type: 'Expense',
              ),
              TransactionModel(
                id: 'seed-amazon',
                title: 'Amazon',
                note: 'Household essentials',
                date: DateTime(now.year, now.month, now.day, 11, 44),
                amount: 1248,
                category: 'Shopping',
                type: 'Expense',
              ),
              TransactionModel(
                id: 'seed-groceries',
                title: 'Whole Foods Groceries',
                note: 'Weekly essentials',
                date: now.subtract(const Duration(days: 2)),
                amount: 1800,
                category: 'Groceries',
                type: 'Expense',
              ),
              TransactionModel(
                id: 'seed-metro',
                title: 'Metro Monthly Pass',
                note: 'Public Transit',
                date: now.subtract(const Duration(days: 4)),
                amount: 1500,
                category: 'Transportation',
                type: 'Expense',
              ),
              TransactionModel(
                id: 'seed-utilities',
                title: 'Electricity & Water',
                note: 'Utility bill',
                date: now.subtract(const Duration(days: 5)),
                amount: 1200,
                category: 'Utilities',
                type: 'Expense',
              ),
            ]
          : [
              TransactionModel(
                id: 'seed-income-$_currentUserId',
                title: 'Opening Balance',
                note: 'Account Initialized',
                date: now.subtract(const Duration(days: 1)),
                amount: 50000,
                category: 'Other',
                type: 'Income',
              ),
            ];
      _sort(defaultSeed);
      transactions.value = defaultSeed;
      _recalculateTotals();
      await _save();
      return;
    }

    try {
      final decoded = jsonDecode(saved);

      if (decoded is! List) {
        transactions.value = [];
        _recalculateTotals();
        return;
      }

      final loaded = <TransactionModel>[];

      for (final item in decoded) {
        if (item is Map) {
          loaded.add(
            TransactionModel.fromMap(
              Map<String, dynamic>.from(item),
            ),
          );
        }
      }

      _sort(loaded);

      transactions.value = loaded;
    } catch (_) {
      transactions.value = [];
    } finally {
      _recalculateTotals();
    }
  }

  // ============================================================
  // ADD
  // ============================================================

  static Future<void> add(
      TransactionModel transaction,
      ) async {
    final updated = [
      ...transactions.value,
      transaction,
    ];

    _sort(updated);

    transactions.value = List.unmodifiable(updated);
    _recalculateTotals();

    await _save();
  }

  // ============================================================
  // UPDATE
  // ============================================================

  static Future<void> update(
      TransactionModel transaction,
      ) async {
    final updated = transactions.value.map((item) {
      return item.id == transaction.id
          ? transaction
          : item;
    }).toList();

    _sort(updated);

    transactions.value = List.unmodifiable(updated);
    _recalculateTotals();

    await _save();
  }

  // ============================================================
  // DELETE
  // ============================================================

  static Future<void> delete(String id) async {
    final updated = transactions.value
        .where((item) => item.id != id)
        .toList();

    transactions.value = List.unmodifiable(updated);
    _recalculateTotals();

    await _save();
  }

  // ============================================================
  // CLEAR ALL
  // ============================================================

  static Future<void> clearAll() async {
    transactions.value = [];
    _recalculateTotals();

    await _prefs.remove(_storageKey);
  }

  // ============================================================
  // REPLACE ALL
  // ============================================================

  static Future<void> replaceAll(
      List<TransactionModel> items,
      ) async {
    final updated = [...items];

    _sort(updated);

    transactions.value = List.unmodifiable(updated);
    _recalculateTotals();

    await _save();
  }

  // ============================================================
  // TOTAL INCOME
  // ============================================================

  static double get totalIncome => _cachedTotalIncome;

  // ============================================================
  // TOTAL EXPENSE
  // ============================================================

  static double get totalExpense => _cachedTotalExpense;

  // ============================================================
  // BALANCE
  // ============================================================

  static double get balance => _cachedBalance;

  // ============================================================
  // MONTHLY TRANSACTIONS
  // ============================================================

  static List<TransactionModel> forMonth(
      int year,
      int month,
      ) {
    return transactions.value.where((item) {
      return item.date.year == year &&
          item.date.month == month;
    }).toList();
  }

  // ============================================================
  // MONTHLY INCOME
  // ============================================================

  static double monthlyIncome(
      int year,
      int month,
      ) {
    return forMonth(year, month)
        .where((item) => item.isIncome)
        .fold(
      0.0,
          (sum, item) => sum + item.amount.abs(),
    );
  }

  // ============================================================
  // MONTHLY EXPENSE
  // ============================================================

  static double monthlyExpense(
      int year,
      int month,
      ) {
    return forMonth(year, month)
        .where((item) => item.isExpense)
        .fold(
      0.0,
          (sum, item) => sum + item.amount.abs(),
    );
  }

  // ============================================================
  // CATEGORY EXPENSE
  // ============================================================

  static double categoryExpense(
      String category, {
        int? year,
        int? month,
      }) {
    final source = year != null && month != null
        ? forMonth(year, month)
        : transactions.value;

    return source
        .where(
          (item) =>
      item.isExpense &&
          item.category == category,
    )
        .fold(
      0.0,
          (sum, item) => sum + item.amount.abs(),
    );
  }

  // ============================================================
  // CATEGORY TOTALS
  // ============================================================

  static Map<String, double> categoryTotals({
    int? year,
    int? month,
  }) {
    final source = year != null && month != null
        ? forMonth(year, month)
        : transactions.value;

    final totals = <String, double>{};

    for (final item in source) {
      if (!item.isExpense) continue;

      totals[item.category] =
          (totals[item.category] ?? 0) +
              item.amount.abs();
    }

    return totals;
  }

  // ============================================================
  // SAVE
  // ============================================================

  static Future<void> _save() async {
    final data = transactions.value
        .map((item) => item.toMap())
        .toList();

    await _prefs.setString(
      _storageKey,
      jsonEncode(data),
    );
  }

  static void _sort(
      List<TransactionModel> items,
      ) {
    items.sort(
          (a, b) => b.date.compareTo(a.date),
    );
  }
}