import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:lottie/lottie.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class RateUsPage extends StatefulWidget {
  const RateUsPage({super.key});

  @override
  State<RateUsPage> createState() => _RateUsPageState();
}

class _RateUsPageState extends State<RateUsPage> {
  int _rating = 0;
  final TextEditingController _feedbackController = TextEditingController();

  String _getRatingText() {
    switch (_rating) {
      case 1: return "Terrible";
      case 2: return "Bad";
      case 3: return "Okay";
      case 4: return "Good";
      case 5: return "Excellent!";
      default: return "Select Stars";
    }
  }

  Color _getRatingColor() {
    switch (_rating) {
      case 1: return Colors.red;
      case 2: return Colors.orange;
      case 3: return Colors.amber;
      case 4: return Colors.lightGreen;
      case 5: return Colors.green;
      default: return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final content = SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 20.h),
      child: Column(
        children: [
          SizedBox(height: 20.h),
          // Animated Icon
          SizedBox(
            height: 180.h,
            child: Lottie.network(
              'https://assets3.lottiefiles.com/packages/lf20_mY88S9.json', // Feedback animation
              fit: BoxFit.contain,
              errorBuilder: (context, error, stackTrace) => Icon(Icons.star_rounded, size: 100.sp, color: Colors.amber),
            ),
          ),
          
          Text(
            "Enjoying Coze?",
            style: TextStyle(
              fontSize: 26.sp,
              fontWeight: FontWeight.bold,
              fontFamily: 'Mogra',
              color: isDark ? Colors.white : Colors.indigo.shade900,
            ),
          ),
          SizedBox(height: 8.h),
          Text(
            "Your feedback helps us grow and provide better services in your zone.",
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 14.sp, color: isDark ? Colors.white70 : Colors.black54),
          ),
          
          SizedBox(height: 32.h),

          // Rating Stars and Label
          Container(
            padding: EdgeInsets.all(20.r),
            decoration: BoxDecoration(
              color: isDark ? Colors.grey[900] : Colors.white,
              borderRadius: BorderRadius.circular(24.r),
              boxShadow: [
                BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 20, offset: const Offset(0, 10))
              ],
            ),
            child: Column(
              children: [
                Text(
                  _getRatingText(),
                  style: TextStyle(
                    fontSize: 20.sp, 
                    fontWeight: FontWeight.w900, 
                    color: _getRatingColor(),
                    letterSpacing: 1,
                  ),
                ),
                SizedBox(height: 16.h),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(5, (index) {
                    bool isSelected = index < _rating;
                    return GestureDetector(
                      onTap: () => setState(() => _rating = index + 1),
                      child: Padding(
                        padding: EdgeInsets.symmetric(horizontal: 4.w),
                        child: TweenAnimationBuilder<double>(
                          tween: Tween(begin: 1.0, end: isSelected ? 1.2 : 1.0),
                          duration: const Duration(milliseconds: 200),
                          builder: (context, scale, child) {
                            return Transform.scale(
                              scale: scale,
                              child: Icon(
                                isSelected ? Icons.star_rounded : Icons.star_outline_rounded,
                                size: 45.sp,
                                color: isSelected ? Colors.amber : Colors.grey.shade300,
                              ),
                            );
                          },
                        ),
                      ),
                    );
                  }),
                ),
              ],
            ),
          ),

          SizedBox(height: 32.h),

          // Feedback Input
          TextField(
            controller: _feedbackController,
            maxLines: 4,
            style: TextStyle(color: isDark ? Colors.white : Colors.black, fontSize: 14.sp),
            decoration: InputDecoration(
              hintText: "Write a short review (Optional)",
              hintStyle: TextStyle(color: Colors.grey, fontSize: 13.sp),
              filled: true,
              fillColor: isDark ? Colors.grey[900] : Colors.grey[100],
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16.r),
                borderSide: BorderSide.none,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16.r),
                borderSide: BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16.r),
                borderSide: const BorderSide(color: Colors.indigo, width: 1.5),
              ),
              contentPadding: EdgeInsets.all(20.r),
            ),
          ),

          SizedBox(height: 32.h),

          // Action Buttons
          Column(
            children: [
              SizedBox(
                width: double.infinity,
                height: 55.h,
                child: ElevatedButton(
                  onPressed: _rating == 0 ? null : _submitToFirebase,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.indigo,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18.r)),
                    elevation: 4,
                  ),
                  child: Text(
                    "SUBMIT FEEDBACK",
                    style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.bold, letterSpacing: 1),
                  ),
                ),
              ),
              SizedBox(height: 16.h),
              SizedBox(
                width: double.infinity,
                height: 55.h,
                child: OutlinedButton.icon(
                  onPressed: _launchPlayStore,
                  icon: Icon(Icons.shop_two_rounded, color: Colors.indigo, size: 22.sp),
                  label: Text(
                    "RATE ON PLAY STORE",
                    style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.bold, color: Colors.indigo, letterSpacing: 1),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Colors.indigo, width: 2),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18.r)),
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 30.h),
        ],
      ),
    );

    if (Platform.isIOS) {
      return CupertinoPageScaffold(
        navigationBar: CupertinoNavigationBar(
          middle: const Text("Rate Us", style: TextStyle(fontFamily: 'Mogra')),
          backgroundColor: isDark ? Colors.black87 : Colors.white,
        ),
        child: SafeArea(child: content),
      );
    } else {
      return Scaffold(
        backgroundColor: isDark ? Colors.black : const Color(0xFFF8F9FE),
        appBar: AppBar(
          title: const Text("Rate Us", style: TextStyle(fontFamily: 'Mogra', fontWeight: FontWeight.bold)),
          backgroundColor: Colors.indigo,
          foregroundColor: Colors.white,
          centerTitle: true,
          elevation: 0,
        ),
        body: content,
      );
    }
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
              backgroundColor: Colors.indigo, 
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
