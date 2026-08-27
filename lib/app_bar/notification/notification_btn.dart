import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class NotificationButton extends StatelessWidget {
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
  Widget build(BuildContext context) {
    // Icon size responsive with ScreenUtil
    final iconSize = 24.sp;

    final icon = Platform.isIOS
        ? Icon(
      CupertinoIcons.bell,
      color: iconColor ?? CupertinoColors.activeBlue,
      size: iconSize,
    )
        : Icon(
      Icons.notifications,
      color: iconColor ?? Colors.blue,
      size: iconSize,
    );

    final button = Platform.isIOS
        ? CupertinoButton(
      padding: EdgeInsets.zero,
      onPressed: onPressed ?? () => debugPrint('Notification button tapped'),
      child: icon,
    )
        : IconButton(
      icon: icon,
      onPressed: onPressed ?? () => debugPrint('Notification button tapped'),
    );

    return Stack(
      clipBehavior: Clip.none,
      children: [
        button,
        if (unreadCount > 0)
          Positioned(
            right: 6.w,
            top: 4.h,
            child: Container(
              padding: EdgeInsets.all(2.w),
              decoration: const BoxDecoration(
                color: Colors.red,
                shape: BoxShape.circle,
              ),
              constraints: BoxConstraints(
                minWidth: 14.w,
                minHeight: 14.w,
              ),
              child: Center(
                child: Text(
                  unreadCount > 99 ? '99+' : '$unreadCount',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 9.sp,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
