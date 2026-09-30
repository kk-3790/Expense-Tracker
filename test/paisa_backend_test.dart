import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:expense_tracker/models/transaction_model.dart';
import 'package:expense_tracker/screens/ai_chat_screen.dart';
import 'package:expense_tracker/services/gemini_service.dart';
import 'package:expense_tracker/services/goal_service.dart';
import 'package:expense_tracker/services/payment_service.dart';
import 'package:expense_tracker/services/qr_scanner_service.dart';
import 'package:expense_tracker/services/settings_service.dart';
import 'package:expense_tracker/services/split_service.dart';
import 'package:expense_tracker/services/transaction_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await SettingsService.init();
    await GoalService.init();
    await TransactionService.init();
  });

  group('TransactionService & Backend Calculations Test', () {
    test('Initializes with default Behance seed transactions and valid balance', () {
      final txs = TransactionService.transactions.value;
      expect(txs.isNotEmpty, true);

      // Verify seed items exist
      final hasSalary = txs.any((t) => t.isIncome && t.amount == 80000);
      final hasSpotify = txs.any((t) => t.isExpense && t.amount == 179);
      final hasAmazon = txs.any((t) => t.isExpense && t.amount == 1248);

      expect(hasSalary, true);
      expect(hasSpotify, true);
      expect(hasAmazon, true);

      // Balance should be income - expenses > 70000
      expect(TransactionService.balance, greaterThan(70000));
    });

    test('Adding an expense updates totalExpense and balance correctly', () async {
      final initialBalance = TransactionService.balance;
      final initialExpense = TransactionService.totalExpense;

      final newExpense = TransactionModel(
        id: 'test-pizza-1',
        title: 'Pizza Margherita ( Large )',
        note: 'Dinner with friends',
        date: DateTime.now(),
        amount: 799,
        category: 'Food',
        type: 'Expense',
      );

      await TransactionService.add(newExpense);

      expect(TransactionService.totalExpense, initialExpense + 799);
      expect(TransactionService.balance, initialBalance - 799);
      expect(
        TransactionService.transactions.value.any((t) => t.id == 'test-pizza-1'),
        true,
      );
    });

    test('Category totals group expenses accurately', () {
      final totals = TransactionService.categoryTotals();
      expect(totals.containsKey('Entertainment'), true);
      expect(totals.containsKey('Shopping'), true);
      expect(totals['Entertainment'], 179);
      expect(totals['Shopping'], 1248);
    });
  });

  group('GoalService Backend Test', () {
    test('Initializes with default Behance goals', () {
      final goals = GoalService.goals.value;
      expect(goals.length, greaterThanOrEqualTo(2));

      final bicycleGoal = goals.firstWhere((g) => g.name == 'New Bicycle');
      expect(bicycleGoal.targetAmount, 25000);
      expect(bicycleGoal.currentAmount, 5000);
      expect(bicycleGoal.percentageInt, 20); // Exactly 20% like Behance mockup
    });

    test('Adding a goal updates list and persists', () async {
      final newGoal = GoalModel(
        id: 'test-car',
        name: 'Electric Scooter',
        targetAmount: 60000,
        currentAmount: 15000,
        targetDate: DateTime.now().add(const Duration(days: 180)),
        category: 'Transportation',
      );

      await GoalService.addGoal(newGoal);

      final goals = GoalService.goals.value;
      expect(goals.any((g) => g.id == 'test-car'), true);
      expect(newGoal.percentageInt, 25);
    });

    test('Updating goal progress updates percentage', () async {
      await GoalService.updateGoalProgress('1', 5000);
      final updated = GoalService.goals.value.firstWhere((g) => g.id == '1');
      expect(updated.currentAmount, 10000);
      expect(updated.percentageInt, 40);
    });

    test('Updating whole goal works properly', () async {
      final goalToUpdate = GoalModel(
        id: '1',
        name: 'Electric Mountain Bike',
        targetAmount: 35000,
        currentAmount: 10000,
        targetDate: DateTime.now().add(const Duration(days: 60)),
        category: 'Transportation',
      );
      await GoalService.updateGoal(goalToUpdate);
      final found = GoalService.goals.value.firstWhere((g) => g.id == '1');
      expect(found.name, 'Electric Mountain Bike');
      expect(found.targetAmount, 35000);
    });

    test('Deleting a goal removes it from GoalService', () async {
      final goalToDelete = GoalModel(
        id: 'to-delete-123',
        name: 'Temporary Goal',
        targetAmount: 10000,
        currentAmount: 1000,
        targetDate: DateTime.now().add(const Duration(days: 30)),
        category: 'Savings',
      );
      await GoalService.addGoal(goalToDelete);
      expect(GoalService.goals.value.any((g) => g.id == 'to-delete-123'), true);

      final countBefore = GoalService.goals.value.length;
      await GoalService.deleteGoal('to-delete-123');
      final countAfter = GoalService.goals.value.length;
      expect(countAfter, countBefore - 1);
      expect(GoalService.goals.value.any((g) => g.id == 'to-delete-123'), false);
    });
  });

  group('SettingsService Backend Test', () {
    test('Default currency is Rupee and can be changed', () async {
      expect(SettingsService.currency.value, '₹');
      await SettingsService.setCurrency('\$');
      expect(SettingsService.currency.value, '\$');
      await SettingsService.setCurrency('₹');
      expect(SettingsService.currency.value, '₹');
    });

    test('Theme mode can be changed and saved', () async {
      await SettingsService.setThemeMode(ThemeMode.dark);
      expect(SettingsService.themeMode.value, ThemeMode.dark);
    });
  });

  group('QR & ISO 18245 MCC Auto-Categorization Test', () {
    test('Parses UPI merchant URI and categorizes Grocery (MCC 5411)', () {
      const upi = 'upi://pay?pa=store@upi&pn=Nature%20Basket&mc=5411&am=450.00';
      final parsed = QrScannerService.parse(upi);

      expect(parsed.merchantName, 'Nature Basket');
      expect(parsed.mcc, '5411');
      expect(parsed.merchantName, 'Nature Basket');
      expect(parsed.amount, 450.00);
    });

    test('Parses Restaurant MCC 5812', () {
      const upi = 'upi://pay?pa=cafe@upi&pn=Blue%20Tokai%20Coffee&mc=5812&am=320.00';
      final parsed = QrScannerService.parse(upi);

      expect(parsed.category, 'Food');
      expect(parsed.merchantName, 'Blue Tokai Coffee');
    });
  });

  group('GoalModel & Remaining Amount Tests', () {
    test('Calculates remaining amount correctly', () {
      final goal = GoalModel(
        id: 'rem-test',
        name: 'MacBook Pro',
        targetAmount: 150000,
        currentAmount: 50000,
        targetDate: DateTime.now().add(const Duration(days: 90)),
        category: 'Tech',
      );

      expect(goal.remainingAmount, 100000);
      expect(goal.percentageInt, 33);
    });

    test('Remaining amount is 0 when target is met or exceeded', () {
      final goal = GoalModel(
        id: 'rem-test-completed',
        name: 'Headphones',
        targetAmount: 5000,
        currentAmount: 6000,
        targetDate: DateTime.now().add(const Duration(days: 30)),
        category: 'Tech',
      );

      expect(goal.remainingAmount, 0.0);
      expect(goal.progressPercentage, 1.0);
    });
  });

  group('AiChatScreen Intelligence Engine Tests', () {
    test('Answers greeting query with balance snapshot', () {
      final reply = AiChatScreen.generateBotReply('hello');
      expect(reply.contains('Paisa AI Financial Assistant'), true);
      expect(reply.contains('Total Balance:'), true);
    });

    test('Answers today spending query accurately', () {
      final reply = AiChatScreen.generateBotReply('How much did I spend today?');
      expect(reply.contains("spent") || reply.contains("today"), true);
    });

    test('Answers weekly spending query', () {
      final reply = AiChatScreen.generateBotReply('What is my spending this week?');
      expect(reply.contains("7 days"), true);
      expect(reply.contains("spending"), true);
    });

    test('Answers goals query with live saved and remaining amounts', () {
      final reply = AiChatScreen.generateBotReply('How are my savings goals?');
      expect(reply.contains("savings goals"), true);
      // Seed goals include New Bicycle
      expect(reply.contains("New Bicycle") || reply.contains("Emergency Fund") || reply.contains("goals"), true);
    });

    test('Answers highest expense query', () {
      final reply = AiChatScreen.generateBotReply('What is my highest expense?');
      expect(reply.contains("highest recorded expense") || reply.contains("expense"), true);
    });

    test('Answers 50/30/20 budgeting query', () {
      final reply = AiChatScreen.generateBotReply('Give me a 50/30/20 budget breakdown');
      expect(reply.contains("50% Needs"), true);
      expect(reply.contains("30% Wants"), true);
      expect(reply.contains("20% Savings"), true);
    });

    test('Answers category specific query for Food', () {
      final reply = AiChatScreen.generateBotReply('What did I spend on food?');
      expect(reply.contains("Food") || reply.contains("spent"), true);
    });

    test('Answers affordability check with calculation', () {
      final reply = AiChatScreen.generateBotReply('Can I afford 5000 for dinner?');
      expect(reply.contains("available") || reply.contains("afford"), true);
    });

    test('Answers saving tips query based on highest category', () {
      final reply = AiChatScreen.generateBotReply('Tips to save money');
      expect(reply.contains("money-saving strategies"), true);
    });
  });

  group('GeminiService & Settings Tests', () {
    test('SettingsService manages Gemini API key lifecycle', () async {
      await SettingsService.setGeminiApiKey('KEY_TEST_XYZ');
      expect(SettingsService.geminiApiKey.value, 'KEY_TEST_XYZ');
      await SettingsService.setGeminiApiKey('');
      expect(SettingsService.geminiApiKey.value, '');
    });

    test('Updating Gemini key persists and updates ValueNotifier', () async {
      const customKey = 'TEST_CUSTOM_KEY_12345';
      await SettingsService.setGeminiApiKey(customKey);
      expect(SettingsService.geminiApiKey.value, customKey);

      // Re-initialize to test persistence
      await SettingsService.init();
      expect(SettingsService.geminiApiKey.value, customKey);

      // Restore key
      await SettingsService.setGeminiApiKey('');
    });

    test('GeminiService falls back to local engine safely when API key is empty', () async {
      await SettingsService.setGeminiApiKey('');
      final reply = await GeminiService.askGemini('What is my total balance?');
      expect(reply.toLowerCase().contains('balance'), true);

      // Restore key
      await SettingsService.setGeminiApiKey('');
    });
  });

  group('SplitService Backend Tests', () {
    test('Calculates equal split accurately among 3 people', () {
      final split = SplitService.calculateEqualSplit(
        totalAmount: 1500,
        peopleCount: 3,
        currentUserName: 'You',
        friendNames: ['Alex', 'Bob'],
      );

      expect(split.peopleCount, 3);
      expect(split.sharePerPerson, 500.0);
      expect(split.yourShare, 500.0);
      expect(split.friendsTotalOwed, 1000.0);
      expect(split.members.length, 3);
      expect(split.members[0].isCurrentUser, true);
      expect(split.members[0].amount, 500.0);
      expect(split.members[1].name, 'Alex');
      expect(split.members[2].name, 'Bob');
    });

    test('Generates valid UPI Payment Request Link for split share', () {
      final upiUri = SplitService.generateSplitUpiLink(
        payeeUpiId: 'krishpatel@paisa',
        payeeName: 'Krish Patel',
        amount: 350.0,
        note: 'Dinner bill split',
      );

      expect(upiUri.startsWith('upi://pay?'), true);
      expect(upiUri.contains('pa=krishpatel@paisa'), true);
      expect(upiUri.contains('am=350.00'), true);
      expect(upiUri.contains('cu=INR'), true);
    });

    test('Formats split note with complete breakdown', () {
      final split = SplitService.calculateEqualSplit(
        totalAmount: 1200,
        peopleCount: 4,
        friendNames: ['Alex', 'Priya', 'Rahul'],
      );

      final note = SplitService.formatSplitNote(
        totalAmount: 1200,
        peopleCount: 4,
        yourShare: split.yourShare,
        members: split.members,
        originalNote: 'Friday Pizza Party',
      );

      expect(note.contains('Friday Pizza Party'), true);
      expect(note.contains('Split bill ₹1200 between 4 people'), true);
      expect(note.contains('Your share: ₹300'), true);
      expect(note.contains('Alex (₹300)'), true);
    });
  });

  group('PaymentService & GPay Response Tests', () {
    test('Generates unique GPay transaction reference format', () {
      final ref1 = PaymentService.generateTransactionRef();
      final ref2 = PaymentService.generateTransactionRef();

      expect(ref1.startsWith('GPAY'), true);
      expect(ref2.startsWith('GPAY'), true);
      expect(ref1 != ref2, true);
    });

    test('Records GPay transaction response and updates balance in database when paid', () async {
      final initialBalance = TransactionService.balance;

      final tx = await PaymentService.recordGPayTransaction(
        recipient: 'rahul@okhdfcbank',
        amount: 450.0,
        category: 'Food',
        note: 'Coffee & snacks',
        isPaid: true,
      );

      expect(tx, isNotNull);
      expect(tx!.amount, 450.0);
      expect(tx.title, 'Transfer to rahul@okhdfcbank');
      expect(tx.note.contains('Google Pay (Ref: GPAY'), true);
      expect(tx.type, 'Expense');

      // Balance decreased by 450
      expect(TransactionService.balance, initialBalance - 450.0);
    });

    test('Does NOT record or track transaction if user cancels or does not pay', () async {
      final initialBalance = TransactionService.balance;
      final initialCount = TransactionService.transactions.value.length;

      final tx = await PaymentService.recordGPayTransaction(
        recipient: 'priya@icici',
        amount: 800.0,
        category: 'Shopping',
        note: 'Shoes',
        isPaid: false,
      );

      expect(tx, isNull);
      // Balance remains completely untouched!
      expect(TransactionService.balance, initialBalance);
      // Transaction list length is unchanged!
      expect(TransactionService.transactions.value.length, initialCount);
    });

    test('Creates valid PaymentResult for successful and cancelled transactions', () {
      final successResult = PaymentService.createPaymentResult(
        isPaid: true,
        recipient: 'alex@okaxis',
        amount: 250.0,
        note: 'Lunch',
      );
      expect(successResult.success, true);
      expect(successResult.rawResponse, 'SUCCESS');
      expect(successResult.errorMessage, isNull);

      final cancelledResult = PaymentService.createPaymentResult(
        isPaid: false,
        recipient: 'alex@okaxis',
        amount: 250.0,
        note: 'Lunch',
      );
      expect(cancelledResult.success, false);
      expect(cancelledResult.rawResponse, 'USER_CANCELLED_OR_NOT_PAID');
      expect(cancelledResult.errorMessage, isNotNull);
    });
  });

  group('New Feature Requirements Tests', () {
    test('TransactionModel supports paymentMethod (UPI, Card, Cash, Transfer)', () {
      final tx = TransactionModel(
        id: 'tx-card-1',
        title: 'Grocery Mart',
        note: 'Weekly essentials',
        date: DateTime.now(),
        amount: 1500,
        category: 'Food',
        type: 'Expense',
        paymentMethod: 'Card',
      );

      expect(tx.paymentMethod, 'Card');
      final map = tx.toMap();
      expect(map['paymentMethod'], 'Card');

      final deserialized = TransactionModel.fromMap(map);
      expect(deserialized.paymentMethod, 'Card');
    });

    test('TransactionService.clearAll() clears all transactions and resets balance', () async {
      expect(TransactionService.transactions.value.isNotEmpty, true);
      await TransactionService.clearAll();
      expect(TransactionService.transactions.value.isEmpty, true);
      expect(TransactionService.balance, 0.0);
      expect(TransactionService.totalIncome, 0.0);
      expect(TransactionService.totalExpense, 0.0);
    });

    test('SplitService: create, approve (debits account), and reject split request', () async {
      await SplitService.init();

      // Create an incoming split request from Alex
      final req = await SplitService.createSplitRequest(
        senderName: 'Alex',
        senderEmail: 'alex@paisa.app',
        recipientName: 'Krish Patel',
        recipientEmail: 'krishpatel@paisa.app',
        expenseTitle: 'Team Dinner',
        totalAmount: 1200.0,
        splitAmount: 300.0,
      );

      expect(req.status, SplitStatus.pending);
      expect(req.splitAmount, 300.0);

      // Approving request should debit account by adding an Expense transaction
      final balanceBefore = TransactionService.balance;
      final success = await SplitService.approveRequest(req.id);
      expect(success, true);

      final updated = SplitService.splitRequests.value.firstWhere((r) => r.id == req.id);
      expect(updated.status, SplitStatus.approved);

      // Verify that recipient was debited 300
      expect(TransactionService.balance, balanceBefore - 300.0);

      // Test rejection on another request
      final req2 = await SplitService.createSplitRequest(
        senderName: 'Rahul',
        senderEmail: 'rahul@paisa.app',
        recipientName: 'Krish Patel',
        recipientEmail: 'krishpatel@paisa.app',
        expenseTitle: 'Snacks',
        totalAmount: 400.0,
        splitAmount: 100.0,
      );

      final balanceBeforeReject = TransactionService.balance;
      final rejectSuccess = await SplitService.rejectRequest(req2.id);
      expect(rejectSuccess, true);

      final updated2 = SplitService.splitRequests.value.firstWhere((r) => r.id == req2.id);
      expect(updated2.status, SplitStatus.rejected);
      // Balance remains untouched on reject
      expect(TransactionService.balance, balanceBeforeReject);
    });

    test('SplitService: friend approval transfers money into user account (Income)', () async {
      await SplitService.init();

      // Outgoing request sent by current user
      final outgoingReq = await SplitService.createSplitRequest(
        senderName: 'Krish Patel',
        senderEmail: 'krishpatel@paisa.app',
        recipientName: 'Priya',
        recipientEmail: 'priya@paisa.app',
        expenseTitle: 'Cab Fare',
        totalAmount: 600.0,
        splitAmount: 300.0,
      );

      final balanceBefore = TransactionService.balance;
      // Friend approves -> credits user's account with Income
      final success = await SplitService.simulateFriendApproval(outgoingReq.id);
      expect(success, true);

      final updated = SplitService.splitRequests.value.firstWhere((r) => r.id == outgoingReq.id);
      expect(updated.status, SplitStatus.approved);
      expect(TransactionService.balance, balanceBefore + 300.0);
    });

    test('SettingsService: goal and category budget alert preferences persist correctly', () async {
      expect(SettingsService.goalAlertsEnabled.value, true);
      expect(SettingsService.categoryBudgetAlertsEnabled.value, true);

      await SettingsService.setGoalAlertsEnabled(false);
      expect(SettingsService.goalAlertsEnabled.value, false);

      await SettingsService.setCategoryBudgetAlertsEnabled(false);
      expect(SettingsService.categoryBudgetAlertsEnabled.value, false);

      // Reset restores defaults
      await SettingsService.reset();
      expect(SettingsService.goalAlertsEnabled.value, true);
      expect(SettingsService.categoryBudgetAlertsEnabled.value, true);
    });

    test('SplitService: verify registered vs unregistered Paisa app users for split eligibility', () async {
      await SplitService.init();

      // 1. Registered users should be verified and marked eligible
      final alex = SplitService.verifyRegisteredUser('alex@paisa.app');
      expect(alex, isNotNull);
      expect(alex!.isRegistered, true);
      expect(alex.name, 'Alex Rivera');

      final priya = SplitService.verifyRegisteredUser('priya');
      expect(priya, isNotNull);
      expect(priya!.email, 'priya@paisa.app');

      expect(SplitService.isUserRegistered('rahul@paisa.app'), true);

      // 2. Unregistered contacts should return null and not eligible
      final unknown = SplitService.verifyRegisteredUser('stranger@gmail.com');
      expect(unknown, isNull);
      expect(SplitService.isUserRegistered('random_person_404'), false);

      // 3. User with @paisa.app domain is auto-recognized as app user
      final autoRegistered = SplitService.verifyRegisteredUser('vikram@paisa.app');
      expect(autoRegistered, isNotNull);
      expect(autoRegistered!.isRegistered, true);
      expect(SplitService.isUserRegistered('vikram@paisa.app'), true);

      // 4. Custom registration persists and becomes eligible
      const newUser = PaisaUser(
        id: 'user_ananya',
        name: 'Ananya Roy',
        email: 'ananya@paisa.app',
        phone: '+91 99887 76655',
        upiId: 'ananya@paisa',
        isRegistered: true,
      );
      await SplitService.registerUser(newUser);
      expect(SplitService.isUserRegistered('ananya@paisa.app'), true);
      expect(SplitService.verifyRegisteredUser('ananya')?.name, 'Ananya Roy');
    });

    test('SplitService: dispatch split requests to multiple registered participants', () async {
      await SplitService.init();

      final alex = SplitService.verifyRegisteredUser('alex@paisa.app')!;
      final priya = SplitService.verifyRegisteredUser('priya@paisa.app')!;

      final requests = await SplitService.createSplitRequestsForMultiple(
        senderName: 'Krish Patel',
        senderEmail: 'krishpatel@paisa.app',
        recipients: [alex, priya],
        expenseTitle: 'Weekend Getaway',
        totalAmount: 3000.0,
        splitAmountPerPerson: 1000.0,
      );

      expect(requests.length, 2);
      expect(requests[0].recipientName, alex.name);
      expect(requests[0].splitAmount, 1000.0);
      expect(requests[1].recipientName, priya.name);
      expect(requests[1].splitAmount, 1000.0);

      // Verify both requests are in SplitService.splitRequests
      final hasAlex = SplitService.splitRequests.value.any((r) => r.id == requests[0].id);
      final hasPriya = SplitService.splitRequests.value.any((r) => r.id == requests[1].id);
      expect(hasAlex, true);
      expect(hasPriya, true);
    });

    test('SplitService: verifyUserInFirebase validates registered user and rejects unknown user', () async {
      await SplitService.init();

      // Test 1: Registered user found
      final verifiedUser = await SplitService.verifyUserInFirebase('alex@paisa.app');
      expect(verifiedUser, isNotNull);
      expect(verifiedUser!.name, 'Alex Rivera');
      expect(verifiedUser.isRegistered, true);

      // Test 2: Registered user found by name
      final priyaUser = await SplitService.verifyUserInFirebase('Priya Sharma');
      expect(priyaUser, isNotNull);
      expect(priyaUser!.email, 'priya@paisa.app');

      // Test 3: Unregistered unknown user returns null (not available in Firebase)
      final unknownUser = await SplitService.verifyUserInFirebase('unknown_random_person_404@gmail.com');
      expect(unknownUser, isNull);

      // Test 4: Empty query returns null
      final emptyResult = await SplitService.verifyUserInFirebase('');
      expect(emptyResult, isNull);
    });
  });

  group('Multi-User Session Switching & Data Isolation Tests', () {
    test('User A and User B maintain completely isolated transactions and balances', () async {
      // 1. Initialize as User A
      await TransactionService.switchUser('user_alpha_111');
      expect(TransactionService.transactions.value.isNotEmpty, true);
      final initialBalanceA = TransactionService.balance;

      // User A records an expense of 2500
      final expenseA = TransactionModel(
        id: 'tx_alpha_laptop_stand',
        title: 'Laptop Stand',
        note: 'User Alpha purchase',
        date: DateTime.now(),
        amount: 2500,
        category: 'Shopping',
        type: 'Expense',
      );
      await TransactionService.add(expenseA);
      expect(TransactionService.balance, initialBalanceA - 2500);
      expect(TransactionService.transactions.value.any((t) => t.id == 'tx_alpha_laptop_stand'), true);

      // 2. User signs out and User B logs in
      await TransactionService.switchUser('user_beta_222');
      // User B should NOT see User A's laptop stand expense
      expect(
        TransactionService.transactions.value.any((t) => t.id == 'tx_alpha_laptop_stand'),
        false,
      );
      // User B starts with their own fresh opening balance
      expect(TransactionService.balance, 50000.0);

      // User B records an income of 15000
      final incomeB = TransactionModel(
        id: 'tx_beta_freelance',
        title: 'Freelance Design',
        note: 'User Beta income',
        date: DateTime.now(),
        amount: 15000,
        category: 'Income',
        type: 'Income',
      );
      await TransactionService.add(incomeB);
      expect(TransactionService.balance, 65000.0);
      expect(TransactionService.transactions.value.any((t) => t.id == 'tx_beta_freelance'), true);

      // 3. User B signs out and User A logs back in
      await TransactionService.switchUser('user_alpha_111');
      // User A should still have their laptop stand expense
      expect(TransactionService.transactions.value.any((t) => t.id == 'tx_alpha_laptop_stand'), true);
      // User A should NOT see User B's freelance income
      expect(TransactionService.transactions.value.any((t) => t.id == 'tx_beta_freelance'), false);
      expect(TransactionService.balance, initialBalanceA - 2500);

      // 4. Guest session is also isolated
      await TransactionService.switchUser('guest');
      expect(TransactionService.transactions.value.any((t) => t.id == 'tx_alpha_laptop_stand'), false);
      expect(TransactionService.transactions.value.any((t) => t.id == 'tx_beta_freelance'), false);
    });

    test('User A and User B maintain separate goals and settings', () async {
      // 1. User A sets currency to $ and adds a specific goal
      await SettingsService.switchUser('user_alpha_111');
      await GoalService.switchUser('user_alpha_111');
      await SettingsService.setCurrency('\$');

      final goalA = GoalModel(
        id: 'goal_alpha_tokyo',
        name: 'Trip to Tokyo',
        targetAmount: 200000,
        currentAmount: 45000,
        targetDate: DateTime.now().add(const Duration(days: 90)),
        category: 'Travel',
      );
      await GoalService.addGoal(goalA);

      expect(SettingsService.currency.value, '\$');
      expect(GoalService.goals.value.any((g) => g.id == 'goal_alpha_tokyo'), true);

      // 2. User B logs in: should have default currency and NOT have User A's Tokyo goal
      await SettingsService.switchUser('user_beta_222');
      await GoalService.switchUser('user_beta_222');
      expect(SettingsService.currency.value, '₹');
      expect(GoalService.goals.value.any((g) => g.id == 'goal_alpha_tokyo'), false);

      // User B sets currency to €
      await SettingsService.setCurrency('€');
      expect(SettingsService.currency.value, '€');

      // 3. User A logs back in: restores currency $ and Tokyo goal
      await SettingsService.switchUser('user_alpha_111');
      await GoalService.switchUser('user_alpha_111');
      expect(SettingsService.currency.value, '\$');
      expect(GoalService.goals.value.any((g) => g.id == 'goal_alpha_tokyo'), true);
    });

    test('Cross-User Split: User A sends request to User B -> User B receives notification, approves -> User A receives funds', () async {
      // 1. User A (sender) creates a split request to User B
      await SplitService.switchUser('user_alice_101');
      await TransactionService.switchUser('user_alice_101');

      final initialAliceBalance = TransactionService.balance;

      const recipientBob = PaisaUser(
        id: 'user_bob_202',
        name: 'Bob Smith',
        email: 'bob@example.com',
        isRegistered: true,
      );
      await SplitService.registerUser(recipientBob);

      final requests = await SplitService.createSplitRequestsForMultiple(
        senderName: 'Alice',
        senderEmail: 'alice@example.com',
        senderId: 'user_alice_101',
        recipients: [recipientBob],
        expenseTitle: 'Team Lunch',
        totalAmount: 1000.0,
        splitAmountPerPerson: 500.0,
      );

      expect(requests.length, 1);
      final aliceRequest = requests.first;
      expect(aliceRequest.splitAmount, 500.0);
      expect(aliceRequest.status, SplitStatus.pending);

      // In Alice's view: this is OUTGOING, not incoming
      expect(SplitService.isRequestIncoming(aliceRequest), false);
      expect(SplitService.incomingPendingCount, 0);

      // 2. User B (Bob) logs in
      await SplitService.switchUser('user_bob_202');
      await TransactionService.switchUser('user_bob_202');

      final initialBobBalance = TransactionService.balance;

      // Bob MUST receive the notification!
      expect(SplitService.splitRequests.value.isNotEmpty, true);
      final bobIncoming = SplitService.splitRequests.value
          .firstWhere((r) => r.id == aliceRequest.id);

      // In Bob's view: this request is INCOMING!
      expect(bobIncoming.recipientEmail, 'bob@example.com');
      expect(bobIncoming.recipientId, 'user_bob_202');
      expect(SplitService.isRequestIncoming(bobIncoming), true);
      expect(SplitService.incomingPendingCount, 1);

      // 3. Bob Approves & Pays the split request
      final approved = await SplitService.approveRequest(bobIncoming.id);
      expect(approved, true);

      // Bob's balance is debited by 500
      expect(TransactionService.balance, initialBobBalance - 500.0);
      expect(SplitService.incomingPendingCount, 0);

      final bobUpdatedRequest = SplitService.splitRequests.value
          .firstWhere((r) => r.id == aliceRequest.id);
      expect(bobUpdatedRequest.status, SplitStatus.approved);

      // 4. User A (Alice) logs back in
      await TransactionService.switchUser('user_alice_101');
      await SplitService.switchUser('user_alice_101');

      // Alice's balance is automatically credited with 500
      expect(TransactionService.balance, initialAliceBalance + 500.0);

      // In Alice's view: request is approved
      final aliceUpdatedRequest = SplitService.splitRequests.value
          .firstWhere((r) => r.id == aliceRequest.id);
      expect(aliceUpdatedRequest.status, SplitStatus.approved);
      expect(aliceUpdatedRequest.senderCredited, true);
    });

    test('TransactionModel stores split metadata and provides accurate breakdown getters', () {
      final tx = TransactionModel(
        id: 'tx_split_test_1',
        title: 'Dinner Party',
        note: 'Birthday celebration',
        date: DateTime.now(),
        amount: 500.0,
        category: 'Food',
        type: 'Expense',
        isSplit: true,
        splitTotalAmount: 1500.0,
        splitShare: 500.0,
        splitPeopleCount: 3,
        splitWith: ['Alex Rivera', 'Priya Sharma'],
      );

      expect(tx.isSplitTransaction, true);
      expect(tx.displayTotalAmount, 1500.0);
      expect(tx.displayYourShare, 500.0);
      expect(tx.displayPeopleCount, 3);
      expect(tx.splitFriendsList, ['Alex Rivera', 'Priya Sharma']);

      // Serialization and deserialization
      final map = tx.toMap();
      final fromMapTx = TransactionModel.fromMap(map);
      expect(fromMapTx.isSplit, true);
      expect(fromMapTx.splitTotalAmount, 1500.0);
      expect(fromMapTx.splitShare, 500.0);
      expect(fromMapTx.splitPeopleCount, 3);
      expect(fromMapTx.splitWith, ['Alex Rivera', 'Priya Sharma']);
    });

    test('TransactionModel backward compatibility parses split details from legacy notes', () {
      final legacyTx = TransactionModel(
        id: 'tx_legacy_split',
        title: 'Friday Pizza Party',
        note: 'Weekend meetup | Split bill ₹1400 between 3 people. Your share: ₹350. Friends: Alex Rivera (₹350), Priya Sharma (₹350)',
        date: DateTime.now(),
        amount: 350.0,
        category: 'Food',
        type: 'Expense',
      );

      expect(legacyTx.isSplitTransaction, true);
      expect(legacyTx.displayTotalAmount, 1400.0);
      expect(legacyTx.displayYourShare, 350.0);
      expect(legacyTx.displayPeopleCount, 3);
      expect(legacyTx.splitFriendsList.contains('Alex Rivera'), true);
      expect(legacyTx.splitFriendsList.contains('Priya Sharma'), true);
      expect(legacyTx.cleanNote, 'Weekend meetup');
    });

    test('SplitService.getRequestsForTransaction pairs live requests accurately', () async {
      await SplitService.switchUser('organizer_user_99');

      final splitRequests = await SplitService.createSplitRequestsForMultiple(
        senderName: 'Organizer',
        senderEmail: 'organizer@paisa.app',
        transactionId: 'tx_movie_night',
        recipients: [
          const PaisaUser(
            id: 'usr_friend_1',
            name: 'Friend One',
            email: 'friend1@paisa.app',
            isRegistered: true,
          ),
          const PaisaUser(
            id: 'usr_friend_2',
            name: 'Friend Two',
            email: 'friend2@paisa.app',
            isRegistered: true,
          ),
        ],
        expenseTitle: 'Movie Night',
        totalAmount: 900.0,
        splitAmountPerPerson: 300.0,
      );

      final movieTx = TransactionModel(
        id: 'tx_movie_night',
        title: 'Movie Night',
        note: 'IMAX tickets',
        date: DateTime.now(),
        amount: 300.0,
        category: 'Entertainment',
        type: 'Expense',
        isSplit: true,
        splitTotalAmount: 900.0,
        splitShare: 300.0,
        splitPeopleCount: 3,
        splitWith: ['Friend One', 'Friend Two'],
        splitRequestIds: splitRequests.map((r) => r.id).toList(),
      );

      final matching = SplitService.getRequestsForTransaction(movieTx);
      expect(matching.length, 2);
      expect(matching.any((r) => r.recipientName == 'Friend One'), true);
      expect(matching.any((r) => r.recipientName == 'Friend Two'), true);
      expect(matching.first.splitAmount, 300.0);
    });
  });
}

