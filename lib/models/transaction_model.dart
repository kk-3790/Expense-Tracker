class TransactionModel {
  final String id;
  final String title;
  final String note;
  final DateTime date;
  final double amount;
  final String category;
  final String type;

  const TransactionModel({
    required this.id,
    required this.title,
    required this.note,
    required this.date,
    required this.amount,
    required this.category,
    required this.type,
  });

  bool get isIncome => type == 'Income';

  bool get isExpense => type == 'Expense';

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'note': note,
      'date': date.toIso8601String(),
      'amount': amount,
      'category': category,
      'type': type,
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
      ) ??
          DateTime.now(),
      amount: map['amount'] is num
          ? (map['amount'] as num).toDouble()
          : double.tryParse(
        map['amount']?.toString() ?? '',
      ) ??
          0,
      category:
      map['category']?.toString() ?? 'Other',
      type: map['type']?.toString() == 'Income'
          ? 'Income'
          : 'Expense',
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
  }) {
    return TransactionModel(
      id: id ?? this.id,
      title: title ?? this.title,
      note: note ?? this.note,
      date: date ?? this.date,
      amount: amount ?? this.amount,
      category: category ?? this.category,
      type: type ?? this.type,
    );
  }
}