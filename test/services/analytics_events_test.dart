import 'package:flutter_test/flutter_test.dart';
import 'package:fitup/services/analytics_service.dart';

void main() {
  group('AnalyticsEvents', () {
    test('event names are snake_case GA4-friendly', () {
      expect(AnalyticsEvents.onboardingComplete, 'onboarding_complete');
      expect(AnalyticsEvents.mealLogged, 'meal_logged');
      expect(AnalyticsEvents.workoutCompleted, 'workout_completed');
      expect(AnalyticsEvents.vitalLogged, 'vital_logged');
      expect(AnalyticsEvents.aiInsightViewed, 'ai_insight_viewed');
      expect(AnalyticsEvents.aiChatMessageSent, 'ai_chat_message_sent');
      expect(AnalyticsEvents.subscriptionStarted, 'subscription_started');
      expect(AnalyticsEvents.subscriptionRestored, 'subscription_restored');
      expect(AnalyticsEvents.fitcoinEarned, 'fitcoin_earned');
      expect(AnalyticsEvents.fitcoinRedeemed, 'fitcoin_redeemed');
      expect(AnalyticsEvents.eventJoined, 'event_joined');
      expect(AnalyticsEvents.achievementUnlocked, 'achievement_unlocked');
    });
  });
}
