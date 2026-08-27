// Fixed deprecation warnings
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:coze/log_in/intro_page.dart';
import 'package:coze/Profile/custom_app_bar/app_bar_widget.dart';

class DeleteAccountPage extends StatefulWidget {
  const DeleteAccountPage({super.key});

  @override
  State<DeleteAccountPage> createState() => _DeleteAccountPageState();
}

class _DeleteAccountPageState extends State<DeleteAccountPage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final TextEditingController _deleteController = TextEditingController();
  
  String? _selectedReason;
  bool _isLoading = false;
  bool _isDeleteEnabled = false;

  final List<String> _reasons = [
    "I found another app",
    "The app is hard to use",
    "I'm worried about my privacy",
    "I don't need this service anymore",
    "Other"
  ];

  Future<void> _deleteAccount() async {
    setState(() => _isLoading = true);
    try {
      final user = _auth.currentUser;
      if (user != null) {
        final uid = user.uid;

        // ✅ Delete student data
        final subcollections = ["wishlist", "blocked", "notifications"];
        for (String sub in subcollections) {
          final snapshot = await _firestore
              .collection("users")
              .doc(uid)
              .collection(sub)
              .get();
          for (var doc in snapshot.docs) {
            await doc.reference.delete();
          }
        }

        await _firestore.collection("users").doc(uid).delete();
        await user.delete();

        final prefs = await SharedPreferences.getInstance();
        await prefs.remove("user_lat");
        await prefs.remove("user_lng");
        await prefs.remove("user_locality");

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Account Deleted. All your ads and data are lost."),
              backgroundColor: Colors.red,
              behavior: SnackBarBehavior.floating,
            ),
          );
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (_) => const IntroPage()),
            (Route<dynamic> route) => false,
          );
        }
      }
    } catch (e) {
      debugPrint("Delete failed: $e");
      String errorMsg = "Delete failed: $e";
      if (e.toString().contains("requires-recent-login")) {
        errorMsg = "Please logout and login again to delete your account for security.";
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(errorMsg)),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomAppBar(
        title: "Delete Account",
        backgroundColor: Colors.red,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(20.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: EdgeInsets.all(20.w),
              decoration: BoxDecoration(
                color: Colors.red.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(20.r),
                border: Border.all(color: Colors.red.shade100),
              ),
              child: Column(
                children: [
                  Icon(Icons.warning_amber_rounded, size: 60.sp, color: Colors.red),
                  SizedBox(height: 16.h),
                  Text(
                    "We're sorry to see you go!",
                    style: TextStyle(fontSize: 20.sp, fontWeight: FontWeight.bold, color: Colors.red.shade900),
                  ),
                  SizedBox(height: 12.h),
                  Text(
                    "Deleting your account is permanent. You will lose your profile information, wishlist, and search history immediately.",
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 14.sp, color: Colors.grey.shade700, height: 1.5),
                  ),
                ],
              ),
            ),
            SizedBox(height: 32.h),
            Text(
              "Why are you leaving?",
              style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 12.h),
            // ignore: deprecated_member_use
            RadioGroup<String>(
              // ignore: deprecated_member_use
              groupValue: _selectedReason,
              // ignore: deprecated_member_use
              onChanged: (val) {
                setState(() {
                  _selectedReason = val;
                  _isDeleteEnabled = (_deleteController.text.trim() == "DELETE") && _selectedReason != null;
                });
              },
              child: Column(
                children: _reasons.map((reason) => RadioListTile<String>(
                  title: Text(reason, style: TextStyle(fontSize: 14.sp)),
                  value: reason,
                  activeColor: Colors.red,
                  contentPadding: EdgeInsets.zero,
                )).toList(),
              ),
            ),
            SizedBox(height: 32.h),
            Text(
              "To confirm, please type 'DELETE' below:",
              style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.w600),
            ),
            SizedBox(height: 16.h),
            TextField(
              controller: _deleteController,
              onChanged: (val) {
                setState(() {
                  _isDeleteEnabled = (val.trim() == "DELETE") && _selectedReason != null;
                });
              },
              decoration: InputDecoration(
                hintText: "DELETE",
                filled: true,
                fillColor: Colors.grey.shade50,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(15.r),
                  borderSide: BorderSide(color: Colors.grey.shade200),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(15.r),
                  borderSide: BorderSide(color: Colors.red.shade700),
                ),
              ),
              style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 2, fontSize: 16.sp),
            ),
            SizedBox(height: 40.h),
            ElevatedButton(
              onPressed: (_isDeleteEnabled && !_isLoading) ? _deleteAccount : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red.shade700,
                foregroundColor: Colors.white,
                disabledBackgroundColor: Colors.grey.shade300,
                minimumSize: Size(double.infinity, 60.h),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15.r)),
                elevation: 0,
              ),
              child: _isLoading
                  ? SizedBox(height: 24.sp, width: 24.sp, child: const CircularProgressIndicator(color: Colors.white))
                  : Text(
                      "DELETE PERMANENTLY",
                      style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.bold, letterSpacing: 1.2),
                    ),
            ),
            SizedBox(height: 24.h),
            Center(
              child: TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(
                  "Changed my mind? Go back",
                  style: TextStyle(color: Colors.grey.shade600, fontWeight: FontWeight.w600, fontSize: 14.sp),
                ),
              ),
            ),
            SizedBox(height: 40.h),
          ],
        ),
      ),
    );
  }
}
