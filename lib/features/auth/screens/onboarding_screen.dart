import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/colors.dart';
import '../../../core/constants/text_styles.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<Map<String, String>> _onboardingData = [
    {
      'emoji': '🎸',
      'title': 'Your Next Gig\nStarts Here',
      'subtitle': 'Connect with clients across the Philippines. Browse gigs, apply, and get booked — all in one place.',
      'description': 'Find gigs. Get hired. Play music.',
    },
    {
      'emoji': '🎤',
      'title': 'Showcase Your\nTalent',
      'subtitle': 'Create your professional profile, upload your portfolio, and let clients discover your musical expertise.',
      'description': 'Build your profile. Get discovered.',
    },
    {
      'emoji': '💰',
      'title': 'Get Paid for\nYour Passion',
      'subtitle': 'Secure payments, clear contracts, and fair rates. Focus on what you love - making music.',
      'description': 'Fair rates. Secure payments.',
    },
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onPageChanged(int page) {
    setState(() {
      _currentPage = page;
    });
  }

  void _nextPage() {
    if (_currentPage < _onboardingData.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      context.go('/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF100C00),
              AppColors.bg,
            ],
            stops: [0.0, 0.7],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: PageView.builder(
                  controller: _pageController,
                  onPageChanged: _onPageChanged,
                  itemCount: _onboardingData.length,
                  itemBuilder: (context, index) {
                    return _buildOnboardingPage(_onboardingData[index]);
                  },
                ),
              ),
              _buildBottomSection(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOnboardingPage(Map<String, String> data) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const Spacer(flex: 1),
          _buildIllustrationCard(data['emoji']!, data['description']!),
          const SizedBox(height: 28),
          _buildHeading(data['title']!),
          const SizedBox(height: 12),
          _buildSubtitle(data['subtitle']!),
          const Spacer(flex: 2),
        ],
      ),
    );
  }

  Widget _buildIllustrationCard(String emoji, String description) {
    return Container(
      width: double.infinity,
      height: 200,
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.border),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Stack(
          children: [
            // Top amber line accent
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: Container(
                height: 1,
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [AppColors.amber, AppColors.copper],
                  ),
                ),
              ),
            ),
            // Centered content
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    emoji,
                    style: const TextStyle(fontSize: 56),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    description,
                    style: AppTextStyles.caption.copyWith(
                      fontSize: 11,
                      letterSpacing: 1.0,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeading(String title) {
    final lines = title.split('\n');
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          lines[0],
          style: AppTextStyles.displayMedium.copyWith(
            color: AppColors.text,
            height: 1.1,
          ),
        ),
        RichText(
          text: TextSpan(
            text: lines.length > 1 ? lines[1] : '',
            style: AppTextStyles.displayMedium.copyWith(
              foreground: Paint()
                ..shader = const LinearGradient(
                  colors: [AppColors.amber, AppColors.copper],
                ).createShader(const Rect.fromLTWH(0, 0, 200, 50)),
              height: 1.1,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSubtitle(String subtitle) {
    return Text(
      subtitle,
      style: AppTextStyles.tagline,
      textAlign: TextAlign.left,
    );
  }

  Widget _buildBottomSection(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      child: Column(
        children: [
          _buildPageIndicators(),
          const SizedBox(height: 20),
          _buildGetStartedButton(context),
          const SizedBox(height: 14),
          _buildLoginLink(context),
          const SizedBox(height: 30),
        ],
      ),
    );
  }

  Widget _buildPageIndicators() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(
        _onboardingData.length,
        (index) => [
          const SizedBox(width: 8),
          Container(
            width: _currentPage == index ? 24 : 8,
            height: 4,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(2),
              gradient: _currentPage == index
                  ? const LinearGradient(
                      colors: [AppColors.amber, AppColors.copper],
                    )
                  : null,
              color: _currentPage == index ? null : AppColors.border,
              boxShadow: _currentPage == index
                  ? [
                      BoxShadow(
                        color: AppColors.amber.withOpacity(0.3),
                        blurRadius: 12,
                        spreadRadius: 0,
                      ),
                    ]
                  : null,
            ),
          ),
        ],
      ).expand((element) => element).skip(1).toList(),
    );
  }

  Widget _buildGetStartedButton(BuildContext context) {
    return GestureDetector(
      onTap: _nextPage,
      child: Container(
        width: double.infinity,
        height: 48,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: const LinearGradient(
            colors: [AppColors.amber, AppColors.copper],
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.amber.withOpacity(0.35),
              blurRadius: 24,
              spreadRadius: 0,
              offset: const Offset(0, 8),
            ),
            const BoxShadow(
              color: Colors.black,
              blurRadius: 16,
              spreadRadius: 0,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Center(
          child: Text(
            _currentPage == _onboardingData.length - 1 ? 'Get Started →' : 'Next →',
            style: AppTextStyles.buttonLarge.copyWith(
              color: AppColors.bg,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLoginLink(BuildContext context) {
    return RichText(
      text: TextSpan(
        text: 'Already have an account? ',
        style: AppTextStyles.bodySmall.copyWith(
          color: AppColors.sub,
          fontSize: 12,
        ),
        children: [
          WidgetSpan(
            child: GestureDetector(
              onTap: () => context.go('/login'),
              child: Text(
                'Log in',
                style: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.amber,
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
