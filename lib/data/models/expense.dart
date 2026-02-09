import 'package:uuid/uuid.dart';

class Expense {
  final String id;
  final double amount;
  final String categoryId;
  final String? description;
  final DateTime date;
  final DateTime createdAt;

  Expense({
    String? id,
    required this.amount,
    required this.categoryId,
    this.description,
    required this.date,
    DateTime? createdAt,
  })  : id = id ?? const Uuid().v4(),
        createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'amount': amount,
      'category_id': categoryId,
      'description': description,
      'date': date.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory Expense.fromMap(Map<String, dynamic> map) {
    return Expense(
      id: map['id'] as String,
      amount: (map['amount'] as num).toDouble(),
      categoryId: map['category_id'] as String,
      description: map['description'] as String?,
      date: DateTime.parse(map['date'] as String),
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }

  Expense copyWith({
    String? id,
    double? amount,
    String? categoryId,
    String? description,
    DateTime? date,
    DateTime? createdAt,
  }) {
    return Expense(
      id: id ?? this.id,
      amount: amount ?? this.amount,
      categoryId: categoryId ?? this.categoryId,
      description: description ?? this.description,
      date: date ?? this.date,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toJson() => toMap();
  
  factory Expense.fromJson(Map<String, dynamic> json) => Expense.fromMap(json);
}
