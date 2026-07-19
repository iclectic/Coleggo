import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../data/models/app_state.dart';
import '../data/models/ride_request.dart';
import '../features/circles/circle_details_screen.dart';
import '../features/circles/circles_screen.dart';
import '../features/commute/accepted_commute_screen.dart';
import '../features/commute/commute_form_screen.dart';
import '../features/home/home_screen.dart';
import '../features/matches/match_details_screen.dart';
import '../features/matches/matches_screen.dart';
import '../features/matches/request_confirmation_screen.dart';
import '../features/messages/message_thread_screen.dart';
import '../features/notifications/notifications_screen.dart';
import '../features/onboarding/onboarding_screen.dart';
import '../features/profile/profile_screen.dart';
import '../features/profile/profile_setup_screen.dart';
import '../features/profile/settings_safety_screen.dart';
import '../features/requests/requests_screen.dart';
import '../features/shell/app_shell.dart';
import '../features/workplace/verification_screen.dart';
import '../features/workplace/workplace_search_screen.dart';

GoRouter createRouter(AppState state) {
  String setupLocation() => !state.onboardingComplete
      ? '/onboarding'
      : state.selectedWorkplaceId == null
      ? '/workplace'
      : !state.workplaceVerified
      ? '/verify'
      : !state.setupComplete
      ? '/setup'
      : switch (state.selectedTab) {
          1 => '/matches',
          2 => '/circles',
          3 => '/requests',
          4 => '/profile',
          _ => '/home',
        };

  final initialLocation = setupLocation();
  return GoRouter(
    initialLocation: initialLocation,
    redirect: (context, routerState) {
      final location = routerState.matchedLocation;
      final setupRoute = setupLocation();
      final isSetupRoute = {
        '/onboarding',
        '/workplace',
        '/verify',
        '/setup',
      }.contains(location);
      if (!state.setupComplete && location != setupRoute) return setupRoute;
      if (state.setupComplete && isSetupRoute) return '/home';
      return null;
    },
    routes: [
      GoRoute(
        path: '/onboarding',
        builder: (context, state) => const OnboardingScreen(),
      ),
      GoRoute(
        path: '/workplace',
        builder: (context, state) => const WorkplaceSearchScreen(),
      ),
      GoRoute(
        path: '/verify',
        builder: (context, state) => const VerificationScreen(),
      ),
      GoRoute(
        path: '/setup',
        builder: (context, state) => const ProfileSetupScreen(),
      ),
      StatefulShellRoute.indexedStack(
        builder: (context, state, shell) => AppShell(navigationShell: shell),
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/home',
                builder: (context, state) => const HomeScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/matches',
                builder: (context, state) => const MatchesScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/circles',
                builder: (context, state) => const CirclesScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/requests',
                builder: (context, state) => const RequestsScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/profile',
                builder: (context, state) => const ProfileScreen(),
              ),
            ],
          ),
        ],
      ),
      GoRoute(
        path: '/circles/:circleId',
        builder: (context, state) =>
            CircleDetailsScreen(circleId: state.pathParameters['circleId']!),
      ),
      GoRoute(
        path: '/matches/:profileId',
        builder: (context, state) =>
            MatchDetailsScreen(profileId: state.pathParameters['profileId']!),
      ),
      GoRoute(
        path: '/messages/:threadId',
        builder: (context, state) =>
            MessageThreadScreen(threadId: state.pathParameters['threadId']!),
      ),
      GoRoute(
        path: '/notifications',
        builder: (context, state) => const NotificationsScreen(),
      ),
      GoRoute(
        path: '/matches/:profileId/confirm',
        builder: (context, state) => RequestConfirmationScreen(
          profileId: state.pathParameters['profileId']!,
          kind: state.extra as RequestKind? ?? RequestKind.seat,
        ),
      ),
      GoRoute(
        path: '/accepted',
        builder: (context, state) =>
            AcceptedCommuteScreen(requestId: state.extra as String?),
      ),
      GoRoute(
        path: '/commute/edit',
        builder: (context, state) => const CommuteFormScreen(),
      ),
      GoRoute(
        path: '/settings',
        builder: (context, state) => const SettingsScreen(),
      ),
      GoRoute(
        path: '/safety',
        builder: (context, state) => const SafetyScreen(),
      ),
    ],
    errorBuilder: (context, state) => Scaffold(
      appBar: AppBar(title: const Text('Page not found')),
      body: Center(
        child: FilledButton(
          onPressed: () => context.go('/home'),
          child: const Text('Return home'),
        ),
      ),
    ),
  );
}
