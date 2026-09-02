import 'dart:async';
import 'package:coze/log_in/personal_detail.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/services.dart';

class OtpPage extends StatefulWidget {
  final String loginType;
  final String identifier;
  String verificationId;
  final bool isLinking;

  OtpPage({
    super.key,
    required this.loginType,
    required this.identifier,
    required this.verificationId,
    this.isLinking = false,
  });

  @override
  State<OtpPage> createState() => _OtpPageState();
}

class _OtpPageState extends State<OtpPage> {
  final TextEditingController otpController = TextEditingController();
  bool isLoading = false;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  
  // Timer variables
  int _secondsRemaining = 60;
  Timer? _timer;
  bool _canResend = false;

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  @override
  void dispose() {
    _timer?.cancel();
    otpController.dispose();
    super.dispose();
  }

  void _startTimer() {
    _secondsRemaining = 60;
    _canResend = false;
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_secondsRemaining > 0) {
        setState(() => _secondsRemaining--);
      } else {
        setState(() => _canResend = true);
        _timer?.cancel();
      }
    });
  }

  Future<void> _verifyOtp() async {
    final smsCode = otpController.text.trim();

    if (smsCode.length < 6) {
      _showError("Please enter valid 6-digit OTP");
      return;
    }

    setState(() => isLoading = true);

    try {
      final credential = PhoneAuthProvider.credential(
        verificationId: widget.verificationId,
        smsCode: smsCode,
      );

      if (widget.isLinking) {
        await _auth.currentUser?.linkWithCredential(credential);
      } else {
        await _auth.signInWithCredential(credential);
      }

      if (!mounted) return;
      Navigator.pushAndRemoveUntil(
        context, 
        MaterialPageRoute(builder: (_) => const PersonalDetailsPage()),
        (route) => false
      );
    } catch (e) {
      debugPrint("OTP Error: $e");
      String errorMsg = "Invalid OTP. Please try again.";
      if (e.toString().contains("session-expired")) {
        errorMsg = "Verification session expired. Please click Resend OTP.";
      } else if (e.toString().contains("credential-already-in-use")) {
        errorMsg = "This phone number is already linked to another account.";
      }
      if (mounted) _showError(errorMsg);
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  Future<void> _resendOtp() async {
    setState(() => isLoading = true);
    try {
      await _auth.verifyPhoneNumber(
        phoneNumber: widget.identifier,
        verificationCompleted: (PhoneAuthCredential credential) async {
          if (widget.isLinking) {
            await _auth.currentUser?.linkWithCredential(credential);
          } else {
            await _auth.signInWithCredential(credential);
          }
          if (mounted) Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const PersonalDetailsPage()));
        },
        verificationFailed: (FirebaseAuthException e) {
          if (mounted) _showError("Verification failed: ${e.message}");
        },
        codeSent: (String vId, int? resendToken) {
          setState(() {
            widget.verificationId = vId;
            isLoading = false;
          });
          _startTimer();
          _showInfo("OTP has been resent!");
        },
        codeAutoRetrievalTimeout: (String vId) {
          widget.verificationId = vId;
        },
      );
    } catch (e) {
      if (mounted) {
        setState(() => isLoading = false);
        _showError("Failed to resend: $e");
      }
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg), 
      backgroundColor: Colors.redAccent,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.r)),
    ));
  }

  void _showInfo(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg), 
      backgroundColor: Colors.green,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.r)),
    ));
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
            colors: [Color(0xFF6B52B6), Color(0xFF4A3592), Color(0xFF311B92)],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: EdgeInsets.symmetric(horizontal: 24.w),
            child: Column(
              children: [
                SizedBox(height: 20.h),
                Align(
                  alignment: Alignment.centerLeft,
                  child: IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white)),
                ),
                SizedBox(height: 10.h),
                Image.asset('assets/images/otp.png', height: 160.h, fit: BoxFit.contain),
                SizedBox(height: 30.h),
                Text("Verification", style: TextStyle(fontSize: 32.sp, color: Colors.white)),
                SizedBox(height: 8.h),
                Text("Enter the code sent to\n${widget.identifier}", textAlign: TextAlign.center, style: TextStyle(color: Colors.white70, fontSize: 16.sp, height: 1.5)),
                SizedBox(height: 40.h),
                Container(
                  padding: EdgeInsets.all(28.w),
                  decoration: BoxDecoration(
                    color: Colors.white, 
                    borderRadius: BorderRadius.circular(35.r),
                    boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 20, offset: const Offset(0, 10))],
                  ),
                  child: Column(
                    children: [
                      TextField(
                        controller: otpController,
                        keyboardType: TextInputType.number,
                        maxLength: 6,
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 28.sp, fontWeight: FontWeight.bold, letterSpacing: 12, color: const Color(0xFF311B92)),
                        decoration: InputDecoration(
                          counterText: "", 
                          hintText: "000000", 
                          hintStyle: TextStyle(color: Colors.grey.shade100), 
                          border: InputBorder.none,
                          filled: true,
                          fillColor: Colors.grey.shade50,
                          contentPadding: EdgeInsets.symmetric(vertical: 15.h),
                          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(15.r), borderSide: BorderSide(color: Colors.grey.shade100)),
                          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(15.r), borderSide: const BorderSide(color: Color(0xFF6B52B6))),
                        ),
                      ),
                      SizedBox(height: 30.h),
                      ElevatedButton(
                        onPressed: isLoading ? null : _verifyOtp,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF6B52B6), 
                          foregroundColor: Colors.white, 
                          minimumSize: Size(double.infinity, 60.h), 
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18.r)),
                          elevation: 8,
                        ),
                        child: isLoading 
                          ? const CircularProgressIndicator(color: Colors.white) 
                          : const Text("VERIFY OTP", style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1, fontSize: 16)),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 30.h),
                
                if (!_canResend)
                  Text(
                    "Resend code in 00:${_secondsRemaining.toString().padLeft(2, '0')}",
                    style: TextStyle(color: Colors.white70, fontSize: 14.sp),
                  )
                else
                  TextButton(
                    onPressed: isLoading ? null : _resendOtp,
                    child: const Text(
                      "Resend OTP",
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, decoration: TextDecoration.underline),
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
}
