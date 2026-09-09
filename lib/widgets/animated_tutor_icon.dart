import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class AnimatedTutorIcon extends StatefulWidget {
  final String? imagePath;
  final IconData? icon;
  final double size;
  final Color glowColor;

  const AnimatedTutorIcon({
    super.key,
    this.imagePath,
    this.icon,
    this.size = 32.0,
    this.glowColor = Colors.blueAccent,
  });

  @override
  State<AnimatedTutorIcon> createState() => _AnimatedTutorIconState();
}

class _AnimatedTutorIconState extends State<AnimatedTutorIcon>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _glowAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);

    _scaleAnimation = Tween<double>(begin: 0.95, end: 1.08).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );

    _glowAnimation = Tween<double>(begin: 0.2, end: 0.6).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
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
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: Container(
            padding: EdgeInsets.all(8.r),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: widget.glowColor.withValues(alpha: _glowAnimation.value),
                  blurRadius: 18,
                  spreadRadius: 2,
                )
              ],
            ),
            child: widget.imagePath != null
                ? Image.asset(
                    widget.imagePath!,
                    width: widget.size.w,
                    height: widget.size.w,
                    fit: BoxFit.contain,
                  )
                : Icon(
                    widget.icon ?? Icons.school_rounded,
                    color: widget.glowColor,
                    size: widget.size.sp,
                  ),
          ),
        );
      },
    );
  }
}
