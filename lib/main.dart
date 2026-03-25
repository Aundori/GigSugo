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
import 'core/theme/app_theme.dart';

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
      builder: (context, state) => const Scaffold(
        body: Center(
          child: Text(
            'Client Home - Coming Next',
            style: TextStyle(color: Colors.white, fontSize: 24),
          ),
        ),
      ),
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
