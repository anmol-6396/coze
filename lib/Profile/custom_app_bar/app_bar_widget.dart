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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final effectiveBgColor = backgroundColor; // Keep original color regardless of theme

    if (Platform.isIOS) {
      // ✅ iOS style AppBar
      return CupertinoNavigationBar(
        middle: Text(
          title,
          style: TextStyle(
            fontSize: 18.sp,
            fontWeight: FontWeight.bold,
            fontFamily: 'Mogra',
            color: Colors.white,
          ),
        ),
        backgroundColor: effectiveBgColor.withOpacity(0.9),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: actions ?? [],
        ),
      );
    } else {
      // ✅ Android style AppBar
      return AppBar(
        title: Text(
          title,
          style: TextStyle(
            fontSize: 20.sp,
            fontWeight: FontWeight.bold,
            fontFamily: 'Mogra',
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
