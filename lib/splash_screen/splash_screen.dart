import 'dart:async';
import 'package:flutter/material.dart';
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
    // Increased delay to let the full-screen GIF play a bit
    await Future.delayed(const Duration(seconds: 3));

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
      backgroundColor: Colors.black, // Dark background for GIF
      body: SizedBox.expand(
        child: Image.asset(
          'assets/images/splashscreen-gif.gif',
          fit: BoxFit.cover, // ✅ Full screen cover
          errorBuilder: (context, error, stackTrace) => const Center(
            child: CircularProgressIndicator(color: Colors.white),
          ),
        ),
      ),
    );
  }
}
