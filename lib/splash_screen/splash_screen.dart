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

class _SplashScreenState extends State<SplashScreen> with TickerProviderStateMixin {
  late AnimationController _mainController;
  late AnimationController _shimmerController;

  late Animation<double> _glowOpacity;
  late Animation<double> _taglineOpacity;
  late Animation<double> _letterSpacing;

  final List<String> _letters = ['C', 'O', 'Z', 'E'];

  @override
  void initState() {
    super.initState();

    // 🔹 Main Animation Timeline Controller
    _mainController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    );

    // 🔹 Continuous Shimmer Light Sweep Controller
    _shimmerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat();

    // 1. Ambient Background Glow Opacity
    _glowOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _mainController,
        curve: const Interval(0.0, 0.4, curve: Curves.easeIn),
      ),
    );

    // 2. Letter Spacing Animation (18 -> 8)
    _letterSpacing = Tween<double>(begin: 18.0, end: 8.0).animate(
      CurvedAnimation(
        parent: _mainController,
        curve: const Interval(0.1, 0.6, curve: Curves.easeOutCubic),
      ),
    );

    // 3. Subtitle Tagline Fade In
    _taglineOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _mainController,
        curve: const Interval(0.55, 0.95, curve: Curves.easeIn),
      ),
    );

    // Start Animation Sequence
    _mainController.forward();

    // Startup Initializations
    PermissionManager.instance.requestAllPermissions();
    AdvertiseManager().preloadInterstitial();

    _navigateNext();
  }

  Future<void> _navigateNext() async {
    // Let full animation play smoothly
    await Future.delayed(const Duration(milliseconds: 2800));

    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      if (mounted) {
        _pushReplacement(const IntroPage());
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
            _pushReplacement(const BottomNav());
          }
        } else {
          if (mounted) {
            _pushReplacement(const PersonalDetailsPage());
          }
        }
      } catch (e) {
        debugPrint("Error checking user profile: $e");
        if (mounted) {
          _pushReplacement(const IntroPage());
        }
      }
    }
  }

  void _pushReplacement(Widget page) {
    Navigator.pushReplacement(
      context,
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 600),
        pageBuilder: (_, __, ___) => page,
        transitionsBuilder: (_, animation, __, child) {
          return FadeTransition(opacity: animation, child: child);
        },
      ),
    );
  }

  @override
  void dispose() {
    _mainController.dispose();
    _shimmerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black, // 🖤 Pure Deep Black Background
      body: Stack(
        alignment: Alignment.center,
        children: [
          // 🔹 Soft Blue Ambient Glow Behind Text
          AnimatedBuilder(
            animation: _glowOpacity,
            builder: (context, child) {
              return Opacity(
                opacity: _glowOpacity.value * 0.2,
                child: Container(
                  width: 320.w,
                  height: 200.w,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        Color(0xFF3B82F6),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              );
            },
          ),

          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // 🌟 1. Animated Letters "C O Z E" with Shimmer & Slide Up
                AnimatedBuilder(
                  animation: _mainController,
                  builder: (context, child) {
                    return Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(_letters.length, (index) {
                        final double start = 0.1 + (index * 0.12);
                        final double end = (start + 0.3).clamp(0.0, 1.0);

                        final letterAnimation = CurvedAnimation(
                          parent: _mainController,
                          curve: Interval(start, end, curve: Curves.easeOutBack),
                        );

                        return AnimatedBuilder(
                          animation: letterAnimation,
                          builder: (context, child) {
                            return Opacity(
                              opacity: letterAnimation.value.clamp(0.0, 1.0),
                              child: Transform.translate(
                                offset: Offset(0, 30 * (1 - letterAnimation.value)),
                                child: Padding(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: _letterSpacing.value.w,
                                  ),
                                  child: _buildShimmerText(_letters[index]),
                                ),
                              ),
                            );
                          },
                        );
                      }),
                    );
                  },
                ),

                SizedBox(height: 20.h),

                // 🌟 2. Animated Tagline "CONNECT OUR ZONE WITH EXPERTS"
                AnimatedBuilder(
                  animation: _taglineOpacity,
                  builder: (context, child) {
                    return Opacity(
                      opacity: _taglineOpacity.value,
                      child: Column(
                        children: [
                          Text(
                            "CONNECT OUR ZONE WITH EXPERTS",
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 11.sp,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 2.5,
                              color: Colors.white54,
                            ),
                          ),
                          SizedBox(height: 36.h),
                          SizedBox(
                            width: 22.w,
                            height: 22.w,
                            child: CircularProgressIndicator(
                              color: Colors.blueAccent.withValues(alpha: 0.7),
                              strokeWidth: 2.2,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// 🔹 Shimmer Effect Shader for Brand Name
  Widget _buildShimmerText(String text) {
    return AnimatedBuilder(
      animation: _shimmerController,
      builder: (context, child) {
        return ShaderMask(
          shaderCallback: (bounds) {
            return LinearGradient(
              colors: const [
                Colors.white,
                Colors.blueAccent,
                Colors.white,
              ],
              stops: const [0.0, 0.5, 1.0],
              transform: _GradientSweepTransform(_shimmerController.value),
            ).createShader(bounds);
          },
          child: Text(
            text,
            style: TextStyle(
              fontSize: 48.sp,
              fontWeight: FontWeight.w900,
              color: Colors.white,
              letterSpacing: 2.0,
            ),
          ),
        );
      },
    );
  }
}

class _GradientSweepTransform extends GradientTransform {
  final double value;
  const _GradientSweepTransform(this.value);

  @override
  Matrix4? transform(Rect bounds, {TextDirection? textDirection}) {
    return Matrix4.translationValues(bounds.width * value * 2 - bounds.width, 0, 0);
  }
}
