import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:coze/Profile/custom_app_bar/app_bar_widget.dart';
import 'package:coze/Services/theme_manager.dart';

class AboutCozePage extends StatelessWidget {
  const AboutCozePage({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = ThemeManager.instance.isDarkMode;

    return Scaffold(
      backgroundColor: isDark ? Colors.black : Colors.grey[50],
      appBar: const CustomAppBar(
        title: "About Coze",
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(20.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            SizedBox(height: 20.h),
            // App Logo
            Container(
              height: 100.w,
              width: 100.w,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.indigo.withValues(alpha: 0.2),
                    blurRadius: 20,
                    spreadRadius: 5,
                  )
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(50.r),
                child: Image.asset('assets/images/cozeblack.png', fit: BoxFit.cover),
              ),
            ),
            SizedBox(height: 20.h),
            Text(
              "COZE",
              style: TextStyle(
                fontSize: 32.sp,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.lightBlueAccent : Colors.indigo,
              ),
            ),

            SizedBox(height: 30.h),

            // Tagline
            Text(
              "Connect Our Zone of Experts",
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 18.sp,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white70 : Colors.black87,
              ),
            ),
            SizedBox(height: 15.h),
            Text(
              "Coze is a comprehensive platform designed to bridge the gap between service providers and those in search of expertise. Whether you are a student looking for the best coaching, a professional searching for job opportunities, or a parent seeking qualified home tutors, Coze brings everything to your fingertips.",
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14.sp,
                height: 1.6,
                color: isDark ? Colors.white60 : Colors.black54,
              ),
            ),
            
            SizedBox(height: 40.h),

            // Features Section
            _buildSectionTitle("What we offer", isDark),
            SizedBox(height: 15.h),
            _buildFeatureRow(Icons.school, "Education", "Find schools, colleges, and coaching institutes near you.", isDark),
            _buildFeatureRow(Icons.home, "Home Tutors", "Connect with verified tutors for personalized learning at home.", isDark),
            _buildFeatureRow(Icons.work, "Job Board", "Discover local job openings and career growth opportunities.", isDark),
            _buildFeatureRow(Icons.star, "Skill Development", "Learn new skills from experts in various domains.", isDark),

            SizedBox(height: 40.h),

            // Missions
            _buildSectionTitle("Our Mission", isDark),
            SizedBox(height: 16.h),
            Container(
              padding: EdgeInsets.all(16.r),
              decoration: BoxDecoration(
                color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.indigo.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(16.r),
                border: Border.all(color: isDark ? Colors.white10 : Colors.indigo.withValues(alpha: 0.1)),
              ),
              child: Text(
                "Our mission is to create a transparent and accessible ecosystem where local expertise is recognized and easily reachable. We believe that everyone deserves the right connection to succeed in their educational and professional journey.",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14.sp,
                  height: 1.6,
                  fontStyle: FontStyle.italic,
                  color: isDark ? Colors.white70 : Colors.indigo.shade900,
                ),
              ),
            ),

            SizedBox(height: 40.h),

            // Footer / Links
            Divider(color: isDark ? Colors.white10 : Colors.grey[300]),
            SizedBox(height: 24.h),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildSocialIcon(Icons.language, "Website", () {}),
                SizedBox(width: 40.w),
                _buildSocialIcon(Icons.email, "Contact Us", () async {
                  final Uri emailUri = Uri(
                    scheme: 'mailto',
                    path: 'support@coze.com',
                    query: 'subject=Feedback for Coze App',
                  );
                  if (await canLaunchUrl(emailUri)) {
                    await launchUrl(emailUri);
                  }
                }),
              ],
            ),
            SizedBox(height: 30.h),
            Text(
              "© 2025 Coze. All rights reserved.",
              style: TextStyle(fontSize: 12.sp, color: Colors.grey),
            ),
            SizedBox(height: 20.h),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title, bool isDark) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 20.sp,
        fontWeight: FontWeight.bold,
        color: isDark ? Colors.lightBlueAccent : Colors.indigo,
      ),
    );
  }

  Widget _buildFeatureRow(IconData icon, String title, String desc, bool isDark) {
    return Padding(
      padding: EdgeInsets.only(bottom: 20.h),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: EdgeInsets.all(10.w),
            decoration: BoxDecoration(
              color: Colors.blue.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: Colors.blue, size: 22.sp),
          ),
          SizedBox(width: 15.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
                SizedBox(height: 4.h),
                Text(
                  desc,
                  style: TextStyle(
                    fontSize: 13.sp,
                    color: isDark ? Colors.white60 : Colors.black54,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSocialIcon(IconData icon, String label, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Icon(icon, color: Colors.blue, size: 28.sp),
          SizedBox(height: 5.h),
          Text(label, style: TextStyle(fontSize: 12.sp, color: Colors.blue)),
        ],
      ),
    );
  }
}
