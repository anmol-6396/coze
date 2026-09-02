import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'home_tutor_btn.dart';
import 'home_co_btn.dart';

class HomeBtn extends StatelessWidget {
  const HomeBtn({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? Colors.black : const Color(0xFFF5F7FF),
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          _buildSliverHeader(context, isDark),
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 30.h),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSectionInfo(isDark),
                  SizedBox(height: 32.h),
                  _buildActionCard(
                    context,
                    title: "Class Nur to 12",
                    desc: "School level tutoring for all subjects and boards.",
                    icon: Icons.menu_book_rounded,
                    color: Colors.blueAccent,
                    image: 'assets/images/hometutor.png',
                    destination: const HomeTutorBtn(),
                  ),
                  SizedBox(height: 20.h),
                  _buildActionCard(
                    context,
                    title: "Private Home Tutor",
                    desc: "Personalized 1-on-1 tutoring sessions at your home.",
                    icon: Icons.person_search_rounded,
                    color: Colors.indigoAccent,
                    image: 'assets/images/homecoach.png',
                    destination: const HomeCoBtn(),
                  ),
                  SizedBox(height: 100.h),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSliverHeader(BuildContext context, bool isDark) {
    return SliverAppBar(
      expandedHeight: 220.h,
      pinned: true,
      backgroundColor: Colors.indigo,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
        onPressed: () => Navigator.pop(context),
      ),
      flexibleSpace: FlexibleSpaceBar(
        centerTitle: true,
        title: Text(
          "Tutor Selection",
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 18.sp,
            shadows: const [Shadow(blurRadius: 10, color: Colors.black45)],
          ),
        ),
        background: Stack(
          fit: StackFit.expand,
          children: [
            Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.indigo, Colors.blue],
                ),
              ),
            ),
            Positioned(
              right: -20.w,
              bottom: 0,
              child: Opacity(
                opacity: 0.3,
                child: Icon(Icons.school_rounded, size: 200.sp, color: Colors.white),
              ),
            ),
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(height: 40.h),
                  Icon(Icons.auto_awesome_rounded, color: Colors.white, size: 40.sp),
                  SizedBox(height: 10.h),
                  Text(
                    "Learn from the Best",
                    style: TextStyle(color: Colors.white70, fontSize: 14.sp, letterSpacing: 1.2),
                  )
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionInfo(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "What are you looking for?",
          style: TextStyle(
            fontSize: 22.sp,
            fontWeight: FontWeight.w900,
            color: isDark ? Colors.white : Colors.indigo.shade900,
          ),
        ),
        SizedBox(height: 6.h),
        Container(
          width: 50.w,
          height: 4.h,
          decoration: BoxDecoration(
            color: Colors.blueAccent,
            borderRadius: BorderRadius.circular(2.r),
          ),
        ),
      ],
    );
  }

  Widget _buildActionCard(
    BuildContext context, {
    required String title,
    required String desc,
    required IconData icon,
    required Color color,
    required String image,
    required Widget destination,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? Colors.grey[900] : Colors.white,
        borderRadius: BorderRadius.circular(28.r),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(isDark ? 0.2 : 0.1),
            blurRadius: 20,
            offset: const Offset(0, 10),
          )
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            Navigator.push(
              context,
              Platform.isIOS
                  ? CupertinoPageRoute(builder: (_) => destination)
                  : MaterialPageRoute(builder: (_) => destination),
            );
          },
          borderRadius: BorderRadius.circular(28.r),
          child: Padding(
            padding: EdgeInsets.all(24.r),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: EdgeInsets.all(8.r),
                        decoration: BoxDecoration(
                          color: color.withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(icon, color: color, size: 22.sp),
                      ),
                      SizedBox(height: 16.h),
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: 18.sp,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : Colors.black87,
                        ),
                      ),
                      SizedBox(height: 6.h),
                      Text(
                        desc,
                        style: TextStyle(
                          fontSize: 12.sp,
                          color: isDark ? Colors.white38 : Colors.grey.shade600,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(width: 16.w),
                Image.asset(
                  image,
                  width: 80.w,
                  height: 80.w,
                  fit: BoxFit.contain,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
