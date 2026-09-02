import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:coze/advertisement/advertise.dart'; // ✅ Centralized Ads
import 'package:coze/home_page/buttons/home_btn/home_btn.dart';
import 'package:coze/home_page/buttons/nur_to_12_btn.dart';
import 'package:coze/home_page/buttons/coaching_btn.dart';
import 'package:coze/home_page/buttons/school_btn.dart';
import 'package:coze/home_page/buttons/college_btn.dart';
import 'package:coze/home_page/buttons/library_page.dart';

class MergedRows extends StatelessWidget {
  const MergedRows({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    Widget categoryItem(String label, {String? imagePath, IconData? icon, required Widget targetPage}) {
      return InkWell(
        onTap: () {
          AdvertiseManager().showInterstitialAd(() {
            Navigator.push(
              context,
              Platform.isIOS
                  ? CupertinoPageRoute(builder: (context) => targetPage)
                  : MaterialPageRoute(builder: (context) => targetPage),
            );
          });
        },
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: EdgeInsets.all(10.w),
              decoration: BoxDecoration(
                color: isDark ? Colors.white.withValues(alpha: 0.08) : Colors.blue.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: imagePath != null 
                ? Image.asset(
                    imagePath,
                    width: 32.w,
                    height: 32.w,
                    fit: BoxFit.contain,
                  )
                : Icon(icon, color: Colors.blue, size: 28.sp),
            ),
            SizedBox(height: 6.h),
            Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 11.sp,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white : Colors.black87,
              ),
            ),
          ],
        ),
      );
    }

    return Card(
      elevation: 0,
      margin: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16.r),
        side: BorderSide(
          color: isDark ? Colors.white10 : Colors.grey.shade200,
          width: 1.w,
        ),
      ),
      color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.white,
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: 16.h, horizontal: 8.w),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                Expanded(child: categoryItem("Tutor", imagePath: "assets/images/homebtn.png", targetPage: const HomeBtn())),
                Expanded(child: categoryItem("Nur-12th", imagePath: "assets/images/nur.png", targetPage: const Nur12Btn())),
                Expanded(child: categoryItem("Coaching", imagePath: "assets/images/coaching.png", targetPage: const CoachingBtn())),
              ],
            ),
            SizedBox(height: 16.h),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                Expanded(child: categoryItem("School", imagePath: "assets/images/school.png", targetPage: const SchoolBtn())),
                Expanded(child: categoryItem("College", imagePath: "assets/images/college.png", targetPage: const CollegeBtn())),
                Expanded(child: categoryItem("Library", icon: Icons.library_books_rounded, targetPage: const LibraryPage())),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
