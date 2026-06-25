import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';

/// Firebase Analytics + Crashlytics facade (Phase 9).
class AnalyticsService {
  AnalyticsService();

  final FirebaseAnalytics _analytics = FirebaseAnalytics.instance;

  Future<void> logEvent(String name, [Map<String, Object>? params]) async {
    try {
      await _analytics.logEvent(
        name: name,
        parameters: params,
      );
    } catch (e, st) {
      if (kDebugMode) {
        debugPrint('AnalyticsService.logEvent $e $st');
      }
    }
  }

  Future<void> setUserId(String? userId) async {
    try {
      await _analytics.setUserId(id: userId);
    } catch (e, st) {
      if (kDebugMode) {
        debugPrint('AnalyticsService.setUserId $e $st');
      }
    }
  }

  Future<void> setUserProperty(String name, String value) async {
    try {
      await _analytics.setUserProperty(name: name, value: value);
    } catch (e, st) {
      if (kDebugMode) {
        debugPrint('AnalyticsService.setUserProperty $e $st');
      }
    }
  }

  Future<void> logScreen(String screenName) async {
    await logEvent('screen_view', <String, Object>{
      'screen_name': screenName,
      'screen_class': screenName,
    });
  }

  Future<void> recordError(
    dynamic exception,
    StackTrace? stack, {
    bool fatal = false,
  }) async {
    if (kIsWeb) {
      return;
    }
    try {
      await FirebaseCrashlytics.instance.recordError(
        exception,
        stack,
        fatal: fatal,
      );
    } catch (e, st) {
      if (kDebugMode) {
        debugPrint('AnalyticsService.recordError $e $st');
      }
    }
  }
}

/// Common Analytics event names (snake_case, ≤40 chars for GA4).
abstract final class AnalyticsEvents {
  static const String onboardingComplete = 'onboarding_complete';
  static const String mealLogged = 'meal_logged';
  static const String workoutCompleted = 'workout_completed';
  static const String vitalLogged = 'vital_logged';
  static const String aiInsightViewed = 'ai_insight_viewed';
  static const String aiChatMessageSent = 'ai_chat_message_sent';
  static const String subscriptionStarted = 'subscription_started';
  static const String subscriptionRestored = 'subscription_restored';
  static const String fitcoinEarned = 'fitcoin_earned';
  static const String fitcoinRedeemed = 'fitcoin_redeemed';
  static const String eventJoined = 'event_joined';
  static const String achievementUnlocked = 'achievement_unlocked';
}
