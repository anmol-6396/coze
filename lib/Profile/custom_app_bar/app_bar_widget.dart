import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final Color backgroundColor;
  final List<Widget>? actions;
  final bool centerTitle;

  const CustomAppBar({
    super.key,
    required this.title,
    this.backgroundColor = Colors.blue,
    this.actions,
    this.centerTitle = true,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveBgColor = backgroundColor;

    if (Platform.isIOS) {
      return CupertinoNavigationBar(
        middle: Text(
          title,
          style: TextStyle(
            fontSize: 18.sp,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: effectiveBgColor.withValues(alpha: 0.9),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: actions ?? [],
        ),
      );
    } else {
      return AppBar(
        title: Text(
          title,
          style: TextStyle(
            fontSize: 20.sp,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: effectiveBgColor,
        centerTitle: centerTitle,
        actions: actions,
        iconTheme: const IconThemeData(color: Colors.white),
      );
    }
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
