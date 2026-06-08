import 'package:flutter/material.dart';

class AnimatedActionIcon extends StatefulWidget {
  final IconData icon;
  final IconData activeIcon;
  final Color inactiveColor;
  final Color activeColor;
  final bool isActive;
  final double size;

  const AnimatedActionIcon({
    super.key,
    required this.icon,
    required this.activeIcon,
    required this.inactiveColor,
    required this.activeColor,
    required this.isActive,
    this.size = 24.0,
  });

  @override
  State<AnimatedActionIcon> createState() => _AnimatedActionIconState();
}

class _AnimatedActionIconState extends State<AnimatedActionIcon>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
    _scaleAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.3), weight: 1),
      TweenSequenceItem(tween: Tween(begin: 1.3, end: 1.0), weight: 1),
    ]).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void didUpdateWidget(AnimatedActionIcon oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isActive != oldWidget.isActive) {
      _controller.forward(from: 0.0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _scaleAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: Icon(
            widget.isActive ? widget.activeIcon : widget.icon,
            size: widget.size,
            color: widget.isActive ? widget.activeColor : widget.inactiveColor,
          ),
        );
      },
    );
  }
}
