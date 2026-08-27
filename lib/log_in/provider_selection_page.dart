import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'login_page.dart';
import 'email_login_page.dart';
import 'intro_page.dart';
import 'personal_detail.dart';

class ProviderSelectionPage extends StatefulWidget {
  const ProviderSelectionPage({super.key});

  @override
  State<ProviderSelectionPage> createState() => _ProviderSelectionPageState();
}

class _ProviderSelectionPageState extends State<ProviderSelectionPage> {
  bool isLoading = false;

  Future<void> _handlePostAuthNavigation() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const PersonalDetailsPage()),
      );
    }
  }

  Future<void> _loginWithGoogle() async {
    setState(() => isLoading = true);
    try {
      final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();
      if (googleUser == null) {
        setState(() => isLoading = false);
        return; // User cancelled
      }

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final UserCredential userCredential = await FirebaseAuth.instance.signInWithCredential(credential);
      
      if (userCredential.user != null) {
        await _handlePostAuthNavigation();
      }
    } catch (e) {
      debugPrint("Google Sign-In Error: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Google Sign-In failed: $e"),
            behavior: SnackBarBehavior.floating,
            backgroundColor: Colors.redAccent,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.r)),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black, // ✅ Premium Black BG
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          onPressed: () => Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const IntroPage()),
          ),
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white70),
        ),
      ),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: RadialGradient(
            center: const Alignment(-0.8, -0.6),
            radius: 1.5,
            colors: [
              Colors.blue.withValues(alpha: 0.1),
              Colors.black,
            ],
          ),
        ),
        child: Stack(
          children: [
            // Decorative glow elements
            Positioned(
              top: 150.h,
              right: -50.w,
              child: _buildGlow(120.w, Colors.blueAccent.withValues(alpha: 0.1)),
            ),
            
            SafeArea(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 24.w),
                child: Column(
                  children: [
                    SizedBox(height: 60.h),
                    
                    // ✨ Header Section
                    Text(
                      "Join the Community",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontFamily: 'Mogra',
                        fontSize: 34.sp,
                        color: Colors.white,
                        letterSpacing: 1.5,
                        shadows: [
                          Shadow(color: Colors.blueAccent.withValues(alpha: 0.5), blurRadius: 20)
                        ],
                      ),
                    ),
                    SizedBox(height: 12.h),
                    Text(
                      "Start your journey with the zone's best experts",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 15.sp,
                        color: Colors.white54,
                        letterSpacing: 0.5,
                      ),
                    ),
                    
                    const Spacer(),
                    
                    // 💎 Modern Provider Container
                    Container(
                      padding: EdgeInsets.all(24.r),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.03),
                        borderRadius: BorderRadius.circular(35.r),
                        border: Border.all(color: Colors.white10, width: 1.5),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _buildProviderButton(
                            image: 'assets/images/google.png',
                            label: "Continue with Google",
                            onTap: isLoading ? () {} : _loginWithGoogle,
                          ),
                          SizedBox(height: 16.h),
                          _buildProviderButton(
                            image: 'assets/images/gmail.png',
                            label: "Continue with Email",
                            onTap: isLoading ? () {} : () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (_) => const EmailLoginPage()),
                              ).then((_) => _handlePostAuthNavigation());
                            },
                          ),
                          SizedBox(height: 16.h),
                          _buildProviderButton(
                            image: 'assets/images/phone.png',
                            label: "Continue with Phone",
                            onTap: isLoading ? () {} : () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (_) => const LoginPage()),
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                    
                    const Spacer(),
                    
                    if (isLoading)
                      Padding(
                        padding: EdgeInsets.only(bottom: 20.h),
                        child: const CircularProgressIndicator(color: Colors.blueAccent),
                      ),
                    
                    // Footer Info
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.verified_user_rounded, color: Colors.blueAccent.withValues(alpha: 0.4), size: 14.sp),
                        SizedBox(width: 8.w),
                        Text(
                          "Trusted by 10k+ Experts and Users",
                          style: TextStyle(
                            fontSize: 11.sp,
                            fontWeight: FontWeight.bold,
                            color: Colors.white24,
                            letterSpacing: 1,
                          ),
                        ),
                      ],
                    ),
                    
                    SizedBox(height: 40.h),
                  ],
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
          BoxShadow(color: color, blurRadius: 50, spreadRadius: 10)
        ],
      ),
    );
  }

  Widget _buildProviderButton({
    required String image,
    required String label,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20.r),
        child: Container(
          padding: EdgeInsets.symmetric(vertical: 18.h, horizontal: 20.w),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20.r),
            color: Colors.white.withValues(alpha: 0.05),
            border: Border.all(color: Colors.white.withValues(alpha: 0.05), width: 1),
          ),
          child: Row(
            children: [
              Image.asset(
                image,
                width: 24.w,
                height: 24.w,
                fit: BoxFit.contain,
              ),
              SizedBox(width: 16.w),
              Text(
                label,
                style: TextStyle(
                  fontSize: 15.sp,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                  letterSpacing: 0.5,
                ),
              ),
              const Spacer(),
              Icon(Icons.arrow_forward_ios_rounded, size: 12.sp, color: Colors.white24),
            ],
          ),
        ),
      ),
    );
  }
}
