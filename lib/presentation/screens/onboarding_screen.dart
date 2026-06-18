import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/glass_card.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<Map<String, String>> _slides = [
    {
      'title': 'ELITE ENTREPRENEUR NETWORK',
      'subtitle': 'Collab & scale with India\'s top high-performance founders. Real peer benchmarks, zero noise.',
      'icon': '🤝',
      'accentText': 'QAFIYA ECOSYSTEM',
    },
    {
      'title': 'BUSINESS INTELLIGENCE PLATFORM',
      'subtitle': 'Consolidate revenue charts, cod settlements, multi-warehouse inventory, and courier routes in one dashboard.',
      'icon': '📊',
      'accentText': 'ENTERPRISE OPERATIONS',
    },
    {
      'title': 'AI-POWERED GROWTH ENGINE',
      'subtitle': 'Deploy automated stock alerts, run predictive analytics, and receive optimization suggestions from Qaafiya AI.',
      'icon': '⚡',
      'accentText': 'INTELLIGENT DECISIONS',
    },
  ];

  Future<void> _completeOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('onboarding_done', true);
    if (mounted) {
      context.go('/dashboard');
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppTheme.darkBackground : AppTheme.lightBackground,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
          child: Column(
            children: [
              // Top logo/brand
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Image.asset(
                    'assets/images/logo.png',
                    height: 32,
                    fit: BoxFit.contain,
                  ),
                  TextButton(
                    onPressed: _completeOnboarding,
                    child: Text(
                      'SKIP',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.5,
                        color: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary,
                      ),
                    ),
                  )
                ],
              ),
              
              const Spacer(),
              
              // Slide details
              SizedBox(
                height: size.height * 0.52,
                child: PageView.builder(
                  controller: _pageController,
                  onPageChanged: (int page) {
                    setState(() {
                      _currentPage = page;
                    });
                  },
                  itemCount: _slides.length,
                  itemBuilder: (context, index) {
                    final slide = _slides[index];
                    return Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Slide Logo Emblem
                        Container(
                          width: size.height * 0.14,
                          height: size.height * 0.14,
                          decoration: BoxDecoration(
                            color: isDark
                                ? AppTheme.darkPrimaryGold.withOpacity(0.08)
                                : AppTheme.lightPrimaryGold.withOpacity(0.06),
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: isDark ? AppTheme.darkPrimaryGold : AppTheme.lightPrimaryGold,
                              width: 1,
                            ),
                          ),
                          child: Center(
                            child: Text(
                              slide['icon']!,
                              style: TextStyle(fontSize: size.height * 0.06),
                            ),
                          ),
                        ),
                        SizedBox(height: size.height * 0.04),
                        // Accent Header Tag
                        Text(
                          slide['accentText']!,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 2.0,
                            color: isDark ? AppTheme.darkPrimaryGold : AppTheme.lightPrimaryGold,
                          ),
                        ),
                        const SizedBox(height: 12),
                        // Title
                        Text(
                          slide['title']!,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1.0,
                            color: isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary,
                          ),
                        ),
                        const SizedBox(height: 16),
                        // Description
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12.0),
                          child: Text(
                            slide['subtitle']!,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 14,
                              height: 1.6,
                              color: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary,
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),

              const Spacer(),

              // Indicators & Button Controls
              Column(
                children: [
                  // Indicators
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(_slides.length, (index) {
                      final active = index == _currentPage;
                      return AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        margin: const EdgeInsets.symmetric(horizontal: 4.0),
                        width: active ? 24.0 : 8.0,
                        height: 4.0,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(2),
                          color: active
                              ? (isDark ? AppTheme.darkPrimaryGold : AppTheme.lightPrimaryGold)
                              : (isDark ? AppTheme.darkBorder : AppTheme.lightBorder),
                        ),
                      );
                    }),
                  ),
                  const SizedBox(height: 32),
                  
                  // CTA Button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        if (_currentPage < _slides.length - 1) {
                          _pageController.nextPage(
                            duration: const Duration(milliseconds: 400),
                            curve: Curves.easeInOutCubic,
                          );
                        } else {
                          _completeOnboarding();
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isDark ? AppTheme.darkPrimaryGold : AppTheme.lightPrimaryGold,
                        foregroundColor: isDark ? AppTheme.darkBackground : Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 18),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: BorderSide(
                            color: isDark ? AppTheme.darkAccentGold.withOpacity(0.3) : Colors.transparent,
                            width: 1,
                          ),
                        ),
                      ),
                      child: Text(
                        _currentPage == _slides.length - 1
                            ? 'ENTER EXECUTIVE SYSTEM'
                            : 'NEXT STEPS',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          letterSpacing: 2.0,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
