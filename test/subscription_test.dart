import 'package:flutter_test/flutter_test.dart';
import 'package:moneyra/data/models/subscription.dart';

void main() {
  test(
    'resolveNextPaymentDate advances monthly subscriptions from past dates',
    () {
      final nextPayment = Subscription.resolveNextPaymentDate(
        startDate: DateTime(2026, 1, 15),
        frequency: SubscriptionFrequency.monthly,
        from: DateTime(2026, 3, 1),
      );

      expect(nextPayment, DateTime(2026, 3, 15));
    },
  );

  test(
    'monthly recurrence clamps end-of-month dates instead of skipping months',
    () {
      final subscription = Subscription(
        name: 'Affitto',
        amount: 600,
        categoryId: 'home',
        frequency: SubscriptionFrequency.monthly,
        startDate: DateTime(2024, 1, 31),
        nextPaymentDate: DateTime(2024, 1, 31),
      );

      final nextPayment = subscription.advancePaymentDate(
        DateTime(2024, 1, 31),
      );

      expect(nextPayment, DateTime(2024, 2, 29));
    },
  );

  test('calculateNextPayment keeps a future payment date unchanged', () {
    final subscription = Subscription(
      name: 'Spotify',
      amount: 10.99,
      categoryId: 'entertainment',
      frequency: SubscriptionFrequency.monthly,
      startDate: DateTime(2026, 2, 20),
      nextPaymentDate: DateTime(2026, 4, 20),
    );

    final nextPayment = subscription.calculateNextPayment(
      from: DateTime(2026, 3, 10),
    );

    expect(nextPayment, DateTime(2026, 4, 20));
  });
}
