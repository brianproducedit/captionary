import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'theme/app_theme.dart';
import 'providers/engagement_provider.dart';

// Screens
import 'screens/media_library_screen.dart';
import 'screens/language_packs_screen.dart';
import 'screens/studio_screen.dart';
import 'screens/donate_screen.dart';
import 'screens/export_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/transcription_screen.dart';
import 'screens/video_player_screen.dart';
import 'screens/onboarding_screen.dart';

class CaptionaryApp extends ConsumerStatefulWidget {
  const CaptionaryApp({super.key});

  @override
  ConsumerState<CaptionaryApp> createState() => _CaptionaryAppState();
}

class _CaptionaryAppState extends ConsumerState<CaptionaryApp> {
  late final GoRouter _router;

  @override
  void initState() {
    super.initState();

    // Initialize router with initial location based on onboarding state
    final hasSeenOnboarding = ref.read(engagementProvider).hasSeenOnboarding;

    _router = GoRouter(
      initialLocation: hasSeenOnboarding ? '/library' : '/onboarding',
      routes: [
        GoRoute(
          path: '/onboarding',
          pageBuilder: (context, state) => CustomTransitionPage(
            child: const OnboardingScreen(),
            transitionsBuilder:
                (context, animation, secondaryAnimation, child) {
                  return FadeTransition(opacity: animation, child: child);
                },
          ),
        ),
        GoRoute(
          path: '/library',
          pageBuilder: (context, state) => CustomTransitionPage(
            child: const MediaLibraryScreen(),
            transitionsBuilder:
                (context, animation, secondaryAnimation, child) {
                  return FadeTransition(opacity: animation, child: child);
                },
          ),
        ),
        GoRoute(
          path: '/languages',
          pageBuilder: (context, state) => CustomTransitionPage(
            child: const LanguagePacksScreen(),
            transitionsBuilder:
                (context, animation, secondaryAnimation, child) {
                  return FadeTransition(opacity: animation, child: child);
                },
          ),
        ),
        GoRoute(
          path: '/studio',
          pageBuilder: (context, state) {
            final videoPath = state.extra as String? ?? '';
            return CustomTransitionPage(
              child: StudioScreen(videoPath: videoPath),
              transitionsBuilder:
                  (context, animation, secondaryAnimation, child) {
                    return FadeTransition(opacity: animation, child: child);
                  },
            );
          },
        ),
        GoRoute(
          path: '/player',
          pageBuilder: (context, state) {
            final videoPath = state.extra as String? ?? '';
            return CustomTransitionPage(
              child: VideoPlayerScreen(videoPath: videoPath),
              transitionsBuilder:
                  (context, animation, secondaryAnimation, child) {
                    return FadeTransition(opacity: animation, child: child);
                  },
            );
          },
        ),
        GoRoute(
          path: '/donate',
          pageBuilder: (context, state) => CustomTransitionPage(
            child: const DonateScreen(),
            transitionsBuilder:
                (context, animation, secondaryAnimation, child) {
                  return FadeTransition(opacity: animation, child: child);
                },
          ),
        ),
        GoRoute(
          path: '/payment',
          redirect: (context, state) {
            return '/donate';
          },
        ),
        GoRoute(path: '/support', redirect: (context, state) => '/donate'),
        GoRoute(
          path: '/export',
          pageBuilder: (context, state) => CustomTransitionPage(
            child: const ExportScreen(),
            transitionsBuilder:
                (context, animation, secondaryAnimation, child) {
                  return FadeTransition(opacity: animation, child: child);
                },
          ),
        ),
        GoRoute(
          path: '/settings',
          pageBuilder: (context, state) => CustomTransitionPage(
            child: const SettingsScreen(),
            transitionsBuilder:
                (context, animation, secondaryAnimation, child) {
                  return FadeTransition(opacity: animation, child: child);
                },
          ),
        ),
        GoRoute(
          path: '/transcription',
          pageBuilder: (context, state) {
            final videoPath = state.extra as String? ?? '';
            return CustomTransitionPage(
              child: TranscriptionScreen(videoPath: videoPath),
              transitionsBuilder:
                  (context, animation, secondaryAnimation, child) {
                    return FadeTransition(opacity: animation, child: child);
                  },
            );
          },
        ),
      ],
    );

    // Track app open for inactivity nudge scheduling
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(engagementProvider.notifier).onAppOpened();
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Captionary',
      debugShowCheckedModeBanner: false,
      themeMode: ThemeMode.dark,
      theme: AppTheme.darkTheme,
      routerConfig: _router,
    );
  }
}

// Global router definition removed since it is now within the state
