import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:internet_connection_checker/internet_connection_checker.dart';
import 'provider_selection_page.dart';

class IntroPage extends StatefulWidget {
  const IntroPage({super.key});

  @override
  State<IntroPage> createState() => _IntroPageState();
}

class _IntroPageState extends State<IntroPage> with TickerProviderStateMixin {
  late AnimationController _mainController;
  late AnimationController _shimmerController;

  late Animation<double> _glowOpacity;
  late Animation<double> _letterSpacing;
  late Animation<double> _cardOpacity;
  late Animation<Offset> _cardSlide;

  final List<String> _letters = ['C', 'O', 'Z', 'E'];
  bool isLoading = false;

  @override
  void initState() {
    super.initState();

    // 🔹 Main Entrance Animation Sequence Controller
    _mainController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    );

    // 🔹 Continuous Shimmer Light Sweep Controller
    _shimmerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat();

    // 1. Ambient Glow Fade In
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

    // 3. Card Fade In & Slide Up
    _cardOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _mainController,
        curve: const Interval(0.5, 0.9, curve: Curves.easeIn),
      ),
    );

    _cardSlide = Tween<Offset>(begin: const Offset(0, 0.15), end: Offset.zero).animate(
      CurvedAnimation(
        parent: _mainController,
        curve: const Interval(0.5, 0.95, curve: Curves.easeOutCubic),
      ),
    );

    // Start Entrance Timeline
    _mainController.forward();
  }

  @override
  void dispose() {
    _mainController.dispose();
    _shimmerController.dispose();
    super.dispose();
  }

  Future<bool> _checkInternet() async {
    return await InternetConnectionChecker.instance.hasConnection;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF090A0F), // 🖤 Deep Black Screen
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
          alignment: Alignment.center,
          children: [
            // 🔹 Ambient Glowing Background Pulse
            AnimatedBuilder(
              animation: _glowOpacity,
              builder: (context, child) {
                return Opacity(
                  opacity: _glowOpacity.value * 0.25,
                  child: Container(
                    width: 320.w,
                    height: 240.w,
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

            SafeArea(
              child: Center(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 20.h),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SizedBox(height: 10.h),

                      // 🌟 1. Animated Letters "C O Z E" with Shimmer & Staggered Entrance
                      AnimatedBuilder(
                        animation: _mainController,
                        builder: (context, child) {
                          return Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: List.generate(_letters.length, (index) {
                              final double start = 0.1 + (index * 0.1);
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
                                      offset: Offset(0, 24 * (1 - letterAnimation.value)),
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

                      SizedBox(height: 12.h),

                      // 🌟 Tagline
                      Text(
                        "CONNECT OUR ZONE WITH EXPERTS",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 10.5.sp,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 2.2,
                          color: Colors.white54,
                        ),
                      ),

                      SizedBox(height: 36.h),

                      // 🌟 2. Animated Entrance for Content Card
                      SlideTransition(
                        position: _cardSlide,
                        child: FadeTransition(
                          opacity: _cardOpacity,
                          child: Container(
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

                                // Feature Highlights Row
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

  /// 🔹 Shimmer Shader Effect for Brand Name
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
              fontSize: 42.sp,
              fontWeight: FontWeight.w900,
              color: Colors.white,
              letterSpacing: 2.0,
            ),
          ),
        );
      },
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

class _GradientSweepTransform extends GradientTransform {
  final double value;
  const _GradientSweepTransform(this.value);

  @override
  Matrix4? transform(Rect bounds, {TextDirection? textDirection}) {
    return Matrix4.translationValues(bounds.width * value * 2 - bounds.width, 0, 0);
  }
}
