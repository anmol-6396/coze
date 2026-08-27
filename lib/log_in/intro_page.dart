import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:internet_connection_checker/internet_connection_checker.dart';
import 'package:flutter/services.dart';
import 'login_page.dart';
import 'provider_selection_page.dart';

class IntroPage extends StatefulWidget {
  const IntroPage({super.key});

  @override
  State<IntroPage> createState() => _IntroPageState();
}

class _IntroPageState extends State<IntroPage> with SingleTickerProviderStateMixin {
  late AnimationController _arrowController;
  late Animation<double> _arrowAnimation;
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    _arrowController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..repeat(reverse: true);
    
    _arrowAnimation = Tween<double>(begin: 0, end: 12).animate(
      CurvedAnimation(parent: _arrowController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _arrowController.dispose();
    super.dispose();
  }

  Future<bool> _checkInternet() async {
    return await InternetConnectionChecker.instance.hasConnection;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(

      appBar: PreferredSize(
        preferredSize: Size.fromHeight(10.h),
        child: AppBar(
          elevation: 0,
          backgroundColor: Colors.white,
        ),
      ),
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
              top: 200.h,
              left: -40.w,
              child: _buildCircle(150.w, Colors.white.withValues(alpha: 0.03)),
            ),
            
            SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Column(
                  children: [
                    // Animated Illustration - Truly Full Width
                    Container(
                      height: 600.h,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.05),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.1),
                            blurRadius: 20.r,
                            offset: Offset(0, 10.h),
                          ),
                        ],
                      ),
                      child: Image.asset(
                        'assets/images/getstart.png',
                        fit: BoxFit.cover, 
                        errorBuilder: (context, error, stackTrace) => Icon(
                          Icons.rocket_launch_rounded,
                          size: 100.sp,
                          color: Colors.white.withValues(alpha: 0.5),
                        ),
                      ),
                    ),

                    SizedBox(height: 12.h),
                    _buildScrollIndicator(),

                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 24.w),
                      child: Column(
                        children: [
                          SizedBox(height: 32.h),
                          // Content Card
                          Container(
                            padding: EdgeInsets.all(24.w),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(32.r),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.2),
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
                                    fontFamily: 'Sniglet',
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
                                  onPressed: isLoading ? null : () async {
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
                                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.r)),
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
                                    minimumSize: Size(double.infinity, 60.h),
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
                                                fontSize: 18.sp,
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
                          
                          SizedBox(height: 40.h),
                          
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
                          SizedBox(height: 80.h), // Extra space for scroll indicator
                        ],
                      ),
                    ),
                  ],
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

  Widget _buildScrollIndicator() {
    return AnimatedBuilder(
      animation: _arrowAnimation,
      builder: (context, child) {
        return Padding(
          padding: EdgeInsets.only(top: _arrowAnimation.value),
          child: Opacity(
            opacity: 1.0 - (_arrowAnimation.value / 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  "Scroll for more",
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.5),
                    fontSize: 10.sp,
                    letterSpacing: 1,
                  ),
                ),
                Icon(
                  Icons.keyboard_double_arrow_down_rounded,
                  color: Colors.white.withValues(alpha: 0.6),
                  size: 28.sp,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
