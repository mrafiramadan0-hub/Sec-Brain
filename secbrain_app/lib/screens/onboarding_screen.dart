import 'package:flutter/material.dart';

import '../main.dart';
import '../widgets/secbrain_logo.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key, required this.onFinish});
  final VoidCallback onFinish;

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<_OnboardingItem> _pages = const [
    _OnboardingItem(
      title: 'Selamat Datang di SecBrain',
      subtitle: 'Satu tempat tenang untuk mengatur seluruh pikiran, agenda, pengetahuan, dan keuangan Anda.',
      icon: Icons.psychology_outlined,
      accentColor: green,
      bgColor: greenLight,
    ),
    _OnboardingItem(
      title: 'Tugas, To-Do & Agenda',
      subtitle: 'Pantau prioritas dengan Eisenhower Matrix, To-Do List berkala, dan pengingat deadline cerdas.',
      icon: Icons.check_circle_outline,
      accentColor: Color(0xFF1976D2),
      bgColor: blueLight,
    ),
    _OnboardingItem(
      title: 'Knowledge Base & Catatan',
      subtitle: 'Dokumentasikan ide, agenda rapat, notulensi klien, dan rangkuman workshop secara terstruktur.',
      icon: Icons.auto_stories_outlined,
      accentColor: Color(0xFFD97706),
      bgColor: amberLight,
    ),
    _OnboardingItem(
      title: 'Keuangan & Konsistensi Habit',
      subtitle: 'Kelola arus kas, pantau target tabungan impian, serta bangun rutinitas positif dengan streak tracker.',
      icon: Icons.savings_outlined,
      accentColor: Color(0xFF7E57C2),
      bgColor: Color(0xFFEDE7F6),
    ),
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _nextPage() {
    if (_currentPage < _pages.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      widget.onFinish();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            // Top Bar with Skip Button
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const SecBrainLogo(size: 28, showSubtitle: false),
                  if (_currentPage < _pages.length - 1)
                    TextButton(
                      onPressed: widget.onFinish,
                      child: const Text(
                        'Lewati',
                        style: TextStyle(
                          color: muted,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            // PageView Content
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                itemCount: _pages.length,
                onPageChanged: (index) => setState(() => _currentPage = index),
                itemBuilder: (context, index) {
                  final item = _pages[index];
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 36),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 140,
                          height: 140,
                          decoration: BoxDecoration(
                            color: isDark
                                ? item.accentColor.withValues(alpha: 0.2)
                                : item.bgColor,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            item.icon,
                            size: 68,
                            color: item.accentColor,
                          ),
                        ),
                        const SizedBox(height: 36),
                        Text(
                          item.title,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w800,
                            color: isDark ? Colors.white : ink,
                            letterSpacing: -0.5,
                          ),
                        ),
                        const SizedBox(height: 14),
                        Text(
                          item.subtitle,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 14,
                            color: muted,
                            height: 1.5,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            // Bottom Controls
            Padding(
              padding: const EdgeInsets.fromLTRB(28, 0, 28, 28),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Indicators
                  Row(
                    children: List.generate(_pages.length, (index) {
                      final isActive = index == _currentPage;
                      return AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        margin: const EdgeInsets.only(right: 6),
                        width: isActive ? 24 : 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: isActive
                              ? green
                              : muted.withValues(alpha: 0.3),
                          borderRadius: BorderRadius.circular(4),
                        ),
                      );
                    }),
                  ),
                  // Next / Get Started Button
                  FilledButton(
                    style: FilledButton.styleFrom(
                      backgroundColor: green,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 14,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: _nextPage,
                    child: Text(
                      _currentPage == _pages.length - 1
                          ? 'Mulai Sekarang'
                          : 'Lanjut',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
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
}

class _OnboardingItem {
  const _OnboardingItem({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.accentColor,
    required this.bgColor,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final Color accentColor;
  final Color bgColor;
}
