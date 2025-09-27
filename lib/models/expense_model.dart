class Expense {
  final String id;
  final String title;
  final String description;
  final double amount;
  final String currency;
  final String groupId;
  final String paidBy;
  final List<String> splitBetween;
  final Map<String, double>? customSplit;
  final String category;
  final DateTime date;
  final DateTime createdAt;
  final List<String>? attachments;
  final bool isSettled;

  Expense({
    required this.id,
    required this.title,
    required this.description,
    required this.amount,
    this.currency = 'USD',
    required this.groupId,
    required this.paidBy,
    required this.splitBetween,
    this.customSplit,
    this.category = 'General',
    required this.date,
    required this.createdAt,
    this.attachments,
    this.isSettled = false,
  });

  factory Expense.fromMap(Map<String, dynamic> map) {
    return Expense(
      id: map['id'] ?? '',
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      amount: (map['amount'] ?? 0).toDouble(),
      currency: map['currency'] ?? 'USD',
      groupId: map['groupId'] ?? '',
      paidBy: map['paidBy'] ?? '',
      splitBetween: List<String>.from(map['splitBetween'] ?? []),
      customSplit: map['customSplit'] != null
          ? Map<String, double>.from(map['customSplit'])
          : null,
      category: map['category'] ?? 'General',
      date: DateTime.parse(map['date']),
      createdAt: DateTime.parse(map['createdAt']),
      attachments: map['attachments'] != null
          ? List<String>.from(map['attachments'])
          : null,
      isSettled: map['isSettled'] ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'amount': amount,
      'currency': currency,
      'groupId': groupId,
      'paidBy': paidBy,
      'splitBetween': splitBetween,
      'customSplit': customSplit,
      'category': category,
      'date': date.toIso8601String(),
      'createdAt': createdAt.toIso8601String(),
      'attachments': attachments,
      'isSettled': isSettled,
    };
  }

  double getAmountPerPerson() {
    if (customSplit != null) {
      return customSplit!.values.fold(0.0, (sum, amount) => sum + amount) / customSplit!.length;
    }
    return amount / splitBetween.length;
  }

  double getAmountForUser(String userId) {
    if (customSplit != null && customSplit!.containsKey(userId)) {
      return customSplit![userId]!;
    }
    return splitBetween.contains(userId) ? getAmountPerPerson() : 0.0;
  }

  Expense copyWith({
    String? id,
    String? title,
    String? description,
    double? amount,
    String? currency,
    String? groupId,
    String? paidBy,
    List<String>? splitBetween,
    Map<String, double>? customSplit,
    String? category,
    DateTime? date,
    DateTime? createdAt,
    List<String>? attachments,
    bool? isSettled,
  }) {
    return Expense(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      amount: amount ?? this.amount,
      currency: currency ?? this.currency,
      groupId: groupId ?? this.groupId,
      paidBy: paidBy ?? this.paidBy,
      splitBetween: splitBetween ?? this.splitBetween,
      customSplit: customSplit ?? this.customSplit,
      category: category ?? this.category,
      date: date ?? this.date,
      createdAt: createdAt ?? this.createdAt,
      attachments: attachments ?? this.attachments,
      isSettled: isSettled ?? this.isSettled,
    );
  }
}