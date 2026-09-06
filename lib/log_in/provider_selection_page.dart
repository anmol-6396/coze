import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'login_page.dart';
import 'email_login_page.dart';
import 'intro_page.dart';
import 'personal_detail.dart';
import 'package:coze/bottom_nav_bar/bottom_nav_bar.dart';

class ProviderSelectionPage extends StatefulWidget {
  final bool isGuestPrompt;
  const ProviderSelectionPage({super.key, this.isGuestPrompt = false});

  @override
  State<ProviderSelectionPage> createState() => _ProviderSelectionPageState();
}

class _ProviderSelectionPageState extends State<ProviderSelectionPage> {
  bool isLoading = false;

  Future<void> _handlePostAuthNavigation() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      final doc = await FirebaseFirestore.instance
          .collection("users")
          .doc(user.uid)
          .get();

      if (!mounted) return;

      if (doc.exists) {
        if (widget.isGuestPrompt) {
          Navigator.pop(context, true);
        } else {
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (_) => const BottomNav()),
            (route) => false,
          );
        }
      } else {
        final setupDone = await Navigator.push<bool>(
          context,
          MaterialPageRoute(
            builder: (_) => PersonalDetailsPage(isGuestPrompt: widget.isGuestPrompt),
          ),
        );
        if (!mounted) return;
        if (widget.isGuestPrompt) {
          Navigator.pop(context, setupDone == true);
        } else if (setupDone == true) {
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (_) => const BottomNav()),
            (route) => false,
          );
        }
      }
    } catch (e) {
      debugPrint("Error checking profile doc: $e");
      if (!mounted) return;
      if (widget.isGuestPrompt) {
        Navigator.pop(context, true);
      } else {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const BottomNav()),
          (route) => false,
        );
      }
    }
  }

  Future<void> _loginWithGoogle() async {
    if (isLoading) return;
    setState(() => isLoading = true);

    try {
      final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();
      if (googleUser == null) {
        if (mounted) setState(() => isLoading = false);
        return; // User cancelled
      }

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final UserCredential userCredential =
          await FirebaseAuth.instance.signInWithCredential(credential);

      if (!mounted) return;

      if (userCredential.user != null) {
        await _handlePostAuthNavigation();
      }
    } catch (e) {
      debugPrint("Google Sign-In Error: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Google Sign-In failed: ${e.toString()}"),
            behavior: SnackBarBehavior.floating,
            backgroundColor: Colors.redAccent,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.r)),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  Future<void> _loginWithApple() async {
    if (isLoading) return;
    setState(() => isLoading = true);

    try {
      final appleProvider = AppleAuthProvider();
      final UserCredential userCredential =
          await FirebaseAuth.instance.signInWithProvider(appleProvider);

      if (!mounted) return;

      if (userCredential.user != null) {
        await _handlePostAuthNavigation();
      }
    } catch (e) {
      debugPrint("Apple Sign-In Error: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Apple Sign-In failed: ${e.toString()}"),
            behavior: SnackBarBehavior.floating,
            backgroundColor: Colors.redAccent,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.r)),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D0E12),
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: Padding(
          padding: EdgeInsets.all(8.r),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.08),
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
            ),
            child: widget.isGuestPrompt
                ? IconButton(
                    padding: EdgeInsets.zero,
                    onPressed: () => Navigator.pop(context, false),
                    icon: const Icon(Icons.close_rounded, color: Colors.white, size: 20),
                  )
                : IconButton(
                    padding: EdgeInsets.zero,
                    onPressed: () => Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(builder: (_) => const IntroPage()),
                    ),
                    icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white70, size: 18),
                  ),
          ),
        ),
      ),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: RadialGradient(
            center: const Alignment(-0.6, -0.7),
            radius: 1.4,
            colors: [
              const Color(0xFF1E2942).withValues(alpha: 0.6),
              const Color(0xFF0B0D13),
            ],
          ),
        ),
        child: Stack(
          children: [
            // Decorative background glowing elements
            Positioned(
              top: 100.h,
              right: -40.w,
              child: _buildGlow(160.w, const Color(0xFF3B82F6).withValues(alpha: 0.15)),
            ),
            Positioned(
              bottom: 80.h,
              left: -60.w,
              child: _buildGlow(180.w, const Color(0xFF6366F1).withValues(alpha: 0.12)),
            ),

            SafeArea(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 24.w),
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: Column(
                    children: [
                      SizedBox(height: 15.h),

                      // Brand Logo Header
                      Container(
                        width: 70.w,
                        height: 70.w,
                        padding: EdgeInsets.all(12.r),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white.withValues(alpha: 0.05),
                          border: Border.all(color: Colors.white.withValues(alpha: 0.12), width: 1.5),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF3B82F6).withValues(alpha: 0.2),
                              blurRadius: 25,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                        child: Image.asset(
                          'assets/images/cozeblack.png',
                          fit: BoxFit.contain,
                          errorBuilder: (context, error, stackTrace) => const Icon(
                            Icons.stars_rounded,
                            color: Colors.blueAccent,
                            size: 32,
                          ),
                        ),
                      ),

                      SizedBox(height: 20.h),

                      // Header Text
                      Text(
                        widget.isGuestPrompt ? "Login Required" : "Welcome to Coze",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 26.sp,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          letterSpacing: 0.8,
                          shadows: [
                            Shadow(
                              color: Colors.blueAccent.withValues(alpha: 0.4),
                              blurRadius: 15,
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: 8.h),
                      Text(
                        widget.isGuestPrompt
                            ? "Please log in to view details, save favorites, or connect with experts."
                            : "Connect with the top experts in your zone instantly.",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 13.sp,
                          color: Colors.white.withValues(alpha: 0.7),
                          height: 1.4,
                          letterSpacing: 0.3,
                        ),
                      ),

                      SizedBox(height: 28.h),

                      // Modern Provider Buttons Container
                      Container(
                        padding: EdgeInsets.all(20.r),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.04),
                          borderRadius: BorderRadius.circular(28.r),
                          border: Border.all(color: Colors.white.withValues(alpha: 0.08), width: 1.2),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.3),
                              blurRadius: 20,
                              offset: const Offset(0, 10),
                            ),
                          ],
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (Platform.isIOS) ...[
                              _buildProviderButton(
                                image: 'assets/images/apple.png',
                                label: "Continue with Apple",
                                fallbackIcon: Icons.apple,
                                onTap: isLoading ? null : _loginWithApple,
                              ),
                              SizedBox(height: 14.h),
                            ],
                            _buildProviderButton(
                              image: 'assets/images/google.png',
                              label: "Continue with Google",
                              fallbackIcon: Icons.g_mobiledata_rounded,
                              onTap: isLoading ? null : _loginWithGoogle,
                            ),
                            SizedBox(height: 14.h),
                            _buildProviderButton(
                              image: 'assets/images/gmail.png',
                              label: "Continue with Email",
                              fallbackIcon: Icons.email_rounded,
                              onTap: isLoading
                                  ? null
                                  : () async {
                                      await Navigator.push(
                                        context,
                                        MaterialPageRoute(builder: (_) => const EmailLoginPage()),
                                      );
                                      if (mounted) {
                                        _handlePostAuthNavigation();
                                      }
                                    },
                            ),
                            SizedBox(height: 14.h),
                            _buildProviderButton(
                              image: 'assets/images/phone.png',
                              label: "Continue with Phone",
                              fallbackIcon: Icons.phone_android_rounded,
                              onTap: isLoading
                                  ? null
                                  : () async {
                                      await Navigator.push(
                                        context,
                                        MaterialPageRoute(builder: (_) => const LoginPage()),
                                      );
                                      if (mounted) {
                                        _handlePostAuthNavigation();
                                      }
                                    },
                            ),
                          ],
                        ),
                      ),

                      SizedBox(height: 24.h),

                      if (isLoading)
                        Padding(
                          padding: EdgeInsets.only(bottom: 16.h),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              SizedBox(
                                width: 18.w,
                                height: 18.w,
                                child: const CircularProgressIndicator(
                                  color: Colors.blueAccent,
                                  strokeWidth: 2,
                                ),
                              ),
                              SizedBox(width: 10.w),
                              Text(
                                "Authenticating...",
                                style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: 12.sp,
                                ),
                              ),
                            ],
                          ),
                        ),

                      // Footer Info
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.verified_user_rounded,
                            color: Colors.blueAccent.withValues(alpha: 0.6),
                            size: 15.sp,
                          ),
                          SizedBox(width: 6.w),
                          Text(
                            "Trusted by 10k+ Experts & Users",
                            style: TextStyle(
                              fontSize: 11.sp,
                              fontWeight: FontWeight.w600,
                              color: Colors.white38,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),

                      SizedBox(height: 16.h),

                      // Terms & Privacy
                      Text(
                        "By continuing, you agree to our Terms & Privacy Policy.",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 10.sp,
                          color: Colors.white24,
                          height: 1.3,
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

  Widget _buildProviderButton({
    required String image,
    required String label,
    required IconData fallbackIcon,
    required VoidCallback? onTap,
  }) {
    final bool disabled = onTap == null;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20.r),
        child: AnimatedOpacity(
          duration: const Duration(milliseconds: 200),
          opacity: disabled ? 0.5 : 1.0,
          child: Container(
            padding: EdgeInsets.symmetric(vertical: 16.h, horizontal: 18.w),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20.r),
              color: Colors.white.withValues(alpha: 0.05),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.08),
                width: 1,
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 32.w,
                  height: 32.w,
                  padding: EdgeInsets.all(4.r),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(10.r),
                  ),
                  child: Image.asset(
                    image,
                    width: 22.w,
                    height: 22.w,
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) => Icon(
                      fallbackIcon,
                      color: Colors.white,
                      size: 20.sp,
                    ),
                  ),
                ),
                SizedBox(width: 14.w),
                Expanded(
                  child: Text(
                    label,
                    style: TextStyle(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                      letterSpacing: 0.3,
                    ),
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 12.sp,
                  color: Colors.white30,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
