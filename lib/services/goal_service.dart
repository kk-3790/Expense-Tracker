import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class GoalModel {
  final String id;
  final String name;
  final double targetAmount;
  final double currentAmount;
  final DateTime targetDate;
  final String category;

  const GoalModel({
    required this.id,
    required this.name,
    required this.targetAmount,
    required this.currentAmount,
    required this.targetDate,
    required this.category,
  });

  double get progressPercentage {
    if (targetAmount <= 0) return 0;
    return (currentAmount / targetAmount).clamp(0.0, 1.0);
  }

  double get remainingAmount {
    final rem = targetAmount - currentAmount;
    return rem > 0 ? rem : 0.0;
  }

  int get percentageInt => (progressPercentage * 100).toInt();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'targetAmount': targetAmount,
      'currentAmount': currentAmount,
      'targetDate': targetDate.toIso8601String(),
      'category': category,
    };
  }

  factory GoalModel.fromMap(Map<String, dynamic> map) {
    final parsed = DateTime.tryParse(map['targetDate']?.toString() ?? '');
    return GoalModel(
      id: map['id']?.toString() ?? '',
      name: map['name']?.toString() ?? '',
      targetAmount: (map['targetAmount'] as num?)?.toDouble() ?? 0.0,
      currentAmount: (map['currentAmount'] as num?)?.toDouble() ?? 0.0,
      targetDate: parsed != null ? parsed.toLocal() : DateTime.now(),
      category: map['category']?.toString() ?? 'Savings',
    );
  }
}

class GoalService {
  static String? _currentUserId;

  static String get _storageKey {
    if (_currentUserId == null || _currentUserId!.isEmpty) {
      return 'paisa_goals_data';
    }
    return 'paisa_goals_data_$_currentUserId';
  }

  static late SharedPreferences _prefs;

  static List<GoalModel> _initialDefaultGoals() {
    final now = DateTime.now();
    return [
      GoalModel(
        id: '1',
        name: 'New Bicycle',
        targetAmount: 25000,
        currentAmount: 5000,
        targetDate: now.add(const Duration(days: 45)),
        category: 'Transportation',
      ),
      GoalModel(
        id: '2',
        name: 'Vacation Fund',
        targetAmount: 50000,
        currentAmount: 26500,
        targetDate: now.add(const Duration(days: 110)),
        category: 'Savings',
      ),
    ];
  }

  static final ValueNotifier<List<GoalModel>> goals =
      ValueNotifier<List<GoalModel>>(_initialDefaultGoals());

  static Future<void> init({String? userId}) async {
    _prefs = await SharedPreferences.getInstance();
    await switchUser(userId ?? _currentUserId);
  }

  /// Switch the active user session and load their specific goals
  static Future<void> switchUser(String? userId) async {
    _currentUserId = userId;
    final key = _storageKey;

    final data = _prefs.getString(key);
    if (data != null && data.isNotEmpty) {
      try {
        final decoded = jsonDecode(data) as List;
        final list = decoded
            .map((e) => GoalModel.fromMap(Map<String, dynamic>.from(e)))
            .toList();
        if (list.isNotEmpty) {
          goals.value = list;
          return;
        }
      } catch (e) {
        debugPrint('Error loading goals: $e');
      }
    }

    // Check if legacy data can be migrated to this initial user
    final legacy = _prefs.getString('paisa_goals_data');
    final migratedTo = _prefs.getString('paisa_goals_migrated_to');
    if (legacy != null && legacy.isNotEmpty && (migratedTo == null || migratedTo == userId)) {
      try {
        final decoded = jsonDecode(legacy) as List;
        final list = decoded
            .map((e) => GoalModel.fromMap(Map<String, dynamic>.from(e)))
            .toList();
        if (list.isNotEmpty) {
          await _prefs.setString(key, legacy);
          await _prefs.setString('paisa_goals_migrated_to', userId ?? 'migrated');
          goals.value = list;
          return;
        }
      } catch (_) {}
    }

    // If no saved goals, initialize with default seeds and persist
    goals.value = _initialDefaultGoals();
    await _save();
  }

  static Future<void> addGoal(GoalModel goal) async {
    final updated = [...goals.value, goal];
    goals.value = updated;
    await _save();
  }

  static Future<void> updateGoal(GoalModel updatedGoal) async {
    final updated = goals.value.map((g) {
      return g.id == updatedGoal.id ? updatedGoal : g;
    }).toList();
    goals.value = updated;
    await _save();
  }

  static Future<void> deleteGoal(String id) async {
    final updated = goals.value.where((g) => g.id != id).toList();
    goals.value = updated;
    await _save();
  }

  static Future<void> updateGoalProgress(String id, double addedAmount) async {
    final updated = goals.value.map((g) {
      if (g.id == id) {
        return GoalModel(
          id: g.id,
          name: g.name,
          targetAmount: g.targetAmount,
          currentAmount:
              (g.currentAmount + addedAmount).clamp(0.0, g.targetAmount),
          targetDate: g.targetDate,
          category: g.category,
        );
      }
      return g;
    }).toList();
    goals.value = updated;
    await _save();
  }

  static Future<void> _save() async {
    final list = goals.value.map((g) => g.toMap()).toList();
    await _prefs.setString(_storageKey, jsonEncode(list));
  }
}
