import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/bouncy_button.dart';
import '../../core/widgets/confetti_painter.dart';

class BalloonData {
  final int id;
  double x;
  double y;
  final double size;
  final Color color;
  final double speed;
  final double wiggleSpeed;
  final double wiggleAmount;
  bool isPopped = false;

  BalloonData({
    required this.id,
    required this.x,
    required this.y,
    required this.size,
    required this.color,
    required this.speed,
    required this.wiggleSpeed,
    required this.wiggleAmount,
  });
}

class PopEffect {
  final double x;
  double y; // mutable to float up
  final String label;
  final Color color;
  double opacity = 1.0;
  double scale = 0.5;

  PopEffect({
    required this.x,
    required this.y,
    required this.label,
    required this.color,
  });
}

class MagicBalloonPopScreen extends StatefulWidget {
  const MagicBalloonPopScreen({super.key});

  @override
  State<MagicBalloonPopScreen> createState() => _MagicBalloonPopScreenState();
}

class _MagicBalloonPopScreenState extends State<MagicBalloonPopScreen>
    with TickerProviderStateMixin {
  late AnimationController _gameController;
  final List<BalloonData> _balloons = [];
  final List<PopEffect> _popEffects = [];
  final Random _random = Random();
  
  int _score = 0;
  int _starsEarned = 0;
  bool _levelCompleted = false;
  bool _showConfetti = false;

  final List<Color> _balloonColors = const [
    Color(0xffff5a5f), // Coral Red
    Color(0xffffb84d), // Sunshine Orange
    Color(0xff4ecdc4), // Teal Green
    Color(0xff6c63ff), // Purple Blue
    Color(0xff7ed957), // Happy Green
    Color(0xffff70a6), // Soft Pink
  ];

  final List<String> _soundWords = const [
    'POP! 🎈',
    'BOOP! ⚡',
    'ZAP! 🌟',
    'BAM! 💥',
    'YAY! 🎉',
  ];

  @override
  void initState() {
    super.initState();
    _gameController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..addListener(_updateGame);

    _gameController.repeat();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _spawnInitialBalloons();
      }
    });
  }

  @override
  void dispose() {
    _gameController.dispose();
    super.dispose();
  }

  void _spawnInitialBalloons() {
    for (int i = 0; i < 6; i++) {
      _spawnBalloon(initialY: true);
    }
  }

  void _spawnBalloon({bool initialY = false}) {
    final size = MediaQuery.of(context).size;
    final width = size.width.isFinite && size.width > 0 ? size.width : 360.0;
    final height = size.height.isFinite && size.height > 0 ? size.height : 640.0;
    
    _balloons.add(
      BalloonData(
        id: _random.nextInt(99999),
        x: _random.nextDouble() * (width - 80) + 40,
        y: initialY
            ? _random.nextDouble() * (height - 200) + 100
            : height + 100, // spawn off-screen bottom
        size: _random.nextDouble() * 20 + 60, // size 60-80
        color: _balloonColors[_random.nextInt(_balloonColors.length)],
        speed: _random.nextDouble() * 2.0 + 1.8, // Float speed
        wiggleSpeed: _random.nextDouble() * 0.05 + 0.02,
        wiggleAmount: _random.nextDouble() * 12 + 6,
      ),
    );
  }

  void _updateGame() {
    if (_levelCompleted) return;
    
    setState(() {
      // 1. Move balloons up
      for (final b in _balloons) {
        b.y -= b.speed;
        // Wiggle left and right
        b.x += sin(_gameController.value * pi * 2 * (b.wiggleSpeed * 10)) * 0.5;
      }

      // 2. Remove out-of-bounds balloons and respawn
      _balloons.removeWhere((b) {
        if (b.y < -120) {
          // Respawn another one
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted && !_levelCompleted) _spawnBalloon();
          });
          return true;
        }
        return false;
      });

      // 3. Update pop texts (fade out & float up)
      for (final eff in _popEffects) {
        eff.y -= 2;
        eff.opacity = max(0.0, eff.opacity - 0.04);
        eff.scale = min(1.3, eff.scale + 0.05);
      }
      _popEffects.removeWhere((eff) => eff.opacity <= 0.0);
    });
  }

  void _popBalloon(BalloonData balloon) {
    if (balloon.isPopped || _levelCompleted) return;
    
    setState(() {
      balloon.isPopped = true;
      _score++;
      
      // Earn a star every pop!
      _starsEarned++;

      // Play simulated beep sound/haptic
      HapticFeedback.lightImpact();

      // Add a cartoon POP text balloon effect
      _popEffects.add(
        PopEffect(
          x: balloon.x,
          y: balloon.y,
          label: _soundWords[_random.nextInt(_soundWords.length)],
          color: balloon.color,
        ),
      );

      // Remove popped balloon
      _balloons.remove(balloon);

      // Check level win condition
      if (_score >= 10) {
        _gameCompleted();
      } else {
        // Spawn a replacement balloon
        _spawnBalloon();
      }
    });
  }

  void _gameCompleted() async {
    setState(() {
      _levelCompleted = true;
      _showConfetti = true;
    });

    // Save stars to local preferences
    final prefs = await SharedPreferences.getInstance();
    final currentStars = prefs.getInt('stars') ?? 0;
    await prefs.setInt('stars', currentStars + _starsEarned);

    // Save 'Balloon Explorer' badge
    final currentBadges = prefs.getStringList('badges') ?? [];
    if (!currentBadges.contains('Balloon Popper 🎈')) {
      currentBadges.add('Balloon Popper 🎈');
      await prefs.setStringList('badges', currentBadges);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Playful sky background
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xffd0e1fd), Color(0xfff5f8ff)],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),

          // Grass elements at the bottom
          Positioned(
            bottom: -20,
            left: -20,
            right: -20,
            child: Opacity(
              opacity: 0.6,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: List.generate(10, (index) {
                  return const Text('🌿', style: TextStyle(fontSize: 48));
                }),
              ),
            ),
          ),

          // Floating Balloons
          ..._balloons.map((b) {
            return Positioned(
              left: b.x - (b.size / 2),
              top: b.y,
              child: GestureDetector(
                onTapDown: (_) => _popBalloon(b),
                child: CustomPaint(
                  size: Size(b.size, b.size * 1.3),
                  painter: BalloonPainter(b.color),
                ),
              ),
            );
          }),

          // Pop bubble text effects
          ..._popEffects.map((eff) {
            return Positioned(
              left: eff.x - 50,
              top: eff.y - 30,
              child: Opacity(
                opacity: eff.opacity,
                child: Transform.scale(
                  scale: eff.scale,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: eff.color, width: 3),
                      boxShadow: [
                        BoxShadow(
                          color: eff.color.withValues(alpha: 0.3),
                          offset: const Offset(0, 3),
                        )
                      ],
                    ),
                    child: Text(
                      eff.label,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: eff.color,
                      ),
                    ),
                  ),
                ),
              ),
            );
          }),

          // Confetti explosion layer when complete
          if (_showConfetti)
            const Positioned.fill(
              child: IgnorePointer(
                child: ConfettiWidget(isPlaying: true),
              ),
            ),

          // Top statistics bar
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 12.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Back button
                  BouncyButton(
                    padding: const EdgeInsets.all(12),
                    color: Colors.white,
                    borderColor: AppTheme.borderLight,
                    radius: 20,
                    onTap: () => Navigator.of(context).pop(),
                    child: const Icon(Icons.arrow_back_rounded, color: AppTheme.textDark, size: 24),
                  ),
                  
                  // Score Tracker
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                    decoration: AppTheme.playfulCardDecoration(
                      color: Colors.white,
                      borderColor: AppTheme.primary,
                      radius: 20,
                    ),
                    child: Row(
                      children: [
                        const Text('🎈', style: TextStyle(fontSize: 22)),
                        const SizedBox(width: 8),
                        Text(
                          'Pops: $_score / 10',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                            color: AppTheme.textDark,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Star rewards in this session
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                    decoration: AppTheme.playfulCardDecoration(
                      color: Colors.white,
                      borderColor: AppTheme.secondary,
                      radius: 20,
                    ),
                    child: Row(
                      children: [
                        const Text('⭐', style: TextStyle(fontSize: 22)),
                        const SizedBox(width: 6),
                        Text(
                          '+$_starsEarned',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                            color: AppTheme.textDark,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Victory Celebration Modal Overlay
          if (_levelCompleted) _buildVictoryOverlay(),
        ],
      ),
    );
  }

  Widget _buildVictoryOverlay() {
    return Container(
      color: Colors.black.withValues(alpha: 0.6),
      alignment: Alignment.center,
      child: TweenAnimationBuilder<double>(
        duration: const Duration(milliseconds: 500),
        curve: Curves.elasticOut,
        tween: Tween(begin: 0.0, end: 1.0),
        builder: (context, val, child) {
          return Transform.scale(
            scale: val,
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 28),
              padding: const EdgeInsets.all(28),
              decoration: AppTheme.playfulCardDecoration(
                color: Colors.white,
                borderColor: AppTheme.secondary,
                radius: AppTheme.radiusExtraLarge,
                borderWidth: 6,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('🎉 CONGRATS! 🎉',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w900,
                        color: AppTheme.secondary,
                      )),
                  const SizedBox(height: 16),
                  const Text(
                    '🦉 Pip is Super Proud! 🦉',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppTheme.textDark),
                  ),
                  const SizedBox(height: 16),
                  
                  // Big Badge representation
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: AppTheme.primary.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Text('🎈', style: TextStyle(fontSize: 70)),
                  ),
                  const SizedBox(height: 16),
                  
                  Text(
                    'You popped 10 balloons\nand earned +$_starsEarned Stars!',
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: AppTheme.textLight),
                  ),
                  const SizedBox(height: 24),
                  
                  BouncyButton(
                    color: AppTheme.success,
                    borderColor: const Color(0xff5cb53b),
                    radius: AppTheme.radiusLarge,
                    onTap: () {
                      Navigator.of(context).pop();
                    },
                    child: const Text(
                      'Play More! 🚀',
                      style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

// Custom Painter to draw a clean cartoon Balloon
class BalloonPainter extends CustomPainter {
  final Color color;

  BalloonPainter(this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final shadowPaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.08)
      ..style = PaintingStyle.fill;

    final highlightPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.4)
      ..style = PaintingStyle.fill;

    final stringPaint = Paint()
      ..color = Colors.grey[600]!
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    // Draw String (squiggly curve at the bottom)
    final pathString = Path()
      ..moveTo(size.width / 2, size.height * 0.8)
      ..quadraticBezierTo(
        size.width / 2 - 15, size.height * 0.9,
        size.width / 2 + 5, size.height,
      );
    canvas.drawPath(pathString, stringPaint);

    // Draw main balloon egg oval
    final balloonRect = Rect.fromLTWH(0, 0, size.width, size.height * 0.8);
    canvas.drawOval(balloonRect, paint);

    // Draw bottom small knot triangle
    final knotPath = Path()
      ..moveTo(size.width / 2 - 6, size.height * 0.8)
      ..lineTo(size.width / 2 + 6, size.height * 0.8)
      ..lineTo(size.width / 2, size.height * 0.8 + 8)
      ..close();
    canvas.drawPath(knotPath, paint);

    // Draw dark side shadow overlay (right side)
    canvas.save();
    canvas.clipPath(Path()..addOval(balloonRect));
    canvas.drawCircle(Offset(size.width * 1.2, size.height * 0.4), size.width * 0.7, shadowPaint);
    canvas.restore();

    // Draw gloss highlight glare (top left)
    canvas.drawOval(
      Rect.fromLTWH(size.width * 0.18, size.height * 0.12, size.width * 0.22, size.height * 0.18),
      highlightPaint,
    );
  }

  @override
  bool shouldRepaint(covariant BalloonPainter oldDelegate) =>
      oldDelegate.color != color;
}
