import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/transaction_model.dart';
import 'transaction_service.dart';

enum SplitStatus {
  pending,
  approved,
  rejected,
}

class PaisaUser {
  final String id;
  final String name;
  final String email;
  final String phone;
  final String upiId;
  final bool isRegistered;

  const PaisaUser({
    required this.id,
    required this.name,
    required this.email,
    this.phone = '',
    this.upiId = '',
    this.isRegistered = true,
  });

  PaisaUser copyWith({
    String? id,
    String? name,
    String? email,
    String? phone,
    String? upiId,
    bool? isRegistered,
  }) {
    return PaisaUser(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      upiId: upiId ?? this.upiId,
      isRegistered: isRegistered ?? this.isRegistered,
    );
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'email': email,
        'phone': phone,
        'upiId': upiId,
        'isRegistered': isRegistered,
      };

  factory PaisaUser.fromMap(Map<String, dynamic> map) => PaisaUser(
        id: map['id']?.toString() ?? '',
        name: map['name']?.toString() ?? '',
        email: map['email']?.toString() ?? '',
        phone: map['phone']?.toString() ?? '',
        upiId: map['upiId']?.toString() ?? '',
        isRegistered: map['isRegistered'] == true,
      );
}

class SplitRequest {
  final String id;
  final String transactionId;
  final String senderId;
  final String senderName;
  final String senderEmail;
  final String recipientId;
  final String recipientName;
  final String recipientEmail;
  final String expenseTitle;
  final double totalAmount;
  final double splitAmount;
  final SplitStatus status;
  final DateTime createdAt;
  final DateTime? resolvedAt;
  final bool senderCredited;
  final bool recipientDebited;

  const SplitRequest({
    required this.id,
    this.transactionId = '',
    this.senderId = '',
    required this.senderName,
    required this.senderEmail,
    this.recipientId = '',
    required this.recipientName,
    required this.recipientEmail,
    required this.expenseTitle,
    required this.totalAmount,
    required this.splitAmount,
    this.status = SplitStatus.pending,
    required this.createdAt,
    this.resolvedAt,
    this.senderCredited = false,
    this.recipientDebited = false,
  });

  bool get isPending => status == SplitStatus.pending;
  bool get isApproved => status == SplitStatus.approved;
  bool get isRejected => status == SplitStatus.rejected;

  SplitRequest copyWith({
    String? id,
    String? transactionId,
    String? senderId,
    String? senderName,
    String? senderEmail,
    String? recipientId,
    String? recipientName,
    String? recipientEmail,
    String? expenseTitle,
    double? totalAmount,
    double? splitAmount,
    SplitStatus? status,
    DateTime? createdAt,
    DateTime? resolvedAt,
    bool? senderCredited,
    bool? recipientDebited,
  }) {
    return SplitRequest(
      id: id ?? this.id,
      transactionId: transactionId ?? this.transactionId,
      senderId: senderId ?? this.senderId,
      senderName: senderName ?? this.senderName,
      senderEmail: senderEmail ?? this.senderEmail,
      recipientId: recipientId ?? this.recipientId,
      recipientName: recipientName ?? this.recipientName,
      recipientEmail: recipientEmail ?? this.recipientEmail,
      expenseTitle: expenseTitle ?? this.expenseTitle,
      totalAmount: totalAmount ?? this.totalAmount,
      splitAmount: splitAmount ?? this.splitAmount,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      resolvedAt: resolvedAt ?? this.resolvedAt,
      senderCredited: senderCredited ?? this.senderCredited,
      recipientDebited: recipientDebited ?? this.recipientDebited,
    );
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'transactionId': transactionId,
        'senderId': senderId,
        'senderName': senderName,
        'senderEmail': senderEmail,
        'recipientId': recipientId,
        'recipientName': recipientName,
        'recipientEmail': recipientEmail,
        'expenseTitle': expenseTitle,
        'totalAmount': totalAmount,
        'splitAmount': splitAmount,
        'status': status.name,
        'createdAt': createdAt.toIso8601String(),
        'resolvedAt': resolvedAt?.toIso8601String(),
        'senderCredited': senderCredited,
        'recipientDebited': recipientDebited,
      };

