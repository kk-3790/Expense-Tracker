import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';

import '../screens/ai_chat_screen.dart';
import 'goal_service.dart';
import 'settings_service.dart';
import 'transaction_service.dart';

class GeminiService {
  // Ordered by speed and responsiveness: flash-lite models generate in ~1s
  static const List<String> _candidateModels = [
    'gemini-3.5-flash-lite',
    'gemini-flash-lite-latest',
    'gemini-3.5-flash',
    'gemini-flash-latest',
    'gemini-3.8-flash',
  ];

  /// Sends a prompt to Gemini with the user's live financial context.
  /// Automatically tries candidate models with fast fallback to the local intelligence engine.
  static Future<String> askGemini(String userPrompt) async {
    final apiKey = SettingsService.geminiApiKey.value.trim();

    if (apiKey.isEmpty) {
      debugPrint('[GeminiService] No API key set, using local engine fallback.');
      return AiChatScreen.generateBotReply(userPrompt);
    }

    final contextPrompt = _buildFinancialContext();
    final payload = {
      'systemInstruction': {
        'parts': [
          {'text': contextPrompt}
        ]
      },
      'contents': [
        {
          'role': 'user',
          'parts': [
            {'text': userPrompt}
          ]
        }
      ],
      'generationConfig': {
        'temperature': 0.7,
        'maxOutputTokens': 600,
      },
    };

    final client = HttpClient();
    client.connectionTimeout = const Duration(seconds: 10);

    for (final model in _candidateModels) {
      try {
        final url = Uri.parse(
          'https://generativelanguage.googleapis.com/v1beta/models/$model:generateContent?key=$apiKey',
        );

        final request = await client.postUrl(url).timeout(const Duration(seconds: 10));
        request.headers.contentType = ContentType.json;
        request.write(jsonEncode(payload));

        final response = await request.close().timeout(const Duration(seconds: 15));
        final responseBody = await response.transform(utf8.decoder).join().timeout(const Duration(seconds: 10));

        if (response.statusCode == 200) {
          final data = jsonDecode(responseBody);
          final candidates = data['candidates'] as List?;
          if (candidates != null && candidates.isNotEmpty) {
            final content = candidates.first['content'] as Map?;
            final parts = content?['parts'] as List?;
            if (parts != null && parts.isNotEmpty) {
              final replyText = parts.first['text'] as String?;
              if (replyText != null && replyText.trim().isNotEmpty) {
                client.close();
                return replyText.trim();
              }
            }
          }
        } else if (response.statusCode == 503 || response.statusCode == 429) {
          debugPrint(
              '[GeminiService] Model $model high demand (${response.statusCode}), trying next model...');
          continue;
        } else {
          debugPrint(
              '[GeminiService] HTTP ${response.statusCode} on $model: $responseBody');
        }
      } catch (e) {
        debugPrint('[GeminiService] Error calling $model: $e');
      }
    }

    client.close();

    // Seamless fallback to local financial intelligence engine
    debugPrint('[GeminiService] Using local financial intelligence engine fallback.');
    return AiChatScreen.generateBotReply(userPrompt);
  }

