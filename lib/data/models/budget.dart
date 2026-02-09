import 'package:uuid/uuid.dart';

class Budget {
  final String id;
  final String? categoryId; // null = budget globale mensile
  final double amount;
  final int month;
  final int year;
  final DateTime createdAt;

  Budget({
    String? id,
    this.categoryId,
    required this.amount,
    required this.month,
    required this.year,
    DateTime? createdAt,
  })  : id = id ?? const Uuid().v4(),
        createdAt = createdAt ?? DateTime.now();

  /// Percentuale spesa rispetto al budget (0.0 - 1.0+)
  double spentPercentage(double spent) {
    if (amount <= 0) return 0;
    return spent / amount;
  }

  /// Importo rimanente
  double remaining(double spent) {
    return amount - spent;
  }

  /// Se il budget è stato superato
  bool isExceeded(double spent) => spent > amount;

  /// Se il budget è quasi esaurito (>= 80%)
  bool isWarning(double spent) => spent >= amount * 0.8;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'category_id': categoryId,
      'amount': amount,
      'month': month,
      'year': year,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory Budget.fromMap(Map<String, dynamic> map) {
    return Budget(
      id: map['id'] as String,
      categoryId: map['category_id'] as String?,
      amount: (map['amount'] as num).toDouble(),
      month: map['month'] as int,
      year: map['year'] as int,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }

  Budget copyWith({
    String? id,
    String? categoryId,
    double? amount,
    int? month,
    int? year,
    DateTime? createdAt,
  }) {
    return Budget(
      id: id ?? this.id,
      categoryId: categoryId ?? this.categoryId,
      amount: amount ?? this.amount,
      month: month ?? this.month,
      year: year ?? this.year,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toJson() => toMap();
  factory Budget.fromJson(Map<String, dynamic> json) => Budget.fromMap(json);
}
