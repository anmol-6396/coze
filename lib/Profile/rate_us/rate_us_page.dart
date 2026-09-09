import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class RateUsPage extends StatefulWidget {
  const RateUsPage({super.key});

  @override
  State<RateUsPage> createState() => _RateUsPageState();
}

class _RateUsPageState extends State<RateUsPage> with TickerProviderStateMixin {
  int _rating = 0;
  final TextEditingController _feedbackController = TextEditingController();

  late AnimationController _shimmerController;
  late AnimationController _pulseController;
  late Animation<double> _pulseScale;

  final List<String> _letters = ['C', 'O', 'Z', 'E'];

  @override
  void initState() {
    super.initState();

    // 🔹 Shimmer Light Sweep Controller (Splash Style)
    _shimmerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat();

    // 🔹 Pulse Animation for Logo Badge
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);

    _pulseScale = Tween<double>(begin: 0.95, end: 1.05).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _shimmerController.dispose();
    _pulseController.dispose();
    _feedbackController.dispose();
    super.dispose();
  }

  String _getRatingText() {
    switch (_rating) {
      case 1:
        return "Terrible";
      case 2:
        return "Bad";
      case 3:
        return "Okay";
      case 4:
        return "Good";
      case 5:
        return "Excellent!";
      default:
        return "Tap a star to rate";
    }
  }

  Color _getRatingColor() {
    switch (_rating) {
      case 1:
        return Colors.redAccent;
      case 2:
        return Colors.orangeAccent;
      case 3:
        return Colors.amber;
      case 4:
        return Colors.lightGreenAccent.shade400;
      case 5:
        return Colors.greenAccent.shade400;
      default:
        return Colors.blueAccent;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final content = Container(
      width: double.infinity,
      height: double.infinity,
      color: isDark ? const Color(0xFF090A0F) : const Color(0xFFF8F9FE),
      child: Stack(
        children: [
          // 🔹 Ambient Glowing Background Pulse (Splash Style)
          Positioned(
            top: 40.h,
            right: -40.w,
            child: _buildGlow(200.w, Colors.blueAccent.withValues(alpha: isDark ? 0.15 : 0.08)),
          ),
          Positioned(
            bottom: 60.h,
            left: -50.w,
            child: _buildGlow(220.w, Colors.indigoAccent.withValues(alpha: isDark ? 0.12 : 0.06)),
          ),

          SafeArea(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 16.h),
              child: Column(
                children: [
                  SizedBox(height: 10.h),

                  // 🌟 1. Glowing Animated Star/Crown Badge (Splash Style)
                  ScaleTransition(
                    scale: _pulseScale,
                    child: Container(
                      width: 80.w,
                      height: 80.w,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.blueAccent.withValues(alpha: 0.12),
                        border: Border.all(
                          color: Colors.blueAccent.withValues(alpha: 0.5),
                          width: 1.5,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.blueAccent.withValues(alpha: 0.3),
                            blurRadius: 25,
                            spreadRadius: 4,
                          )
                        ],
                      ),
                      child: Icon(
                        Icons.stars_rounded,
                        color: Colors.blueAccent,
                        size: 40.sp,
                      ),
                    ),
                  ),

                  SizedBox(height: 16.h),

                  // 🌟 2. Shimmer COZE Brand Header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: _letters.map((letter) {
                      return Padding(
                        padding: EdgeInsets.symmetric(horizontal: 3.w),
                        child: _buildShimmerText(letter),
                      );
                    }).toList(),
                  ),

                  SizedBox(height: 8.h),

                  Text(
                    "ENJOYING COZE?",
                    style: TextStyle(
                      fontSize: 12.sp,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 2.0,
                      color: isDark ? Colors.white54 : Colors.grey.shade600,
                    ),
                  ),

                  SizedBox(height: 24.h),

                  // 🌟 3. Glassmorphic Rating Card
                  Container(
                    padding: EdgeInsets.all(24.r),
                    decoration: BoxDecoration(
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.04)
                          : Colors.white,
                      borderRadius: BorderRadius.circular(28.r),
                      border: Border.all(
                        color: isDark
                            ? Colors.white.withValues(alpha: 0.1)
                            : Colors.black.withValues(alpha: 0.06),
                        width: 1.2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: isDark
                              ? Colors.black.withValues(alpha: 0.4)
                              : Colors.black.withValues(alpha: 0.05),
                          blurRadius: 20,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        Text(
                          _getRatingText(),
                          style: TextStyle(
                            fontSize: 18.sp,
                            fontWeight: FontWeight.w900,
                            color: _getRatingColor(),
                            letterSpacing: 0.8,
                          ),
                        ),
                        SizedBox(height: 18.h),

                        // Interactive Stars
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: List.generate(5, (index) {
                            bool isSelected = index < _rating;
                            return GestureDetector(
                              onTap: () => setState(() => _rating = index + 1),
                              child: Padding(
                                padding: EdgeInsets.symmetric(horizontal: 4.w),
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 200),
                                  transform: Matrix4.identity()
                                    ..scale(isSelected ? 1.15 : 1.0),
                                  child: Icon(
                                    isSelected ? Icons.star_rounded : Icons.star_outline_rounded,
                                    size: 42.sp,
                                    color: isSelected
                                        ? Colors.amberAccent
                                        : (isDark ? Colors.white24 : Colors.grey.shade300),
                                  ),
                                ),
                              ),
                            );
                          }),
                        ),
                      ],
                    ),
                  ),

                  SizedBox(height: 20.h),

                  // 🌟 4. Feedback Input Box
                  TextField(
                    controller: _feedbackController,
                    maxLines: 3,
                    style: TextStyle(
                      color: isDark ? Colors.white : Colors.black87,
                      fontSize: 14.sp,
                    ),
                    decoration: InputDecoration(
                      hintText: "Write a short review or suggestion (Optional)",
                      hintStyle: TextStyle(
                        color: isDark ? Colors.white38 : Colors.grey.shade500,
                        fontSize: 13.sp,
                      ),
                      filled: true,
                      fillColor: isDark
                          ? Colors.white.withValues(alpha: 0.04)
                          : Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20.r),
                        borderSide: BorderSide(
                          color: isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.06),
                        ),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20.r),
                        borderSide: BorderSide(
                          color: isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.06),
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20.r),
                        borderSide: const BorderSide(color: Colors.blueAccent, width: 1.5),
                      ),
                      contentPadding: EdgeInsets.all(18.r),
                    ),
                  ),

                  SizedBox(height: 28.h),

                  // 🌟 5. Action Buttons (Submit & Play Store)
                  Container(
                    width: double.infinity,
                    height: 56.h,
                    decoration: BoxDecoration(
                      gradient: _rating == 0
                          ? null
                          : const LinearGradient(
                              colors: [Color(0xFF2563EB), Color(0xFF1D4ED8)],
                            ),
                      color: _rating == 0
                          ? (isDark ? Colors.white12 : Colors.grey.shade300)
                          : null,
                      borderRadius: BorderRadius.circular(18.r),
                      boxShadow: [
                        if (_rating > 0)
                          BoxShadow(
                            color: Colors.blueAccent.withValues(alpha: 0.35),
                            blurRadius: 15,
                            offset: const Offset(0, 5),
                          ),
                      ],
                    ),
                    child: ElevatedButton(
                      onPressed: _rating == 0 ? null : _submitToFirebase,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        shadowColor: Colors.transparent,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18.r)),
                      ),
                      child: Text(
                        "SUBMIT FEEDBACK",
                        style: TextStyle(
                          fontSize: 15.sp,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.2,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),

                  SizedBox(height: 14.h),

                  SizedBox(
                    width: double.infinity,
                    height: 54.h,
                    child: OutlinedButton.icon(
                      onPressed: _launchPlayStore,
                      icon: Icon(Icons.shop_two_rounded, color: Colors.blueAccent, size: 20.sp),
                      label: Text(
                        "RATE ON PLAY STORE",
                        style: TextStyle(
                          fontSize: 14.sp,
                          fontWeight: FontWeight.bold,
                          color: Colors.blueAccent,
                          letterSpacing: 1.0,
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Colors.blueAccent, width: 1.5),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18.r)),
                      ),
                    ),
                  ),

                  SizedBox(height: 24.h),
                ],
              ),
            ),
          ),
        ],
      ),
    );

    if (Platform.isIOS) {
      return CupertinoPageScaffold(
        navigationBar: CupertinoNavigationBar(
          middle: const Text("Rate Us"),
          backgroundColor: isDark ? const Color(0xFF12141A) : Colors.white,
        ),
        child: SafeArea(child: content),
      );
    } else {
      return Scaffold(
        appBar: AppBar(
          title: const Text("Rate Us", style: TextStyle(fontWeight: FontWeight.bold)),
          backgroundColor: Colors.blueAccent,
          foregroundColor: Colors.white,
          centerTitle: true,
          elevation: 0,
        ),
        body: content,
      );
    }
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
              fontSize: 32.sp,
              fontWeight: FontWeight.w900,
              color: Colors.white,
              letterSpacing: 1.5,
            ),
          ),
        );
      },
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

  Future<void> _submitToFirebase() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      await FirebaseFirestore.instance.collection("ratings").add({
        "uid": user?.uid ?? "anonymous",
        "name": user?.displayName ?? "User",
        "email": user?.email ?? "No Email",
        "rating": _rating,
        "feedback": _feedbackController.text.trim(),
        "timestamp": FieldValue.serverTimestamp(),
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text("Thank you! Your feedback is saved."),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.r)),
          ),
        );

        if (_rating >= 4) {
          _showPlayStoreDialog();
        } else {
          Navigator.pop(context);
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
      }
    }
  }

  Future<void> _launchPlayStore() async {
    final uri = Uri.parse("https://play.google.com/store/apps/details?id=com.anmol.coze");
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  void _showPlayStoreDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20.r)),
        title: const Text("Excellent!", style: TextStyle(fontWeight: FontWeight.bold)),
        content: const Text("Would you like to share your review on Play Store as well? It helps us reach more people!"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("NOT NOW")),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _launchPlayStore();
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blueAccent,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.r)),
            ),
            child: const Text("RATE ON PLAY STORE"),
          ),
        ],
      ),
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
