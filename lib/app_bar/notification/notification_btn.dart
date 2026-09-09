import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class NotificationButton extends StatefulWidget {
  final int unreadCount;
  final VoidCallback? onPressed;
  final Color? iconColor;

  const NotificationButton({
    super.key,
    this.unreadCount = 0,
    this.onPressed,
    this.iconColor,
  });

  @override
  State<NotificationButton> createState() => _NotificationButtonState();
}

class _NotificationButtonState extends State<NotificationButton>
    with TickerProviderStateMixin {
  late AnimationController _bellSwingController;
  late AnimationController _badgePulseController;

  late Animation<double> _bellRotation;
  late Animation<double> _badgeScale;

  @override
  void initState() {
    super.initState();

    // 🔔 Bell Swing / Ringing Animation Sequence
    _bellSwingController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    _bellRotation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: -0.12), weight: 1),
      TweenSequenceItem(tween: Tween(begin: -0.12, end: 0.12), weight: 2),
      TweenSequenceItem(tween: Tween(begin: 0.12, end: -0.08), weight: 2),
      TweenSequenceItem(tween: Tween(begin: -0.08, end: 0.08), weight: 2),
      TweenSequenceItem(tween: Tween(begin: 0.08, end: 0.0), weight: 1),
    ]).animate(CurvedAnimation(
      parent: _bellSwingController,
      curve: Curves.easeInOut,
    ));

    // 🔴 Badge Pulse Controller
    _badgePulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );

    _badgeScale = Tween<double>(begin: 0.9, end: 1.25).animate(
      CurvedAnimation(parent: _badgePulseController, curve: Curves.easeInOut),
    );

    _checkAnimationState();
  }

  @override
  void didUpdateWidget(NotificationButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.unreadCount != widget.unreadCount) {
      _checkAnimationState();
    }
  }

  void _checkAnimationState() {
    if (widget.unreadCount > 0) {
      if (!_badgePulseController.isAnimating) {
        _badgePulseController.repeat(reverse: true);
      }
      // Periodically swing bell every 3 seconds
      if (!_bellSwingController.isAnimating) {
        _bellSwingController.repeat(period: const Duration(seconds: 3));
      }
    } else {
      _bellSwingController.stop();
      _bellSwingController.reset();
      _badgePulseController.stop();
      _badgePulseController.reset();
    }
  }

  @override
  void dispose() {
    _bellSwingController.dispose();
    _badgePulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final iconSize = 24.sp;
    final color = widget.iconColor ?? (Platform.isIOS ? CupertinoColors.activeBlue : Colors.blue);

    final bellIcon = Platform.isIOS
        ? Icon(
            CupertinoIcons.bell_fill,
            color: color,
            size: iconSize,
          )
        : Icon(
            Icons.notifications_active_rounded,
            color: color,
            size: iconSize,
          );

    final animatedBell = RotationTransition(
      turns: _bellRotation,
      child: bellIcon,
    );

    final button = Platform.isIOS
        ? CupertinoButton(
            padding: EdgeInsets.zero,
            onPressed: widget.onPressed ?? () => debugPrint('Notification tapped'),
            child: animatedBell,
          )
        : IconButton(
            icon: animatedBell,
            onPressed: widget.onPressed ?? () => debugPrint('Notification tapped'),
          );

    return Stack(
      clipBehavior: Clip.none,
      children: [
        button,
        if (widget.unreadCount > 0)
          Positioned(
            right: 6.w,
            top: 4.h,
            child: ScaleTransition(
              scale: _badgeScale,
              child: Container(
                padding: EdgeInsets.all(2.w),
                decoration: BoxDecoration(
                  color: Colors.redAccent,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.redAccent.withValues(alpha: 0.5),
                      blurRadius: 6,
                      spreadRadius: 1,
                    )
                  ],
                ),
                constraints: BoxConstraints(
                  minWidth: 15.w,
                  minHeight: 15.w,
                ),
                child: Center(
                  child: Text(
                    widget.unreadCount > 99 ? '99+' : '${widget.unreadCount}',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 8.5.sp,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
