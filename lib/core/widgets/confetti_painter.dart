import 'dart:math';
import 'package:flutter/material.dart';

class ConfettiParticle {
  double x;
  double y;
  double vx;
  double vy;
  double rotation;
  double rotationSpeed;
  Color color;
  double size;
  double opacity;
  int shapeType; // 0: rectangle, 1: circle, 2: triangle

  ConfettiParticle({
    required this.x,
    required this.y,
    required this.vx,
    required this.vy,
    required this.rotation,
    required this.rotationSpeed,
    required this.color,
    required this.size,
    required this.shapeType,
    this.opacity = 1.0,
  });

  void update() {
    x += vx;
    y += vy;
    vy += 0.15; // Gravity
    vx *= 0.98; // Air resistance
    rotation += rotationSpeed;
    opacity = max(0.0, opacity - 0.015);
  }
}

class ConfettiWidget extends StatefulWidget {
  final bool isPlaying;
  final Widget? child;

  const ConfettiWidget({
    super.key,
    required this.isPlaying,
    this.child,
  });

  @override
  State<ConfettiWidget> createState() => _ConfettiWidgetState();
}

class _ConfettiWidgetState extends State<ConfettiWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _ticker;
  final List<ConfettiParticle> _particles = [];
  final Random _random = Random();

  final List<Color> _palette = const [
    Color(0xff6c63ff),
    Color(0xffffb84d),
    Color(0xff4ecdc4),
    Color(0xff7ed957),
    Color(0xffff5a5f),
    Color(0xffffd166),
  ];

  @override
  void initState() {
    super.initState();
    _ticker = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..addListener(_tick);

    if (widget.isPlaying) {
      _ticker.repeat();
      _spawnBurst();
    }
  }

  @override
  void didUpdateWidget(ConfettiWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isPlaying && !oldWidget.isPlaying) {
      _ticker.repeat();
      _spawnBurst();
    } else if (!widget.isPlaying && oldWidget.isPlaying) {
      // Allow remaining particles to fade out naturally
    }
  }

  @override
  void dispose() {
    _ticker.dispose();
    super.dispose();
  }

  void _spawnBurst() {
    // Generate initial explosion of particles from the center/bottom
    for (int i = 0; i < 80; i++) {
      final angle = _random.nextDouble() * pi * 2;
      final speed = _random.nextDouble() * 12 + 5;
      _particles.add(
        ConfettiParticle(
          x: 0, // coordinates relative to layout offset
          y: 0,
          vx: cos(angle) * speed,
          vy: sin(angle) * speed - 5.0, // Upward bias
          rotation: _random.nextDouble() * pi,
          rotationSpeed: (_random.nextDouble() - 0.5) * 0.3,
          color: _palette[_random.nextInt(_palette.length)],
          size: _random.nextDouble() * 10 + 6,
          shapeType: _random.nextInt(3),
        ),
      );
    }
  }

  void _tick() {
    setState(() {
      for (final p in _particles) {
        p.update();
      }
      _particles.removeWhere((p) => p.opacity <= 0.0);
      
      // If playing, periodically spawn extra particles
      if (widget.isPlaying && _particles.length < 50 && _random.nextDouble() < 0.3) {
        _particles.add(
          ConfettiParticle(
            x: (_random.nextDouble() - 0.5) * 200,
            y: -100,
            vx: (_random.nextDouble() - 0.5) * 4,
            vy: _random.nextDouble() * 2,
            rotation: _random.nextDouble() * pi,
            rotationSpeed: (_random.nextDouble() - 0.5) * 0.2,
            color: _palette[_random.nextInt(_palette.length)],
            size: _random.nextDouble() * 8 + 6,
            shapeType: _random.nextInt(3),
          ),
        );
      }
      
      if (!widget.isPlaying && _particles.isEmpty) {
        _ticker.stop();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _ConfettiPainter(_particles),
      child: widget.child,
    );
  }
}

class _ConfettiPainter extends CustomPainter {
  final List<ConfettiParticle> particles;

  _ConfettiPainter(this.particles);

  @override
  void paint(Canvas canvas, Size size) {
    // Translate origin to center so x=0, y=0 is centered
    canvas.save();
    canvas.translate(size.width / 2, size.height / 2);

    final paint = Paint()..style = PaintingStyle.fill;

    for (final p in particles) {
      paint.color = p.color.withValues(alpha: p.opacity);
      canvas.save();
      canvas.translate(p.x, p.y);
      canvas.rotate(p.rotation);

      if (p.shapeType == 0) {
        // Rectangle
        canvas.drawRect(
          Rect.fromCenter(center: Offset.zero, width: p.size * 1.5, height: p.size),
          paint,
        );
      } else if (p.shapeType == 1) {
        // Circle
        canvas.drawCircle(Offset.zero, p.size / 2, paint);
      } else {
        // Triangle
        final path = Path()
          ..moveTo(0, -p.size / 2)
          ..lineTo(p.size / 2, p.size / 2)
          ..lineTo(-p.size / 2, p.size / 2)
          ..close();
        canvas.drawPath(path, paint);
      }

      canvas.restore();
    }

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _ConfettiPainter oldDelegate) => true;
}
