import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class SplashScreen extends StatefulWidget {
  final VoidCallback onComplete;

  const SplashScreen({
    super.key,
    required this.onComplete,
  });

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  // Staggered animations
  late Animation<double> _glowScale;
  late Animation<double> _logoScale;
  late Animation<double> _logoOpacity;
  late Animation<double> _titleFade;
  late Animation<Offset> _titleSlide;
  late Animation<double> _subtitleFade;
  late Animation<double> _progressValue;
  late Animation<double> _exitOpacity;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2800),
    );

    // 1. Background glow pulse: 0.0 -> 0.6
    _glowScale = Tween<double>(begin: 0.6, end: 1.25).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.65, curve: Curves.easeOutCubic),
      ),
    );

    // 2. Logo entrance with bounce: 0.1 -> 0.45
    _logoScale = Tween<double>(begin: 0.2, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.1, 0.5, curve: Curves.elasticOut),
      ),
    );

    _logoOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.08, 0.35, curve: Curves.easeIn),
      ),
    );

    // 3. Title reveal: 0.45 -> 0.75
    _titleFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.42, 0.68, curve: Curves.easeOut),
      ),
    );

    _titleSlide = Tween<Offset>(
      begin: const Offset(0.0, 0.35),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.42, 0.7, curve: Curves.easeOutCubic),
      ),
    );

    // 4. Subtitle and features: 0.55 -> 0.85
    _subtitleFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.55, 0.8, curve: Curves.easeOut),
      ),
    );

    // 5. Progress bar: 0.3 -> 0.95
    _progressValue = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.3, 0.92, curve: Curves.easeInOutCubic),
      ),
    );

    // 6. Final exit fade out: 0.92 -> 1.0
    _exitOpacity = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.92, 1.0, curve: Curves.easeIn),
      ),
    );

    _controller.forward().then((_) {
      if (mounted) {
        widget.onComplete();
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Opacity(
          opacity: _exitOpacity.value.clamp(0.0, 1.0),
          child: Scaffold(
            backgroundColor: const Color(0xFF061711),
            body: Stack(
              children: [
                // 1. Cinematic Background Gradient & Ambient Glows
                Positioned.fill(
                  child: Container(
                    decoration: const BoxDecoration(
                      gradient: RadialGradient(
                        center: Alignment(0.0, -0.15),
                        radius: 1.1,
                        colors: [
                          Color(0xFF144D3D),
                          Color(0xFF0C382B),
                          Color(0xFF072118),
                          Color(0xFF04110C),
                        ],
                        stops: [0.0, 0.45, 0.75, 1.0],
                      ),
                    ),
                  ),
                ),

                // 2. Animated Floating Geometry Court Rings
                Center(
                  child: Transform.scale(
                    scale: _glowScale.value,
                    child: Container(
                      width: 420,
                      height: 420,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: AppColors.emeraldLight.withValues(
                            alpha: (0.18 * (1.0 - (_glowScale.value - 0.6) / 0.65))
                                .clamp(0.0, 0.18),
                          ),
                          width: 1.5,
                        ),
                      ),
                    ),
                  ),
                ),
                Center(
                  child: Transform.scale(
                    scale: (_glowScale.value * 0.72).clamp(0.4, 1.2),
                    child: Container(
                      width: 290,
                      height: 290,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.08),
                          width: 1.0,
                        ),
                      ),
                    ),
                  ),
                ),

                // Radial Soft Ambient Light Behind Logo
                Center(
                  child: Container(
                    width: 240,
                    height: 240,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF1B7A5A).withValues(
                            alpha: (0.35 * _logoOpacity.value).clamp(0.0, 0.35),
                          ),
                          blurRadius: 100,
                          spreadRadius: 30,
                        ),
                        BoxShadow(
                          color: const Color(0xFF48BB78).withValues(
                            alpha: (0.15 * _logoOpacity.value).clamp(0.0, 0.15),
                          ),
                          blurRadius: 60,
                          spreadRadius: 10,
                        ),
                      ],
                    ),
                  ),
                ),

                // 3. Skip Button (Top Right)
                Positioned(
                  top: 24,
                  right: 24,
                  child: SafeArea(
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: widget.onComplete,
                        borderRadius: BorderRadius.circular(20),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                "Skip",
                                style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              SizedBox(width: 4),
                              Icon(Icons.chevron_right_rounded, size: 16, color: Colors.white70),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),

                // 4. Central Grand Emblem & Text Content
                Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Grand Emblem Icon
                        Transform.scale(
                          scale: _logoScale.value,
                          child: Opacity(
                            opacity: _logoOpacity.value.clamp(0.0, 1.0),
                            child: Container(
                              width: 110,
                              height: 110,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: const LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: [
                                    Color(0xFF1B7A5A),
                                    Color(0xFF0C382B),
                                    Color(0xFF061A13),
                                  ],
                                ),
                                border: Border.all(
                                  color: const Color(0xFF48BB78).withValues(alpha: 0.6),
                                  width: 2.5,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(0xFF1B7A5A).withValues(alpha: 0.4),
                                    blurRadius: 30,
                                    offset: const Offset(0, 10),
                                  ),
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.5),
                                    blurRadius: 20,
                                    offset: const Offset(0, 8),
                                  ),
                                ],
                              ),
                              child: Stack(
                                alignment: Alignment.center,
                                children: [
                                  // Inner Racket Icon
                                  Transform.rotate(
                                    angle: -math.pi / 8,
                                    child: const Icon(
                                      Icons.sports_tennis_rounded,
                                      size: 54,
                                      color: Colors.white,
                                    ),
                                  ),
                                  // Glowing Tennis Ball Accent
                                  Positioned(
                                    top: 22,
                                    right: 22,
                                    child: Container(
                                      width: 14,
                                      height: 14,
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFE2F952),
                                        shape: BoxShape.circle,
                                        boxShadow: [
                                          BoxShadow(
                                            color: const Color(0xFFE2F952).withValues(alpha: 0.8),
                                            blurRadius: 10,
                                            spreadRadius: 2,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(height: 36),

                        // Grand Title
                        SlideTransition(
                          position: _titleSlide,
                          child: FadeTransition(
                            opacity: _titleFade,
                            child: Column(
                              children: [
                                ShaderMask(
                                  shaderCallback: (bounds) => const LinearGradient(
                                    colors: [
                                      Colors.white,
                                      Color(0xFFE6F4EE),
                                      Color(0xFFA8DF8E),
                                    ],
                                    begin: Alignment.topCenter,
                                    end: Alignment.bottomCenter,
                                  ).createShader(bounds),
                                  child: const Text(
                                    "PADEL SHUFFLE",
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontSize: 34,
                                      fontWeight: FontWeight.w900,
                                      letterSpacing: 4.5,
                                      color: Colors.white,
                                      height: 1.1,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 10),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF1B7A5A).withValues(alpha: 0.25),
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(
                                      color: const Color(0xFF48BB78).withValues(alpha: 0.35),
                                    ),
                                  ),
                                  child: const Text(
                                    "By WoWo Padel Binus @Semarang",
                                    style: TextStyle(
                                      fontSize: 11.5,
                                      fontWeight: FontWeight.w800,
                                      letterSpacing: 1.0,
                                      color: Color(0xFF98E2B5),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),

                        const SizedBox(height: 16),

                        // Tagline - Ear-catchy, bold, vibrant
                        FadeTransition(
                          opacity: _subtitleFade,
                          child: const Text(
                            "Plan Your Play, Enjoy Your Day! 🎾✨",
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 14.5,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                              letterSpacing: 0.5,
                              shadows: [
                                Shadow(
                                  color: Color(0xFF48BB78),
                                  blurRadius: 12,
                                ),
                              ],
                            ),
                          ),
                        ),

                        const SizedBox(height: 52),

                        // Glowing Loading Progress Bar
                        FadeTransition(
                          opacity: _subtitleFade,
                          child: Container(
                            constraints: const BoxConstraints(maxWidth: 220),
                            child: Column(
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(10),
                                  child: Container(
                                    height: 4,
                                    width: double.infinity,
                                    color: Colors.white.withValues(alpha: 0.12),
                                    child: Align(
                                      alignment: Alignment.centerLeft,
                                      child: FractionallySizedBox(
                                        widthFactor: _progressValue.value.clamp(0.0, 1.0),
                                        child: Container(
                                          decoration: const BoxDecoration(
                                            gradient: LinearGradient(
                                              colors: [
                                                Color(0xFF1B7A5A),
                                                Color(0xFF48BB78),
                                                Color(0xFFE2F952),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 14),
                                Text(
                                  _progressValue.value < 0.45
                                      ? "Initializing tournament engine..."
                                      : _progressValue.value < 0.85
                                          ? "Connecting to Cloud Firestore..."
                                          : "Ready to play!",
                                  style: const TextStyle(
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white54,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
