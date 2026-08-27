import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'package:flutter_screenutil/flutter_screenutil.dart';

class ReportPage extends StatefulWidget {
  final String userId;
  final String parentId;
  final String type;

  const ReportPage({
    super.key,
    required this.userId,
    required this.parentId,
    required this.type,
  });

  @override
  State<ReportPage> createState() => _ReportPageState();
}

class _ReportPageState extends State<ReportPage> {
  final TextEditingController _controller = TextEditingController();
  bool _submitting = false;

  Future<void> _submitReport() async {
    final reason = _controller.text.trim();
    if (reason.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("⚠️ Please write your problem before submitting")),
      );
      return;
    }

    setState(() => _submitting = true);

    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      await FirebaseFirestore.instance.collection("reports").add({
        "reportedId": widget.userId,
        "parentId": widget.parentId,
        "type": widget.type,
        "reason": reason,
        "reportedAt": DateTime.now().toIso8601String(),
        "submittedBy": user.uid,
      });

      setState(() => _submitting = false);

      // ✅ Confirmation message with auto back navigation
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text("Report Submitted"),
          content: const Text(
              "Your report has been submitted successfully.\n\nThank you for helping us improve!"),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context); // close dialog
                Navigator.pop(context); // go back to UserDetails
              },
              child: const Text("OK"),
            ),
          ],
        ),
      );

      _controller.clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Report User"),
        backgroundColor: isDark ? Colors.black87 : Colors.indigo,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: EdgeInsets.all(16.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Describe the problem:",
                style: TextStyle(
                    fontSize: 18.sp,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white70 : Colors.black87)),
            SizedBox(height: 16.h),
            TextField(
              controller: _controller,
              maxLines: 5,
              style: TextStyle(color: isDark ? Colors.white : Colors.black, fontSize: 14.sp),
              decoration: InputDecoration(
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12.r)),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12.r),
                  borderSide: BorderSide(color: isDark ? Colors.white24 : Colors.grey),
                ),
                hintText: "Write your issue here...",
                hintStyle: TextStyle(color: isDark ? Colors.white38 : Colors.grey, fontSize: 14.sp),
                fillColor: isDark ? Colors.grey.shade900 : Colors.white,
                filled: true,
              ),
            ),
            SizedBox(height: 24.h),
            _submitting
                ? const Center(child: CircularProgressIndicator())
                : ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: isDark ? Colors.orange.shade900 : Colors.orange,
                minimumSize: Size(double.infinity, 55.h),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
              ),
              icon: Icon(Icons.send, color: Colors.white, size: 20.sp),
              label: Text("Submit Report",
                  style: TextStyle(color: Colors.white, fontSize: 16.sp, fontWeight: FontWeight.bold)),
              onPressed: _submitReport,
            ),
          ],
        ),
      ),
    );
  }
}
