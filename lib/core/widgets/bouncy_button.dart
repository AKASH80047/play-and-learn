import 'package:flutter/material.dart';

class BouncyButton extends StatefulWidget {
  final Widget child;
  final VoidCallback onTap;
  final Color? color;
  final Color? borderColor;
  final double radius;
  final double borderWidth;
  final EdgeInsets padding;
  final bool enabled;

  const BouncyButton({
    super.key,
    required this.child,
    required this.onTap,
    this.color,
    this.borderColor,
    this.radius = 24.0,
    this.borderWidth = 4.0,
    this.padding = const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
    this.enabled = true,
  });

  @override
  State<BouncyButton> createState() => _BouncyButtonState();
}

class _BouncyButtonState extends State<BouncyButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.92).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onTapDown(TapDownDetails details) {
    if (widget.enabled) {
      _controller.forward();
    }
  }

  void _onTapUp(TapUpDetails details) {
    if (widget.enabled) {
      _controller.reverse();
      widget.onTap();
    }
  }

  void _onTapCancel() {
    if (widget.enabled) {
      _controller.reverse();
    }
  }

  @override
  Widget build(BuildContext context) {
    final defaultColor = widget.color ?? Theme.of(context).colorScheme.primary;
    final defaultBorderColor = widget.borderColor ?? defaultColor.withValues(alpha: 0.8);

    return GestureDetector(
      onTapDown: _onTapDown,
      onTapUp: _onTapUp,
      onTapCancel: _onTapCancel,
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: Container(
          padding: widget.padding,
          decoration: BoxDecoration(
            color: widget.enabled ? defaultColor : Colors.grey[300],
            borderRadius: BorderRadius.circular(widget.radius),
            border: Border.all(
              color: widget.enabled ? defaultBorderColor : Colors.grey[400]!,
              width: widget.borderWidth,
            ),
            boxShadow: widget.enabled
                ? [
                    BoxShadow(
                      color: defaultBorderColor.withValues(alpha: 0.4),
                      offset: const Offset(0, 6),
                      blurRadius: 0,
                    ),
                  ]
                : null,
          ),
          child: DefaultTextStyle(
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
            child: widget.child,
          ),
        ),
      ),
    );
  }
}
