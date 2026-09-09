import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:internet_connection_checker/internet_connection_checker.dart';
import 'provider_selection_page.dart';

class IntroPage extends StatefulWidget {
  const IntroPage({super.key});

  @override
  State<IntroPage> createState() => _IntroPageState();
}

class _IntroPageState extends State<IntroPage> {
  bool isLoading = false;

  Future<bool> _checkInternet() async {
    return await InternetConnectionChecker.instance.hasConnection;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF090A0F), // 🖤 Deep Premium Black Canvas
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: RadialGradient(
            center: const Alignment(-0.6, -0.7),
            radius: 1.4,
            colors: [
              const Color(0xFF1E2942).withValues(alpha: 0.7),
              const Color(0xFF08090E),
            ],
          ),
        ),
        child: Stack(
          children: [
            // 🔹 Ambient Glowing Background Blobs
            Positioned(
              top: 80.h,
              right: -50.w,
              child: _buildGlow(220.w, const Color(0xFF3B82F6).withValues(alpha: 0.15)),
            ),
            Positioned(
              bottom: 120.h,
              left: -60.w,
              child: _buildGlow(240.w, const Color(0xFF6366F1).withValues(alpha: 0.12)),
            ),

            SafeArea(
              child: Center(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 20.h),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SizedBox(height: 10.h),

                      // 🌟 1. Glowing Brand Icon Header
                      Container(
                        width: 90.w,
                        height: 90.w,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white.withValues(alpha: 0.05),
                          border: Border.all(color: Colors.blueAccent.withValues(alpha: 0.4), width: 1.5),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.blueAccent.withValues(alpha: 0.25),
                              blurRadius: 30,
                              spreadRadius: 4,
                            )
                          ],
                        ),
                        child: Icon(
                          Icons.rocket_launch_rounded,
                          color: Colors.blueAccent,
                          size: 42.sp,
                        ),
                      ),

                      SizedBox(height: 16.h),

                      // 🌟 Brand Title
                      Text(
                        "COZE",
                        style: TextStyle(
                          fontSize: 26.sp,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 4.0,
                          color: Colors.white,
                          shadows: [
                            Shadow(
                              color: Colors.blueAccent.withValues(alpha: 0.5),
                              blurRadius: 20,
                            ),
                          ],
                        ),
                      ),

                      SizedBox(height: 28.h),

                      // 🌟 2. Glassmorphic Dark Card
                      Container(
                        padding: EdgeInsets.all(24.r),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.04),
                          borderRadius: BorderRadius.circular(32.r),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.1),
                            width: 1.2,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.4),
                              blurRadius: 30,
                              offset: const Offset(0, 10),
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            Text(
                              "Empower Your Future",
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 24.sp,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                                letterSpacing: 0.5,
                              ),
                            ),
                            SizedBox(height: 12.h),
                            Text(
                              "Access world-class expertise in just a few taps. We connect you with the best mentors to accelerate your success.",
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 13.5.sp,
                                color: Colors.white70,
                                height: 1.5,
                                letterSpacing: 0.2,
                              ),
                            ),

                            SizedBox(height: 28.h),

                            // 🌟 Feature Highlights Row
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceAround,
                              children: [
                                _buildDarkFeatureItem(Icons.verified_user_rounded, "Verified"),
                                _buildDarkFeatureItem(Icons.bolt_rounded, "Fast"),
                                _buildDarkFeatureItem(Icons.support_agent_rounded, "Support"),
                              ],
                            ),

                            SizedBox(height: 32.h),

                            // 🌟 3. Glowing Action Button
                            Container(
                              width: double.infinity,
                              height: 58.h,
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [Color(0xFF2563EB), Color(0xFF4F46E5)],
                                  begin: Alignment.centerLeft,
                                  end: Alignment.centerRight,
                                ),
                                borderRadius: BorderRadius.circular(20.r),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.blueAccent.withValues(alpha: 0.4),
                                    blurRadius: 20,
                                    offset: const Offset(0, 6),
                                  )
                                ],
                              ),
                              child: ElevatedButton(
                                onPressed: isLoading
                                    ? null
                                    : () async {
                                        setState(() => isLoading = true);
                                        bool hasInternet = await _checkInternet();
                                        if (!mounted) return;
                                        setState(() => isLoading = false);

                                        if (!hasInternet) {
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            SnackBar(
                                              content: const Text("No internet connection"),
                                              backgroundColor: Colors.redAccent,
                                              behavior: SnackBarBehavior.floating,
                                              shape: RoundedRectangleBorder(
                                                borderRadius: BorderRadius.circular(10.r),
                                              ),
                                            ),
                                          );
                                        } else {
                                          Navigator.of(context).pushReplacement(
                                            MaterialPageRoute(
                                              builder: (context) => const ProviderSelectionPage(),
                                            ),
                                          );
                                        }
                                      },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.transparent,
                                  shadowColor: Colors.transparent,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(20.r),
                                  ),
                                ),
                                child: isLoading
                                    ? SizedBox(
                                        height: 22.h,
                                        width: 22.h,
                                        child: const CircularProgressIndicator(
                                          color: Colors.white,
                                          strokeWidth: 2.5,
                                        ),
                                      )
                                    : Row(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Text(
                                            "GET STARTED",
                                            style: TextStyle(
                                              fontSize: 16.sp,
                                              fontWeight: FontWeight.bold,
                                              letterSpacing: 2,
                                              color: Colors.white,
                                            ),
                                          ),
                                          SizedBox(width: 10.w),
                                          Icon(Icons.arrow_forward_rounded, size: 20.sp, color: Colors.white),
                                        ],
                                      ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      SizedBox(height: 32.h),

                      // 🌟 4. Bottom Trust Footer
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.verified_rounded,
                            color: Colors.blueAccent.withValues(alpha: 0.7),
                            size: 15.sp,
                          ),
                          SizedBox(width: 6.w),
                          Text(
                            "TRUSTED BY 10,000+ USERS",
                            style: TextStyle(
                              fontSize: 11.sp,
                              fontWeight: FontWeight.bold,
                              color: Colors.white38,
                              letterSpacing: 1.8,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 16.h),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGlow(double size, Color color) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: color,
            blurRadius: 60,
            spreadRadius: 20,
          ),
        ],
      ),
    );
  }

  Widget _buildDarkFeatureItem(IconData icon, String label) {
    return Column(
      children: [
        Container(
          padding: EdgeInsets.all(10.r),
          decoration: BoxDecoration(
            color: Colors.blueAccent.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(14.r),
            border: Border.all(color: Colors.blueAccent.withValues(alpha: 0.2)),
          ),
          child: Icon(icon, color: Colors.blueAccent, size: 22.sp),
        ),
        SizedBox(height: 6.h),
        Text(
          label,
          style: TextStyle(
            fontSize: 12.sp,
            fontWeight: FontWeight.w600,
            color: Colors.white70,
          ),
        ),
      ],
    );
  }
}
