import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/activity/domain/entities/activity.dart';
import '../../features/activity/domain/entities/sleep_log.dart';
import '../../features/activity/domain/repositories/activity_repository.dart';
import '../../features/activity/presentation/providers/activity_providers.dart';
import '../../features/activity/presentation/screens/activity_complete_screen.dart';
import '../../features/activity/presentation/screens/activity_detail_screen.dart';
import '../../features/activity/presentation/screens/activity_screen.dart';
import '../../features/activity/presentation/screens/live_tracking_screen.dart';
import '../../features/activity/presentation/widgets/activity_type_selector.dart';
import '../../features/activity/presentation/widgets/sleep_log_sheet.dart';
import '../../features/home/presentation/screens/module_placeholder_screen.dart';
import '../../features/auth/domain/entities/fitup_user.dart';
import '../../features/auth/presentation/providers/auth_providers.dart';
import '../../features/auth/presentation/screens/login_screen.dart';
import '../../features/auth/presentation/screens/register_screen.dart';
import '../../features/diet/domain/entities/meal.dart';
import '../../features/diet/domain/entities/meal_type.dart';
import '../../features/diet/presentation/screens/barcode_scanner_screen.dart';
import '../../features/diet/presentation/screens/diet_screen.dart';
import '../../features/diet/presentation/screens/meal_log_screen.dart';
import '../../features/diet/presentation/screens/photo_meal_screen.dart';
import '../../features/health/presentation/screens/health_screen.dart';
import '../../features/health/presentation/screens/lab_scan_screen.dart';
import '../../features/health/presentation/screens/log_vital_screen.dart';
import '../../features/health/presentation/screens/medication_screen.dart';
import '../../features/health/presentation/screens/menstrual_cycle_screen.dart';
import '../../features/health/presentation/screens/vital_trend_screen.dart';
import '../../features/community/presentation/screens/achievements_screen.dart';
import '../../features/community/presentation/screens/community_events_list_screen.dart';
import '../../features/community/presentation/screens/create_challenge_screen.dart';
import '../../features/community/presentation/screens/create_event_screen.dart';
import '../../features/community/presentation/screens/community_screen.dart';
import '../../features/community/presentation/screens/event_detail_screen.dart';
import '../../features/community/presentation/screens/event_search_screen.dart';
import '../../features/community/presentation/screens/leaderboard_screen.dart';
import '../../features/community/presentation/screens/social_feed_screen.dart';
import '../../features/community/presentation/providers/community_providers.dart';
import '../../features/community/presentation/widgets/achievement_unlock_overlay.dart';
import '../../features/fitcoins/presentation/screens/fitcoin_history_screen.dart';
import '../../features/fitcoins/presentation/screens/fitcoins_wallet_screen.dart';
import '../../features/home/presentation/screens/home_screen.dart';
import '../../features/insights/presentation/screens/ai_chat_screen.dart';
import '../../features/insights/presentation/screens/insights_screen.dart';
import '../../features/insights/presentation/screens/weekly_report_screen.dart';
import '../../features/mental_wellbeing/domain/entities/breathing_pattern.dart';
import '../../features/mental_wellbeing/domain/entities/meditation_sound.dart';
import '../../features/mental_wellbeing/domain/entities/survey_type.dart';
import '../../features/mental_wellbeing/presentation/screens/breathing_screen.dart';
import '../../features/mental_wellbeing/presentation/screens/breathing_session_screen.dart';
import '../../features/mental_wellbeing/presentation/screens/meditation_complete_screen.dart';
import '../../features/mental_wellbeing/presentation/screens/meditation_screen.dart';
import '../../features/mental_wellbeing/presentation/screens/meditation_timer_screen.dart'
    show MeditationTimerRouteExtra, MeditationTimerScreen;
import '../../features/mental_wellbeing/presentation/screens/mental_wellbeing_screen.dart';
import '../../features/mental_wellbeing/presentation/screens/survey_history_screen.dart';
import '../../features/mental_wellbeing/presentation/screens/survey_result_screen.dart';
import '../../features/mental_wellbeing/presentation/screens/survey_screen.dart'
    show SurveyResultExtra, SurveyScreen;
