import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late final AnimationController _mainController;
  late final Animation<double> _fadeAnimation;
  late final Animation<double> _scaleAnimation;
  late final Animation<double> _logoBounceAnimation;

  @override
  void initState() {
    super.initState();
    _mainController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3000),
    );

    _fadeAnimation = CurvedAnimation(
      parent: _mainController,
      curve: const Interval(0.0, 0.6, curve: Curves.easeInOut),
    );

    _scaleAnimation = CurvedAnimation(
      parent: _mainController,
      curve: const Interval(0.2, 0.7, curve: Curves.elasticOut),
    );

    _logoBounceAnimation = CurvedAnimation(
      parent: _mainController,
      curve: const Interval(0.4, 0.9, curve: Curves.bounceOut),
    );

    _mainController.forward();
  }

  @override
  void dispose() {
    _mainController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF1E1B4B),
              Color(0xFF312E81),
              Color(0xFF4338CA),
              Color(0xFF5048E5),
            ],
          ),
        ),
        child: SafeArea(
          child: Stack(
            children: [
              // Background decorative elements
              Positioned(
                top: -100,
                right: -100,
                child: Container(
                  width: 400,
                  height: 400,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        const Color(0xFF818CF8).withValues(alpha: 0.35),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ),
              Positioned(
                top: 150,
                left: -80,
                child: Container(
                  width: 250,
                  height: 250,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        const Color(0xFF6366F1).withValues(alpha: 0.25),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ),
              Positioned(
                bottom: -50,
                left: 80,
                child: Container(
                  width: 300,
                  height: 300,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        const Color(0xFF4F46E5).withValues(alpha: 0.2),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ),
              Positioned(
                bottom: 80,
                right: -30,
                child: Container(
                  width: 200,
                  height: 200,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        const Color(0xFFA78BFA).withValues(alpha: 0.2),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ),

              // Wall decorations - floating shapes
              Positioned(
                top: 50,
                right: 60,
                child: Opacity(
                  opacity: 0.15,
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      shape: BoxShape.rectangle,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                  ),
                ),
              ),
              Positioned(
                top: 80,
                right: 100,
                child: Opacity(
                  opacity: 0.1,
                  child: Container(
                    width: 25,
                    height: 25,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),

              // Team working illustration
              Positioned(
                top: 50,
                left: 0,
                right: 0,
                child: AnimatedBuilder(
                  animation: _mainController,
                  builder: (context, child) {
                    return Opacity(
                      opacity: _fadeAnimation.value.clamp(0.0, 1.0),
                      child: const _TeamWorkspace(),
                    );
                  },
                ),
              ),

              // Decorative elements around workspace
              // Books/files on left
              Positioned(
                left: 50,
                bottom: 120,
                child: Opacity(
                  opacity: 0.25,
                  child: Column(
                    children: [
                      Container(
                        width: 28,
                        height: 32,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.4),
                          borderRadius: BorderRadius.circular(3),
                        ),
                      ),
                      const SizedBox(height: 3),
                      Container(
                        width: 22,
                        height: 28,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.3),
                          borderRadius: BorderRadius.circular(3),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              // Plant on right
              Positioned(
                right: 65,
                bottom: 115,
                child: Opacity(
                  opacity: 0.3,
                  child: Column(
                    children: [
                      Container(
                        width: 30,
                        height: 30,
                        decoration: BoxDecoration(
                          color: Colors.green.withValues(alpha: 0.5),
                          shape: BoxShape.circle,
                        ),
                      ),
                      Container(
                        width: 12,
                        height: 22,
                        decoration: BoxDecoration(
                          color: Colors.brown.withValues(alpha: 0.5),
                          borderRadius: const BorderRadius.only(
                            bottomLeft: Radius.circular(3),
                            bottomRight: Radius.circular(3),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              // Lamp on left
              Positioned(
                left: 35,
                bottom: 145,
                child: Opacity(
                  opacity: 0.2,
                  child: Container(
                    width: 22,
                    height: 50,
                    child: Column(
                      children: [
                        Container(
                          width: 22,
                          height: 22,
                          decoration: BoxDecoration(
                            color: Colors.yellow.withValues(alpha: 0.5),
                            shape: BoxShape.circle,
                          ),
                        ),
                        Container(
                          width: 4,
                          height: 28,
                          color: Colors.white.withValues(alpha: 0.4),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              // Coffee cup
              Positioned(
                right: 130,
                bottom: 108,
                child: Opacity(
                  opacity: 0.25,
                  child: Container(
                    width: 18,
                    height: 14,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.4),
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(4),
                        topRight: Radius.circular(4),
                        bottomLeft: Radius.circular(3),
                        bottomRight: Radius.circular(3),
                      ),
                    ),
                  ),
                ),
              ),

              // Logo and name at center
              Center(
                child: AnimatedBuilder(
                  animation: _mainController,
                  builder: (context, child) {
                    return Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const SizedBox(height: 220),
                        Transform.scale(
                          scale: _scaleAnimation.value,
                          child: Transform.translate(
                            offset: Offset(0, _logoBounceAnimation.value * -15),
                            child: Container(
                              width: 90,
                              height: 90,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(24),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.4),
                                    blurRadius: 40,
                                    offset: const Offset(0, 15),
                                  ),
                                ],
                              ),
                              child: const Center(
                                child: Icon(
                                  Icons.bolt,
                                  size: 52,
                                  color: Color(0xFF5048E5),
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 30),
                        Opacity(
                          opacity: _fadeAnimation.value.clamp(0.0, 1.0),
                          child: Text(
                            'PROGRESSO',
                            style: GoogleFonts.inter(
                              fontSize: 40,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                              letterSpacing: 3.5,
                              shadows: [
                                Shadow(
                                  color: Colors.black.withValues(alpha: 0.4),
                                  blurRadius: 20,
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
        ),
      ),
    );
  }
}

class _TeamWorkspace extends StatelessWidget {
  const _TeamWorkspace();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 500,
      height: 220,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Large meeting table
          Positioned(
            bottom: 0,
            child: Container(
              width: 460,
              height: 65,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.1),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(12),
                  topRight: Radius.circular(12),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.2),
                    blurRadius: 10,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
            ),
          ),

          // Table legs
          Positioned(
            bottom: 0,
            child: Row(
              children: [
                Container(
                  width: 120,
                  height: 10,
                  color: Colors.white.withValues(alpha: 0.08),
                ),
                const SizedBox(width: 220),
                Container(
                  width: 120,
                  height: 10,
                  color: Colors.white.withValues(alpha: 0.08),
                ),
              ],
            ),
          ),

          // Monitor 1 (far left)
          Positioned(left: 30, bottom: 45, child: _MonitorWidget(small: true)),

          // Monitor 2 (left center)
          Positioned(left: 100, bottom: 42, child: _MonitorWidget()),

          // Monitor 3 (right center)
          Positioned(right: 100, bottom: 42, child: _MonitorWidget()),

          // Monitor 4 (far right)
          Positioned(right: 30, bottom: 45, child: _MonitorWidget(small: true)),

          // Person 1 (far left)
          Positioned(
            left: 20,
            bottom: 48,
            child: _PersonWidget(
              bodyColor: Colors.white.withValues(alpha: 0.7),
              headColor: Colors.white.withValues(alpha: 0.95),
            ),
          ),

          // Person 2 (left)
          Positioned(
            left: 80,
            bottom: 48,
            child: _PersonWidget(
              bodyColor: Colors.white.withValues(alpha: 0.75),
              headColor: Colors.white.withValues(alpha: 0.95),
            ),
          ),

          // Person 3 (center - standing)
          Positioned(
            left: 180,
            bottom: 52,
            child: _PersonWidget(
              standing: true,
              bodyColor: Colors.white.withValues(alpha: 0.85),
              headColor: Colors.white.withValues(alpha: 0.95),
            ),
          ),

          // Person 4 (right)
          Positioned(
            right: 80,
            bottom: 48,
            child: Transform.scale(
              scaleX: -1,
              child: _PersonWidget(
                bodyColor: Colors.white.withValues(alpha: 0.75),
                headColor: Colors.white.withValues(alpha: 0.95),
              ),
            ),
          ),

          // Person 5 (far right)
          Positioned(
            right: 20,
            bottom: 48,
            child: Transform.scale(
              scaleX: -1,
              child: _PersonWidget(
                bodyColor: Colors.white.withValues(alpha: 0.7),
                headColor: Colors.white.withValues(alpha: 0.95),
              ),
            ),
          ),

          // Papers/documents on table
          Positioned(
            left: 140,
            bottom: 55,
            child: Opacity(opacity: 0.2, child: _DocumentStack()),
          ),
          Positioned(
            right: 150,
            bottom: 58,
            child: Opacity(opacity: 0.18, child: _DocumentStack()),
          ),
        ],
      ),
    );
  }
}

class _MonitorWidget extends StatelessWidget {
  final bool small;

  const _MonitorWidget({this.small = false});

  @override
  Widget build(BuildContext context) {
    final width = small ? 65.0 : 80.0;
    final height = small ? 50.0 : 60.0;

    return SizedBox(
      width: width,
      height: height,
      child: Stack(
        children: [
          // Monitor frame
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Container(
              height: height - 10,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.4),
                  width: 2,
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.all(3.5),
                child: Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E1B4B),
                    borderRadius: BorderRadius.circular(3),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        height: 3,
                        width: small ? 18.0 : 22.0,
                        margin: const EdgeInsets.only(bottom: 3),
                        decoration: BoxDecoration(
                          color: Colors.green,
                          borderRadius: BorderRadius.circular(1.5),
                        ),
                      ),
                      Container(
                        height: 3,
                        width: small ? 15.0 : 20.0,
                        margin: const EdgeInsets.only(bottom: 3),
                        decoration: BoxDecoration(
                          color: Colors.cyan.withValues(alpha: 0.7),
                          borderRadius: BorderRadius.circular(1.5),
                        ),
                      ),
                      Container(
                        height: 3,
                        width: small ? 12.0 : 17.0,
                        decoration: BoxDecoration(
                          color: Colors.orange.withValues(alpha: 0.6),
                          borderRadius: BorderRadius.circular(1.5),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          // Stand
          Positioned(
            bottom: 0,
            left: (width - 20) / 2,
            child: Container(
              width: 20,
              height: 8,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.35),
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(2),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PersonWidget extends StatelessWidget {
  final bool standing;
  final Color bodyColor;
  final Color headColor;

  const _PersonWidget({
    this.standing = false,
    required this.bodyColor,
    required this.headColor,
  });

  @override
  Widget build(BuildContext context) {
    final headSize = standing ? 32.0 : 28.0;
    final bodyHeight = standing ? 48.0 : 38.0;
    final bodyWidth = standing ? 30.0 : 24.0;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Head
        Container(
          width: headSize,
          height: headSize,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: headColor,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 3,
              ),
            ],
          ),
          child: Stack(
            children: [
              Center(
                child: Icon(
                  Icons.person,
                  size: headSize * 0.55,
                  color: const Color(0xFF6366F1),
                ),
              ),
              // Hair
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: Container(
                  height: headSize * 0.35,
                  decoration: BoxDecoration(
                    color: const Color(0xFF4C1D95).withValues(alpha: 0.25),
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(headSize / 2),
                      topRight: Radius.circular(headSize / 2),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 2),
        // Body
        Container(
          width: bodyWidth,
          height: bodyHeight,
          decoration: BoxDecoration(
            color: bodyColor,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(bodyWidth / 2),
              topRight: Radius.circular(bodyWidth / 2),
              bottomLeft: Radius.circular(standing ? 7 : 5),
              bottomRight: Radius.circular(standing ? 7 : 5),
            ),
          ),
          child: standing
              ? Stack(
                  children: [
                    // Arms
                    Positioned(
                      top: 10,
                      left: -5,
                      child: Container(
                        width: bodyWidth + 10,
                        height: 3,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.5),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                  ],
                )
              : null,
        ),
      ],
    );
  }
}

class _DocumentStack extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 32,
      height: 36,
      child: Stack(
        children: [
          Positioned(
            bottom: 0,
            left: 0,
            child: Container(
              width: 26,
              height: 34,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.25),
                borderRadius: BorderRadius.circular(3),
              ),
            ),
          ),
          Positioned(
            bottom: 3,
            right: 0,
            child: Container(
              width: 22,
              height: 30,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(3),
              ),
            ),
          ),
          Positioned(
            top: 0,
            left: 3,
            child: Container(
              width: 20,
              height: 28,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.35),
                borderRadius: BorderRadius.circular(3),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.3),
                  width: 1,
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  Container(
                    height: 2,
                    width: 14,
                    margin: const EdgeInsets.only(top: 4),
                    color: Colors.white.withValues(alpha: 0.4),
                  ),
                  Container(
                    height: 2,
                    width: 12,
                    color: Colors.white.withValues(alpha: 0.35),
                  ),
                  Container(
                    height: 2,
                    width: 9,
                    color: Colors.white.withValues(alpha: 0.3),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
