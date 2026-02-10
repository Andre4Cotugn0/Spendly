import 'package:uuid/uuid.dart';

/// Tipo di debito: devo a qualcuno oppure qualcuno deve a me
enum DebtType {
  iOwe,    // Io devo a qualcuno
  owedToMe; // Qualcuno deve a me

  String get label {
    switch (this) {
      case DebtType.iOwe:
        return 'Devo';
      case DebtType.owedToMe:
        return 'Mi devono';
    }
  }

  String get emoji {
    switch (this) {
      case DebtType.iOwe:
        return '📤';
      case DebtType.owedToMe:
        return '📥';
    }
  }
}

class Debt {
  final String id;
  final String personName;
  final double amount;
  final double amountPaid;
  final DebtType type;
  final String? description;
  final DateTime date;
  final DateTime? dueDate;
  final bool isSettled;
  final DateTime createdAt;

  Debt({
    String? id,
    required this.personName,
    required this.amount,
    this.amountPaid = 0.0,
    required this.type,
    this.description,
    required this.date,
    this.dueDate,
    this.isSettled = false,
    DateTime? createdAt,
  })  : id = id ?? const Uuid().v4(),
        createdAt = createdAt ?? DateTime.now();

  /// Importo rimanente da saldare
  double get remaining => amount - amountPaid;

  /// Percentuale saldata
  double get paidPercentage => amount > 0 ? (amountPaid / amount).clamp(0.0, 1.0) : 0.0;

  /// Se è scaduto (ha una scadenza e non è saldato)
  bool get isOverdue =>
      !isSettled && dueDate != null && dueDate!.isBefore(DateTime.now());

  /// Giorni alla scadenza (negativo se scaduto)
  int? get daysUntilDue =>
      dueDate?.difference(DateTime.now()).inDays;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'person_name': personName,
      'amount': amount,
      'amount_paid': amountPaid,
      'type': type.name,
      'description': description,
      'date': date.toIso8601String(),
      'due_date': dueDate?.toIso8601String(),
      'is_settled': isSettled ? 1 : 0,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory Debt.fromMap(Map<String, dynamic> map) {
    return Debt(
      id: map['id'] as String,
      personName: map['person_name'] as String,
      amount: (map['amount'] as num).toDouble(),
      amountPaid: (map['amount_paid'] as num?)?.toDouble() ?? 0.0,
      type: DebtType.values.firstWhere(
        (t) => t.name == map['type'],
        orElse: () => DebtType.iOwe,
      ),
      description: map['description'] as String?,
      date: DateTime.parse(map['date'] as String),
      dueDate: map['due_date'] != null
          ? DateTime.parse(map['due_date'] as String)
          : null,
      isSettled: (map['is_settled'] as int) == 1,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }

  Debt copyWith({
    String? id,
    String? personName,
    double? amount,
    double? amountPaid,
    DebtType? type,
    String? description,
    DateTime? date,
    DateTime? dueDate,
    bool? isSettled,
    DateTime? createdAt,
  }) {
    return Debt(
      id: id ?? this.id,
      personName: personName ?? this.personName,
      amount: amount ?? this.amount,
      amountPaid: amountPaid ?? this.amountPaid,
      type: type ?? this.type,
      description: description ?? this.description,
      date: date ?? this.date,
      dueDate: dueDate ?? this.dueDate,
      isSettled: isSettled ?? this.isSettled,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toJson() => toMap();
  factory Debt.fromJson(Map<String, dynamic> json) => Debt.fromMap(json);
}
