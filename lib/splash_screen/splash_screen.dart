import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:coze/bottom_nav_bar/bottom_nav_bar.dart';
import 'package:coze/log_in/intro_page.dart';
import 'package:coze/log_in/personal_detail.dart';
import 'package:coze/Services/data_manager.dart';
import 'package:coze/Services/permission_manager.dart';
import 'package:coze/advertisement/advertise.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();

    // ✅ Request permissions on startup
    PermissionManager.instance.requestAllPermissions();

    AdvertiseManager().preloadInterstitial();
    _navigateNext();
  }

  Future<void> _navigateNext() async {
    await Future.delayed(const Duration(seconds: 2));

    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const IntroPage()),
        );
      }
    } else {
      try {
        final doc = await FirebaseFirestore.instance
            .collection("users")
            .doc(user.uid)
            .get();

        if (doc.exists) {
          try {
            await DataManager.instance
                .fetchAllData()
                .timeout(const Duration(seconds: 10));
          } catch (e) {
            debugPrint("Data fetch timed out or failed: $e");
          }

          if (mounted) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => const BottomNav()),
            );
          }
        } else {
          if (mounted) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => const PersonalDetailsPage()),
            );
          }
        }
      } catch (e) {
        debugPrint("Error checking user profile: $e");
        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const IntroPage()),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D0E12),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 90.w,
              height: 90.w,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.blueAccent.withValues(alpha: 0.12),
                border: Border.all(color: Colors.blueAccent.withValues(alpha: 0.4), width: 1.5),
                boxShadow: [
                  BoxShadow(
                    color: Colors.blueAccent.withValues(alpha: 0.25),
                    blurRadius: 30,
                    spreadRadius: 5,
                  )
                ],
              ),
              child: Icon(
                Icons.stars_rounded,
                color: Colors.blueAccent,
                size: 42.sp,
              ),
            ),
            SizedBox(height: 20.h),
            Text(
              "COZE",
              style: TextStyle(
                fontSize: 28.sp,
                fontWeight: FontWeight.bold,
                letterSpacing: 4.0,
                color: Colors.white,
              ),
            ),
            SizedBox(height: 24.h),
            SizedBox(
              width: 24.w,
              height: 24.w,
              child: const CircularProgressIndicator(
                color: Colors.blueAccent,
                strokeWidth: 2.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