  factory SplitRequest.fromMap(Map<String, dynamic> map) => SplitRequest(
        id: map['id']?.toString() ?? '',
        transactionId: map['transactionId']?.toString() ?? '',
        senderId: map['senderId']?.toString() ?? '',
        senderName: map['senderName']?.toString() ?? '',
        senderEmail: map['senderEmail']?.toString() ?? '',
        recipientId: map['recipientId']?.toString() ?? '',
        recipientName: map['recipientName']?.toString() ?? '',
        recipientEmail: map['recipientEmail']?.toString() ?? '',
        expenseTitle: map['expenseTitle']?.toString() ?? '',
        totalAmount: (map['totalAmount'] as num?)?.toDouble() ?? 0.0,
        splitAmount: (map['splitAmount'] as num?)?.toDouble() ?? 0.0,
        status: SplitStatus.values.firstWhere(
          (e) => e.name == map['status'],
          orElse: () => SplitStatus.pending,
        ),
        createdAt: DateTime.tryParse(map['createdAt']?.toString() ?? '') ??
            DateTime.now(),
        resolvedAt: map['resolvedAt'] != null
            ? DateTime.tryParse(map['resolvedAt'].toString())
            : null,
        senderCredited: map['senderCredited'] == true,
        recipientDebited: map['recipientDebited'] == true,
      );
}

class SplitMember {
  final String id;
  final String name;
  final double amount;
  final bool isCurrentUser;
  final bool hasPaid;

  const SplitMember({
    required this.id,
    required this.name,
    required this.amount,
    this.isCurrentUser = false,
    this.hasPaid = false,
  });

  SplitMember copyWith({
    String? id,
    String? name,
    double? amount,
    bool? isCurrentUser,
    bool? hasPaid,
  }) {
    return SplitMember(
      id: id ?? this.id,
      name: name ?? this.name,
      amount: amount ?? this.amount,
      isCurrentUser: isCurrentUser ?? this.isCurrentUser,
      hasPaid: hasPaid ?? this.hasPaid,
    );
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'amount': amount,
        'isCurrentUser': isCurrentUser,
        'hasPaid': hasPaid,
      };

  factory SplitMember.fromMap(Map<String, dynamic> map) => SplitMember(
        id: map['id']?.toString() ?? '',
        name: map['name']?.toString() ?? '',
        amount: (map['amount'] as num?)?.toDouble() ?? 0.0,
        isCurrentUser: map['isCurrentUser'] == true,
        hasPaid: map['hasPaid'] == true,
      );
}

class SplitCalculation {
  final double totalAmount;
  final int peopleCount;
  final double sharePerPerson;
  final double yourShare;
  final double friendsTotalOwed;
  final List<SplitMember> members;

  const SplitCalculation({
    required this.totalAmount,
    required this.peopleCount,
    required this.sharePerPerson,
    required this.yourShare,
    required this.friendsTotalOwed,
    required this.members,
  });
}

class SplitService {
  static String? _currentUserId;

  static const String _allRequestsKey = 'paisa_master_split_requests_v2';
  static const String _usersStorageKey = 'paisa_registered_users_v1';
  static late SharedPreferences _prefs;

  static final List<PaisaUser> _defaultRegisteredUsers = [
    const PaisaUser(
      id: 'usr_alex',
      name: 'Alex Rivera',
      email: 'alex@paisa.app',
      phone: '+91 98765 43210',
      upiId: 'alex@paisa',
      isRegistered: true,
    ),
    const PaisaUser(
      id: 'usr_priya',
      name: 'Priya Sharma',
      email: 'priya@paisa.app',
      phone: '+91 98111 22334',
      upiId: 'priya@paisa',
      isRegistered: true,
    ),
    const PaisaUser(
      id: 'usr_rahul',
      name: 'Rahul Mehta',
      email: 'rahul@paisa.app',
      phone: '+91 98222 33445',
      upiId: 'rahul@paisa',
      isRegistered: true,
    ),
    const PaisaUser(
      id: 'usr_neha',
      name: 'Neha Kapoor',
      email: 'neha@paisa.app',
      phone: '+91 98333 44556',
      upiId: 'neha@paisa',
      isRegistered: true,
    ),
    const PaisaUser(
      id: 'usr_rohit',
      name: 'Rohit Verma',
      email: 'rohit@paisa.app',
      phone: '+91 98444 55667',
      upiId: 'rohit@paisa',
      isRegistered: true,
    ),
  ];

