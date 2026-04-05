import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'features/auth/screens/splash_screen.dart';
import 'features/auth/screens/onboarding_screen.dart';
import 'features/auth/screens/login_screen.dart';
import 'features/auth/screens/register_screen.dart';
import 'features/auth/screens/role_select_screen.dart';
import 'features/home/screens/musician_home_screen.dart';
import 'features/gigs/screens/gig_feed_screen.dart';
import 'features/gigs/screens/post_gig_screen.dart';
import 'features/gigs/screens/my_gigs_screen.dart';
import 'features/gigs/screens/gig_detail_screen.dart';
import 'features/applications/screens/applied_screen.dart';
import 'features/applications/screens/applicants_screen.dart';
import 'features/home/screens/client_home_screen.dart';
import 'features/profile/screens/musician_profile_screen.dart';
import 'features/profile/screens/client_profile_screen.dart';
import 'core/theme/app_theme.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const ProviderScope(child: GigSugoApp()));
}

class GigSugoApp extends StatelessWidget {
  const GigSugoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'GigSugo',
      theme: AppTheme.darkTheme,
      routerConfig: _router,
      debugShowCheckedModeBanner: false,
    );
  }
}

final GoRouter _router = GoRouter(
  initialLocation: '/splash',
  routes: [
    GoRoute(
      path: '/splash',
      builder: (context, state) => const SplashScreen(),
    ),
    GoRoute(
      path: '/onboarding',
      builder: (context, state) => const OnboardingScreen(),
    ),
    GoRoute(
      path: '/home',
      builder: (context, state) => const Scaffold(
        body: Center(
          child: Text(
            'Home Screen - Coming Next',
            style: TextStyle(color: Colors.white, fontSize: 24),
          ),
        ),
      ),
    ),
    GoRoute(
      path: '/musician-home',
      builder: (context, state) => const MusicianHomeScreen(),
    ),
    GoRoute(
      path: '/client-home',
      builder: (context, state) => const ClientHomeScreen(),
    ),
    GoRoute(
      path: '/gigs',
      builder: (context, state) => const GigFeedScreen(),
    ),
    GoRoute(
      path: '/gig-detail/:gigId',
      builder: (context, state) {
        final gigId = state.pathParameters['gigId']!;
        return GigDetailScreen(gigId: gigId);
      },
    ),
    GoRoute(
      path: '/post-gig',
      builder: (context, state) => const PostGigScreen(),
    ),
    GoRoute(
      path: '/my-gigs',
      builder: (context, state) => const MyGigsScreen(),
    ),
    GoRoute(
      path: '/applications',
      builder: (context, state) => const AppliedScreen(),
    ),
    GoRoute(
      path: '/applicants/:gigId',
      builder: (context, state) {
        final gigId = state.pathParameters['gigId']!;
        final gigTitle = state.uri.queryParameters['title'] ?? 'Gig';
        return ApplicantsScreen(gigId: gigId, gigTitle: gigTitle);
      },
    ),
    GoRoute(
      path: '/profile',
      builder: (context, state) => const MusicianProfileScreen(),
    ),
    GoRoute(
      path: '/client-profile',
      builder: (context, state) => const ClientProfileScreen(),
    ),
    GoRoute(
      path: '/login',
      builder: (context, state) => const LoginScreen(),
    ),
    GoRoute(
      path: '/register',
      builder: (context, state) => const RegisterScreen(),
    ),
    GoRoute(
      path: '/role-select',
      builder: (context, state) {
        final extra = state.extra as Map<String, dynamic>?;
        return RoleSelectScreen(
          fromSocial: extra?['fromSocial'] as bool? ?? false,
          prefillName: extra?['name'] as String? ?? '',
          prefillEmail: extra?['email'] as String? ?? '',
          uid: extra?['uid'] as String? ?? '',
        );
      },
    ),
  ],
);
