import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../data/models/app_state.dart';
import '../features/launch/launch_screen.dart';
import '../features/state/providers.dart';
import 'router.dart';
import 'theme.dart';

class ColeggoApp extends ConsumerStatefulWidget {
  const ColeggoApp({super.key});

  @override
  ConsumerState<ColeggoApp> createState() => _ColeggoAppState();
}

class _ColeggoAppState extends ConsumerState<ColeggoApp> {
  GoRouter? _router;
  String? _routerSignature;

  @override
  void dispose() {
    _router?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(appControllerProvider);
    final themeMode = switch (state.themePreference) {
      AppThemePreference.system => ThemeMode.system,
      AppThemePreference.light => ThemeMode.light,
      AppThemePreference.dark => ThemeMode.dark,
    };
    if (state.isLoading) {
      return MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Coleggo',
        theme: ColeggoTheme.light(),
        darkTheme: ColeggoTheme.dark(),
        themeMode: themeMode,
        home: const LaunchScreen(),
      );
    }
    final signature = [
      state.onboardingComplete,
      state.selectedWorkplaceId,
      state.selectedWorksiteId,
      state.workplaceVerified,
      state.setupComplete,
      state.selectedTab,
    ].join('|');
    if (_router == null || _routerSignature != signature) {
      _router?.dispose();
      _router = createRouter(state);
      _routerSignature = signature;
    }
    return MaterialApp.router(
      debugShowCheckedModeBanner: false,
      title: 'Coleggo',
      theme: ColeggoTheme.light(),
      darkTheme: ColeggoTheme.dark(),
      themeMode: themeMode,
      routerConfig: _router,
    );
  }
}