  static final ValueNotifier<List<PaisaUser>> registeredUsers =
      ValueNotifier<List<PaisaUser>>([..._defaultRegisteredUsers]);

  static final ValueNotifier<List<SplitRequest>> splitRequests =
      ValueNotifier<List<SplitRequest>>([]);

  static bool get isFirebaseAvailable {
    try {
      return Firebase.apps.isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  static User? get _currentAuthUser {
    if (!isFirebaseAvailable) return null;
    try {
      return FirebaseAuth.instance.currentUser;
    } catch (_) {
      return null;
    }
  }

  /// Master list loader from shared storage
  static List<SplitRequest> _loadAllMasterRequests() {
    final raw = _prefs.getString(_allRequestsKey);
    if (raw == null || raw.isEmpty) {
      // Legacy data fallback if available
      final legacy = _prefs.getString('paisa_split_requests_v1');
      if (legacy != null && legacy.isNotEmpty) {
        try {
          final decoded = jsonDecode(legacy);
          if (decoded is List) {
            return decoded
                .whereType<Map>()
                .map((m) => SplitRequest.fromMap(Map<String, dynamic>.from(m)))
                .toList();
          }
        } catch (_) {}
      }
      return [];
    }

    try {
      final decoded = jsonDecode(raw);
      if (decoded is List) {
        return decoded
            .whereType<Map>()
            .map((m) => SplitRequest.fromMap(Map<String, dynamic>.from(m)))
            .toList();
      }
    } catch (_) {}
    return [];
  }

  /// Master list saver to shared storage
  static Future<void> _saveMasterList(List<SplitRequest> all) async {
    final encoded = jsonEncode(all.map((e) => e.toMap()).toList());
    await _prefs.setString(_allRequestsKey, encoded);
  }

  /// Refreshes splitRequests ValueNotifier for the current active user
  static void _refreshActiveList(List<SplitRequest> all) {
    final filtered = all.where((r) => isRelevantToUser(r, _currentUserId)).toList();
    splitRequests.value = List.unmodifiable(filtered);
  }

  /// Determines if a split request was sent TO the current user (Incoming)
  static bool isRequestIncoming(SplitRequest req) {
    final user = _currentAuthUser;
    final currentEmail = (user?.email ?? '').trim().toLowerCase();
    final currentName = (user?.displayName ?? '').trim().toLowerCase();
    final currentUid = user?.uid ?? _currentUserId ?? '';

    // 1. Signed-in Firebase Auth match
    if (currentEmail.isNotEmpty && req.recipientEmail.trim().toLowerCase() == currentEmail) {
      return true;
    }
    if (currentUid.isNotEmpty && req.recipientId.isNotEmpty && req.recipientId == currentUid) {
      return true;
    }
    if (currentName.isNotEmpty && req.recipientName.trim().toLowerCase() == currentName) {
      return true;
    }

    // 2. Unauthenticated / guest / offline fallback
    final isGuestOrOffline = currentUid.isEmpty || currentUid == 'guest' || currentUid == 'offline';
    if (isGuestOrOffline) {
      final rEmail = req.recipientEmail.trim().toLowerCase();
      final rName = req.recipientName.trim().toLowerCase();
      if (rEmail == 'krishpatel@paisa.app' ||
          rName == 'krish patel' ||
          req.recipientId == 'guest' ||
          (req.recipientId.isEmpty && req.senderEmail != 'krishpatel@paisa.app')) {
        return true;
      }
    }

    return false;
  }

  /// Determines if a split request was sent BY the current user (Outgoing)
  static bool isRequestOutgoing(SplitRequest req) {
    return !isRequestIncoming(req);
  }

  /// Checks if a request involves the given user (as sender or recipient)
  static bool isRelevantToUser(SplitRequest req, String? userId) {
    final user = _currentAuthUser;
    final currentEmail = (user?.email ?? '').trim().toLowerCase();
    final currentName = (user?.displayName ?? '').trim().toLowerCase();
    final uid = user?.uid ?? userId ?? _currentUserId ?? '';

    // Guest / test session matches guest, seed or Behance mockup account
    final isGuestOrOffline = uid.isEmpty || uid == 'guest' || uid == 'offline';
    if (isGuestOrOffline) {
      final rEmail = req.recipientEmail.trim().toLowerCase();
      final sEmail = req.senderEmail.trim().toLowerCase();
      final rName = req.recipientName.trim().toLowerCase();
      final sName = req.senderName.trim().toLowerCase();
      if (rEmail == 'krishpatel@paisa.app' ||
          sEmail == 'krishpatel@paisa.app' ||
          rName == 'krish patel' ||
          sName == 'krish patel' ||
          req.recipientId == uid ||
          req.senderId == uid ||
          req.id == 'split_seed_1') {
        return true;
      }
    }

    // Recipient match
    if (currentEmail.isNotEmpty && req.recipientEmail.trim().toLowerCase() == currentEmail) {
      return true;
    }
    if (currentName.isNotEmpty && req.recipientName.trim().toLowerCase() == currentName) {
      return true;
    }
    if (uid.isNotEmpty && req.recipientId.isNotEmpty && req.recipientId == uid) {
      return true;
    }

    // Sender match
    if (currentEmail.isNotEmpty && req.senderEmail.trim().toLowerCase() == currentEmail) {
      return true;
    }
    if (currentName.isNotEmpty && req.senderName.trim().toLowerCase() == currentName) {
      return true;
    }
    if (uid.isNotEmpty && req.senderId.isNotEmpty && req.senderId == uid) {
      return true;
    }

    return false;
  }

  /// Unread incoming pending split requests count for badge display
  static int get incomingPendingCount {
    return splitRequests.value
        .where((r) => isRequestIncoming(r) && r.isPending)
        .length;
  }

  /// Initialize SplitService with stored requests
  static Future<void> init({String? userId}) async {
    _prefs = await SharedPreferences.getInstance();
    await switchUser(userId ?? _currentUserId);
  }

  /// Switch the active user session and load their specific split requests
  static Future<void> switchUser(String? userId) async {
    _currentUserId = userId;

    // 1. Initialize registered users from storage
    final savedUsers = _prefs.getString(_usersStorageKey);
    if (savedUsers != null && savedUsers.isNotEmpty) {
      try {
        final decoded = jsonDecode(savedUsers);
        if (decoded is List) {
          final loaded = decoded
              .whereType<Map>()
              .map((m) => PaisaUser.fromMap(Map<String, dynamic>.from(m)))
              .toList();
          if (loaded.isNotEmpty) {
            registeredUsers.value = loaded;
          }
        }
      } catch (_) {}
    }

    // 2. Load master requests list
    var all = _loadAllMasterRequests();

    // If master list is empty and user is guest / offline, seed initial Behance demo request
    if (all.isEmpty && (_currentUserId == null || _currentUserId == 'offline' || _currentUserId == 'guest')) {
      final now = DateTime.now();
      all = [
        SplitRequest(
          id: 'split_seed_1',
          senderName: 'Alex Rivera',
          senderEmail: 'alex@paisa.app',
          recipientName: 'Krish Patel',
          recipientEmail: 'krishpatel@paisa.app',
          expenseTitle: 'Friday Pizza Party',
          totalAmount: 1400.0,
          splitAmount: 350.0,
          status: SplitStatus.pending,
          createdAt: now.subtract(const Duration(minutes: 45)),
        ),
      ];
      await _saveMasterList(all);
    }

    // 3. Process settlement for any outgoing requests approved while sender was offline
    bool masterUpdated = false;
    final now = DateTime.now();
    for (int i = 0; i < all.length; i++) {
      final req = all[i];
      if (req.isApproved && !req.senderCredited && isRequestOutgoing(req)) {
        final creditTx = TransactionModel(
          id: 'split_credit_${now.millisecondsSinceEpoch}_${req.id}',
          title: 'Split payment from ${req.recipientName}',
          note: 'Payment received for "${req.expenseTitle}" split share (Ref: ${req.id})',
          date: now,
          amount: req.splitAmount,
          category: 'Income',
          type: 'Income',
          paymentMethod: 'UPI',
        );
        await TransactionService.add(creditTx);
        all[i] = req.copyWith(senderCredited: true);
        masterUpdated = true;
      }
    }
    if (masterUpdated) {
      await _saveMasterList(all);
    }

    // 4. Update active user view
    _refreshActiveList(all);

    // 5. Connect to live Firebase if initialized
    if (isFirebaseAvailable) {
      syncCurrentAuthUser();
    }
  }

  /// Sync current Firebase Auth user into Paisa registered users
  static Future<void> syncCurrentAuthUser() async {
    if (!isFirebaseAvailable) return;
    try {
      final user = _currentAuthUser;
      if (user != null && (user.email != null && user.email!.isNotEmpty)) {
        final paisaUser = PaisaUser(
          id: user.uid,
          name: (user.displayName != null && user.displayName!.isNotEmpty)
              ? user.displayName!
              : user.email!.split('@').first,
          email: user.email!,
          phone: user.phoneNumber ?? '',
          upiId: '${user.email!.split('@').first}@paisa',
          isRegistered: true,
        );
        await registerUser(paisaUser);
      }
    } catch (e) {
      debugPrint('syncCurrentAuthUser error: $e');
    }
  }

  /// Register a user in the local registered users list and persist
  static Future<void> registerUser(PaisaUser user) async {
    final list = [...registeredUsers.value];
    final index = list.indexWhere((u) => u.email.toLowerCase() == user.email.toLowerCase());
    if (index >= 0) {
      list[index] = user;
    } else {
      list.add(user);
    }
    registeredUsers.value = List.unmodifiable(list);
    try {
      final encoded = jsonEncode(list.map((u) => u.toMap()).toList());
      await _prefs.setString(_usersStorageKey, encoded);
    } catch (_) {}
  }

  /// Sync a user to Firebase / registered store
  static Future<void> syncUserToFirebase(PaisaUser user) async {
    await registerUser(user);
  }

  /// Sync all registered users to Firebase / registered store
  static Future<void> syncAllUsersToFirebase() async {
    for (final u in registeredUsers.value) {
      await registerUser(u);
    }
  }

  /// Verify if user is registered and available in Firebase (Firebase Auth / Registered users).
  static Future<PaisaUser?> verifyUserInFirebase(String query) async {
    final clean = query.trim().toLowerCase();
    if (clean.isEmpty) return null;

    // 1. Check local cache first
    final localMatch = verifyRegisteredUser(clean);
    if (localMatch != null) {
      return localMatch;
    }

    // 2. Check current authenticated Firebase user
    if (isFirebaseAvailable) {
      try {
        final currentAuth = _currentAuthUser;
        if (currentAuth != null &&
            (currentAuth.email?.toLowerCase() == clean ||
                currentAuth.displayName?.toLowerCase() == clean)) {
          final u = PaisaUser(
            id: currentAuth.uid,
            name: currentAuth.displayName ?? 'You',
            email: currentAuth.email ?? '',
            phone: currentAuth.phoneNumber ?? '',
            upiId: '${(currentAuth.email ?? 'user').split('@').first}@paisa',
            isRegistered: true,
          );
          await registerUser(u);
          return u;
        }
      } catch (e) {
        debugPrint('Firebase verification query error: $e');
      }
    }

    // 3. Fallback domain rule for @paisa.app or @paisa accounts
    if (clean.endsWith('@paisa.app') || clean.endsWith('@paisa')) {
      final rawName = clean.split('@').first;
      final capitalized = rawName.isNotEmpty
          ? rawName[0].toUpperCase() + rawName.substring(1)
          : 'Paisa User';
      final newUser = PaisaUser(
        id: 'usr_${DateTime.now().millisecondsSinceEpoch}',
        name: capitalized,
        email: clean.endsWith('@paisa.app') ? clean : '$clean.app',
        phone: '',
        upiId: clean.endsWith('@paisa') ? clean : '$rawName@paisa',
        isRegistered: true,
      );
      await registerUser(newUser);
      return newUser;
    }

    return null;
  }

  /// Check if a user is registered on the Paisa app and eligible for split.
  static PaisaUser? verifyRegisteredUser(String query) {
    final clean = query.trim().toLowerCase();
    if (clean.isEmpty) return null;

    final cleanDigits = clean.replaceAll(RegExp(r'[^0-9]'), '');

    for (final u in registeredUsers.value) {
      final emailLower = u.email.toLowerCase();
      final nameLower = u.name.toLowerCase();
      final upiLower = u.upiId.toLowerCase();

      // Check email (exact or username prefix)
      if (emailLower == clean || emailLower.split('@').first == clean) {
        return u;
      }

      // Check name (exact, first name, or contains)
      if (nameLower == clean || nameLower.split(' ').first == clean) {
        return u;
      }

      // Check UPI ID
      if (upiLower == clean || upiLower.split('@').first == clean) {
        return u;
      }

      // Check phone digits if digits were entered
      if (cleanDigits.length >= 7) {
        final phoneDigits = u.phone.replaceAll(RegExp(r'[^0-9]'), '');
        if (phoneDigits.contains(cleanDigits) || cleanDigits.contains(phoneDigits)) {
          return u;
        }
      }
    }

    // Auto-recognize any email ending in @paisa.app or @paisa as valid app accounts
    if (clean.endsWith('@paisa.app') || clean.endsWith('@paisa')) {
      final rawName = clean.split('@').first;
      final capitalized = rawName.isNotEmpty
          ? rawName[0].toUpperCase() + rawName.substring(1)
          : 'Paisa User';
      return PaisaUser(
        id: 'usr_${rawName.hashCode.abs()}',
        name: capitalized,
        email: clean.endsWith('@paisa.app') ? clean : '$clean.app',
        phone: '',
        upiId: clean.endsWith('@paisa') ? clean : '$rawName@paisa',
        isRegistered: true,
      );
    }

    return null;
  }

  /// Check if a user is registered (returns true/false)
  static bool isUserRegistered(String query) {
    return verifyRegisteredUser(query) != null;
  }

  /// Create a new Split Request to another app user
  static Future<SplitRequest> createSplitRequest({
    required String senderName,
    required String senderEmail,
    String senderId = '',
    required String recipientName,
    required String recipientEmail,
    String recipientId = '',
    required String expenseTitle,
    required double totalAmount,
    required double splitAmount,
  }) async {
    final effectiveSenderId = senderId.isNotEmpty
        ? senderId
        : (_currentAuthUser?.uid ?? _currentUserId ?? 'guest');

    final req = SplitRequest(
      id: 'split_${DateTime.now().millisecondsSinceEpoch}',
      senderId: effectiveSenderId,
      senderName: senderName,
      senderEmail: senderEmail,
      recipientId: recipientId,
      recipientName: recipientName,
      recipientEmail: recipientEmail,
      expenseTitle: expenseTitle,
      totalAmount: totalAmount,
      splitAmount: splitAmount,
      status: SplitStatus.pending,
      createdAt: DateTime.now(),
    );

    final all = _loadAllMasterRequests();
    all.insert(0, req);
    await _saveMasterList(all);
    _refreshActiveList(all);
    return req;
  }

  /// Create split requests for multiple registered recipients
  static Future<List<SplitRequest>> createSplitRequestsForMultiple({
    required String senderName,
    required String senderEmail,
    String senderId = '',
    String transactionId = '',
    required List<PaisaUser> recipients,
    required String expenseTitle,
    required double totalAmount,
    required double splitAmountPerPerson,
  }) async {
    final effectiveSenderId = senderId.isNotEmpty
        ? senderId
        : (_currentAuthUser?.uid ?? _currentUserId ?? 'guest');
    final newRequests = <SplitRequest>[];
    final now = DateTime.now();

    for (int i = 0; i < recipients.length; i++) {
      final recipient = recipients[i];
      final req = SplitRequest(
        id: 'split_${now.millisecondsSinceEpoch}_$i',
        transactionId: transactionId,
        senderId: effectiveSenderId,
        senderName: senderName,
        senderEmail: senderEmail,
        recipientId: recipient.id,
        recipientName: recipient.name,
        recipientEmail: recipient.email,
        expenseTitle: expenseTitle,
        totalAmount: totalAmount,
        splitAmount: splitAmountPerPerson,
        status: SplitStatus.pending,
        createdAt: now,
      );
      newRequests.add(req);
    }

    final all = _loadAllMasterRequests();
    all.insertAll(0, newRequests);
    await _saveMasterList(all);
    _refreshActiveList(all);
    return newRequests;
  }

  /// Retrieve all split requests matching a given transaction
  static List<SplitRequest> getRequestsForTransaction(TransactionModel tx) {
    final all = _loadAllMasterRequests();
    // 1. Direct transaction ID or splitRequestIds match
    final byTxId = all.where((r) =>
        (r.transactionId.isNotEmpty && r.transactionId == tx.id) ||
        (tx.splitRequestIds != null && tx.splitRequestIds!.contains(r.id))).toList();
    if (byTxId.isNotEmpty) return byTxId;

    // 2. Direct expense title and total amount match
    final byTitle = all.where((r) {
      final titleMatch = r.expenseTitle.toLowerCase().trim() == tx.title.toLowerCase().trim();
      final totalDiff = (r.totalAmount - tx.displayTotalAmount).abs();
      return titleMatch && (totalDiff < 1.0 || (r.splitAmount - tx.amount).abs() < 1.0);
    }).toList();
    if (byTitle.isNotEmpty) return byTitle;

    // 3. Match by recipient names listed in the transaction note or splitWith
    final friends = tx.splitFriendsList;
    if (friends.isNotEmpty) {
      final byFriends = all.where((r) {
        final matchesFriend = friends.any((f) =>
            r.recipientName.toLowerCase().contains(f.toLowerCase()) ||
            f.toLowerCase().contains(r.recipientName.toLowerCase()));
        final titleMatch = r.expenseTitle.toLowerCase().trim() == tx.title.toLowerCase().trim();
        return matchesFriend && titleMatch;
      }).toList();
      if (byFriends.isNotEmpty) return byFriends;
    }

    return [];
  }

  /// Approve a split request: debits money from current user's account and records expense
  static Future<bool> approveRequest(String requestId) async {
    final all = _loadAllMasterRequests();
    final index = all.indexWhere((r) => r.id == requestId);
    if (index == -1) return false;

    final req = all[index];
    final now = DateTime.now();

    // 1. Mark as approved in master list
    all[index] = req.copyWith(
      status: SplitStatus.approved,
      resolvedAt: now,
      recipientDebited: true,
    );
    await _saveMasterList(all);
    _refreshActiveList(all);

    // 2. Debit recipient's account by adding an Expense transaction
    final debitTx = TransactionModel(
      id: 'split_debit_${now.millisecondsSinceEpoch}',
      title: 'Paid split to ${req.senderName}',
      note: 'Approved split bill for "${req.expenseTitle}" (Ref: ${req.id})',
      date: now,
      amount: req.splitAmount,
      category: 'Food',
      type: 'Expense',
      paymentMethod: 'UPI',
    );
    await TransactionService.add(debitTx);

    return true;
  }

  /// Reject a split request: no money is debited or transferred
  static Future<bool> rejectRequest(String requestId) async {
    final all = _loadAllMasterRequests();
    final index = all.indexWhere((r) => r.id == requestId);
    if (index == -1) return false;

    final req = all[index];
    all[index] = req.copyWith(
      status: SplitStatus.rejected,
      resolvedAt: DateTime.now(),
    );
    await _saveMasterList(all);
    _refreshActiveList(all);
    return true;
  }

  /// Simulate friend approving the split request sent by the user:
  /// Transfers money to user's account by adding an Income transaction.
  static Future<bool> simulateFriendApproval(String requestId) async {
    final all = _loadAllMasterRequests();
    final index = all.indexWhere((r) => r.id == requestId);
    if (index == -1) return false;

    final req = all[index];
    final now = DateTime.now();

    all[index] = req.copyWith(
      status: SplitStatus.approved,
      resolvedAt: now,
      senderCredited: true,
    );
    await _saveMasterList(all);
    _refreshActiveList(all);

    // Credit current user's account with Income transfer
    final creditTx = TransactionModel(
      id: 'split_credit_${now.millisecondsSinceEpoch}',
      title: 'Split received from ${req.recipientName}',
      note: 'Transfer received for "${req.expenseTitle}" split share (Ref: ${req.id})',
      date: now,
      amount: req.splitAmount,
      category: 'Other',
      type: 'Income',
      paymentMethod: 'UPI',
    );
    await TransactionService.add(creditTx);
    return true;
  }

  /// Simulate friend rejecting the split request sent by the user
  static Future<bool> simulateFriendRejection(String requestId) async {
    final all = _loadAllMasterRequests();
    final index = all.indexWhere((r) => r.id == requestId);
    if (index == -1) return false;

    final req = all[index];
    all[index] = req.copyWith(
      status: SplitStatus.rejected,
      resolvedAt: DateTime.now(),
    );
    await _saveMasterList(all);
    _refreshActiveList(all);
    return true;
  }

  /// Calculate equal split across N participants
  static SplitCalculation calculateEqualSplit({
    required double totalAmount,
    required int peopleCount,
    String currentUserName = 'You',
    List<String>? friendNames,
  }) {
    final count = peopleCount < 1 ? 1 : peopleCount;
    final perPerson = (totalAmount / count);
    final roundedPerPerson = (perPerson * 100).roundToDouble() / 100.0;

    final members = <SplitMember>[
      SplitMember(
        id: 'me',
        name: currentUserName,
        amount: roundedPerPerson,
        isCurrentUser: true,
        hasPaid: true,
      ),
    ];

    final defaultFriends = ['Alex Rivera', 'Priya Sharma', 'Rahul Mehta', 'Neha Kapoor', 'Rohit Verma'];

    for (int i = 1; i < count; i++) {
      final name = (friendNames != null && friendNames.length >= i)
          ? friendNames[i - 1]
          : (i - 1 < defaultFriends.length
              ? defaultFriends[i - 1]
              : 'Friend $i');

      members.add(
        SplitMember(
          id: 'friend_$i',
          name: name,
          amount: roundedPerPerson,
          isCurrentUser: false,
          hasPaid: false,
        ),
      );
    }

    final friendsOwed = count > 1 ? (totalAmount - roundedPerPerson) : 0.0;

    return SplitCalculation(
      totalAmount: totalAmount,
      peopleCount: count,
      sharePerPerson: roundedPerPerson,
      yourShare: roundedPerPerson,
      friendsTotalOwed: friendsOwed > 0 ? friendsOwed : 0.0,
      members: members,
    );
  }

  /// Build a standard UPI Payment Request URL for friends to pay their split share
  static String generateSplitUpiLink({
    required String payeeUpiId,
    required String payeeName,
    required double amount,
    required String note,
  }) {
    final cleanUpi = payeeUpiId.trim();
    final cleanName = Uri.encodeComponent(payeeName.trim());
    final cleanNote = Uri.encodeComponent(note.trim());
    final formattedAmount = amount.toStringAsFixed(2);

    return 'upi://pay?pa=$cleanUpi&pn=$cleanName&am=$formattedAmount&cu=INR&tn=$cleanNote';
  }

  /// Generate human-readable split breakdown text to save in transaction notes
  static String formatSplitNote({
    required double totalAmount,
    required int peopleCount,
    required double yourShare,
    required List<SplitMember> members,
    String? originalNote,
  }) {
    final buffer = StringBuffer();
    if (originalNote != null && originalNote.trim().isNotEmpty) {
      buffer.write('${originalNote.trim()} | ');
    }
    buffer.write('Split bill ₹${totalAmount.toStringAsFixed(0)} between $peopleCount people. ');
    buffer.write('Your share: ₹${yourShare.toStringAsFixed(0)}. ');

    final friendNames = members
        .where((m) => !m.isCurrentUser)
        .map((m) => '${m.name} (₹${m.amount.toStringAsFixed(0)})')
        .join(', ');

    if (friendNames.isNotEmpty) {
      buffer.write('Friends: $friendNames');
    }

    return buffer.toString();
  }
}
