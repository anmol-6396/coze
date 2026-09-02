import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'intro_page.dart';
import 'otp_page.dart';
import 'personal_detail.dart';

class LoginPage extends StatefulWidget {
  final bool forceLinkMode;

  const LoginPage({super.key, this.forceLinkMode = false});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController phoneController = TextEditingController();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    if (!widget.forceLinkMode) {
      _checkAuthState();
    }
  }

  Future<void> _checkAuthState() async {
    final user = _auth.currentUser;
    if (user != null) {
      final doc = await FirebaseFirestore.instance
          .collection("users")
          .doc(user.uid)
          .get();

      if (mounted) {
        if (!doc.exists) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const PersonalDetailsPage()),
          );
        }
      }
    }
  }

  Future<void> _loginWithPhone() async {
    String phone = phoneController.text.trim();

    if (phone.length != 10) {
      _showError("Enter a valid 10 digit number");
      return;
    }

    phone = "+91$phone";
    setState(() => isLoading = true);

    try {
      await _auth.verifyPhoneNumber(
        phoneNumber: phone,
        verificationCompleted: (PhoneAuthCredential credential) async {
          if (widget.forceLinkMode) {
            await _auth.currentUser?.linkWithCredential(credential);
          } else {
            await _auth.signInWithCredential(credential);
          }
          
          if (mounted) {
            setState(() => isLoading = false);
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => const PersonalDetailsPage()),
            );
          }
        },
        verificationFailed: (FirebaseAuthException e) {
          if (mounted) {
            setState(() => isLoading = false);
            _showError("Verification failed: ${e.message}");
          }
        },
        codeSent: (String verificationId, int? resendToken) {
          if (mounted) {
            setState(() => isLoading = false);
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => OtpPage(
                  loginType: "Phone",
                  identifier: phone,
                  verificationId: verificationId,
                  isLinking: widget.forceLinkMode,
                ),
              ),
            );
          }
        },
        codeAutoRetrievalTimeout: (String verificationId) {
          if (mounted) setState(() => isLoading = false);
        },
      );
    } catch (e) {
      if (mounted) {
        setState(() => isLoading = false);
        _showError("Unexpected error: $e");
      }
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.redAccent,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.r)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black, // ✅ Premium Black BG
      resizeToAvoidBottomInset: true,
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: RadialGradient(
            center: const Alignment(-0.8, -0.6),
            radius: 1.2,
            colors: [
              Colors.blue.withValues(alpha: 0.15),
              Colors.black,
            ],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Padding(
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
                  // 🔥 Hero Image with Glow
                  Stack(
                    alignment: Alignment.center,
                    children: [
                      Container(
                        height: 140.h,
                        width: 140.h,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(color: Colors.blue.withValues(alpha: 0.3), blurRadius: 40, spreadRadius: 5)
                          ],
                        ),
                      ),
                      SizedBox(
                        height: 160.h,
                        child: Image.asset('assets/images/phone.png', fit: BoxFit.contain),
                      ),
                    ],
                  ),

                  SizedBox(height: 30.h),
                  Text(
                    widget.forceLinkMode ? "Secure Your Account" : "Welcome Back",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 30.sp, 
                      color: Colors.white,
                      letterSpacing: 1.2,
                    ),
                  ),
                  SizedBox(height: 8.h),
                  Text(
                    "Enter your mobile number to continue",
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 14.sp, color: Colors.white54, letterSpacing: 0.5),
                  ),

                  SizedBox(height: 40.h),

                  // 💎 Modern Glassmorphism-style Input Card
                  Container(
                    padding: EdgeInsets.all(24.r),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(30.r),
                      border: Border.all(color: Colors.white10, width: 1.5),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.phone_android_rounded, color: Colors.blueAccent, size: 18.sp),
                            SizedBox(width: 8.w),
                            Text(
                              "MOBILE NUMBER", 
                              style: TextStyle(
                                fontSize: 11.sp, 
                                fontWeight: FontWeight.bold, 
                                color: Colors.white,
                                letterSpacing: 1.5,
                              )
                            ),
                          ],
                        ),
                        SizedBox(height: 16.h),
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 4.h),
                          decoration: BoxDecoration(
                            color: Colors.black,
                            borderRadius: BorderRadius.circular(15.r),
                            border: Border.all(color: Colors.blue.withValues(alpha: 0.3)),
                          ),
                          child: TextField(
                            controller: phoneController,
                            onChanged: (value) {
                              // ✅ Remove non-numeric characters
                              String digits = value.replaceAll(RegExp(r'[^0-9]'), '');
                              // ✅ If user pastes/enters +91 or 0 prefix, take only last 10 digits
                              if (digits.length > 10) {
                                String clean = digits.substring(digits.length - 10);
                                phoneController.value = TextEditingValue(
                                  text: clean,
                                  selection: TextSelection.collapsed(offset: clean.length),
                                );
                              }
                            },
                            keyboardType: TextInputType.phone,
                            maxLength: 10,
                            style: TextStyle(
                              fontSize: 22.sp, 
                              fontWeight: FontWeight.bold, 
                              letterSpacing: 3, 
                              color: Colors.white,
                            ),
                            decoration: InputDecoration(
                              counterText: "",
                              prefixText: "+91 ",
                              prefixStyle: TextStyle(
                                fontSize: 20.sp, 
                                fontWeight: FontWeight.bold, 
                                color: Colors.blueAccent,
                              ),
                              hintText: "0000000000",
                              hintStyle: TextStyle(color: Colors.white),
                              border: InputBorder.none,
                            ),
                          ),
                        ),
                        SizedBox(height: 32.h),
                        
                        // 🚀 Glowing Action Button
                        Container(
                          width: double.infinity,
                          height: 60.h,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(18.r),
                            boxShadow: [
                              if (!isLoading)
                                BoxShadow(
                                  color: Colors.blueAccent.withValues(alpha: 0.3),
                                  blurRadius: 15,
                                  offset: const Offset(0, 5),
                                )
                            ],
                          ),
                          child: ElevatedButton(
                            onPressed: isLoading ? null : _loginWithPhone,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blueAccent,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18.r)),
                              elevation: 0,
                            ),
                            child: isLoading
                                ? const SizedBox(
                                    height: 24, 
                                    width: 24, 
                                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 3),
                                  )
                                : Text(
                                    "CONTINUE", 
                                    style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.bold, letterSpacing: 2),
                                  ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  SizedBox(height: 40.h),
                  // Footer info
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.shield_outlined, color: Colors.white24, size: 14.sp),
                      SizedBox(width: 6.w),
                      Text(
                        "Your data is safe with us",
                        style: TextStyle(color: Colors.white24, fontSize: 11.sp),
                      ),
                    ],
                  ),
                  SizedBox(height: 40.h),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
