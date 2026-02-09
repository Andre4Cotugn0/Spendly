import 'package:uuid/uuid.dart';

/// Frequenza di un abbonamento ricorrente
enum SubscriptionFrequency {
  weekly,
  monthly,
  yearly;

  String get label {
    switch (this) {
      case SubscriptionFrequency.weekly:
        return 'Settimanale';
      case SubscriptionFrequency.monthly:
        return 'Mensile';
      case SubscriptionFrequency.yearly:
        return 'Annuale';
    }
  }

  String get shortLabel {
    switch (this) {
      case SubscriptionFrequency.weekly:
        return '/sett';
      case SubscriptionFrequency.monthly:
        return '/mese';
      case SubscriptionFrequency.yearly:
        return '/anno';
    }
  }
}

class Subscription {
  final String id;
  final String name;
  final double amount;
  final String categoryId;
  final SubscriptionFrequency frequency;
  final DateTime startDate;
  final DateTime? endDate;
  final DateTime nextPaymentDate;
  final bool isActive;
  final String? description;
  final bool reminderEnabled;
  final int reminderDaysBefore;
  final DateTime createdAt;

  Subscription({
    String? id,
    required this.name,
    required this.amount,
    required this.categoryId,
    required this.frequency,
    required this.startDate,
    this.endDate,
    DateTime? nextPaymentDate,
    this.isActive = true,
    this.description,
    this.reminderEnabled = true,
    this.reminderDaysBefore = 1,
    DateTime? createdAt,
  })  : id = id ?? const Uuid().v4(),
        nextPaymentDate = nextPaymentDate ?? startDate,
        createdAt = createdAt ?? DateTime.now();

  /// Costo mensile equivalente
  double get monthlyCost {
    switch (frequency) {
      case SubscriptionFrequency.weekly:
        return amount * 4.33; // ~52 settimane / 12 mesi
      case SubscriptionFrequency.monthly:
        return amount;
      case SubscriptionFrequency.yearly:
        return amount / 12;
    }
  }

  /// Costo annuale equivalente
  double get yearlyCost {
    switch (frequency) {
      case SubscriptionFrequency.weekly:
        return amount * 52;
      case SubscriptionFrequency.monthly:
        return amount * 12;
      case SubscriptionFrequency.yearly:
        return amount;
    }
  }

