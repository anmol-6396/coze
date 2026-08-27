import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:firebase_auth/firebase_auth.dart';

class EmailLoginPage extends StatefulWidget {
  const EmailLoginPage({super.key});

  @override
  State<EmailLoginPage> createState() => _EmailLoginPageState();
}

class _EmailLoginPageState extends State<EmailLoginPage> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  bool isLoading = false;
  bool isSignUp = false;
  bool _showPassword = false;

  Future<void> _handleEmailAuth() async {
    final email = emailController.text.trim();
    final password = passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      _showError("Please fill all fields");
      return;
    }

    setState(() => isLoading = true);

    try {
      if (isSignUp) {
        await _auth.createUserWithEmailAndPassword(email: email, password: password);
      } else {
        await _auth.signInWithEmailAndPassword(email: email, password: password);
      }

      if (mounted) {
        Navigator.pop(context); 
      }
    } on FirebaseAuthException catch (e) {
      if (mounted) {
        String msg = "Authentication failed.";
        switch (e.code) {
          case 'user-not-found':
            msg = "Account not found. Please Sign Up.";
            break;
          case 'wrong-password':
            msg = "Incorrect password.";
            break;
          case 'email-already-in-use':
            msg = "Email already registered. Login instead.";
            break;
          case 'weak-password':
            msg = "Password too weak (min 6 chars).";
            break;
          default:
            msg = e.message ?? "An error occurred.";
        }
        _showError(msg);
      }
    } catch (e) {
      if (mounted) _showError("Unexpected error occurred.");
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  Future<void> _resetPassword() async {
    final email = emailController.text.trim();
    if (email.isEmpty) {
      _showError("Enter email to reset password");
      return;
    }
    try {
      await _auth.sendPasswordResetEmail(email: email);
      if (mounted) _showInfo("Reset link sent to your email!");
    } catch (e) {
      if (mounted) _showError("Failed to send reset link.");
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message), 
        backgroundColor: Colors.redAccent,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.r)),
      )
    );
  }
  
  void _showInfo(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message), 
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.r)),
      )
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      resizeToAvoidBottomInset: true,
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: RadialGradient(
            center: const Alignment(0.8, -0.6),
            radius: 1.2,
            colors: [
              Colors.blue.withValues(alpha: 0.1),
              Colors.black,
            ],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: EdgeInsets.symmetric(horizontal: 24.w),
            child: Column(
              children: [
                SizedBox(height: 20.h),
                Align(
                  alignment: Alignment.centerLeft,
                  child: IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white70),
                  ),
                ),
                SizedBox(height: 10.h),
                // 📸 Animated Glow for Icon
                Stack(
                  alignment: Alignment.center,
                  children: [
                    Container(
                      height: 100.h,
                      width: 100.h,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(color: Colors.blue.withValues(alpha: 0.2), blurRadius: 40)
                        ],
                      ),
                    ),
                    Image.asset('assets/images/gmail.png', height: 120.h, fit: BoxFit.contain),
                  ],
                ),
                SizedBox(height: 30.h),
                Text(
                  isSignUp ? "Create Account" : "Access Coze",
                  style: TextStyle(
                    fontFamily: 'Mogra', 
                    fontSize: 30.sp, 
                    color: Colors.white, 
                    letterSpacing: 1.2
                  ),
                ),
                SizedBox(height: 8.h),
                Text(
                  isSignUp ? "Sign up to join our expert community" : "Login with your email and password",
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white54, fontSize: 14.sp),
                ),
                SizedBox(height: 40.h),

                // 💎 Modern Input Card (Glassmorphism)
                Container(
                  padding: EdgeInsets.all(24.r),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.03),
                    borderRadius: BorderRadius.circular(32.r),
                    border: Border.all(color: Colors.white10, width: 1.5),
                  ),
                  child: Column(
                    children: [
                      _buildModernField(
                        controller: emailController, 
                        hint: "Email Address", 
                        icon: Icons.alternate_email_rounded,
                        keyboardType: TextInputType.emailAddress,
                      ),
                      SizedBox(height: 20.h),
                      _buildModernField(
                        controller: passwordController, 
                        hint: "Password", 
                        icon: Icons.lock_outline_rounded, 
                        isObscure: !_showPassword,
                        suffixIcon: IconButton(
                          icon: Icon(
                            _showPassword ? Icons.visibility : Icons.visibility_off,
                            color: Colors.white24,
                            size: 20.sp,
                          ),
                          onPressed: () => setState(() => _showPassword = !_showPassword),
                        ),
                      ),
                      SizedBox(height: 40.h),

                      // 🚀 Action Button
                      Container(
                        width: double.infinity,
                        height: 60.h,
                        decoration: BoxDecoration(
                          boxShadow: [
                            if (!isLoading)
                              BoxShadow(color: Colors.blueAccent.withValues(alpha: 0.3), blurRadius: 15, offset: const Offset(0, 5))
                          ],
                        ),
                        child: ElevatedButton(
                          onPressed: isLoading ? null : _handleEmailAuth,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blueAccent,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18.r)),
                            elevation: 0,
                          ),
                          child: isLoading 
                            ? const SizedBox(height: 24, width: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 3))
                            : Text(
                                isSignUp ? "GET STARTED" : "LOGIN NOW", 
                                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16.sp, letterSpacing: 2)
                              ),
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 32.h),
                
                // Toggle between Login and Sign Up
                TextButton(
                  onPressed: () => setState(() {
                    isSignUp = !isSignUp;
                  }),
                  child: RichText(
                    text: TextSpan(
                      text: isSignUp ? "Already have an account? " : "New to Coze? ",
                      style: TextStyle(color: Colors.white, fontSize: 16.sp),
                      children: [
                        TextSpan(
                          text: isSignUp ? "Login" : "Sign Up",
                          style: const TextStyle(color: Colors.blueAccent, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                ),
                
                if (!isSignUp)
                  TextButton(
                    onPressed: _resetPassword,
                    child: Text(
                      "Forgot Password?", 
                      style: TextStyle(color: Colors.white, fontSize: 14.sp, decoration: TextDecoration.underline)
                    ),
                  ),
                
                SizedBox(height: 40.h),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildModernField({
    required TextEditingController controller, 
    required String hint, 
    required IconData icon, 
    bool isObscure = false, 
    Widget? suffixIcon,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(15.r),
        border: Border.all(color: Colors.white),
      ),
      child: TextField(
        controller: controller,
        obscureText: isObscure,
        keyboardType: keyboardType,
        style: TextStyle(color: Colors.white, fontSize: 15.sp, fontWeight: FontWeight.w600),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(color: Colors.white, fontSize: 14.sp),
          prefixIcon: Icon(icon, color: Colors.blueAccent, size: 20.sp),
          suffixIcon: suffixIcon,
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
        ),
      ),
    );
  }
}