import '../../features/onboarding/presentation/screens/onboarding_screen.dart';
import '../../features/profile/domain/entities/user_profile.dart';
import '../../features/profile/presentation/providers/profile_providers.dart';
import '../../features/profile/presentation/screens/edit_profile_screen.dart';
import '../../features/profile/presentation/screens/profile_screen.dart';
import '../../features/settings/presentation/screens/settings_screen.dart';
import '../../features/settings/presentation/screens/subscription_screen.dart';
import '../../features/workout/domain/entities/workout.dart';
import '../../features/workout/presentation/screens/active_session_screen.dart';
import '../../features/workout/presentation/screens/exercise_detail_screen.dart';
import '../../features/workout/presentation/screens/exercise_library_screen.dart';
import '../../features/workout/presentation/screens/workout_complete_screen.dart';
import '../../features/workout/presentation/screens/workout_history_screen.dart';
import '../../features/workout/presentation/screens/workout_logger_screen.dart';
import '../../features/workout/presentation/screens/workout_plan_generator_screen.dart';
import '../../features/workout/presentation/screens/workout_screen.dart';
import '../../core/di/injection.dart';
import '../../services/analytics_service.dart';
import '../../shared/widgets/app_shell.dart';
import '../../shared/widgets/sidebar_nav.dart';
import 'analytics_navigator_observer.dart';
import 'go_router_refresh.dart';

final GlobalKey<NavigatorState> rootNavigatorKey = GlobalKey<NavigatorState>(
  debugLabel: 'root',
);

