import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'location_header.dart';

class MainAppBar extends StatelessWidget implements PreferredSizeWidget {
  final bool showNotification;
  
  const MainAppBar({
    super.key, 
    this.showNotification = true,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final canPop = Navigator.canPop(context);

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle(
        statusBarColor: Colors.blue,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: isDark ? Brightness.light : Brightness.dark,
      ),
      child: Material(
        elevation: isDark ? 0 : 3,
        shadowColor: Colors.black12,
        color: isDark ? Colors.black : Colors.white,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Safe Area / Status Bar Spacer
            Container(
              height: MediaQuery.of(context).padding.top,
              width: double.infinity,
              color: Colors.blue,
            ),
            
            // Header Content: Unified Row for Back Button, Location Manager, and Notification
            Padding(
              padding: EdgeInsets.fromLTRB(canPop ? 4.w : 12.w, 8.h, 8.w, 8.h),
              child: Row(
                children: [
                  if (canPop)
                    IconButton(
                      icon: Icon(
                        Platform.isIOS ? CupertinoIcons.back : Icons.arrow_back_ios_new_rounded,
                        color: Colors.blue,
                        size: 20.sp,
                      ),
                      onPressed: () => Navigator.pop(context),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  if (canPop) SizedBox(width: 8.w),
                  Expanded(
                    child: LocationHeader(showNotification: showNotification),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Size get preferredSize => Size.fromHeight(65.h);
}