  /// Calcola la prossima data di pagamento a partire da oggi
  DateTime calculateNextPayment() {
    final now = DateTime.now();
    DateTime next = nextPaymentDate;

    while (next.isBefore(now)) {
      switch (frequency) {
        case SubscriptionFrequency.weekly:
          next = next.add(const Duration(days: 7));
          break;
        case SubscriptionFrequency.monthly:
          next = DateTime(next.year, next.month + 1, next.day);
          break;
        case SubscriptionFrequency.yearly:
          next = DateTime(next.year + 1, next.month, next.day);
          break;
      }
    }
    return next;
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'amount': amount,
      'category_id': categoryId,
      'frequency': frequency.name,
      'start_date': startDate.toIso8601String(),
      'end_date': endDate?.toIso8601String(),
      'next_payment_date': nextPaymentDate.toIso8601String(),
      'is_active': isActive ? 1 : 0,
      'description': description,
      'reminder_enabled': reminderEnabled ? 1 : 0,
      'reminder_days_before': reminderDaysBefore,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory Subscription.fromMap(Map<String, dynamic> map) {
    return Subscription(
      id: map['id'] as String,
      name: map['name'] as String,
      amount: (map['amount'] as num).toDouble(),
      categoryId: map['category_id'] as String,
      frequency: SubscriptionFrequency.values.firstWhere(
        (f) => f.name == map['frequency'],
        orElse: () => SubscriptionFrequency.monthly,
      ),
      startDate: DateTime.parse(map['start_date'] as String),
      endDate: map['end_date'] != null
          ? DateTime.parse(map['end_date'] as String)
          : null,
      nextPaymentDate: DateTime.parse(map['next_payment_date'] as String),
      isActive: (map['is_active'] as int) == 1,
      description: map['description'] as String?,
      reminderEnabled: (map['reminder_enabled'] as int) == 1,
      reminderDaysBefore: (map['reminder_days_before'] as int?) ?? 1,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }

  Subscription copyWith({
    String? id,
    String? name,
    double? amount,
    String? categoryId,
    SubscriptionFrequency? frequency,
    DateTime? startDate,
    DateTime? endDate,
    DateTime? nextPaymentDate,
    bool? isActive,
    String? description,
    bool? reminderEnabled,
    int? reminderDaysBefore,
    DateTime? createdAt,
  }) {
    return Subscription(
      id: id ?? this.id,
      name: name ?? this.name,
      amount: amount ?? this.amount,
      categoryId: categoryId ?? this.categoryId,
      frequency: frequency ?? this.frequency,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      nextPaymentDate: nextPaymentDate ?? this.nextPaymentDate,
      isActive: isActive ?? this.isActive,
      description: description ?? this.description,
      reminderEnabled: reminderEnabled ?? this.reminderEnabled,
      reminderDaysBefore: reminderDaysBefore ?? this.reminderDaysBefore,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toJson() => toMap();
  factory Subscription.fromJson(Map<String, dynamic> json) =>
      Subscription.fromMap(json);
}

/// Servizi di abbonamento suggeriti
class SuggestedSubscriptions {
  static const List<Map<String, dynamic>> suggestions = [
    {'name': 'Netflix', 'amount': 15.99, 'frequency': 'monthly', 'category': 'entertainment'},
    {'name': 'Spotify', 'amount': 10.99, 'frequency': 'monthly', 'category': 'entertainment'},
    {'name': 'Amazon Prime', 'amount': 49.90, 'frequency': 'yearly', 'category': 'shopping'},
    {'name': 'Disney+', 'amount': 8.99, 'frequency': 'monthly', 'category': 'entertainment'},
    {'name': 'YouTube Premium', 'amount': 11.99, 'frequency': 'monthly', 'category': 'entertainment'},
    {'name': 'Apple Music', 'amount': 10.99, 'frequency': 'monthly', 'category': 'entertainment'},
    {'name': 'DAZN', 'amount': 44.99, 'frequency': 'monthly', 'category': 'entertainment'},
    {'name': 'Crunchyroll', 'amount': 4.99, 'frequency': 'monthly', 'category': 'entertainment'},
    {'name': 'iCloud+', 'amount': 0.99, 'frequency': 'monthly', 'category': 'bills'},
    {'name': 'Google One', 'amount': 1.99, 'frequency': 'monthly', 'category': 'bills'},
    {'name': 'PlayStation Plus', 'amount': 59.99, 'frequency': 'yearly', 'category': 'entertainment'},
    {'name': 'Xbox Game Pass', 'amount': 12.99, 'frequency': 'monthly', 'category': 'entertainment'},
    {'name': 'ChatGPT Plus', 'amount': 20.00, 'frequency': 'monthly', 'category': 'bills'},
    {'name': 'Adobe Creative Cloud', 'amount': 62.99, 'frequency': 'monthly', 'category': 'bills'},
    {'name': 'Palestra', 'amount': 30.00, 'frequency': 'monthly', 'category': 'health'},
    {'name': 'TIM', 'amount': 7.99, 'frequency': 'monthly', 'category': 'bills'},
    {'name': 'Vodafone', 'amount': 9.99, 'frequency': 'monthly', 'category': 'bills'},
    {'name': 'Iliad', 'amount': 7.99, 'frequency': 'monthly', 'category': 'bills'},
    {'name': 'WindTre', 'amount': 9.99, 'frequency': 'monthly', 'category': 'bills'},
    {'name': 'Assicurazione Auto', 'amount': 500.00, 'frequency': 'yearly', 'category': 'transport'},
    {'name': 'Bollo Auto', 'amount': 200.00, 'frequency': 'yearly', 'category': 'transport'},
    {'name': 'Affitto', 'amount': 600.00, 'frequency': 'monthly', 'category': 'home'},
  ];

  static List<Map<String, dynamic>> search(String query) {
    if (query.isEmpty) return [];
    final lower = query.toLowerCase();
    return suggestions
        .where((s) => (s['name'] as String).toLowerCase().contains(lower))
        .toList();
  }
}
