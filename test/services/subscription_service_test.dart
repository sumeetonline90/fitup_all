import 'package:fitup/features/profile/domain/entities/profile_enums.dart';
import 'package:fitup/services/subscription_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('StubSubscriptionService yields pro tier', () async {
    final StubSubscriptionService s = StubSubscriptionService();
    final SubscriptionTier tier = await s.watchTier('u1').first;
    expect(tier, SubscriptionTier.pro);
  });

  test('StubSubscriptionService launchSubscriptionFlow returns Right', () async {
    final StubSubscriptionService s = StubSubscriptionService();
    final result = await s.launchSubscriptionFlow();
    expect(result.isRight(), isTrue);
  });
}
