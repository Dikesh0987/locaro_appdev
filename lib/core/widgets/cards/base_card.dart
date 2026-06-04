import 'package:flutter/material.dart';

class BaseCard extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry padding;

  const BaseCard({
    super.key,
    required this.child,
    this.onTap,
    this.padding = EdgeInsets.zero,
  });

  @override
  State<BaseCard> createState() => _BaseCardState();
}

class _BaseCardState extends State<BaseCard> {
  bool _isPressed = false;

  void _onTapDown(TapDownDetails details) {
    if (widget.onTap != null) {
      setState(() => _isPressed = true);
    }
  }

  void _onTapUp(TapUpDetails details) {
    if (widget.onTap != null) {
      setState(() => _isPressed = false);
      widget.onTap!();
    }
  }

  void _onTapCancel() {
    if (widget.onTap != null) {
      setState(() => _isPressed = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: _onTapDown,
      onTapUp: _onTapUp,
      onTapCancel: _onTapCancel,
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 150),
        opacity: _isPressed ? 0.8 : 1.0, // Subtle opacity feedback as requested
        child: Card(
          // Appearance driven by AppTheme.cardTheme
          child: Padding(
            padding: widget.padding,
            child: widget.child,
          ),
        ),
      ),
    );
  }
}
