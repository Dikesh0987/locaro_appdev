import 'package:flutter/material.dart';
import '../../../core/theme/colors.dart';
import '../../../core/theme/typography.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _logoScaleAnimation;
  late Animation<double> _ring1Animation;
  late Animation<double> _ring2Animation;
  late Animation<double> _fadeAnimation;
  late Animation<double> _textSlideAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    );

    // Zoom in the inner circle (elastic)
    _logoScaleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.0, 0.4, curve: Curves.elasticOut),
      ),
    );

    // Expand middle ring
    _ring1Animation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.2, 0.6, curve: Curves.easeOutCubic),
      ),
    );

    // Expand outer ring
    _ring2Animation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.4, 0.8, curve: Curves.easeOutCubic),
      ),
    );

    // Fade in text and spinner later
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.6, 1.0, curve: Curves.easeIn),
      ),
    );

    // Slide up text
    _textSlideAnimation = Tween<double>(begin: 30.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.6, 1.0, curve: Curves.easeOutCubic),
      ),
    );

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.colors.primary, // Sleek dark/navy slate background
      body: Stack(
        children: [
          // Background subtle aesthetic gradients
          Positioned(
            top: -100,
            right: -100,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.03),
              ),
            ),
          ),
          Positioned(
            bottom: -50,
            left: -50,
            child: Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.02),
              ),
            ),
          ),
          // Center content
          Center(
            child: AnimatedBuilder(
              animation: _animationController,
              builder: (context, child) {
                return Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // App Icon Container
                    Transform.scale(
                      scale: _logoScaleAnimation.value,
                      child: Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(28),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.12),
                            width: 1,
                          ),
                        ),
                        child: CustomPaint(
                          size: const Size(64, 64),
                          painter: LocaroLogoPainter(
                            ring1Progress: _ring1Animation.value,
                            ring2Progress: _ring2Animation.value,
                            primaryColor: context.colors.primary,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 28),
                    // App Title and Subtitle (Fades and Slides up)
                    Opacity(
                      opacity: _fadeAnimation.value,
                      child: Transform.translate(
                        offset: Offset(0, _textSlideAnimation.value),
                        child: Column(
                          children: [
                            Text(
                              'Locaro',
                              style: AppTypography.display.copyWith(
                                color: Colors.white,
                                fontSize: 38,
                                fontWeight: FontWeight.w900,
                                letterSpacing: -1.0,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Discover Local. Shop Smart.',
                              style: AppTypography.label.copyWith(
                                color: Colors.white.withValues(alpha: 0.6),
                                letterSpacing: 0.5,
                                fontWeight: FontWeight.w400,
                              ),
                            ),
                            const SizedBox(height: 48),
                            // Clean minimalist spinner
                            SizedBox(
                              height: 24,
                              width: 24,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.5,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  Colors.white.withValues(alpha: 0.8),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class LocaroLogoPainter extends CustomPainter {
  final double ring1Progress;
  final double ring2Progress;
  final Color primaryColor;

  LocaroLogoPainter({
    required this.ring1Progress, 
    required this.ring2Progress,
    required this.primaryColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    // Scale canvas so that 160x160 fits into size.width x size.height
    canvas.scale(size.width / 160, size.height / 160);
    final center = const Offset(80, 80);
    
    // Draw inner circle
    final paint = Paint()..color = const Color(0xFFF6F4EE)..style = PaintingStyle.fill;
    canvas.drawCircle(center, 24, paint);
    
    // Draw L
    final lPaint = Paint()..color = primaryColor..style = PaintingStyle.fill;
    final path = Path();
    path.moveTo(center.dx - 6, center.dy - 12);
    path.lineTo(center.dx - 6, center.dy + 10);
    path.lineTo(center.dx + 9, center.dy + 10);
    path.lineTo(center.dx + 9, center.dy + 14);
    path.lineTo(center.dx - 10, center.dy + 14);
    path.lineTo(center.dx - 10, center.dy - 12);
    path.close();
    canvas.drawPath(path, lPaint);
    
    // Draw ring 1 (middle ring, r=36)
    if (ring1Progress > 0) {
      final ringPaint = Paint()
        ..color = const Color(0xFFF6F4EE).withValues(alpha: 0.6 * ring1Progress)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3;
      canvas.drawCircle(center, 24 + (12 * ring1Progress), ringPaint); // Expands from 24 to 36
    }
    
    // Draw ring 2 (outer ring, r=50)
    if (ring2Progress > 0) {
      final ringPaint2 = Paint()
        ..color = const Color(0xFFF6F4EE).withValues(alpha: 0.35 * ring2Progress)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3;
      canvas.drawCircle(center, 36 + (14 * ring2Progress), ringPaint2); // Expands from 36 to 50
    }
    
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant LocaroLogoPainter oldDelegate) {
    return oldDelegate.ring1Progress != ring1Progress || 
           oldDelegate.ring2Progress != ring2Progress ||
           oldDelegate.primaryColor != primaryColor;
  }
}