  static String _buildFinancialContext() {
    final balance = TransactionService.balance;
    final totalIncome = TransactionService.totalIncome;
    final totalExpense = TransactionService.totalExpense;
    final currency = SettingsService.currency.value;
    final budget = SettingsService.monthlyBudget.value;
    final goals = GoalService.goals.value;
    final transactions = TransactionService.transactions.value;
    final now = DateTime.now();

    final todayExpenses = transactions
        .where((t) =>
            t.isExpense &&
            t.date.toLocal().year == now.year &&
            t.date.toLocal().month == now.month &&
            t.date.toLocal().day == now.day)
        .fold(0.0, (s, t) => s + t.amount);

    final categoryTotals = TransactionService.categoryTotals();

    final goalsSummary = goals.isEmpty
        ? 'None'
        : goals
            .map((g) =>
                '${g.name} (${g.category}): saved $currency${g.currentAmount.toStringAsFixed(0)} / $currency${g.targetAmount.toStringAsFixed(0)} (${(g.progressPercentage * 100).toStringAsFixed(0)}% reached, $currency${g.remainingAmount.toStringAsFixed(0)} remaining)')
            .join('; ');

    final topCategories = categoryTotals.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final categoriesSummary = topCategories.isEmpty
        ? 'None'
        : topCategories
            .take(6)
            .map((e) => '${e.key}: $currency${e.value.toStringAsFixed(0)}')
            .join(', ');

    final recentTransactions = transactions.take(5).map((t) {
      final sign = t.isExpense ? '-' : '+';
      return '${t.title} ($sign$currency${t.amount.toStringAsFixed(0)}, ${t.category}, ${t.date.toLocal().day}/${t.date.toLocal().month})';
    }).join('; ');

    return '''
You are Paisa AI, an expert, encouraging, and friendly personal financial advisor built into the Paisa Expense Tracker app.
You provide intelligent, actionable, concise, and personalized money advice based on the user's real-time financial snapshot.

USER REAL-TIME FINANCIAL SNAPSHOT:
• Available Balance: $currency${balance.toStringAsFixed(0)}
• Total Tracked Income: $currency${totalIncome.toStringAsFixed(0)}
• Total Tracked Expenses: $currency${totalExpense.toStringAsFixed(0)}
• Monthly Budget Limit: ${budget > 0 ? '$currency${budget.toStringAsFixed(0)}' : 'Not set'}
• Spent Today: $currency${todayExpenses.toStringAsFixed(0)}
• Top Spending Categories: $categoriesSummary
• Active Savings Goals: $goalsSummary
• Recent Transactions: $recentTransactions

GUIDELINES:
1. Always reference the user's actual numbers (balance, goals, spending) when relevant.
2. Keep responses concise, clear, and engaging (usually 60–120 words). Use bullet points and emojis to make advice easy to read on mobile.
3. If the user asks whether they can afford something, evaluate it against their balance, upcoming expenses, and safety cushion.
4. If the user asks for savings tips, target their highest spending category.
5. If the user asks about the 50/30/20 rule, calculate the exact figures based on their income/balance.
6. Maintain a helpful, supportive, and privacy-conscious financial coaching tone.
''';
  }

  /// Fetches personalized actionable insights using Google Gemini API based on real financial context,
  /// with immediate smart fallback to local financial intelligence engine so it never hangs.
  static Future<List<String>> fetchDynamicInsights() async {
    final currency = SettingsService.currency.value;
    final topCats = TransactionService.categoryTotals().entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final goals = GoalService.goals.value;
    final balance = TransactionService.balance;

    final smartLocalInsights = <String>[
      if (topCats.isNotEmpty)
        'Your top spending is in ${topCats.first.key} ($currency${topCats.first.value.toStringAsFixed(0)}). Cutting 15% here could save you $currency${(topCats.first.value * 0.15).toStringAsFixed(0)} this month.',
      if (goals.isNotEmpty)
        'You have saved $currency${goals.first.currentAmount.toStringAsFixed(0)} toward "${goals.first.name}" (${(goals.first.progressPercentage * 100).toInt()}%). Consistent deposits will reach target ahead of time!',
      if (balance > 30000)
        'Healthy account balance of $currency${balance.toStringAsFixed(0)}! Consider moving a portion into automated savings or short-term investments.'
      else
        'Aim to build an emergency fund equal to 3 months of basic living expenses to protect your financial cushion.',
      'Tracking payment methods (UPI/Card/Cash) helps identify discretionary cash leaks before they impact your goals.',
    ];

    try {
      const prompt = 'Give me exactly 3 highly personalized, practical financial insights and recommendations based on my real spending, budget, and savings goals. Format each insight as a single concise sentence starting with a bullet (•). Do not include any intro, greeting, or numbering.';
      final response = await askGemini(prompt).timeout(
        const Duration(seconds: 4),
        onTimeout: () => '',
      );

      if (response.isNotEmpty) {
        final rawLines = response.split('\n');
        final insights = <String>[];
        for (final line in rawLines) {
          final trimmed = line.trim();
          if (trimmed.isEmpty) continue;
          final cleaned = trimmed.replaceFirst(RegExp(r'^[•\-\*\d\.\)]+\s*'), '').trim();
          if (cleaned.length > 15) {
            insights.add(cleaned);
          }
        }
        if (insights.isNotEmpty) {
          return insights.take(4).toList();
        }
      }
    } catch (e) {
      debugPrint('[GeminiService] Error fetching dynamic insights: $e');
    }

    return smartLocalInsights.take(3).toList();
  }
}
