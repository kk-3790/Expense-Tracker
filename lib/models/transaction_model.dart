class TransactionModel {
  final String id;
  final String title;
  final String note;
  final DateTime date;
  final double amount;
  final String category;
  final String type;
  final String paymentMethod;
  final bool isSplit;
  final double? splitTotalAmount;
  final double? splitShare;
  final int? splitPeopleCount;
  final List<String>? splitWith;
  final List<String>? splitRequestIds;

  const TransactionModel({
    required this.id,
    required this.title,
    required this.note,
    required this.date,
    required this.amount,
    required this.category,
    required this.type,
    this.paymentMethod = 'UPI',
    this.isSplit = false,
    this.splitTotalAmount,
    this.splitShare,
    this.splitPeopleCount,
    this.splitWith,
    this.splitRequestIds,
  });

  bool get isIncome => type == 'Income';

  bool get isExpense => type == 'Expense';

  bool get isSplitTransaction =>
      isSplit ||
      (splitTotalAmount != null && splitTotalAmount! > 0) ||
      (splitWith != null && splitWith!.isNotEmpty) ||
      note.contains('Split bill') ||
      note.contains('Friends:');

  double get displayTotalAmount {
    if (splitTotalAmount != null && splitTotalAmount! > 0) {
      return splitTotalAmount!;
    }
    if (note.contains('Split bill')) {
      final match = RegExp(r'Split bill ₹?([0-9.]+)').firstMatch(note);
      if (match != null) {
        return double.tryParse(match.group(1) ?? '') ?? amount;
      }
    }
    return amount;
  }

  double get displayYourShare {
    if (splitShare != null && splitShare! > 0) {
      return splitShare!;
    }
    if (note.contains('Your share:')) {
      final match = RegExp(r'Your share: ₹?([0-9.]+)').firstMatch(note);
      if (match != null) {
        return double.tryParse(match.group(1) ?? '') ?? amount;
      }
    }
    return amount;
  }

  int get displayPeopleCount {
    if (splitPeopleCount != null && splitPeopleCount! > 0) {
      return splitPeopleCount!;
    }
    if (note.contains('between')) {
      final match = RegExp(r'between ([0-9]+) people').firstMatch(note);
      if (match != null) {
        return int.tryParse(match.group(1) ?? '') ??
            (splitFriendsList.length + 1);
      }
    }
    return splitFriendsList.isNotEmpty ? splitFriendsList.length + 1 : 1;
  }

  List<String> get splitFriendsList {
    if (splitWith != null && splitWith!.isNotEmpty) {
      return splitWith!;
    }
    if (note.contains('Friends:')) {
      final friendsPart = note.split('Friends:').last.split('|').first.trim();
      final rawList = friendsPart.split(',');
      return rawList.map((item) {
        final clean = item.split('(').first.trim();
        return clean;
      }).where((s) => s.isNotEmpty).toList();
    }
    return [];
  }

  String get cleanNote {
    if (!isSplitTransaction) return note;
    if (note.contains('| Split bill')) {
      return note.split('| Split bill').first.trim();
    }
    if (note.startsWith('Split bill')) {
      return '';
    }
    return note;
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'note': note,
      'date': date.toIso8601String(),
      'amount': amount,
      'category': category,
      'type': type,
      'paymentMethod': paymentMethod,
      'isSplit': isSplit,
      if (splitTotalAmount != null) 'splitTotalAmount': splitTotalAmount,
      if (splitShare != null) 'splitShare': splitShare,
      if (splitPeopleCount != null) 'splitPeopleCount': splitPeopleCount,
      if (splitWith != null) 'splitWith': splitWith,
      if (splitRequestIds != null) 'splitRequestIds': splitRequestIds,
    };
  }

  factory TransactionModel.fromMap(
    Map<String, dynamic> map,
  ) {
    return TransactionModel(
      id: map['id']?.toString() ?? '',
      title: map['title']?.toString() ?? '',
      note: map['note']?.toString() ?? '',
      date: DateTime.tryParse(
            map['date']?.toString() ?? '',
          )?.toLocal() ??
          DateTime.now(),
      amount: map['amount'] is num
          ? (map['amount'] as num).toDouble()
          : double.tryParse(
                map['amount']?.toString() ?? '',
              ) ??
              0,
      category: map['category']?.toString() ?? 'Other',
      type: map['type']?.toString() == 'Income' ? 'Income' : 'Expense',
      paymentMethod: map['paymentMethod']?.toString() ?? 'UPI',
      isSplit: map['isSplit'] == true,
      splitTotalAmount: (map['splitTotalAmount'] as num?)?.toDouble(),
      splitShare: (map['splitShare'] as num?)?.toDouble(),
      splitPeopleCount: (map['splitPeopleCount'] as num?)?.toInt(),
      splitWith: (map['splitWith'] is List)
          ? (map['splitWith'] as List).map((e) => e.toString()).toList()
          : null,
      splitRequestIds: (map['splitRequestIds'] is List)
          ? (map['splitRequestIds'] as List).map((e) => e.toString()).toList()
          : null,
    );
  }

  TransactionModel copyWith({
    String? id,
    String? title,
    String? note,
    DateTime? date,
    double? amount,
    String? category,
    String? type,
    String? paymentMethod,
    bool? isSplit,
    double? splitTotalAmount,
    double? splitShare,
    int? splitPeopleCount,
    List<String>? splitWith,
    List<String>? splitRequestIds,
  }) {
    return TransactionModel(
      id: id ?? this.id,
      title: title ?? this.title,
      note: note ?? this.note,
      date: date ?? this.date,
      amount: amount ?? this.amount,
      category: category ?? this.category,
      type: type ?? this.type,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      isSplit: isSplit ?? this.isSplit,
      splitTotalAmount: splitTotalAmount ?? this.splitTotalAmount,
      splitShare: splitShare ?? this.splitShare,
      splitPeopleCount: splitPeopleCount ?? this.splitPeopleCount,
      splitWith: splitWith ?? this.splitWith,
      splitRequestIds: splitRequestIds ?? this.splitRequestIds,
    );
  }
}