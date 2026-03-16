import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _navigateToNextScreen();
  }

  void _navigateToNextScreen() async {
    await Future.delayed(const Duration(milliseconds: 2500));
    
    if (mounted) {
      // For testing, always go to onboarding
      context.go('/onboarding');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          color: const Color(0xFF07080E),
          gradient: RadialGradient(
            center: Alignment.center,
            radius: 1.2,
            colors: [
              const Color.fromRGBO(245, 166, 35, 0.07),
              Colors.transparent,
            ],
          ),
        ),
        child: const Center(
          child: _WaveformLogo(),
        ),
      ),
    );
  }
}

class _WaveformLogo extends StatelessWidget {
  const _WaveformLogo();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 100,
      height: 100,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFF5A623), Color(0xFFE8863A)],
        ),
      ),
      child: Center(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Bar 1 (leftmost) - short, opacity 0.45
            Container(
              width: 4,
              height: 24,
              decoration: BoxDecoration(
                color: const Color(0xFF07080E).withOpacity(0.45),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            // Bar 2 - medium, opacity 0.70
            Container(
              width: 4,
              height: 40,
              decoration: BoxDecoration(
                color: const Color(0xFF07080E).withOpacity(0.70),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            // Bar 3 (center) - tallest, full opacity, slightly thicker
            Container(
              width: 6,
              height: 60,
              decoration: BoxDecoration(
                color: const Color(0xFF07080E),
                borderRadius: BorderRadius.circular(3),
              ),
            ),
            // Bar 4 - medium, opacity 0.70
            Container(
              width: 4,
              height: 40,
              decoration: BoxDecoration(
                color: const Color(0xFF07080E).withOpacity(0.70),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            // Bar 5 (rightmost) - short, opacity 0.45
            Container(
              width: 4,
              height: 24,
              decoration: BoxDecoration(
                color: const Color(0xFF07080E).withOpacity(0.45),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
