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
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF6B52B6),
              Color(0xFF4A3592),
              Color(0xFF311B92),
            ],
          ),
        ),
        child: Stack(
          children: [
            // Decorative background elements (Abstract shapes)
            Positioned(
              top: -40.h,
              right: -30.w,
              child: _buildCircle(300.w, Colors.white.withValues(alpha: 0.05)),
            ),
            Positioned(
              bottom: 100.h,
              left: -40.w,
              child: _buildCircle(200.w, Colors.white.withValues(alpha: 0.03)),
            ),

            SafeArea(
              child: Center(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 20.h),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SizedBox(height: 20.h),

                      // Brand Icon Header (No Picture Assets)
                      Container(
                        width: 90.w,
                        height: 90.w,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white.withValues(alpha: 0.12),
                          border: Border.all(color: Colors.white24, width: 1.5),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.2),
                              blurRadius: 30,
                              spreadRadius: 5,
                            )
                          ],
                        ),
                        child: Icon(
                          Icons.rocket_launch_rounded,
                          color: Colors.white,
                          size: 42.sp,
                        ),
                      ),

                      SizedBox(height: 32.h),

                      // Content Card
                      Container(
                        padding: EdgeInsets.all(24.w),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(32.r),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.25),
                              blurRadius: 30.r,
                              offset: Offset(0, 10.h),
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            Text(
                              "Empower Your Future",
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 26.sp,
                                fontWeight: FontWeight.bold,
                                color: const Color(0xFF311B92),
                              ),
                            ),
                            SizedBox(height: 16.h),
                            Text(
                              "Access world-class expertise in just a few taps. We connect you with the best mentors to accelerate your success.",
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 15.sp,
                                color: Colors.grey.shade600,
                                height: 1.6,
                              ),
                            ),

                            SizedBox(height: 32.h),

                            // Feature Row
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceAround,
                              children: [
                                _buildFeatureItem(Icons.verified_user_rounded, "Verified"),
                                _buildFeatureItem(Icons.flash_on_rounded, "Fast"),
                                _buildFeatureItem(Icons.support_agent_rounded, "Support"),
                              ],
                            ),

                            SizedBox(height: 32.h),

                            // Primary Action Button
                            ElevatedButton(
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
                                backgroundColor: const Color(0xFF6B52B6),
                                foregroundColor: Colors.white,
                                minimumSize: Size(double.infinity, 58.h),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(20.r),
                                ),
                                elevation: 8,
                                shadowColor: const Color(0xFF6B52B6).withValues(alpha: 0.4),
                              ),
                              child: isLoading
                                  ? SizedBox(
                                      height: 24.h,
                                      width: 24.h,
                                      child: const CircularProgressIndicator(
                                        color: Colors.white,
                                        strokeWidth: 3,
                                      ),
                                    )
                                  : Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Text(
                                          "GET STARTED",
                                          style: TextStyle(
                                            fontSize: 17.sp,
                                            fontWeight: FontWeight.bold,
                                            letterSpacing: 2,
                                          ),
                                        ),
                                        SizedBox(width: 12.w),
                                        Icon(Icons.arrow_forward_ios_rounded, size: 18.sp),
                                      ],
                                    ),
                            ),
                          ],
                        ),
                      ),

                      SizedBox(height: 32.h),

                      // Bottom Footer
                      Text(
                        "TRUSTED BY 10,000+ USERS",
                        style: TextStyle(
                          fontSize: 10.sp,
                          fontWeight: FontWeight.bold,
                          color: Colors.white.withValues(alpha: 0.6),
                          letterSpacing: 2,
                        ),
                      ),
                      SizedBox(height: 20.h),
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

  Widget _buildCircle(double size, Color color) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color,
      ),
    );
  }

  Widget _buildFeatureItem(IconData icon, String label) {
    return Column(
      children: [
        Icon(icon, color: const Color(0xFF6B52B6), size: 24.sp),
        SizedBox(height: 4.h),
        Text(
          label,
          style: TextStyle(
            fontSize: 12.sp,
            fontWeight: FontWeight.w600,
            color: Colors.grey.shade700,
          ),
        ),
      ],
    );
  }
}