final Provider<GoRouter> appRouterProvider = Provider<GoRouter>((Ref ref) {
  final GoRouterRefreshNotifier refresh = GoRouterRefreshNotifier(ref);
  ref.onDispose(refresh.dispose);
  return GoRouter(
    navigatorKey: rootNavigatorKey,
    initialLocation: '/loading',
    refreshListenable: refresh,
    observers: getIt.isRegistered<AnalyticsService>()
        ? <NavigatorObserver>[
            FitupAnalyticsNavigatorObserver(getIt<AnalyticsService>()),
          ]
        : const <NavigatorObserver>[],
    redirect: (BuildContext context, GoRouterState state) {
      final AsyncValue<FitupUser?> auth = ref.read(authStateProvider);
      final String loc = state.matchedLocation;
      final bool loggingIn = loc == '/login' || loc == '/register';
      final bool loadingRoute = loc == '/loading';
      final bool isLoggedIn = auth.maybeWhen(
        data: (FitupUser? u) => u != null,
        orElse: () => false,
      );
      if (auth.isLoading) {
        return '/loading';
      }
      if (!isLoggedIn && !loggingIn) {
        return '/login';
      }
      if (!isLoggedIn) {
        if (loadingRoute) {
          return '/login';
        }
        return null;
      }
      if (kIsWeb && loc.contains('/activity/live')) {
        return '/activity';
      }
      if (loc == '/profile/settings') {
        return '/settings';
      }
      final AsyncValue<UserProfile> prof = ref.read(userProfileProvider);
      if (prof.isLoading) {
        return null;
      }
      final UserProfile? p = prof.value;
      final bool onboardingComplete = p?.onboardingComplete ?? false;
      if (!onboardingComplete) {
        if (loggingIn) {
          return '/onboarding';
        }
        if (loc != '/onboarding') {
          return '/onboarding';
        }
        return null;
      }
      if (onboardingComplete && loc == '/onboarding') {
        return '/home';
      }
      if (isLoggedIn && (loggingIn || loadingRoute)) {
        return '/home';
      }
      return null;
    },
    routes: <RouteBase>[
      GoRoute(
        path: '/loading',
        builder: (BuildContext context, GoRouterState state) =>
            const Scaffold(body: Center(child: CircularProgressIndicator())),
      ),
      GoRoute(
        path: '/login',
        builder: (BuildContext context, GoRouterState state) =>
            const LoginScreen(),
      ),
      GoRoute(
        path: '/register',
        builder: (BuildContext context, GoRouterState state) =>
            const RegisterScreen(),
      ),
      GoRoute(
        path: '/activity/start',
        builder: (BuildContext context, GoRouterState state) =>
            const _ActivityStartRoute(),
      ),
      GoRoute(
        path: '/activity/live/:type',
        builder: (BuildContext context, GoRouterState state) {
          final String raw = state.pathParameters['type'] ?? 'run';
          return LiveTrackingScreen(initialType: _parseActivityTypeParam(raw));
        },
      ),
      GoRoute(
        path: '/activity/complete',
        parentNavigatorKey: rootNavigatorKey,
        pageBuilder: (BuildContext context, GoRouterState state) =>
            _slideUpTransitionPage(
              state,
              _resolveActivityCompletePage(ref, state),
            ),
      ),
      GoRoute(
        path: '/activity/sleep',
        builder: (BuildContext context, GoRouterState state) =>
            const _ActivitySleepRoute(),
      ),
      GoRoute(
        path: '/coming-soon',
        builder: (BuildContext context, GoRouterState state) {
          final String title = state.uri.queryParameters['m'] ?? 'Module';
          return ModulePlaceholderScreen(title: title);
        },
      ),
      GoRoute(
        path: '/onboarding',
        pageBuilder: (BuildContext context, GoRouterState state) =>
            _slideUpTransitionPage(state, const OnboardingScreen()),
      ),
      GoRoute(
        path: '/settings',
        pageBuilder: (BuildContext context, GoRouterState state) =>
            _slideRightTransitionPage(state, const SettingsScreen()),
      ),
      GoRoute(
        path: '/subscription',
        pageBuilder: (BuildContext context, GoRouterState state) =>
            _slideRightTransitionPage(state, const SubscriptionScreen()),
      ),
      GoRoute(
        path: '/profile',
        builder: (BuildContext context, GoRouterState state) =>
            const ProfileScreen(),
        routes: <RouteBase>[
          GoRoute(
            path: 'edit',
            pageBuilder: (BuildContext context, GoRouterState state) =>
                _slideRightTransitionPage(state, const EditProfileScreen()),
          ),
        ],
      ),
      GoRoute(
        path: '/insights',
        builder: (BuildContext context, GoRouterState state) =>
            const InsightsScreen(),
        routes: <RouteBase>[
          GoRoute(
            path: 'chat',
            builder: (BuildContext context, GoRouterState state) {
              return AiChatScreen(
                initialModuleContext: _moduleContextFromExtra(state.extra),
              );
            },
          ),
          GoRoute(
            path: 'weekly-report',
            builder: (BuildContext context, GoRouterState state) =>
                const WeeklyReportScreen(),
          ),
        ],
      ),
      StatefulShellRoute.indexedStack(
        builder:
            (
              BuildContext context,
              GoRouterState state,
              StatefulNavigationShell navigationShell,
            ) {
              return AchievementUnlockHost(
                child: _MainShell(navigationShell: navigationShell),
              );
            },
        branches: <StatefulShellBranch>[
          StatefulShellBranch(
            routes: <RouteBase>[
              GoRoute(
                path: '/home',
                builder: (BuildContext context, GoRouterState state) =>
                    const HomeScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: <RouteBase>[
              GoRoute(
                path: '/activity',
                builder: (BuildContext context, GoRouterState state) =>
                    const ActivityScreen(),
                routes: <RouteBase>[
                  GoRoute(
                    path: 'session',
                    parentNavigatorKey: rootNavigatorKey,
                    pageBuilder: (BuildContext context, GoRouterState state) {
                      final Activity? activity =
                          _resolveActivityFromRouteState(ref, state);
                      return _slideRightTransitionPage(
                        state,
                        activity != null
                            ? ActivityDetailScreen(activity: activity)
                            : const ModulePlaceholderScreen(
                                title: 'Activity summary',
                              ),
                      );
                    },
                  ),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            routes: <RouteBase>[
              GoRoute(
                path: '/diet',
                builder: (BuildContext context, GoRouterState state) =>
                    const DietScreen(),
                routes: <RouteBase>[
                  GoRoute(
                    path: 'log/:mealType',
                    builder: (BuildContext context, GoRouterState state) {
                      final MealType t = mealTypeFromRouteParam(
                        state.pathParameters['mealType'],
                      );
                      Meal? existing;
                      List<String> superseded = const <String>[];
                      final Object? extra = state.extra;
                      if (extra is MealLogRouteExtra) {
                        existing = extra.meal;
                        superseded = extra.supersededMealIds;
                      } else if (extra is Meal) {
                        existing = extra;
                      }
                      return MealLogScreen(
                        initialMealType: t,
                        existingMeal: existing,
                        supersededMealIds: superseded,
                      );
                    },
                  ),
                  GoRoute(
                    path: 'scan',
                    builder: (BuildContext context, GoRouterState state) {
                      final MealType t = mealTypeFromRouteParam(
                        state.uri.queryParameters['mealType'],
                      );
                      return BarcodeScannerScreen(mealType: t);
                    },
                  ),
                  GoRoute(
                    path: 'photo/:mealType',
                    builder: (BuildContext context, GoRouterState state) {
                      final MealType t = mealTypeFromRouteParam(
                        state.pathParameters['mealType'],
                      );
                      return PhotoMealScreen(mealType: t);
                    },
                  ),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            routes: <RouteBase>[
              GoRoute(
                path: '/workout',
                builder: (BuildContext context, GoRouterState state) =>
                    const WorkoutScreen(),
                routes: <RouteBase>[
                  GoRoute(
                    path: 'plan/generate',
                    builder: (BuildContext context, GoRouterState state) =>
                        const WorkoutPlanGeneratorScreen(),
                  ),
                  GoRoute(
                    path: 'session/:sessionId',
                    builder: (BuildContext context, GoRouterState state) {
                      final String id = state.pathParameters['sessionId'] ?? '';
                      return ActiveSessionScreen(sessionId: id);
                    },
                  ),
                  GoRoute(
                    path: 'complete',
                    builder: (BuildContext context, GoRouterState state) {
                      final Object? extra = state.extra;
                      if (extra is! WorkoutLog) {
                        return const WorkoutScreen();
                      }
                      return WorkoutCompleteScreen(log: extra);
                    },
                  ),
                  GoRoute(
                    path: 'exercises',
                    builder: (BuildContext context, GoRouterState state) =>
                        const ExerciseLibraryScreen(),
                    routes: <RouteBase>[
                      GoRoute(
                        path: ':exerciseId',
                        builder: (BuildContext context, GoRouterState state) {
                          final String id =
                              state.pathParameters['exerciseId'] ?? '';
                          return ExerciseDetailScreen(exerciseId: id);
                        },
                      ),
                    ],
                  ),
                  GoRoute(
                    path: 'history',
                    builder: (BuildContext context, GoRouterState state) =>
                        const WorkoutHistoryScreen(),
                  ),
                  GoRoute(
                    path: 'log-custom',
                    builder: (BuildContext context, GoRouterState state) =>
                        const WorkoutLoggerScreen(),
                  ),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            routes: <RouteBase>[
              GoRoute(
                path: '/health',
                builder: (BuildContext context, GoRouterState state) =>
                    const HealthScreen(),
                routes: <RouteBase>[
                  GoRoute(
                    path: 'vitals/log',
                    builder: (BuildContext context, GoRouterState state) =>
                        const LogVitalScreen(),
                  ),
                  GoRoute(
                    path: 'vitals/:type',
                    builder: (BuildContext context, GoRouterState state) {
                      final String? raw = state.pathParameters['type'];
                      return VitalTrendScreen(
                        type: vitalTypeFromPathParam(raw),
                      );
                    },
                  ),
                  GoRoute(
                    path: 'lab-scan',
                    builder: (BuildContext context, GoRouterState state) =>
                        const LabScanScreen(),
                  ),
                  GoRoute(
                    path: 'medications',
                    builder: (BuildContext context, GoRouterState state) =>
                        const MedicationScreen(),
                  ),
                  GoRoute(
                    path: 'menstrual',
                    builder: (BuildContext context, GoRouterState state) =>
                        const MenstrualCycleScreen(),
                  ),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            routes: <RouteBase>[
              GoRoute(
                path: '/mental',
                builder: (BuildContext context, GoRouterState state) =>
                    const MentalWellbeingScreen(),
                routes: <RouteBase>[
                  GoRoute(
                    path: 'survey-history',
                    builder: (BuildContext context, GoRouterState state) =>
                        const SurveyHistoryScreen(),
                  ),
                  GoRoute(
                    path: 'survey/result',
                    builder: (BuildContext context, GoRouterState state) {
                      final Object? extra = state.extra;
                      if (extra is! SurveyResultExtra) {
                        return const MentalWellbeingScreen();
                      }
                      return SurveyResultScreen(extra: extra);
                    },
                  ),
                  GoRoute(
                    path: 'survey/:type',
                    builder: (BuildContext context, GoRouterState state) {
                      final SurveyType? t = surveyTypeFromParam(
                        state.pathParameters['type'],
                      );
                      if (t == null) {
                        return const MentalWellbeingScreen();
                      }
                      return SurveyScreen(type: t);
                    },
                  ),
                  GoRoute(
                    path: 'breathing',
                    builder: (BuildContext context, GoRouterState state) =>
                        const BreathingScreen(),
                  ),
                  GoRoute(
                    path: 'breathing/session',
                    builder: (BuildContext context, GoRouterState state) {
                      final Object? extra = state.extra;
                      final BreathingPattern pattern = extra is BreathingPattern
                          ? extra
                          : breathingPatternFromName(
                                  state.uri.queryParameters['pattern'],
                                ) ??
                                BreathingPattern.box478;
                      return BreathingSessionScreen(pattern: pattern);
                    },
                  ),
                  GoRoute(
                    path: 'meditation',
                    builder: (BuildContext context, GoRouterState state) =>
                        const MeditationScreen(),
                  ),
                  GoRoute(
                    path: 'meditation/timer',
                    builder: (BuildContext context, GoRouterState state) {
                      final Object? extra = state.extra;
                      if (extra is MeditationTimerRouteExtra) {
                        return MeditationTimerScreen(
                          totalSeconds: extra.totalSeconds,
                          sound: extra.sound,
                        );
                      }
                      final int mins =
                          int.tryParse(
                            state.uri.queryParameters['minutes'] ?? '5',
                          ) ??
                          5;
                      final MeditationSound sound = meditationSoundFromName(
                        state.uri.queryParameters['sound'],
                      );
                      return MeditationTimerScreen(
                        totalSeconds: mins * 60,
                        sound: sound,
                      );
                    },
                  ),
                  GoRoute(
                    path: 'meditation/complete',
                    builder: (BuildContext context, GoRouterState state) {
                      final int mins =
                          int.tryParse(
                            state.uri.queryParameters['minutes'] ?? '5',
                          ) ??
                          5;
                      return MeditationCompleteScreen(minutes: mins);
                    },
                  ),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            routes: <RouteBase>[
              GoRoute(
                path: '/community',
                builder: (BuildContext context, GoRouterState state) =>
                    const CommunityScreen(),
                routes: <RouteBase>[
                  GoRoute(
                    path: 'wallet',
                    builder: (BuildContext context, GoRouterState state) =>
                        const FitcoinsWalletScreen(),
                    routes: <RouteBase>[
                      GoRoute(
                        path: 'history',
                        builder: (BuildContext context, GoRouterState state) =>
                            const FitcoinHistoryScreen(),
                      ),
                    ],
                  ),
                  GoRoute(
                    path: 'shop',
                    builder: (BuildContext context, GoRouterState state) =>
                        const ModulePlaceholderScreen(
                          title: 'Fitcoins Shop — Coming Soon',
                        ),
                  ),
                  GoRoute(
                    path: 'leaderboard',
                    builder: (BuildContext context, GoRouterState state) =>
                        const LeaderboardScreen(),
                  ),
                  GoRoute(
                    path: 'feed',
                    builder: (BuildContext context, GoRouterState state) =>
                        const SocialFeedScreen(),
                  ),
                  GoRoute(
                    path: 'achievements',
                    builder: (BuildContext context, GoRouterState state) =>
                        const AchievementsScreen(),
                  ),
                  GoRoute(
                    path: 'challenges/create',
                    builder: (BuildContext context, GoRouterState state) =>
                        const CreateChallengeScreen(),
                  ),
                  GoRoute(
                    path: 'events',
                    builder: (BuildContext context, GoRouterState state) =>
                        const CommunityEventsListScreen(),
                    routes: <RouteBase>[
                      GoRoute(
                        path: 'create',
                        builder: (BuildContext context, GoRouterState state) =>
                            const CreateEventScreen(),
                      ),
                      GoRoute(
                        path: 'search',
                        builder: (BuildContext context, GoRouterState state) =>
                            const EventSearchScreen(),
                      ),
                      GoRoute(
                        path: ':eventId',
                        builder: (BuildContext context, GoRouterState state) {
                          final String id =
                              state.pathParameters['eventId'] ?? '';
                          return EventDetailScreen(eventId: id);
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    ],
  );
});

class _MainShell extends ConsumerWidget {
  const _MainShell({required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  static const List<String> _moduleLabels = <String>[
    'Home',
    'Activity',
    'Diet',
    'Workout',
    'Health',
    'Mental',
    'Community',
  ];

  static final List<SidebarNavEntry> _navEntries = <SidebarNavEntry>[
    SidebarNavEntry(
      path: '/home',
      iconOutlined: Icons.home_outlined,
      iconFilled: Icons.home,
      label: 'Home',
      semanticLabel: 'Home',
      sectionLabel: 'Main',
    ),
    SidebarNavEntry(
      path: '/activity',
      iconOutlined: Icons.directions_run_outlined,
      iconFilled: Icons.directions_run,
      label: 'Activity',
      semanticLabel: 'Activity',
    ),
    SidebarNavEntry(
      path: '/diet',
      iconOutlined: Icons.restaurant_outlined,
      iconFilled: Icons.restaurant,
      label: 'Diet',
      semanticLabel: 'Diet',
    ),
    SidebarNavEntry(
      path: '/workout',
      iconOutlined: Icons.fitness_center_outlined,
      iconFilled: Icons.fitness_center,
      label: 'Workout',
      semanticLabel: 'Workout',
    ),
    SidebarNavEntry(
      path: '/health',
      iconOutlined: Icons.favorite_border_outlined,
      iconFilled: Icons.favorite,
      label: 'Health',
      semanticLabel: 'Health & Vitals',
    ),
    SidebarNavEntry(
      path: '/mental',
      iconOutlined: Icons.self_improvement_outlined,
      iconFilled: Icons.self_improvement,
      label: 'Mental',
      semanticLabel: 'Mental Wellbeing',
    ),
    SidebarNavEntry(
      path: '/community',
      iconOutlined: Icons.groups_outlined,
      iconFilled: Icons.groups,
      label: 'Community',
      semanticLabel: 'Community',
      sectionLabel: 'Community',
    ),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<int> badgeAsync = ref.watch(communityTabBadgeProvider);
    final int badgeCount = badgeAsync.value ?? 0;

    return AppShell(
      navigationShell: navigationShell,
      navEntries: _navEntries,
      moduleLabelForIndex: (int i) =>
          i >= 0 && i < _moduleLabels.length ? _moduleLabels[i] : 'Home',
      communityBadgeCount: badgeCount,
    );
  }
}

Activity? _resolveActivityFromRouteState(Ref ref, GoRouterState state) {
  final Object? extra = state.extra;
  if (extra is Activity) {
    return extra;
  }
  if (extra is Map<String, dynamic>) {
    final Activity? fromMap = extra['activity'] as Activity?;
    if (fromMap != null) {
      return fromMap;
    }
  }
  return ref.read(selectedActivityDetailProvider) ??
      ref.read(lastActivitySessionResultProvider)?.activity;
}

Widget _resolveActivityCompletePage(Ref ref, GoRouterState state) {
  final Object? extra = state.extra;
  Activity? activity;
  int fitcoins = 0;
  if (extra is Map<String, dynamic>) {
    activity = extra['activity'] as Activity?;
    fitcoins = (extra['fitcoins'] as int?) ?? 0;
  } else if (extra is Activity) {
    activity = extra;
  }
  final ActivitySessionResult? held = ref.read(lastActivitySessionResultProvider);
  activity ??= held?.activity;
  if (fitcoins <= 0) {
    fitcoins = held?.fitcoinsEarned ?? 0;
  }
  if (activity != null) {
    return ActivityCompleteScreen(
      activity: activity,
      fitcoinsEarned: fitcoins,
    );
  }
  return const ModulePlaceholderScreen(title: 'Activity');
}

CustomTransitionPage<void> _slideUpTransitionPage(
  GoRouterState state,
  Widget page,
) {
  return CustomTransitionPage<void>(
    key: state.pageKey,
    child: page,
    transitionsBuilder:
        (
          BuildContext context,
          Animation<double> animation,
          Animation<double> secondaryAnimation,
          Widget child,
        ) {
          return SlideTransition(
            position: Tween<Offset>(begin: const Offset(0, 1), end: Offset.zero)
                .animate(
                  CurvedAnimation(
                    parent: animation,
                    curve: Curves.easeOutCubic,
                  ),
                ),
            child: child,
          );
        },
  );
}

CustomTransitionPage<void> _slideRightTransitionPage(
  GoRouterState state,
  Widget page,
) {
  return CustomTransitionPage<void>(
    key: state.pageKey,
    child: page,
    transitionsBuilder:
        (
          BuildContext context,
          Animation<double> animation,
          Animation<double> secondaryAnimation,
          Widget child,
        ) {
          return SlideTransition(
            position: Tween<Offset>(begin: const Offset(1, 0), end: Offset.zero)
                .animate(
                  CurvedAnimation(
                    parent: animation,
                    curve: Curves.easeOutCubic,
                  ),
                ),
            child: child,
          );
        },
  );
}

String? _moduleContextFromExtra(Object? extra) {
  if (extra is Map<dynamic, dynamic>) {
    final Object? m = extra['moduleContext'];
    if (m is String) {
      return m;
    }
  }
  return null;
}

ActivityType _parseActivityTypeParam(String raw) {
  final String lower = raw.toLowerCase();
  for (final ActivityType t in ActivityType.values) {
    if (t.name == lower) {
      return t;
    }
  }
  return ActivityType.run;
}

/// Opens [showActivityTypeSelector] then pops unless user navigated to live.
class _ActivityStartRoute extends StatefulWidget {
  const _ActivityStartRoute();

  @override
  State<_ActivityStartRoute> createState() => _ActivityStartRouteState();
}

class _ActivityStartRouteState extends State<_ActivityStartRoute> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) {
        return;
      }
      if (kIsWeb) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'GPS live tracking is available on the mobile app only.',
            ),
          ),
        );
        context.pop();
        return;
      }
      bool navigated = false;
      await showActivityTypeSelector(
        context,
        onActivitySelected: (ActivityType type) {
          navigated = true;
          context.go('/activity/live/${type.name}');
        },
      );
      if (mounted && !navigated) {
        context.pop();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return const ColoredBox(
      color: Colors.transparent,
      child: SizedBox.expand(),
    );
  }
}

/// Opens [showSleepLogSheet] then pops.
class _ActivitySleepRoute extends StatefulWidget {
  const _ActivitySleepRoute();

  @override
  State<_ActivitySleepRoute> createState() => _ActivitySleepRouteState();
}

class _ActivitySleepRouteState extends State<_ActivitySleepRoute> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) {
        return;
      }
      await showSleepLogSheet(
        context,
        onSave: (DateTime start, DateTime end, int qualityStars) async {
          final FitupUser? user = ProviderScope.containerOf(
            context,
            listen: false,
          ).read(authStateProvider).value;
          if (user == null) {
            return;
          }
          final SleepLog log = SleepLog(
            id: '${user.id}_${DateTime.now().millisecondsSinceEpoch}_manual_sleep',
            userId: user.id,
            bedtime: start,
            wakeTime: end,
            durationMinutes: end.difference(start).inMinutes,
            quality: qualityStars.toDouble(),
            source: 'manual',
          );
          await getIt<ActivityRepository>().saveSleepLog(log);
        },
      );
      if (mounted) {
        context.pop();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return const ColoredBox(
      color: Colors.transparent,
      child: SizedBox.expand(),
    );
  }
}
