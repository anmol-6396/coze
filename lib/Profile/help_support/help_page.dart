import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:coze/Profile/custom_app_bar/app_bar_widget.dart';
import 'package:coze/Services/theme_manager.dart';

class HelpPage extends StatefulWidget {
  const HelpPage({super.key});

  @override
  State<HelpPage> createState() => _HelpPageState();
}

class _HelpPageState extends State<HelpPage> {
  final TextEditingController _complaintController = TextEditingController();
  bool _isSubmitting = false;

  Future<void> _submitComplaint() async {
    final complaint = _complaintController.text.trim();
    if (complaint.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please write your issue first")),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      final uid = user?.uid ?? "anonymous";
      
      final helpData = {
        "uid": uid,
        "email": user?.email ?? "no-email",
        "name": user?.displayName ?? "No Name",
        "issue": complaint,
        "timestamp": FieldValue.serverTimestamp(),
        "status": "new",
      };

      // ✅ 1. Add to global 'help' collection for admin
      await FirebaseFirestore.instance.collection("help").add(helpData);

      // ✅ 2. Add to user's specific sub-collection
      if (uid != "anonymous") {
        await FirebaseFirestore.instance
            .collection("users")
            .doc(uid)
            .collection("help")
            .add(helpData);
      }

      if (mounted) {
        _complaintController.clear();
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20.r)),
            title: const Icon(Icons.check_circle, color: Colors.green, size: 60),
            content: const Text(
              "We received your message!\nOur support team will contact you very soon.",
              textAlign: TextAlign.center,
              style: TextStyle(fontWeight: FontWeight.w500),
            ),
            actions: [
              Center(
                child: TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text("OK", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                ),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Submission failed: $e")),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = ThemeManager.instance.isDarkMode;

    return Scaffold(
      backgroundColor: isDark ? Colors.black : Colors.grey[50],
      appBar: const CustomAppBar(
        title: "Help & Support",
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 24.h),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 💡 FAQ Section
            Row(
              children: [
                Icon(Icons.question_answer_rounded, color: Colors.indigo, size: 22.sp),
                SizedBox(width: 8.w),
                _sectionTitle("Quick Help (FAQs)", isDark),
              ],
            ),
            SizedBox(height: 16.h),
            _buildFAQList(isDark),
            
            SizedBox(height: 40.h),
            
            // 📩 Contact Form Section
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(24.r),
              decoration: BoxDecoration(
                color: isDark ? Colors.grey[900] : Colors.white,
                borderRadius: BorderRadius.circular(24.r),
                border: Border.all(color: isDark ? Colors.white10 : Colors.indigo.withOpacity(0.1)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(isDark ? 0.3 : 0.05),
                    blurRadius: 15,
                    offset: const Offset(0, 8),
                  )
                ],
              ),
              child: Column(
                children: [
                  Container(
                    padding: EdgeInsets.all(12.r),
                    decoration: BoxDecoration(
                      color: Colors.orange.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.support_agent_rounded, color: Colors.orange, size: 32.sp),
                  ),
                  SizedBox(height: 16.h),
                  Text(
                    "Still Need Help?",
                    style: TextStyle(fontSize: 20.sp, fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.indigo),
                  ),
                  SizedBox(height: 8.h),
                  Text(
                    "Send us a message and we'll get back to you within a few hours.",
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 13.sp, color: isDark ? Colors.white60 : Colors.black54),
                  ),
                  SizedBox(height: 24.h),
                  TextField(
                    controller: _complaintController,
                    maxLines: 5,
                    style: TextStyle(color: isDark ? Colors.white : Colors.black, fontSize: 14.sp),
                    decoration: InputDecoration(
                      hintText: "Describe your issue or feedback here...",
                      hintStyle: TextStyle(color: Colors.grey, fontSize: 13.sp),
                      filled: true,
                      fillColor: isDark ? Colors.black26 : Colors.grey[50],
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16.r),
                        borderSide: BorderSide(color: isDark ? Colors.white10 : Colors.grey.shade300),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16.r),
                        borderSide: BorderSide(color: isDark ? Colors.white10 : Colors.grey.shade300),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16.r),
                        borderSide: const BorderSide(color: Colors.indigo, width: 1.5),
                      ),
                    ),
                  ),
                  SizedBox(height: 24.h),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _isSubmitting ? null : _submitComplaint,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.indigo,
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.symmetric(vertical: 16.h),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
                        elevation: 0,
                      ),
                      child: _isSubmitting 
                        ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                        : Text("SEND MESSAGE", style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.bold, letterSpacing: 1)),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 40.h),
          ],
        ),
      ),
    );
  }

  Widget _sectionTitle(String title, bool isDark) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 18.sp,
        fontWeight: FontWeight.bold,
        color: isDark ? Colors.white : Colors.black87,
      ),
    );
  }

  Widget _buildCategoryGrid(bool isDark) {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      mainAxisSpacing: 15.w,
      crossAxisSpacing: 15.w,
      childAspectRatio: 1.5,
      children: [
        _categoryCard(Icons.person_outline, "Account", Colors.blue, isDark),
        _categoryCard(Icons.payment_outlined, "Payments", Colors.green, isDark),
        _categoryCard(Icons.ads_click, "Manage Ads", Colors.orange, isDark),
        _categoryCard(Icons.security_outlined, "Privacy", Colors.purple, isDark),
      ],
    );
  }

  Widget _categoryCard(IconData icon, String label, Color color, bool isDark) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? Colors.grey[900] : Colors.white,
        borderRadius: BorderRadius.circular(16.r),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10.r)],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 24.sp),
          SizedBox(height: 8.h),
          Text(
            label,
            style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.w600, color: isDark ? Colors.white : Colors.black87),
          ),
        ],
      ),
    );
  }

  Widget _buildFAQList(bool isDark) {
    return Column(
      children: [
        _faqItem("Are my details secure?", "Yes, Coze uses industry-standard encryption to protect your data.", isDark),
        _faqItem("How can I change my location?", "While searching or viewing ads, the app uses your current location or you can pick one manually.", isDark),
      ],
    );
  }

  Widget _faqItem(String question, String answer, bool isDark) {
    return Container(
      margin: EdgeInsets.only(bottom: 12.h),
      decoration: BoxDecoration(
        color: isDark ? Colors.grey[900] : Colors.white,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: isDark ? Colors.white10 : Colors.grey.shade200),
      ),
      child: ExpansionTile(
        title: Text(
          question,
          style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.w600, color: isDark ? Colors.white : Colors.black87),
        ),
        iconColor: Colors.indigo,
        children: [
          Padding(
            padding: EdgeInsets.fromLTRB(16.w, 0, 16.w, 16.h),
            child: Text(
              answer,
              style: TextStyle(fontSize: 13.sp, color: isDark ? Colors.white60 : Colors.black54, height: 1.5),
            ),
          ),
        ],
      ),
    );
  }
}
